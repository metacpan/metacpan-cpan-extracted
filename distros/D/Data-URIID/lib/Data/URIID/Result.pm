# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Result;

use v5.16;
use strict;
use warnings;

use Carp;
use URI;
use URI::Escape;
use Scalar::Util qw(blessed);
use List::Util qw(any);
use UUID::Tiny ':std';
use Math::BigInt;
use MIME::Base64;

use Data::Identifier;

use Data::URIID::Service;
use Data::URIID::Digest;

use constant {
    ISEORDER_UOR => ['uuid', 'oid', 'uri'],
    ISEORDER_RUO => ['uri', 'uuid', 'oid'],
};

use constant RE_UUID => qr/^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/;
use constant RE_UINT => qr/^[1-9][0-9]*$/;

our $VERSION = v0.13;

use parent 'Data::URIID::Base';

my %digest_name_converter = (
    fc('md5')   => 'md-5-128',
    fc('sha1')  => 'sha-1-160',
    fc('sha-1') => 'sha-1-160',
    (map {
            fc('sha-'.$_)  => 'sha-2-'.$_,
            fc('sha3-'.$_) => 'sha-3-'.$_,
        } qw(224 256 384 512)),
);

my %attributes = (
    action      => {
        source_type => 'ise',
    },
    displayname => {
        source_type => 'string',
    },
    displaycolour => {},
    description => {
        source_type => 'string',
    },
    icon_text => {
        source_type => 'string',
    },
    icon => {},
    thumbnail => {},
    website => {},
    final_file_size => { # experimental
        source_type => 'uint',
    },
    service => {},
    best_service => {},
    (map {$_ => {source_type => 'number'}} qw(altitude latitude longitude)),
    space_object => {},

    sex_or_gender => {},

    media_subtype => {
        source_type => 'media_subtype',
    },

    roles => {},

    sources => {
        cb => sub {
            my ($self) = @_;
            my Data::URIID $extractor = $self->extractor;
            my %sources;

            foreach my $key (keys(%{$self->{offline_results}}), keys(%{$self->{online_results}})) {
                if (scalar(keys %{$self->{offline_results}{$key} // {}}) || scalar(keys %{$self->{online_results}{$key} // {}})) {
                    $sources{$extractor->name_to_ise(service => $key)} = undef;
                }
            }

            return [map {$extractor->service($_)} sort keys %sources];
        },
    },

    # TODO: define type. # experimental
    (map {$_ => {source_type => 'string'}} qw(date_of_birth date_of_death)),

    ext => {}, # experimental
);

my %id_conv = (
    uuid => [qw(wikidata-identifier fellig-identifier oid)],
    oid  => [qw(uuid)],
    uri  => [qw(wikidata-identifier uuid oid)],
    doi  => [qw(grove-art-online-identifier)],
);

my %lookup_services;
my %lookup_services_digest;

my %best_services = (
    'wikidata-identifier'           => 'wikidata',
    'musicbrainz-identifier'        => 'musicbrainz',
    'british-museum-term'           => 'britishmuseum',
    'gnd-identifier'                => 'dnb',
    'fellig-box-number'             => 'fellig',
    'fellig-identifier'             => 'fellig',
    'youtube-video-identifier'      => 'youtube',
    'e621tagtype'                   => 'e621',
    'wikimedia-commons-identifier'  => 'wikimedia-commons',
    'e621-post-identifier'          => 'e621',
    'e621-pool-identifier'          => 'e621',
    'osm-node'                      => 'osm',
    'osm-way'                       => 'osm',
    'osm-relation'                  => 'osm',
    'xkcd-num'                      => 'xkcd',
    'viaf-identifier'               => 'viaf',
    'open-library-identifier'       => 'open-library',
    #'unesco-thesaurus-identifier'   => '',
    #'isni'                          => '',
    #'aev-identifier'                => '',
    'europeana-entity-identifier'   => 'europeana',
    'ngv-artist-identifier'         => 'ngv',
    'ngv-artwork-identifier'        => 'ngv',
    'geonames-identifier'           => 'geonames',
    'find-a-grave-identifier'       => 'find-a-grave',
    'libraries-australia-identifier'=> 'nla',
    'nla-trove-people-identifier'   => 'nla',
    'agsa-creator-identifier'       => 'agsa',
    'amc-artist-identifier'         => 'amc',
    'a-p-and-p-artist-identifier'   => 'a-p-and-p',
    'tww-artist-identifier'         => 'tww',
    'factgrid-identifier'           => 'factgrid',
    'grove-art-online-identifier'   => 'grove-art-online',
    'wikitree-person-identifier'    => 'wikitree-person',
    'doi'                           => 'doi',
    'iconclass-identifier'          => 'iconclass',
    'media-subtype-identifier'      => 'iana',
    #'gtin'                          => '',
    #'small-identifier'              => '',
    #'language-tag-identifier'       => '',
    #'chat-0-word-identifier'        => '',
    'furaffinity-post-identifier'   => 'furaffinity',
    'imgur-post-identifier'         => 'imgur',
    'notalwaysright-post-identifier' => 'notalwaysright',
    'fefe-blog-post-identifier'     => 'fefe',
    'ruthede-comic-post-identifier' => 'ruthede',
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
{
    my $extra = Data::URIID::Service->_extra_lookup_services_digests;
    foreach my $service_name (keys %{$extra}) {
        foreach my $digest (@{$extra->{$service_name}}) {
            $lookup_services_digest{$digest} //= [];
            push(@{$lookup_services_digest{$digest}}, $service_name);
        }
    }
}

my %url_templates = (
    'wikidata' => [
        ['wikidata-identifier' => 'https://www.wikidata.org/wiki/%s'                    => qr/^Q/  => [qw(documentation info edit)]],
        ['wikidata-identifier' => 'https://www.wikidata.org/wiki/Property:%s'           => qr/^P/  => [qw(documentation info edit)]],
        ['wikidata-identifier' => 'https://www.wikidata.org/wiki/Special:EntityData/%s' => undef() => [qw(metadata)]],
    ],
    'wikimedia-commons' => [
        ['wikimedia-commons-identifier' => 'https://commons.wikimedia.org/wiki/%s', undef, [qw(info render edit)]],
    ],
    'fellig' => [
        map {
            [$_ => sprintf('https://www.fellig.org/subject/best/any/%s/%%s', $_), undef, [qw(info render)]],
            [$_ => sprintf('https://api.fellig.org/v0/overview/%s/%%s', $_), undef, [qw(metadata)]],
        } qw(fellig-identifier fellig-box-number uuid oid uri wikidata-identifier e621-post-identifier e621-pool-identifier wikimedia-commons-identifier british-museum-term musicbrainz-identifier gnd-identifier e621tagtype)
    ],
    'youtube' => [
        ['youtube-video-identifier' => 'https://www.youtube.com/watch?v=%s', undef, [qw(info render)]],
        ['youtube-video-identifier' => 'https://www.youtube.com/embed/%s',   undef, [qw(embed)]],
    ],
    'youtube-nocookie' => [
        ['youtube-video-identifier' => 'https://www.youtube-nocookie.com/embed/%s', undef, [qw(embed)]],
    ],
    'e621' => [
        ['e621tagtype'          => 'https://e621.net/wiki_pages/show_or_new?title=%s', undef, [qw(info)]],
        ['e621-post-identifier' => 'https://e621.net/posts/%u',                        undef, [qw(info render)]],
        ['e621-post-identifier' => 'https://e621.net/posts.json?limit=1&tags=id:%u',   undef, [qw(metadata)]],
        ['e621-pool-identifier' => 'https://e621.net/pools/%u',                        undef, [qw(info render)]],
        ['e621-pool-identifier' => 'https://e621.net/pools.json?search[id]=%u',        undef, [qw(metadata)]],
    ],
    'dnb' => [
        ['gnd-identifier' => 'https://d-nb.info/gnd/%s', undef, [qw(info)]],
    ],
    'britishmuseum' => [
        ['british-museum-term' => 'https://www.britishmuseum.org/collection/term/%s', undef, [qw(info)]],
    ],
    'musicbrainz' => [
        ['musicbrainz-identifier' => 'https://musicbrainz.org/mbid/%s', undef, [qw(info)]],
        ['uuid'                   => 'https://musicbrainz.org/mbid/%s', undef, [qw(info)]],
    ],
    'osm' => [
        map {
            ['osm-'.$_ => sprintf('https://www.openstreetmap.org/%s/%%s', $_), undef, [qw(info render)]]
        } qw(node way relation)
    ],
    'xkcd' => [
        ['xkcd-num' => 'https://xkcd.com/%s/',              undef, [qw(info render)]],
        ['xkcd-num' => 'https://xkcd.com/%s/info.0.json',   undef, [qw(metadata)]],
    ],
    'viaf' => [
        ['viaf-identifier' => 'https://viaf.org/viaf/%s/', undef, [qw(info)]],
    ],
    'europeana' => [
        ['europeana-entity-identifier' => 'https://data.europeana.eu/%s', undef, [qw(info)], {no_escape => 1}],
    ],
    'open-library' => [
        ['open-library-identifier' => 'https://openlibrary.org/works/%s?mode=all', undef, [qw(info)]],
        ['open-library-identifier' => 'https://openlibrary.org/works/%s.json', undef, [qw(metadata)]],
    ],
    'ngv' => [
        ['ngv-artist-identifier'  => 'https://www.ngv.vic.gov.au/explore/collection/artist/%s/', undef, [qw(info)]],
        ['ngv-artwork-identifier' => 'https://www.ngv.vic.gov.au/explore/collection/work/%s/',   undef, [qw(info)]],
    ],
    'geonames' => [
        ['geonames-identifier' => 'https://www.geonames.org/%s', undef, [qw(info)]],
    ],
    'find-a-grave' => [
        ['find-a-grave-identifier' => 'https://www.findagrave.com/memorial/%s', undef, [qw(info)]],
    ],
    'nla' => [
        ['libraries-australia-identifier' => 'https://nla.gov.au/anbd.aut-an%s', undef, [qw(info)]],
        ['nla-trove-people-identifier'    => 'https://trove.nla.gov.au/people/%s', undef, [qw(info)]],
    ],
    'agsa' => [
        ['agsa-creator-identifier' => 'https://www.agsa.sa.gov.au/collection-publications/collection/creators/_/%s/', undef, [qw(info)]],
    ],
    'amc' => [
        ['amc-artist-identifier' => 'https://www.australianmusiccentre.com.au/artist/%s', undef, [qw(info)]],
    ],
    'a-p-and-p' => [
        ['a-p-and-p-artist-identifier' => 'https://www.printsandprintmaking.gov.au/artists/%s/', undef, [qw(info)]],
    ],
    'tww' => [
        ['tww-artist-identifier' => 'https://www.watercolourworld.org/artist/%s', undef, [qw(info)]],
    ],
    'factgrid' => [
        ['factgrid-identifier' => 'https://database.factgrid.de/wiki/Item:%s'               => qr/^Q/  => [qw(documentation info edit)]],
        ['factgrid-identifier' => 'https://database.factgrid.de/wiki/Property:%s'           => qr/^P/  => [qw(documentation info edit)]],
        ['factgrid-identifier' => 'https://database.factgrid.de/wiki/Special:EntityData/%s' => undef() => [qw(metadata)]],
    ],
    'grove-art-online' => [
        ['grove-art-online-identifier' => 'https://doi.org/10.1093/gao/9781884446054.article.%s', undef, [qw(info)]],
    ],
    'wikitree-person' => [
        ['wikitree-person-identifier' => 'https://www.wikitree.com/wiki/%s', undef, [qw(info)]],
    ],
    'doi' => [
        ['doi' => 'https://doi.org/%s',    undef, [qw(info)], {no_escape => 1}],
        ['doi' => 'https://dx.doi.org/%s', undef, [qw(metadata)], {no_escape => 1}],
    ],
    'iconclass' => [
        ['iconclass-identifier' => 'https://iconclass.org/%s', undef, [qw(info)]],
        ['iconclass-identifier' => 'https://iconclass.org/%s.jsonld', undef, [qw(metadata)]],
    ],
    'iana' => [
        ['media-subtype-identifier' => 'https://www.iana.org/assignments/media-types/%s', undef, [qw(info)], {no_escape => 1}],
    ],
    'oidref' => [
        ['oid' => 'https://oidref.com/%s' => undef, [qw(info)]],
    ],
    'furaffinity' => [
        ['furaffinity-post-identifier' => 'https://www.furaffinity.net/view/%s/', undef, [qw(info render)]],
    ],
    'imgur' => [
        ['imgur-post-identifier' => 'https://imgur.com/%s', undef, [qw(info render)]],
    ],
    'notalwaysright' => [
        ['notalwaysright-post-identifier' => 'https://notalwaysright.com/x/%u/', undef, [qw(info render)]],
    ],
    'fefe' => [
        ['fefe-blog-post-identifier' => 'https://blog.fefe.de/?ts=%s', undef, [qw(info render)]],
        ['fefe-blog-post-identifier' => 'https://blog.fefe.de/rss.xml?ts=%s', undef, [qw(metadata)]],
    ],
    'schemaorg' => [
        ['uri' => '%s', qr#^https://schema\.org/[^/]+$#, [qw(info)], {no_escape => 1}],
    ],
    'purlorg' => [
        ['uri' => '%s', qr#^http://purl\.org/dc/(?:elements/1\.1|terms|dcam|dcmitype)/[^/]+$#, [qw(info)], {no_escape => 1}],
    ],
    'ruthede' => [
        ['ruthede-comic-post-identifier' => 'https://ruthe.de/static/cartoon_%s.html', undef, [qw(info render)]],
    ],
);
my %digest_url_templates = (
    'e621' => [
        ['md-5-128'     => 'https://e621.net/posts/random?tags=md5:%{digest}', [qw(info render)]],
        ['md-5-128'     => 'https://static1.e621.net/data/%{digest,0,2}/%{digest,2,2}/%{digest}.%{ext}', [qw(file-fetch fetch)]],
        ['md-5-128'     => 'https://e621.net/posts.json?limit=1&tags=md5:%{digest}', [qw(metadata)]],
    ],
    'fellig' => [
        (map {[$_ => 'https://files.fellig.org/v2/by/'.$_.'/%{digest}.%{ext}', [qw(file-fetch fetch)]]}
            qw(sha-3-224 sha-3-512 md-5-128),
        ),
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
        {
            path => qr/^isbn:([0-9]{13})$/,
            type => 'gtin',
            id => \1,
        },
        {
            path => qr/^isbn:([0-9]{9}[0-9Xx])$/,
            type => 'gtin',
            id => sub {
                my ($self, $uri, $rule, $res) = @_;
                my $isbn = $res->[0];

                {
                    my @digits = split(//, $isbn);
                    my $check = pop(@digits);
                    my $sum = 0;

                    for (my $i = 0; length(my $c = shift @digits); $i++) {
                        $sum += (ord($c) - ord('0')) * (10 - $i);
                    }

                    if ($check eq 'X' || $check eq 'x') {
                        $check = 11;
                    }

                    die 'Bad check' unless $check == (11 - ($sum % 11));
                }

                {
                    $isbn =~ s/^([0-9]{9}).$/978$1/;

                    my @digits = split(//, $isbn);
                    my $sum = 0;

                    for (my $i = 0; length(my $c = shift @digits); $i++) {
                        $sum += (ord($c) - ord('0')) * ($i & 1 ? 3 : 1);
                    }

                    return sprintf('%u%u', $isbn, 10 - ($sum % 10));
                }
            },
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
            path => qr#^/subject/(?:info|best)/[^/]+/(fellig-identifier|fellig-box-number|uuid|oid|uri|wikidata-identifier|e621-(?:post|pool)-identifier|wikimedia-commons-identifier|british-museum-term|musicbrainz-identifier|gnd-identifier|e621tagtype|[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})/([^/]+)$#,
            source => 'fellig',
            type => \1,
            id => \2,
            action => 'info',
        },
        {
            host => 'api.fellig.org',
            path => qr#^/v0/(?:overview|full)/(fellig-identifier|fellig-box-number|uuid|oid|uri|wikidata-identifier|e621-(?:post|pool)-identifier|wikimedia-commons-identifier|british-museum-term|musicbrainz-identifier|gnd-identifier|e621tagtype|[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12})/([^/]+)$#,
            source => 'fellig',
            type => \1,
            id => \2,
            action => 'metadata',
        },
        {
            host => qr#^(?:www\.)?youtube\.com$#,
            path => qr#^/(?:embed|shorts|live)/($re_yt_vid)$#,
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
        {
            host => 'e621.net',
            path => qr#^/pools/([1-9][0-9]*)$#,
            source => 'e621',
            type => 'e621-pool-identifier',
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
            host => qr#^(?:www\.)?xkcd\.com$#,
            path => qr#^/([1-9][0-9]*)/$#,
            source => 'xkcd',
            type => 'xkcd-num',
            id => \1,
            action => 'render',
        },
        {
            host => qr#^(?:www\.)?xkcd\.com$#,
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
        {
            host => qr#^(?:www|de|es|fr|fr-ca|it|nl|sv|pt)\.findagrave\.com$#,
            path => qr#^/memorial/([1-9][0-9]*)(?:/[^/]*)?$#,
            source => 'find-a-grave',
            type => 'find-a-grave-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'nla.gov.au',
            path => qr#^/anbd\.aut-an([1-9][0-9]*)$#,
            source => 'nla',
            type => 'libraries-australia-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'trove.nla.gov.au',
            path => qr#^/people/([1-9][0-9]*)$#,
            source => 'nla',
            type => 'nla-trove-people-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.agsa.sa.gov.au',
            path => qr#^/collection-publications/collection/creators/_/([1-9][0-9]*)/$#,
            source => 'agsa',
            type => 'agsa-creator-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.australianmusiccentre.com.au',
            path => qr#^/artist/([a-z]+(-[a-z]+)+)$#,
            source => 'amc',
            type => 'amc-artist-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.printsandprintmaking.gov.au',
            path => qr#^/artists/([1-9][0-9]*)/$#,
            source => 'a-p-and-p',
            type => 'a-p-and-p-artist-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.watercolourworld.org',
            path => qr#/artist/([\p{L}\d]+(-[\p{L}\d]+)*)$#,
            source => 'tww',
            type => 'tww-artist-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'database.factgrid.de',
            path => qr#^/entity/(?:Property:)?([QP][1-9][0-9]*)$#,
            source => 'factgrid',
            type => 'factgrid-identifier',
            id => \1,
            ise_order => ISEORDER_RUO,
        },
        {
            host => 'database.factgrid.de',
            path => qr#^/wiki/(?:Item|Property):([QP][1-9][0-9]*)$#,
            source => 'factgrid',
            type => 'factgrid-identifier',
            id => \1,
            ise_order => ISEORDER_RUO,
            action => 'info',
        },
        {
            host => 'database.factgrid.de',
            path => qr#^/wiki/Special:EntityData/([QP][1-9][0-9]*)(?:\.[a-z]+)?$#,
            source => 'factgrid',
            type => 'factgrid-identifier',
            id => \1,
            ise_order => ISEORDER_RUO,
            action => 'metadata',
        },
        {
            host => 'www.wikitree.com',
            path => qr#^/wiki/(\D+-[1-9][0-9]*)$#,
            source => 'wikitree',
            type => 'wikitree-person-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'doi.org',
            path => qr#^/(10\.[0-9]{4,9}\/.+)$#,
            source => 'doi',
            type => 'doi',
            id => \1,
            action => 'info',
        },
        {
            host => 'dx.doi.org',
            path => qr#^/(10\.[0-9]{4,9}\/.+)$#,
            source => 'doi',
            type => 'doi',
            id => \1,
            action => 'metadata',
        },
        {
            host => 'iconclass.org',
            path => qr#^/(?:(?:de|en)/)?([0-9].*)\.[a-z]+$#,
            source => 'iconclass',
            type => 'iconclass-identifier',
            id => \1,
            action => 'metadata',
        },
        {
            host => 'iconclass.org',
            path => qr#^/(?:(?:de|en)/)?([0-9].*)$#,
            source => 'iconclass',
            type => 'iconclass-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.iana.org',
            path => qr#^/assignments/media-types/([a-z0-9\.\-\+]+\/[a-z0-9\.\-\+]+)$#,
            source => 'iana',
            type => 'media-subtype-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'oidref.com',
            path => qr#^/([0-2](?:\.[0-9]+)+)$#,
            source => 'oidref',
            type => 'oid',
            id => \1,
            action => 'info',
        },
        {
            host => 'www.furaffinity.net',
            path => qr#^/view/([1-9][0-9]*)/$#,
            source => 'furaffinity',
            type => 'furaffinity-post-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'imgur.com',
            path => qr#^/([0-9a-zA-Z]{7})$#,
            source => 'imgur',
            type => 'imgur-post-identifier',
            id => \1,
            action => 'info',
        },
        {
            host => 'i.imgur.com',
            path => qr#^/([0-9a-zA-Z]{7})\.[a-z]{3,4}$#,
            source => 'imgur',
            type => 'imgur-post-identifier',
            id => \1,
            action => 'file-fetch',
        },
        {
            host => 'notalwaysright.com',
            path => qr#^/[^/]+/([0-9]+)/$#,
            source => 'notalwaysright',
            type => 'notalwaysright-post-identifier',
            id => \1,
            action => 'render',
        },
        {
            host => 'blog.fefe.de',
            path => qr#^/$#,
            source => 'fefe',
            type => 'fefe-blog-post-identifier',
            action => 'render',
            id => sub {
                my ($self, $uri, $rule, $res) = @_;
                if ($uri->query =~ /^ts=([0-9a-f]{8})$/) {
                    return $1;
                }
                return undef;
            },
        },
        {
            host => 'blog.fefe.de',
            path => qr#^/rss\.xml$#,
            source => 'fefe',
            type => 'fefe-blog-post-identifier',
            action => 'metadata',
            id => sub {
                my ($self, $uri, $rule, $res) = @_;
                if ($uri->query =~ /^(?:html\&)?ts=([0-9a-f]{8})(?:\&html)?$/) {
                    return $1;
                }
                return undef;
            },
        },
        {
            host => 'schema.org',
            path => qr#^/[^/]+$#,
            source => 'schemaorg',
            type => 'uri',
            action => 'info',
            id => sub {
                my ($self, $uri, $rule, $res) = @_;
                return $uri;
            },
        },
        {
            host => 'purl.org',
            path => qr#^/dc/(?:elements/1\.1|terms|dcam|dcmitype)/[^/]+$#,
            source => 'purlorg',
            type => 'uri',
            action => 'info',
            id => sub {
                my ($self, $uri, $rule, $res) = @_;
                return $uri;
            },
        },
        {
            host => 'ruthe.de',
            path => qr#^/cartoon/([1-9][0-9]*)/datum/asc/#,
            source => 'ruthede',
            type => 'ruthede-comic-post-identifier',
            action => 'render',
            id => \1,
        },
        {
            host => 'ruthe.de',
            path => qr#^/static/cartoon_([1-9][0-9]*)\.html$#,
            source => 'ruthede',
            type => 'ruthede-comic-post-identifier',
            action => 'render',
            id => \1,
        },
    ],
);

my %syntax = (
    'uuid'                          => RE_UUID,
    'oid'                           => qr/^[1-3](?:\.(?:0|[1-9][0-9]*))+$/,
    'uri'                           => qr/^[a-zA-Z][a-zA-Z0-9\+\.\-]+:/,
    'tagname'                       => qr/./,
    'wikidata-identifier'           => qr/^[QP][1-9][0-9]*$/,
    'factgrid-identifier'           => qr/^[QP][1-9][0-9]*$/,
    'wikimedia-commons-identifier'  => qr/^File:.*$/,
    'musicbrainz-identifier'        => RE_UUID,
    'british-museum-term'           => qr/^[A-Z]+[1-9][0-9]{0,5}$/, # TODO: Find good reference; See also: https://www.wikidata.org/wiki/Property:P1711#P1793
    'gnd-identifier'                => qr/^1[012]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]$/, # https://www.wikidata.org/wiki/Property:P227#P1793
    'fellig-box-number'             => qr/^[1-9][0-9]{3}$/,
    'fellig-identifier'             => qr/^[A-Z]+[1-9][0-9]*$/,
    'youtube-video-identifier'      => qr/^.{11}$/,
    'e621tagtype'                   => qr/./,
    'amc-artist-identifier'         => qr/^[a-z]+(-[a-z]+)+$/,
    'tww-artist-identifier'         => qr/^[\p{L}\d]+(-[\p{L}\d]+)*$/,
    'grove-art-online-identifier'   => qr/^T(?:0|20|22)\d{5}$/,
    'wikitree-person-identifier'    => qr/^\D+-[1-9][0-9]*$/,
    'doi'                           => qr/^10\.[0-9]{4,9}\/.+$/,
    'iconclass-identifier'          => qr/^[0-9].*$/,
    'media-subtype-identifier'      => qr/^[a-z0-9\.\-\+]+\/[a-z0-9\.\-\+]+$/,
    'europeana-entity-identifier'   => qr/^(?:place|agent|concept|organisation)\/base\/[1-9][0-9]+$/,
    'open-library-identifier'       => qr/^(?:(?:person|place|time):)?[^:\n]+$/,
    'viaf-identifier'               => qr/^[1-9][0-9]+$/,
    'isni'                          => qr/^[0]{4} [0-9]{4} [0-9]{4} [0-9]{3}[0-9X]$/,
    'aev-identifier'                => qr/^[\w\/\d]+$/,
    'unesco-thesaurus-identifier'   => qr/^concept[0-9]+$/,
    'gtin'                          => qr/^[0-9]{8}(?:[0-9]{4,6})?$/,
    'language-tag-identifier'       => qr/^[0-9a-zA-Z-]+$/,
    'imgur-post-identifier'         => qr/^[0-9a-zA-Z]{7}$/,
    'fefe-blog-post-identifier'     => qr/^[0-9a-f]{8}$/,
    (map {'osm-'.$_ => RE_UINT} qw(node way relation)),
    (map {$_        => RE_UINT} qw(e621-post-identifier e621-pool-identifier xkcd-num ngv-artist-identifier ngv-artwork-identifier find-a-grave-identifier libraries-australia-identifier nla-trove-people-identifier agsa-creator-identifier a-p-and-p-artist-identifier geonames-identifier small-identifier chat-0-word-identifier furaffinity-identifier notalwaysright-post-identifier ruthede-comic-post-identifier)),
);

my %fellig_tables = (
    U   => 'users',
    P   => 'posts',
    TXT => 'texts',
);

my %media_subtype_to_ext = (
    'application/gzip'      => 'gz',
    'application/json'      => 'json',
    'application/ogg'       => 'ogg',
    'application/pdf'       => 'pdf',
    'application/vnd.debian.binary-package' => 'deb',
    'application/xml'       => 'xml',
    'audio/flac'            => 'flac',
    'audio/matroska'        => 'mkv',
    'audio/ogg'             => 'oga',
    'image/gif'             => 'gif',
    'image/jpeg'            => 'jpg',
    'image/png'             => 'png',
    'image/svg+xml'         => 'svg',
    'image/svg+xml'         => 'svg',
    'text/html'             => 'html',
    'text/plain'            => 'txt',
    'video/matroska'        => 'mkv',
    'video/matroska-3d'     => 'mkv',
    'video/ogg'             => 'ogv',
    'video/webm'            => 'webm',
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
    my $best_service;
    my $type_name;

    if (defined $type) {
        $type      = $extractor->name_to_ise(type => $type);
        $type_name = $extractor->ise_to_name(type => $type);

        croak 'Invalid syntax for identifier type' unless $id =~ $syntax{$type_name};
    }

    $ise_order //= ISEORDER_UOR;
    $service = $extractor->service($service) if defined $service;
    $action  = $extractor->name_to_ise(action  => $action) if defined $action;

    if (defined(my $best_service_name = $best_services{$type_name // ''})) {
        $best_service = $extractor->service($best_service_name);
    }

    if (defined($type_name) && $type_name eq 'uri') {
        # normalise a bit.
        $id =~ s#^http://schema\.org/#https://schema\.org/#;
    }

    $self->{primary} = {
        service      => $service,
        type         => $type,
        id           => $id,
        ise_order    => $ise_order,
        action       => $action,
        best_service => $best_service,
    };
    if (defined($type) && defined($id)) {
        $self->{id} = {
            $type => $id,
        };
    }
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
            next unless defined $host;
            if (ref($rule->{host})) {
                next unless $host =~ $rule->{host};
            } else {
                next unless $host eq $rule->{host};
            }
        }
        if (defined $rule->{path}) {
            next unless defined($path) && (@res = $path =~ $rule->{path});
        }

        foreach my $value (values %found) {
            if (my $ref = ref $value) {
                if ($ref eq 'SCALAR') {
                    $value = uri_unescape($res[${$value} - 1]);
                } elsif ($ref eq 'CODE') {
                    $value = $value->($self, $uri, $rule, \@res);
                }
            }
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

    if (defined $res->{url_overrides}) {
        $self->{url_overrides} //= {};
        $self->{url_overrides}{$service} //= $res->{url_overrides};
    }

    return $res;
}

sub _lookup_with_mode {
    my ($self, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $mode = $opts{mode};

    return if $mode eq 'online' && !$extractor->online;

    foreach my $pass (0..2) {
        my %done;
        foreach my $id_type_ise (keys %{$self->{id}}) {
            my $id_type = eval {$extractor->ise_to_name(type => $id_type_ise)} // next;
            foreach my $service (@{$lookup_services{$id_type}}) {
                next if $done{$service};
                $done{$service} = 1;
                $self->_lookup_one($service, %opts);
            }
        }
        foreach my $digest (keys %lookup_services_digest) {
            $self->digest($digest, as => 'hex', default => undef) // next;
            foreach my $service (@{$lookup_services_digest{$digest}}) {
                next if $done{$service};
                $done{$service} = 1;
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
    } elsif ($host eq 'uriid.org' && $path =~ m#^/(?:[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}|[a-z-]+|[a-zA-Z])/.+$#) {
        my ($prefix, $type, $id) = $uri->path_segments;
        if ($prefix eq '') {
            my Data::URIID::Service $uriid = $self->extractor->service('uriid');
            my $types = $uriid->_get_uriid_decompiled_types_json->{forward}{types};
            my $type_uuid;
            if ($type =~ RE_UUID) {
                $type_uuid = lc($type);
            } elsif (defined $types->{$type}{alias_for}) {
                $type_uuid = $types->{$type}{alias_for};
            }
            $self->_set(uriid => $type_uuid => $id, undef, 'info');
        }
    } elsif ($host eq 'uriid.org' || $host eq 'api.uriid.org') {
        my Data::URIID $extractor = $self->extractor;
        my %query = $uri->query_form;
        my $action = $host eq 'uriid.org' ? 'info' : 'metadata';

        if (defined($query{type}) && length($query{type}) && defined($query{id}) && length($query{id})) {
            my Data::URIID::Service $uriid = $extractor->service('uriid');
            my $types = $uriid->_get_uriid_decompiled_types_json->{forward}{types};
            my $type_uuid;
            if ($query{type} =~ RE_UUID) {
                $type_uuid = lc($query{type});
            } elsif (defined $types->{$query{type}}{alias_for}) {
                $type_uuid = $types->{$query{type}}{alias_for};
            }
            $self->_set(uriid => $type_uuid => $query{id}, undef, $action);
        } elsif (defined($query{for}) && length($query{for})) {
            my $old_online = $extractor->online;
            my $result;
            $extractor->online(0);
            $result = eval {$extractor->lookup($query{for})};
            $extractor->online($old_online);
            if (defined $result) {
                $self->_set(uriid => $result->id_type => $result->id, undef, $action);
            }
        }
    } elsif ($host eq 'static1.e621.net') {
        my @segments = $uri->path_segments;
        if (scalar(@segments) == 5 &&
            $segments[0] eq '' && $segments[1] eq 'data' &&
            length($segments[2]) == 2 && length($segments[3]) == 2 &&
            length($segments[4]) > 32) {
            my ($md5, $ext) = $segments[4] =~ /^([0-9a-f]{32})\.([0-9a-z]+)$/;
            $self->_set('e621', undef, undef, undef, 'file-fetch');
            $self->{primary}{ext} = $ext;
            $self->{primary}{digest} //= {};
            $self->{primary}{digest}{'md-5-128'} = $md5;
        }
    } elsif ($host eq 'files.fellig.org' || $host eq 'thumbnails.fellig.org') {
        my @segments = $uri->path_segments;
        if (scalar(@segments) == 5 &&
            $segments[0] eq '' && $segments[1] eq 'v2' && $segments[2] eq 'by' &&
            $segments[3] =~ /^[a-z]+-[0-9]+-[0-9]+$/ &&
            length($segments[4]) > 32) {
            my ($hash, $ext) = $segments[4] =~ /^([0-9a-f]{32,})\.([0-9a-z]+)$/;
            if (length($hash) == int(($segments[3] =~ /^[a-z]+-[0-9]+-([0-9]+)$/)[0]/4)) {
                $self->_set('fellig', undef, undef, undef, 'file-fetch');
                $self->{primary}{ext} = $ext;
                $self->{primary}{digest} //= {};
                $self->{primary}{digest}{$segments[3]} = $hash;
            }
        }
    }
}


sub id_type {
    my ($self, %opts) = @_;
    return $self->_cast_ise($self->{primary}{type}, 'ise', %opts);
}


sub _cast_id {
    my ($self, $src, $src_type, %opts) = @_;
    my $as = $opts{as} // 'raw';

    if ($as eq 'raw' || $as eq 'string' || $as eq $src_type) {
        return $src;
    } elsif ($as eq 'Data::Identifier') {
        return Data::Identifier->new($src_type => $src);
    } elsif ($as eq __PACKAGE__) {
        return $self->_as_lookup([$src_type => $src], %opts);
    } else {
        croak sprintf('Cannot convert identifier to type "%s"', $as);
    }
}

sub id {
    my ($self, $type, %opts);

    if (scalar(@_) % 2) {
        ($self, %opts) = @_;
        $type = $opts{type};
    } else {
        ($self, $type, %opts) = @_;
    }

    return $self->_cast_id($self->{primary}{id}, $self->{primary}{type}, %opts) unless defined $type;

    # We do a double convert of type here to ensure we have it the right way
    # independent of if we got name or ISE passed.
    $type = $self->extractor->name_to_ise(type => $type);
    if (defined $self->{id}{$type}) {
        return $self->_cast_id($self->{id}{$type}, $type, %opts);
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
                return $self->_cast_id($self->{id}{$type}, $type, %opts) if defined $self->{id}{$type};
            }
        }
    }

    croak 'Identifier type not supported';
}


sub _cast {
    my ($self, $key, $value, $source_type, $as, %opts) = @_;
    if ($as eq $source_type) {
        return $value;
    } else {
        if ($as eq 'string' && $source_type eq 'media_subtype') {
            return $value;
        } elsif ($as eq 'ise' && $source_type eq 'media_subtype') {
            return $self->_media_subtype_to_uuid($value);
        } elsif ($as eq 'string' && eval {$value->isa('URI')}) {
            return $value->as_string;
        } elsif ($as eq __PACKAGE__ && eval {$value->isa('URI')}) {
            return $self->_as_lookup([$value], %opts);
        } elsif ($as eq __PACKAGE__ && eval {$value->can('ise')}) {
            return $self->_as_lookup([ise => $value->ise], %opts);
        } elsif ($as eq 'ise' && eval {$value->can('ise')}) {
            return $value->ise;
        } elsif ($as eq 'rgb' && eval {$value->can('rgb')}) {
            return $value->rgb;
        } elsif (eval {$value->isa('Data::URIID::Base')} && defined(my $r = eval {$value->ise(as => $as)})) {
            return $r;
        } elsif (($as =~ /^[A-Z]/ || $as =~ /::/) && eval {$value->isa($as)}) {
            return $value;
        }

        if ($as eq __PACKAGE__ && defined(my $ise = eval{$self->attribute($key, %opts, as => 'ise')})) {
            return $self->_as_lookup([ise => $ise], %opts);
        }
    }

    croak sprintf('Cannot convert from type "%s" to "%s" for attribute "%s"', $source_type, $as, $key);
}
sub _cache_key {
    my ($self) = @_;
    return $self->{cache_key} //= sprintf('%s/%s', $self->{primary}{type}, $self->{primary}{id});
}
sub attribute {
    my ($self, $key, %opts) = @_;
    my $info = $attributes{$key} // croak sprintf('Unknown attribute "%s"', $key);
    my $as = $opts{as} // $info->{default_as} // $info->{source_type};
    my $value = $self->{primary}{$key};
    my @value;

    if (defined(my $cb = $info->{cb})) {
        $value = $self->$cb($key, %opts);
        @value = @{$value} if ref($value) eq 'ARRAY';
    } else {
        my $default_value;

        unless (defined($value) || ref($value) eq 'ARRAY') {
            $self->{offline_results} //= {};
            $self->{online_results}  //= {};

            @value = @{$value} if ref($value) eq 'ARRAY';

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

                    if (defined($value)) {
                        next unless defined $value;

                        if (ref($value) eq 'ARRAY') {
                            push(@value, @{$value});
                        } else {
                            last;
                        }
                    } elsif (ref($default_value) eq 'ARRAY') {
                        push(@value, @{$default_value});
                    }
                }
            }
        }

        $value //= $default_value;
    }

    if (defined $value) {
        my $cache = ($self->{attributes_cache} //= {})->{$key} //= {};
        my $source_type;

        $source_type = ref($value[0]) || ref($value) || $info->{source_type};
        $as //= $source_type;

        if (ref($value) eq 'ARRAY' xor $opts{list}) {
            croak sprintf('Invalid list mode for attribute "%s"', $key);
        }

        if (ref($value) eq 'ARRAY') {
            my %uniq;

            return @{$cache->{$as}} if defined $cache->{$as};

            foreach my $item (@value) {
                if (blessed $item) {
                    $uniq{$item->ise} = $item;
                } else {
                    my __PACKAGE__ $result = $self->_as_lookup($item, %opts);
                    $uniq{$result->_cache_key} = $result;
                }
            }

            $cache->{$as} = [map{$self->_cast($key => $_, $source_type => $as, %opts)} values %uniq];
            return @{$cache->{$as}};
        } else {
            return $cache->{$as} //= $self->_cast($key => $value, $source_type => $as, %opts);
        }
    }

    if (exists $opts{default}) {
        if ($opts{list}) {
            return @{$opts{default}};
        } else {
            return $opts{default};
        }
    }

    croak sprintf('No value found for attribute "%s"', $key);
}


sub digest {
    my ($self, $key, %opts) = @_;
    my $as = $opts{as} // 'hex';
    my $value;

    # convert L<Digest> name into utag name if needed:
    $key = $digest_name_converter{fc($key)} // $key;

    # Check utag name:
    if ($key !~ /^[a-z]+-[0-9]+-[1-9][0-9]*$/) {
        croak sprintf('Unknown digest format "%s"', $key);
    }

    unless (defined $value) {
        $self->{primary}{digest} //= {};
        $value = $self->{primary}{digest}{$key};
    }

    unless (defined $value) {
        $self->{offline_results} //= {};
        $self->{online_results}  //= {};

        foreach my $result (values(%{$self->{offline_results}}), values(%{$self->{online_results}})) {
            next unless defined($result) && defined($result->{digest});
            last if defined($value = $result->{digest}{$key});
        }
    }

    if (defined $value) {
        if ($as eq 'hex') {
            return $value;
        } elsif ($as eq 'binary') {
            return pack('H*', $value);
        } elsif ($as eq 'base64' || $as eq 'b64') {
            return MIME::Base64::encode(pack('H*', $value), '') =~ s/=+$//r;
        } elsif ($as eq 'base64_padded') {
            return MIME::Base64::encode(pack('H*', $value), '');
        } elsif ($as eq 'utag') {
            if (defined(my $size = eval {$self->attribute('final_file_size')})) {
                return sprintf('v0 %s bytes 0-%u/%u %s', $key, $size - 1, $size, $value);
            }

            return sprintf('v0 %s bytes 0-/* %s', $key, $value);
        } elsif ($as eq 'Digest') {
            return Data::URIID::Digest->_new($value);
        }

        croak sprintf('Cannot convert from type "%s" to "%s" for digest "%s"', 'hex', $as, $key);
    }

    return $opts{default} if exists $opts{default};

    croak sprintf('No value found for digest "%s"', $key);
}


sub available_keys {
    my ($self, $class) = @_;

    croak 'No class given' unless defined $class;

    if ($class eq 'attribute') {
        return keys %attributes;
    } elsif ($class eq 'digest') {
        # TODO: optimise this later.
        my %digest = %{$self->{primary}{digest} // {}};

        $self->{offline_results} //= {};
        $self->{online_results}  //= {};

        foreach my $result (values(%{$self->{offline_results}}), values(%{$self->{online_results}})) {
            next unless defined($result) && defined($result->{digest});
            %digest = (%digest, %{$result->{digest}});
        }

        return keys %digest;
    } else {
        croak 'Unknown class given: '.$class;
    }
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
    if (defined(my $id = eval {$self->id})) {
        my $id_type = $extractor->ise_to_name(type => $self->id_type);

        foreach my $template (@{$url_templates{$service} // []}) {
            my $t_opts = $template->[4] // {};

            next unless $id_type eq $template->[0];

            next if defined($template->[2]) && $id !~ $template->[2];
            next unless $self->_match_actions($template, \%opts);

            return URI->new(sprintf($template->[1], $t_opts->{no_escape} ? $id : uri_escape_utf8($id)));
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

        return URI->new(sprintf($t_template, $t_opts->{no_escape} ? $id : uri_escape_utf8($id)));
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

    if ($service eq 'uriid' && defined(my $type = eval {$self->id_type})) {
        my Data::URIID::Service $uriid = $extractor->service($service);
        my $types = $uriid->_get_uriid_decompiled_types_json;

        $type = $types->{backward}{$type} // $type;

        if (defined($opts{action}) && $opts{action} eq 'info') {
            my $u = URI->new("https://uriid.org/");
            $u->path_segments('', $type, $self->id);
            return $u;
        }
    }

    # Now try digest based:
    {
        my %base = (
            ext => $self->attribute('ext', default => undef),
        );

        unless (defined($base{ext})) {
            my $media_subtype = $self->attribute('media_subtype', as => 'media_subtype', default => undef);
            if (defined $media_subtype) {
                $base{ext} = $media_subtype_to_ext{$media_subtype};
            }
        }

        foreach my $digest ($self->available_keys('digest')) {
            my $value = $self->digest($digest, default => undef) // next;
            my %map = (%base, digest => $value);

            foreach my $tpl (@{$digest_url_templates{$service}}) {
                my ($t_digest, $t_url, $t_actions) = @{$tpl};
                my $url;
                next unless $t_digest eq $digest;
                next unless $self->_match_actions([undef, undef, undef, $t_actions], \%opts);

                $url = $t_url;
                $url =~ s/%\{([a-z]+)(?:,([0-9]+)(?:,([0-9]+))?)?\}/uri_escape_utf8(substr($map{$1} || next, $2 || 0, $3 || 9999))/ge;

                return URI->new($url);
            }
        }
    }

    if (defined($self->{url_overrides}) && defined($self->{url_overrides}{$service})) {
        if (defined(my $action = $opts{action})) {
            if (defined(my $url = $self->{url_overrides}{$service}{$action})) {
                return URI->new($url);
            }
        }
    }

    return $opts{default} if exists $opts{default};
    croak 'Identifier does not generate a URL for the selected service';
}

# Converters:

sub _media_subtype_to_uuid {
    my ($pkg, $media_subtype) = @_;
    state $uuids = {};
    return $uuids->{$media_subtype} //= create_uuid_as_string(UUID_SHA1, '50d7c533-2d9b-4208-b560-bcbbf75ce3f9', lc $media_subtype);
}

sub _id_conv__uuid__wikidata_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = create_uuid_as_string(UUID_SHA1, '9e10aca7-4a99-43ac-9368-6cbfa43636df', lc $id);
}

sub _id_conv__uuid__gtin {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = create_uuid_as_string(UUID_SHA1, 'd95d8b1f-5091-4642-a6b0-a585313915f1', lc $id);
}

sub _id_conv__uuid__media_subtype_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = $self->_media_subtype_to_uuid($id);
}

sub _id_conv__uuid__language_tag_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = create_uuid_as_string(UUID_SHA1, '47dd950c-9089-4956-87c1-54c122533219', lc $id);
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

sub _id_conv__doi__grove_art_online_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = sprintf('10.1093/gao/9781884446054.article.%s', $id);
}

sub _id_conv__uri__fefe_blog_post_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = sprintf('https://blog.fefe.de/?ts=%s', $id);
}

sub _id_conv__uuid__e621_post_identifier {
    my ($self, $type_want, $type_name_have, $id) = @_;
    $self->{id}{$type_want} = create_uuid_as_string(UUID_SHA1, 'ac59062c-6ba2-44de-9f54-09e28f2c0b5c', lc $id);
}

# --- Overrides for Data::URIID::Base ---
sub ise {
    my ($self, %opts) = @_;

    {
        my $type_name = $self->extractor->ise_to_name(type => $self->id_type);
        if ($type_name eq 'uuid' || $type_name eq 'oid' || $type_name eq 'uri') {
            return $self->_cast_ise($self->id, $type_name, %opts);
        }
    }

    foreach my $type (@{$self->{primary}{ise_order}}) {
        my $id = eval { $self->id($type) };
        return $self->_cast_ise($id, $type, %opts) if defined $id;
    }

    return $opts{default} if exists $opts{default};
    croak 'Identifier does not map to an ISE';
}

sub displayname {
    my ($self, %opts) = @_;
    my $v = $self->attribute('displayname', default => undef);
    return $v if defined $v;
    return $self->SUPER::displayname(%opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Result - Extractor for identifiers from URIs

=head1 VERSION

version v0.13

=head1 SYNOPSIS

    use Data::URIID;

    my $extractor = Data::URIID->new;
    my $result = $extractor->lookup( $URI );

This module provides access to results from a lookup.

This package inherits from L<Data::URIID::Base>.

=head1 METHODS

=head2 id_type

    my $id_type = $result->id_type( [%opts] );

This method will return the ISE of the id's type if successful or C<die> otherwise.

This takes the same options as L<Data::URIID::Base/ise>

=head2 id

    my $id = $result->id;
    # or:
    my $id = $result->id( $type );
    # or:
    my $id = $result->id( %opts );

This method will return the id if successful or C<die> otherwise.

The following options are defined. All options are optional.

=over

=item C<as>

Return the value as the given type.
This is the package name of the type, C<raw> for plain perl strings.
If the given type is not supported for the given attribute the function C<die>s.

=item C<online>

Overrides the L<Data::URIID/"online"> flag used for the lookup if C<as> is set to L<Data::URIID::Result>.
This is very useful to prevent network traffic for auxiliary lookups.

=item C<type>

The type of the identifier to return.

=back

=head2 attribute

    my $value = $result->attribute( $key, [%opts] );

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

=item C<best_service>

The L<Data::URIID::Service> best used with this identifier.
This is normally the service the identifier type originated from.

=item C<date_of_birth>

The date of birth of the person or object.

B<Warning:> This is an experimental attribute and may be removed or changed later!

=item C<date_of_death>

The date of death of the person or object.

B<Warning:> This is an experimental attribute and may be removed or changed later!

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

=item C<media_subtype>

Media subtype of the item.

B<Warning:> This is an experimental attribute and may be removed or changed later!

=item C<roles>

List of roles returned by the lookup for the subject.
This attribute requires C<list> to be set true.

=item C<service>

The L<Data::URIID::Service> the original URL was using.

=item C<sources>

The list of L<Data::URIID::Service> that returned data in the lookup. Useful to provide a bibliography.
This attribute requires C<list> to be set true.

=item C<sex_or_gender>

The sex or gender of the object. This is useful when addressing people.

=item C<space_object>

The object in space (astronomical body) this item is on.

=item C<thumbnail>

A thumbnail image that can be used for the item.

=item C<website>

A website that represents the item. For example if the item is a company the website of that company.

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

=item C<list>

Sets the function in list mode. List mode is used for special attributes that are lists.
In this mode this method will return a list. C<default> if used needs to be set to some array reference.
This mode is only available with list mode keys.

=item C<online>

Overrides the L<Data::URIID/"online"> flag used for the lookup if C<as> is set to L<Data::URIID::Result>.
This is very useful to prevent network traffic for auxiliary lookups.

=back

=head2 digest

    my $digest = $result->digest( $algorithm, [%opts] );

Returns a digest of the referenced file or object. This refers to the result of URLs for the C<fetch> or C<file-fetch> actions.

Supported algorithms depend on the providing service. Algorithm names are given in the universal tag form but
aliases for names as by L<Digest> are supported.

Common values include: C<md-5-128>, C<sha-1-160>, C<sha-2-256>, and C<sha-3-512>.

The following options are defined:

=over

=item C<as>

Return the value as the given type.
This is the package name of the type, C<hex> for hex values, or C<base64> (or C<b64>) for Base64 encoding without padding
and C<base64_padded> for Base64 encoding with padding.
To get an object that is compatible with the L<Digest> API use C<Digest>. Do not try to use specific types such as C<Digest::MD5>.
If the given type is not supported for the given attribute the function C<die>s.

=item C<default>

Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

=back

=head2 available_keys

    my @keys = $result->available_keys( $class );

Returns the list of keys available for C<$class>.
Currently C<attribute> for keys valid for L<"attribute"> and
C<digest> for keys valid for L<"digest"> are supported.

The caller must not assume that all values for keys returned by this method are actually set/available.
This method may return an empty list.

On any error this method will C<die>.

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

=item C<default>

Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

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

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
