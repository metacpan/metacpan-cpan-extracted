#ABSTRACT: An asynchronous library for InfluxDB time-series database
use strict;
use warnings;
package AnyEvent::InfluxDB;
our $AUTHORITY = 'cpan:AJGB';
$AnyEvent::InfluxDB::VERSION = '1.0.2.0';
use AnyEvent;
use AnyEvent::HTTP;
use URI;
use URI::QueryParam;
use JSON qw(decode_json);
use List::MoreUtils qw(zip);
use URI::Encode::XS qw( uri_encode );
use Moo;

has [qw( ssl_options username password jwt on_request )] => (
    is => 'ro',
    predicate => 1,
);

has 'server' => (
    is => 'rw',
    default => 'http://localhost:8086',
);

has '_is_ssl' => (
    is => 'lazy',
);

has '_tls_ctx' => (
    is => 'lazy',
);

has '_server_uri' => (
    is => 'lazy',
);


sub _build__tls_ctx {
    my ($self) = @_;

    # no ca/hostname checks
    return 'low' unless $self->has_ssl_options;

    # create ctx
    require AnyEvent::TLS;
    return AnyEvent::TLS->new( %{ $self->ssl_options } );
}

sub _build__is_ssl {
    my ($self) = @_;

    return $self->server =~ /^https/;
}

sub _build__server_uri {
    my ($self) = @_;

    my $url = URI->new( $self->server, 'http' );

    if ( $self->has_username && $self->has_password ) {
        $url->query_param( 'u' => $self->username );
        $url->query_param( 'p' => $self->password );
    }

    return $url;
}

sub _make_url {
    my ($self, $path, $params) = @_;

    my $url = $self->_server_uri->clone;
    $url->path($path);

    while ( my ($k, $v) = each %$params ) {
        $url->query_param( $k => $v );
    }

    return $url;
}

sub _http_request {
    my $cb = pop;
    my ($self, $method, $url, $post_data) = @_;

    if ($self->has_on_request) {
        $self->on_request->($method, $url, $post_data);
    }

    my %args = (
        headers => {
            referer => undef,
            'user-agent' => "AnyEvent-InfluxDB/0.13",
        }
    );

    if ($self->has_jwt) {
        $args{headers}->{Authorization} = 'Bearer '. $self->jwt;
    }

    if ( $method eq 'POST' ) {
        if ( defined $post_data ) {
            $args{'body'} = $post_data;
        } else {
            if ( my $q = $url->query_param_delete('q') ) {
                $args{headers}{'content-type'} = 'application/x-www-form-urlencoded';
                $args{body} = 'q='. uri_encode($q);
            }
        }
    }
    if ( $self->_is_ssl ) {
        $args{tls_ctx} = $self->_tls_ctx;
    }

    my $guard;
    $guard = http_request
        $method => $url->as_string,
        %args,
        sub {
            $cb->(@_);
            undef $guard;
        };
};


sub ping {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/ping', {
        (
            exists $args{wait_for_leader} ?
                ( wait_for_leader => $args{wait_for_leader} )
                :
                ()
        )
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;
            if ( $headers->{Status} eq '204' ) {
                $args{on_success}->( $headers->{'x-influxdb-version'} );
            } else {
                $args{on_error}->( $headers->{Reason} || $body );
            }
        }
    );
}


sub _to_line {
    my $data = shift;

    my $t = $data->{tags} || {};
    my $f = $data->{fields} || {};

    return $data->{measurement}
        .(
            $t ?
                    ','.
                    join(',',
                        map {
                            join('=', $_, $t->{$_})
                        } sort { $a cmp $b } keys %$t
                    )
                :
                ''
        )
        . ' '
        .(
            join(',',
                map {
                    join('=', $_, $f->{$_})
                } keys %$f
            )
        )
        .(
            $data->{time} ?
                ' '. $data->{time}
                :
                ''
        );
}

