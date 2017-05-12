use strict;
use warnings;
use Test::More;
use Bio::Cigar;

# Valid/invalid CIGAR strings
{
    my @valid = (
        "1M",
        "2H1S1M2S",
        "1S1M1S",
        "1H1H",
        "1H2S1H",
        "1M2S",
    );
    my @invalid = (
        [ string => "1M" ],
        "bogus",
        "1M2H1M",
        "1M2S1M",
    );
    for (@valid) {
        $_ = [$_] unless ref $_;
        my $cigar = Bio::Cigar->new(@$_);
        ok $cigar, "->new(" . join(" => ", map { explain($_) } @$_) . ")";
    }
    for (@invalid) {
        $_ = [$_] unless ref $_;
        my $cigar = eval { Bio::Cigar->new(@$_) };
        ok $@, "Got an exception";
        ok !$cigar, "->new(" . join(" => ", map { explain($_) } @$_) . ") failed";
    }
}

# Optional length when 1
{
    my $cigar = Bio::Cigar->new("2MD");
    is $cigar->string, "2MD";
    is $cigar->query_length, 2;
    is $cigar->reference_length, 3;
    is_deeply $cigar->ops, [ [2, "M"], [1, "D"], ];
}

{
    #      1234 5678
    # REF: ATCG-ATCG
    # SEQ: AT-GAATCG
    #      12 345678
    my $cigar = Bio::Cigar->new("2M1D1M1I4M");
    is $cigar->string, "2M1D1M1I4M", "string matches";
    is $cigar->query_length, 8, "seq len = 8";
    is $cigar->reference_length, 8, "ref len = 8";
    is_deeply $cigar->ops, [ [2, "M"], [1, "D"], [1, "M"], [1, "I"], [4, "M"] ], "parsed ops match";

    # rpos_to_qpos, op_at_rpos
    my %positions = (
        1 => [1, "M"],      # start
        2 => [2, "M"],      # simple
        3 => [undef, "D"],  # deletion, non-existent qpos
        4 => [3, "M"],      # after deletion
        5 => [5, "M"],      # after insertion (note qpos jump from 3 -> 5 for rpos 4 -> 5)
        7 => [7, "M"],      # in match, testing overshoot correction
        8 => [8, "M"],      # end
    );
    for (sort keys %positions) {
        is          $cigar->rpos_to_qpos($_),   $positions{$_}->[0], "->rpos_to_qpos($_) in scalar context";
        is_deeply [ $cigar->rpos_to_qpos($_) ], $positions{$_},      "->rpos_to_qpos($_) in list context";
        is $cigar->op_at_rpos($_), $positions{$_}->[1], "->op_at_rpos($_)";
    }

    ok !eval { $cigar->rpos_to_qpos(9) }, "no qpos for rpos > rlen";
    like $@, qr/rpos = 9 is < 1 or > reference_length \(8\)/, "exception wording";
    ok !eval { $cigar->rpos_to_qpos(0) }, "no qpos for rpos < 1";
    like $@, qr/rpos = 0 is < 1 or > reference_length \(8\)/, "exception wording";

    # qpos_to_rpos, op_at_qpos
    %positions = (
        1 => [1, "M"],      # start
        2 => [2, "M"],      # simple
        3 => [4, "M"],      # after deletion
        4 => [undef, "I"],  # insertion!
        6 => [6, "M"],      # back to match
        8 => [8, "M"],      # end
    );
    for (sort keys %positions) {
        is          $cigar->qpos_to_rpos($_),   $positions{$_}->[0], "->qpos_to_rpos($_) in scalar context";
        is_deeply [ $cigar->qpos_to_rpos($_) ], $positions{$_},      "->qpos_to_rpos($_) in list context";
        is $cigar->op_at_qpos($_), $positions{$_}->[1], "->op_at_qpos($_)";
    }

    ok !eval { $cigar->qpos_to_rpos(9) }, "no rpos for qpos > qlen";
    like $@, qr/qpos = 9 is < 1 or > query_length \(8\)/, "exception wording";
    ok !eval { $cigar->qpos_to_rpos(0) }, "no rpos for qpos < 1";
    like $@, qr/qpos = 0 is < 1 or > query_length \(8\)/, "exception wording";
}

{
    #        1234  5678
    # REF:   ATCG--ATCG
    # SEQ: AAATCGATATCG
    #      123456789012
    my $cigar = Bio::Cigar->new("2S4M2I4M3H");
    is $cigar->string, "2S4M2I4M3H", "string matches";
    is $cigar->query_length, 12, "seq len = 9";
    is $cigar->reference_length, 8, "ref len = 8";
    is_deeply $cigar->ops, [ [2, "S"], [4, "M"], [2, "I"], [4, "M"], [3, "H"] ], "parsed ops match";

    # rpos_to_qpos, op_at_rpos
    my %positions = (
        1 => [3, "M"],      # start
        3 => [5, "M"],      # simple
        5 => [9, "M"],      # after insertion
        7 => [11, "M"],     # overshoot correction
        8 => [12, "M"],     # end
    );
    for (sort keys %positions) {
        is          $cigar->rpos_to_qpos($_),   $positions{$_}->[0], "->rpos_to_qpos($_) in scalar context";
        is_deeply [ $cigar->rpos_to_qpos($_) ], $positions{$_},      "->rpos_to_qpos($_) in list context";
        is $cigar->op_at_rpos($_), $positions{$_}->[1], "->op_at_rpos($_)";
    }

    # qpos_to_rpos, op_at_qpos
    %positions = (
         1 => [undef, "S"], # clipping at start
         3 => [1, "M"],     # ref start
         7 => [undef, "I"], # insertion!
         8 => [undef, "I"],
         9 => [5, "M"],     # after insertion
        12 => [8, "M"],     # end
    );
    for (sort keys %positions) {
        is          $cigar->qpos_to_rpos($_),   $positions{$_}->[0], "->qpos_to_rpos($_) in scalar context";
        is_deeply [ $cigar->qpos_to_rpos($_) ], $positions{$_},      "->qpos_to_rpos($_) in list context";
        is $cigar->op_at_qpos($_), $positions{$_}->[1], "->op_at_qpos($_)";
    }

    ok !eval { $cigar->qpos_to_rpos(13) }, "no rpos for qpos > qlen";
    like $@, qr/qpos = 13 is < 1 or > query_length \(12\)/, "exception wording";
}

done_testing;
