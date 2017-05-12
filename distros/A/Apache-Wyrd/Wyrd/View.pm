use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::View;
our $VERSION = '0.98';
use base qw(Apache::Wyrd Apache::Wyrd::Interfaces::Setter);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::View - Show the attributes of an enclosing Wyrd

=head1 SYNOPSIS

	<BASENAME::Message text="Hello, World!" color="#ffffff">
		<BASENAME::View text="name" />
	</BASENAME::Message>
	
	<BASENAME::Message name="Hello, World!" color="#ffffff">
		<BASENAME::View>
			<p color="$:color">$:name</p>
		</BASENAME::View>
	</BASENAME::Message>


=head1 DESCRIPTION

The View Wyrd is simply a display placemarker for the attributes of the
enclosing wyrd.  If invoked with no enclosing text, it will replace itself
with the value of that one of its parent's attribute indicated under the
"attribute" attribute.  If it encloses some text, that text will be treated
as a "Setter" style template (see C<Apache::Wyrd::Interfaces::Setter>).

=head2 HTML ATTRIBUTES

=over

=item attribute

The name of the attribute it is to display

=back

=head2 PERL METHODS

NONE

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the C<_setup> method.

=cut

sub _setup {
	my ($self) = @_;
	my $data = $self->_data;
	my $attribute = '';
	if ($data) {
		my $hashref = $self->_template_hash($data, $self->_parent);
		$data = $self->_text_set($hashref, $data);
	} else {
		if ($self->{'attribute'}) {
			$data = $self->_parent->{$self->{'attribute'}};
		} else {
			$self->_raise_exception($self->class_name . " Wyrds require either an enclosed template or an attribute");
		}
	}
	$self->_data($data);
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
