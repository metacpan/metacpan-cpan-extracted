use strict;
use Test::More;
use Data::Password::passwdqc;
use POSIX ();

my @min              = (POSIX::INT_MAX, 24, 11, 8, 7);
my $max              = 40;
my $passphrase_words = 3;
my $match_length     = 4;
my $similar_deny     = 1;
my $random_bits      = 47;

my @expected_params = (@min, $max, $passphrase_words, $match_length, $similar_deny, $random_bits);
my $packed_params = pack 'i*', @expected_params;
my @got_params = Data::Password::passwdqc::_test_params($packed_params);
is_deeply(\@got_params, \@expected_params, 'packed integers works');

my $int_max = Data::Password::passwdqc::_test_int_max();
is($int_max, POSIX::INT_MAX, 'of course POSIX INT_MAX is equal to C INT_MAX');

done_testing;
