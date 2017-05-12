package Benchmark::Perl::Formance::Plugin::P6STD;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - P6STD - Stress using Perl6/Perl5 tools around STD.pm

use strict;
use warnings;

our $VERSION = "0.002";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

our $goal;
our $count;

use Benchmark ':all', ':hireswallclock';
use File::Temp qw(tempfile tempdir);
use File::ShareDir qw(dist_dir);
use File::Copy::Recursive qw(dircopy fcopy);
use Cwd;

sub prepare {
        my ($options) = @_;

        my $dstdir = tempdir( CLEANUP => 1 );

        my $srcdir; eval { $srcdir = dist_dir('Benchmark-Perl-Formance-Cargo')."/P6STD" };
        return if $@;

        print STDERR "# Make viv in $dstdir ...\n" if $options->{verbose} >= 3;
        dircopy($srcdir, $dstdir);

        my $cmd = "cd $dstdir ; make PERL=$^X 2>&1";
        print STDERR "# $cmd\n"   if $options->{verbose} && $options->{verbose} >= 4;
        print STDERR "# Run...\n" if $options->{verbose} && $options->{verbose} >= 3;

        my @output;
        my $makeviv = { Benchmark => timeit(1, sub { @output = map { chomp; $_ } qx"$cmd" }) };

        my $maxerr = ($#output < 10) ? $#output : 10;
        print STDERR join("\n# ", "", @output[0..$maxerr])    if $options->{verbose} >= 4;

        return $dstdir, $makeviv;
}

sub viv
{
        my ($workdir, $options) = @_;

        my $viv       = "$workdir/viv";
        my $perl6file = "$workdir/$goal";
        my $cmd       = "cd $workdir ; $^X -I. $viv $perl6file";

        print STDERR "# $cmd\n"   if $options->{verbose} && $options->{verbose} >= 4;
        print STDERR "# Run...\n" if $options->{verbose} && $options->{verbose} >= 3;

        my @output;
        my $t = timeit ($count, sub { @output = map { chomp; $_ } qx"$cmd" });

        my $maxerr = ($#output < 10) ? $#output : 10;
        print STDERR join("\n# ", "", @output[0..$maxerr])    if $options->{verbose} >= 4;

        return {
                Benchmark => $t,
                goal      => $goal,
               };
}

sub main {
        my ($options) = @_;

        $goal  = $options->{fastmode} ? "hello.p6" : "STD.pm6";
        $count = $options->{fastmode} ? 1          : 5;

        my $workdir;
        my $makeviv;
        my $viv;
        ($workdir, $makeviv ) = prepare($options);
        return { failed => "no Benchmark-Perl-Formance-Cargo" } if not $workdir;

        $viv = viv($workdir, $options);

        return {
                makeviv => $makeviv,
                viv     => $viv,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::P6STD - benchmark plugin - P6STD - Stress using Perl6/Perl5 tools around STD.pm

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
