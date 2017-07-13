package Test::Alien::CanCompile;

use strict;
use warnings;
use base 'Test2::Require';

# ABSTRACT: Skip a test file unless a C compiler is available
our $VERSION = '0.61'; # VERSION


sub skip
{
  require ExtUtils::CBuilder;
  ExtUtils::CBuilder->new->have_compiler ? undef : 'This test requires a compiler.';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Alien::CanCompile - Skip a test file unless a C compiler is available

=head1 VERSION

version 0.61

=head1 SYNOPSIS

 use Test::Alien::CanCompile;

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
