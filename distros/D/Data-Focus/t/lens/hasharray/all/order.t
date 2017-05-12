use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::All;

sub lens {
    my ($immutable) = @_;
    Data::Focus::Lens::HashArray::All->new(immutable => $immutable);
}

note("-- order of focal points");

{
    my $target = [0,1,2,3];
    is_deeply [focus($target)->list(lens())], [0 .. 3], "array: forward order";
}

{
    my $target = {
        a => 0,
        b => 1,
        c => 2,
        d => 3,
    };
    my @got = focus($target)->list(lens());
    my %got_count;
    $got_count{$_}++ foreach @got;
    is_deeply \%got_count, {0 => 1, 1 => 1, 2 => 1, 3 => 1}, "hash: order is not defined";
}

done_testing;
