use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::PerfectHash::Shared;

srand 71829;
my $dir = tempdir(CLEANUP => 1);
my @lengths = (0, 1, 7, 16, 17, 31, 32, 33, 64, 128, 241, 1024);
my $max = ~0 >> 1;

sub check_set {
    my ($set, $expected, $type) = @_;
    is $set->count, scalar(keys %$expected), 'distinct count';
    my @missing = grep { !$set->has($_) } keys %$expected;
    is_deeply \@missing, [], 'every member is present';
    my @seen;
    $set->each_key(sub { push @seen, $_[0] });
    is_deeply [sort @seen], [sort keys %$expected], 'each key round-trips exactly once';
    my @miss = grep { !exists $expected->{$_} }
        map { $type eq 'int' ? $_ : "absent:$_" } -20 .. 20;
    is_deeply [grep { $set->has($_) } @miss], [], 'non-members stay absent';
}

for my $type (qw(int str)) {
    for my $n (0, 1, 6, 7, 63, 1000) {
        subtest "$type/$n" => sub {
            my @keys = map {
                $type eq 'int' ? int(rand(2_000_000)) - 1_000_000
                    : pack('C*', map { int rand 256 } 1 .. $lengths[$_ % @lengths]);
            } 1 .. $n;
            if ($n >= 6 && $type eq 'int') {
                @keys[0 .. 5] = (-$max - 1, $max, -1, 0, 1, -42);
            }
            push @keys, '' if $n && $type eq 'str';
            push @keys, @keys;
            my %expected = map { $_ => 1 } @keys;
            my $b = Data::PerfectHash::Shared->new_builder(type => $type);
            my @input = @keys;
            $b->add_many([splice @input, 0, int(@input / 2)]);
            $b->add($_) for @input;
            is $b->count, scalar(@keys), 'builder counts all additions';
            my $path = "$dir/$type-$n.phs";
            for (1 .. 2) {
                $b->build($path);
                is $b->count, scalar(@keys), 'build preserves the addition count';
                check_set(Data::PerfectHash::Shared->load($path), \%expected, $type);
            }
            my $old = Data::PerfectHash::Shared->load($path);
            my $extra = $type eq 'int' ? 3_000_001 : "new\0key";
            $b->add($extra);
            $b->build($path);
            is $b->count, @keys + 1, 'builder remains usable after rebuilds';
            check_set($old, \%expected, $type);
            $expected{$extra} = 1;
            check_set(Data::PerfectHash::Shared->load($path), \%expected, $type);
        };
    }
}
done_testing;
