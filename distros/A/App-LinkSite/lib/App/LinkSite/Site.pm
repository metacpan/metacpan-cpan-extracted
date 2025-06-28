=head1 NAME

App::LinkSite::Site

=head1 SYNOPIS

(You probably want to just look at the L<linksite> application.)

=head1 DESCRIPTION

A class to model a link site (part of App::LinkSite).

=cut

use Feature::Compat::Class;

class App::LinkSite::Site {
  our $VERSION = '0.0.15';
  use strict;
  use warnings;
  no if $] >= 5.038, 'warnings', 'experimental::class';

  use JSON;

  field $name :reader :param;
  field $handle :reader :param;
  field $image :reader :param;
  field $desc :reader :param;
  field $og_image :reader :param;
  field $site_url :reader :param;

  field $socials :reader :param = [];
  field $links :reader :param = [];

=head1 METHODS

=head2 json_ld

Returns a JSON/LD fragment for this web site.

=cut

  method json_ld {
    my $json = {
      '@context' => 'https://schema.org',
      '@type' => 'WebPage',
      name => "Links page for $name ($handle)",
      mainEntity => {
        '@context' => 'https://schema.org',
        '@type' => 'Person',
        name => $self->name,
        image => $self->image,
        sameAs => [ map { $_->mk_social_link } $self->socials->@* ],
      },
      relatedLink => [ map { $_->link } $self->links->@* ],
    };

    return JSON->new->pretty->encode($json);
  }
}

1;

=head1 AUTHOR

Dave Cross <dave@davecross.co.uk>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2024, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
