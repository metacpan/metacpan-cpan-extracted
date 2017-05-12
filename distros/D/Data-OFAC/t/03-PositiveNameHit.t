use Test;
BEGIN { plan tests => 4 };
use Data::OFAC;

ok(1);

ok(my $ofac = Data::OFAC->new());

ok($result = $ofac->checkName('ABASTECEDORA NAVAL Y INDUSTRIAL, S.A.'));
ok((defined $result && defined $result->{entityhit} && $result->{entityhit} eq 'ABASTECEDORA NAVAL Y INDUSTRIAL, S.A.' ) ? 0 : 1 );
