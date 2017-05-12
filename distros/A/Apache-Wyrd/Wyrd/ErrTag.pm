use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::ErrTag;
our $VERSION = '0.98';
use base qw(Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::ErrTag - Indicate errors on a Form Wyrd

=head1 SYNOPSIS

	<b>Name:</b><BASENAME::ErrTag trigger="name" /><br>
	<BASENAME::Input type="text" name="name" flags="required" />

=head1 DESCRIPTION

The ErrTag is an item which shows up when an error occurs.  It is used
for putting a placemarker, typically an asterisk, next to an input with
an error in it's input.

=head2 HTML ATTRIBUTES

=over

=item trigger

Alias of triggers.

=item triggers

Which errors to alter state for.  May be a comma or whitespace separated
list.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<default_tag> (void)

Returns the HTML string which should be used as the default.  Normally
an asterisk spanned with the class "error".

=cut

sub default_tag {
	return '<span class="error">*</span>';
}

=pod

=item (void) C<fire> (void)

Method called to trigger the behavior of an error.

=cut

sub fire {
	my ($self) = @_;
	$self->{'_text'} = $self->{'_errtag'};
}

=pod

=item (arrayref) C<get_triggers> (void)

Called by the Form parent to determine what error conditions will
trigger this tag.

=cut

sub get_triggers {
	my ($self) = @_;
	return $self->{'_trigger_on'};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the C<_setup>, C<_format_output>, and C<final_output> methods.

=cut

sub _setup {
	my ($self) = @_;
	my $triggers = ($self->{'trigger'} || $self->{'triggers'});
	$self->_raise_exception("ErrorTag requires triggers") unless ($self->{'trigger'});
	$self->{'_trigger_on'} = [token_parse($triggers)];
}

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception("ErrorTag must be in the top-level of a Form family tag")
		unless ($self->{'_parent'}->can('register_errortag'));
	my $id = $self->{'_parent'}->register_errortag($self);
	$self->_raise_exception('No ID provided by form') unless ($id);
	$self->{'_errtag'} = ($self->_data || $self->default_tag);
	$self->{'_text'} = '';
	$self->_data('$:' . $id);
}

sub final_output {
	my ($self) = @_;
	return $self->{'_text'};
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Form

Build complex HTML forms from Wyrds

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
