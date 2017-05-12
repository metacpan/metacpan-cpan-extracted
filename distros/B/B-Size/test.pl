BEGIN { 
    $ENV{PERL_DL_NONLAZY} = '0' if $] < 5.005_58; #Perl_byterun problem
}

use strict;
use Test;

use B::Size ();

my @subs;

{
    package B::Sizeof;
    for (keys %B::Sizeof::) {
	next unless defined &$_;
	push @subs, "B::Sizeof::$_";
    }
}

my $tests = @subs;

plan tests => $tests;

for (@subs) {
    ok eval "&$_";
}
