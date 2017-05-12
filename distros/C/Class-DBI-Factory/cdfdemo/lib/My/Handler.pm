package My::Handler;
use strict;
use base qw( Class::DBI::Factory::Handler );

use vars qw( $VERSION );
$VERSION = '0.02';

# this is just a silly difference but serves to illustrate:

sub task_sequence { qw(check_permission read_input do_op say_hello return_output) };

# your session management goes here...

sub check_permission { 1 };

sub say_hello {
	my $self = shift;
	$self->debug(0, "Hello.");
}

1;