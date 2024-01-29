# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Service;

use v5.10;
use strict;
use warnings;

use Carp;
use JSON;
use URI;
use URI::Escape;
use Encode;
use Scalar::Util qw(weaken);
use List::Util qw(all);
use UUID::Tiny ':std';
use DateTime::Format::ISO8601;

use Data::URIID::Result;
use Data::URIID::Colour;
use Data::URIID::Future;

our $VERSION = v0.05;

my @musicbrainz_wikidata_relations = qw(P434 P435 P436 P966 P982 P1004 P1330 P1407 P4404 P5813 P6423 P8052);

my $config_wikidata = {
    type => 'wikidata-identifier',
    idmap => {
        P213   => 'isni',
        P214   => 'viaf-identifier',
        P227   => 'gnd-identifier',
        P356   => 'doi',
        P402   => 'osm-relation',
        P409   => 'libraries-australia-identifier',
        P535   => 'find-a-grave-identifier',
        P648   => 'open-library-identifier',
        P1256  => 'iconclass-identifier',
        P1315  => 'nla-trove-people-identifier',
        P1566  => 'geonames-identifier',
        P1651  => 'youtube-video-identifier',
        P2041  => 'ngv-artist-identifier',
        P2949  => 'wikitree-person-identifier',
        P3916  => 'unesco-thesaurus-identifier',
        P4684  => 'ngv-artwork-identifier',
        P6735  => 'tww-artist-identifier',
        P6804  => 'agsa-creator-identifier',
        P7033  => 'aev-identifier',
        P7704  => 'europeana-entity-identifier',
        P8168  => 'factgrid-identifier',
        P8406  => 'grove-art-online-identifier',
        P9575  => 'amc-artist-identifier',
        P10086 => 'a-p-and-p-artist-identifier',
        P10689 => 'osm-way',
        P10787 => 'factgrid-identifier',
        P11693 => 'osm-node',
        (map {$_ => 'musicbrainz-identifier'} @musicbrainz_wikidata_relations),
    },
    endpoint => {
        sparql      => 'https://query.wikidata.org/sparql',
        entitydata  => 'https://www.wikidata.org/wiki/Special:EntityData/%s.json?flavor=dump',
    },
    prefix => 'http://www.wikidata.org/entity/',
    uuid_relations => \@musicbrainz_wikidata_relations,
    special_ids => [
        {
            property => 'P1711',
            type => 'british-museum-term',
            to_service => sub {($_[0] =~ /^BIOG([1-9][0-9]+)$/)[0]},
            from_service => sub {sprintf('BIOG%u', $_[0])},
        },
    ],
    attributes => [
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub { return ($c->[1] => {'*' => $_[0]})},
                }} (
                [P487  => 'icon_text'],     # 'Unicode character'
                [P1163 => 'media_subtype'], # 'MIME type'
            )),
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub {_online_lookup__wikibase__from_service__datetime($c->[1] => @_)},
            }} (
                [P569 => 'date_of_birth'],
                [P570 => 'date_of_death'],
            )),
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub {
                    my ($value, $config) = @_;
                    return ($c->[1] => {'*' => URI->new($value)}) if defined $value;
                    return ();
                },
            }} (
                [P856 => 'website'], # 'official website'
            )),
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub {
                    my ($value, $config) = @_;
                    return ($c->[1] => {'*' => URI->new($config->{prefix} . $value->{id})}) if defined $value->{id};
                    return ();
                },
            }} (
                [P21  => 'sex_or_gender'], # 'sex or gender'
                [P376 => 'space_object'],  # 'located on astronomical body'
            )),
        (map {my $c = $_; {
                property => $c->[0],
                list_value => sub {
                    my ($value, $config) = @_;
                    return ($c->[1] => [[URI->new($config->{prefix} . $value->{id})]]) if defined $value->{id};
                    return ();
                },
            }} (
                [P31  => 'roles'], # 'instance of'
            )),
        {   # 'sRGB colour hex triplet'
            property => 'P465',
            from_service => sub {
                my ($value) = @_;
                return (displaycolour => {'*' => Data::URIID::Colour->new(rgb => sprintf('#%s', uc($value)))}) if $value =~ /^[0-9a-f-AF]{6}$/;
                return ();
            },
        },
        {   # 'coordinate location'
            property => 'P625',
            from_service => \&_online_lookup__wikibase__from_service__coordinate,
        },
    ],
};

