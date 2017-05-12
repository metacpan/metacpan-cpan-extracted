use strict;
use warnings;
use Test::More;
use Test::Method;
use Class::Load 0.20 'load_class';
use Test::Requires::Env qw( PAPERLESSTRANS_USER PAPERLESSTRANS_PASS );

my $req_prefix = 'Business::PaperlessTrans::Request';
my $prefix     = $req_prefix . 'Part::';

my $req = new_ok load_class( $req_prefix . '::TestConnection' );

my $client
	= new_ok( load_class('Business::PaperlessTrans::Client') => [{
		user  => $ENV{PAPERLESSTRANS_USER},
		pass  => $ENV{PAPERLESSTRANS_PASS},
	}]);

my $res = $client->submit( $req );

isa_ok $res, 'Business::PaperlessTrans::Response::TestConnection';

done_testing;
