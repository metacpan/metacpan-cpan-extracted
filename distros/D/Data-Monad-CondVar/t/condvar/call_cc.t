use strict;
use warnings;
use Data::Monad::CondVar;
use AnyEvent;
use Test::More;

my $cv213 = do {
    my $cv = AE::cv;
    my $t; $t = AE::timer 0, 0, sub {
        $cv->send(2, 1, 3);
        undef $t;
    };
    $cv;
};

sub create_cv($) {
    my $should_skip = shift;
    my $cv1 = $cv213->flat_map(sub {
        my @v = @_;

        call_cc {
            my $skip = shift;

            my $cv213 = cv_unit(@v);
            my $cv426 = $cv213->flat_map(sub {
                cv_unit(map { $_ * 2 } @_);
            });
            my $cv_skipped = $cv426->flat_map(sub {
                $should_skip ? $skip->(@_) : cv_unit(@_)
            });

            return $cv_skipped->flat_map(sub {
                cv_unit(map { $_ * 2 } @_);
            });
        };
    });
    return $cv1->flat_map(sub {
        cv_unit(map { $_ * 3 } @_);
    });
}


is_deeply [(create_cv 1)->recv], [12, 6, 18];
is_deeply [(create_cv 0)->recv], [24, 12, 36];

done_testing;
