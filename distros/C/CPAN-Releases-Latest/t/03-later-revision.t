#!perl
use strict;
use warnings;
use Test::More 0.88 tests => 3;
use CPAN::Releases::Latest;

my $latest = CPAN::Releases::Latest->new(
                path => 't/data/03-later-revision.txt'
             );

ok(defined($latest), 'instantiate CPAN::Releases::Latest');

my $iterator;
my $release;

eval { $iterator = $latest->release_iterator };

ok(defined($iterator),
   "Create a release iterator");

eval { $release = $iterator->next_release };

ok(defined($@) && $@ =~ m!the passed file has a later format revision!,
   "trying to load a later format revision should croak");

