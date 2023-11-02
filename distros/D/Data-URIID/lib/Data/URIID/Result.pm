# Copyright (c) 2023 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Result;

use v5.10;
use strict;
use warnings;

use Carp;
use URI;
use URI::Escape;
use List::Util qw(any);
use UUID::Tiny ':std';
use Math::BigInt;

use Data::URIID::Service;

use constant {
    ISEORDER_UOR => ['uuid', 'oid', 'uri'],
    ISEORDER_RUO => ['uri', 'uuid', 'oid'],
};

use constant RE_UUID => qr/^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/;
use constant RE_UINT => qr/^[1-9][0-9]*$/;

our $VERSION = v0.03;

my %attributes = (
    action      => {
        source_type => 'ise',
    },
    displayname => {
        source_type => 'string',
    },
    displaycolour => {
        source_type => 'rgb',
    },
    description => {
        source_type => 'string',
    },
    icon_text => {
        source_type => 'string',
    },
    icon => {},
    thumbnail => {},
    final_file_size => {
        source_type => 'uint',
    },
    service => {},
    (map {$_ => {source_type => 'number'}} qw(altitude latitude longitude)),
    space_object => {},
);

my %id_conv = (
    uuid => [qw(wikidata-identifier fellig-identifier oid)],
    oid  => [qw(uuid)],
    uri  => [qw(wikidata-identifier uuid oid)],
);

my %lookup_services = (
    uuid                            => [qw(Data::URIID)],
    oid                             => [qw(Data::URIID)],
    uri                             => [qw(Data::URIID)],
    tagname                         => [], # none.
    'wikidata-identifier'           => [qw(wikidata)],
    'musicbrainz-identifier'        => [qw(musicbrainz)],
    'british-museum-term'           => [qw(britishmuseum)],
    'gnd-identifier'                => [qw(dnb)],
    'fellig-box-number'             => [qw(fellig)],
    'fellig-identifier'             => [qw(fellig)],
    'youtube-video-identifier'      => [qw(youtube)],
    e621tagtype                     => [qw(e621)],
    'wikimedia-commons-identifier'  => [qw(wikimedia-commons)],
    'e621-post-identifier'          => [qw(e621)],
    'xkcd-num'                      => [qw(xkcd)],
);

# Load extra services:
{
    my $extra = Data::URIID::Service->_extra_lookup_services;
    foreach my $service_name (keys %{$extra}) {
        foreach my $type (@{$extra->{$service_name}}) {
            $lookup_services{$type} //= [];
            push(@{$lookup_services{$type}}, $service_name);
        }
    }
}

