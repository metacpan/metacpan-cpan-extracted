package Benchmark::Perl::Formance::Plugin::PerlStone2015::regexdna;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Match DNA 8-mers and substitute nucleotides for IUB codes
$Benchmark::Perl::Formance::Plugin::PerlStone2015::regexdna::VERSION = '0.002';
# COMMAND LINE:
# /usr/bin/perl regexdna.perl-2.perl 0 < regexdna-input5000000.txt

# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
# contributed by Danny Sauer
# completely rewritten and
# cleaned up for speed and fun by Mirco Wahab
# improved STDIN read, regex clean up by Jake Berner
# More speed and multithreading by Andrew Rodland
# Benchmark::Perl::Formance plugin by Steffen Schwigon

use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use File::ShareDir qw(dist_dir);
use Benchmark ':hireswallclock';
use Scalar::Util "reftype";

sub run
{
        my ($infile) = @_;

        my $srcdir; eval { $srcdir = dist_dir('Benchmark-Perl-Formance-Cargo')."/Shootout" };
        return { failed => "no Benchmark-Perl-Formance-Cargo" } if $@;

        my $srcfile = "$srcdir/$infile";
        open my $INFILE, "<", $srcfile or die "Cannot read $srcfile";

        my $l_file  = -s $INFILE;
        my $content; read $INFILE, $content, $l_file;
        # this is significantly faster than using <> in this case
        close $INFILE;

        $content =~ s/^>.*//mg;
        $content =~ tr/\n//d;
        my $l_code  =  length $content;

        my @seq = ( 'agggtaaa|tttaccct',
                    '[cgt]gggtaaa|tttaccc[acg]',
                    'a[act]ggtaaa|tttacc[agt]t',
                    'ag[act]gtaaa|tttac[agt]ct',
                    'agg[act]taaa|ttta[agt]cct',
                    'aggg[acg]aaa|ttt[cgt]ccct',
                    'agggt[cgt]aa|tt[acg]accct',
                    'agggta[cgt]a|t[acg]taccct',
                    'agggtaa[cgt]|[acg]ttaccct' );

        my @procs;
        for my $s (@seq) {
                my $pat = qr/$s/;
                my $pid = open my $fh, '-|';
                defined $pid or die "Error creating process";
                unless ($pid) {
                        my $cnt = 0;
                        ++$cnt while $content =~ /$pat/gi;
                        print "$s $cnt\n";
                        exit 0;
                }
                push @procs, $fh;
        }

        for my $proc (@procs) {
                #print
                <$proc>;
                close $proc;
        }

        my %iub = (         B => '(c|g|t)',  D => '(a|g|t)',
                            H => '(a|c|t)',   K => '(g|t)',    M => '(a|c)',
                            N => '(a|c|g|t)', R => '(a|g)',    S => '(c|g)',
                            V => '(a|c|g)',   W => '(a|t)',    Y => '(c|t)' );

        # We could cheat here by using $& in the subst and doing it inside a string
        # eval to "hide" the fact that we're using $& from the rest of the code... but
        # it's only worth 0.4 seconds on my machine.
        my $findiub = '(['.(join '', keys %iub).'])';

        $content =~ s/$findiub/$iub{$1}/g;

        return {
                length_file    => $l_file,
                length_code    => $l_code,
                length_content => length $content,
               };
}

sub main
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? "fasta-100000.txt" : "fasta-1000000.txt";
        my $count  = $options->{fastmode} ? 5 : 10;

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
        return $result if reftype($result) eq "HASH" and $result->{failed};

        return {
                Benchmark     => $t,
                goal          => $goal,
                count         => $count,
                result        => $result,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::regexdna - benchmark - Match DNA 8-mers and substitute nucleotides for IUB codes

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
