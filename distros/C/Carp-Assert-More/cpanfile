# Validate with cpanfile-dump
# https://metacpan.org/release/Module-CPANfile

requires 'Carp' => 0;
requires 'Scalar::Util' => 0;

on 'test' => sub {
    requires 'Test::More', '0.94';  # So we can run subtests on v5.10
    requires 'Test::Exception', 0;
};

# vi:et:sw=4 ts=4 ft=perl