my %url_templates = (
    wikidata => [
        ['wikidata-identifier' => 'https://www.wikidata.org/wiki/%s'                    => qr/^Q/  => [qw(documentation info edit)]],
        ['wikidata-identifier' => 'https://www.wikidata.org/wiki/Property:%s'           => qr/^P/  => [qw(documentation info edit)]],
        ['wikidata-identifier' => 'https://www.wikidata.org/wiki/Special:EntityData/%s' => undef() => [qw(metadata)]],
    ],
    'wikimedia-commons' => [
        ['wikimedia-commons-identifier' => 'https://commons.wikimedia.org/wiki/%s', undef, [qw(info render edit)]],
    ],
    fellig => [
        map {
            [$_ => sprintf('https://www.fellig.org/subject/best/any/%s/%%s', $_), undef, [qw(info render)]],
            [$_ => sprintf('https://api.fellig.org/v0/overview/%s/%%s', $_), undef, [qw(metadata)]],
        } qw(fellig-identifier fellig-box-number uuid oid uri wikidata-identifier e621-post-identifier wikimedia-commons-identifier british-museum-term musicbrainz-identifier gnd-identifier e621tagtype)
    ],
    youtube => [
        ['youtube-video-identifier' => 'https://www.youtube.com/watch?v=%s', undef, [qw(info render)]],
        ['youtube-video-identifier' => 'https://www.youtube.com/embed/%s',   undef, [qw(embed)]],
    ],
    'youtube-nocookie' => [
        ['youtube-video-identifier' => 'https://www.youtube-nocookie.com/embed/%s', undef, [qw(embed)]],
    ],
    e621 => [
        ['e621tagtype'          => 'https://e621.net/wiki_pages/show_or_new?title=%s', undef, [qw(info)]],
        ['e621-post-identifier' => 'https://e621.net/posts/%u',                        undef, [qw(render)]],
    ],
    dnb => [
        ['gnd-identifier' => 'https://d-nb.info/gnd/%s', undef, [qw(info)]],
    ],
    britishmuseum => [
        ['british-museum-term' => 'https://www.britishmuseum.org/collection/term/%s', undef, [qw(info)]],
    ],
    musicbrainz => [
        ['musicbrainz-identifier' => 'https://musicbrainz.org/mbid/%s', undef, [qw(info)]],
        ['uuid'                   => 'https://musicbrainz.org/mbid/%s', undef, [qw(info)]],
    ],
    osm => [
        map {
            ['osm-'.$_ => sprintf('https://www.openstreetmap.org/%s/%%s', $_), undef, [qw(info render)]]
        } qw(node way relation)
    ],
    xkcd => [
        ['xkcd-num' => 'https://xkcd.com/%s/',              undef, [qw(info render)]],
        ['xkcd-num' => 'https://xkcd.com/%s/info.0.json',   undef, [qw(metadata)]],
    ],
    viaf => [
        ['viaf-identifier' => 'https://viaf.org/viaf/%s/', undef, [qw(info)]],
    ],
    europeana => [
        ['europeana-entity-identifier' => 'https://data.europeana.eu/%s', undef, [qw(info)], {no_escape => 1}],
    ],
    'open-library' => [
        ['open-library-identifier' => 'https://openlibrary.org/works/%s?mode=all', undef, [qw(info)]],
        ['open-library-identifier' => 'https://openlibrary.org/works/%s.json', undef, [qw(metadata)]],
    ],
    ngv => [
        ['ngv-artist-identifier'  => 'https://www.ngv.vic.gov.au/explore/collection/artist/%s/', undef, [qw(info)]],
        ['ngv-artwork-identifier' => 'https://www.ngv.vic.gov.au/explore/collection/work/%s/',   undef, [qw(info)]],
    ],
    geonames => [
        ['geonames-identifier' => 'https://www.geonames.org/%s', undef, [qw(info)]],
    ],
);

