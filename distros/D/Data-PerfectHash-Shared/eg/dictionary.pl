#!/usr/bin/env perl
# String set: build an exact set of byte-string keys with the builder API,
# query it, and iterate the stored keys back out of the dumped image.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/words.phs";

my @words = qw(apple banana cherry date elderberry fig grape);
my $b = Data::PerfectHash::Shared->new_builder(type => 'str');
$b->add_many(\@words);
$b->add('kiwi');
$b->build($path);            # secure 0600 file by default

my $set = Data::PerfectHash::Shared->load($path);
printf "loaded %d words (type=%s)\n", $set->count, $set->type;
for my $w (qw(cherry kiwi mango grape)) {
    printf "  has(%-10s) = %s\n", $w, $set->has($w) ? 'yes' : 'no';
}

# Full keys are stored, so the set can be iterated straight from the image.
my @back;
$set->each_key(sub { push @back, $_[0] });
printf "each_key -> %s\n", join(', ', sort @back);
