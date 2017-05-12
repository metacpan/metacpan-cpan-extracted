#!/usr/bin/perl

use common::sense;

use Bread::Board;
use Test::More qw(no_plan);

use App::Services::Forker::Container;

my $log_conf = qq/ 
log4perl.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%-6p| %m%n

/;

my @co = qw( 1 2 3 4 5 6 7 8 9 10 );
sub ca { say "$_[0]" }

say "ref: " . ref( \@co );

my $cntnr = App::Services::Forker::Container->new(
	child_objects => \@co,
	child_actions => \&ca,
	log_conf      => \$log_conf,
);

my $lsvc = $cntnr->resolve( service => 'log/logger_svc' );

ok( $lsvc, "Create logger service" );

my $svc = $cntnr->resolve( service => 'forker_svc' );

ok( $svc, "Create forker store service" );

ok( $svc->forker, "forker apparently worked" );

