package Catalyst::Plugin::Facebook;
our $VERSION = '0.2';


use strict;
use warnings;

use WWW::Facebook::API;

use Scalar::Util qw();

# why not
*fb = \&facebook;

sub facebook {
    my ($c) = @_;
    unless ( $c->{'facebook'} and Scalar::Util::blessed($c->{'facebook'}) and $c->{'facebook'}->isa('WWW::Facebook::API') ) {
        $c->{'facebook'} = WWW::Facebook::API->new(
            'desktop' => 0,
            'format' => 'JSON',
            'parse' => 1,
            %{ $c->config->{'facebook'} || { }  },
        );
        $c->{'facebook'}->query( $c->request);
        my $params = $c->facebook->canvas->get_fb_params;
        $c->{'facebook'}->session('uid' => $params->{'user'}, 'key' => $params->{'session_key'}, 'expires' => $params->{'expires'});
    }
    return $c->{'facebook'};
}

1;



=pod

=head1 VERSION

version 0.2

=pod 

=head1 NAME

Catalyst::Plugin::Facebook - Build Facebook applications in Catalyst easier

=head1 SYNOPSIS

This module adds quick and easy access to WWW::Facebook::API within
a Catalyst application.

  use Catalyst qw/Facebook/;
  __PACKAGE__->config(
    'facebook' => {
      'api_key' => 'api_key_xyz',
      'secret' => '12345ddd',
    }
  );

  sub auto : Private { 
      my ( $self, $c ) = @_;
      if (! $self->can_display($c)) {
          return;
      }
      return 1;
  }

  sub can_display {
      my ($self, $c) = @_;
      if (! $c->facebook->canvas->in_fb_canvas()) {
          $c->res->redirect('http://apps.facebook.com/iplaywow/');
          return 0;
      }
      if (! $c->facebook->canvas->get_fb_params->{'added'} ) {
          $c->res->redirect($c->facebook->get_add_url());
          return 0;
      }
      my $user = $c->facebook->canvas->get_fb_params->{'user'};
      if (! $user) {
          $c->res->redirect($c->facebook->get_login_url());
          return 0;
      }
      return 1;
  }

=head1 CONFIGURATION

This package uses the 'facebook' configuration namespace. See the
WWW::Facebook::API module for all of the configuration options available.

The two required configuration options are 'api_key' and 'secret'.

=head1 INTERFACE

=head2 METHODS

=head3 facebook

This method, which will be available on your Catalyst context object, will
return the full L<WWW::Facebook::API> object.

=head3 fb

fb is just an alias for facebook.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-facebook at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Facebook>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Facebook

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Facebook>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Facebook>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Facebook>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Facebook>

=back 

=head1 COPYRIGHT & LICENSE

Copyright 2007 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



=head1 AUTHOR

  Nick Gerakines <nick@gerakines.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Nick Gerakines.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__

