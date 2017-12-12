use strict;
use warnings;
package Alien::Texinfo;

our $VERSION = '0.001000';

use base qw( Alien::Base );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Texinfo - Find or download/build/install libtexinfo in the Texinfo GNU Documentation System

=head1 SYNOPSIS

From a Perl script

    use Alien::Texinfo;

    use Env qw(@PATH);
    unshift @PATH, Alien::Texinfo->bin_dir();
    system 'makeinfo';

    print Alien::Texinfo->dist_dir();

=head1 DESCRIPTION

This package can be used by other CPAN modules that require Texinfo or libtexinfo.

=head1 AUTHOR

William N. Braswell, Jr. <wbraswell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by William N. Braswell, Jr.;

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
