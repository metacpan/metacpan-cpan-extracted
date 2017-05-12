#!/usr/bin/env perl
use Test::More tests => 10;
use utf8;
use lib 'lib';
use App::I18N::DB;

use_ok('App::I18N::DB');

my $db = App::I18N::DB->new();
ok( $db );

$db->insert( 'zh-tw',  'test' , '測試' );

$entry = $db->find( 'zh-tw', 'test' );


ok( $entry );
ok( $entry->{id} );
ok( $entry->{msgid} );
ok( $entry->{lang} );
ok( $entry->{msgstr} );

is( $entry->{msgstr} , '測試' );

my $entries = $db->get_entry_list( 'zh-tw' );
ok( @$entries );
is( scalar(@$entries) , 1 );
