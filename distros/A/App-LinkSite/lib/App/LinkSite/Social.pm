=head1 NAME

App::LinkSite::Social

=head1 SYNOPIS

(You probably want to just look at the L<linksite> application.)

=head1 DESCRIPTION

A class to model a social link on a link site (part of App::LinkSite).

=cut

use Feature::Compat::Class;

class App::LinkSite::Social {
  our $VERSION = '0.0.5';
  use strict;
  use warnings;
  use feature qw[say signatures];
  no if $] >= 5.038, 'warnings', qw[experimental::signatures experimental::class];

  field $service :reader :param;
  field $handle :reader :param;
  field $url :reader :param = undef;

  # TODO: This needs to be a class field.
  field $urls = {
    facebook   => {
      url  => "https://facebook.com/",
      name => 'Facebook',
    },
    'x-twitter' => {
      # This is currently still the correct URL
      url  => "https://twitter.com/",
      name => 'X/Twitter',
    },
    instagram  => {
      url  => "https://instagram.com/",
      name => 'Instagram',
    },
    tiktok     => {
      url  => "https://tiktok.com/@",
      name => 'TikTok',
    },
    linkedin   => {
      url  => "https://linkedin.com/in/",
      name => 'LinkedIn',
    },
    substack   => {
      url  => "https://XXXX.substack.com/",
      name => 'Substack',
    },
    github     => {
      url  => "https://github.com/",
      name => 'GitHub',
    },
    medium     => {
      url  => "https://XXXX.medium.com/",
      name => 'Medium',
    },
    reddit     => {
      url  => "https://reddit.com/user/",
      name => 'Reddit',
    },
    quora      => {
      url  => "https://quora.com/profile/",
      name => 'Quora',
    },
    mastodon   => {
      # Hmm...
      url  => "https://fosstodon.org/@",
      name => 'Mastodon',
    },
    threads    => {
      url  => "https://www.threads.net/@",
      name => 'Threads',
    },
    bluesky   => {
      url  => 'https://bsky.app/profile/',
      name => 'Bluesky',
    },
    letterboxd => {
      url  => 'https://letterboxd.com/',
      name => 'Letterboxd',
    },
    lastfm => {
      url  => 'https://last.fm/user/',
      name => 'last.fm',
    },
  };

=head1 METHODS

=head2 mk_social_link

Return a fragment of HTML that is used to represent this social media link
on the link site.

=cut

  method mk_social_link {
    return $url if $url;

    my $social_url;

    if (exists $urls->{$service}) {
      $social_url = $urls->{$service}{url};
    } else {
      warn('Unknown social service: ', $service);
      return;
    }

    if ($social_url =~ /XXXX/) {
      $social_url =~ s/XXXX/$handle/g;
    } else {
      $social_url .= $handle;
    }

    return $social_url;
  }


=head2 social_icon_template

Return a string that is used to produce the HTML that displays the social
icon and link on the link site. The template string will expect three
substitution values:

=over 4

=item *

The title for the link (probably the `name` from the `$urls` field)

=item *

The link for the social account (as built by `mk_social_link()`)

=item *

The name of the social media site's icon as represented in Font Awesome
(probably a key from the `$urls` field).

=back

=cut

  method social_icon_template {
    return q[<a title='%s' href='%s'><i class='fa-brands fa-3x fa-%s'></i></a>];
  }

=head2 mk_social_icon

Returns a fragment of HTML that will be used to display the social media
account on the web site.

=cut

  method mk_social_icon {
    return sprintf $self->social_icon_template,
      $urls->{$service}{name}, $self->mk_social_link(), $service;
  }
}

=head1 AUTHOR

Dave Cross <dave@davecross.co.uk>

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2024, Magnum Solutions Ltd. All Rights Reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