sub write {
    my ($self, %args) = @_;

    my $data = ref $args{data} eq 'ARRAY' ?
        join("\n", map { ref $_ eq 'HASH' ? _to_line($_) : $_ } @{ $args{data} })
        :
        ref $args{data} eq 'HASH' ? _to_line($args{data}) : $args{data};

    my $url = $self->_make_url('/write', {
        db => $args{database},
        (
            $args{consistency} ?
                ( consistency => $args{consistency} )
                :
                ()
        ),
        (
            $args{rp} ?
                ( rp => $args{rp} )
                :
                ()
        ),
        (
            $args{precision} ?
                ( precision => $args{precision} )
                :
                ()
        ),
        (
            $args{one} ?
                ( one => $args{one} )
                :
                ()
        )
    });

    $self->_http_request( POST => $url, $data,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '204' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub select {
    my ($self, %args) = @_;

    my $method = 'GET';
    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
        if ( $q =~ /\s+INTO\s+/i ) {
            $method = 'POST';
        }
    } else {
        $q = 'SELECT '. $args{fields};

        if ( my $into = $args{into} ) {
            $q .= ' INTO '. $into;
            $method = 'POST';
        }

        $q .= ' FROM '. $args{measurement};

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }

        if ( my $group = $args{group_by} ) {
            $q .= ' GROUP BY '. $group;

            if ( my $fill = $args{fill} ) {
                $q .= ' fill('. $fill .')';
            }
        }

        if ( my $order_by = $args{order_by} ) {
            $q .= ' ORDER BY '. $order_by;
        }

        if ( my $limit = $args{limit} ) {
            $q .= ' LIMIT '. $limit;

            if ( my $offset = $args{offset} ) {
                $q .= ' OFFSET '. $offset;
            }
        }

        if ( my $slimit = $args{slimit} ) {
            $q .= ' SLIMIT '. $slimit;

            if ( my $soffset = $args{soffset} ) {
                $q .= ' SOFFSET '. $soffset;
            }
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q,
        (
            $args{rp} ?
                ( rp => $args{rp} )
                :
                ()
        ),
        (
            $args{epoch} ?
                ( epoch => $args{epoch} )
                :
                ()
        ),
        (
            $args{chunk_size} ?
                ( chunk_size => $args{chunk_size} )
                :
                ()
        ),
    });

    $self->_http_request( $method => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $series = [
                    map {
                        my $res = $_;

                        my $cols = $res->{columns};
                        my $values = $res->{values};

                        +{
                            name => $res->{name},
                            values => [
                                map {
                                    +{
                                        zip(@$cols, @$_)
                                    }
                                } @{ $values || [] }
                            ]
                        }
                    } @{ $data->{results}->[0]->{series} || [] }
                ];
                $args{on_success}->($series);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub create_database {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'CREATE DATABASE '. $args{database};
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->( $body );
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_database {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP DATABASE '. $args{database};
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_series {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP SERIES';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' FROM '. $measurement;
        }
        elsif ( my $measurements = $args{measurements} ) {
            $q .= ' FROM '. join(',', @{ $measurements || [] });
        }

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub delete_series {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DELETE';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' FROM '. $measurement;
        }

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_measurement {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP MEASUREMENT '. $args{measurement};
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_shards {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        q => 'SHOW SHARDS'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $shards = {};
                for my $res ( @{ $data->{results}->[0]->{series} || [] } ) {
                    my $cols = $res->{columns};
                    my $values = $res->{values};
                    $shards->{ $res->{name } } = [
                        map {
                            +{
                                zip(@$cols, @$_)
                            }
                        } @{ $values || [] }
                    ];
                }
                $args{on_success}->($shards);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_shard_groups {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        q => 'SHOW SHARD GROUPS'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $cols = $res->{columns};
                my $values = $res->{values};
                my @shard_groups = (
                    map {
                        +{
                            zip(@$cols, @$_)
                        }
                    } @{ $values || [] }
                );
                $args{on_success}->(@shard_groups);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_shard {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP SHARD '. $args{id};
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_queries {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        q => 'SHOW QUERIES'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $cols = $res->{columns};
                my $values = $res->{values};
                my @queries = (
                    map {
                        +{
                            zip(@$cols, @$_)
                        }
                    } @{ $values || [] }
                );
                $args{on_success}->(@queries);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub kill_query {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'KILL QUERY '. $args{id};
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}



sub create_retention_policy {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'CREATE RETENTION POLICY '. $args{name}
            .' ON '. $args{database}
            .' DURATION '. $args{duration}
            .' REPLICATION '. $args{replication}
            .' SHARD DURATION '. $args{shard_duration};

        $q .= ' DEFAULT' if $args{default};
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub alter_retention_policy {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'ALTER RETENTION POLICY '. $args{name}
            .' ON '. $args{database};

        $q .= ' DURATION '. $args{duration} if exists $args{duration};
        $q .= ' SHARD DURATION '. $args{shard_duration} if exists $args{shard_duration};
        $q .= ' REPLICATION '. $args{replication} if exists $args{replication};;
        $q .= ' DEFAULT' if $args{default};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_retention_policy {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP RETENTION POLICY '. $args{name} .' ON '. $args{database};
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_databases {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        q => 'SHOW DATABASES'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my @names;
                eval {
                    @names = map { $_->[0] } @{ $data->{results}->[0]->{series}->[0]->{values} || [] };
                };
                $args{on_success}->(@names);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_retention_policies {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW RETENTION POLICIES ON '. $args{database};
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $cols = $res->{columns};
                my $values = $res->{values};
                my @policies = (
                    map {
                        +{
                            zip(@$cols, @$_)
                        }
                    } @{ $values || [] }
                );
                $args{on_success}->(@policies);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_series {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW SERIES';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' FROM '. $measurement;
        }

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }

        if ( my $order_by = $args{order_by} ) {
            $q .= ' ORDER BY '. $order_by;
        }

        if ( my $limit = $args{limit} ) {
            $q .= ' LIMIT '. $limit;

            if ( my $offset = $args{offset} ) {
                $q .= ' OFFSET '. $offset;
            }
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $values = $res->{values};
                my @series = (
                    map { @$_ } @{ $values || [] }
                );
                $args{on_success}->(@series);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_measurements {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW MEASUREMENTS';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' WITH MEASUREMENT '
                . ( $measurement =~ /^\/.*\/$/ ? '=~' : '=' )
                . $measurement;
        }

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }

        if ( my $order_by = $args{order_by} ) {
            $q .= ' ORDER BY '. $order_by;
        }

        if ( my $limit = $args{limit} ) {
            $q .= ' LIMIT '. $limit;

            if ( my $offset = $args{offset} ) {
                $q .= ' OFFSET '. $offset;
            }
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $values = $res->{values};
                my @measurements = (
                    map { @$_ } @{ $values || [] }
                );
                $args{on_success}->(@measurements);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_tag_keys {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW TAG KEYS';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' FROM '. $measurement;
        }

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }

        if ( my $limit = $args{limit} ) {
            $q .= ' LIMIT '. $limit;
        }

        if ( my $offset = $args{offset} ) {
            $q .= ' OFFSET '. $offset;
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $tag_keys = {};
                for my $res ( @{ $data->{results}->[0]->{series} || [] } ) {
                    my $values = $res->{values};
                    $tag_keys->{ $res->{name } } = [
                        map {
                            @$_
                        } @{ $values || [] }
                    ];
                }
                $args{on_success}->($tag_keys);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_tag_values {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW TAG VALUES';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' FROM '. $measurement;
        }

        if ( my $keys = $args{keys} ) {
            $q .= ' WITH KEY IN ('. join(", ", @$keys) .')';
        }
        elsif ( my $key = $args{key} ) {
            $q .= ' WITH KEY = '. $key;
        }

        if ( my $cond = $args{where} ) {
            $q .= ' WHERE '. $cond;
        }

        if ( my $limit = $args{limit} ) {
            $q .= ' LIMIT '. $limit;
        }

        if ( my $offset = $args{offset} ) {
            $q .= ' OFFSET '. $offset;
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $tag_values = {};
                for my $res ( @{ $data->{results}->[0]->{series} || [] } ) {
                    my $cols = $res->{columns};
                    my %col_idx = ( key => 0, value => 1 );
                    for ( my $i = 0; $i < @{ $cols || [] }; $i++ ) {
                        $col_idx{ $cols->[$i] } = $i;
                    }
                    my $values = $res->{values};
                    for my $v ( @{ $values || [] } ) {
                        push @{ $tag_values->{ $res->{name } }->{ $v->[ $col_idx{key} ] } },
                            $v->[ $col_idx{value} ];
                    }
                }
                $args{on_success}->($tag_values);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_field_keys {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW FIELD KEYS';

        if ( my $measurement = $args{measurement} ) {
            $q .= ' FROM '. $measurement;
        }
    }

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => $q
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $field_keys = {};
                for my $res ( @{ $data->{results}->[0]->{series} || [] } ) {
                    my $values = $res->{values};
                    $field_keys->{ $res->{name } } = [
                        map {
                            +{
                                name => $_->[0],
                                type => $_->[1],
                            }
                        } @{ $values || [] }
                    ];
                }
                $args{on_success}->($field_keys);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub create_user {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'CREATE USER '. $args{username}
            .' WITH PASSWORD \''. $args{password} .'\'';

        $q .= ' WITH ALL PRIVILEGES' if $args{all_privileges};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub set_user_password {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SET PASSWORD FOR '. $args{username}
            .' = \''. $args{password} .'\'';
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_users {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        q => 'SHOW USERS'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $cols = $res->{columns};
                my $values = $res->{values};
                my @users = (
                    map {
                        +{
                            zip(@$cols, @$_)
                        }
                    } @{ $values || [] }
                );
                $args{on_success}->(@users);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub grant_privileges {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'GRANT ';

        if ( $args{all_privileges} ) {
            $q .= 'ALL PRIVILEGES';
        } else {
            $q .= $args{access} .' ON '. $args{database};
        }
        $q .= ' TO '. $args{username};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_grants {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'SHOW GRANTS FOR '. $args{username};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $res = $data->{results}->[0]->{series}->[0];
                my $cols = $res->{columns};
                my $values = $res->{values};
                my @grants = (
                    map {
                        +{
                            zip(@$cols, @$_)
                        }
                    } @{ $values || [] }
                );
                $args{on_success}->(@grants);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}



sub revoke_privileges {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'REVOKE ';

        if ( $args{all_privileges} ) {
            $q .= 'ALL PRIVILEGES';
        } else {
            $q .= $args{access} .' ON '. $args{database};
        }
        $q .= ' FROM '. $args{username};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}



sub drop_user {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP USER '. $args{username};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub create_continuous_query {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        my $resample = '';
        if ( $args{every} || $args{for} ) {
            $resample = ' RESAMPLE';
            if ( $args{every} ) {
                $resample .= ' EVERY '. $args{every};
            }
            if ( $args{for} ) {
                $resample .= ' FOR '. $args{for};
            }
        }
        $q = 'CREATE CONTINUOUS QUERY '. $args{name}
            .' ON '. $args{database}
            . $resample
            .' BEGIN '. $args{query}
            .' END';
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_continuous_query {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP CONTINUOUS QUERY '. $args{name} . ' ON '. $args{database};
    }

    my $url = $self->_make_url('/query', {
        q => $q
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_continuous_queries {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        db => $args{database},
        q => 'SHOW CONTINUOUS QUERIES'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $cqs = {};
                for my $res ( @{ $data->{results}->[0]->{series} || [] } ) {
                    my $cols = $res->{columns};
                    my $values = $res->{values};
                    $cqs->{ $res->{name } } = [
                        map {
                            +{
                                zip(@$cols, @$_)
                            }
                        } @{ $values || [] }
                    ];
                }
                $args{on_success}->($cqs);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub create_subscription {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'CREATE SUBSCRIPTION '. $args{name} .' ON '
            . $args{database} .'.'. $args{rp}
            . ' DESTINATIONS '. $args{mode} .' '
            . (
                ref $args{destinations} eq 'ARRAY' ?
                    join(", ", @{ $args{destinations} || [] } )
                    :
                    $args{destinations}
            );
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub show_subscriptions {
    my ($self, %args) = @_;

    my $url = $self->_make_url('/query', {
        q => 'SHOW SUBSCRIPTIONS'
    });

    $self->_http_request( GET => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                my $data = decode_json($body);
                my $subscriptions = {};
                for my $res ( @{ $data->{results}->[0]->{series} || [] } ) {
                    my $cols = $res->{columns};
                    my $values = $res->{values};
                    $subscriptions->{ $res->{name } } = [
                        map {
                            +{
                                zip(@$cols, @$_)
                            }
                        } @{ $values || [] }
                    ];
                }
                $args{on_success}->($subscriptions);
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub drop_subscription {
    my ($self, %args) = @_;

    my $q;
    if ( exists $args{q} ) {
        $q = $args{q};
    } else {
        $q = 'DROP SUBSCRIPTION '. $args{name} .' ON '
            . $args{database} .'.'. $args{rp};
    }

    my $url = $self->_make_url('/query', {
        q => $q,
    });

    $self->_http_request( POST => $url,
        sub {
            my ($body, $headers) = @_;

            if ( $headers->{Status} eq '200' ) {
                $args{on_success}->();
            } else {
                $args{on_error}->( $body );
            }
        }
    );
}


sub query {
    my ($self, %args) = @_;

    my $url = $self->_server_uri->clone;
    $url->path('/query');
    $url->query_form_hash( $args{query} );

    my $method = $args{method} || 'GET';

    $self->_http_request( $method => $url,
        sub {
            $args{on_response}->(@_);
        }
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::InfluxDB - An asynchronous library for InfluxDB time-series database

=head1 VERSION

version 1.0.2.0

=head1 SYNOPSIS

    use EV;
    use AnyEvent;
    use AnyEvent::Socket;
    use AnyEvent::Handle;
    use AnyEvent::InfluxDB;
    use Monitoring::Plugin::Performance;

    my $db = AnyEvent::InfluxDB->new(
        server => 'http://localhost:8086',
        username => 'admin',
        password => 'password',
    );

    my $hdl;
    tcp_server undef, 8888, sub {
        my ($fh, $host, $port) = @_;

        $hdl = AnyEvent::Handle->new(
            fh => $fh,
        );

        $hdl->push_read(
            line => sub {
                my (undef, $line) = @_;

                # Disk\t/=382MB;15264;15269;; /var=218MB;9443;9448
                my ($measurement, $perfstring) = split(/\t/, $line);

                my @perfdata
                    = Monitoring::Plugin::Performance->parse_perfstring($perfstring);

                $db->write(
                    database => 'mydb',
                    data => [
                        map {
                            +{
                                measurement => $measurement,
                                tags => {
                                    label => $_->label,
                                },
                                fields => {
                                    value => $_->value,
                                    uom => '"'. $_->uom .'"',
                                },
                            }
                        } @perfdata
                    ],
                    on_success => sub { print "$line written\n"; },
                    on_error => sub { print "$line error: @_\n"; },
                );

                $hdl->on_drain(
                    sub {
                        $hdl->fh->close;
                        undef $hdl;
                    }
                );
            },
        );
    };

    EV::run;

=head1 DESCRIPTION

Asynchronous client library for InfluxDB time-series database L<https://influxdb.com>.

This version is meant to be used with InfluxDB v1.0.0 or newer.

=head1 METHODS

=head2 new

    my $db = AnyEvent::InfluxDB->new(
        server => 'http://localhost:8086',

        # authenticate using Basic credentials
        username => 'admin',
        password => 'password',

        # or use JWT token
        jwt => 'JWT_TOKEN_BLOB'
    );

Returns object representing given InfluDB C<server> connected using optionally
provided username C<username> and password C<password>.

Default value of C<server> is C<http://localhost:8086>.

If the server protocol is C<https> then by default no validation of remote
host certificate is performed. This can be changed by setting C<ssl_options>
parameter with any options accepted by L<AnyEvent::TLS>.

    my $db = AnyEvent::InfluxDB->new(
        ...
        ssl_options => {
            verify => 1,
            verify_peername => 'https',
            ca_file => '/path/to/cacert.pem',
        }
    );

As an debugging aid the C<on_request> code reference may also be provided. It will
be executed before each request with the method name, url and POST data if set.

    my $db = AnyEvent::InfluxDB->new(
        ...
        on_request => sub {
            my ($method, $url, $post_data) = @_;
            print "$method $url\n";
            print "$post_data\n" if $post_data;
        }
    );

=for Pod::Coverage has_jwt jwt has_on_request has_password has_ssl_options has_username on_request password server ssl_options username

=head2 ping

    $cv = AE::cv;
    $db->ping(
        wait_for_leader => 2,

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to ping cluster leader: @_");
        }
    );
    my $version = $cv->recv;

Checks the leader of the cluster to ensure that the leader is available and ready.
The optional parameter C<wait_for_leader> specifies the number of seconds to wait
before returning a response.

The required C<on_success> code reference is executed if request was successful
with the value of C<X-Influxdb-Version> response header as argument,
otherwise executes the required C<on_error> code reference with the value of
C<Reason> response header as argument.

=head2 Managing Data

=head3 write

    $cv = AE::cv;
    $db->write(
        database => 'mydb',
        precision => 's',
        rp => 'last_day',
        consistency => 'quorum',

        data => [
            # line protocol formatted
            'cpu_load,host=server02,region=eu-east sensor="top",value=0.64 1456097956',

            # or as a hash
            {
                measurement => 'cpu_load',
                tags => {
                    host => 'server02',
                    region => 'eu-east',
                },
                fields => {
                    value => '0.64',
                    sensor => q{"top"},
                },
                time => time()
            }
        ],

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to write data: @_");
        }
    );
    $cv->recv;

Writes time-series data C<data> to database C<database> with optional parameters:
retention policy C<rp>, time precision C<precision> and consistency C<consistency>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

The C<data> can be specified as single scalar value or hash reference with
required keys C<measurement> and C<fields> and optional C<tags> and C<time>.
Both can be also mixed and matched within an array reference.

Scalar values are expected to be formatted using InfluxDB line protocol.

All special characters need to be escaped. In that case you might want to use
L<InfluxDB::LineProtocol>:

    use InfluxDB::LineProtocol qw(dataline);

    ...
    $db->write(
        database => 'mydb',
        precision => 'n',

        data => [
            dataline('CPU Load', 0.64, { "Region of the World" => "Eastern Europe", codename => "eu-east" }, 1437868012260500137)

            # which translates to
            'CPU\ Load,Region\ of\ the\ World=Eastern\ Europe,codename=eu-east value=0.64 1437868012260500137',
        ],
        ...
    );

=head2 Querying Data

=head3 select

    $cv = AE::cv;
    $db->select(
        database => 'mydb',

        # return time in Unix epoch format
        epoch => "s",

        # raw query
        q => "SELECT count(value) FROM cpu_load"
            ." WHERE region = 'eu-east' AND time > now() - 14d"
            ." GROUP BY time(1d) fill(none)"
            ." ORDER BY time DESC"
            ." LIMIT 10 OFFSET 3",

        # or query created from arguments
        fields => 'count(value)',
        measurement => 'cpu_load',
        where => "region = 'eu-east' AND time > now() - 14d",

        group_by => 'time(1d)',
        fill => 'none',

        order_by => 'time DESC',

        limit => 10,
        offset => 3,

        # downsample result to another database, retention policy and measurement
        into => 'otherdb."default".cpu_load_per5m',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to select data: @_");
        }
    );
    my $results = $cv->recv;
    for my $row ( @{ $results } ) {
        print "Measurement: $row->{name}\n";
        print "Values:\n";
        for my $value ( @{ $row->{values} || [] } ) {
            print " * $_ = $value->{$_}\n" for keys %{ $value || {} };
        }
    }

Executes an select query on database C<database> created from provided arguments
measurement C<measurement>, fields to select C<fields>, optional C<where>
clause, grouped by C<group_by> and empty values filled with C<fill>, ordered by
C<order_by> with number of results limited to C<limit> with offset C<offset>.
To limit number of returned series use C<slimit> with offset C<soffset>.
If C<into> parameter is provided the result of the query will be copied to specified
measurement.
If C<epoch> is provided the returned C<time> value will in Unix epoch format.
Optional C<chunk_size> can be provided to override the default value of 10,000 datapoints.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 Database Management

=head3 create_database

    $cv = AE::cv;
    $db->create_database(
        # raw query
        q => "CREATE DATABASE mydb WITH DURATION 7d REPLICATION 3 SHARD DURATION 30m NAME oneweek",

        # or query created from arguments
        database => "mydb",

        # retention policy parameters
        duration => '7d',
        shard_duration => '30m',
        replication => 3,
        name => 'oneweek',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to create database: @_");
        }
    );
    $cv->recv;

Creates database specified by C<database> argument.

If one of retention policy parameters is specified then the database will be
created with that retention policy as default - see L</"Retention Policy Management">
for more details.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_database

    $cv = AE::cv;
    $db->drop_database(
        # raw query
        q => "DROP DATABASE mydb",

        # or query created from arguments
        database => "mydb",

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop database: @_");
        }
    );
    $cv->recv;

Drops database specified by C<database> argument.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_series

    $cv = AE::cv;
    $db->drop_series(
        database => 'mydb',

        # raw query
        q => "DROP SERIES FROM cpu_load WHERE host = 'server02'",

        # or query created from arguments
        measurement => 'cpu_load',
        where => q{host = 'server02'},

        # multiple measurements can also be specified
        measurements => [qw( cpu_load cpu_temp )],

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop measurement: @_");
        }
    );
    $cv->recv;

Drops series from single measurement C<measurement> (or many using C<measurements>)
and/or filtered by C<where> clause from database C<database>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 delete_series

    $cv = AE::cv;
    $db->delete_series(
        database => 'mydb',

        # raw query
        q => "DELETE FROM cpu_load WHERE host = 'server02' AND time < '2016-01-01'",

        # or query created from arguments
        measurement => 'cpu_load',
        where => q{host = 'server02' AND time < '2016-01-01'},

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop measurement: @_");
        }
    );
    $cv->recv;

Deletes all points from a measurement C<measurement>
and/or filtered by C<where> clause from database C<database>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_measurement

    $cv = AE::cv;
    $db->drop_measurement(
        database => 'mydb',

        # raw query
        q => "DROP MEASUREMENT cpu_load",

        # or query created from arguments
        measurement => 'cpu_load',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop measurement: @_");
        }
    );
    $cv->recv;

Drops measurement C<measurement>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_shards

    $cv = AE::cv;
    $db->show_shards(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list shards: @_");
        }
    );
    my $shards = $cv->recv;
    for my $database ( sort keys %{ $shards } ) {
        print "Database: $database\n";
        for my $s ( @{ $shards->{$database} } ) {
            print " * $_: $s->{$_}\n" for sort keys %{ $s };
        }
    }

Returns a hash reference with database name as keys and their shards as values.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_shard_groups

    $cv = AE::cv;
    $db->show_shard_groups(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list shard groups: @_");
        }
    );
    my @shard_groups = $cv->recv;
    for my $sg ( @shard_groups ) {
        print "ID: $sg->{id}\n";
        print "Database: $sg->{database}\n";
        print "Retention Policy: $sg->{retention_policy}\n";
        print "Start Time: $sg->{start_time}\n";
        print "End Time: $sg->{end_time}\n";
        print "Expiry Time: $sg->{expiry_time}\n";
    }

Returns a list of hash references with keys C<id>, C<database>, C<retention_policy>,
C<start_time>, C<end_time> and C<expiry_time> for each shard groups.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_shard

    $cv = AE::cv;
    $db->drop_shard(
        database => 'mydb',

        # raw query
        q => "DROP SHARD 1",

        # or query created from arguments
        id => 1,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop measurement: @_");
        }
    );
    $cv->recv;

Drops shard identified by id number C<id>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_queries

    $cv = AE::cv;
    $db->show_queries(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list shard groups: @_");
        }
    );
    my @queries = $cv->recv;
    for my $q ( @queries ) {
        print "ID: $q->{qid}\n";
        print "Query: $q->{query}\n";
        print "Database: $q->{database}\n";
        print "Duration: $q->{duration}\n";
    }

Returns a list of hash references with keys C<qid>, C<query>, C<database>,
C<duration> for all currently running queries.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 kill_query

    $cv = AE::cv;
    $db->kill_query(
        id => 36,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to kill query: @_");
        }
    );
    $cv->recv;

Stops a running query identified by id number C<id>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 Retention Policy Management

=head3 create_retention_policy

    $cv = AE::cv;
    $db->create_retention_policy(
        # raw query
        q => "CREATE RETENTION POLICY last_day ON mydb DURATION 1d REPLICATION 1",

        # or query created from arguments
        name => 'last_day',
        database => 'mydb',
        duration => '1d',
        shard_duration => '168h',
        replication => 1,
        default => 0,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to create retention policy: @_");
        }
    );
    $cv->recv;

Creates new retention policy named by C<name> on database C<database> with
duration C<duration>, shard group duration C<shard_duration> and replication
factor C<replication>. If C<default> is provided and true the created retention
policy becomes the default one.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 alter_retention_policy

    $cv = AE::cv;
    $db->alter_retention_policy(
        # raw query
        q => "ALTER RETENTION POLICY last_day ON mydb DURATION 1d REPLICATION 1 DEFAULT",

        # or query created from arguments
        name => 'last_day',
        database => 'mydb',

        duration => '1d',
        shard_duration => '12h',
        replication => 1,
        default => 1,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to alter retention policy: @_");
        }
    );
    $cv->recv;

Modifies retention policy named by C<name> on database C<database>. At least one
of duration C<duration>, replication factor C<replication> or flag C<default>
must be set.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_retention_policy

    $cv = AE::cv;
    $db->drop_retention_policy(
        # raw query
        q => "DROP RETENTION POLICY last_day ON mydb",

        # or query created from arguments
        name => "last_day",
        database => "mydb",

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop retention policy: @_");
        }
    );
    $cv->recv;

Drops specified by C<name> retention policy on database C<database>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 Schema Exploration

=head3 show_databases

    $cv = AE::cv;
    $db->show_databases(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list databases: @_");
        }
    );
    my @db_names = $cv->recv;
    print "$_\n" for @db_names;

Returns list of known database names.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_retention_policies

    $cv = AE::cv;
    $db->show_retention_policies(
        # raw query
        q => "SHOW RETENTION POLICIES ON mydb",

        # or query created from arguments
        database => 'mydb',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list retention policies: @_");
        }
    );
    my @retention_policies = $cv->recv;
    for my $rp ( @retention_policies ) {
        print "Name: $rp->{name}\n";
        print "Duration: $rp->{duration}\n";
        print "Shard group duration: $rp->{shardGroupDuration}\n";
        print "Replication factor: $rp->{replicaN}\n";
        print "Default?: $rp->{default}\n";
    }

Returns a list of hash references with keys C<name>, C<duration>,
C<shardGroupDuration>, C<replicaN> and C<default> for each replication policy
defined on database C<database>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_series

    $cv = AE::cv;
    $db->show_series(
        database => 'mydb',

        # raw query
        q => "SHOW SERIES FROM cpu_load"
            ." WHERE host = 'server02'"
            ." ORDER BY region"
            ." LIMIT 10 OFFSET 3",

        # or query created from arguments
        measurement => 'cpu_load',
        where => q{host = 'server02'},

        order_by => 'region',

        limit => 10,
        offset => 3,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list series: @_");
        }
    );
    my @series = $cv->recv;
    print "$_\n" for @series;

Returns names of series from database C<database> using optional measurement C<measurement>
and optional C<where> clause.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_measurements

    $cv = AE::cv;
    $db->show_measurements(
        database => 'mydb',

        # raw query
        q => "SHOW MEASUREMENTS WITH MEASUREMENT =~ /cpu_load.*/"
            ." WHERE host = 'server02'"
            ." ORDER BY region"
            ." LIMIT 10 OFFSET 3",

        # or query created from arguments
        measurement => '/cpu_load.*/',
        where => q{host = 'server02'},

        order_by => 'region',

        limit => 10,
        offset => 3,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list measurements: @_");
        }
    );
    my @measurements = $cv->recv;
    print "$_\n" for @measurements;

Returns names of measurements from database C<database>, optionally filtered with
regular expression C<measurement> and optional C<where> clause.
If the C<measurement> is not enclosed in C<//> then it will be treated as name of
the measurement.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_tag_keys

    $cv = AE::cv;
    $db->show_tag_keys(
        database => 'mydb',

        # raw query
        q => "SHOW TAG KEYS FROM cpu_load WHERE host = 'server02' LIMIT 10 OFFSET 3",

        # or query created from arguments
        measurement => 'cpu_load',
        where => q{host = 'server02'},

        limit => 10,
        offset => 3,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag keys: @_");
        }
    );
    my $tag_keys = $cv->recv;
    for my $measurement ( sort keys %{ $tag_keys } ) {
        print "Measurement: $measurement\n";
        print " * $_\n" for @{ $tag_keys->{$measurement} };
    }

Returns a hash reference with measurements as keys and their unique tag keys
as values from database C<database> and optional measurement C<measurement>,
optionally filtered by the C<where> clause, grouped by C<group_by> with number
of results limited to C<limit> with offset C<offset>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_tag_values

    $cv = AE::cv;
    $db->show_tag_values(
        database => 'mydb',

        # raw query
        q => q{SHOW TAG VALUES FROM cpu_load WITH KEY = "host"},

        # or query created from arguments
        measurement => 'cpu_load',

        # single key
        key => q{"host"},
        # or a list of keys
        keys => [qw( "host" "region" )],

        limit => 10,
        offset => 3,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag values: @_");
        }
    );
    my $tag_values = $cv->recv;
    for my $measurement ( sort keys %{ $tag_values } ) {
        print "Measurement: $measurement\n";
        for my $tag_key ( sort keys %{ $tag_values->{$measurement} } ) {
            print "  Tag key: $tag_key\n";
            print "   * $_\n" for @{ $tag_values->{$measurement}->{$tag_key} };
        }
    }

Returns a hash reference with measurements as keys and their unique tag values
as values from database C<database> and optional measurement C<measurement>
from a single tag key C<key> or a list of tag keys C<keys> with number
of results limited to C<limit> with offset C<offset>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_field_keys

    $cv = AE::cv;
    $db->show_field_keys(
        database => 'mydb',

        # raw query
        q => "SHOW FIELD KEYS FROM cpu_load",

        # or query created from arguments
        measurement => 'cpu_load',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list field keys: @_");
        }
    );
    my $field_keys = $cv->recv;
    for my $measurement ( sort keys %{ $field_keys } ) {
        print "Measurement: $measurement\n";
        for my $field ( @{ $field_keys->{$measurement} } ) {
            print "  Key:  $field->{key}\n";
            print "  Type: $field->{type}\n";
        }
    }

Returns a hash reference with measurements as keys and their field keys names
and type as values from database C<database> and optional measurement
C<measurement>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 User Management

=head3 create_user

    $cv = AE::cv;
    $db->create_user(
        # raw query
        q => "CREATE USER jdoe WITH PASSWORD 'mypassword' WITH ALL PRIVILEGES",

        # or query created from arguments
        username => 'jdoe',
        password => 'mypassword',
        all_privileges => 1,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to create user: @_");
        }
    );
    $cv->recv;

Creates user with C<username> and C<password>. If flag C<all_privileges> is set
to true created user will be granted cluster administration privileges.

Note: C<password> will be automatically enclosed in single quotes.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 set_user_password

    $cv = AE::cv;
    $db->set_user_password(
        # raw query
        q => "SET PASSWORD FOR jdoe = 'otherpassword'",

        # or query created from arguments
        username => 'jdoe',
        password => 'otherpassword',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to set password: @_");
        }
    );
    $cv->recv;

Sets password to C<password> for the user identified by C<username>.

Note: C<password> will be automatically enclosed in single quotes.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_users

    $cv = AE::cv;
    $db->show_users(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list users: @_");
        }
    );
    my @users = $cv->recv;
    for my $u ( @users ) {
        print "Name: $u->{user}\n";
        print "Admin?: $u->{admin}\n";
    }

Returns a list of hash references with keys C<user> and C<admin> for each
defined user.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 grant_privileges

    $cv = AE::cv;
    $db->grant_privileges(
        # raw query
        q => "GRANT ALL ON mydb TO jdoe",

        # or query created from arguments
        username => 'jdoe',

        # privileges at single database
        database => 'mydb',
        access => 'ALL',

        # or to grant cluster administration privileges
        all_privileges => 1,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to grant privileges: @_");
        }
    );
    $cv->recv;

Grants to user C<username> access C<access> on database C<database>.
If flag C<all_privileges> is set it grants cluster administration privileges
instead.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_grants

    $cv = AE::cv;
    $db->show_grants(
        # raw query
        q => "SHOW GRANTS FOR jdoe",

        # or query created from arguments
        username => 'jdoe',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list users: @_");
        }
    );
    my @grants = $cv->recv;
    for my $g ( @grants ) {
        print "Database: $g->{database}\n";
        print "Privilege: $g->{privilege}\n";
    }

