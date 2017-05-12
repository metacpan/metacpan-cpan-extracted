#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';
use Storable;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

my $default_artist_page = {
    'total' => 3,
    'rows' => [
                {
                  'stringified' => 'Adam Smith',
                  'dbid' => "id\0003",
                },
                {
                  'stringified' => 'David Brown',
                  'dbid' => "id\0002",
                },
                {
                  'stringified' => 'Mike Smith',
                  'dbid' => "id\0001",
                }
              ]
};

$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {}, {total => 0, rows => []}, 'no args');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => ''}, {total => 0, rows => []}, 'empty fk');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'foobar'}, {total => 0, rows => []}, 'nonexistant fk');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'dsfgdsfg. '}, {total => 0, rows => []}, 'illegal char fk');

$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id'}, $default_artist_page, 'sfy all');

$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id', query => ''}, $default_artist_page, 'empty query');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id', query => 'foobar'}, {total => 0, rows => []}, 'nonesense query');

my $brown = Storable::dclone($default_artist_page);
$brown->{total} = 1;
$brown->{rows} = [ $brown->{rows}->[1] ];
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id', query => 'Brown'}, $brown, 'brown query, caseful');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id', query => 'brown'}, $brown, 'brown query, lowercase');

my $adam = Storable::dclone($default_artist_page);
$adam->{rows} = [ $adam->{rows}->[0] ];
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id', limit => 1}, $adam, 'limit 1');

$brown->{total} = 3;
$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'artist_id', limit => 1, page => 2}, $brown, 'limit 1, page 2');

$mech->ajax_ok('/site/default/schema/dbic/source/album/list_stringified', {fkname => 'sleeve_notes'}, {
    'total' => 1,
    'rows' => [
                {
                  'stringified' => 'SleeveNotes: id(1)',
                  'dbid' => "id\0001",
                }
              ]
}, 'sfy rr');

# we assume Data::Page is tested,
# or can add tests for the pager in the future.

