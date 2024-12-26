# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile

requires 'Carp' => 0;
requires 'Scalar::Util' => 0;

on 'build' => sub {
    requires 'ExtUtils::MakeMaker' => 6.64;
};

on 'test' => sub {
    requires 'Test::More', '0.72';
    requires 'Test::Exception', 0;
};

# vi:et:sw=4 ts=4 ft=perl
