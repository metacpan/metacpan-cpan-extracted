use Test::More tests => 17;

use_ok('DataFlow::Proc::SimpleFileInput');
new_ok('DataFlow::Proc::SimpleFileInput');

my $file = './examples/file.test';

my $data = DataFlow::Proc::SimpleFileInput->new;

is( ( $data->process($file) )[0], 'linha 1' );
is( ( $data->process() )[0],      'linha 2' );
is( ( $data->process() )[0],      'linha 3' );
is( ( $data->process() )[0],      'linha 4' );
is( ( $data->process() )[0],      'linha 5' );
is( ( $data->process() )[0],      'linha 6' );
is( ( $data->process() )[0],      'linha 7' );

ok( !defined( ( $data->process() )[0] ) );

my $data2 = DataFlow::Proc::SimpleFileInput->new( do_slurp => 1 );
my $res2 = ( $data2->process($file) )[0];

is( $res2->[0], 'linha 1' );
is( $res2->[1], 'linha 2' );
is( $res2->[2], 'linha 3' );
is( $res2->[3], 'linha 4' );
is( $res2->[4], 'linha 5' );
is( $res2->[5], 'linha 6' );
is( $res2->[6], 'linha 7' );

