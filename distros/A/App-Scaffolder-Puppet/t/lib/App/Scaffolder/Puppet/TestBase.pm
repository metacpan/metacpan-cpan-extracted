package App::Scaffolder::Puppet::TestBase;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::MockObject;

sub setup : Test(setup) {
	my ($self) = @_;

	$self->{opt_mock} = Test::MockObject->new();
	delete $self->{target_opt};
	delete $self->{name_opt};
	delete $self->{package_opt};
	$self->{opt_mock}->mock(target => sub {
		return $self->{target_opt};
	});
	$self->{opt_mock}->mock(name => sub {
		return $self->{name_opt};
	});
	$self->{opt_mock}->mock(package => sub {
		return $self->{package_opt};
	});
}

1;
