use strict;
use warnings;
use Test::More;

SKIP: {
  skip 'missing environment variables: reddit_username, reddit_password and reddit_subreddit', 5
    unless $ENV{reddit_username} && $ENV{reddit_password} && $ENV{reddit_subreddit};

  use_ok 'Cache::Reddit';
  my $data = { some => 'data' };
  ok my $id = set($data), 'set some data';
  sleep(1); # weird delay in saving data before retrieving it
  ok my $new_data = get($id), 'Get data back';
  is_deeply $new_data, $data, 'check set data matches';
  ok remove($id), 'remove the cache entry';
};
done_testing;
