#!perl
use 5.012;
use strict;
use warnings;
use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Test;
use File::Spec;
use Test::More;
use Test::Warnings;

#
# To activate debugging, uncomment the following
#
#use App::CELL::Test::LogToFile;
#$log->init( debug_mode => 1 );

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------------ ");
$log->info("---                    050-load.t                  ---");
$log->info("------------------------------------------------------ ");

$log->info("*****");
$log->info("***** TESTING find_files for 'message' type" );
$status = App::CELL::Test::cleartmpdir();
ok( $status, "Temporary directory not present" );

$status = App::CELL::Test::mktmpdir();
my $tmpdir = $status->payload();
my @file_list = qw{ 
                     CELL_Message.conf
                     CELL_Message_en.conf
                     Dochazka_MetaConfig.pm
                     Bubba_MetaConfig.pm
                     adfa343kk.conf
                     Dochazka_SiteConfig.pm
                     Dochazka_Config.pm
                  };
my $count1 = App::CELL::Test::touch_files( $tmpdir, @file_list );

# now we have some files in $tmpdir
my $return_list = App::CELL::Load::find_files( 'message', $tmpdir );

# how many matched the regex?
my $count2 = keys( @$return_list );
#diag( "Touched $count1 files; $count2 of them match the regex" );
ok( $count2 == 2, "find_files found the right number of files" );

# which ones?
#my @return_files = map { s|^.*/(?=[^/]*$)||g; $_; } @return_list;
my @return_files = map { 
        my ( undef, undef, $file ) = File::Spec->splitpath( $_ );
        $file;
                       } @$return_list;
my @should_be = ( 'CELL_Message.conf', 'CELL_Message_en.conf' );
ok( App::CELL::Test::cmp_arrays( \@return_files, \@should_be ), 
    "find_files found the right files" );

# what about meta, core, and site configuration files?
$return_list = App::CELL::Load::find_files( 'meta', $tmpdir );
ok( keys( @$return_list ) == 2, "Right number of meta config files" );
$return_list = App::CELL::Load::find_files( 'core', $tmpdir );
ok( keys( @$return_list ) == 1, "Right number of core config files" );
$return_list = App::CELL::Load::find_files( 'site', $tmpdir );
ok( keys( @$return_list ) == 1, "Right number of site config files" );


$log->info("*****");
$log->info("***** TESTING parse_message_file" );
my $stuff = <<'EOS';
# This is a test


TEST_MESSAGE
OK
 
    
   TEST_MESSAGE
OKAY

BORKED_MESSAGE
Bimble bomble brum

TEST_MESSAGE_WITH_ARG
This is a %s test message

EOS
my $full_path = File::Spec->catfile( $tmpdir, $file_list[0] );
App::CELL::Test::populate_file( $full_path, $stuff);
my %messages;
#diag( "BEFORE: %messages has " . keys(%messages) . " keys" );
App::CELL::Load::parse_message_file( File => $full_path, Dest => \%messages );
#diag( "Loaded " . keys(%messages) . " message codes from $full_path" );
ok( exists $messages{'TEST_MESSAGE'}, "TEST_MESSAGE loaded from file" );
is( $messages{'TEST_MESSAGE'}->{'en'}->{'Text'}, "OK", "TEST_MESSAGE has the right text");

$log->info("*****");
$log->info("***** TESTING parse_config_file" );
$return_list = App::CELL::Load::find_files( 'meta', $tmpdir );
is( scalar @$return_list, 2, "Found right number of meta config files");
#diag( "Meta config file found: $return_list->[0]" );
$full_path = $return_list->[0];
$stuff = <<'EOS';
# This is a test
set( 'TEST_PARAM_1', 'Fine and dandy' );
set( 'TEST_PARAM_2', [ 0, 1, 2 ] );
set( 'TEST_PARAM_3', { 'one' => 1, 'two' => 2 } );
set( 'TEST_PARAM_1', 'Now is the winter of our discontent' );
set( 'TEST_PARAM_4', sub { 1; } );
1;
EOS
App::CELL::Test::populate_file( $full_path, $stuff);
my %params = ();
my $count = App::CELL::Load::parse_config_file( File => $full_path, Dest => \%params );
is( keys( %params ), 4, "Correct number of parameters loaded from file" );
is( $count, keys( %params ), "Return value matches number of parameters loaded");
ok( exists $params{ 'TEST_PARAM_1' }, "TEST_PARAM_1 loaded from file" );
is( $params{ 'TEST_PARAM_1' }->{ 'Value' }, "Fine and dandy", "TEST_PARAM_1 has the right value" );
is_deeply( $params{ 'TEST_PARAM_2' }->{ 'Value' }, [ 0, 1, 2], "TEST_PARAM_2 has the right value" );
is_deeply( $params{ 'TEST_PARAM_3' }->{ 'Value' }, { 'one' => 1, 'two' => 2 }, "TEST_PARAM_3 has the right value" );
is( $params{ 'UNDEFINED_VALUE' }->{ 'Value' }, undef, 'UNDEFINED_VALUE is undef' );

$log->info("*****");
$log->info("***** TESTING wrong number of arguments in set" );
$return_list = App::CELL::Load::find_files( 'site', $tmpdir );
is( scalar @$return_list, 1, "Found right number of site config files");
#diag( "scalar \@\$return_list == ", scalar @$return_list );
$full_path = $return_list->[0];
$stuff = <<'EOS';
# This is a test
set( 'ONE_ARGUMENT_NO_VALUE' );
set( 'TOO_MANY_ARGUMENTS', 1, 2, 3 );
set( 'EXPLICIT_UNDEF', undef );
1;
EOS
$count = App::CELL::Test::populate_file( $full_path, $stuff );
ok( $count > 0, "$count characters written; greater than zero" );
%params = ();
$count = App::CELL::Load::parse_config_file( File => $full_path, Dest => \%params );
is( $count, 3 );
is( keys( %params ), 3, "Correct number of parameters loaded from file" );
is( $count, keys( %params ), "Return value matches number of parameters loaded");
is( $params{ 'ONE_ARGUMENT_NO_VALUE' }->{ 'Value' }, undef, 'ONE_ARGUMENT_NO_VALUE is undef' );
is( $params{ 'TOO_MANY_ARGUMENTS' }->{ 'Value' }, 1, 'TOO_MANY_ARGUMENTS is 1' );
is( $params{ 'EXPLICIT_UNDEF' }->{ 'Value' }, undef, 'EXPLICIT_UNDEF is undef' );

done_testing;
