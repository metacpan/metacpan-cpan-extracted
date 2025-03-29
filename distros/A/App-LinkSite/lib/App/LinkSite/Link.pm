=head1 NAME

App::LinkSite::Link

=head1 SYNOPSIS

(You probably want to just look at the L<linksite> application.)

=head1 DESCRIPTION

A class to model a link on a link site (part of App::LinkSite).

=cut

use Feature::Compat::Class;

class App::LinkSite::Link {
  our $VERSION = '0.0.13';
  use strict;
  use warnings;
  no if $] >= 5.038, 'warnings', 'experimental::class';

  field $title :reader :param;
  field $subtitle :reader :param = '';
  field $link :reader :param;
  field $new_link :reader(is_new) :param(new) = 0;

=head1 METHODS

=head2 mk_link

Returns a fragment of HTML that is used to display this link on the site.

It's actually an `<li>` that wraps an `<a>`. So this method probably needs
to be renamed or refactored. Maybe it should just be called `render()`.

=cut

  method mk_link {
    my $a_tag = q[<a href="] . $self->link . q[" class="text-decoration-none">] . $self->title . q[</a>];
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
