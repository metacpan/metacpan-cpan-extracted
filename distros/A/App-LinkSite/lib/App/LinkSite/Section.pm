=head1 NAME

App::LinkSite::Section

=head1 SYNOPSIS

(You probably want to just look at the L<linksite> application.)

=head1 DESCRIPTION

A class to model a section of links on a link site (part of App::LinkSite).

=cut

use Feature::Compat::Class;

class App::LinkSite::Section {
  our $VERSION = '0.1.3';
  use strict;
  use warnings;
  no if $] >= 5.038, 'warnings', 'experimental::class';

  field $title :reader :param;
  field $links :reader :param = [];

=head1 METHODS

=head2 has_links

Returns true if this section has any links.

=cut

  method has_links {
    return scalar @$links > 0;
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
