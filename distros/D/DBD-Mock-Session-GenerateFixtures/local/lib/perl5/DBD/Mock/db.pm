package DBD::Mock::db;

use strict;
use warnings;

use List::Util qw( first );
use DBI;

our $imp_data_size = 0;

sub ping {
    my ($dbh) = @_;
    return $dbh->{mock_can_connect};
}

sub last_insert_id {
    my ($dbh) = @_;
    return $dbh->{mock_last_insert_id};
}

sub get_info {
    my ( $dbh, $attr ) = @_;
    $dbh->{mock_get_info} ||= {};
    return $dbh->{mock_get_info}{$attr};
}

sub table_info {
    my ( $dbh, @params ) = @_;

    my ($cataloge, $schema, $table, $type) = map { $_ || '' } @params[0..4];

    $dbh->{mock_table_info} ||= {};

    my @tables = @{ $dbh->{mock_table_info}->{ $cataloge }->{ $schema }->{ $table }->{ $type } || [] };

    my ($fieldNames, @rows) = map { [ @$_ ] } @tables;

    $fieldNames ||= [];

    my $sponge = DBI->connect('dbi:Sponge:', '', '' )
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    my $sth = $sponge->prepare("table_info", {
        rows          => \@rows,
        NUM_OF_FIELDS => scalar @$fieldNames,
        NAME          => $fieldNames
    }) or return $dbh->DBI::set_err( $sponge->err(), $sponge->errstr() );

    return $sth;
}

sub prepare {
    my ( $dbh, $statement ) = @_;

    unless ( $dbh->{mock_can_connect} ) {
        $dbh->set_err( 1, "No connection present" );
        return;
    }
    unless ( $dbh->{mock_can_prepare} ) {
        $dbh->set_err( 1, "Cannot prepare" );
        return;
    }
    $dbh->{mock_can_prepare}++ if $dbh->{mock_can_prepare} < 0;

    eval {
        foreach my $parser ( @{ $dbh->{mock_parser} } )
        {
            if ( ref($parser) eq 'CODE' ) {
                $parser->($statement);
            }
            else {
                $parser->parse($statement);
            }
        }
    };
    if ($@) {
        my $parser_error = $@;
        chomp $parser_error;
        $dbh->set_err( 1,
"Failed to parse statement. Error: ${parser_error}. Statement: ${statement}"
        );
        return;
    }

    my $sth = DBI::_new_sth( $dbh, { Statement => $statement } );
    $sth->trace_msg( "Preparing statement '${statement}'\n", 1 );
    my %track_params = ( statement => $statement );

    if ( my $session = $dbh->{mock_session} ) {
        eval {
            my $rs = $session->results_for($statement);
            if ( ref($rs) eq 'ARRAY' && scalar( @{$rs} ) > 0 ) {
                my $fields = @{$rs}[0];
                $track_params{return_data} = $rs;
                $track_params{fields}      = $fields;
                $sth->STORE( NAME          => $fields );
                $sth->STORE( NUM_OF_FIELDS => scalar @{$fields} );
            }
            else {
                $sth->trace_msg( "No return data set in DBH\n", 1 );
            }
        };

        if ($@) {
            $dbh->DBI::set_err( 1, "Session Error: $@. Statement: $statement" );
        }

    }

    else {
        # If we have available resultsets seed the tracker with one

        my ($rs, $callback, $failure, $prepare_attributes, $execute_attributes);

        if ( my $all_rs = $dbh->{mock_rs} ) {
            if ( my $by_name = defined $all_rs->{named}{$statement} ? $all_rs->{named}{$statement} : first { $statement =~ m/$_->{regexp}/ } @{ $all_rs->{matching} } ) {
                # We want to copy this, because it is meant to be reusable
                $rs = [ @{ $by_name->{results} } ];
                $callback = $by_name->{callback};
                $failure = $by_name->{failure};
                $prepare_attributes = $by_name->{prepare_attributes};
                $execute_attributes = $by_name->{execute_attributes};
            }
            else {
                $rs = shift @{ $all_rs->{ordered} };
                if (ref($rs) eq 'HASH') {
                    $callback = $rs->{callback};
                    $failure = $rs->{failure};
                    $prepare_attributes = $rs->{prepare_attributes};
                    $execute_attributes = $rs->{execute_attributes};
                    $rs = [ @{ $rs->{results} } ];
                }
            }
        }

        if ( ref($rs) eq 'ARRAY' && ( scalar( @{$rs} ) > 0 || $callback ) ) {
            my $fields = shift @{$rs};
            $track_params{return_data}        = $rs;
            $track_params{fields}             = $fields;
            $track_params{callback}           = $callback;
            $track_params{failure}            = $failure;
            $track_params{driver_attributes}  = $prepare_attributes;
            $track_params{execute_attributes} = $execute_attributes;

            if( $fields ) {
                $sth->STORE( NAME          => $fields );
                $sth->STORE( NUM_OF_FIELDS => scalar @{$fields});
            }

        }
        else {
            $sth->trace_msg( "No return data set in DBH\n", 1 );
        }

    }

    # do not allow a statement handle to be created if there is no
    # connection present.

    unless ( $dbh->FETCH('Active') ) {
        $dbh->set_err( 1, "No connection present" );
        return;
    }

    # This history object will track everything done to the statement
    my $history = DBD::Mock::StatementTrack->new(%track_params);
    $sth->STORE( mock_my_history => $history );

    # ...now associate the history object with the database handle so
    # people can browse the entire history at once, even for
    # statements opened and closed in a black box

    my $all_history = $dbh->FETCH('mock_statement_history');
    push @{$all_history}, $history;

    return $sth;
}

