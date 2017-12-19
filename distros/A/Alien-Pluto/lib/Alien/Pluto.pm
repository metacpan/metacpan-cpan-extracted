use strict;
use warnings;
package Alien::Pluto;

our $VERSION = '0.003000';

use base qw( Alien::Base );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Pluto - Find or download/build/install libpluto in the Pluto PolyCC compiler suite

=head1 SYNOPSIS

From a Perl script

    use Alien::Pluto;

    use Env qw(@PATH);
    unshift @PATH, Alien::Pluto->bin_dir();
    system 'pluto -v';

    print Alien::Pluto->dist_dir();

=head1 DESCRIPTION

This package can be used by other CPAN modules that require Pluto or libpluto.

=head1 AUTHOR

William N. Braswell, Jr. <wbraswell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by William N. Braswell, Jr.;

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
