=encoding utf-8

=head1 NAME

Business::cXML::Credential - cXML credential

=head1 SYNOPSIS

	use Business::cXML::Transmission;
	$msg = new Business::cXML::Transmission $incoming_cxml_string;
	print $msg->to->id;  # Fetches Identity string from the To credential

=head1 DESCRIPTION

Object representation of cXML C<To>, C<From> and C<Sender> (default).

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Credential;
use base qw(Business::cXML::Object);

use constant NODENAME => 'Sender';
use constant PROPERTIES => (
	_note     => undef,
	domain    => 'NetworkId',
	id        => ' ',
	secret    => undef,
	useragent => undef,
	type      => undef,
	lang      => undef,
	contact   => undef,
);
use constant OBJ_PROPERTIES => (
	contact => 'Business::cXML::Contact',
);

use Business::cXML;
use Business::cXML::Contact;
use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
		# domain attribute is implicit
		# type attribute is implicit
		Credential => {
			# We will only consider the last Credential if there are multiples
			Identity     => 'id',
			SharedSecret => 'secret',
			DigitalSignature => '__OBSOLETE',
			CredentialMac    => '__UNIMPLEMENTED',
		},
		Correspondent => {
			preferredLanguage => 'lang',
			# We will implicitly keep only the last Contact if there are multiples
			Contact => [ 'contact', 'Business::cXML::Contact' ],
		},
	});
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});
	my $cred = $node->add('Credential', undef, domain => $self->{domain}, type => $self->{type});
	$cred->add('Identity', $self->{id});
	$cred->add('SharedSecret', $self->{secret}) if $self->{secret};
	# UNIMPLEMENTED: DigitalSignature CredentialMac
	if ($self->{_nodeName} eq 'Sender') {
		$node->add('UserAgent', $Business::cXML::USERAGENT);
	} elsif (ref $self->{contact}) {
		$node->add('Correspondent', undef, preferredLanguage => $self->{lang})
			->add($self->{contact}->to_node($node))
		;
	};
	return $node;
}

=item C<B<domain>>

Mandatory, default: C<NetworkId>

=item C<B<id>>

Mandatory

=item C<B<type>>

Optional, expected to be C<undef> (default) or C<marketplace>

=item C<B<lang>>

Optional, in outgoing messages it is only used if contact information is defined.

=item C<B<contact>>

Optional, L<Business::cXML::Contact> object

=item C<B<_note>>

Private note.  It will be lost in conversion back to cXML.  Intended to help
you store your own representation of the remote company during processing.

=back

=head3 C<Sender> adds:

=over

=item C<B<useragent>>

Mandatory

=item C<B<secret>>

Optional

=back

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=cut

1;