*prepare_cached = \&prepare;

{
    my $begin_work_commit;

    sub begin_work {
        my $dbh = shift;
        if ( $dbh->FETCH('AutoCommit') ) {
            $dbh->STORE( 'AutoCommit', 0 );
            $begin_work_commit = 1;
            my $sth = $dbh->prepare('BEGIN WORK')
              or return $dbh->set_err( 1, $DBI::errstr );
            my $rc = $sth->execute()
              or return $dbh->set_err( 1, $DBI::errstr );
            $sth->finish();
            return $rc;
        }
        else {
            return $dbh->set_err( 1,
                'AutoCommit is off, you are already within a transaction' );
        }
    }

    sub commit {
        my $dbh = shift;
        if ( $dbh->FETCH('AutoCommit') && $dbh->FETCH('Warn') ) {
            return $dbh->set_err( 1, "commit ineffective with AutoCommit" );
        }

        my $sth = $dbh->prepare('COMMIT')
          or return $dbh->set_err( 1, $DBI::errstr );
        my $rc = $sth->execute()
          or return $dbh->set_err( 1, $DBI::errstr );
        $sth->finish();

        if ($begin_work_commit) {
            $dbh->STORE( 'AutoCommit', 1 );
            $begin_work_commit = 0;
        }

        return $rc;
    }

    sub rollback {
        my $dbh = shift;
        if ( $dbh->FETCH('AutoCommit') && $dbh->FETCH('Warn') ) {
            return $dbh->set_err( 1, "rollback ineffective with AutoCommit" );
        }

        my $sth = $dbh->prepare('ROLLBACK')
          or return $dbh->set_err( 1, $DBI::errstr );
        my $rc = $sth->execute()
          or return $dbh->set_err( 1, $DBI::errstr );
        $sth->finish();

        if ($begin_work_commit) {
            $dbh->STORE( 'AutoCommit', 1 );
            $begin_work_commit = 0;
        }

        return $rc;
    }
}

