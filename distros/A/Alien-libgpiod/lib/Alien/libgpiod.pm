use strict;
use warnings;
package Alien::libgpiod;

use parent qw(Alien::Base);

# ABSTRACT: Find or build libgpiod (Linux GPIO character device library)
our $VERSION = 'v0.1';

=head1 NAME

Alien::libgpiod - Find or Build libgpiod

=head1 SYNOPSIS

In dist.ini, if using L<Dist::Zilla>:

  [Prereqs / ConfigureRequires]
  Alien::libgpiod = v0.1
  
  [MakeMaker::Awesome]
  header = use Alien::Base::Wrapper qw(Alien::libgpiod !export);
  WriteMakefile_arg = Alien::Base::Wrapper->mm_args

=head1 DESCRIPTION

This package will find or build (note: building has not currently been
tested) the libgpiod library, used for accessing GPIO character
devices on Linux. This is a new API that deprecates the older sysfs
GPIO interface since kernel 4.8.

=head1 AUTHOR

Stephen Cavilia E<lt>sac@atomicradi.usE<gt>

=head1 COPYRIGHT

Copyright 2021 Stephen Cavilia

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

1;
