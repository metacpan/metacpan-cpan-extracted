package Test::Alien::CanCompileCpp;

use strict;
use warnings;
use base 'Test2::Require';

# ABSTRACT: Skip a test file unless a C++ compiler is available
our $VERSION = '0.95'; # VERSION


sub skip
{
  require ExtUtils::CBuilder;
  ExtUtils::CBuilder->new->have_cplusplus ? undef : 'This test requires a compiler.';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Alien::CanCompileCpp - Skip a test file unless a C++ compiler is available

=head1 VERSION

version 0.95

=head1 SYNOPSIS

 use Test::Alien::CanCompileCpp;

=head1 DESCRIPTION

This is just a L<Test2> plugin that requires that a compiler
be available.  Otherwise the test will be skipped.

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Juan Julián Merelo Guervós (JJ)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