my $re_yt_vid = qr#[^/]{11}#;
my $re_uuid = qr/[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}/;
my %url_parser = (
    urn => [
        {
            path => qr/^uuid:($re_uuid)$/,
            type => 'uuid',
            id => \1,
        },
        {
            path => qr/^oid:([1-3](?:\.(?:0|[1-9][0-9]*))+)$/,
            type => 'oid',
            id => \1,
        },
    ],
    https => [
        {
            host => 'www.wikidata.org',
            path => qr#^/entity/(?:Property:)?([QP][1-9][0-9]*)$#,
            source => 'wikidata',
            type => 'wikidata-identifier',
            id => \1,
            ise_order => ISEORDER_RUO,
        },
        {
            host => 'www.wikidata.org',
            path => qr#^/wiki/(?:Property:)?([QP][1-9][0-9]*)$#,
            source => 'wikidata',
            type => 'wikidata-identifier',
            id => \1,
            ise_order => ISEORDER_RUO,
            action => 'info',
        },
        {
            host => 'www.wikidata.org',
            path => qr#^/wiki/Special:EntityData/([QP][1-9][0-9]*)(?:\.[a-z]+)?$#,
            source => 'wikidata',
            type => 'wikidata-identifier',
            id => \1,
            ise_order => ISEORDER_RUO,
            action => 'metadata',
        },
        {
            host => 'commons.wikimedia.org',
            path => qr#^/wiki/(File(?:%3[Aa]|:)[^/]+)$#,
            source => 'wikimedia-commons',
            type => 'wikimedia-commons-identifier',
            id => \1,
        },
        {
            host => 'www.fellig.org',
            path => qr#^/subject/(?:info|best)/[^/]+/(fellig-identifier|fellig-box-number|uuid|oid|uri|wikidata-identifier|e621-post-identifier|wikimedia-commons-identifier|british-museum-term|musicbrainz-identifier|gnd-identifier|e621tagtype|[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})/([^/]+)$#,
            source => 'fellig',
            type => \1,
            id => \2,
            action => 'info',
        },
        {
            host => 'api.fellig.org',
            path => qr#^/v0/(?:overview|full)/(fellig-identifier|fellig-box-number|uuid|oid|uri|wikidata-identifier|e621-post-identifier|wikimedia-commons-identifier|british-museum-term|musicbrainz-identifier|gnd-identifier|e621tagtype|[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})/([^/]+)$#,
            source => 'fellig',
            type => \1,
            id => \2,
            action => 'metadata',
        },
        {
            host => 'www.youtube.com',
            path => qr#^/(?:embed|shorts)/($re_yt_vid)$#,
            source => 'youtube',
            type => 'youtube-video-identifier',
            id => \1,
            action => 'embed',
        },
        {
            host => 'www.youtube-nocookie.com',
            path => qr#^/embed/($re_yt_vid)$#,
            source => 'youtube-nocookie',
            type => 'youtube-video-identifier',
            id => \1,
            action => 'embed',
        },
        {
            host => 'musicbrainz.org',
            path => qr#^/[^/]+/($re_uuid)$#,
            source => 'musicbrainz',
            type => 'musicbrainz-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'd-nb.info',
            path => qr#^/gnd/([\dX]+)$#,
            source => 'dnb',
            type => 'gnd-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.britishmuseum.org',
            path => qr#^/collection/term/([A-Z]+[0-9]+)$#,
            source => 'britishmuseum',
            type => 'british-museum-term',
            id => \1,
            action => 'info',
        },
        {
            host => 'e621.net',
            path => qr#^/posts/([1-9][0-9]*)$#,
            source => 'e621',
            type => 'e621-post-identifier',
            id => \1,
            action => 'render',
        },
        (map {{
            host => 'www.openstreetmap.org',
            path => qr#^/$_/([1-9][0-9]*)$#,
            source => 'osm',
            type => 'osm-'.$_,
            id => \1,
            action => 'info',
        }} qw(node way relation)),
        {
            host => 'xkcd.com',
            path => qr#^/([1-9][0-9]*)/$#,
            source => 'xkcd',
            type => 'xkcd-num',
            id => \1,
            action => 'render',
        },
        {
            host => 'xkcd.com',
            path => qr#^/([1-9][0-9]*)/info\.0\.json$#,
            source => 'xkcd',
            type => 'xkcd-num',
            id => \1,
            action => 'metadata',
        },
        {
            host => 'www.ngv.vic.gov.au',
            path => qr#^/explore/collection/artist/([1-9][0-9]*)/$#,
            source => 'ngv',
            type => 'ngv-artist-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.ngv.vic.gov.au',
            path => qr#^/explore/collection/work/([1-9][0-9]*)/$#,
            source => 'ngv',
            type => 'ngv-artwork-identifier',
            id => \1,
            action => 'info',
        },
    ],
);

my %syntax = (
    uuid                            => RE_UUID,
    oid                             => qr/^[1-3](?:\.(?:0|[1-9][0-9]*))+$/,
    uri                             => qr/^[a-zA-Z][a-zA-Z0-9\+\.\-]+:/,
    tagname                         => qr/./,
    'wikidata-identifier'           => qr/^[QP][1-9][0-9]*$/,
    'wikimedia-commons-identifier'  => qr/^File:.*$/,
    'musicbrainz-identifier'        => RE_UUID,
    'british-museum-term'           => qr/^[A-Z]+[1-9][0-9]{0,5}$/, # TODO: Find good reference; See also: https://www.wikidata.org/wiki/Property:P1711#P1793
    'gnd-identifier'                => qr/^1[012]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$/, # https://www.wikidata.org/wiki/Property:P227#P1793
    'fellig-box-number'             => qr/^[1-9][0-9]{3}$/,
    'fellig-identifier'             => qr/^[A-Z]+[1-9][0-9]*$/,
    'youtube-video-identifier'      => qr/^.{11}$/,
    e621tagtype                     => qr/./,
    'e621-post-identifier'          => RE_UINT,
    (map {'osm-'.$_ => RE_UINT} qw(node way relation)),
    'xkcd-num'                      => RE_UINT,
    'ngv-artist-identifier'         => RE_UINT,
    'ngv-artwork-identifier'        => RE_UINT,
);

my %fellig_tables = (
    U   => 'users',
    P   => 'posts',
    TXT => 'texts',
);


