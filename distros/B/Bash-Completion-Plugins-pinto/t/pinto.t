#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;
use Bash::Completion::Request;
use Bash::Completion::Plugins::pinto;
use Data::Dumper;
use Test::Deep "cmp_deeply";

sub complete {
        my ($line) = @_;

        local %ENV;

        $ENV{'COMP_LINE'} = $line;
        $ENV{'COMP_POINT'} = length($line);

        my $r = Bash::Completion::Request->new();
        my $c = Bash::Completion::Plugins::pinto->new();

        $c->complete($r);
        #diag Dumper($r);

        return [sort $r->candidates];
}

my %spec = (
            "pinto " => [qw(--help --nocolor --quiet --root --verbose -h -q -r -v add commands copy delete edit help index init install list manual merge new nop pin props pull stacks statistics unpin verify version)],

            "pinto -r PINTO m" => [qw(manual merge)],
            "pinto -r PINTO m" => [qw(manual merge)],
            "pinto --root PINTO m" => [qw(manual merge)],
            "pinto --root PINTO m" => [qw(manual merge)],

            "pinto -r PINTO ma" => [qw(manual)],
            "pinto -rPINTO ma" => [qw(manual)],
            "pinto --root=PINTO ma" => [qw(manual)],
            "pinto --root PINTO ma" => [qw(manual)],

            "pinto m" => [qw(manual merge)],
            "pinto s" => [qw(stacks statistics)],
            "pinto ma" => [qw(manual)],
            "pinto man" => [qw(manual)],
            "pinto manu" => [qw(manual)],
           );

foreach my $line (sort keys %spec) {
        my $expect = $spec{$line};
        my $result = complete($line);
        cmp_deeply($result, $expect, "$line => [".join(" ", @$result)."]");
}

done_testing;
