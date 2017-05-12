
use Test::More tests => 24;

use_ok('DataFlow::ProcWrapper');

eval { my $fail = DataFlow::ProcWrapper->new };
ok($@);

my $wrapped = DataFlow::ProcWrapper->new( wraps => 'UC' );
ok($wrapped);
my @res = $wrapped->process('abc');
is( scalar(@res), 1 );
isnt( $res[0], 'ABC' );
is( $res[0]->get_data('default'), 'ABC' );

# non-raw input tests
use DataFlow::Item;
my $item = DataFlow::Item->new;
isa_ok( $item, 'DataFlow::Item' );
is( $item->set_data( 'teste123', 'something' ), $item );
is_deeply( $wrapped->process($item), $item );

is( $item->set_data( 'default', 'another one' ), $item );
@res = $wrapped->process($item);
is( scalar @res, 1 );

is( $res[0]->get_data('teste123'), 'something' );
is( $res[0]->get_data('default'),  'ANOTHER ONE' );

# channel tests
my $wrap_ch1 = DataFlow::ProcWrapper->new( wraps => 'UC', input_chan => 'ch1' );
ok($wrap_ch1);
@res = $wrap_ch1->process('abc');
ok(@res);
is( $res[0]->get_data('ch1'), 'ABC' );
is_deeply( $res[0]->channels, { ch1 => 'ABC' } );

@res = $wrap_ch1->process($item);
ok(@res);
is_deeply( $res[0]->channels, $item->channels );

# multiple responses tests
my $wrap_multi =
  DataFlow::ProcWrapper->new(
    wraps => sub { return ( 1 + $_, 2 * $_, sqrt($_) ) } );
ok($wrap_multi);
@res = $wrap_multi->process(34);
is( scalar @res, 3 );

is( $res[0]->get_data('default'), 35 );
is( $res[1]->get_data('default'), 68 );
is( $res[2]->get_data('default'), sqrt(34) );

