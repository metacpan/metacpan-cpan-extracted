use strict;
package TESTCLIENT::Form;
use base qw(Apache::Wyrd::Form Apache::Wyrd::Interfaces::Setter);

sub _submit_data {
	my ($self) = @_;
	$self->{_globals} = $self->{_variables};
}