Returns a list of hash references with keys C<database> and C<privilege>
describing the privileges granted for database to given user.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 revoke_privileges

    $cv = AE::cv;
    $db->revoke_privileges(
        # raw query
        q => "REVOKE WRITE ON mydb FROM jdoe",

        # or query created from arguments
        username => 'jdoe',

        # privileges at single database
        database => 'mydb',
        access => 'WRITE',

        # or to revoke cluster administration privileges
        all_privileges => 1,

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to revoke privileges: @_");
        }
    );
    $cv->recv;

Revokes from user C<username> access C<access> on database C<database>.
If flag C<all_privileges> is set it revokes cluster administration privileges
instead.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_user

    $cv = AE::cv;
    $db->drop_user(
        # raw query
        q => "DROP USER jdoe",

        # or query created from arguments
        username => 'jdoe',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop user: @_");
        }
    );
    $cv->recv;

Drops user C<username>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 Continuous Queries

=head3 create_continuous_query

    $cv = AE::cv;
    $db->create_continuous_query(
        # raw query
        q => 'CREATE CONTINUOUS QUERY per5minutes ON mydb'
            .' RESAMPLE EVERY 10s FOR 10m'
            .' BEGIN'
            .' SELECT MEAN(value) INTO "cpu_load_per5m" FROM cpu_load GROUP BY time(5m)'
            .' END',

        # or query created from arguments
        database => 'mydb',
        name => 'per5minutes',
        every => '10s',
        for => '2m',
        query => 'SELECT MEAN(value) INTO "cpu_load_per5m" FROM cpu_load GROUP BY time(5m)',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to create continuous query: @_");
        }
    );
    $cv->recv;