# NOTE:
# this method should work in most cases, however it does
# not exactly follow the DBI spec in the case of error
# handling. I am not sure if that level of detail is
# really nessecary since it is a weird error conditon
# which causes it to fail anyway. However if you find you do need it,
# then please email me about it. I think it would be possible
# to mimic it by accessing the DBD::Mock::StatementTrack
# object directly.
sub selectcol_arrayref {
    my ( $dbh, $query, $attrib, @bindvalues ) = @_;

    # get all the columns ...
    my $a_ref = $dbh->selectall_arrayref( $query, $attrib, @bindvalues );

    # if we get nothing back, or dont get an
    # ARRAY ref back, then we can assume
    # something went wrong, and so return undef.
    return undef unless defined $a_ref || ref($a_ref) ne 'ARRAY';

    my @cols = 0;
    if ( ref $attrib->{Columns} eq 'ARRAY' ) {
        @cols = map { $_ - 1 } @{ $attrib->{Columns} };
    }

    # if we do get something then we
    # grab all the columns out of it.
    return [ map { @$_[@cols] } @{$a_ref} ];
}

sub FETCH {
    my ( $dbh, $attrib, $value ) = @_;
    $dbh->trace_msg("Fetching DB attrib '$attrib'\n");

    if ( $attrib eq 'Active' ) {
        return $dbh->{mock_can_connect};
    }
    elsif ( $attrib eq 'mock_all_history' ) {
        return $dbh->{mock_statement_history};
    }
    elsif ( $attrib eq 'mock_all_history_iterator' ) {
        return DBD::Mock::StatementTrack::Iterator->new(
            $dbh->{mock_statement_history} );
    }
    elsif ( $attrib =~ /^mock/ ) {
        return $dbh->{$attrib};
    }
    elsif ( $attrib =~ /^(private_|dbi_|dbd_|[A-Z])/ ) {
        $dbh->trace_msg(
            "... fetching non-driver attribute ($attrib) that DBI handles\n");
        return $dbh->SUPER::FETCH($attrib);
    }
    else {
        if ( $dbh->{mock_attribute_aliases} ) {
            if ( exists ${ $dbh->{mock_attribute_aliases}->{db} }{$attrib} ) {
                my $mock_attrib =
                  $dbh->{mock_attribute_aliases}->{db}->{$attrib};
                if ( ref($mock_attrib) eq 'CODE' ) {
                    return $mock_attrib->($dbh);
                }
                else {
                    return $dbh->FETCH($mock_attrib);
                }
            }
        }
        $dbh->trace_msg(
"... fetching non-driver attribute ($attrib) that DBI doesn't handle\n"
        );
        return $dbh->{$attrib};
    }
}

