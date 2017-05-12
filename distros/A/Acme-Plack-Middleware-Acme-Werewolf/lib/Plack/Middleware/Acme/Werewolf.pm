package Plack::Middleware::Acme::Werewolf;

use strict;
use warnings;
use Astro::MoonPhase ();
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( moonlength message handler );

our $VERSION = '0.02';

sub prepare_app {
    my ( $self ) = @_;
    die "Set moonlength" unless $self->moonlength;
    die "handler must be a code reference." if $self->handler && ref( $self->handler ) ne 'CODE';
}

sub call {
    my ( $self, $env ) = @_;
    my $moonage    = ( Astro::MoonPhase::phase( time ) )[2];
    #print "moonage:$moonage\n";
    if ( abs( 14 - $moonage ) > $self->moonlength / 2 ) {
        return $self->app->( $env );
    }
    else {
        my $body = $self->message || 'Forbidden';
 
        if ( $self->handler ) {
            return $self->handler->( $self, $env, $moonage );
        }

        return [
            403, 
            [
                'Content-Type'   => 'text/plain',
                'Content-Length' => length $body,
            ], 
            [ $body ]
        ];
    }
}

1;
__END__

=pod

=head1 NAME

Plack::Middleware::Acme::Werewolf - Plack middleware of Acme::Apache::Werewolf

=head1 SYNOPSIS

  my $app = sub { ... };
  builder {
      enable "Acme::Werewolf", moonlength => 4;
      $app;
  };

=head1 DESCRIPTION

Plack middleware implementation of L<Acme::Apache::Werewolf>
which keeps werewolves out of your web site during the full moon.

=head1 CONFIGURATION

=over

=item moonlength

Required. The period considered as a full moon (in day).

If you set moonlength with 4, the moon age from 12 to 16 is full moon.

=item message

Optional. The forbidden message. Default is 'Forbidden'.

=item handler

Optional. The subroutine reference for resoneses takes the plack middleware itself, environment variable and moon age.

    handler => sub {
        my ( $middleware, $env, $moon_age ) = @_;
        return [ 403, ['Content-Type' => 'text/plain'], ['Werewolf!'] ];
    }

If set this option, C<message> option is ignored.

=back

=head1 SEE ALSO

L<Acme::Apache::Werewolf>, L<Astro::MoonPhase>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

The author of L<Acme::Apache::Werewolf> is Rich Bowen.

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