my $config_factgrid = {
    type => 'factgrid-identifier',
    idmap => {
        P76  => 'gnd-identifier',
        P378 => 'viaf-identifier',
        P980 => 'iconclass-identifier',
    },
    endpoint => {
        sparql      => 'https://database.factgrid.de/sparql',
        entitydata  => 'https://database.factgrid.de/wiki/Special:EntityData/%s.json?flavor=dump',
    },
    prefix => 'https://database.factgrid.de/entity/',
    attributes => [
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub {_online_lookup__wikibase__from_service__datetime($c->[1] => @_)},
            }} (
                [P38 => 'date_of_death'],
                [P77 => 'date_of_birth'],
            )),
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub {
                    my ($value, $config) = @_;
                    return ($c->[1] => {'*' => URI->new($value)}) if defined $value;
                    return ();
                },
            }} (
                [P156 => 'website'], # 'Online presence'
            )),
        (map {my $c = $_; {
                property => $c->[0],
                from_service => sub {
                    my ($value, $config) = @_;
                    return ($c->[1] => {'*' => URI->new($config->{prefix} . $value->{id})}) if defined $value->{id};
                    return ();
                },
            }} (
                [P154 => 'sex_or_gender'], # 'Gender'
                [P625 => 'sex_or_gender'], # 'Predominant gender usage'
            )),
        {   # 'Coordinate location'
            property => 'P48',
            from_service => \&_online_lookup__wikibase__from_service__coordinate,
        },
        {   # 'Hex color'
            property => 'P696',
            from_service => sub {
                my ($value) = @_;
                return (displaycolour => {'*' => Data::URIID::Colour->new(rgb => sprintf('#%s', uc($value)))}) if $value =~ /^[0-9a-f-AF]{6}$/;
                return ();
            },
        },
    ],
};

my @fellig_types = qw(fellig-identifier fellig-box-number uuid oid uri wikidata-identifier e621-post-identifier wikimedia-commons-identifier british-museum-term musicbrainz-identifier gnd-identifier e621tagtype);

my %attrmap_osm = (
    name        => 'displayname',
    description => 'description',
);

my %own_metadata = (
    service => {
        'wikidata'          => {
            'displayname' => {'*' => 'Wikidata'},
        },
        'fellig'            => {
            'displayname' => {'*' => 'Fellig.org'},
        },
        'youtube'           => {},
        'youtube-nocookie'  => {},
        'dropbox'           => {},
        '0wx'               => {},
        'e621'              => {},
        'dnb'               => {
            'displayname' => {'*' => 'Deutsche Nationalbibliothek'},
        },
        'britishmuseum'     => {
            'displayname' => {'*' => 'British Museum'},
        },
        'musicbrainz'       => {
            'displayname' => {'*' => 'MusicBrainz'},
        },
        'wikimedia-commons' => {
            'displayname' => {'*' => 'Wikimedia Commons'},
        },
        'wikipedia'         => {
            'displayname' => {'*' => 'Wikipedia'},
        },
        'noembed.com'       => {},
        'osm'               => {
            'displayname' => {'*' => 'OpenStreetMap'},
        },
        'overpass'          => {},
        'xkcd'              => {},
        'Data::URIID'       => {},
        'viaf'              => {
            'displayname' => {'*' => 'Virtual International Authority File'},
        },
        'europeana'         => {},
        'open-library'      => {
            'displayname' => {'*' => 'Open Library'},
        },
        'ngv'               => {
            'displayname' => {'*' => 'National Gallery of Victoria'},
        },
        'geonames'          => {},
        'find-a-grave'      => {
            'displayname' => {'*' => 'Find a Grave'},
        },
        'nla'               => {
            'displayname' => {'*' => 'National Library of Australia'},
        },
        'agsa'              => {
            'displayname' => {'*' => 'Art Gallery of South Australia'},
        },
        'amc'               => {
            'displayname' => {'*' => 'Australian Music Centre'},
        },
        'a-p-and-p'         => {
            'displayname' => {'*' => 'Australian Prints + Printmaking'},
        },
        'tww'               => {
            'displayname' => {'*' => 'The Watercolour World'},
        },
        'factgrid'          => {
            'displayname' => {'*' => 'FactGrid'},
        },
        'grove-art-online'  => {
            'displayname' => {'*' => 'Grove Art Online'},
        },
        'wikitree'          => {
            'displayname' => {'*' => 'WikiTree'},
        },
        'doi'               => {
            'displayname' => {'*' => 'doi.org'},
        },
    },
);