sub STORE {
    my ( $dbh, $attrib, $value ) = @_;

    my $printed_value = $value || 'undef';
    $dbh->trace_msg("Storing DB attribute '$attrib' with '$printed_value'\n");

    if ( $attrib eq 'AutoCommit' ) {

        # These are magic DBI values that say we can handle AutoCommit
        # internally as well
        $value = ($value) ? -901 : -900;
    }

    if ( $attrib eq 'mock_clear_history' ) {
        if ($value) {
            $dbh->{mock_statement_history} = [];
        }
        return [];
    }
    elsif ( $attrib eq 'mock_add_parser' ) {
        my $parser_type = ref($value);
        my $is_valid_parser;

        if ( $parser_type eq 'CODE' ) {
            $is_valid_parser++;
        }
        elsif ( $parser_type && $parser_type !~ /^(ARRAY|HASH|SCALAR)$/ ) {
            $is_valid_parser = eval { $parser_type->can('parse') };
        }

        unless ($is_valid_parser) {
            my $error =
                "Parser must be a code reference or object with 'parse()' "
              . "method (Given type: '$parser_type')";
            $dbh->set_err( 1, $error );
            return;
        }
        push @{ $dbh->{mock_parser} }, $value;
        return $value;
    }
    elsif ( $attrib eq 'mock_add_resultset' ) {
        my @copied_values;

        $dbh->{mock_rs} ||= {
            named   => {},
            ordered => [],
            matching => [],
        };

        if ( ref $value eq 'ARRAY' ) {
            @copied_values = @{$value};
            push @{ $dbh->{mock_rs}{ordered} }, \@copied_values;
        }
        elsif ( ref $value eq 'HASH' ) {
            my $name = $value->{sql};

            @copied_values = @{ $value->{results} ? $value->{results} : [] };

            if (not defined $name) {
                push @{ $dbh->{mock_rs}{ordered} }, {
                    results => \@copied_values,
                    callback => $value->{callback},
                    failure => ref($value->{failure}) ? [ @{ $value->{failure} } ] : undef,
                    prepare_attributes => $value->{prepare_attributes},
                    execute_attributes => $value->{execute_attributes},
                };
            }
            elsif ( ref $name eq "Regexp" ) {
                my $matching = {
                    regexp => $name,
                    results => \@copied_values,
                    callback => $value->{callback},
                    failure => ref($value->{failure}) ? [ @{ $value->{failure} } ] : undef,
                    prepare_attributes => $value->{prepare_attributes},
                    execute_attributes => $value->{execute_attributes},
                };
                # either replace existing match or push
                grep { $_->{regexp} eq $name && ($_ = $matching) } @{ $dbh->{mock_rs}{matching} }
                  or push @{ $dbh->{mock_rs}{matching} }, $matching;
            }
            else {
                $dbh->{mock_rs}{named}{$name} = {
                    results => \@copied_values,
                    callback => $value->{callback},
                    failure => ref($value->{failure}) ? [ @{ $value->{failure} } ] : undef,
                    prepare_attributes => $value->{prepare_attributes},
                    execute_attributes => $value->{execute_attributes},
                };
            }
        }
        else {
            die "Must provide an arrayref or hashref when adding ",
              "resultset via 'mock_add_resultset'.\n";
        }

        return \@copied_values;
    }
    elsif ( $attrib eq 'mock_start_insert_id' ) {
        if ( ref $value eq 'ARRAY' ) {
            $dbh->{mock_last_insert_ids} = {}
              unless $dbh->{mock_last_insert_ids};
            $dbh->{mock_last_insert_ids}{ $value->[0] } = $value->[1];
        }
        else {

            # we start at one minus the start id
            # so that the increment works
            $dbh->{mock_last_insert_id} = $value - 1;
        }

    }
    elsif ( $attrib eq 'mock_session' ) {
        ( ref($value) && UNIVERSAL::isa( $value, 'DBD::Mock::Session' ) )
          || die
"Only DBD::Mock::Session objects can be placed into the 'mock_session' slot\n"
          if defined $value;
        $dbh->{mock_session} = $value;
    }
    elsif ( $attrib =~ /^mock_(add_)?data_sources/ ) {
        $dbh->{Driver}->STORE( $attrib, $value );
    }
    elsif ( $attrib =~ /^mock_add_table_info$/ ) {
        $dbh->{mock_table_info} ||= {};

        if ( ref $value ne "HASH" ) {
            die "mock_add_table_info needs a hash reference"
        }

        my ( $cataloge, $schema, $table, $type ) = map { defined $_ ? $_ : '' } @$value{qw( cataloge schema table type )};

        $dbh->{mock_table_info}->{ $cataloge }->{ $schema }->{ $table }->{ $type } = $value->{table_info}; 
    }
    elsif ( $attrib =~ /^mock_clear_table_info$/ ) {
        if ( $value ) {
            $dbh->{mock_table_info} = {};
        }

        return {};
    }
    elsif ( $attrib =~ /^mock/ ) {
        return $dbh->{$attrib} = $value;
    }
    elsif ( $attrib =~ /^(private_|dbi_|dbd_|[A-Z])/ ) {
        $dbh->trace_msg(
"... storing non-driver attribute ($attrib) with value ($printed_value) that DBI handles\n"
        );
        return $dbh->SUPER::STORE( $attrib, $value );
    }
    else {
        $dbh->trace_msg(
"... storing non-driver attribute ($attrib) with value ($printed_value) that DBI won't handle\n"
        );
        return $dbh->{$attrib} = $value;
    }
}

sub DESTROY {
    my ($dbh) = @_;
    if ( my $session = $dbh->{mock_session} ) {
        if ( $session->has_states_left ) {
            die "DBH->finish called when session still has states left\n";
        }
    }
}

sub disconnect {
    my ($dbh) = @_;
    if ( my $session = $dbh->{mock_session} ) {
        if ( $session->has_states_left ) {
            die "DBH->finish called when session still has states left\n";
        }
    }
}

1;
