#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';
use Storable;

use DBIx::Class;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;


my $default_sleeve_notes_page = {
    'total' => 1,
    'rows' => [
                {
                    'cpac__id' => "id\0001",
                    'cpac__display_name' => 'SleeveNotes: id(1)',
                    'id' => 1,
                    'text' => 'This is a groovy album.',
                    'album_id' => 'DJ Mix 2',
                    'cpac__pk_for_album_id' => [{ tag => 'input', type => 'hidden', name => 'cpac_filter.id', value => 2}],
                }
             ],
};

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/delete', {}, {success => '0'}, 'no args');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/list', {'cpac_filter.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/delete', {key => ''}, {success => '0'}, 'empty key');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/list', {'cpac_filter.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/delete', {foobar => ''}, {success => '0'}, 'no key');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/list', {'cpac_filter.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/delete', {key => 'foobar'}, {success => '0'}, 'no key match');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/list', {'cpac_filter.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/delete', {key => "id\0001"}, {success => '1'}, 'delete success');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/list', {'cpac_filter.text' => 'This is a groovy album.'}, {total => 0, rows => []}, 'check deleted');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/delete', {key => "id\0001"}, {success => '0'}, 'delete again fails');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/extjs2/list', {'cpac_filter.text' => 'This is a groovy album.'}, {total => 0, rows => []}, 'check deleted');

