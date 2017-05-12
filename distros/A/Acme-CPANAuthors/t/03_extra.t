use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Acme::CPANAuthors;

BEGIN {
  eval {require Gravatar::URL; 1} or
    plan skip_all => "this test requires Gravatar::URL";
}

plan tests => 1;

local $ENV{ACME_CPANAUTHORS_HOME} = 't/data';

my $authors = Acme::CPANAuthors->new('TestExtra');

my $avatar_url = $authors->avatar_url('AADLER');
ok $avatar_url;
