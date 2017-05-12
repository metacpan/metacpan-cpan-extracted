#!/usr/bin/perl

use common::sense;

use Test::More qw(no_plan);

use App::Services::DB::Container::SQLite;

my $log_conf = qq/ 
log4perl.rootLogger=INFO, main
log4perl.appender.main=Log::Log4perl::Appender::Screen
log4perl.appender.main.layout   = Log::Log4perl::Layout::SimpleLayout
/;

my $cntnr = App::Services::DB::Container::SQLite->new(
	db_file => 't_01.sqlite',
	log_conf => \$log_conf,
);

my $svc = $cntnr->resolve( service => 'db_exec_svc' );

ok($svc, "Create db exec service");

my $log = $svc->log;

ok($log, "Got Log4perl logger");
