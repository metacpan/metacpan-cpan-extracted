#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';
use Storable;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

my $default_album_page = {
            'rows' => [
                        {
                          'cpac__id' => "id\0005",
                          'sleeve_notes' => undef,
                          'cpac__pk_for_sleeve_notes' => undef,
                          'tracks' => [
                                        'Hit Tune',
                                        'Hit Tune 3',
                                        'Hit Tune II'
                                      ],                          'deleted' => 0,
                          'artist_id' => 'Adam Smith',
                          'cpac__pk_for_artist_id' => [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 3}],
                          'copyright' => [
                                              'Label B'
                                            ],                          'id' => 5,
                          'recorded' => '2002-05-21',
                          'title' => 'Greatest Hits',
                          'cpac__display_name' => 'Greatest Hits'
                        }
                      ],
            'total' => 1
};

my $testing_album_page = {
            'rows' => [
                        {
                          'cpac__id' => "id\0006",
                          'sleeve_notes' => undef,
                          'tracks' => [],
                          'cpac__pk_for_sleeve_notes' => undef,
                          'deleted' => 0,
                          'artist_id' => 'Mike Smith',
                          'cpac__pk_for_artist_id' => [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 1}],
                          'copyright' => [],
                          'id' => 6,
                          'recorded' => '',
                          'title' => 'Testing Hits',
                          'cpac__display_name' => 'Testing Hits'
                        }
                      ],
            'total' => 1
};

my $new_album_page = {
            'rows' => [
                        {
                          'cpac__id' => "id\0007",
                          'sleeve_notes' => undef,
                          'cpac__pk_for_sleeve_notes' => undef,
                          'tracks' => [],
                          'deleted' => 0,
                          'artist_id' => 'Charlie Thornton',
                          'cpac__pk_for_artist_id' => [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 5}],
                          'copyright' => [],
                          'id' => 7,
                          'recorded' => '',
                          'title' => 'Testing Hits 2',
                          'cpac__display_name' => 'Testing Hits 2'
                        }
                      ],
            'total' => 1
};

my $new_artist_page = {
            'rows' => [
                        {
                          'cpac__id' => "id\0004",
                          'forename' => 'Bob',
                          'born' => '',
                          'albums' => [
                                        'Greatest Hits 2'
                                      ],
                          'surname' => 'Thornton',
                          'pseudonym' => '',
                          'id' => 4,
                          'cpac__display_name' => 'Bob Thornton'
                        }
                      ],
            'total' => 1
};

my $second_artist_page = {
            'rows' => [
                        {
                          'cpac__id' => "id\0005",
                          'forename' => 'Charlie',
                          'born' => '',
                          'albums' => [
                                        'Testing Hits 2'
                                      ],
                          'surname' => 'Thornton',
                          'pseudonym' => '',
                          'id' => 5,
                          'cpac__display_name' => 'Charlie Thornton'
                        }
                      ],
            'total' => 1
};

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {}, {success => '0'}, 'add row, no data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {}, {success => '0'}, 'update row, no data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Greatest Hits'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {
    'cpac__id' => "id\0005",
    id => 5,
    'combobox.artist_id' => 3,
    title     => 'Greatest Hits',
    recorded  => '2002-05-21',
}, {success => '0'}, 'add row, dupe data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Greatest Hits'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {
    'combobox.artist_id' => "id\0001",
    recorded  => '2002-05-21',
}, {success => '0'}, 'add row, duff data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {
    'combobox.artist_id' => "id\0001",
    title     => 'Testing Hits',
}, {success => '1'}, 'add minimal row');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Testing Hits'}, $testing_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {
    cpac__id => "id\0005",
    id => "5",
    'combobox.artist_id' => "id\0003",
    foobar  => '2002-05-21',
}, {success => '1'}, 'edit row cols, extra data ignored');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Greatest Hits'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {
    cpac__id => "id\0005",
    id => "5",
    'combobox.artist_id' => "id\0003",
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '1'}, 'edit row cols');

$default_album_page->{rows}->[0]->{cpac__display_name} = 'Greatest Hits 2';
$default_album_page->{rows}->[0]->{title} = 'Greatest Hits 2';
$default_album_page->{rows}->[0]->{artist_id} = 'Adam Smith';
$default_album_page->{rows}->[0]->{recorded} = '2002-05-21';
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');

