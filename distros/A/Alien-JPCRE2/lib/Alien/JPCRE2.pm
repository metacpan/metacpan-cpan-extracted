use strict;
use warnings;
package Alien::JPCRE2;

our $VERSION = '0.003000';

use base qw( Alien::Base );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::JPCRE2 - Find or download/build/install libjpcre2 in JPCRE2, the C++ wrapper for the new Perl Compatible Regular Expression engine

=head1 SYNOPSIS

From a Perl script

    use Alien::JPCRE2;
    use Env qw(@PATH);

    print Alien::JPCRE2->dist_dir();

=head1 DESCRIPTION

This package can be used by other CPAN modules that require JPCRE2 or libjpcre2.

=head1 AUTHOR

William N. Braswell, Jr. <wbraswell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by William N. Braswell, Jr.;

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
