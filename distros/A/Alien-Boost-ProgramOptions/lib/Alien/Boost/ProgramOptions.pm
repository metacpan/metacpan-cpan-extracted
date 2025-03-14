package Alien::Boost::ProgramOptions;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '1.7';

=head1 NAME

Alien::Boost::ProgramOptions - Wrapper for installing Boost

=head1 DESCRIPTION

Alien::Boost::ProgramOptions is a wrapper to install Boost library. 
Modules that depend on Boost.ProgramOptions can depend on 
Alien::Boost::ProgramOptions and use the CPAN shell 
to install it for you.

=head1 AUTHOR

Thibault Duponchelle E<lt>thibault.duponchelle@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Thibault Duponchelle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Alien>

=back

=cut

1;
