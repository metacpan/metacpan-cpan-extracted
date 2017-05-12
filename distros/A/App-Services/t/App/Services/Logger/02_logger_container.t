#!/usr/bin/perl

use common::sense;
use Bread::Board;
use Test::More qw(no_plan);

use App::Services::Logger::Container;

my $log_conf = qq/ 
log4perl.rootLogger=INFO, main
log4perl.appender.main=Log::Log4perl::Appender::Screen
log4perl.appender.main.layout   = Log::Log4perl::Layout::SimpleLayout
/;

my $cntnr = App::Services::Logger::Container->new(
	log_conf => \$log_conf,
);

my $svc = $cntnr->resolve( service => 'logger_svc' );

ok($svc, "Create logger service");

my $log = $svc->log;

ok($log, "Got Log4perl logger");

ok($log->info("Log success!!"), "Logged something");
