# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl AnyEvent-ClickHouse.t'

#########################

use strict;
use Test::More;
BEGIN {
	unless ($ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING}) {
		plan skip_all => "These tests are for authors only!";
		print "1..0 # SKIP  These tests are for authors only!";
		exit;
	}
	eval {
		use Test::HTTP::AnyEvent::Server;
	};
	if ($@) {
		plan skip_all => "Test::HTTP::AnyEvent::Server required for testing AnyEvent::ClickHouse";
		print "1..0 # SKIP  Test::HTTP::AnyEvent::Server required for testing AnyEvent::ClickHouse";
		exit;
	}
}

plan tests => 3;

BEGIN { use_ok('AnyEvent::ClickHouse') };

use Test::HTTP::AnyEvent::Server;
my $server = Test::HTTP::AnyEvent::Server->new(
    custom_handler => sub {
    	my ($response) = @_;
    	$response->content('Ok.');
    	return 1;
    }
);

my $cv = AnyEvent->condvar;

clickhouse_select({
	hast=>'127.0.0.1',
	port=>$server->{port}
}, "select 1",
sub {
    my $r = shift;
    is $r, 'Ok.';
    $cv->send;
},
sub {
    is 0, 1;
    $cv->send;	
}
);

clickhouse_select_array({
	hast=>'127.0.0.1',
	port=>$server->{port}
}, "select 1",
sub {
    my $r = shift;
    is $r->[0]->[0], 'Ok.';
    $cv->send;
},
sub {
    is 0, 1;
    $cv->send;	
}
);

$cv->recv;