Creates new continuous query named by C<name> on database C<database> using
query C<query>. Optional C<every> and C<for> define the resampling
times.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_continuous_query

    $cv = AE::cv;
    $db->drop_continuous_query(
        # raw query
        q => 'DROP CONTINUOUS QUERY per5minutes ON mydb',

        # or query created from arguments
        database => 'mydb',
        name => 'per5minutes',

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop continuous query: @_");
        }
    );
    $cv->recv;

Drops continuous query named by C<name> on database C<database>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_continuous_queries

    $cv = AE::cv;
    $db->show_continuous_queries(
        database => 'mydb',

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list continuous queries: @_");
        }
    );
    my $continuous_queries = $cv->recv;
    for my $database ( sort keys %{ $continuous_queries } ) {
        print "Database: $database\n";
        for my $s ( @{ $continuous_queries->{$database} } ) {
            print " Name: $s->{name}\n";
            print " Query: $s->{query}\n";
        }
    }

Returns a list of hash references with keys C<name> and C<query> for each
continuous query defined on database C<database>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 Kapacitor integration

Subscriptions tell InfluxDB to send all the data it receives to Kapacitor.

=head3 create_subscription

    $cv = AE::cv;
    $db->create_subscription(
        # raw query
        q => 'CREATE SUBSCRIPTION alldata ON "mydb"."default"'
            ." DESTINATIONS ANY 'udp://h1.example.com:9090', 'udp://h2.example.com:9090'",

        # or query created from arguments
        name => q{alldata},
        database => q{"mydb"},
        rp => q{"default"},
        mode => "ANY",
        destinations => [
            q{'udp://h1.example.com:9090'},
            q{'udp://h2.example.com:9090'}
        ],
        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to create subscription: @_");
        }
    );
    $cv->recv;