SKIP : {
    skip 'cannot test FK constraints with SQLite', 6;

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {
    cpac__id => "id\0005",
    id => "5",
    'combobox.artist_id' => "id\0009",
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '0'}, 'edit row fks, duff data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {
    'combobox.artist_id' => "id\0001",
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '1'}, 'edit row fks');

} # SKIP

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {
    cpac__id => "id\0005",
    id => "5",
    'checkbox.artist_id' => 'on',
    'combobox.artist_id' => "id\0003",
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '0'}, 'edit row add fwd related, duff data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/update', {
    cpac__id => "id\0005",
    id => "5",
    'checkbox.artist_id' => 'on',
    'artist_id.forename' => 'Bob',
    'artist_id.surname' => 'Thornton',
    'combobox.artist_id' => "id\0003",
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '1'}, 'edit row add fwd related');

$default_album_page->{rows}->[0]->{artist_id} = 'Bob Thornton';
$default_album_page->{rows}->[0]->{cpac__pk_for_artist_id} = [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 4}];
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/extjs2/list', {'cpac_filter.surname' => 'Thornton'}, $new_artist_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {
    'artist.forename' => 'Charlie',
    'artist.surname' => 'Thornton',
    'checkbox.artist_id' => 'on',
    'combobox.artist_id' => "id\0003",
}, {success => '0'}, 'add row, duff data, with related');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/extjs2/list', {'cpac_filter.forename' => 'Charlie'}, {total => 0, rows => []}, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {
    'checkbox.artist_id' => 'on',
    'artist_id.surname' => 'Thornton',
    'combobox.artist_id' => "id\0001",
    title     => 'Testing Hits 2',
    recorded  => '2002-05-21',
}, {success => '0'}, 'add row, with related, duff data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Testing Hits 2'}, {total => 0, rows => []}, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/extjs2/list', {'cpac_filter.surname' => 'Thornton'}, $new_artist_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/create', {
    'checkbox.artist_id' => 'on',
    'artist_id.forename' => 'Charlie',
    'artist_id.surname' => 'Thornton',
    'combobox.artist_id' => "id\0001",
    title     => 'Testing Hits 2',
}, {success => '1'}, 'add row, with related');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.title' => 'Testing Hits 2'}, $new_album_page, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/extjs2/list', {'cpac_filter.forename' => 'Charlie'}, $second_artist_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/track/extjs2/create', {
    title => 'Track Title',
    'combobox.album_id' => '',
    'checkbox.album_id' => 'on',
    'album_id.recorded' => '1999-05-21',
    'combobox.copyright_id' => '',
    'checkbox.copyright_id' => 'on',
    'rights owner' => 'Label D',
}, {success => '0'}, 'add row, with 2x related, one duff');
$mech->ajax_ok('/site/default/schema/dbic/source/track/extjs2/list', {'cpac_filter.title' => 'Track Title'}, {total => 0, rows => []}, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/copyright/extjs2/list', {'cpac_filter.rights owner' => 'Label D'}, {total => 0, rows => []}, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/extjs2/list', {'cpac_filter.recorded' => '1999-05-21'}, {total => 0, rows => []}, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/track/extjs2/create', {
    'parent_album.title' => 'Testing Hits 3',
    'checkbox.parent_album' => 'on',
    'checkbox.copyright_id' => 'on',
    'combobox.parent_album.artist_id' => "id\0003",
    'copyright_id.rights owner' => 'Label D',
    title => 'Track Title',
}, {success => '1'}, 'add row, with 2x related');

$mech->ajax_ok('/site/default/schema/dbic/source/track/extjs2/list', {'cpac_filter.title' => 'Track Title'}, {
            'rows' => [
                        {
                          'cpac__id' => "id\00014",
                          'length' => '',
                          'sales' => '',
                          'parent_album' => 'Testing Hits 3',
                          'cpac__pk_for_parent_album' => [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 8}],
                          'id' => 14,
                          'title' => 'Track Title',
                          'copyright_id' => 'Label D',
                          'cpac__pk_for_copyright_id' => [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 4}],
                          'cpac__display_name' => 'Track Title',
                          'releasedate' => ''
                        }
                      ],
            'total' => 1
}, 'check data');

