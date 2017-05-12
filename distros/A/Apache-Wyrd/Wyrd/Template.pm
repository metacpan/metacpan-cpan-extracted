use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Template;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Template - Self-parsed Wyrd template-attribute

=head1 SYNOPSIS

    <BASENAME::Template name="header_template">
      <h1>$:title</h1>
    </BASENAME::Template>

The parent of this object will now be able to get the value
"E<lt>h1E<gt>$:titleE<lt>/h1E<gt>" by accessing it's C<header_template>
attribute.

=head1 DESCRIPTION

Modifies attributes of the parent Wyrd directly (for making templates)
and suspends parsing of the enclosed area.  Like attribute, it allows
the setting of attributes in the parent that contain HTML tags.

=head2 HTML ATTRIBUTES

=over

=item name

Name of the parent Wyrd's attribute to modify

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _setup method.

=cut

sub _setup {
	my ($self) = @_;
	$self->_parent->{$self->{'name'}} = $self->{'_data'};
	$self->_debug("Set parent's '" . $self->{'name'} . "' to '" . $self->{'_data'} . "'");
	$self->{'_data'} = '';
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