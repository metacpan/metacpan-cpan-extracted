#!/usr/bin/perl

use common::sense;

use Bread::Board;
use Test::More qw(no_plan);

my $log_conf = qq/ 
log4perl.rootLogger=INFO, main

log4perl.appender.main=Log::Log4perl::Appender::Screen
log4perl.appender.main.layout   = Log::Log4perl::Layout::SimpleLayout
/;

my $mailhost   = '10.97.19.153';
my $msg        = 'Test email';
my $recipients = ['sblanton@choppertrading.com'];
my $from       = 'sblanton@choppertrading.com';
my $subject    = 'Test Email';

my $cntnr = container '01_basic_t' => as {

	service log_conf   => \$log_conf;
	service msg        => $msg;
	service mailhost   => $mailhost;
	service recipients => $recipients;
	service from       => $from;
	service subject    => $subject;

	service 'logger_svc' => (
		class        => 'App::Services::Logger::Service',
		lifecycle    => 'Singleton',
		dependencies => { log_conf => 'log_conf' },
	);

	service 'email_svc' => (
		class        => 'App::Services::Email::Service',
		dependencies => {
			logger_svc => depends_on('logger_svc'),
			msg        => 'msg',
			recipients => 'recipients',
			mailhost   => 'mailhost',
			from       => 'from',
			subject    => 'subject',
		},
	);

};

my $lsvc = $cntnr->resolve( service => 'logger_svc' );

ok( $lsvc, "Create logger service" );

my $svc = $cntnr->resolve( service => 'email_svc' );

ok( $svc, "Create email service" );

SKIP: {
	skip 1 unless 0;
	ok( $svc->send, "Sent mail" );
}
