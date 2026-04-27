use strict;
use warnings;
use Test::More;

use Data::Log::Shared;

# Empty string rejected
{
    my $l = Data::Log::Shared->new_memfd("e1", 1024);
    eval { $l->append("") };
    ok $@, "append empty string rejected";
    is $l->entry_count, 0, "no entries on reject";
}

# Binary data with NULs
{
    my $l = Data::Log::Shared->new_memfd("e2", 1024);
    my $binary = "\x00\x01\x02\xff\x00\x7f";
    $l->append($binary);
    my @got;
    $l->each_entry(sub { push @got, $_[0] });
    is $got[0], $binary, "binary data preserved";
    is length($got[0]), 6, "length includes NULs";
}

# Fill exactly to capacity
{
    my $l = Data::Log::Shared->new_memfd("e3", 256);
    my $r;
    do { $r = $l->append("x" x 10) } while (defined $r && $r >= 0);
    ok $l->entry_count > 0, "filled log";
}

# Truncate API
{
    my $l = Data::Log::Shared->new_memfd("e4", 4096);
    my $off1 = $l->append("first");
    my $off2 = $l->append("second");
    $l->truncate($off2);
    my @rem;
    $l->each_entry(sub { push @rem, $_[0] });
    is_deeply \@rem, ["second"], "truncate hides pre-truncation entries";
}

# Overflow (too big entry)
{
    my $l = Data::Log::Shared->new_memfd("e5", 64);
    my $r = eval { $l->append("x" x 1000) };
    ok !$r || $r == -1 || $@, "oversized entry rejected";
}

done_testing;
