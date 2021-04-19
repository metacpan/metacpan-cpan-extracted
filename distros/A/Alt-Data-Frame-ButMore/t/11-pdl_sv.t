#!perl

use 5.016;
use warnings;

use PDL::Core qw(pdl);
use PDL::SV ();

use Test2::V0;
use Test2::Tools::PDL;

subtest bad => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] );
    $p1->setbadat(1);

    ok( $p1->badflag, 'badflag() after setbadat()' );
    pdl_is( $p1->isbad,  pdl( [ 0, 1, 0 ] ), 'isbad' );
    pdl_is( $p1->isgood, pdl( [ 1, 0, 1 ] ), 'isgood' );

    is( $p1->ngood, 2, 'ngood' );
    is( $p1->nbad,  1, 'nbad' );

    my $p2 = $p1->setbadif( pdl( [ 0, 0, 1 ] ) );

    ok( $p2->badflag, 'badflag() after setbadif()' );
    pdl_is( $p2->isbad, pdl( [ 0, 1, 1 ] ), 'isbad() after setbadif' );

    is( [ @{ $p2->_internal }[ 0, 2 ] ],
        [qw(foo baz)], '_internal copied after setbadif' );

    my $p3 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux quuz)] ] );
    $p3 = $p3->setbadif( pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] ) );
    pdl_is( $p3->isbad, pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] ),
        '$pdlsv_1d->setbadif' );

    my $p3a = $p3->setbadtoval('hello');
    ok( !$p3a->badflag, 'badflag() after setbadtoval()' );
    is( $p3a->unpdl, [ [qw(foo bar hello)], [qw(qux hello quuz)] ],
        '$pdlsv_nd->setbadtoval' );
};

subtest at => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    is( $p1->at(0), 'foo', 'at' );
    is( $p1->at(1), 'BAD', 'at a bad value' );
};

subtest uniq => sub {
    my $p1 =
      PDL::SV->new( [qw(foo bar baz foo bar)] )->setbadat(1)->setbadat(2);
    pdl_is( $p1->uniq, PDL::SV->new( [qw(foo bar)] ), 'uniq' );

    pdl_is( $p1->uniqind, pdl( [ 0, 4 ] ), 'uniqind' );
};

subtest sever => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);
    my $p2 = $p1->slice( pdl( [ 1, 2 ] ) );

    $p2->sever;
    $p1->set( 2, 'quux' );
    pdl_is( $p2, PDL::SV->new( [qw(bar baz)] )->setbadat(0), 'sever' );
};

subtest slice => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( $p1->slice( pdl( [ 1, 2 ] ) ),
        PDL::SV->new( [qw(bar baz)] )->setbadat(0) );
};

subtest where => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( $p1->where( pdl( [ 0, 1, 1 ] ) ),
        PDL::SV->new( [qw(bar baz)] )->setbadat(0) );
};

subtest unpdl => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    is( $p1->unpdl, [qw(foo BAD baz)], '1D object' );

    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux quuz)] ] )
      ->setbadif( pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] ) );
    is( $p2->unpdl, [ [qw(foo bar BAD)], [qw(qux BAD quuz)] ], 'ND object' );

    my $p3 = $p1->slice( pdl( [ 1, 2 ] ) );
    is( $p3->unpdl, [qw(BAD baz)], '$slice->unpdl' );
};

subtest list => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    is( [ $p1->list ], [qw(foo BAD baz)], '1D object' );

    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux quuz)] ] )
      ->setbadif( pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] ) );
    is( [ $p2->list ], [qw(foo bar BAD qux BAD quuz)], 'ND object' );

    my $p3 = $p1->slice( pdl( [ 1, 2 ] ) );
    is( [ $p3->list ], [qw(BAD baz)], '$slice->list' );
};


subtest glue => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);
    my $p2 = PDL::SV->new( [qw(qux quux quuz)] )->setbadat(0);

    pdl_is($p1->glue(0, $p2),
           PDL::SV->new( [ qw(foo bar baz qux quux quuz) ] )
            ->setbadat(1)->setbadat(3),
           'glue 1D objects');
};

subtest match_regexp => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is(
        $p1->match_regexp(qr/ba/),
        pdl( [ 0, 1, 1 ] )->setbadat(1),
        '1D object'
    );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux quuz)] ] )
      ->setbadif($badmask);

    pdl_is(
        $p2->match_regexp(qr/fo|ux/),
        pdl( [ [ 1, 0, 0 ], [ 1, 1, 0 ] ] )->setbadif($badmask),
        'ND object'
    );
};

