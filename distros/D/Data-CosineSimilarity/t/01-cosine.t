#!perl -T

use Test::More tests => 31;

use Math::Trig;

use Data::CosineSimilarity;

sub near {
    my ($value, $test) = @_;
    my $e = 0.0001;
    ok( abs( $value - $test ) < $e, "$value near $test");
}


note 'Euclidean Norm';

note 'Scalar Product';

note 'independant';
{
    my $cs = Data::CosineSimilarity->new;
    isa_ok $cs, 'Data::CosineSimilarity';

    $cs->add( a => { aaa => 3, aa => 2 } );
    $cs->add( b => { bbb => 1, bb => 4 } );

    my $r = $cs->similarity( 'a', 'b' ); 
    isa_ok $r, 'Data::CosineSimilarity::Result';

    is_deeply [ $r->labels ], [ 'a', 'b' ], 'labels';
    is $r->cosine, 0, 'cosine';
    is $r->radian, pi/2, 'radian';
    is $r->degree, 90, 'degree';
}

note 'similar';
{
    my $cs = Data::CosineSimilarity->new;
    isa_ok $cs, 'Data::CosineSimilarity';

    $cs->add( a => { aaa => 2, aa => 2 } );
    $cs->add( b => { aaa => 1, aa => 1 } );

    my $r = $cs->similarity( 'a', 'b' ); 
    isa_ok $r, 'Data::CosineSimilarity::Result';

    is_deeply [ $r->labels ], [ 'a', 'b' ], 'labels';
    is $r->cosine, 1, 'cosine';
    near( $r->radian, 0 );
    near( $r->degree, 0 );
}


note '45 degree';
{
    my $cs = Data::CosineSimilarity->new;
    isa_ok $cs, 'Data::CosineSimilarity';

    $cs->add( a => { aaa => 1, aa => 1 } );
    $cs->add( b => { aaa => 1, aa => 0 } );

    my $r = $cs->similarity( 'a', 'b' ); 
    isa_ok $r, 'Data::CosineSimilarity::Result';

    is_deeply [ $r->labels ], [ 'a', 'b' ], 'labels';
    is $r->cosine, 1/sqrt(2), 'cosine';
    is $r->radian, pi/4, 'radian';
    is $r->degree, 45, '45 degree';
}

note 'best and worst';
{
    my $cs = Data::CosineSimilarity->new;
    isa_ok $cs, 'Data::CosineSimilarity';

    $cs->add( a => { aaa => 1, aa => 1 } );
    $cs->add( b => { aaa => 1, aa => 0 } );
    $cs->add( c => { aaa => 2, aa => 2 } );

    my ($best, $worst, $r);

    ($best, $r) = $cs->best_for_label('a');
    is $best, 'c';
    isa_ok $r, 'Data::CosineSimilarity::Result';
    is_deeply [ $r->labels ], [ 'a', 'c' ], 'labels';
    is $r->cosine, 1, 'cosine';
    near( $r->radian, 0 );
    near( $r->degree, 0 );

    ($worst, $r) = $cs->worst_for_label('a');
    is $worst, 'b';
    isa_ok $r, 'Data::CosineSimilarity::Result';
    is_deeply [ $r->labels ], [ 'a', 'b' ], 'labels';
    is $r->cosine, 1/sqrt(2), 'cosine';
    is $r->radian, pi/4, 'radian';
    is $r->degree, 45, '45 degree';
}