sub _own_well_known {
    state $res;

    return $res if defined $res;

    my %own_well_known = (
        'wikidata-identifier' => {
            Q2 => {
                ids => {
                    'tagname' => 'Earth',
                    'aev-identifier' => 'scot/1917',
                    'factgrid-identifier' => 'Q176134',
                    'gnd-identifier' => '1135962553',
                    'viaf-identifier' => '6270149919445006650001',
                    'open-library-identifier' => 'earth_(planet)',
                    'unesco-thesaurus-identifier' => 'concept4083',
                    'geonames-identifier' => '6295630',
                },
                attributes => {
                    'displayname' => {'*' => 'Earth'},
                    'description' => {'*' => 'third planet from the sun in the solar system'},
                },
            },
            Q405        => {attributes => {displayname => {'*' => 'Moon'}}},
            Q6581072    => {attributes => {displayname => {'*' => 'female'}}},
            Q6581097    => {attributes => {displayname => {'*' => 'male'}}}
        },
        'factgrid-identifier' => {
            Q17  => {attributes => {displayname => {'*' => 'Female gender'}}},
            Q18  => {attributes => {displayname => {'*' => 'Male gender'}}},
        },
        'media-subtype-identifier' => {
            (map {$_ => {
                        attributes => {
                            displayname => {'*' => $_},
                        },
                        ids => {
                            'uuid'                      => Data::URIID::Result->_media_subtype_to_uuid($_),
                            'media-subtype-identifier'  => $_,
                            'tagname'                   => $_,
                        },
                    }}
                # List copied from tags-universal:
                qw(
                application/gzip
                application/http
                application/json
                application/ld+json
                application/octet-stream
                application/ogg
                application/pdf
                application/vnd.debian.binary-package
                application/vnd.oasis.opendocument.base
                application/vnd.oasis.opendocument.chart
                application/vnd.oasis.opendocument.chart-template
                application/vnd.oasis.opendocument.formula
                application/vnd.oasis.opendocument.formula-template
                application/vnd.oasis.opendocument.graphics
                application/vnd.oasis.opendocument.graphics-template
                application/vnd.oasis.opendocument.image
                application/vnd.oasis.opendocument.image-template
                application/vnd.oasis.opendocument.presentation
                application/vnd.oasis.opendocument.presentation-template
                application/vnd.oasis.opendocument.spreadsheet
                application/vnd.oasis.opendocument.spreadsheet-template
                application/vnd.oasis.opendocument.text
                application/vnd.oasis.opendocument.text-master
                application/vnd.oasis.opendocument.text-master-template
                application/vnd.oasis.opendocument.text-template
                application/vnd.oasis.opendocument.text-web
                application/xhtml+xml
                application/xml
                audio/flac
                audio/matroska
                audio/ogg
                image/gif
                image/jpeg
                image/png
                image/svg+xml
                image/webp
                message/http
                text/html
                text/plain
                video/matroska
                video/matroska-3d
                video/ogg
                video/webm
                )),
        },
    );

    foreach my $id (keys %{$own_well_known{'wikidata-identifier'}}) {
        my $uuid = create_uuid_as_string(UUID_SHA1, '9e10aca7-4a99-43ac-9368-6cbfa43636df', lc $id);
        $own_well_known{uuid}{$uuid} = $own_well_known{'wikidata-identifier'}{$id};
    }

    {
        my $uuids = $own_well_known{uuid} //= {};
        foreach my $id_type (keys %own_well_known) {
            foreach my $entry (values %{$own_well_known{$id_type}}) {
                next unless defined $entry->{ids};
                next unless defined $entry->{ids}{uuid};
                $uuids->{$entry->{ids}{uuid}} //= $entry;
            }
        }
    }

    return $res = \%own_well_known;
}


# Private method:
sub new {
    my ($pkg, %opts) = @_;
    weaken($opts{extractor});
    return bless \%opts, $pkg;
}

# Private helper:
sub _is_online {
    my ($self) = @_;
    return $self->online && $self->extractor->online;
}

# Private method:
sub _online_lookup {
    my ($self, $result, %opts) = @_;
    my $func;

    return undef unless $self->_is_online;
    $func = $self->can(sprintf('_online_lookup__%s', $self->name =~ tr/\.:\-/_/r));
    return undef unless $func;

    return $self->$func($result, %opts);
}

# Private method:
sub _offline_lookup {
    my ($self, $result, %opts) = @_;
    my $func;

    $func = $self->can(sprintf('_offline_lookup__%s', $self->name =~ tr/\.:\-/_/r));
    return undef unless $func;

    return $self->$func($result, %opts);
}