subtest eq => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( ( $p1 eq $p1->copy ), pdl( [ 1, 1, 1 ] )->setbadat(1), 'eq' );
    pdl_is( ( $p1 == $p1->copy ), pdl( [ 1, 1, 1 ] )->setbadat(1), '==' );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    my $p2a = PDL::SV->new( [ [qw(foo1 bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    pdl_is( ( $p2 eq $p2a ),
            pdl( [ [ 0, 1, 1 ], [ 1, 1, 1 ] ] )->setbadif($badmask),
            'eq for ND object' );
    
    pdl_is( ( $p2 eq 'foo' ),
            pdl( [ [ 1, 0, 0 ], [ 0, 0, 1 ] ] )->setbadif($badmask),
            'eq vs. a plain string' );
};

subtest ne => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( ( $p1 ne $p1->copy ), pdl( [ 0, 0, 0 ] )->setbadat(1), 'ne' );
    pdl_is( ( $p1 != $p1->copy ), pdl( [ 0, 0, 0 ] )->setbadat(1), '!=' );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    my $p2a = PDL::SV->new( [ [qw(foo1 bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    pdl_is( ( $p2 ne $p2a ),
            pdl( [ [ 1, 0, 0 ], [ 0, 0, 0 ] ] )->setbadif($badmask),
            'ne for ND object' );
    
    pdl_is( ( $p2 ne 'foo' ),
            pdl( [ [ 0, 1, 1 ], [ 1, 1, 0 ] ] )->setbadif($badmask),
            'ne vs. a plain string' );
};

subtest lt => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( ( $p1 lt $p1->copy ), pdl( [ 0, 0, 0 ] )->setbadat(1), 'lt' );
    pdl_is( ( $p1 <  $p1->copy ), pdl( [ 0, 0, 0 ] )->setbadat(1), '<' );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    my $p2a = PDL::SV->new( [ [qw(foo1 bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    pdl_is( ( $p2 lt $p2a ),
            pdl( [ [ 1, 0, 0 ], [ 0, 0, 0 ] ] )->setbadif($badmask),
            'lt for ND object' );
    
    pdl_is( ( $p2 lt 'foo' ),
            pdl( [ [ 0, 1, 1 ], [ 0, 0, 0 ] ] )->setbadif($badmask),
            'lt vs. a plain string' );
};

subtest le => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( ( $p1 le $p1->copy ), pdl( [ 1, 1, 1 ] )->setbadat(1), 'le' );
    pdl_is( ( $p1 <= $p1->copy ), pdl( [ 1, 1, 1 ] )->setbadat(1), '<=' );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    my $p2a = PDL::SV->new( [ [qw(foo1 bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    pdl_is( ( $p2 le $p2a ),
            pdl( [ [ 1, 1, 1 ], [ 1, 1, 1 ] ] )->setbadif($badmask),
            'le for ND object' );
    
    pdl_is( ( $p2 le 'foo' ),
            pdl( [ [ 1, 1, 1 ], [ 0, 0, 1 ] ] )->setbadif($badmask),
            'le vs. a plain string' );
};

subtest gt => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( ( $p1 gt $p1->copy ), pdl( [ 0, 0, 0 ] )->setbadat(1), 'gt' );
    pdl_is( ( $p1 >  $p1->copy ), pdl( [ 0, 0, 0 ] )->setbadat(1), '>' );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    my $p2a = PDL::SV->new( [ [qw(foo1 bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    pdl_is( ( $p2 gt $p2a ),
            pdl( [ [ 0, 0, 0 ], [ 0, 0, 0 ] ] )->setbadif($badmask),
            'gt for ND object' );
    
    pdl_is( ( $p2 gt 'foo' ),
            pdl( [ [ 0, 0, 0 ], [ 1, 1, 0 ] ] )->setbadif($badmask),
            'gt vs. a plain string' );
};

subtest ge => sub {
    my $p1 = PDL::SV->new( [qw(foo bar baz)] )->setbadat(1);

    pdl_is( ( $p1 ge $p1->copy ), pdl( [ 1, 1, 1 ] )->setbadat(1), 'ge' );
    pdl_is( ( $p1 >= $p1->copy ), pdl( [ 1, 1, 1 ] )->setbadat(1), '>=' );

    my $badmask = pdl( [ [ 0, 0, 1 ], [ 0, 1, 0 ] ] );
    my $p2 = PDL::SV->new( [ [qw(foo bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    my $p2a = PDL::SV->new( [ [qw(foo1 bar baz)], [qw(qux quux foo)] ] )
      ->setbadif($badmask);
    pdl_is( ( $p2 ge $p2a ),
            pdl( [ [ 0, 1, 1 ], [ 1, 1, 1 ] ] )->setbadif($badmask),
            'ge for ND object' );
    
    pdl_is( ( $p2 ge 'foo' ),
            pdl( [ [ 1, 0, 0 ], [ 1, 1, 1 ] ] )->setbadif($badmask),
            'ge vs. a plain string' );
};

subtest string => sub {
    is( PDL::SV->new( [qw(foo bar baz)] ), '[ foo bar baz ]', 'string' );
    is(
        PDL::SV->new( [ ('foo') x 10001 ] ),
        'TOO LONG TO PRINT',
        'string toolongtoprint'
    );
};

subtest dotassign => sub {
    my $p = PDL::SV->new([qw(a b c)]);

    $p .= PDL::SV->new([qw(foo bar baz)]);
    pdl_is( $p, PDL::SV->new([qw(foo bar baz)]), '.= pdlsv(len > 1)');

    $p .= PDL::SV->new(["foo"]);
    pdl_is( $p, PDL::SV->new([qw(foo foo foo)]), '.= pdlsv(len == 1)');

    $p->slice([1,2]) .= "bar";
    pdl_is( $p, PDL::SV->new([qw(foo bar bar)]), '.= non-piddle');
};

done_testing;
