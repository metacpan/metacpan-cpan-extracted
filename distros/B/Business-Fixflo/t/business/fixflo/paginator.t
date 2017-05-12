#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::Paginator' );

my $Client = Business::Fixflo::Client->new(
	username      => 'foo',
	password      => 'bar',
	custom_domain => 'baz',
);

isa_ok(
    my $Paginator = Business::Fixflo::Paginator->new(
		'objects'         => [
			qw/ foo bar baz /
		],
		'links'           => {
			next     => 'foo',
			previous => 'bar',
		},
		'class'           => 'Business::Fixflo::Issue',
        'client'          => $Client,
    ),
    'Business::Fixflo::Paginator'
);

no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub {
	return {
		NextURL     => 'foo',
		PreviousURL => 'bar',
		Items       => [ qw/
			url1 url2 url3
		/ ],
	}
};

can_ok(
    $Paginator,
    qw/
		client
		objects
		class
		links
    /,
);

cmp_deeply(
	$Paginator->next,
	[ qw/ foo bar baz / ],
	'next returns first set of objects'
);

cmp_deeply(
	$Paginator->next,
	[
		map { Business::Fixflo::Issue->new(
			client => $Client,
			url    => "url" . $_,
		) } 1 .. 3,
	],
	' ... then moves onto next'
);

cmp_deeply(
	$Paginator->previous,
	[
		map { Business::Fixflo::Issue->new(
			client => $Client,
			url    => "url" . $_,
		) } 1 .. 3,
	],
	'previous returns current set of objects'
);

*Business::Fixflo::Client::api_get = sub {
	return {
		NextURL     => 'foo',
		PreviousURL => 'bar',
		Items       => [ {},{},{} ],
	}
};

my $expected = Business::Fixflo::Issue->new( client => $Client );

note explain $Paginator->next;

cmp_deeply(
	$Paginator->next,
	[ $expected,$expected,$expected ],
	'next returns first set of objects'
);

done_testing();

# vim: ts=4:sw=4:et