#@returns Data::URIID
sub extractor {
    my ($self) = @_;
    return $self->{extractor} // croak(sprintf('Invalid access to %s belonging to no longer existing instance of Data::URIID', __PACKAGE__));
}


sub ise {
    my ($self) = @_;
    return $self->{ise};
}


sub name {
    my ($self) = @_;
    return $self->{name} //= $self->extractor->ise_to_name(service => $self->ise);
}


sub online {
    my ($self, $new_value) = @_;

    if (scalar(@_) == 2) {
        $self->{online} = !!$new_value;
    }

    return $self->{online};
}


sub setting {
    my ($self, $setting, $new_value) = @_;

    $self->{setting} //= {};

    if (scalar(@_) == 3) {
        $self->{setting}{$setting} = $new_value;
    }

    return $self->{setting}{$setting};
}



# Private helper:
sub _extra_lookup_services {
    return {
        'wikidata'              => [values(%{$config_wikidata->{idmap}}), qw(wikidata-identifier british-museum-term uuid)],
        'wikimedia-commons'     => [qw(wikimedia-commons-identifier)],
        'fellig'                => \@fellig_types,
        'noembed.com'           => [qw(youtube-video-identifier)],
        'osm'                   => [qw(osm-node osm-way osm-relation)],
        'overpass'              => [qw(wikidata-identifier)],
        'Data::URIID'           => [
            qw(uuid oid uri),                               # ISE,
            keys %{_own_well_known()},
        ],
        'factgrid'              => [values(%{$config_factgrid->{idmap}}), qw(factgrid-identifier)],
        'doi'                   => [qw(doi)],
        'iconclass'             => ['iconclass-identifier'],
        'xkcd'                  => ['xkcd-num'],
    }
}

