package Benchmark::Perl::Formance::Plugin::Shootout;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - Shootout - Benchmark::Perl::Formance plugin covering Shootout code

use strict;
use warnings;

use Benchmark ':hireswallclock';
use Data::Dumper;

our $VERSION = "0.001";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

sub shootout
{
        my ($options) = @_;

        no strict "refs"; ## no critic

        my $verbose = $options->{verbose};
        my %results = ();
                             #fannkuch
                             #knucleotide
                             #mandelbrot
        for my $subtest (qw( binarytrees
                             fasta
                             nbody
                             pidigits
                             regexdna
                             revcomp
                             spectralnorm
                          ))
        {
                print STDERR "#  - $subtest...\n" if $options->{verbose} > 2;
                eval "use Benchmark::Perl::Formance::Plugin::Shootout::$subtest"; ## no critic
                if ($@) {
                        print STDERR "# Skip Shootout plugin '$subtest'" if $verbose;
                        print STDERR ":$@"                               if $verbose >= 2;
                        print STDERR "\n"                                if $verbose;
                }
                else {
                        eval {
                                my $main = __PACKAGE__."::$subtest"."::main";
                                $results{$subtest} = $main->($options);
                        };
                        if ($@) {
                                $results{$subtest} = { failed => $@ };
                        }
                }
        }
        return \%results;
}

sub main
{
        my ($options) = @_;

        return shootout($options);
}

1; # End of Benchmark::Perl::Formance::Plugin::Shootout

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::Shootout - benchmark plugin - Shootout - Benchmark::Perl::Formance plugin covering Shootout code

=head1 AUTHOR

The plugin wrapper for Benchmark::Perl::Formance suite is written by

  Steffen Schwigon c<< <ss5 at renormalist.net> >>

The benchmark code is taken from L<http://shootout.alioth.debian.org>,
written by their respective authors under the following license:

=head1 COPYRIGHT & LICENSE

 This is a specific instance of the Open Source Initiative (OSI) BSD
 license template.

 Revised BSD license

 Copyright © 2004-2010 Brent Fulgham

 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of "The Computer Language Benchmarks Game" nor
      the name of "The Computer Language Shootout Benchmarks" nor the
      names of its contributors may be used to endorse or promote
      products derived from this software without specific prior
      written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
