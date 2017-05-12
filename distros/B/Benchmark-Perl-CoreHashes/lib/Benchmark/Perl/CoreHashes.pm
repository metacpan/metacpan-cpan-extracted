package Benchmark::Perl::CoreHashes;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    run_PERL_HASH_FUNC_SIPHASH
    run_PERL_HASH_FUNC_SDBM
    run_PERL_HASH_FUNC_DJB2
    run_PERL_HASH_FUNC_SUPERFAST
    run_PERL_HASH_FUNC_MURMUR3
    run_PERL_HASH_FUNC_ONE_AT_A_TIME
    run_PERL_HASH_FUNC_ONE_AT_A_TIME_HARD
    run_PERL_HASH_FUNC_ONE_AT_A_TIME_OLD
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Benchmark::Perl::CoreHashes', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Benchmark::Perl::CoreHashes - benchmark core Perl hash algorithms

=head1 SYNOPSIS

  perl Makefile.PL
  make test

=head1 DESCRIPTION

This module benchmarks the various hash algorithms in >= 5.17.10 perl. It
installs nothing. This module was created to generate cpantesters reports.
It is not an API or library.

Do a make test, look at the results. Think about whether your current Perl is
using the fastest hash algorithm or not on your CPU platform.

=head2 EXPORT

No API.

=head1 AUTHOR

Daniel Dragan, E<lt>bulkdd@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Daniel Dragan bulkdd@cpan.org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.19.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
