use 5.008001; use strict; use warnings;

package Catalyst::Plugin::Flash;

our $VERSION = '0.002';

use URI ();

sub flash {
	my ( $c, $uri, %var ) = ( shift, @_ );
	( my $location = URI->new_abs( $uri, $c->request->uri )->as_string ) =~ s!#.*!!s;
	@{ $c->{(__PACKAGE__)}{ $location } }{ keys %var } = values %var;
	$uri;
}

sub clear_flash { %{ $_[0]{(__PACKAGE__)} } = () }

########################################################################

sub flash_to_cookie   { shift; @_ }
sub flash_from_cookie { shift; @_ }

########################################################################

sub prepare_flash {
	my $c = shift;
	( my $location = $c->request->uri->as_string ) =~ s!#.*!!s;
	my $cookie = $c->request->cookie( $location ) or return;
	$c->stash( $c->flash_from_cookie( $cookie->value ) );
	$c->response->cookies->{ $cookie->name } = { expires => '-1y', value => '' };
}

sub finalize_flash {
	my $c = shift;
	my $flash = $c->{(__PACKAGE__)} or return;
	my $uri = $c->response->status =~ /\A(?:30[12378]|201)\z/ && $c->response->location or return;
	( my $location = URI->new_abs( $uri, $c->request->uri )->as_string ) =~ s!#.*!!s;
	my @value = $c->flash_to_cookie( %{ $flash->{ $location } or return } );
	$c->response->cookies->{ $location } = { expires => '+1m', value => \@value };
}

########################################################################

# use Catalyst 5.80004 ();
use Moose::Role;
after prepare_path => sub { shift->prepare_flash };
before finalize_cookies => sub { shift->finalize_flash };
no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Flash - put values on the stash of the next request

=head1 DESCRIPTION

This plugin will allow providing values that will automatically be placed
on the stash during a subsequent request.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
