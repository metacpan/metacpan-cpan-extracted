use strict;
use warnings;
use utf8;
use Encode;
use Test::More;
use Test::Requires 'Capture::Tiny';
use Acme::Songmu;

my $songmu = Acme::Songmu->instance;
my ($stdout) = Capture::Tiny::capture { $songmu->gmu };
is $stdout, encode_utf8("ぐむー\n");

done_testing;
