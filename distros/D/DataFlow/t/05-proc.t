use Test::More tests => 8;

BEGIN { use_ok('DataFlow::Proc'); }

# tests: 2
diag('constructor and basic tests');
my $uc = DataFlow::Proc->new( p => sub { uc } );
ok($uc);
isa_ok( $uc, 'DataFlow::Proc' );
can_ok( $uc, qw(name deref dump_input dump_output p process) );

# tests: 4
# scalars
diag('scalar params');
ok( !defined( $uc->process() ), 'returns nothing for nothing' );
is( ( $uc->process('aaa') )[0], 'AAA', 'works as it should' );
isnt( ( $uc->process('bbb') )[0], 'bbb', 'indeed works as it should' );
is( ( $uc->process(1) )[0], 1, );

