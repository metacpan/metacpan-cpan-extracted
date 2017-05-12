use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::ErrField;
our $VERSION = '0.98';
use strict;
use base qw(Apache::Wyrd::ErrTag);

=pod

=head1 NAME

Apache::Wyrd::ErrField - Alter layout of an Apache Wyrd to indicate errors

=head1 SYNOPSIS

    <BASENAME::ErrField trigger="name">
      <b>Name:</b>
    </BASENAME::ErrField><br>
    <BASENAME::Input type="text" name="name" flags="required" />

=head1 DESCRIPTION

Identical to C<Apache::Wyrd::ErrTag>, but instead changes the format of
the enclosed text (by default to the CSS class of "error"), if the
trigger error has occurred.  This is meant to be used as a method of
changing the appearance of the titles of inputs when those inputs
contain illegal values.

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

=item (void) C<fire> (void)

Method called to trigger the behavior of an error.

=cut

sub fire {
	my ($self) = @_;
	$self->{'_text'} = '<span class="error">'. $self->{'_text'} . '</span>';
}

=item (arrayref) C<get_triggers> (void)

Called by the Form parent to determine what error conditions will
trigger this tag.

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception("ErrorField must be in the top-level of a Form family tag")
		unless ($self->{'_parent'}->can('register_errortag'));
	my $id = $self->{'_parent'}->register_errortag($self);
	$self->_raise_exception('No ID provided by form') unless ($id);
	$self->{'_text'} = $self->{'_data'};
	$self->_data('$:' . $id);
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

sub default_tag {
	return;
}

1;