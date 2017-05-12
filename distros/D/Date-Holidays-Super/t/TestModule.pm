package TestModule;

use strict;
use lib qw(lib ../lib);
use Date::Holidays::Super;
use vars qw(@ISA);

@ISA = qw(Date::Holidays::Super);

sub new {
	my $class = shift;

	my $self = bless {}, ref $class || $class;

	return $self;
}

1;