#!perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::NoWarnings;
use CGI::Compile;

my $SHEBANG  = "#!perl -w\n";
my %VALS     = ('undef' => 0, '"bla"' => 0);
my %NUM_VALS = (0.5 => 0, 1.2 => 1, 2.7 => 3, 0 => 0, 1240 => 216);
my %TESTS;

my $gen_keys = sub {
    my @r;
    foreach my $cmd ('', 'return ', 'exit ') {
        push @r, $SHEBANG . "${cmd}$_[0];\n";
    }
    @r;
};

while (my ($k, $v) = each %VALS) {
    $TESTS{$_} = $v foreach $gen_keys->($k);
}
while (my ($k, $v) = each %NUM_VALS) {
    $TESTS{$_} = $v foreach $gen_keys->($k);
    $TESTS{$_} = $v foreach $gen_keys->(qq|"${k}bla"|);
}

while (my ($k, $v) = each %TESTS) {
    local $@;
    eval {
        is(CGI::Compile->compile(\$k)->(), $v, 'return val from CGI');
    };
    if ($@ && $@ =~ /^exited nonzero: (\d+) /) {
        is($1, $v, 'nonzero exit val from CGI');
    }
}
