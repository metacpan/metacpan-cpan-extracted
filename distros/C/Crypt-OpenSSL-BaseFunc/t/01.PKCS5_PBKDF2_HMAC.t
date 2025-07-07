#!/usr/bin/perl
use utf8;
use Test::More;
use Crypt::OpenSSL::BaseFunc ;

my $pbkdf2_key = pkcs5_pbkdf2_hmac('123456', pack("H*", 'b698314b0d68bcbd'), 2048, 'sha256');
is($pbkdf2_key, pack("H*", 'F68B5386DE3A8D6335846950544D29A55AD3328DEA17685304D7822848AEC534'), 'pkcs5_pbkdf2_hmac');

my $dgst = digest('sha256', 'just for test');
is($dgst, pack("H*", '015848fe450f5636d03d33d3bb1b8640edb9fe43cad6237664a6370ab953983b'), 'digest');
my $dgst2 = digest('sha256', 'ju', 'st for test');
is($dgst2, $dgst, 'digest');

done_testing();
