use Test;
BEGIN { plan tests => 56 };
use Algorithm::HowSimilar 'compare';
ok(1);
my @res;

@res = compare( 'this string', 'this string' );
ok( $res[0], 1  );
ok( $res[1], 1 );
ok( $res[2], 1 );
ok( $res[3], 'this string' );
ok( $res[4], '' );
ok( $res[5], '' );

@res = compare( 'this', 'that' );
ok( $res[0], 0.5  );
ok( $res[1], 0.5 );
ok( $res[2], 0.5 );
ok( $res[3], 'th' );
ok( $res[4], 'is' );
ok( $res[5], 'at' );

@res = compare( 'the quick brown fox jumped over the lazy dog',
                'the quick brown dog jumped over the lazy fox' );

ok( (sprintf"%.6f",$res[0]), 0.909091 );
ok( (sprintf"%.6f",$res[1]), 0.909091 );
ok( (sprintf"%.6f",$res[2]), 0.909091 );
ok( $res[3], 'the quick brown o jumped over the lazy o' );
ok( $res[4], 'fxdg' );
ok( $res[5], 'dgfx' );

@res = compare( 'the quick brown fox jumped over the lazy dog',
                'the quick brown dog jumped over the lazy fox',
                sub { [split ' '] } );

ok( (sprintf"%.6f",$res[0]), 0.833333 );
ok( (sprintf"%.6f",$res[1]), 0.833333 );
ok( (sprintf"%.6f",$res[2]), 0.833333 );
ok( $res[3], 'thequickbrownjumpedoverthelazy' );
ok( $res[4], 'foxdog' );
ok( $res[5], 'dogfox' );

@res = compare( 'the quick brown fox jumped over the lazy dog',
                'the quick brown dog jumped over the lazy fox, tripped and broke its neck' );

ok( (sprintf"%.6f",$res[0]), 0.750631 );
ok( (sprintf"%.6f",$res[1]), 0.931818 );
ok( (sprintf"%.6f",$res[2]), 0.569444 );
ok( $res[3], 'the quick brown o jumped over the lazy do' );
ok( $res[4], 'fxg' );
ok( $res[5], 'dgfox, trippe and brke its neck' );

@res = compare( [split//,'this string'], [split//,'this string'] );
ok( $res[0], 1  );
ok( $res[1], 1 );
ok( $res[2], 1 );
ok( @{$res[3]}, 11 );
ok( (join '',@{$res[3]}), 'this string' );
ok( @{$res[4]}, 0 );
ok( @{$res[5]}, 0 );


@res = compare( [split//,'this'], [split//,'that'], );
ok( $res[0], 0.5  );
ok( $res[1], 0.5 );
ok( $res[2], 0.5 );
ok( @{$res[3]}, 2 );
ok( @{$res[4]}, 2 );
ok( @{$res[5]}, 2 );
ok( (join ' ',@{$res[3]}), 't h' );
ok( (join ' ',@{$res[4]}), 'i s' );
ok( (join ' ',@{$res[5]}), 'a t' );

@res = compare( [(split ' ','the quick brown fox jumped over the lazy dog')],
                [(split ' ','the quick brown dog jumped over the lazy fox, tripped and broke its neck')] );

ok( (sprintf"%.6f",$res[0]), 0.638889 );
ok( (sprintf"%.6f",$res[1]), 0.777778 );
ok( (sprintf"%.6f",$res[2]), '0.500000' );
ok( @{$res[3]}, 7 );
ok( @{$res[4]}, 2 );
ok( @{$res[5]}, 7 );
ok( (join ' ',@{$res[3]}), 'the quick brown jumped over the lazy' );
ok( (join ' ',@{$res[4]}), 'fox dog' );
ok( (join ' ',@{$res[5]}), 'dog fox, tripped and broke its neck' );