Creates a new subscription C<name> on database C<database> with retention policy
C<rp> with mode C<mode> to destinations provided as C<destinations>. The
C<destinations> could be either a single scalar value or array reference to a
list of host.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 show_subscriptions

    $cv = AE::cv;
    $db->show_subscriptions(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list shards: @_");
        }
    );
    my $subscriptions = $cv->recv;
    for my $database ( sort keys %{ $subscriptions } ) {
        print "Database: $database\n";
        for my $s ( @{ $subscriptions->{$database} } ) {
            print " Name: $s->{name}\n";
            print " Retention Policy: $s->{retention_policy}\n";
            print " Mode: $s->{mode}\n";
            print " Destinations:\n";
            print "  * $_\n" for @{ $s->{destinations} || [] };
        }
    }

Returns a hash reference with database name as keys and their shards as values.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head3 drop_subscription

    $cv = AE::cv;
    $db->drop_subscription(
        # raw query
        q => 'DROP SUBSCRIPTION "alldata" ON "mydb"."default"',

        # or query created from arguments
        name => q{"alldata"},
        database => q{"mydb"},
        rp => q{"default"},

        # callbacks
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to drop subscription: @_");
        }
    );
    $cv->recv;

Drops subscription C<name> on database C<database> with retention policy
C<rp>.

The required C<on_success> code reference is executed if request was successful,
otherwise executes the required C<on_error> code reference.

=head2 Other

=head3 query

    $cv = AE::cv;
    $db->query(
        method => 'GET',
        query => {
            db => 'mydb',
            q => 'SELECT * FROM cpu_load',
        },
        on_response => $cv,
    );
    my ($response_data, $response_headers) = $cv->recv;

Executes an arbitrary query using provided in C<query> arguments.

The required C<on_response> code reference is executed with the raw response
data and headers as parameters.

=head1 CAVEATS

Following the optimistic nature of InfluxDB this modules does not validate any
arguments. Also quoting and escaping special characters is to be done by the
user of this library.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
