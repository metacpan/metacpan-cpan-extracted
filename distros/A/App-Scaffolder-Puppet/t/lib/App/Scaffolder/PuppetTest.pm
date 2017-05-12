package App::Scaffolder::PuppetTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;

sub use_test : Test(1) {
	my ($self) = @_;
	use_ok('App::Scaffolder::Puppet');
}

1;
