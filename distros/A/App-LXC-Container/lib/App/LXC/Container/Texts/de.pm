package App::LXC::Container::Texts::de;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Texts::de - German language support of L<App::LXC::Container>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly by the main modules of App::LXC::Container via
    use App::LXC::Container::Texts;

=head1 ABSTRACT

This module contains all German texts of L<App::LXC::Container>.

=head1 DESCRIPTION

The module just provides a hash of texts to be used.

See L<App::LXC::Container::Texts::en> for more details.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.14';

#########################################################################

=head1 EXPORT

=head2 %T - hash of German texts

Note that C<%T> is not exported into the callers name-space, it must always
be fully qualified (as it's only used in two location in C<Texts> anyway).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our %T =
    (
     bad_container_name
     => 'Der Name des Containers darf nur Wort-Zeichen enthalten!',
     bad_debug_level__1
     => "unzulässiges Debug Level '%s'",
     message__1_missing
     => "text '%s' fehlt",
     message__1_missing_en
     => "text '%s' fehlt, falle auf en zurück",
     unsupported_language__1
     => "keine Sprachunterstützung für %s, falle auf en zurück",
    );

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<App::LXC::Container>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (AT) cpan.orgE<gt>

=cut
