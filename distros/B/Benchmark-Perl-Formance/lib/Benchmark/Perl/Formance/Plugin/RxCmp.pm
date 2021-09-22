package Benchmark::Perl::Formance::Plugin::RxCmp;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - RxCmp - Compare different Regex engines


use 5.010; # [sic - pluggable regex engines]
use strict;
use warnings;

our $VERSION = "0.002";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';
use Data::Dumper;

our $goal;
our $count;
our $length;
our $n;
our $re;
our $string;

sub native
{
        my ($options) = @_;

        my $result;
        my $reg = qr/$re/o;
        my $t = timeit $count, sub { $result = $string =~ $reg };
        return {
                Benchmark             => $t,
                goal                  => $goal,
                count                 => $count,
                result                => $result,
                # string                => $string,
                # re                    => $re,
                used_qr_or_precompile => 1,
               };
}

sub POSIX
{
        my ($options) = @_;

        my $reg;
        ## no critic
        eval '
                use POSIX::Regex qw(:all);
                $reg = POSIX::Regex->new($re, REG_EXTENDED);
        ';
        ## use critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }


        my $result;
        my $t = timeit $count, sub { $result = $reg->match($string) };
        return {
                Benchmark             => $t,
                goal                  => $goal,
                count                 => $count,
                result                => $result,
                # string                => $string,
                # re                    => $re,
                used_qr_or_precompile => 1,
               };
}

sub LPeg
{
        my ($options) = @_;

        # LPEG regexes seemingly don't work the same way as usual regexes
        # therefore the pattern below does not match.
        # TODO: Find a equivalent pattern.
        eval "use re::engine::LPEG"; ## no critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }

        return { not_yet_implemented => 'missing comparable equivalent regex' };

        my $result;
        my $re_local = ("'a'?" x $n) . ("'a'" x $n);
        #my $reg      = qr/$re_local/; # using that $reg later segfaults
        my $t = timeit $count, sub { $result = $string =~ /$re_local/ };
        return {
                Benchmark             => $t,
                goal                  => $goal,
                count                 => $count,
                result                => $result,
                # string                => $string,
                # re                    => $re_local,
                used_qr_or_precompile => 0,
               };
}

sub Lua
{
        my ($options) = @_;

        # LPEG regexes seemingly don't work the same way as usual regexes
        # therefore the pattern below does not match.
        # TODO: Find a equivalent pattern.
        # return { not_yet_implemented => 'need to find a equivalent pattern' };

        eval "use re::engine::Lua"; ## no critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }

        my $result;
        #my $reg      = qr/$re/; # using that $reg later segfaults, unfortunately that makes
        my $t = timeit $count, sub { $result = $string =~ /$re/ };
        return {
                Benchmark             => $t,
                goal                  => $goal,
                count                 => $count,
                result                => $result,
                # string                => $string,
                # re                    => $re,
                used_qr_or_precompile => 0,
               };
}

sub PCRE
{
        my ($options) = @_;

        eval "use re::engine::PCRE"; ## no critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }

        my $result;
        my $reg = qr/$re/o;
        my $t = timeit $count, sub { $result = $string =~ $reg };
        return {
                Benchmark => $t,
                goal      => $goal,
                count     => $count,
                result    => $result,
                # string    => $string,
                # re        => $re_local,
                used_qr_or_precompile => 1,
               };
}

sub RE2
{
        my ($options) = @_;

        eval "use re::engine::RE2"; ## no critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }

        my $result;
        my $reg = qr/$re/o;
        my $t = timeit $count, sub { $result = $string =~ $reg };
        return {
                Benchmark => $t,
                goal      => $goal,
                count     => $count,
                result    => $result,
                # string    => $string,
                # re        => $re_local,
                used_qr_or_precompile => 1,
               };
}

sub Plan9
{
        my ($options) = @_;

        eval "use re::engine::Plan9"; ## no critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }

        my $result;
        my $reg = qr/$re/o;
        my $t = timeit $count, sub { $result = $string =~ $reg };
        return {
                Benchmark => $t,
                goal      => $goal,
                count     => $count,
                result    => $result,
                # string    => $string,
                # re        => $re_local,
                used_qr_or_precompile => 1,
               };
}

sub Oniguruma
{
        my ($options) = @_;

        eval "use re::engine::Oniguruma"; ## no critic
        if ($@) {
                print STDERR "# ".$@ if $options->{verbose} > 2;
                return { failed => "use failed" };
        }

        my $result;
        my $reg = qr/$re/o;
        my $t = timeit $count, sub { $result = $string =~ $reg };
        return {
                Benchmark             => $t,
                goal                  => $goal,
                count                 => $count,
                result                => $result,
                # string                => $string,
                # re                    => $re,
                used_qr_or_precompile => 1,
               };
}

sub regexes
{
        my ($options) = @_;

        # http://swtch.com/~rsc/regexp/regexp1.html

        my %results = ();

        no strict "refs"; ## no critic
        for my $subtest (qw( native POSIX Lua PCRE RE2 Oniguruma Plan9 )) {
                print STDERR "#  - $subtest...\n" if $options->{verbose} > 2;
                $results{$subtest} = $subtest->($options);
        }
        # ----------------------------------------------------

        return \%results;
}

sub main
{
        my ($options) = @_;

        $goal   = $options->{fastmode} ? 22 : 29; # probably 28 or more
        $count  = $options->{fastmode} ? 1 : 5;
        $n      = $goal;
        $re     = ("a?" x $n) . ("a" x $n);
        $string = "a" x $n;

        return regexes($options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::RxCmp - benchmark plugin - RxCmp - Compare different Regex engines

=head1 ABOUT

Perl 5.10 allows to plug in other Regular expression engines. So we
compare different Regexes engines with pathological regular
expressions. Inspired by and examples taken from
L<http://swtch.com/~rsc/regexp/regexp1.html>.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
