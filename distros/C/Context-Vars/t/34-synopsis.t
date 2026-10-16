#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

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

# The code is written to a script, never passed with -e: Windows has no
# argument vector, and perl does not escape the double quotes the SYNOPSIS
# uses when it joins the arguments into one command line.
my $work = tempdir(CLEANUP => 1);
my $script = File::Spec->catfile($work, 'synopsis.pl');
my $output = File::Spec->catfile($work, 'synopsis.out');
open my $sfh, '>', $script or die "$script: $!";
print {$sfh} "BEGIN { open STDOUT, '>', q{$output} or die \$! }\n$code";
close $sfh or die "$script: $!";

my @inc = map { "-I$_" } grep { !ref } @INC;
system($^X, @inc, $script);
is($?, 0, 'it runs without dying');
my $got = '';
if (open my $in, '<', $output) {
    local $/;
    $got = <$in>;
    close $in;
}
is($got, "twoonerequest 42\n", 'and prints what its comments say: two, then one, then request 42');

done_testing;
