=encoding utf-8

=head1 NAME

Business::cXML::Request::PunchOutSetup - cXML punch-out setup request payload

=head1 SYNOPSIS

	use Business::cXML;
	my $cxml = new Business::cXML;
	my $posr = $cxml->new_request('PunchOutSetup');
	$posr->checkout_url = 'https://www.example.com/welcome_back';

=head1 DESCRIPTION

Object representation of a cXML punch-out setup request.

If no C<Contact> information is supplied directly in the request, this module
will try to infer the information (name and e-mail address) from any
recognized C<Extrinsic> elements: e-mail is obtained from C<UserEmail> and
name from C<UserFullName>, C<UserPrintableName>, C<FirstName>/C<LastName>,
C<User>, C<UniqueUsername> or C<UniqueName>.

B<Caution:> This implementation is centered around C<create> operations and
thus doesn't implement C<SelectedItem> and C<ItemOut>.

Also supports the C<ReturnFrame> extrinsic required by Aquiire (Vinimaya).
See L</checkout_target()>.

=head1 METHODS

See L<Business::cXML::Object/COMMON METHODS>.

=head1 PROPERTY METHODS

See L<Business::cXML::Object/PROPERTY METHODS> for how the following operate.

=over

=cut

use 5.014;
use strict;

package Business::cXML::Request::PunchOutSetup;
use base qw(Business::cXML::Object);

use constant NODENAME => 'PunchOutSetupRequest';
use constant PROPERTIES => (
	_ext_email      => undef,
	_ext_name       => undef,
	_ext_firstname  => undef,
	_ext_lastname   => undef,
	_ext_uid        => undef,
	operation       => 'create',
	buyer_cookie    => ' ',
	checkout_url    => undef,
	checkout_target => undef,
	contacts        => [],
	shipto          => undef,
);
use constant OBJ_PROPERTIES => (
	contacts => 'Business::cXML::Contact',
	shipto   => 'Business::cXML::ShipTo',
);

use Business::cXML::Contact;
use XML::LibXML::Ferry;

sub from_node {
	my ($self, $el) = @_;

	$el->ferry($self, {
			BuyerCookie     => 'buyer_cookie',
			BrowserFormPost => { URL => 'checkout_url' },
			Contact         => [ 'contacts',     'Business::cXML::Contact' ],
			SupplierSetup   => '__OBSOLETE',
			ShipTo          => [ 'shipto',       'Business::cXML::ShipTo'  ],
			SelectedItem    => '__UNIMPLEMENTED',
			ItemOut         => '__UNIMPLEMENTED',
			Extrinsic       => {
				__meta_name       => 'name',
				ReturnFrame       => 'checkout_target',
				UserEmail         => '_ext_email',
				FirstName         => '_ext_firstname',
				LastName          => '_ext_lastname',
				UserFullName      => '_ext_name',
				UserPrintableName => '_ext_name',
				User              => '_ext_uid',
				UniqueUsername    => '_ext_uid',
				UniqueName        => '_ext_uid',
			},
		}
	);

	# Fake a contact from extrinsics if necessary
	unless (scalar @{ $self->{contacts} } > 0) {
		# 1. Full name
		# 2. First + last names
		# 3. User ID is better than nothing
		$self->{_ext_name} = $self->{_ext_firstname} . ' ' . $self->{_ext_lastname}
			if !$self->{_ext_name} && $self->{_ext_firstname} && $self->{_ext_lastname};
		$self->{_ext_name} = $self->{_ext_uid}
			unless $self->{_ext_name};
		if ($self->{_ext_email} && $self->{_ext_name}) {
			$self->contacts(
				new Business::cXML::Contact 'Contact', {
					name   => $self->{_ext_name},
					emails => $self->{_ext_email},
					# CAUTION: the language is left to default, but should ideally be the cXML node's
				}
			);
		};
	};
}

sub to_node {
	my ($self, $doc) = @_;
	my $node = $doc->create($self->{_nodeName});
	$node->{operation} = $self->{operation};

	$node->add('BuyerCookie', $self->{buyer_cookie});
	$node->add('Extrinsic', $self->{checkout_target}, name => 'ReturnFrame') if defined $self->{checkout_target};
	$node->add('BrowserFormPost')->add('URL', $self->{checkout_url}) if defined $self->{checkout_url};
	$node->add($_->to_node($node)) foreach (@{ $self->{contacts} });
	$node->add($self->{shipto}->to_node($node)) if defined $self->{shipto};

	return $node;
}

=item C<B<operation>>

Mandatory, one of: C<create> (default), C<inspect>, C<edit>, C<source>

=item C<B<buyer_cookie>>

Mandatory

=item C<B<checkout_url>>

Optional, the URL to which a subsequent form post should submit a
C<PunchOutOrderMessage>.

=item C<B<checkout_target>>

Optional, "ReturnFrame" extrinsic which some buyers use to specify the target
frame for the checkout POST form.

=item C<B<contacts[]>>

Optional, L<Business::cXML::Contact> objects

=item C<B<shipto>>

Optional, L<Business::cXML::ShipTo> object

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
