package MyPassword;
use strict;
use warnings;
# inherit core functionality from Data::Password::Check
use base qw{ Data::Password::Check };

# now we write a list of our own checks we'd like to add
# all function names take the form _check_<testname>

sub _check_all_x($) {
	# we're always passed ourself only as checks
	my ($self) = @_;

	# we can access the password with $self->{'password'}
	unless ($self->{'password'} =~ /^x+$/) {
		# since we failed our test we want to add a validation failure message
		$self->_add_error("The password must consist of one or more x's only");
	}

	# we don't need a return value
}

# be true;
1;
