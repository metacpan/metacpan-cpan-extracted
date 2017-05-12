#!/usr/bin/perl

use common::sense;

use Bread::Board;
use Test::More qw(no_plan);

my $log_conf = qq/ 
log4perl.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%-6p| %m%n

/;

my @child_objects = ( 1 .. 10 );

sub child_actions {
	say "child: $_[0]";
}

my $cntnr = container '01_basic_t' => as {

	service log_conf => \$log_conf;

	service 'logger_svc' => (
		class        => 'App::Services::Logger::Service',
		lifecycle    => 'Singleton',
		dependencies => { log_conf => 'log_conf' },
	);

	service child_objects => \@child_objects;
	service child_actions => \&child_actions;

	service 'forker_svc' => (
		class        => 'App::Services::Forker::Service',
		dependencies => {
			logger_svc    => depends_on('logger_svc'),
			child_objects => 'child_objects',
			child_actions => 'child_actions'
		},
	);

};

my $svc = $cntnr->resolve( service => 'forker_svc' );

ok( $svc, "Create forker service" );

ok ( $svc->forker, "forker apparently worked");
