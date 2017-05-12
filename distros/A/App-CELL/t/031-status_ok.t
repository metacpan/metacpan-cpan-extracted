#!perl -T
use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log );
#use App::CELL::Test::LogToFile;
use Data::Dumper;
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest' );
$log->info("---------------------------------------------------- ");
$log->info("---               031-status_ok.t                ---");
$log->info("---------------------------------------------------- ");

$status = $CELL->status_ok();
#diag( Dumper( $status ) );
ok( $status->ok, "OK status is OK" );
is( $status->{code}, undef, "real code is undef" );
is( $status->code, '<NONE>', "no code" );
is( $status->{text}, undef, "real text is undef" );
is( $status->text, '<NONE>', "no text" );
is( $status->payload, undef, "payload is undefined" );
is_deeply( $status->args, [], "args is empty" );

$status = $CELL->status_ok( "foobar" );
#diag( Dumper( $status ) );
ok( $status->ok, "OK status is OK" );
is( $status->code, "foobar", "code is as expected" );
is( $status->text, "foobar", "text is as expected" );
is( $status->payload, undef, "payload is undefined" );
is_deeply( $status->args, [], "args is empty" );

done_testing;
