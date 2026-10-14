#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;

# The SYNOPSIS of Context::Vars, taken from the POD itself and run in a child
# perl, so that the example in the documentation cannot drift from what the
# module does.

my $pm = File::Spec->catfile('lib', 'Context', 'Vars.pm');
plan skip_all => "run from the dist root: no $pm" unless -f $pm;

open my $fh, '<', $pm or die "$pm: $!";
my $pod = do { local $/; <$fh> };
close $fh;
my ($synopsis) = $pod =~ /^=head1 SYNOPSIS\n\n(.*?)^=head1/ms;
ok(defined $synopsis, 'the SYNOPSIS is found');
(my $code = $synopsis) =~ s/^    //mg;

my @inc = map { "-I$_" } grep { !ref } @INC;
my $pid = open(my $out, '-|', $^X, @inc, '-e', $code) // die "cannot run $^X: $!";
my $got = do { local $/; <$out> };
close $out;
is($?, 0, 'it runs without dying');
is($got, "twoonerequest 42\n", 'and prints what its comments say: two, then one, then request 42');

done_testing;