# Private helper:
sub _get_json {
    my ($self, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $f = $opts{options_provider} // Data::URIID::Future->done(\%opts);

    $f = $f->then(sub {
            %opts = (%opts, %{$_[0]});

            if ($opts{bail_out}) {
                return undef;
            }

            if (defined(my $local_override = $opts{local_override})) {
                if (defined(my $local_override_dir = $self->setting('local_override_dir'))) {
                    my ($path, @args) = @{$local_override};

                    if (all { defined } @args) {
                        my $data;

                        $path =~ s/%s/uri_escape_utf8(shift(@args))/ge;
                        $path = $local_override_dir.'/'.$path;

                        $data = $self->_get_json_file($path);
                        return $data if defined $data;
                    }
                }
            }
            return undef;
        });

    return Data::URIID::Future->get_json(elder => $f, extractor => $extractor, uri => sub {
            if ($opts{bail_out}) {
                return undef;
            }

            my $url = $opts{url};
            if (defined(my $query = $opts{query})) {
                $url = ref($url) ? $url->clone : URI->new($url);
                $url->query_form($url->query_form, %{$query});
            }

            return $url;
        });
}

# Private helper:
sub _get_json_file {
    my ($self, $filename) = @_;
    my $fh = eval { open(my $fh, '<', $filename) or die $!; $fh; } // eval { open(my $fh, '<:gzip', $filename.'.gz') or die $!; $fh; };

    return undef unless $fh;

    return eval {
        local $/ = undef;
        from_json(scalar <$fh>);
    };
}

# Private helper:
sub _get_uriid_decompiled_types_json {
    my ($self) = @_;
    state $json = {types => {
            'oid'                   => {alias_for => 'd08dc905-bbf6-4183-b219-67723c3c8374'},
            'uri'                   => {alias_for => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439'},
            'uuid'                  => {alias_for => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31'},
            'wikidata-identifier'   => {alias_for => 'ce7aae1e-a210-4214-926a-0ebca56d77e3'},
        }};
    return state $decompiled = do {{
            forward => $json,
            backward => {map {$json->{types}{$_}{alias_for} => $_} grep {defined $json->{types}{$_}{alias_for}} keys %{$json->{types}}},
        }};
}

# Private lookup drivers:
sub _offline_lookup__Data__URIID {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $ise_order = $result->{primary}{ise_order} // [qw(uuid oid uri)];
    state $own_well_known = _own_well_known();
    my %attr;
    my %ids;
    my @found;

    outer:
    foreach my $ise_type (@{$ise_order}) {
        my $ise = eval {$result->id($ise_type)} // next;
        foreach my $type (qw(service type action)) {
            my $name = eval { $extractor->ise_to_name($type => $ise) } // next;
            my $displayname = $attr{displayname} //= {};
            $displayname->{'*'} //= $name;
            push(@found, {attributes => $own_metadata{$type}{$name}});
            last outer;
        }
    }

    foreach my $id_type (keys %{$own_well_known}) {
        my $id = eval {$result->id($id_type, _no_convert => 1)};
        if (defined $id) {
            if (defined(my $entry = $own_well_known->{$id_type}{$id})) {
                push(@found, $entry);
            }
        }
    }

    foreach my $found (@found) {
        my $attributes = $found->{attributes};
        my $ids        = $found->{ids};

        foreach my $attr (keys %{$attributes//{}}) {
            $attr{$attr} //= {};
            foreach my $key (keys %{$attributes->{$attr}}) {
                $attr{$attr}{$key} = $attributes->{$attr}{$key};
            }
        }

        foreach my $id_type (keys %{$ids//{}}) {
            $ids{$id_type} //= $ids->{$id_type};
        }
    }

    {
        my %res;
        $res{id} = \%ids if scalar keys %ids;
        $res{attributes} = \%attr if scalar keys %attr;
        return Data::URIID::Future->done(\%res);
    }
}

sub _online_lookup__wikidata {
    my ($self, $result) = @_;
    return _online_lookup__wikibase($self, $result, $config_wikidata);
}

sub _online_lookup__factgrid {
    my ($self, $result) = @_;
    return _online_lookup__wikibase($self, $result, $config_factgrid);
}

sub _online_lookup__wikibase {
    my ($self, $result, $config) = @_;
    my $id = eval {$result->id($config->{type})};
    my $f;

    if (defined $id) {
        $f = Data::URIID::Future->done($id);
    } else {
        $f = $self->_online_lookup__wikibase__stage_0($result, $config);
    }

    return $self->_online_lookup__wikibase__stage_1($result, $f, $config);

    return undef;
}

sub _online_lookup__wikibase__stage_0 {
    my ($self, $result, $config) = @_;
    my @ids;

    foreach my $property (keys %{$config->{idmap}}) {
        my $id = eval {$result->id($config->{idmap}{$property})};
        if (defined $id) {
            if ($id !~ /['"]/) {
                push(@ids, sprintf('?item wdt:%s "%s"', $property, $id));
            }
        }
    }

    foreach my $special (@{$config->{special_ids}}) {
        my $id = eval {$result->id($special->{type})};
        if (defined $id) {
            push(@ids, sprintf('?item wdt:%s "%s"', $special->{property}, $special->{to_service}->($id)));
        }
    }

    # UUID is special:
    {
        my $id = eval {$result->id('uuid')};
        if (defined $id) {
            foreach my $property (@{$config->{uuid_relations}}) {
                push(@ids, sprintf('?item wdt:%s "%s"', $property, $id));
            }
        }
    }

    return undef unless scalar @ids;

    {
        my $q = sprintf('SELECT * WHERE { { %s } } LIMIT 1', join('} UNION {', @ids));
        return $self->_get_json(url => $config->{endpoint}{sparql}, query => {format => 'json', query => $q})->then(sub {
                my ($res) = @_;
                my $item = eval {$res->{results}{bindings}[0]{item}};
                return undef unless $item;
                return undef unless ($item->{type} // '') eq 'uri';
                if (($item->{value} // '') =~ m#^\Q$config->{prefix}\E([QP][1-9][0-9]*)$#) {
                    return $1;
                }
                die 'No ID';
            });
    }
}

sub _online_lookup__wikibase__stage_1 {
    my ($self, $result, $f, $config) = @_;
    my $id;
    $f = $f->then(sub {
            ($id) = @_;
            return {bail_out => 1} unless defined($id) && length($id);
            return {
                url => sprintf($config->{endpoint}{entitydata}, $id),
                local_override => ['%s.json', $id],
            };
        });
    return $self->_get_json(options_provider => $f)->then(sub {
            my ($data) = @_;
            my %ids = ($config->{type} => $id);
            my %attr;
            my %res = (id => \%ids, attributes => \%attr);

            $data = $data->{entities}{$id};

            $attr{displayname} = {map {$_ => $data->{labels}{$_}{value}}       keys %{$data->{labels}}};
            $attr{description} = {map {$_ => $data->{descriptions}{$_}{value}} keys %{$data->{descriptions}}};

            $res{wikidata_sitelinks} = $data->{sitelinks};
            foreach my $property (keys %{$config->{idmap}}) {
                foreach my $entry (@{$data->{claims}{$property} // []}) {
                    $ids{$config->{idmap}{$property}} = $entry->{mainsnak}{datavalue}{value};
                }
            }

            foreach my $special (@{$config->{special_ids}}) {
                foreach my $entry (@{$data->{claims}{$special->{property}} // []}) {
                    $ids{$special->{type}} //= $special->{from_service}->($entry->{mainsnak}{datavalue}{value});
                }
            }

            foreach my $attribute (@{$config->{attributes}}) {
                foreach my $entry (@{$data->{claims}{$attribute->{property}} // []}) {
                    if (defined $attribute->{from_service}) {
                        my %res = $attribute->{from_service}->($entry->{mainsnak}{datavalue}{value}, $config);
                        $attr{$_} //= $res{$_} foreach keys %res;
                    } elsif (defined $attribute->{list_value}) {
                        my %res = $attribute->{list_value}->($entry->{mainsnak}{datavalue}{value}, $config);
                        foreach my $key (keys %res) {
                            $attr{$key} //= [];
                            push(@{$attr{$key}}, @{$res{$key}});
                        }
                    }
                }
            }

            return \%res;
        });
}

sub _online_lookup__wikibase__from_service__datetime {
    my ($key, $value) = @_;
    my $precision = $value->{precision};

    #use Data::Dumper;
    #die Dumper $value;

    if ($precision >= 9) {
        my $dt = DateTime::Format::ISO8601->parse_datetime($value->{time} =~ s/^\+//r =~ s/-00-00T/-01-01T/r =~ s/-00T/-01T/r);
        my $val;

        if ($precision == 9) {
            $val = $dt->year;
        } elsif ($precision == 10) {
            $val = sprintf('%.4u-%.2u', $dt->year, $dt->month);
        } else {
            $val = $dt->ymd;
        }

        return ($key => $val);
    }
    return ();
}

sub _online_lookup__wikibase__from_service__coordinate {
    my ($value) = @_;
    my %attr;

    foreach my $subkey (qw(altitude latitude longitude)) {
        $attr{$subkey} = {'*' => $value->{$subkey} + 0} if defined $value->{$subkey};
    }
    $attr{space_object} = {'*' => URI->new($value->{globe})} if defined $value->{globe};

    return %attr;
}

sub _online_lookup__wikimedia_commons {
    my ($self, $result) = @_;

    return $self->_get_json(
        url => 'https://commons.wikimedia.org/w/api.php',
        query => {
            action      => 'query',
            titles      => $result->id,
            prop        => 'imageinfo',
            iiprop      => 'url|mime|size|sha1|canonicaltitle',
            iiurlwidth  => 240, # get thumbnail
            format      => 'json'
        }
    )->then( sub {
        my ($json) = @_;
        my $res = {
            'attributes' => {},
        };

        foreach my $page_id ( keys(%{ $json->{query}->{pages} }) ) { # only one item
            my $page = $json->{query}->{pages}->{$page_id};
            my $imageinfo = $page->{imageinfo}->[0];

            $res->{attributes}->{displayname}       = { '*' => $imageinfo->{canonicaltitle} };
            $res->{attributes}->{thumbnail}         = { '*' => URI->new($imageinfo->{thumburl}) };
            $res->{attributes}->{final_file_size}   = { '*' => int($imageinfo->{size}) };
            $res->{attributes}->{media_subtype}     = { '*' => $imageinfo->{mime} };
            $res->{digest}                          = { 'sha-1-160' => $imageinfo->{sha1} };
        }

        return $res;
    });
}

sub _online_lookup__fellig {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $f = Data::URIID::Future->new;
    my $h = $f;

    foreach my $type (@fellig_types) {
        my $id = eval {$result->id($type, _no_convert => 1)} // next;

        $h = $h->else(sub {
                $self->_get_json(url => sprintf('https://api.fellig.org/v0/overview/%s/%s', $type, uri_escape($id)), local_override => ['overview/%s/%s.json', $type, $id])->get // die
            });
    }

    $h = $h->then(sub {
            my ($json) = @_;
            foreach my $idx (@{$json->{main_result}}) {
                my $tag = $json->{tags}[$idx];
                my %ids;
                my %attr;
                my %res = (id => \%ids, attributes => \%attr, digest => $tag->{unvaried}{'final-file-hash'});

                foreach my $class (qw(unvaried varied)) {
                    # This is a trusted service, so we only check for the id types to be valid ISE
                    # but accept them all.
                    foreach my $relation ('ids', 'tag-linked-by') {
                        foreach my $idtype (keys %{$tag->{$class}{$relation}//{}}) {
                            if ($extractor->is_ise($idtype)) {
                                $ids{$idtype} //= $tag->{$class}{$relation}{$idtype}[0];
                            }
                        }
                    }

                    $attr{displayname}    = {'*' => $tag->{$class}{displayname}} if defined $tag->{$class}{displayname};
                    $attr{icon_text}      = {'*' => $tag->{$class}{icontext}} if defined $tag->{$class}{icontext};
                    $attr{displaycolour}  = {'*' => Data::URIID::Colour->new(rgb => $tag->{$class}{displaycolour})} if defined $tag->{$class}{displaycolour};
                    $attr{final_file_size}= {'*' => $tag->{$class}{'final-file-size'}} if defined $tag->{$class}{'final-file-size'};
                    $attr{icon}           = {'*' => URI->new($tag->{$class}{icon})} if defined $tag->{$class}{icon};

                    if (defined $tag->{$class}{'final-file-encoding'}) {
                        if (defined(my $wk = _own_well_known()->{uuid}{$tag->{$class}{'final-file-encoding'}})) {
                            if (defined(my $media_subtype = $wk->{ids}{'media-subtype-identifier'})) {
                                $attr{media_subtype} = $media_subtype;
                            }
                        }
                    }
                }

                return \%res;
            }
        });

    $f->die('rock it!');
    return $h;
}

sub _online_lookup__noembed_com {
    my ($self, $result) = @_;

    foreach my $service (qw(youtube)) {
        my $url = eval {$result->url(service => $service, action => 'render')} // eval {$result->url($service, action => 'embed')} // next;
        return $self->_get_json(url => 'https://noembed.com/embed', query => {url => $url})->then(sub {
                my ($json) = @_;
                my %attr;
                my %res = (attributes => \%attr);

                $attr{displayname} = {'*' => $json->{title}} if defined $json->{title};
                $attr{thumbnail}   = {'*' => URI->new($json->{thumbnail_url})} if defined $json->{thumbnail_url};

                return \%res;
            });
    }

    return undef;
}

sub _online_lookup__osm__handle {
    my ($self, $element) = @_;
    my $tags = $element->{tags} // {};
    my %ids;
    my %attr;
    my %res = (id => \%ids, attributes => \%attr);

    $attr{space_object} = {'*' => URI->new('http://www.wikidata.org/entity/Q2')}; # If it's on OSM it's on earth.
    $attr{latitude} = {'*' => $element->{lat} + 0} if defined $element->{lat};
    $attr{longitude} = {'*' => $element->{lon} + 0} if defined $element->{lon};
    $attr{altitude} = {'*' => $tags->{ele} + 0} if defined $tags->{ele};
    $attr{altitude} = {'*' => $tags->{'ele:wgs84'} + 0} if defined $tags->{'ele:wgs84'};
    #foreach my $subkey (qw(altitude latitude longitude)) {

    $ids{'wikidata-identifier'} = $tags->{wikidata} if defined $tags->{wikidata};

    foreach my $key (keys %attrmap_osm) {
        my %data;

        $data{'*'} = $tags->{$key} if defined $tags->{$key};
        foreach my $inkey (keys %{$tags}) {
            if ($inkey =~ /^\Q$key\E:([a-z]{2,3})$/) {
                $data{$1} = $tags->{$inkey};
            }
        }

        $attr{$attrmap_osm{$key}} = \%data if scalar keys %data;
    }

    return \%res;
}

sub _online_lookup__osm {
    my ($self, $result) = @_;
    my @list;

    foreach my $type (qw(node way relation)) {
        my $id = eval {$result->id('osm-'.$type)} // next;
        push(@list, $self->_get_json(url => sprintf('https://api.openstreetmap.org/api/0.6/%s/%s.json', $type, $id), local_override => ['%s/%s.json', $type, $id])->then(sub {
                    my ($json) = @_;
                    my $element = eval {$json->{elements}[0]} // return undef;
                    return $self->_online_lookup__osm__handle($element);
                }));
    }

    return Data::URIID::Future->combine(@list);
}

sub _online_lookup__overpass {
    my ($self, $result) = @_;
    my $id = $result->id('wikidata-identifier');
    return $self->_get_json(url => 'https://overpass-api.de/api/interpreter', query => {
            data => sprintf("[out:json][timeout:25];\n(node[\"wikidata\"=\"%s\"];\nway[\"wikidata\"=\"%s\"];\nrelation[\"wikidata\"=\"%s\"];\n);\nout;",
                $id, $id, $id,
            ),
        })->then(sub {
            my ($json) = @_;
            my $element = eval {$json->{elements}[0]} // return undef;
            my $res = $self->_online_lookup__osm__handle($element);
            my $type = $element->{type} // '';
            my $id_new = $element->{id} // '';

            if ($type eq 'node' || $type eq 'way' || $type eq 'relation') {
                if ($id_new =~ Data::URIID::Result->RE_UINT) {
                    $res->{id}->{'osm-'.$type} = $id_new;
                }
            }

            return $res;
        });
}

sub _online_lookup__xkcd {
    my ($self, $result, %opts) = @_;
    my $id = eval {$result->id('xkcd-num')};
    return $self->_get_json(url => $opts{metadata_url} // $result->url(service => 'xkcd', action => 'metadata'), local_override => ['%s.json', $id])->then(sub {
            my ($json) = @_;
            my %ids;
            my %attr;
            my %res = (id => \%ids, attributes => \%attr);

            $ids{'xkcd-num'} = int($json->{num}) if defined($json->{num}) && $json->{num} =~ Data::URIID::Result->RE_UINT;
            $attr{displayname} = {'*' => $json->{title}} if defined($json->{title}) && length($json->{title});

            return \%res;
        });
}

sub _online_lookup__doi {
    my ($self, $result, %opts) = @_;
    return $self->_get_json(url => $result->url(service => 'doi', action => 'metadata'))->then(sub {
            my ($json) = @_;
            my %attr;
            my %res = (attributes => \%attr);

            $attr{displayname} = {'*' => $json->{title}} if defined($json->{title}) && length($json->{title});

            return \%res;
        });
}

sub _online_lookup__iconclass {
    my ($self, $result, %opts) = @_;
    my $id = $result->id('iconclass-identifier');
    return $self->_get_json(url => $result->url(service => 'iconclass', action => 'metadata'), local_override => ['%s.jsonld', $id])->then(sub {
            my ($json) = @_;
            my $item = $json->{graph}[0] // return undef;
            my %displayname;
            my %res = (attributes => {displayname => \%displayname});

            foreach my $key ('prefLabel', 'dc:subject') {
                foreach my $entry (@{$item->{$key}}) {
                    $displayname{$entry->{lang}} //= $entry->{value};
                }
            }

            $displayname{'*'} = $displayname{en} // $displayname{de};

            return \%res;
        });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Service - Extractor for identifiers from URIs

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use Data::URIID;

    my $extractor = Data::URIID->new;
    my $result = $extractor->lookup( $URI );
    my $service = $result->attribute('service');

    my $name = $service->name;
    my $ise = $service->ise;

=head1 METHODS

=head2 extractor

    my $extractor = $service->extractor;

Returns the L<Data::URIID> object used to create this object.

=head2 ise

    my $ise = $service->ise;

Returns the ISE of this service.

=head2 name

    my $name = $service->name;

Returns the name of this service.

=head2 online

    my $online = $service->online( [ $new_value ] );

Gets or sets the online status of the service.
If this value is false no online operations are permitted.
In addition to this value being true the online value for the extractor need to be true.

See also L<"extractor">, L<Data::URIID/"online">.

=head2 setting

    my $value = $service->setting( $setting[, $new_value ] );

Gets or sets the setting C<$setting> the of the service.

The available settings depend on the service. This method may or may not die
when an invalid setting or an invalid value is provided.

Setting an invalid value may result in failures when this service is being used.

=head1 KNOWN/SUPPORTED SERVICES

The following is a non-complete list of services for which lookups (online or offline) are supported.
For a complete list of known services see L<Data::URIID/"known">.

=head2 C<wikidata> and C<wikipedia>

Wikidata is a large collection of machine readable data from all categories. It can act as a central connecting point
for several types of identifiers and services. It also provides Wikipedia pages for the given subject.

The C<wikipedia> services is only used for online lookups if a Wikipedia page is used as an input. It does not provide
lookup from identifiers to Wikipedia links.

In many cases you want to enable online lookups for both C<wikidata>, and C<wikipedia>. This is specifically true if you
want to work with very different services at once.

You commonly don't need to enable online lookups if all the services you're interested in use the same type of identifiers.

=head2 C<osm> and C<overpass>

The C<osm> service is mainly used to lookup from OpenStreetMap identifiers to other identifiers as well as attributes.
While the C<overpass> service is mostly used to look up from other identifiers to OpenStreetMap identifiers.

If you work with places you most likely want to enable online lookups on those services.

=head2 C<factgrid>

The C<factgrid> provides information mostly on history topics. It contains a large amount of data for historical figures.

=head2 C<Data::URIID>

This service is used to perform internal offline lookups on identifiers known to the module.
It mainly provides display names for ISEs used by this module.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
