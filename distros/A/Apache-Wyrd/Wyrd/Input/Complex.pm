use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Input::Complex;
our $VERSION = '0.98';
use base qw(
	Apache::Wyrd::Interfaces::Mother
	Apache::Wyrd::Interfaces::Setter
	Apache::Wyrd::Input
);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::Input::Complex - Abstract class for more complex Wyrds (hashes/structures)

=head1 SYNOPSIS

	NONE

=head1 DESCRIPTION

Occasionally, an Input is needed which is too complicated to reduce to a
single parameter or control.  These might be items in a sub-table or
otherwise related information to the main information being requested. 
If it can be reduced to a single data structure, such as an arrayref to
an array of hashes, it can be handled by the Complex Input Wyrd.

Form objects need a certain behavior out of the Inputs they handle.  The
form will be calling certain methods and expecting certain outcomes. 
This module abstract-ifies those requirements and consists of hook
methods which must be overridden in a subclass.  The normal behavior of
these methods is to cause an exception to be raised and to emit an error
message concerning the method which requires overriding.

Another implementation of the Complex Input is available which simply
combines the values of all classic "inputs" into a single hashref.  See
C<Apache::Wyrd::Input::Condenser>.  This will be suitable for many
complex operations, so try it first before implementing a complex Input
object from scratch.

In the documentation below, the indeterminate structure that the data
this Input represents is denoted by B<STRUCTURE>.

=head2 HTML ATTRIBUTES

unlike other Input Wyrds, Complex does not handle standard attributes
such as class and onselect, except as implemented by the developer.

As is, there are no default attributes other than:

=over

=item name

The name of the Complex Input.

=back

=head2 PERL METHODS

see C<Apache::Wyrd::Input> for "normal" Input Wyrd behavior.  The
methods requiring overriding are (in the order of recommended implementation):

=item (STRUCTURE) C<default> (void)

This should return the default, or baseline, data structure.

=cut

sub default {
	my ($self) = @_;
	$self->_unimplemented('It should return the default data structure.');
}

=item (STRUCTURE) C<current_value> (void)

This should return the data structure based on the current state of CGI.

=cut

sub current_value {
	my ($self) = @_;
	$self->_unimplemented('It should return the data structure based on the current state of CGI.');
}

=item (scalar, scalar) C<check> (STRUCTURE)

This should accept the data structure and return (1, undef) if OK,
(undef, "error message") if not.

=cut

sub check {
	my ($self, $structure) = @_;
	$self->_unimplemented('It should accept the data structure and return (1, undef) if OK, (undef, "error message") if not.');
}

=item (void) C<set> (STRUCTURE)

This should accept the data structure , call C<check>, and
C<parent-E<gt>register_errors>, C<parent-E<gt>register_error_messages>
when there are errors, and set the value that C<value> returns.

=cut

sub set {
	my ($self, $structure) = @_;
	$self->_unimplemented('It should accept the data structure , call check, and parent->register_errors, parent->register_error_messages when there are errors, and set the value that value() returns.');
}

=item (STRUCTURE) C<value> (void)

This should return the data structure.

=cut

sub value {
	my ($self) = @_;
	$self->_unimplemented('It should return the data structure.)');
}

=pod

=item (scalar) C<final_output> (void)

This should manipulate _template to produce the appropriate HTML.  By
default, _template is defined as the enclosed text.

=cut

sub final_output {
	my ($self) = @_;
	$self->_unimplemented('It should manipulate _template (default: _data) to produce the appropriate HTML.');
}

=pod

=item (scalar) C<_get_value> (Apache::Wyrd::Input)

Don't subclass this one unless you know what you're doing.  Is normally
implemented only to return undef to any attempt to set a sub-Input's
value by default.

=cut

sub _get_value() {
	return;
}

=item 

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the C<_setup>, C<_format_output>, and C<_generate_output>. 
Also overerides the register_input and _parse_options methods from
C<Apache::Wyrd::Input>. methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->_flags->complex(1);
}

sub _format_output {
	my ($self) = @_;
	$self->{'value'} ||= $self->default;
	$self->{'_error_messages'} ||= [];
	$self->{'_error_messages'} ||= [];
	$self->{'triggers'} = token_parse($self->{'triggers'});
	$self->{'_id'} = $self->{'_parent'}->register_input($self);
}

sub _generate_output {
	my ($self) = @_;
	#note that the _data attribute should be the enclosed text at this point, or the children won't
	#be output.
	$self->_set_children;
	my $id = $self->{'_id'};
	$self->_raise_exception('No ID provided by form') unless ($id);
	$self->{'_template'} = $self->_data;
	$self->_data('$:' . $id);
}

sub register_input {
	my ($self, $child) = @_;
	$self->register_child($child);
}

sub _parse_options {
	my ($self) = @_;
	$self->_unimplemented('If you are calling this method, you probably don\'t mean to.  It\'s for Apache::Wyrd::Datum objects and sets, really.');
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

sub _unimplemented {
	my ($self, $params) = @_;
	my @method = caller(1);
	$self->_raise_exception("You need to override the $method[3] method. $params. This message applies to the Wyrd");
}

1;