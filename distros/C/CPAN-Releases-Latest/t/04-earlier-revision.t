#!perl
use strict;
use warnings;
use Test::More 0.88 tests => 3;
use CPAN::Releases::Latest;

my $latest = CPAN::Releases::Latest->new(
                path => 't/data/04-earlier-revision.txt'
             );

ok(defined($latest), 'instantiate CPAN::Releases::Latest');

my $iterator;
my $release;

eval { $iterator = $latest->release_iterator };

ok(defined($iterator),
   "Create a release iterator");

eval { $release = $iterator->next_release };

ok(defined($@) && $@ =~ m!the passed file .*? is from an older version!,
   "trying to load an earlier format revision should croak");

