use Test::More tests => 4;

use DataFlow;

my $flow = DataFlow->new( [ sub { uc } ] );
ok( $flow, 'Can construct a dataflow from a bare sub' );
is( $flow->process('aaa'), 'AAA', 'and it provides the correct result' );
my @data = qw/a1 b2 c3 d4 e5 f6 g7 h8 i9 j0/;
my @res  = $flow->process(@data);
is( scalar @res, 10, 'result has the right size' );
is_deeply( \@res, [qw/A1 B2 C3 D4 E5 F6 G7 H8 I9 J0/], 'has the right data' );

