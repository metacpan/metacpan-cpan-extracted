use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::IntervalTree::Shared;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/shared.it";
my $writer = Data::IntervalTree::Shared->new($path, 16);
my $peer = Data::IntervalTree::Shared->new($path, 1);
$writer->add(10, 20, 42);
$peer->add(15, 25, 43);
is_deeply [$writer->stab(16)], [{id => 42, lo => 10, hi => 20}, {id => 43, lo => 15, hi => 25}],
    'independent handles share queries and appends';
is $writer->stats->{ops}, 2, 'operation count shared between handles';
$peer->clear;
$writer->add(30, 40);
is $peer->stats->{ops}, 4, 'clear and add update the operation count';
$writer->freeze;
ok $peer->frozen, 'existing peer sees the seal';
ok !$peer->readonly, 'peer retains its original mapping mode';
is_deeply [$peer->stab(35)], [{id => 0, lo => 30, hi => 40}], 'peer queries the frozen data';
for my $method (qw(add clear build)) {
    eval { $method eq 'add' ? $peer->add(1, 2) : $peer->$method() };
    like $@, qr/frozen|read-only/, "$method on an existing peer rejects mutation after freeze";
}
is $peer->stats->{ops}, 4, 'rejected frozen mutations do not change operation count';
ok $peer->stats->{frozen}, 'stats sees the seal';

{
    my $p = "$dir/fd.it";
    { my $h = Data::IntervalTree::Shared->new($p, 4); $h->add(1, 5, 7); }
    open my $fh, '+<', $p or die $!;
    my $h = Data::IntervalTree::Shared->new_from_fd(fileno $fh);
    close $fh or die $!;
    $h->add(2, 6, 8);
    is_deeply [map { $_->{id} } $h->stab(3)], [7, 8], 'fd attach survives closing the supplied descriptor';
    my $peer = Data::IntervalTree::Shared->new($p, 1);
    is $peer->count, 2, 'fd mutations persist for path attach';
}

{
    my $h = Data::IntervalTree::Shared->new(undef, 4);
    my $min = -9223372036854775807 - 1;
    my $max = 9223372036854775807;
    my $id = 18446744073709551615;
    $h->add($min, $max, $id);
    $h->add($min, $min, 0);
    $h->add($max, $max, 1);
    is_deeply [$h->stab($min)], [{id => 0, lo => $min, hi => $min}, {id => $id, lo => $min, hi => $max}],
        'signed endpoint and unsigned id boundaries are exact and sorted';
    is_deeply [map { $_->{id} } $h->stab($max)], [$id, 1], 'upper endpoint stays inclusive';
}

{
    package ThrowingId;
    use overload '0+' => sub { die "id conversion failed\n" }, fallback => 1;
}
{
    my $h = Data::IntervalTree::Shared->new(undef, 4);
    eval { $h->add(1, 2, bless([], 'ThrowingId')) };
    like $@, qr/id conversion failed/, 'payload conversion propagates exceptions';
    is $h->count, 0, 'failed conversion leaves the index empty';
    is $h->add(1, 2), 0, 'failed conversion leaves no live-owner lock behind';
}

done_testing;
