# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2025 Philipp Schafft

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

our $VERSION = v0.15;

use parent 'Data::URIID::Base';

my $HAVE_HTML_TreeBuilder_XPath = eval {require HTML::TreeBuilder::XPath; 1;};

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

my @fellig_types = qw(fellig-identifier fellig-box-number uuid oid uri wikidata-identifier e621-post-identifier e621-pool-identifier wikimedia-commons-identifier british-museum-term musicbrainz-identifier gnd-identifier e621tagtype);

my %attrmap_osm = (
    name        => 'displayname',
    description => 'description',
);

my %attrmap_open_graph = (
    title       => 'displayname',
    description => 'description',
    image       => 'thumbnail',
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
        'language-tag-identifier' => {
            en => {attributes => {displayname => {'*' => 'English'}}},
            de => {attributes => {displayname => {'*' => 'German'}}},
        },
        'small-identifier' => {
            map {$_->{sid} => {
                    ids => {
                        uuid => $_->{uuid},
                    },
                    attributes => {
                        displayname => {'*' => $_->{name}},
                    },
                }} (
                {uuid => 'ddd60c5c-2934-404f-8f2d-fcb4da88b633', sid => 1, name => 'also-shares-identifier'},
                {uuid => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', sid => 2, name => 'uuid'},
                {uuid => 'bfae7574-3dae-425d-89b1-9c087c140c23', sid => 3, name => 'tagname'},
                {uuid => '7f265548-81dc-4280-9550-1bd0aa4bf748', sid => 4, name => 'has-type'},
                {uuid => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439', sid => 5, name => 'uri'},
                {uuid => 'd08dc905-bbf6-4183-b219-67723c3c8374', sid => 6, name => 'oid'},
                # Unassigned: 7
                {uuid => 'd0a4c6e2-ce2f-4d4c-b079-60065ac681f1', sid => 8, name => 'language-tag-identifier'},
                {uuid => 'ce7aae1e-a210-4214-926a-0ebca56d77e3', sid => 9, name => 'wikidata-identifier'},
                {uuid => '923b43ae-a50e-4db3-8655-ed931d0dd6d4', sid => 10, name => 'specialises'},
                {uuid => 'eacbf914-52cf-4192-a42c-8ecd27c85ee1', sid => 11, name => 'unicode-string'},
                {uuid => '928d02b0-7143-4ec9-b5ac-9554f02d3fb1', sid => 12, name => 'integer'},
                {uuid => 'dea3782c-6bcb-4ce9-8a39-f8dab399d75d', sid => 13, name => 'unsigned-integer'},
                # Unassigned: 14 - 15
                {uuid => '6ba648c2-3657-47c2-8541-9b73c3a9b2b4', sid => 16, name => 'default-context'},
                {uuid => '52a516d0-25d8-47c7-a6ba-80983e576c54', sid => 17, name => 'proto-file'},
                {uuid => '1cd4a6c6-0d7c-48d1-81e7-4e8d41fdb45d', sid => 18, name => 'final-file-size'},
                {uuid => '6085f87e-4797-4bb2-b23d-85ff7edc1da0', sid => 19, name => 'text-fragment'},
                {uuid => '4c9656eb-c130-42b7-9348-a1fee3f42050', sid => 20, name => 'also-list-contains-also'},
                {uuid => '298ef373-9731-491d-824d-b2836250e865', sid => 21, name => 'proto-message'},
                {uuid => '7be4d8c7-6a75-44cc-94f7-c87433307b26', sid => 22, name => 'proto-entity'},
                {uuid => '65bb36f2-b558-48af-8512-bca9150cca85', sid => 23, name => 'proxy-type'},
                {uuid => 'a1c478b5-0a85-4b5b-96da-d250db14a67c', sid => 24, name => 'flagged-as'},
                {uuid => '59cfe520-ba32-48cc-b654-74f7a05779db', sid => 25, name => 'marked-as'},
                {uuid => '2bffc55d-7380-454e-bd53-c5acd525d692', sid => 26, name => 'roaraudio-error-number'},
                {uuid => 'f87a38cb-fd13-4e15-866c-e49901adbec5', sid => 27, name => 'small-identifier'},
                {uuid => 'd2750351-aed7-4ade-aa80-c32436cc6030', sid => 28, name => 'also-has-role'},
                # Unassigned: 29 - 31
                {uuid => '448c50a8-c847-4bc7-856e-0db5fea8f23b', sid => 32, name => 'final-file-encoding'},
                {uuid => '79385945-0963-44aa-880a-bca4a42e9002', sid => 33, name => 'final-file-hash'},
                {uuid => '3fde5688-6e34-45e9-8f33-68f079b152c8', sid => 34, name => 'SEEK_SET'},
                {uuid => 'bc598c52-642e-465b-b079-e9253cd6f190', sid => 35, name => 'SEEK_CUR'},
                {uuid => '06aff30f-70e8-48b4-8b20-9194d22fc460', sid => 36, name => 'SEEK_END'},
                {uuid => '59a5691a-6a19-4051-bc26-8db82c019df3', sid => 37, name => 'inode'},
                {uuid => 'ae8ec1de-38ec-4c58-bbd7-7ff43e1100fc', sid => 38, name => 'in-reply-to'},
                {uuid => '8a31868b-0a26-42e0-ac54-819a9ed9dcab', sid => 39, name => 'in-response-to'},
                {uuid => 'ffa893a2-9a0e-4013-96b4-307e2bca15b9', sid => 40, name => 'has-message-body'},
                {uuid => 'b72508ba-7fb9-42ae-b4cf-b850b53a16c2', sid => 41, name => 'account'},
                # Unassigned: 42
                {uuid => '4e855294-4b4f-443e-b67b-8cb9d733a889', sid => 43, name => 'backwards'},
                {uuid => '6ad2c921-7a3e-4859-ae02-98e42522e2f8', sid => 44, name => 'forwards'},
                # Unassigned: 45 - 47
                {uuid => 'dd8e13d3-4b0f-5698-9afa-acf037584b20', sid => 48, name => 'zero'},
                {uuid => 'bd27669b-201e-51ed-9eb8-774ba7fef7ad', sid => 49, name => 'one'},
                {uuid => '73415b5a-31fb-5b5a-bb82-8ea5eb3b12f7', sid => 50, name => 'two'},
                # Unassigned: 51
                {uuid => 'e425be57-58cb-43fb-ba85-c1a55a6a2ebd', sid => 52, name => 'ancestor-of'},
                {uuid => 'cdee05f4-91ec-4809-a157-8c58dcb23715', sid => 53, name => 'descendant-of'},
                {uuid => '26bda7b1-4069-4003-925c-2dbf47833a01', sid => 54, name => 'sibling-of'},
                {uuid => 'a75f9010-9db3-4d78-bd78-0dd528d6b55d', sid => 55, name => 'see-also'},
                {uuid => 'd1963bfc-0f79-4b1a-a95a-b05c07a63c2a', sid => 56, name => 'also-at'},
                {uuid => 'c6e83600-fd96-4b71-b216-21f0c4d73ca6', sid => 57, name => 'also-shares-colour'},
                {uuid => 'a942ba41-20e6-475e-a2c1-ce891f4ac920', sid => 58, name => 'also-identifies-as'},
                {uuid => 'ac14b422-e7eb-4e5b-bccd-ad5a65aeab96', sid => 59, name => 'also-is-identified-as'},
                {uuid => '3c2c155f-a4a0-49f3-bdaf-7f61d25c6b8c', sid => 60, name => 'Earth'},
                {uuid => 'fade296d-c34f-4ded-abd5-d9adaf37c284', sid => 61, name => 'black'},
                {uuid => '1a2c23fa-2321-47ce-bf4f-5f08934502de', sid => 62, name => 'white'},
                {uuid => 'f9bb5cd8-d8e6-4f29-805f-cc6f2b74802d', sid => 63, name => 'grey'},
                {uuid => 'dd708015-0fdd-4543-9751-7da42d19bc6a', sid => 64, name => 'Sun'},
                {uuid => '23026974-b92f-4820-80f6-c12f4dd22fca', sid => 65, name => 'Luna'},
                # Unassigned: 66 - 74
                {uuid => 'd642eff3-bee6-5d09-aea9-7c47b181dd83', sid => 75, name => 'male'},
                {uuid => 'db9b0db1-a451-59e8-aa3b-9994e683ded3', sid => 76, name => 'female'},
                {uuid => 'f6249973-59a9-47e2-8314-f7cf9a5f77bf', sid => 77, name => 'person'},
                {uuid => '5501e545-f39a-4d62-9f65-792af6b0ccba', sid => 78, name => 'body'},
                {uuid => 'a331f2c5-20e5-4aa2-b277-8e63fd03438d', sid => 79, name => 'character'},
                {uuid => '838eede5-3f93-46a9-8e10-75165d10caa1', sid => 80, name => 'cat'},
                {uuid => '252314f9-1467-48bf-80fd-f8b74036189f', sid => 81, name => 'dog'},
                {uuid => '571fe2aa-95f6-4b16-a8d2-1ff4f78bdad1', sid => 82, name => 'lion'},
                {uuid => '36297a27-0673-44ad-b2d8-0e4e97a9022d', sid => 83, name => 'tiger'},
                {uuid => '5d006ca0-c27b-4529-b051-ac39c784d5ee', sid => 84, name => 'fox'},
                {uuid => '914b3a09-4e01-4afc-a065-513c199b6c24', sid => 85, name => 'squirrel'},
                {uuid => '95f1b56e-c576-4f32-ac9b-bfdd397c36a6', sid => 86, name => 'wolf'},
                {uuid => 'dcf8f4f0-c15e-44bd-ad76-0d483079db16', sid => 87, name => 'human'},
                # Unassigned: 88
                {uuid => 'f901e5e0-e217-41c8-b752-f7287af6e6c3', sid => 89, name => 'mammal'},
                {uuid => '7ed4160e-06d6-44a2-afe8-457e2228304d', sid => 90, name => 'vertebrate'},
                {uuid => '0510390c-9604-4362-b603-ea09e48de7b7', sid => 91, name => 'animal'},
                {uuid => 'bccdaf71-0c82-422e-af44-bb8396bf90ed', sid => 92, name => 'plant'},
                {uuid => 'a0b8122e-d11b-4b78-a266-0bb90d1c1cbe', sid => 93, name => 'fungus'},
                {uuid => '3e92ac2d-f8fe-48bf-acd7-8505d23d07ab', sid => 94, name => 'organism'},
                {uuid => '115c1bcf-02cd-4a57-bd02-1d9f1ea8dd01', sid => 95, name => 'any-taxon'},
                {uuid => 'd2526d8b-25fa-4584-806b-67277c01c0db', sid => 96, name => 'inode-number'},
                {uuid => 'cd5bfb11-620b-4cce-92bd-85b7d010f070', sid => 97, name => 'also-on-filesystem'},
                {uuid => '63c1da19-0dd6-4181-b3fa-742b9ceb2903', sid => 98, name => 'filesystem'},
                {uuid => '5ecb4562-dad7-431d-94a6-d301dcea8d37', sid => 99, name => 'parent'},
                {uuid => '1a9215b2-ad06-4f4f-a1e7-4cbb908f7c7c', sid => 100, name => 'child'},
                {uuid => 'a7cfbcb0-45e2-46b9-8f60-646ab2c18b0b', sid => 101, name => 'displaycolour'},
                # Unassigned: 102
                {uuid => 'd926eb95-6984-415f-8892-233c13491931', sid => 103, name => 'tag-links'},
                {uuid => '2c07ddc1-bdb8-435a-9614-4e6782a5101f', sid => 104, name => 'tag-linked-by'},
                {uuid => '4efce01d-411e-5e9c-9ed9-640ecde31d1d', sid => 105, name => 'parallel'},
                {uuid => '9aad6c99-67cd-45fd-a8a6-760d863ce9b5', sid => 106, name => 'also-where'},
                {uuid => '8efbc13b-47e5-4d92-a960-bd9a2efa9ccb', sid => 107, name => 'generated-by'},
                # Unassigned: 108
                {uuid => '83e3acbb-eb8d-4dfb-8f2f-ae81cc436d4b', sid => 109, name => 'batch'},
                {uuid => 'b17f36c6-c397-4e84-bd32-1eccb3f00671', sid => 110, name => 'set'},
                {uuid => 'aa9d311a-89b7-44cc-a356-c3fc93dfa951', sid => 111, name => 'category'},
                {uuid => '2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a', sid => 112, name => 'chat-0-word-identifier'},
                # Unassigned: 113 - 118
                {uuid => 'c9ec3bea-558e-4992-9b76-91f128b6cf29', sid => 119, name => 'red'},
                {uuid => 'c0e957d0-b5cf-4e53-8e8a-ff0f5f2f3f03', sid => 120, name => 'green'},
                {uuid => '3dcef9a3-2ecc-482d-a98b-afffbc2f64b9', sid => 121, name => 'blue'},
                {uuid => 'abcbf48d-c302-4be1-8c5c-a8de4471bcbb', sid => 122, name => 'cyan'},
                {uuid => 'a30d070d-9909-40d4-a33a-474c89e5cd45', sid => 123, name => 'magenta'},
                {uuid => '2892c143-2ae7-48f1-95f4-279e059e7fc3', sid => 124, name => 'yellow'},
                {uuid => '5c41829f-5062-4868-9c31-2ec98414c53d', sid => 125, name => 'orange'},
                {uuid => 'c90acb33-b8ea-4f55-bd86-beb7fa5cf80a', sid => 126, name => 'savannah'},
                # Unassigned: 127 - 131
                {uuid => 'caf11e36-d401-4521-8f10-f6b36125415c', sid => 132, name => 'icon'},
                {uuid => 'e7330249-53b8-4dab-aa43-b5bfa331a8e5', sid => 133, name => 'thumbnail'},
                {uuid => '2ec4a6b0-e6bf-40cd-96a2-490cbc8d6c4b', sid => 134, name => 'empty-set'},
                # Unassigned: 135 - 143
                {uuid => 'be6d8e00-a6c1-5c44-8ffc-f7393e14aa23', sid => 144, name => 'three'},
                {uuid => '79422b2c-b6f6-547f-949f-0cba44fa69b7', sid => 145, name => 'four'},
                # Unassigned: 146 - 158
                {uuid => '7cb67873-33bc-4a93-b53f-072ce96c6f1a', sid => 159, name => 'hrair'},
                {uuid => '82d529be-0f00-4b4f-a43f-4a22de5f5312', sid => 160, name => 'gtin'},
                {uuid => 'e8c156be-4fe7-4b13-b4fa-e207213caef8', sid => 161, name => 'subject-type'},
                # Unassigned: 163 - 175
                {uuid => 'c44ee482-0fb7-421b-9aad-a6c8f099a4b6', sid => 176, name => 'Universe'},
                {uuid => '0ac40a25-d20f-42ed-ae1c-64e62a56d673', sid => 177, name => 'Observable universe'},
                # Unassigned: 178 - 188
                {uuid => '8a1cb2d6-df2f-46db-89c3-a75168adebf6', sid => 189, name => 'generator'},
                {uuid => '3c9f40b4-2b98-44ce-b4dc-97649eb528ae', sid => 190, name => 'using-namespace'},
                {uuid => 'bc2d2e7c-8aa4-420e-ac07-59c422034de9', sid => 191, name => 'for-type'},
                {uuid => '5cbdbe1c-e8b6-4cac-b274-b066a7f86b28', sid => 192, name => 'left'},
                {uuid => '3b1858a9-996b-4831-b600-eb55ab7bb0d1', sid => 193, name => 'right'},
                {uuid => 'f158e457-9a75-42ac-b864-914b34e813c7', sid => 194, name => 'up'},
                {uuid => '4c834505-8e77-4da6-b725-e11b6572d979', sid => 195, name => 'down'},
                # Unassigned: 196 - 207
                {uuid => 'fd324dee-4bc7-4716-bf0c-6d50a69961b7', sid => 208, name => 'north'},
                {uuid => '8685e1d8-f313-403a-9f4d-48fce22f9312', sid => 209, name => 'east'},
                {uuid => 'c65c5baf-630e-4a28-ace5-1082b032dd07', sid => 210, name => 'south'},
                {uuid => '7ed25dc4-5afc-4b39-8446-4df7748040a4', sid => 211, name => 'west'},
                {uuid => '7ce365d8-71d2-4bd6-95c9-888a8f1d834c', sid => 212, name => 'northeast'},
                {uuid => '39be7db6-1dc7-41c3-acd2-de19ad17a97f', sid => 213, name => 'northwest'},
                {uuid => '33233365-20ec-4073-9962-0cb4b1b1e48d', sid => 214, name => 'southeast'},
                {uuid => 'b47ecfde-02b1-4790-85dd-c2e848c89d2e', sid => 215, name => 'southwest'},
            ),
        },
        'uuid' => {
            map {$_->{uuid} => {
                    attributes => {
                        displayname => {'*' => $_->{name}},
                    },
                }} (
                {uuid => '878aac4c-581b-4257-998c-19a9c4003d22', name => 'colour'},
            ),
        },
    );

    foreach my $id (keys %{$own_well_known{'wikidata-identifier'}}) {
        my $uuid = create_uuid_as_string(UUID_SHA1, '9e10aca7-4a99-43ac-9368-6cbfa43636df', lc $id);
        $own_well_known{uuid}{$uuid} = $own_well_known{'wikidata-identifier'}{$id};
    }

    my @colours = (
        # Abstract colours:
        [black    => 'fade296d-c34f-4ded-abd5-d9adaf37c284' => '#000000'],
        [white    => '1a2c23fa-2321-47ce-bf4f-5f08934502de' => '#ffffff'],
        [red      => 'c9ec3bea-558e-4992-9b76-91f128b6cf29' => '#ff0000'],
        [green    => 'c0e957d0-b5cf-4e53-8e8a-ff0f5f2f3f03' => '#008000'],
        [blue     => '3dcef9a3-2ecc-482d-a98b-afffbc2f64b9' => '#0000ff'],
        [cyan     => 'abcbf48d-c302-4be1-8c5c-a8de4471bcbb' => '#00ffff'],
        [magenta  => 'a30d070d-9909-40d4-a33a-474c89e5cd45' => '#ff00ff'],
        [yellow   => '2892c143-2ae7-48f1-95f4-279e059e7fc3' => '#ffff00'],
        [grey     => 'f9bb5cd8-d8e6-4f29-805f-cc6f2b74802d' => '#808080'],
        [orange   => '5c41829f-5062-4868-9c31-2ec98414c53d' => '#ff8000'],
        [savannah => 'c90acb33-b8ea-4f55-bd86-beb7fa5cf80a' => '#decc9c'],

        # VGA colours:
        [black    => '32f5e924-0ddb-4427-ad81-2d099b590c68' => '#000000'],
        [maroon   => '2aeedebd-2814-41b3-9cfd-f992e9a60827' => '#800000'],
        [green    => 'd045d86c-3437-4b42-aa77-2d7ac6ff1656' => '#008000'],
        [olive    => 'a64b447b-3eb3-4a71-92fe-f4399e845892' => '#808000'],
        [navy     => 'f8ace5ee-45a9-4e46-8324-095b6ab452b5' => '#000080'],
        [purple   => '7cd1228f-b55b-4b86-a057-f620e7934f7f' => '#800080'],
        [teal     => 'c7d4cc0e-dd3b-465c-b1ed-6fea3d424b9f' => '#008080'],
        [gray     => 'aa82b49e-12c2-41a4-9fd8-800957be9161' => '#808080'],
        [silver   => 'cdb01cbf-0eca-4aad-b732-caf55abc7566' => '#C0C0C0'],
        [red      => '6d62509a-aac5-412b-953b-e002867090ef' => '#FF0000'],
        [lime     => '18b0ad77-95a1-4ddc-8a3e-52fb1fca2ead' => '#00FF00'],
        [yellow   => 'b85fca40-ab8e-4ab3-b582-43cb0979b994' => '#FFFF00'],
        [blue     => '7f2e2d6a-ec70-417b-8418-a5d67c05b7e0' => '#0000FF'],
        [fuchsia  => '465087e0-a8d0-4a42-8f05-a1aea0d53385' => '#FF00FF'],
        [aqua     => '4feff8a2-dbe4-447b-b052-db333b9ebee3' => '#00FFFF'],
        [white    => 'a671d5f4-5a1d-498d-b3ec-52b92f15218e' => '#FFFFFF'],
    );
    my $colour_roles = {'*' => [[URI->new('urn:uuid:878aac4c-581b-4257-998c-19a9c4003d22')]]};
    my @displaycolours;

    foreach my $list (\@colours, \@displaycolours) {
        foreach my $colour (@{$list}) {
            my ($name, $uuid, $displaycolour) = @{$colour};
            my $e = ($own_well_known{uuid}{$uuid} //= {})->{attributes} //= {};
            my $colour_object = Data::URIID::Colour->new(rgb => $displaycolour, register => 1);

            if (defined $name) {
                $e->{displayname} //= {};
                $e->{displayname}{'*'} //= $name;
            }

            $e->{displaycolour} //= {};
            $e->{displaycolour}{'*'} //= $colour_object;
            $e->{roles} = $colour_roles;

            if ($list != \@displaycolours) {
                push(@displaycolours, [undef, $colour_object->ise, $displaycolour]);
            }
        }
    }

    # Add an entry for each colour used.
    foreach my $type (keys %own_well_known) {
        foreach my $entry (values %{$own_well_known{$type}}) {
            my $dpca = $entry->{attributes}{displaycolour} // next;
            my $displaycolour = $dpca->{'*'} // next;
            my $e = ($own_well_known{uuid}{$displaycolour->ise} //= {})->{attributes} //= {};
            $e->{displaycolour} //= {};
            $e->{displaycolour}{'*'} //= $displaycolour;
        }
    }

    foreach my $language (keys %{$own_well_known{'language-tag-identifier'}}) {
        my $uuid = create_uuid_as_string(UUID_SHA1, '47dd950c-9089-4956-87c1-54c122533219', lc $language);
        $own_well_known{uuid}{$uuid} = $own_well_known{'language-tag-identifier'}{$language};
    }
    # Mix and match entries by identifiers to speed up lookups.
    # This step must always be the last one.
    foreach my $id_type_outer (keys %own_well_known) {
        foreach my $src_id (keys %{$own_well_known{$id_type_outer}}) {
            my $src     = $own_well_known{$id_type_outer}{$src_id};
            my $s_ids   = $src->{ids} //= {};
            my $s_attrs = $src->{attributes} //= {};

            $s_ids->{$id_type_outer} = $src_id;

            foreach my $id_type_inner (keys %{$s_ids}) {
                my $dst = ($own_well_known{$id_type_inner} //= {})->{$s_ids->{$id_type_inner}} //= {};
                if ($src != $dst) {
                    my $d_ids   = $dst->{ids} //= {};
                    my $d_attrs = $dst->{attributes} //= {};

                    $s_ids->{$_}   //= $d_ids->{$_}   foreach keys %{$d_ids};
                    $s_attrs->{$_} //= $d_attrs->{$_} foreach keys %{$d_attrs};
                    $own_well_known{$id_type_inner}{$s_ids->{$id_type_inner}} = $src;
                }
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
            qw(uuid oid uri),                                                   # ISE,
            keys %{_own_well_known()},
        ],
        'Data::Identifier'      => [
            qw(uuid oid uri),                                                   # ISE,
            qw(e621-post-identifier e621-pool-identifier e621tagtype e621tag),  # e621
            qw(danbooru2chanjp-post-identifier danbooru2chanjp-tag),            # danbooru2chanjp
            keys %{_own_well_known()},
        ],
        'factgrid'              => [values(%{$config_factgrid->{idmap}}), qw(factgrid-identifier)],
        'doi'                   => [qw(doi)],
        'iconclass'             => ['iconclass-identifier'],
        'xkcd'                  => ['xkcd-num'],
        'e621'                  => ['e621-post-identifier', 'e621-pool-identifier'],
        'furaffinity'           => ['furaffinity-post-identifier'],
        'imgur'                 => ['imgur-post-identifier'],
        'notalwaysright'        => ['notalwaysright-post-identifier'],
        'ruthede'               => ['ruthede-comic-post-identifier'],
        'danbooru2chanjp'       => ['danbooru2chanjp-post-identifier'],
    }
}

sub _extra_lookup_services_digests {
    return {
        'e621'                  => ['md-5-128'],
    };
}

# Private helper:
sub _get_html {
    my ($self, $url, %opts) = @_;

    if ($self->setting('network_deny')) {
        return undef;
    }

    if ($HAVE_HTML_TreeBuilder_XPath) {
        my Data::URIID $extractor = $self->extractor;

        if (defined(my $query = $opts{query})) {
            $url = ref($url) ? $url->clone : URI->new($url);
            $url->query_form($url->query_form, %{$query});
        }

        # We cannot use decoded_content()'s charset decoding here as it's buggy for JSON (and others?) response (at least in v6.18).
        return eval {
            my $msg = $extractor->_ua->get($url, 'Accept' => 'text/html');
            return undef unless $msg->is_success;
            my $val = $msg->decoded_content(ref => 1, charset => 'none');
            my $r = HTML::TreeBuilder::XPath->new;
            $r->parse(decode($msg->content_charset, $$val));
            $r->eof;
            $r;
        };
    } else {
        return undef;
    }
}

# Private helper:
sub _get_json {
    my ($self, $url, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;

    if ( $self->setting('network_deny') ) {
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

    if (defined(my $query = $opts{query})) {
        $url = ref($url) ? $url->clone : URI->new($url);
        $url->query_form($url->query_form, %{$query});
    }

    # We cannot use decoded_content()'s charset decoding here as it's buggy for JSON response (at least in v6.18).
    return eval {
        my $msg = $extractor->_ua->get($url, 'Accept' => 'application/json');
        return undef unless $msg->is_success;
        my $val = $msg->decoded_content(ref => 1, charset => 'none');
        from_json(decode($msg->content_charset, $$val));
    };
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
sub _load_open_graph {
    my ($self, $res, $html, $keys, $filters) = @_;
    my $attr = $res->{attributes} //= {};
    my %raw = map {$_->attr('property') => $_->attr('content')} $html->findnodes('/html/head/meta[@property]');

    $filters //= {};

    foreach my $key (@{$keys}) {
        my $attrname = $attrmap_open_graph{$key} // croak 'BUG: Unknown key name: '.$key;
        my $filter   = $filters->{$key};

        if (defined(my $value = $raw{'og:'.$key})) {
            if (length($value)) {
                if (defined $filter) {
                    next unless $value =~ $filter;
                }

                $attr->{$attrname} //= {};
                $attr->{$attrname}{'*'} //= $value;
            }
        }
    }
}

# Private helper:
sub _get_uriid_decompiled_types_json {
    my ($self) = @_;
    state $json = {types => {
            'oid'                   => {alias_for => 'd08dc905-bbf6-4183-b219-67723c3c8374'},
            'uri'                   => {alias_for => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439'},
            'uuid'                  => {alias_for => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31'},
            'wikidata-identifier'   => {alias_for => 'ce7aae1e-a210-4214-926a-0ebca56d77e3'},
            'gtin'                  => {alias_for => '82d529be-0f00-4b4f-a43f-4a22de5f5312'},
            'sid'                   => {alias_for => 'f87a38cb-fd13-4e15-866c-e49901adbec5'},
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
        return \%res;
    }
}

sub _offline_lookup__Data__Identifier {
    my ($self, $result) = @_;
    my $ise_order = $result->{primary}{ise_order} // [qw(uuid oid uri)];
    my %attr;
    my %ids;

    eval { $result->id('uri') }; # prefil cache. See RT#157959

    foreach my $id (
        map {
            eval {$result->id($_, as => 'Data::Identifier', _no_convert => 1)}
        } (
            $result->{primary}{type},
            @{$ise_order},
        )) {

        next unless defined $id;

        if (defined(my $displayname = $id->displayname(default => undef, no_defaults => 1))) {
            $attr{displayname} //= {'*' => $displayname};
        }

        foreach my $type (qw(uuid oid uri sid)) {
            my $func = $id->can($type);

            if (defined(my $value = $id->$func(default => undef))) {
                $ids{$type eq 'sid' ? 'small-identifier' : $type} //= $value;
            }
        }
    }

    {
        my %res;
        $res{id} = \%ids if scalar keys %ids;
        $res{attributes} = \%attr if scalar keys %attr;
        return \%res;
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

    unless (defined $id) {
        $id = $self->_online_lookup__wikibase__stage_0($result, $config);
    }

    if (defined $id) {
        return $self->_online_lookup__wikibase__stage_1($result, $id, $config);
    }

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
        my $res = $self->_get_json($config->{endpoint}{sparql}, query => {format => 'json', query => $q});
        my $item = eval {$res->{results}{bindings}[0]{item}};
        return undef unless $item;
        return undef unless ($item->{type} // '') eq 'uri';
        if (($item->{value} // '') =~ m#^\Q$config->{prefix}\E([QP][1-9][0-9]*)$#) {
            return $1;
        }
    }

    return undef;
}

sub _online_lookup__wikibase__stage_1 {
    my ($self, $result, $id, $config) = @_;
    my %ids = ($config->{type} => $id);
    my %attr;
    my %res = (id => \%ids, attributes => \%attr);
    my $data = $self->_get_json(sprintf($config->{endpoint}{entitydata}, $id), local_override => ['%s.json', $id]);

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
    my $res = {
        'attributes' => {},
    };
    my $json = $self->_get_json(
        'https://commons.wikimedia.org/w/api.php',
        query => {
            action      => 'query',
            titles      => $result->id,
            prop        => 'imageinfo',
            iiprop      => 'url|mime|size|sha1|canonicaltitle',
            iiurlwidth  => 240, # get thumbnail
            format      => 'json'
        });

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
}

sub _online_lookup__fellig {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;

    foreach my $type (@fellig_types) {
        my $id = eval {$result->id($type, _no_convert => 1)} // next;
        my $json = $self->_get_json(sprintf('https://api.fellig.org/v0/overview/%s/%s', $type, uri_escape($id)), local_override => ['overview/%s/%s.json', $type, $id]) // next;

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
    }

    return undef;
}

sub _online_lookup__noembed_com {
    my ($self, $result) = @_;

    foreach my $service (qw(youtube)) {
        my $url = eval {$result->url(service => $service, action => 'render')} // eval {$result->url($service, action => 'embed')} // next;
        my $json = $self->_get_json('https://noembed.com/embed', query => {url => $url}) // next;
        my %attr;
        my %res = (attributes => \%attr);

        $attr{displayname} = {'*' => $json->{title}} if defined $json->{title};
        $attr{thumbnail}   = {'*' => URI->new($json->{thumbnail_url})} if defined $json->{thumbnail_url};

        return \%res;
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

    foreach my $type (qw(node way relation)) {
        my $id = eval {$result->id('osm-'.$type)} // next;
        my $json = $self->_get_json(sprintf('https://api.openstreetmap.org/api/0.6/%s/%s.json', $type, $id), local_override => ['%s/%s.json', $type, $id]) // next;
        my $element = eval {$json->{elements}[0]} // return undef;
        return $self->_online_lookup__osm__handle($element);
    }

    return undef;
}

sub _online_lookup__overpass {
    my ($self, $result) = @_;
    my $id = $result->id('wikidata-identifier');
    my $json = $self->_get_json('https://overpass-api.de/api/interpreter', query => {
            data => sprintf("[out:json][timeout:25];\n(node[\"wikidata\"=\"%s\"];\nway[\"wikidata\"=\"%s\"];\nrelation[\"wikidata\"=\"%s\"];\n);\nout;",
                $id, $id, $id,
            ),
        }) // return undef;
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
}

sub _online_lookup__xkcd {
    my ($self, $result, %opts) = @_;
    my $id = eval {$result->id('xkcd-num')};
    my $json = $self->_get_json($opts{metadata_url} // $result->url(service => 'xkcd', action => 'metadata'), local_override => ['%s.json', $id]) // return undef;
    my %ids;
    my %attr;
    my %res = (id => \%ids, attributes => \%attr);

    $ids{'xkcd-num'} = int($json->{num}) if defined($json->{num}) && $json->{num} =~ Data::URIID::Result->RE_UINT;
    $attr{displayname} = {'*' => $json->{title}} if defined($json->{title}) && length($json->{title});

    return \%res;
}

sub _online_lookup__doi {
    my ($self, $result, %opts) = @_;
    my $json = $self->_get_json($result->url(service => 'doi', action => 'metadata')) // return undef;
    my %attr;
    my %res = (attributes => \%attr);

    $attr{displayname} = {'*' => $json->{title}} if defined($json->{title}) && length($json->{title});

    return \%res;
}

sub _online_lookup__iconclass {
    my ($self, $result, %opts) = @_;
    my $id = $result->id('iconclass-identifier');
    my $json = $self->_get_json($result->url(service => 'iconclass', action => 'metadata'), local_override => ['%s.jsonld', $id]) // return undef;
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
}

sub _online_lookup__e621 {
    my ($self, $result, %opts) = @_;
    my $json = $self->_get_json($result->url(service => 'e621', action => 'metadata')) // return undef;
    my %ids;
    my %attr;
    my %digest;
    my %res = (id => \%ids, attributes => \%attr, digest => \%digest);

    return undef unless scalar(@{$json->{posts}}) == 1;

    foreach my $post (@{$json->{posts}}) {
        my $preview = $post->{preview};
        my $file = $post->{file};

        $ids{'e621-post-identifier'} = int($post->{id});
        $attr{ext}              = {'*' => $file->{ext}}                 if defined $file->{ext};
        $attr{final_file_size}  = {'*' => $file->{size}}                if defined $file->{size};
        $attr{thumbnail}        = {'*' => URI->new($preview->{url})}    if defined $preview->{url};
        $digest{'md-5-128'}     = $file->{md5}                          if defined $file->{md5};

        if (defined(my $tagroot = $post->{tags})) {
            $attr{tagged_as} = [map {[Data::Identifier->new('6fe0dbf0-624b-48b3-b558-0394c14bad6a' => $_)]} map {@{$_}} values %{$tagroot}];
        }
    }

    return \%res;
}

sub _online_lookup__danbooru2chanjp {
    my ($self, $result, %opts) = @_;
    my $url = $result->url(service => 'danbooru2chanjp', action => 'info');
    my $html = $self->_get_html($url) // return undef;
    my $json = from_json(((($html->findnodes('//script[@id="metadata" and @type="application/json"]'))[0] // return undef)->content_list)[0]);
    my %attr;
    my %digest;
    my %res = (attributes => \%attr, digest => \%digest);

    $digest{'md-5-128'}     = $json->{hash} if defined($json->{hash}) && $json->{hash} =~ /^[0-9a-f]{32}$/;
    $attr{final_file_size}  = {'*' => int($json->{filesize})} if defined($json->{filesize}) && int($json->{filesize});
    $attr{ext}              = {'*' => $1} if defined($json->{ext}) && $json->{ext} =~ /^\.?([0-9a-z]{1,5})$/;

    if (defined(my $tags = $json->{tags})) {
        my @list;
        $attr{tagged_as} = \@list;

        foreach my $tag (split /\s+/, $tags) {
            next unless length $tag;
            eval { # eval required for Data::Identifier < v0.11
                push(@list, [Data::Identifier->new('c5632c60-5da2-41af-8b60-75810b622756' => $tag)]);
            };
        }
    }

    if (defined(my $image = $json->{image}) && defined(my $directory = $json->{directory})) {
        my $file_fetch = $url->clone;

        $file_fetch->query(undef);
        $file_fetch->path_segments('', 'images', $directory, $image);

        $res{url_overrides} = {
            'fetch'      => $file_fetch,
            'file-fetch' => $file_fetch,
        };
    }

    return \%res;
}

sub _online_lookup__furaffinity {
    my ($self, $result, %opts) = @_;
    my $html = $self->_get_html($result->url(service => 'furaffinity', action => 'info')) // return undef;
    my %attr;
    my %res = (attributes => \%attr);
    my %raw = map {$_->attr('property') => $_->attr('content')} $html->findnodes('/html/head/meta[@property]');

    $self->_load_open_graph(\%res, $html, [qw(title description image)], {image => qr#^https://t\.furaffinity\.net/#});

    foreach my $download ($html->findnodes('/html/body//div[@id="submission_page"]//a[text()="Download" and @href]')) {
        my $url = URI->new($download->attr('href'), 'https');

        $url->scheme('https');
        $url = $url->as_string;

        $res{url_overrides} = {
            'fetch' => $url,
            'file-fetch' => $url,
        };
    }

    return \%res;
}

sub _online_lookup__imgur {
    my ($self, $result, %opts) = @_;
    my $html = $self->_get_html($result->url(service => 'imgur', action => 'info')) // return undef;
    my %attr;
    my %res = (attributes => \%attr);
    my %raw = map {$_->attr('name') => $_->attr('content')} $html->findnodes('/html/head/meta[@name]');

    $res{url_overrides} = {};

    $self->_load_open_graph(\%res, $html, [qw(title image)]);

    if (defined($raw{'twitter:player:stream'}) && length($raw{'twitter:player:stream'})) {
        $res{url_overrides}{'stream-fetch'} = $raw{'twitter:player:stream'};
    }

    return \%res;
}

sub _online_lookup__notalwaysright {
    my ($self, $result, %opts) = @_;
    my $html = $self->_get_html($result->url(service => 'notalwaysright', action => 'info')) // return undef;
    my %attr;
    my %res = (attributes => \%attr);
    my %raw = map {$_->attr('property') => $_->attr('content')} $html->findnodes('/html/head/meta[@property]');

    $res{url_overrides} = {};

    $self->_load_open_graph(\%res, $html, [qw(title)]);

    if (defined(my $url = $raw{'og:url'})) {
        if (length($url)) {
            $res{url_overrides}{'info'} = $url;
            $res{url_overrides}{'render'} = $url;
        }
    }

    return \%res;
}

sub _online_lookup__ruthede {
    my ($self, $result, %opts) = @_;
    my $html = $self->_get_html($result->url(service => 'ruthede', action => 'info')) // return undef;
    my %attr;
    my %res = (attributes => \%attr);

    $self->_load_open_graph(\%res, $html, [qw(image)]);

    if (defined($attr{thumbnail}) && defined(my $url = $attr{thumbnail}{'*'})) {
        if ($url =~ m#^(https://ruthe\.de/cartoons/)(strip_2487\.jpg)$#) {
            $attr{thumbnail} = {'*' => $1.'tn_'.$2};
            $res{url_overrides} = {
                'file-fetch' => $url,
            };
        }
    }

    return \%res;
}

# --- Overrides for Data::URIID::Base ---

sub displayname {
    my ($self, %opts) = @_;
    return $self->name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Service - Extractor for identifiers from URIs

=head1 VERSION

version v0.15

=head1 SYNOPSIS

    use Data::URIID;

    my $extractor = Data::URIID->new;
    my $result = $extractor->lookup( $URI );
    my $service = $result->attribute('service');

    my $name = $service->name;
    my $ise = $service->ise;

This module represents a single service.

This package inherits from L<Data::URIID::Base>.

=head1 METHODS

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

=head3 Universally available settings

=over

=item C<network_deny>: Denies network access (i.e. online lookups) for this service.

=back

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

=head2 C<Data::Identifier>

This service uses L<Data::Identifier> as a data source.
It can provide display names and similar for a number of common identifiers.

See also L<Data::Identifier::Wellknown>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
