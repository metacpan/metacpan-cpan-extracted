use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Attribute;
our $VERSION = '0.98';
use base qw (Apache::Wyrd);

=pod

=head1 NAME

Apache::Wyrd::Attribute - Unparsed Wyrd template/attribute

=head1 SYNOPSIS

	<BASENAME::Attribute name="title"><BASENAME::CGISetter>$:data</BASENAME::CGISetter></BASENAME::Attribute>

The parent of this object will have it's attribute C<title> set to the value of
the CGI variable "data"

=head1 DESCRIPTION

Modifies attributes of the parent object directly after the enclosed
space is fully parsed.  This is unlike Apache::Wyrd::Template which does
not parse the enclosed area beforehand.  Both these Wyrds are meant to
provide a comprehensible way of setting Wyrd attributes to values which
contain HTML text without resorting to an "insane" escaping syntax.

=head2 HTML ATTRIBUTES

=over

=item name

The name of the attribute of the parent Wyrd which is set to the value of the
enclosing text.

=item value

The value to set the attribute of the parent to.  Defaults to the
enclosed text if unspecified.

=back

=head2 PERL METHODS

I<(format: (returns) name (accepts))>

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the _format_output method.  Modifies the parent Wyrd's
attribute by direct manipulation, violating strict object encapsulation,
sort of like a "family" class.

=cut

sub _format_output {
	my ($self) = @_;
	my $value = ($self->{'value'} || $self->{'_data'});
	$self->_parent->{$self->{'name'}} = $value;
	$self->_debug("Set parent's '$self->{name}' to '$value'");
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