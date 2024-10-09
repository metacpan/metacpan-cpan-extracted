use Test2::V0;
use Bible::Reference;

my $r1 = Bible::Reference->new( sorting => 1 );
my $r2 = Bible::Reference->new( sorting => 0 );

$r1->bible('Protestant');
$r2->bible('Catholic');

$r1->in('Jam 3:5');
$r2->in('Rom 12:13');

is( $r1->sorting, 1, 'sorting 1' );
is( $r2->sorting, 0, 'sorting 0' );

is( $r1->bible, 'Protestant', 'Protestant Bible' );
is( $r2->bible, 'Catholic', 'Catholic Bible' );

is( $r1->refs, 'James 3:5', 'James 3:5' );
is( $r2->refs, 'Romans 12:13', 'Romans 12:13' );

done_testing;
