use strict;
use warnings;
use Test::More;
use Data::SortedSet::Shared;

# anonymous
my $s = Data::SortedSet::Shared->new(undef, 1000);
isa_ok $s, 'Data::SortedSet::Shared';
is $s->count, 0, 'fresh anon count == 0';
is $s->max_entries, 1000, 'max_entries';
ok !defined($s->path), 'anonymous path is undef';
$s->clear;
is $s->count, 0, 'clear keeps an empty set empty';

# memfd round-trip
my $m  = Data::SortedSet::Shared->new_memfd('ss', 50);
my $fd = $m->memfd;
cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
my $m2 = Data::SortedSet::Shared->new_from_fd($fd);
is $m2->max_entries, 50, 'reopened memfd max_entries';
is $m2->count, 0, 'reopened memfd count';

# file-backed reopen: stored header wins
my $path = "/tmp/ss-basic-$$.bin";
unlink $path;
{
    my $w = Data::SortedSet::Shared->new($path, 100);
    is $w->path, $path, 'file-backed path';
    $w->sync;
}
{
    my $r = Data::SortedSet::Shared->new($path, 999);   # caller arg ignored on reopen
    is $r->max_entries, 100, 'reopen: stored max_entries wins';
    is $r->count, 0, 'reopen count == 0';
}

# validation
ok !eval { Data::SortedSet::Shared->new(undef, 0); 1 }, 'max_entries 0 rejected';
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::SortedSet::Shared->new($path, 100); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# eventfd
my $e = Data::SortedSet::Shared->new(undef, 10);
my $efd = $e->eventfd;
cmp_ok $efd, '>=', 0, 'eventfd created';
ok $e->notify, 'notify writes';
is $e->fileno, $efd, 'fileno returns the eventfd descriptor';
is $e->eventfd_consume, 1, 'eventfd_consume reads the count';
my $ne = Data::SortedSet::Shared->new(undef, 10);
is $ne->fileno, -1, 'fileno is -1 before any eventfd is created';

# class-method unlink
my $cu = "/tmp/ss-classunlink-$$.bin";
unlink $cu;
{ my $w = Data::SortedSet::Shared->new($cu, 10); $w->add(1, 1); $w->sync; }
ok -e $cu, 'backing file exists';
Data::SortedSet::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# DESTROY nulls the handle: use-after-destroy croaks cleanly instead of a use-after-free,
# and the implicit second DESTROY at scope exit is a safe no-op.
{
    my $z = Data::SortedSet::Shared->new(undef, 10);
    $z->add(1, 1.0);
    $z->DESTROY;
    eval { $z->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
}
pass 'double DESTROY did not crash';

done_testing;
