use Modern::Perl;
use Test::More;
use Test::Exception;

use_ok( 'Bio::Protease' );

my $enzyme;

lives_ok { $enzyme = Bio::Protease->new(specificity => 'trypsin') };

is $enzyme->specificity, 'trypsin';

isa_ok($enzyme, 'Bio::Protease');

dies_ok { $enzyme = Bio::Protease->new() };
dies_ok { $enzyme = Bio::Protease->new(specificity => 'ooo') };

my $regexp = qr/AGGAL[^P]/;
my @arrayrefs = (['AGGAL[^P]'], [$regexp]);

test_custom($_) for (@arrayrefs, $regexp);

sub test_custom {

    my $pattern = shift;

    lives_ok { $enzyme = Bio::Protease->new(specificity => $pattern) };

    is $enzyme->specificity, 'custom';

    ok  $enzyme->is_substrate( 'AGGALH' ), "Custom pattern: $pattern";
    ok !$enzyme->is_substrate( 'AGGALP' );
}


done_testing();
