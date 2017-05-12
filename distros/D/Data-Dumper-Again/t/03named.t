#perl -T 

use Test::More 'no_plan';

BEGIN { use_ok('Data::Dumper::Again'); }

{
my $dumper = Data::Dumper::Again->new;
isa_ok($dumper, 'Data::Dumper::Again');

my $s = $dumper->dump_named(a => 1);
is ($s, "\$a = 1;\n");

}

