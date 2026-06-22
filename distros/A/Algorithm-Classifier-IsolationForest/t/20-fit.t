#!perl
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::IsolationForest;

sub exception (&) {
    my $code = shift;
    my $ok   = eval { $code->(); 1 };
    return $ok ? undef : ( $@ // 'died' );
}

my $CLASS = 'Algorithm::Classifier::IsolationForest';

# A small, valid training set used throughout.
my @data = map { [ $_, $_ + 1 ] } 1 .. 30;

subtest 'fit() input validation' => sub {
    my $f = $CLASS->new( n_trees => 5 );

    like(
        exception { $f->fit() },
        qr/non-empty arrayref/,
        'fit() with no data croaks'
    );
    like(
        exception { $f->fit('not a ref') },
        qr/non-empty arrayref/,
        'fit() with a non-arrayref croaks'
    );
    like(
        exception { $f->fit( [] ) },
        qr/non-empty arrayref/,
        'fit() with an empty arrayref croaks'
    );
    like(
        exception { $f->fit( [ 1, 2, 3 ] ) },
        qr/each sample must be an arrayref/,
        'fit() croaks when samples are not arrayrefs'
    );
    like(
        exception { $f->fit( [ [] ] ) },
        qr/each sample must be an arrayref/,
        'fit() croaks when the first sample has no features'
    );
};

subtest 'fit() succeeds and is chainable' => sub {
    my $f   = $CLASS->new( n_trees => 10, sample_size => 16, seed => 1 );
    my $ret = $f->fit( \@data );
    is( $ret, $f, 'fit() returns the invocant (chainable)' );

    # The forest is now usable directly off the chain.
    my $scores = $CLASS->new( n_trees => 10, seed => 1 )->fit( \@data )
        ->score_samples( \@data );
    is( ref $scores, 'ARRAY', 'new->fit->score_samples works in one chain' );
    is( scalar @$scores, scalar @data, 'one score per sample' );
};

subtest 'fit() records training metadata' => sub {
    my $f = $CLASS->new( n_trees => 7, sample_size => 1000, seed => 2 );
    $f->fit( \@data );
    is( scalar @{ $f->{trees} }, 7, 'builds exactly n_trees trees' );
    is( $f->{n_features}, 2, 'n_features inferred from the data' );
    is( $f->{psi_used}, scalar @data,
        'sub-sample size is clamped to the data size when sample_size is larger'
    );
};

subtest 'consumers croak before fit()' => sub {
    for my $method (qw(score_samples predict path_lengths to_json)) {
        my $f = $CLASS->new;
        like(
            exception { $f->$method( \@data ) },
            qr/not fitted/i,
            "$method() croaks on an unfitted model"
        );
    }
};

done_testing;