# Private method.
sub new {
    my ($pkg, %opts) = @_;
    my URI $uri = $opts{uri};
    my __PACKAGE__ $self;

    croak 'Passed undef as URI' unless defined $uri;
    croak 'Passed a non-URI object' unless $uri->isa('URI');

    $opts{uri} = $uri->canonical;

    $self = bless \%opts, $pkg;

    $self->_lookup;
    $self->_lookup_with_mode(mode => 'offline');
    $self->_lookup_with_mode(mode => 'online');

    return $self;
}

sub _set {
    my ($self, $service, $type, $id, $ise_order, $action) = @_;
    my Data::URIID $extractor = $self->extractor;

    croak 'Invalid syntax for identifier type' unless $id =~ $syntax{$type};

    $ise_order //= ISEORDER_UOR;
    $service = $extractor->service($service) if defined $service;
    $type    = $extractor->name_to_ise(type    => $type);
    $action  = $extractor->name_to_ise(action  => $action) if defined $action;

    $self->{primary} = {
        service     => $service,
        type        => $type,
        id          => $id,
        ise_order   => $ise_order,
        action      => $action,
    };
    $self->{id} = {
        $type => $id,
    };
}

sub _lookup {
    my ($self) = @_;
    my URI $uri = $self->{uri};
    my $scheme = $uri->scheme;
    my $host = eval {$uri->host};
    my $path = eval {$uri->path};
    my $func;

    # handle HTTP and HTTPS alike.
    $scheme = 'https' if $scheme eq 'http';

    foreach my $rule (@{$url_parser{$scheme}}) {
        my @res;
        my %found = map {$_ => $rule->{$_}} qw(source type id ise_order action);

        if (defined $rule->{host}) {
            next unless defined($host) && $host eq $rule->{host};
        }
        if (defined $rule->{path}) {
            next unless defined($path) && (@res = $path =~ $rule->{path});
        }

        foreach my $value (values %found) {
            $value = uri_unescape($res[${$value} - 1]) if ref($value) eq 'SCALAR';
        }

        $self->_set(@found{qw(source type id ise_order action)});
        return;
    }

    $func = $self->can('_lookup__'.$scheme);

    croak 'Not implemented (unsupported scheme)' unless $func;

    $self->$func();

    croak 'Not implemented' unless defined $self->{primary};
}

