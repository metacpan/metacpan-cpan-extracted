=head1 NAME

App::LinkSite::Link

=head1 SYNOPSIS

(You probably want to just look at the L<linksite> application.)

=head1 DESCRIPTION

A class to model a link on a link site (part of App::LinkSite).

=cut

use Feature::Compat::Class;

class App::LinkSite::Link {
  our $VERSION = '0.2.0';
  use strict;
  use warnings;
  no if $] >= 5.038, 'warnings', 'experimental::class';

  use URI;
  use URI::Escape qw(uri_escape_utf8 uri_unescape);

  field $title :reader :param;
  field $subtitle :reader :param = '';
  field $link :reader :param;
  field $new_link :reader(is_new) :param(new) = 0;
  field $utm :param = undef;

  ADJUST {
    if ($utm) {
      die "utm must be an object or false\n" unless ref $utm eq 'HASH';
      for my $key (keys %$utm) {
        die "Invalid UTM parameter '$key'; use utm_* names\n"
          unless $key =~ /\Autm_[a-z][a-z0-9_]*\z/;
        die "UTM parameter '$key' must be a string, number, or null\n"
          if defined $utm->{$key} && ref $utm->{$key};
      }
    }
  }

=head1 METHODS

=head2 tracked_link

Returns the destination used for clicks. An optional C<utm> constructor
parameter enables tracking when it is a hash reference, even an empty one.
Defaults are C<utm_source=linksite>, C<utm_medium=referral>,
C<utm_campaign=profile>, and C<utm_content> from a slug of the link title.
Slugs use lowercase Unicode letters and numbers, with other runs replaced
by hyphens and leading/trailing hyphens removed. Empty slugs are omitted.
Supplied values override them; null or empty values omit a parameter.
False or undefined C<utm> leaves the destination unchanged.

Only absolute HTTP(S) URLs are tagged. Existing query parameters, including
UTM values, and fragments are preserved. C<link> still returns the original
destination, which is also used for JSON-LD.

=cut

  method tracked_link {
    return $link unless $utm;
    my $uri = URI->new($link);
    return $link unless ($uri->scheme // '') =~ /\Ahttps?\z/i && $uri->host;

    my $content = lc($title // '');
    $content =~ s/[^\p{L}\p{N}]+/-/g;
    $content =~ s/\A-|-\z//g;
    my %parameters = (
      utm_source => 'linksite', utm_medium => 'referral',
      utm_campaign => 'profile', utm_content => $content, %$utm,
    );
    my %existing;
    for my $pair (split /[&;]/, $uri->query // '') {
      next unless length $pair;
      my ($key) = split /=/, $pair, 2;
      $key =~ tr/+/ /;
      $existing{uri_unescape($key)} = 1;
    }
    my @added;
    for my $key (sort keys %parameters) {
      next if exists $existing{$key};
      next unless defined $parameters{$key} && length $parameters{$key};
      push @added, uri_escape_utf8($key) . '=' . uri_escape_utf8($parameters{$key});
    }
    return $link unless @added;

    # Append to the original query so its ordering, encoding, and duplicates survive.
    my ($base, $fragment) = split /#/, $link, 2;
    my $separator = index($base, '?') < 0 ? '?' : $base =~ /[?&]\z/ ? '' : '&';
    return $base . $separator . join('&', @added)
      . (defined $fragment ? "#$fragment" : '');
  }

=head2 mk_link

Returns a fragment of HTML that is used to display this link on the site.

It's actually an `<li>` that wraps an `<a>`. So this method probably needs
to be renamed or refactored. Maybe it should just be called `render()`.

=cut

  method mk_link {
    my $destination = $self->tracked_link;
    if ($utm) {
      $destination =~ s/&/&amp;/g;
      $destination =~ s/"/&quot;/g;
      $destination =~ s/</&lt;/g;
      $destination =~ s/>/&gt;/g;
    }
    my $a_tag = q[<a href="] . $destination . q[" class="text-decoration-none">] . $self->title . q[</a>];
    my $subtitle = $self->subtitle ? q[<br><small class="text-muted">] . $self->subtitle . q[</small>] : '';

    my @li_classes = qw[list-group-item list-group-item-action];
    push @li_classes, 'new-link' if $self->is_new;

    return qq[<li class='@li_classes'>$a_tag$subtitle</li>];
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
