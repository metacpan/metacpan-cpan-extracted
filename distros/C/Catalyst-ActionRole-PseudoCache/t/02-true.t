#!perl

use strict;
use warnings;
use autodie;

use FindBin;
use Test::More;
use Test::WWW::Mechanize::Catalyst;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

plan skip_all => 'These tests require Catalyst::Plugin::Cache'
   unless eval { require Catalyst::Plugin::Cache; 1 };


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TrueTestApp');
$mech->get_ok('/peek_cache_test', 'get test works when uncached');
$mech->get_ok('/peek_cache_key', 'get test_key works when uncached');
use Catalyst::Test 'TrueTestApp';
{
   my $empty_cache_test = get('/peek_cache_test');
   is ($empty_cache_test, '', 'test cache is empty');
   my $empty_cache_key = get('/peek_cache_key');
   is ($empty_cache_key, '', 'test cache is empty');
   is(get('/test'), 'we cached your stuff', 'request works');
   content_like('/peek_cache_test',qr{we cached your stuff},'something got cached');
   is(get('/test_key'), 'we cached your stuff with your neat key', 'keyed request works');
   content_like('/peek_cache_key',qr{we cached your stuff with your neat key},'something got cached with a custom key');
};
done_testing;