sub _lookup_one {
    my ($self, $service, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $mode = $opts{mode} // 'online';
    my $have = $self->{$mode.'_results'} //= {};
    my $res;

    return $have->{$service} if $have->{$service};

    $res = eval {
        my $_service = $extractor->service($service);
        my $_func = $_service->can(sprintf('_%s_lookup', $mode));
        $_service->$_func($self, %opts)
    } // {};
    $have->{$service} = $res;
    foreach my $id_type (keys %{$res->{id} // {}}) {
        my $ise = $extractor->name_to_ise(type => $id_type);
        $self->{id}{$ise} //= $res->{id}{$id_type};
    }

    return $res;
}

sub _lookup_with_mode {
    my ($self, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $mode = $opts{mode};

    return if $mode eq 'online' && !$extractor->online;

    foreach my $pass (0..2) {
        foreach my $id_type_ise (keys %{$self->{id}}) {
            my $id_type = eval {$extractor->ise_to_name(type => $id_type_ise)} // next;
            foreach my $service (@{$lookup_services{$id_type}}) {
                $self->_lookup_one($service, %opts);
            }
        }
    }
}

sub _lookup__https {
    my ($self) = @_;
    my URI $uri = $self->{uri};
    my $host = $uri->host;
    my $path = $uri->path;

    if ($host eq 'www.youtube.com') {
        if (defined(my $v = {$uri->query_form}->{v})) {
            $self->_set(youtube => 'youtube-video-identifier' => $v);
        }
    } elsif ($host =~ /^[a-z]{2}\.wikipedia\.org$/) {
        if (scalar(my ($page) = $path =~ m#^/wiki/(.+)$#)) {
            # We need to do this very early as we cannot store it as an ID before we did an online lookup.
            my Data::URIID::Service $service = $self->extractor->service('wikipedia');
            if ($service->_is_online) {
                my $json = $service->_get_json(sprintf('https://%s/w/api.php', $host),
                    query => {
                        action      => 'query',
                        format      => 'json',
                        redirects   => 1,
                        prop        => 'pageprops',
                        ppprop      => 'wikibase_item',
                        titles      => $page,
                    });
                if (defined $json) {
                    my $wikidata_identifier = eval {$json->{query}{pages}{(keys %{$json->{query}{pages}})[0]}{pageprops}{wikibase_item}};
                    if (defined $wikidata_identifier) {
                        $self->_set(wikipedia => 'wikidata-identifier' => $wikidata_identifier, undef, 'info');
                    }
                }
            } else {
                croak 'Wikipedia URLs can only be lookedup in online mode';
            }
        }
    } elsif ($host eq 'xkcd.com' && ($path eq '/' || $path eq '/info.0.json')) {
        # We need to do this very early as we cannot store it as an ID before we did an online lookup.
        my Data::URIID::Service $service = $self->extractor->service('xkcd');
        if ($service->_is_online) {
            my $res = $self->_lookup_one($service->name, metadata_url => 'https://xkcd.com/info.0.json');
            $self->_set(xkcd => 'xkcd-num' => $res->{id}{'xkcd-num'}, undef, $path eq '/' ? 'render' : 'metadata') if defined $res->{id}{'xkcd-num'};
        }
    }
}


#@returns Data::URIID
sub extractor {
    my ($self) = @_;
    return $self->{extractor};
}


sub id_type {
    my ($self) = @_;
    return $self->{primary}{type};
}


# %opts is currently private
sub id {
    my ($self, $type, %opts) = @_;

    return $self->{primary}{id} unless defined $type;

    # We do a double convert of type here to ensure we have it the right way
    # independent of if we got name or ISE passed.
    $type = $self->extractor->name_to_ise(type => $type);
    if (defined $self->{id}{$type}) {
        return $self->{id}{$type};
    } elsif (!$opts{_no_convert}) {
        my $primary_type_name =  $self->extractor->ise_to_name(type => $self->{primary}{type});
        my $type_name = $self->extractor->ise_to_name(type => $type);
        $opts{_no_try} //= {};
        $opts{_no_try}{$type_name} = 1;

        # Do two passes: first try only IDs we already have, then try them in order of converters.
        foreach my $no_convert (1, 0) {
            foreach my $from ($primary_type_name, grep {$_ ne 'x'.$primary_type_name} @{$id_conv{$type_name} // []}) {
                next if $opts{_no_try}{$from};
                eval {
                    my $id = $self->id($from, %opts, _no_convert => $no_convert, _no_try => {%{$opts{_no_try}}});
                    my $func = $self->can(sprintf('_id_conv__%s__%s', $type_name =~ tr/-/_/r, $from =~ tr/-/_/r));
                    $self->$func($type => $from => $id) if defined $func;
                };
                return $self->{id}{$type} if defined $self->{id}{$type};
            }
        }
    }

    croak 'Identifier type not supported';
}


sub ise {
    my ($self) = @_;

    {
        my $type_name = $self->extractor->ise_to_name(type => $self->id_type);
        if ($type_name eq 'uuid' || $type_name eq 'oid' || $type_name eq 'uri') {
            return $self->id;
        }
    }

    foreach my $type (@{$self->{primary}{ise_order}}) {
        my $id = eval { $self->id($type) };
        return $id if defined $id;
    }

    croak 'Identifier does not map to an ISE';
}


sub attribute {
    my ($self, $key, %opts) = @_;
    my $info = $attributes{$key} // croak sprintf('Unknown attribute "%s"', $key);
    my $attributes = $self->{attributes} //= {};
    my $value = $attributes->{$key};
    my $as = $opts{as} // $info->{default_as} // $info->{source_type};
    my $default_value;

    unless (defined $value) {
        $value = $self->{primary}{$key};
    }

    unless (defined $value) {
        $self->{offline_results} //= {};
        $self->{online_results}  //= {};

        foreach my $result (values(%{$self->{offline_results}}), values(%{$self->{online_results}})) {
            next unless defined($result) && defined($result->{attributes});
            if (defined($value = $result->{attributes}->{$key})) {
                if (ref($value) eq 'HASH') {
                    my $new;
                    foreach my $language_tag ($self->extractor->_get_language_tags(%opts)) {
                        $new = $value->{$language_tag} and last;
                    }
                    $default_value = $value->{'*'};
                    $value = $new;
                }
                last if defined $value;
            }
        }
    }

    $value //= $default_value;

    if (defined $value) {
        my $source_type;

        $source_type = ref($value) || $info->{source_type};
        $as //= $source_type;

        if ($as eq $source_type) {
            return $value;
        } else {
            my $cache = ($self->{attributes_cache} //= {})->{$key} //= {};
            if ($as eq 'string' && eval {$value->isa('URI')}) {
                return $cache->{$as} //= $value->as_string;
            } elsif ($as eq __PACKAGE__ && eval {$value->isa('URI')}) {
                return $cache->{$as} //= $self->extractor->lookup($value);
            } elsif ($as eq __PACKAGE__ && eval {$value->can('ise')}) {
                return $cache->{$as} //= $self->extractor->lookup(ise => $value->ise);
            } elsif ($as eq 'ise' && eval {$value->can('ise')}) {
                return $cache->{$as} //= $value->ise;
            }
        }

        croak sprintf('Cannot convert from type "%s" to "%s" for attribute "%s"', $source_type, $as, $key);
    }

    return $opts{default} if exists $opts{default};

    croak sprintf('No value found for attribute "%s"', $key);
}


sub _match_actions {
    my ($self, $template, $opts) = @_;
    my $template_actions = $template->[3];
    my $action = $opts->{action};

    return 1 unless defined $template_actions;
    return 1 unless defined $action;

    return any {$_ eq $action} @{$template_actions};

    return undef;
}

#@returns URI
sub url {
    my ($self) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $service;
    my %opts;

    if (scalar(@_) == 2) {
        $opts{service} = $_[1];
    } else {
        (undef, %opts) = @_;
    }

    $service = $opts{service} // $self->attribute('service');

    # Normalise name:
    $service = $extractor->service($service);
    $service = $extractor->ise_to_name(service => $service->ise);

    # Normalise action:
    if (defined $opts{action}) {
        $opts{action} = $extractor->name_to_ise(action => $opts{action});
        $opts{action} = $extractor->ise_to_name(action => $opts{action});
    }

    $opts{action} //= eval {$extractor->ise_to_name(action => $self->attribute('action', as => 'ise'))};

    # First pass: try original id type
    {
        my $id = $self->id;
        my $id_type = $extractor->ise_to_name(type => $self->id_type);

        foreach my $template (@{$url_templates{$service} // []}) {
            next unless $id_type eq $template->[0];

            next if defined($template->[2]) && $id !~ $template->[2];
            next unless $self->_match_actions($template, \%opts);

            return URI->new(sprintf($template->[1], uri_escape($id)));
        }
    }

    # Second pass: try in order of preference of the service
    foreach my $template (@{$url_templates{$service} // []}) {
        #   0           1            2             3           4
        my ($t_id_type, $t_template, $t_id_filter, $t_actions, $t_opts) = @{$template};
        my $id = eval { $self->id($t_id_type) } // next;

        $t_opts //= {};

        next if defined($t_id_filter) && $id !~ $t_id_filter;
        next unless $self->_match_actions($template, \%opts);

        return URI->new(sprintf($t_template, $t_opts->{no_escape} ? $id : uri_escape($id)));
    }

    if (defined($opts{action}) && $opts{action} eq 'info' && $service eq 'wikipedia') {
        if (defined(my $sitelinks = eval {$self->{online_results}{wikidata}{wikidata_sitelinks}})) {
            foreach my $language_tag ($extractor->_get_language_tags(%opts)) {
                if (defined(my $link = $sitelinks->{$language_tag.'wiki'})) {
                    return URI->new($link->{url}) if defined $link->{url};
                }
            }
        }
    }

    croak 'Identifier does not generate a URL for the selected service';
}

# Converters:

sub _id_conv__uuid__wikidata_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = create_uuid_as_string(UUID_SHA1, '9e10aca7-4a99-43ac-9368-6cbfa43636df', lc $id);
}

sub _id_conv__uuid__fellig_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    my ($table, $num) = $id =~ /^([A-Z]+)([1-9][0-9]*)$/;
    my $table_id = create_uuid_as_string(UUID_SHA1, '7a287954-9156-402f-ac3d-92f71956f1aa', $fellig_tables{$table} // croak 'Not supported');
    $self->{id}{$type_want} = create_uuid_as_string(UUID_SHA1, '7f9670af-21d9-4aa5-afd5-6e9e01261d6c', sprintf('%s/%u', $table_id, $num));
}

sub _id_conv__uuid__oid {
    my ($self, $type_want, $type_name_have, $id) = @_;
    if ($id =~ /^2\.25\.([1-9][0-9]*)$/) {
        my $hex = Math::BigInt->new($1)->as_hex;
        $hex =~ s/^0x//;
        $hex = ('0' x (32 - length($hex))) . $hex;
        $hex =~ s/^(.{8})(.{4})(.{4})(.{4})(.{12})$/$1-$2-$3-$4-$5/;
        $self->{id}{$type_want} = $hex;
    }
}

sub _id_conv__oid__uuid {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = sprintf('2.25.%s', Math::BigInt->new('0x'.$id =~ tr/-//dr))
}

sub _id_conv__uri__wikidata_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = sprintf('http://www.wikidata.org/entity/%s', $id);
}

sub _id_conv__uri__uuid {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = sprintf('urn:%s:%s', $type_name_have => $id);
}

*_id_conv__uri__oid = *_id_conv__uri__uuid;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Result - Extractor for identifiers from URIs

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use Data::URIID;

    my $extractor = Data::URIID->new;
    my $result = $extractor->lookup( $URI );

=head1 METHODS

=head2 extractor

    my $extractor = $result->extractor;

Returns the L<Data::URIID> object used to create this object.

=head2 id_type

    my $id_type = $result->id_type;

This method will return the ISE of the id's type if successful or C<die> otherwise.

=head2 id

    my $id = $result->id;
    # or:
    my $id = $result->id( $type );

This method will return the id if successful or C<die> otherwise.

=head2 ise

    my $ise = $result->ise;

This method will return the ISE if successful or C<die> otherwise.

=head2 attribute

    my $ise = $result->attribute( $key, [%opts] );

Get a attribute of the result or the default or C<die>.
Attributes are subject to the settings passed to L<Data::URIID/"new">.
The default can be supplied via the C<default> option (see below).

The following attributes are defined:

=over

=item C<action>

The action the original URL was using.

=item C<altitude>

The altitude of the item.
The reference system is not specified.

=item C<description>

A description of the subject.

=item C<displaycolour>

A colour that is commonly used to display alongside the item.

=item C<displayname>

A name that can be used to display the subject to the user.

=item C<icon>

An icon for the item.

=item C<icon_text>

A one character alternative to the icon.
This character may be any unicode character.
This also implies that a) the width of the character may vary, b) may use characters outside the range of any 8 bit encoding.

=item C<latitude>

The latitude of the item.
The reference system is not specified.

=item C<longitude>

The longitude of the item.
The reference system is not specified.

=item C<service>

The L<Data::URIID::Service> the original URL was using.

=item C<space_object>

The object in space (astronomical body) this item is on.

=item C<thumbnail>

A thumbnail image that can be used for the item.

=back

The following options are defined:

=over

=item C<as>

Return the value as the given type.
This is the package name of the type, C<string> for plain perl strings, or C<ise> for an ISE.
If the given type is not supported for the given attribute the function C<die>s.

=item C<default>

Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

=item C<language_tags>

Overrides the default language tags from the C<$result-E<gt>extractor> object.
May be an arrayref with a list of exact matches or a string that is parsed as a list (and supers being added).

=back

=head2 url

    my $url = $result->url;
    # or:
    my $url = $result->url( $service );
    my $url = $result->url( service => $service ); # the same
    # or:
    my $url = $result->url( %options );

Returns a URL for the resource on a given service.
If no service is given the value returned by C<$result-E<gt>attribute('service')> is used.

This method will return a URL (L<URI> object) if successful or C<die> otherwise.

The following options are defined:

=over

=item C<action>

Returns an URL for the given action.
Defaults to C<$result-E<gt>attribute('action')>.

=item C<service>

Returns an URL for the given service.
May be an service name, or L<Data::URIID::Service> object.
Defaults to C<$result-E<gt>attribute('service')>.

=item C<language_tags>

Overrides the default language tags from the C<$result-E<gt>extractor> object.
May be an arrayref with a list of exact matches or a string that is parsed as a list (and supers being added).

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
