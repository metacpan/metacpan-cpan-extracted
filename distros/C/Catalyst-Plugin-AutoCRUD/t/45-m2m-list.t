#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON::XS;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppM2M" }
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

my $default_album_page = <<'END_ALBUM_EXPECTED';
{"total":5,"rows":[{"cpac__id":"id\u00001","artist_albums":["ArtistAlbum: id(1)"],"artist":["Artist: id(1)"],"title":"DJ Mix 1","recorded":"1989-01-02","deleted":1,"id":1,"cpac__display_name":"Album: id(1)"},{"cpac__id":"id\u00002","artist_albums":["ArtistAlbum: id(2)"],"artist":["Artist: id(1)"],"title":"DJ Mix 2","recorded":"1989-02-02","deleted":1,"id":2,"cpac__display_name":"Album: id(2)"},{"cpac__id":"id\u00003","artist_albums":["ArtistAlbum: id(3)"],"artist":["Artist: id(2)"],"title":"DJ Mix 3","recorded":"1989-03-02","deleted":1,"id":3,"cpac__display_name":"Album: id(3)"},{"cpac__id":"id\u00004","artist_albums":[],"artist":[],"title":"Pop Songs","recorded":"2007-05-30","deleted":0,"id":4,"cpac__display_name":"Album: id(4)"},{"cpac__id":"id\u00005","artist_albums":["ArtistAlbum: id(4)"],"artist":["Artist: id(3)"],"title":"Greatest Hits","recorded":"2002-05-21","deleted":0,"id":5,"cpac__display_name":"Album: id(5)"}]}
END_ALBUM_EXPECTED

my $default_artist_page = <<'END_ARTIST_EXPECTED';
{"total":3,"rows":[{"cpac__id":"id\u00001","album":["Album: id(1)","Album: id(2)"],"forename":"Mike","born":"1970-02-28","surname":"Smith","artist_albums":["ArtistAlbum: id(1)","ArtistAlbum: id(2)"],"pseudonym":"Alpha Artist","id":1,"cpac__display_name":"Artist: id(1)"},{"cpac__id":"id\u00002","album":["Album: id(3)"],"forename":"David","born":"1992-05-30","surname":"Brown","artist_albums":["ArtistAlbum: id(3)"],"pseudonym":"Band Beta","id":2,"cpac__display_name":"Artist: id(2)"},{"cpac__id":"id\u00003","album":["Album: id(5)"],"forename":"Adam","born":"1981-05-10","surname":"Smith","artist_albums":["ArtistAlbum: id(4)"],"pseudonym":"Gamma Group","id":3,"cpac__display_name":"Artist: id(3)"}]}
END_ARTIST_EXPECTED

$mech->ajax_ok( '/site/default/schema/dbic/source/album/extjs2/list', {}, JSON::XS::decode_json($default_album_page), 'album no args' );

$mech->ajax_ok( '/site/default/schema/dbic/source/artist/extjs2/list', {}, JSON::XS::decode_json($default_artist_page), 'artist no args' );

__END__
