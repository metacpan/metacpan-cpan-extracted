#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Form::View;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Form::View - Preview Wyrd for Form Wyrds

=head1 DESCRIPTION

Provides a window into the current state of a C<Apache::Wyrd::Form> object.
 This is useful for previews and similar widgets.

What data is to be viewed is represented by standard
C<Apache::Wyrd::Interface::Setter> placemarkers where variable in
C<$:variable> is the name of the CGI parameter.

Apache::Wyrd::Form::View automatically joins together the values of any
multiple-value cgi variable with the string indicated under the
B<joiner> attribute.  By default, this is ", ".

=head2 HTML ATTRIBUTES

=over

=item joiner

What string to put between items when there are multiple values for the
parameter.  Defaults to ', ' (comma-space).

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<joiner> (void)

The joiner

=cut

sub joiner {
	my ($self) = @_;
	return ($self->{'joiner'} || ', ');
}

=pod

=item (hashref) C<_prepare_values> (hashref)

Hook method for manipulating parameter values before showing them.

=cut

sub _prepare_values {
	my ($self, $values) = @_;
	return $values;
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception("Form::Template objects must exist inside a Form object family member")
		unless ($self->{'_parent'}->can('register_view'));
	$self->{'_template'} = $self->{'_data'};
	$self->{'_data'} = '$:' . $self->{'_parent'}->register_view($self);
}

sub final_output {
	my ($self, $values) = @_;
	$values = {} unless (ref($values) eq 'HASH');
	$values = $self->_prepare_values($values);
	foreach my $key (keys(%$values)) {
		$$values{$key} = join ($self->joiner, @{$$values{$key}}) if (ref($$values{$key}) eq 'ARRAY');
		unless ($$values{$key}) {
			delete ($$values{$key});
			next;
		}
	}
	return $self->_clear_set($values, $self->{'_template'});
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
