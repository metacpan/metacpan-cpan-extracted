use strict;
use warnings;
use Test::More;
use Test::Moose;
use Test::Method;
use Class::Load 0.20 'load_class';

my $obj
	= new_ok( load_class('Business::PaperlessTrans::Client') => [{
		user => 'foo',
		pass => 'bar',
	}]);

does_ok $obj, 'MooseY::RemoteHelper::Role::Client';
can_ok  $obj, qw( submit user pass test debug );

# just a regression test for files not loading properly
ok $obj->_calls, 'check that calls returns without error';

done_testing;
