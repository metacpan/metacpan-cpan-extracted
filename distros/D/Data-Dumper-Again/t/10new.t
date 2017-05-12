#perl -T 

use Test::More 'no_plan';

BEGIN { use_ok('Data::Dumper::Again'); }

{
my $dumper = Data::Dumper::Again->new;
isa_ok($dumper, 'Data::Dumper::Again');

isa_ok($dumper->guts, 'Data::Dumper');
}

{
my @params = (
    indent => 3,
    purity => 1,
    pad => '# ',
    varname => '$var',
    useqq => 1,
    terse => 1,
#    freezer 
#    toaster
    deepcopy => 1,
    quotekeys => 1,
#    bless
    pair => ' => ',
    maxdepth => 0,
    useperl => 1,
    sortkeys => 1,
    deparse => 1,
);
my %params = @params;

my $dumper = Data::Dumper::Again->new( purity => 1, indent => 3 );
isa_ok($dumper, 'Data::Dumper::Again');

my $guts = $dumper->guts;
isa_ok($guts, 'Data::Dumper');
is($guts->Purity, 1, "Purity => 1");
is($guts->Indent, 3, "Indent => 3");

}

{
my $dumper = Data::Dumper::Again->new;
isa_ok($dumper, 'Data::Dumper::Again');
}

