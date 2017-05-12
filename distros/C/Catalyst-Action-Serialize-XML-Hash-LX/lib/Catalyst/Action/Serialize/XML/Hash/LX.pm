#
# Catlyst::Action::Serialize::XML::Hash::LX.pm
# Created by: Mons Anderson, <mons@cpan.org>
#
# $Id$

package Catalyst::Action::Serialize::XML::Hash::LX;

=head1 NAME

Catalyst::Action::Serialize::XML::Hash::LX - XML::Hash::LX serializer for Catalyst

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
    sub end : ActionClass('Serialize') {}

=head1 DESCRIPTION

L<XML::Hash::LX> serializer for L<Catalyst::Action::Serialize> 

=cut

use 5.006002;
use strict;
use warnings;

use base 'Catalyst::Action';
use XML::Hash::LX 'hash2xml';

our $VERSION = '0.06';

sub execute {
	my $self = shift;
	my ( $controller, $c, $opts ) = @_;
	
	my $stash_key = (
		$controller->{'serialize'} ?
			$controller->{'serialize'}->{'stash_key'} :
			$controller->{'stash_key'} 
	) || 'rest';
	my $output = eval {
		hash2xml( $c->stash->{$stash_key}, $opts ? ( ref $opts eq 'ARRAY' ? @$opts : %$opts ) : () );
	};
	return $@ if $@;
	$c->response->output( $output );
	return 1;
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Action::Serialize>

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
