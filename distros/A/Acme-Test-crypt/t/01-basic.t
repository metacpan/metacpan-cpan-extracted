#!perl

use 5.010001;
use strict;
use warnings;

use Crypt::Password::Util qw(crypt_type);
use Test::More 0.98;

my @tests = (
    {type=>'CRYPT', salt=>'aa'},
    {type=>'EXT-DES', salt=>'_9G..8147'},
    {type=>'MD5-CRYPT', salt=>'$1$x$'},
    {type=>'MD5-CRYPT', note=>' (apache variant)', salt=>'$apr1$x$'},
    {type=>'SSHA256', salt=>'$5$123456789$'},
    {type=>'SSHA256', note=>'+rounds', salt=>'$5$rounds=9999$123456789$'},
    {type=>'SSHA512', salt=>'$6$12345678$'},
    {type=>'SSHA512', note=>'+rounds', salt=>'$6$rounds=9999$12345678$'},
    {type=>'BCRYPT', note=>' (2 variant)', salt=>'$2$10$1234567890123456789012$'},
    {type=>'BCRYPT', note=>' (2a variant)', salt=>'$2a$10$1234567890123456789012$'},
    {type=>'BCRYPT', note=>' (2b variant)', salt=>'$2b$10$1234567890123456789012$'},
    {type=>'BCRYPT', note=>' (2y variant)', salt=>'$2y$10$1234567890123456789012$'},
);

my @res;
my @supported_types;

for my $test (@tests) {
    my $res_crypt = crypt("foo", $test->{salt});
    my $res_type  = $res_crypt ? crypt_type($res_crypt) : undef;
    my $supported = $res_type && $res_type eq $test->{type} ? 1:0;
    push @res, {
        test => $test,
        result_crypt => $res_crypt,
        result_type => $res_type,
        supported => $supported,
    };
    push @supported_types, $test->{type} . ($test->{note} // '')
        if $supported;
}

diag explain \@res;
ok 1;

diag "Summary: supported types = ", explain \@supported_types;

done_testing;
