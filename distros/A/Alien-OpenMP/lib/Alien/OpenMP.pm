package Alien::OpenMP;

use strict;
use warnings;

our $VERSION = '0.001';

1;

__END__

=head1 NAME

Alien::OpenMP - Encapsulate system info for OpenMP

=head1 SYNOPSIS

  use Alien::OpenMP;
  say Alien::OpenMP->cflags; # e.g. -fopenmp if GCC
  say Alien::OpenMP->lddlflags; # e.g. -fopenmp if GCC

=head1 DESCRIPTION

Encapsulates knowledge of per-compiler or per-environment information
so consuming modules don't need to know. Won't install if no OpenMP
environment available.

=head1 AUTHOR

OODLER 577 <oodler@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by oodler577

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<PDL>, L<OpenMP::Environment>,
L<https://gcc.gnu.org/onlinedocs/libgomp/index.html>.
