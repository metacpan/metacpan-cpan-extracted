#!perl
use strict;
use inc::Module::Install;

if (eval { require DateTime::Util::Calc } && $DateTime::Util::Calc::VERSION < 0.12) {
    print "WARNING:\n",
        "    Because of some incompatible changes, this version of\n",
        "    DateTime::Util::Calc may possibly break other modules that depend on\n",
        "    it, such as DateTime::Calendar::Chinese\n",
        "\n",
        "Proceed ? [n] "
    ;
    my $y_n = <STDIN>;
    chomp($y_n);
    exit 1 if $y_n !~ /^y(?:es)?$/i;
}
    

name("DateTime-Util-Calc");
license("perl");
perl_version("5.6.1");
all_from("lib/DateTime/Util/Calc.pm");

requires "DateTime";
requires "Math::BigInt";
requires "Math::BigFloat";
requires "Math::Trig";
build_requires("Test::More");

features(
    'Fast BigInt Support (FastCalc)' => [
        -default => 0,
        recommends('Math::BigInt::FastCalc')
    ],
    'Fast BigInt Support (GMP)' => [
        -default => 0,
        recommends('Math::BigInt::GMP')
    ],
    'Fast BigInt Support (Pari)' => [
        -default => 0,
        recommends('Math::BigInt::Pari')
    ],
);

auto_install;
WriteAll;

1;
