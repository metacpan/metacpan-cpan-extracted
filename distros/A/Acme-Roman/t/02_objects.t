
use Test::More no_plan => 1;

require_ok( 'Acme::Roman' );

{
my $r = Acme::Roman->new(2);

isa_ok( $r, 'Acme::Roman');
is( abs $r, 2, 'numification works' );
is( "$r", 'II', 'stringification works too' );
}

{
my $r = Acme::Roman->new('XLII');

isa_ok( $r, 'Acme::Roman');
is( abs $r, 42, 'numification works' );
is( "$r", 'XLII', 'stringification works too' );
}

{
my $r1 = Acme::Roman->new(33);
my $r2 = Acme::Roman->new('XXII');

is( abs $r1, 33, 'numification works' );
is( "$r1", 'XXXIII', 'stringification works too' );
is( abs $r2, 22, 'numification works' );
is( "$r2", 'XXII', 'stringification works too' );

isa_ok( $r1+$r2, 'Acme::Roman', 'sum of romans' );
is( abs($r1+$r2), 55, 'works as num' );
is( ($r1+$r2).'', 'LV', 'works as roman too' );

isa_ok( $r1+7, 'Acme::Roman', 'sum of roman and number' );
is( abs($r1+7), 40, 'works as num' );
is( ($r1+7).'', 'XL', 'works as roman too' );

isa_ok( 8+$r2, 'Acme::Roman', 'sum of number and roman' );
is( abs(8+$r2), 30, 'works as num' );
is( (8+$r2).'', 'XXX', 'works as roman too' );

}

{
my $r1 = Acme::Roman->new(3);
my $r2 = Acme::Roman->new('IV');

isa_ok( $r1*$r2, 'Acme::Roman', 'product of romans' );
is( abs($r1*$r2), 12, 'works as num' );
is( ($r1*$r2).'', 'XII', 'works as roman too' );

isa_ok( $r1*2, 'Acme::Roman', 'sum of roman and number' );
is( abs($r1*2), 6, 'works as num' );
is( ($r1*2).'', 'VI', 'works as roman too' );

isa_ok( 4*$r2, 'Acme::Roman', 'sum of number and roman' );
is( abs(4*$r2), 16, 'works as num' );
is( (4*$r2).'', 'XVI', 'works as roman too' );

}

{
my $r1 = Acme::Roman->new('X');
my $r2 = Acme::Roman->new(10);

isa_ok( $r1*'I', 'Acme::Roman', 'product of roman and string' );
is( abs($r1*'I'), 10, 'works as num' );
is( ($r1*'I').'', 'X', 'works as roman too' );

isa_ok( 'II'*$r2, 'Acme::Roman', 'product of string and roman' );
is( abs('II'*$r2), 20, 'works as num' );
is( ('II'*$r2).'', 'XX', 'works as roman too' );

}

{
    eval { Acme::Roman->new(10000); };
    like( $@, qr/above 3999/, 'new() dies on too large numbers' );
}

{
    eval { Acme::Roman->new('ab'); };
    like( $@, qr/not look like .* number/, 'new() dies on strange inputs' );
}
