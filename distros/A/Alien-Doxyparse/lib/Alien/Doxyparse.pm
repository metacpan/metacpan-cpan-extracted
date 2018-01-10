package Alien::Doxyparse;
use strict;
use warnings;
use parent 'Alien::Base';
 
our $VERSION = '0.05';

=head1 NAME

Alien::Doxyparse - Build and make available the doxyparse tool

=head1 SYNOPSIS

From your Perl script:

  use Alien::Doxyparse;
  use Env qw( @PATH );

  unshift @PATH, Alien::Doxyparse->bin_dir; # doxyparse is now in your path
  system 'doxyparse', ...;

From alienfile:

  share {
    requires 'Alien::Doxyparse';
    build [
      '%{doxyparse} ...',
    ];
  };

=head1 DESCRIPTION

This distribution installs L<Doxyparse|http://github.com/analizo/doxyparse> so that
it can be used by other Perl distributions. If already installed for your
operating system, and it can be found, this distribution will use the Doxyparse
that comes with your operating system, otherwise it will download it from the
Internet, build and install it from you.

=head1 SEE ALSO

=over

=item *

L<Alien>

=item *

L<Alien::Base>

=back

Similar modules:

=over

=item *

L<Alien::qd>

=item *

L<Alien::flex>

=item *

L<Alien::m4>

=item *

L<Alien::bison>


=item *

L<Alien::CMake>

=item *

L<Alien::ffmpeg>

=item *

L<Alien::Gearman>

=back

=head1 AUTHOR

Joenio Costa <joenio@joenio.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Joenio Costa.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
