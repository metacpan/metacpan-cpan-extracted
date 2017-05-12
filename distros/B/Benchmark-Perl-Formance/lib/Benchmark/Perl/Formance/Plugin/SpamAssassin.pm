package Benchmark::Perl::Formance::Plugin::SpamAssassin;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - SpamAssassin - SpamAssassin Benchmarks

use strict;
use warnings;

our $VERSION = "0.003";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use File::Temp qw(tempfile tempdir);
use File::Copy::Recursive qw(dircopy);
use File::ShareDir qw(dist_dir);
use Time::HiRes qw(gettimeofday);

our $count;
our $easy_ham;

use Benchmark ':hireswallclock';

sub main {
        my ($options) = @_;

        require Mail::SpamAssassin;
        my $sa_version = $Mail::SpamAssassin::VERSION;

        my $srcdir; eval { $srcdir = dist_dir('Benchmark-Perl-Formance-Cargo')."/SpamAssassin" };
        if ($@) {
                return { salearn => { failed => "no Benchmark-Perl-Formance-Cargo" } }
        }

        (my $salearn = $^X) =~ s!/perl[\d.]*$!/sa-learn!;
        if (not $salearn && -x $salearn) {
                print STDERR "# did not find executable $salearn\n" if $options->{verbose} >= 2;
                return { salearn => { failed => "did not find executable sa-learn", salearn_path => $salearn } };
        }

        $count     = $options->{fastmode} ? 1 : 5;
        my @passes = $options->{fastmode} ? (
                                             { metric => "ham",
                                               type   => "ham",
                                               subdir => "easy_ham_subset",
                                             },
                                            ) :
                                             (
                                              { metric => "ham",
                                                type   => "ham",
                                                subdir => "easy_ham",
                                              },
                                              { metric => "ham2",
                                                type   => "ham",
                                                subdir => "easy_ham_2",
                                              },
                                              { metric => "spam",
                                                type   => "spam",
                                                subdir => "spam",
                                              },
                                              { metric => "spam2",
                                                type   => "spam",
                                                subdir => "spam_2",
                                              },
                                             );

        # sa-learn
        my %results;
        for my $pass (@passes) {
                my @output;
                my $cmd       = "$^X -T $salearn --$pass->{type} -L --no-sync '$srcdir/$pass->{subdir}' 2>&1";
                print STDERR "\n# $cmd\n" if $options->{verbose} >= 4;
                my $t         = timeit $count, sub { @output = map { chomp; $_ } qx($cmd) };
                my $maxerr    = ($#output < 10) ? $#output : 10;
                print STDERR join("\n# ", "", @output[0..$maxerr]) if $options->{verbose} >= 4;

                $results{salearn}{$pass->{metric}} = {
                                                      Benchmark    => [@$t],
                                                      salearn_path => $salearn,
                                                      sa_version   => $sa_version,
                                                      count        => $count,
                                                     };
        }
        return \%results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::SpamAssassin - benchmark plugin - SpamAssassin - SpamAssassin Benchmarks

=head1 ABOUT

This plugin does some runs with SpamAssassin on the public corpus
provided taken from spamassassin.org.

=head1 CONFIGURATION

It uses the executable "sa-learn" that it by default searches in
the same path of your used perl executable ($^X).

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
