package App::Scaffolder::HTMLTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;

sub use_test : Test(1) {
	my ($self) = @_;
	use_ok('App::Scaffolder::HTML');
}

1;
