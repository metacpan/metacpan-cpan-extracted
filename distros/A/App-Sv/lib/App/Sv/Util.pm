package App::Sv::Util;

use strict;
use warnings;

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub get_env {
	my $self = shift;
	my %env;
	map { $env{$_} = delete $ENV{$_} } (keys %ENV);
	return \%env;
}

sub set_env {
	my ($self, $env) = @_;
	if (ref $env eq 'HASH') {
		map { $ENV{$_} = delete $env->{$_} } (keys %{$env});
		return 1;
	}
	return 0;
}

1;
