#!perl
use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $core $site );
use App::CELL::Test qw( mktmpdir cleartmpdir populate_file );
#use App::CELL::Test::LogToFile;
#use Data::Dumper;
use File::Spec;
use Scalar::Util qw( blessed );
use Test::More;
use Test::Warnings;

my $status;
delete $ENV{CELL_DEBUG_MODE};
$log->init( ident => 'CELLtest', debug_mode => 1 );
$log->info("------------------------------------------------------- ");
$log->info("---                   110-site.t                    ---");
$log->info("------------------------------------------------------- ");

$status = mktmpdir();
ok( $status->ok, "Temporary directory created" );
my $sitedir = $status->payload;
ok( -d $sitedir, "tmpdir is a directory" );
ok( -W $sitedir, "tmpdir is writable by us" );

my $full_path = File::Spec->catfile( $sitedir, 'CELL_Message_en.conf' );
my $stuff = <<'EOS';
# some messages in English
TEST_MESSAGE
This is a test message.

FOO_BAR
Message that says foo bar.

BAR_ARGS_MSG
This %s message takes %s arguments.

EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$full_path = File::Spec->catfile( $sitedir, 'CELL_Message_cz.conf' );
$stuff = <<'EOS';
# some messages in Czech
TEST_MESSAGE
Tato zpráva slouží k testování.

FOO_BAR
Zpráva, která zní foo bar.

BAR_ARGS_MSG
Tato %s zpráva bere %s argumenty.

EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$full_path = File::Spec->catfile( $sitedir, 'CELL_SiteConfig.pm' );
$stuff = <<'EOS';
# set supported languages
set( 'CELL_SUPP_LANG', [ 'en', 'cz' ] );

# a random parameter
set( 'A_RANDOM_PARAMETER', "34WDFWWD" );

1;
EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

ok( ! defined( $meta->CELL_META_SITEDIR_LOADED ), "Meta param undefined before load");
$status = $CELL->load( sitedir => $sitedir );
ok( $status->ok, "CELL initialization with sitedir OK" );
ok( $meta->CELL_META_SITEDIR_LOADED, "Meta param set correctly after load" );
is( $CELL->loaded, "BOTH", "Both sharedir and sitedir have been loaded" );
is_deeply( $meta->CELL_META_SITEDIR_LIST, [ $sitedir ], "List of sitedirs is correct" );
is_deeply( $CELL->supported_languages, [ 'en', 'cz' ], 
    "CELL now supports two languages instead of just one" );
ok( $CELL->language_supported( 'en' ), "English is supported" );
ok( $CELL->language_supported( 'cz' ), "Czech is supported" );
ok( ! $CELL->language_supported( 'fr' ), "French is not supported" );
is( $site->CELL_DEF_LANG, 'en', "Site language default is English" );
my $msgobj = $CELL->msg('TEST_MESSAGE');
ok( blessed($msgobj), "Message object is blessed" );
is( $msgobj->text, 'This is a test message.', 
    "Test message has the right text" );
$msgobj = $CELL->msg( 'NON_EXISTENT_MESSAGE' );
ok( blessed($msgobj), "Message object with undefined code is blessed" );
is( $msgobj->text, 'NON_EXISTENT_MESSAGE', 
    "Non-existent message text the same as non-existent message code" );

$msgobj = $CELL->msg( 'BAR_ARGS_MSG', "FooBar", 2 );
is( $msgobj->text, 'This FooBar message takes 2 arguments.' );

#$status = $msgobj->lang('cz');
#my $cesky_text = $status->payload->text;
#is( $cesky_text, "Tato FooBar zpráva bere 2 argumenty." );

is( $site->A_RANDOM_PARAMETER, "34WDFWWD", "Random parameter has value we set" );

#---
# and now, a second sitedir
#---
$status = mktmpdir();
ok( $status->ok, "Second temporary directory created" );
my $sitedir2 = $status->payload;
ok( -d $sitedir2, "Second tmpdir is a directory" );
ok( -W $sitedir2, "Second tmpdir is writable by us" );

$full_path = File::Spec->catfile( $sitedir2, 'CELL2_Message_en.conf' );
$stuff = <<'EOS';
# some messages for the second sitedir
TEST2_MESSAGE
This is a test2 message.

FOO2_BAR
Second message that says bar foo.

BAR2_ARGS_MSG
This second %s message takes %s arguments.

EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$full_path = File::Spec->catfile( $sitedir2, 'CELL_SiteConfig.pm' );
$stuff = <<'EOS';
set( 'CELL2_BIG_BUS_PARAM', "Vehiculo longo" );

# a random parameter
set( 'A_RANDOM_PARAMETER', "different value" );

use strict;
use warnings;
1;
EOS
#diag( "Now populating $full_path" );
populate_file( $full_path, $stuff );

$status = $CELL->load( sitedir => $sitedir2 );
ok( $status->ok, "CELL initialization with second sitedir OK" );
is( $site->CELL2_BIG_BUS_PARAM, "Vehiculo longo", "Unique param has value we set" );
is( $site->A_RANDOM_PARAMETER, "34WDFWWD", "Attempt to overwrite existing site param failed" );
is( $meta->CELL_META_SITEDIR_LOADED, 2, "Meta param set correctly after second load");
is_deeply( $meta->CELL_META_SITEDIR_LIST, [ $sitedir, $sitedir2 ], "List of sitedirs correctly expanded after second load" );

done_testing;
