package Alien::Tar::Size;

use 5.006;
use strict;
use warnings;
use parent qw( Alien::Base );
use version; our $VERSION = version->declare("v0.1.0");

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Alien::Tar::Size - tar LD_PRELOAD hack to compute size of tar file
without reading and writing, provided as Alien package

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Alien::Tar::Size

Additional documentation, support, and bug reports can be found at the
MHFS repository L<https://github.com/G4Vi/MHFS>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut