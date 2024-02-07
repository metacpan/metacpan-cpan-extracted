package App::LXC::Container::Data::Ubuntu;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Data::Ubuntu - define Ubuntu-specific configuration data

=head1 SYNOPSIS

    # This module should only be used by OS-specific classes deriving from
    # it or by App::LXC::Container::Data.

=head1 ABSTRACT

This module provides configuration data specific for Ubuntu.

=head1 DESCRIPTION

see L<App::LXC::Container::Data>

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.41';

use App::LXC::Container::Data::Debian;

#########################################################################

=head1 EXPORT

Nothing is exported as access should only be done using the singleton
object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;
our @ISA = qw(App::LXC::Container::Data::Debian);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

C<L<App::LXC::Container::Data>>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
