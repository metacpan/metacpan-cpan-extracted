use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Log::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.log');
close $fh;

{
    my $l = Data::Log::Shared->new($path, 4096);
    $l->append("entry $_") for 1..5;
    $l->sync;
}

{
    my $l = Data::Log::Shared->new($path, 4096);
    is $l->entry_count, 5, "entry_count persisted";
    my @entries;
    $l->each_entry(sub { push @entries, $_[0] });
    is_deeply \@entries, [map "entry $_", 1..5], "entries persisted";
}

done_testing;
