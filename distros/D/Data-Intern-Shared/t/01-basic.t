use strict;
use warnings;
use Test::More;
use Data::Intern::Shared;

# anonymous
my $in = Data::Intern::Shared->new(undef, 1000);
isa_ok $in, 'Data::Intern::Shared';
is $in->count, 0, 'fresh count == 0';
is $in->arena_used, 0, 'fresh arena_used == 0';
is $in->max_strings, 1000, 'max_strings';
cmp_ok $in->arena_bytes, '>=', 1000, 'default arena sized from max_strings';
ok !defined($in->path), 'anonymous path is undef';
is $in->memfd, -1, 'anonymous memfd is -1';
$in->clear;
is $in->count, 0, 'clear keeps an empty table empty';

# explicit arena size
my $in2 = Data::Intern::Shared->new(undef, 100, 4096);
is $in2->arena_bytes, 4096, 'explicit arena_bytes honored';

# memfd round-trip
my $m  = Data::Intern::Shared->new_memfd('intern', 50);
my $fd = $m->memfd;
cmp_ok $fd, '>=', 0, 'memfd fd >= 0';
my $mu = Data::Intern::Shared->new_memfd(undef, 10);
cmp_ok $mu->memfd, '>=', 0, 'new_memfd with undef name uses a default label';
my $m2 = Data::Intern::Shared->new_from_fd($fd);
cmp_ok $m2->memfd, '>=', 0, 'new_from_fd handle exposes its (dup) backing fd';
ok !defined($m->path),  'memfd path is undef';
ok !defined($m2->path), 'fd-reopened path is undef';
is $m2->max_strings, 50, 'reopened memfd max_strings';
is $m2->count, 0, 'reopened memfd count';

# file-backed reopen: stored header wins
my $path = "/tmp/intern-basic-$$.bin";
unlink $path;
{
    my $w = Data::Intern::Shared->new($path, 200, 8192);
    is $w->path, $path, 'file-backed path';
    $w->sync;
}
{
    my $r = Data::Intern::Shared->new($path, 999, 1);   # caller args ignored on reopen
    is $r->max_strings, 200, 'reopen: stored max_strings wins';
    is $r->arena_bytes, 8192, 'reopen: stored arena_bytes wins';
    is $r->count, 0, 'reopen count == 0';
}

# validation
ok !eval { Data::Intern::Shared->new(undef, 0); 1 }, 'max_strings 0 rejected';
{ open my $fh, '>', $path or die $!; print $fh "junk"; close $fh; }
ok !eval { Data::Intern::Shared->new($path, 200); 1 }, 'too-small/corrupt file rejected';
unlink $path;

# class-method unlink
my $cu = "/tmp/intern-cu-$$.bin";
unlink $cu;
{ my $w = Data::Intern::Shared->new($cu, 10); $w->sync; }
ok -e $cu, 'backing file exists';
Data::Intern::Shared->unlink($cu);
ok !-e $cu, 'class-method unlink removed the file';

# instance-method unlink
my $iu = "/tmp/intern-iu-$$.bin";
unlink $iu;
{
    my $w = Data::Intern::Shared->new($iu, 10); $w->sync;
    ok -e $iu, 'instance unlink: backing file exists';
    $w->unlink;
    ok !-e $iu, 'instance-method unlink removed the file';
}

# DESTROY nulls the handle: use-after-destroy croaks cleanly instead of a use-after-free,
# and the implicit second DESTROY at scope exit is a safe no-op.
{
    my $i = Data::Intern::Shared->new(undef, 10);
    $i->intern("x");
    $i->DESTROY;
    eval { $i->count };
    like $@, qr/destroyed/, 'use after DESTROY croaks (not a use-after-free)';
}
pass 'double DESTROY did not crash';

done_testing;
