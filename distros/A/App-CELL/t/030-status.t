#!perl -T
use 5.012;
use strict;
use warnings;
use App::CELL::Log qw( $log );
use App::CELL::Status;
use App::CELL::Test;
use Data::Dumper;
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("------------------------------------------------- ");
$log->info("---               030-status.t                ---");
$log->info("------------------------------------------------- ");

$status = App::CELL::Status->ok;
ok( $status->ok, "OK status is OK" );
ok( ! $status->not_ok, "OK status is not not_ok" );
is( $status->level, "OK", "level returns OK" );
is( $status->code, "<NONE>", "No code");
my $caller = $status->caller;
is( scalar @$caller , 3, "Caller is present" );
is( @$caller[0], "main", "First element of caller is 'main'" );

$status = App::CELL::Status->ok( "My payload" );
is( $status->payload, "My payload", "OK status can take a payload" );

$status = App::CELL::Status->not_ok;
ok( $status->not_ok, "NOT_OK status is not_ok" );
ok( ! $status->ok, "NOT_OK status is not ok" );
is( $status->level, "NOT_OK", "level returns NOT_OK" );
is( $status->code, "<NONE>", "No code");
$caller = $status->caller;
is( scalar @$caller , 3, "Caller is present" );
is( @$caller[0], "main", "First element of caller is 'main'" );

$status = App::CELL::Status->not_ok( "Not my payload" );
is( $status->payload, "Not my payload", "NOT_OK status can take a payload" );

$status = App::CELL::Status->new( level => 'OK' );
ok( $status->ok, "OK status via new is OK" );
ok( ! $status->not_ok, "OK status via new is not not_ok" );
is( $status->level, "OK", "level returns OK" );
is( $status->code, "<NONE>", "No code");
$caller = $status->caller;
is( scalar @$caller , 3, "Caller is present" );
is( @$caller[0], "main", "First element of caller is 'main'" );

$status = App::CELL::Status->new( level => 'NOT_OK' );
ok( $status->not_ok, "NOT_OK status via new is not OK" );
ok( ! $status->ok, "NOT_OK status via new is not OK" );
is( $status->level, "NOT_OK", "level returns NOT_OK" );
is( $status->code, "<NONE>", "No code");
$caller = $status->caller;
is( scalar @$caller , 3, "Caller is present" );
is( @$caller[0], "main", "First element of caller is 'main'" );

$status = App::CELL::Status->new( level => 'DEBUG', code => 'Bugs galore' );
ok( $status->not_ok, "DEBUG status is not OK" );
is( $status->level, "DEBUG", "level returns DEBUG" );
is( $status->code, 'Bugs galore', "Has the right code" );
is( @$caller[0], "main", "First element of caller is 'main'" );

$status = App::CELL::Status->new( level => 'FOOBAR', code => 'Bugs flying',
                                  payload => "Obstinate" );
is( $status->level, "ERR", "Attempt to create status with non-existent level defaults to ERR level");
is( $status->code, "Bugs flying", "Code is there");
is( @$caller[0], "main", "First element of caller is 'main'" );
is( $status->payload, "Obstinate", "FOOBAR-level status can take a payload" );

$status = App::CELL::Status->new( level => 'INFO' );
is( $status->level, "INFO", "INFO level is INFO" );
ok( $status->not_ok, "INFO status is not OK" );
ok( ! $status->ok, "INFO status is not OK in another way" );

$status = App::CELL::Status->new( level => 'NOTICE', foobar => 44 );
is( $status->level, "NOTICE", "NOTICE level is NOTICE" );
ok( $status->not_ok, "NOTICE status is not OK" );
is( $status->{foobar}, 44, "Value of undocumented attribute obtainable by cheating" );

$status = App::CELL::Status->new( level => 'WARN' );
ok( $status->not_ok, "WARN status is not OK" );

$status = App::CELL::Status->new( level => 'ERR' );
ok( $status->not_ok, "ERR status is not OK" );

$status = App::CELL::Status->new( level => 'CRIT' );
ok( $status->not_ok, "CRIT status is not OK" );

$status = App::CELL::Status->new( level => 'OK',
    payload => [ 0, 'foo' ] );
ok( $status->ok, "OK status object with payload is OK" );
is_deeply( $status->payload, [ 0, 'foo' ], "Payload is retrievable" );

$status = App::CELL::Status->new( 
            level => 'NOTICE',
            code => "Pre-init notice w/arg ->%s<-",
            args => [ "CONTENT" ],
                             );
ok( ! $status->ok, "Our pre-init status is not OK" );
ok( $status->not_ok, "Our pre-init status is not_ok" );
is( $status->msgobj->text, "Pre-init notice w/arg ->CONTENT<-", "Access message object through the status object" );

$status = App::CELL::Status->new(
              level => 'CRIT',
              code => "This is just a test. Don't worry; be happy.",
              payload => "FOOBARBAZ",
          );
is( $status->payload, "FOOBARBAZ", "Payload accessor function returns the right value" );
is( $status->level, "CRIT", "Level accessor function returns the right value" );

done_testing;
