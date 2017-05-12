#
# Catlyst::Action::Deserialize::XML::Hash::LX.pm
# Created by: Mons Anderson, <mons@cpan.org>
#
# $Id$

package Catalyst::Action::Deserialize::XML::Hash::LX;

=head1 NAME

Catalyst::Action::Deserialize::XML::Hash::LX - XML::Hash::LX deserializer for Catalyst

=head1 SYNOPSIS

    package Foo::Controller::Bar;

    __PACKAGE__->config(
        default => 'text/xml',
        map => {
            'text/xml' => 'XML::Hash::LX',
            # or 
            'text/xml' => [ 'XML::Hash::LX', { XML::Hash::LX options } ],
        },
    )
    sub begin : ActionClass('Deserialize') {}

=head1 DESCRIPTION

L<XML::Hash::LX> deserializer for L<Catalyst::Action::Deserialize> 

=cut

use strict;
use warnings;

use base 'Catalyst::Action';
use XML::Hash::LX 'xml2hash';

our $VERSION = '0.06';

sub execute {
	my $self = shift;
	my ( $controller, $c, $opts ) = @_;

	my $body = $c->request->body;
	my $rbody;

	if ($body) {
		while (my $line = <$body>) {
			$rbody .= $line;
		}
	}

	if ( $rbody ) {
		warn "Hash::LX deserialize";
		my $rdata = eval { xml2hash( $rbody, $opts ? ( ref $opts eq 'ARRAY' ? @$opts : %$opts ) : () ) };
		return $@ if $@;
		$c->request->data($rdata);
	} else {
		$c->log->debug('I would have deserialized, but there was nothing in the body!') if $c->debug;
	}
	return 1;
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Action::Deserialize>

=item * L<XML::Hash::LX>

=back

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
