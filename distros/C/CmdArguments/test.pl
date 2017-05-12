use strict;
use Test;

BEGIN {
    plan tests => 5;
    @ARGV = qw(-arg1 23 -arg2 -arg3 2 4 3 2 5 -arg4 2 4 3 2 4);
}

use CmdArguments;

ok(1);

my $var1 = 10;          # initialize variable
my $var2 = 0;           # with default values.
my @var3 = ( 1, 2, 3);  # well, if you like to.
my @var4;               # but, not necessary

my $parse_ref = [
                 [ "arg1", \$var1 ], # argTypeScalar is assumed
                 [ "arg2", \$var2,
                   {TYPE => argTypeSwitch}], # explicit argTypeSwitch
                 [ "arg3", \@var3 ], # argTypeArray assumed
                 [ "arg4", \@var4,
                   {UNIQUE => 1}], # argTypeArray assumed
                ];

CmdArguments::parse(@ARGV, $parse_ref);

ok($var1, 23);
ok($var2, 1);
ok(scalar(@var3), 8);
ok(scalar(@var4), 3);
