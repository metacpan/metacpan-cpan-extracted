package Data::RandomKeep_T;

=head1 NAME

    Data::RandomKeep_T - Test the Data::RandomKeep module.

=head1 SYNOPSIS

        # See Test::Usage for details.
    perl -w -MData::RandomKeep_T -e 'test(a => "*")'

=cut

# --------------------------------------------------------------------
use strict;
use Test::Usage;
use Data::RandomKeep;

# --------------------------------------------------------------------
example('a1', sub {
    my $keeper = Data::RandomKeep->new();
    ok(
        $keeper,
        "Expected constructor to succeed.",
        "But it didn't."
    );
    my $exp_nb_kept = 0;
    my $got_nb_kept = @{$keeper->kept()};
    ok(
        $got_nb_kept == $exp_nb_kept,
        "Expected '$exp_nb_kept' kept items immediately after construction.",
        "But got '$got_nb_kept'."
    );
    my $nb_to_offer = 100;
    $keeper->offer($_) for 1 .. $nb_to_offer;
    $exp_nb_kept = 1;
    $got_nb_kept = @{$keeper->kept()};
    ok(
        $got_nb_kept == $exp_nb_kept,
        "Expected '$exp_nb_kept' kept items after proposing $nb_to_offer.",
        "But got '$got_nb_kept'."
    );
});

# --------------------------------------------------------------------
example('a2', sub {
    my $nb_to_keep = 10;
    my $keeper = Data::RandomKeep->new($nb_to_keep)
      or die 'Constructor failed';
    my $nb_to_offer = 4;
    $keeper->offer($_) for 1 .. $nb_to_offer;
    my $exp_nb_kept = 4;
    my $got_nb_kept = @{$keeper->kept()};
    ok(
        $got_nb_kept == $exp_nb_kept,
        "Expected '$exp_nb_kept' kept items after proposing $nb_to_offer.",
        "But got '$got_nb_kept'."
    );
    $nb_to_offer = 20;
    $keeper->offer($_) for 1 .. $nb_to_offer;
    $exp_nb_kept = $nb_to_keep;
    my $kept_ref = $keeper->kept();
    $got_nb_kept = @$kept_ref;
    ok(
        $got_nb_kept == $exp_nb_kept,
        "Expected '$exp_nb_kept' kept items after proposing $nb_to_offer.",
        "But got '$got_nb_kept'."
    );
});

# --------------------------------------------------------------------
example('a3', sub {
    my $nb_to_keep = 10;
    my $keeper = Data::RandomKeep->new($nb_to_keep)
      or die 'Constructor failed';
    my $nb_to_offer = $nb_to_keep;
    $keeper->offer($_) for 1 .. $nb_to_offer;
    my $exp_kept = join ' ', 1 .. $nb_to_offer;
    my $got_kept = join ' ', @{$keeper->kept()};
    ok(
        $got_kept eq $exp_kept,
        "Expected to have kept '$exp_kept'.",
        "But got '$got_kept'."
    );
});

# --------------------------------------------------------------------
example('a4', sub {
        # Just generate
    my $nb_to_keep = 3;
    my $nb_to_offer = 10;
    my $nb_runs = 10;
    for my $run (1 .. $nb_runs) {
        my $keeper = Data::RandomKeep->new($nb_to_keep)
          or die 'Constructor failed';
        $keeper->offer(1 .. $nb_to_offer);
        ok_labeled($run,
            do {
                my $succeeded = 1;  # So far.
                $succeeded = 0 unless @{$keeper->kept()} == $nb_to_keep;
                my $low_so_far = 0;
                for my $kept (@{$keeper->kept()}) {
                    $succeeded = 0 unless $kept > $low_so_far
                      && $kept <= $nb_to_offer;
                }
                $succeeded;
            },
            "Expected $nb_to_keep different, increasing, kept results, "
              . "between 1 and $nb_to_offer. Got: "
              . join(', ', @{$keeper->kept()}),
            'Failed.'
        );
    }
});

# --------------------------------------------------------------------
1;

