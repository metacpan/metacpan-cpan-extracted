#!/usr/bin/perl

use common::sense;

use Test::More qw(no_plan);

use App::Services::Email::Container;

my $cntnr = App::Services::Email::Container->new(
	mailhost   => '10.97.19.153',
	msg        => 'Test email',
	recipients => ['sblanton@choppertrading.com'],
	from       => 'sblanton@choppertrading.com',
	subject    => 'Test Email',
);

my $svc = $cntnr->resolve( service => 'email_svc' );

ok( $svc, "Create email service" );

SKIP: {
	skip 1 unless 0;
	ok( $svc->send, "Sent mail" );

}
