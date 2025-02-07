package Database::passwd;

# Open /etc/passwd as a database
use strict;
use warnings;

use Database::Abstraction;

our @ISA = ('Database::Abstraction');

# Doesn't ignore lines starting with '#' as it's not treated like a CSV file
sub _open {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $self->SUPER::_open(sep_char => ':', column_names => ['name', 'password', 'uid', 'gid', 'gecos', 'home', 'shell'], %args);
}

1;
