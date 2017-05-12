use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Var;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Var - pass a variable object into a parent Wyrd

=head1 SYNOPSIS

    <BASENAME::Var name="my_name" param="my_param"></BASENAME::Var>

provides parent with variable "my_name" with value of the CGI param "my_param"

    <BASENAME::Var name="my_name"></BASENAME::Var>

provides parent with variable "my_name" with value of the CGI param "my_name"

    <BASENAME::Var name="my_name">some_value</BASENAME::Var>

provides parent with variable "my_name" with value of "some_value"


=head1 DESCRIPTION

Inserts a variable into a Wyrd if that Wyrd implements a set_var method.
 How the Wyrd implements the method is it's own business (but for
C<Apache::Wyrd::Form> objects, it is to set the appropriate value under
the variable's name in the B<_variables> hash).

=head2 HTML ATTRIBUTES

=over

=item name

the name of the variable to be set

=item value

its value

=back

=head2 PERL METHODS

I<(format: (returns) name (accepts))>

=over

=item (scalar) C<value> (void)

returns the value of the variable.

=back

=cut

sub value {
	my ($self) = @_;
	return $self->{'value'};
}

=pod

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _startup and _generate_output methods.

=cut

sub _startup {
	my ($self) = @_;
	$self->{'name'} || $self->_raise_exception("Must Supply a name for Var");
}

sub _generate_output {
	#Use enclosed area as variable value, or try CGI
	#unless a param is specified, in which always use CGI,
	#but default to enclosed data.
	my ($self) = @_;
	my $var = ($self->{'_data'});
	my $param = $self->{'param'};
	if ($param) {
		$var = $self->dbl->param($param);
	} else {
		$var ||= $self->dbl->param($self->{'name'});
	}
	$self->{'value'} = $var;
	$self->_debug("Var '" . $self->{'name'} . "' has value '" . $self->{'value'} . "'");
	if ($self->{'_parent'}->can('set_var')) {
		$self->{'_parent'}->set_var($self);
	} else {
		$self->_error('Parent does not have a set_var() method.');
	}
	return;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;