use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Input::Condenser;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Input::Complex);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::Input::Condenser - Use Wyrd Inputs/Sets as sub-Input Wyrds

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

The Condenser Input is so called because it condenses the results of
several enclosed Inputs into a single value.  It is meant to be an
abstract class from which Inputs can be derived which are used primarily
in editing multiple whole related records along with a reference record,
for example in relating track information to a CD on the same page/form
as the CD information.

=head2 HTML ATTRIBUTES

see C<Apache::Wyrd::Input::Complex>

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<_generate_inputs> (void)

This method should take the _template attribute and make from it any
HTML inputs that are required, for example, by repeating it, altering
the input names/ids to be able to distinguish them from each other.

The result of the generation should be stored under the _data attribute.

=cut

sub _generate_inputs {
	my ($self) = @_;
	$self->_unimplemented('It should produce the Wyrd-rich HTML from the _template attribute and place the output in the _data attribute.');
}

=pod

=item (void) C<_set_template_globals> (void)

Within the template, there may be
C<Apache::Wyrd::Interfaces::Setter>-style placemarkers which must be set
to proper values for the Condenser Input to display properly.  This is
the method one can use in order to set these.  However, these
placemarkers will be set AFTER _generate_inputs, so be sure not to use
placemarkers that are going to be used by sub-inputs, such as
B<$:value>.

=cut

sub _set_template_globals {
	my $self=shift;
	#template globals are used to set elements in the Condenser area that are not Input Wyrds or otherwise
	#self-generating, such as names, titles, etc.  These are used in a simple _set interface.  Caution: avoid
	#namespace conflicts, since these are set AFTER the elements generated in _generate_inputs are processed.
	$self->{'_template_globals'} = {};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup, _format_output, and final_output method on top of
the methods reserved by C<Apache::Wyrd::Input::Complex>.

Additionally, it reserves the Form methods C<register_errors>,
C<register_error_messages>, C<register_errortag>, and C<_set_input>
methods, since it is in essence a mini-form within a form.

=cut

sub _setup {
	my ($self) = @_;
	$self->_flags->complex(1);
	my $id = $self->{'_parent'}->register_input($self);
	$self->_raise_exception('No ID provided by parent') unless ($id);
	$self->{'_template'} = $self->{'_data'};
	$self->{'_id'} = $id;
	$self->{'_data'} = '';
}

sub _format_output {
	my ($self) = @_;
	$self->{'triggers'} = token_parse($self->{'triggers'});
	$self->{'value'} ||= $self->default;
	$self->{'_error_messages'} ||= [];
	$self->{'_error_messages'} ||= [];
}

sub _generate_output {
	my ($self) = @_;
	$self->_generate_inputs;
	#after the inputs are generated, call _process_self to properly generate the children
	$self->_process_self;
	$self->{'_complete_inputs'} = $self->{'_data'};
	my $id = $self->{'_id'};
	$self->_data('$:' . $id);
}

sub final_output {
	my ($self) = @_;
	$self->{'_data'} = $self->{'_complete_inputs'};
	$self->_set_children;
	$self->{'_data'} = $self->_set($self->{'_template_globals'});
	return $self->{'_data'};
}

sub register_errors {
	my ($self, $input) = @_;
	return $self->{_parent}->register_errors($input);
}

sub register_error_messages {
	my ($self, $input) = @_;
	return $self->{_parent}->register_error_messages($input);
}

sub register_errortag {
	my ($self, $input) = @_;
	my $id = $self->{_parent}->register_errortag($input);
	return $self->register_child($input);
}

sub _set_input {
	#necessary for embedded error tags -- ignores them when they're set
	my ($self, $input, $value) = @_;
	return unless ($input->can('set'));
	$input->set($value);
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