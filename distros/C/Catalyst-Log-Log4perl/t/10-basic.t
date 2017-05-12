#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use lib ( "$FindBin::Bin/lib", "$FindBin::Bin/../lib" );


use Catalyst::Test 'MockApp';

use Test::More tests => 11;


# fetch the single appender so we can access log messages
my ($appender) = values %{ Log::Log4perl->appenders };
isa_ok( $appender, 'Log::Log4perl::Appender' );

sub log_ok($;$) {
    my ( $check, $msg ) = @_;
    is( $appender->string, $check, $msg );
    $appender->string('');
}

sub log_like($;$) {
    my ( $re, $msg ) = @_;
    like( $appender->string, $re, $msg );
    $appender->string('');
}

## test capturing of log messages
my $c;
$c = get('/foo');
is( $c, 'foo', 'Foo response body' );
log_ok( '[MockApp.Controller.Root] root/foo', 'Foo log message' );

$c = get( '/bar?say=hello' );
is( $c, 'hello', 'Bar response body' );
log_ok( '[MockApp.Controller.Root] root/bar', 'Bar log message' );

## test different cseps

# %F File where the logging event occurred

$appender->layout( Log::Log4perl::Layout::PatternLayout->new('%F') );
$c = get('/foo');
log_like( qr|lib/MockApp/Controller/Root.pm$|, 'Loggin filepath' );

$appender->layout( Log::Log4perl::Layout::PatternLayout->new('%L') );
$c = get('/foo');
log_ok( '16', 'Loggin line number' );

# %C Fully qualified package (or class) name of the caller

$appender->layout( Log::Log4perl::Layout::PatternLayout->new('%C') );
$c = get('/foo');
log_ok( 'MockApp::Controller::Root', 'Loggin class name' );

# %l Fully qualified name of the calling method followed by the
#    callers source the file name and line number between
#    parentheses.

$appender->layout( Log::Log4perl::Layout::PatternLayout->new('%l') );
$c = get('/foo');
log_like
qr|^MockApp::Controller::Root::foo .*lib/MockApp/Controller/Root.pm \(16\)$|,
  'Loggin location';

# %M Method or function where the logging request was issued

$appender->layout( Log::Log4perl::Layout::PatternLayout->new('%M') );
$c = get('/foo');
log_ok( 'MockApp::Controller::Root::foo', 'Loggin method' );

# %T A stack trace of functions called

# unimplemented: would cause a major performance hit

## check another log message to ensure the closures work correctly

$appender->layout( Log::Log4perl::Layout::PatternLayout->new('%L') );
$c = get('/bar');
log_ok( '22', 'Loggin another line number' );
