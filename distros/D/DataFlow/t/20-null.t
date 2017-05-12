
use Test::More tests => 7;

use_ok('DataFlow::Proc::Null');

my $null = DataFlow::Proc::Null->new;
ok($null);

#use Data::Dumper; warn Dumper($null->process());
ok( !defined( ( $null->process() )[0] ) );
ok( !defined( ( $null->process('yadayadayada') )[0] ) );
ok( !defined( ( $null->process(42) )[0] ) );
ok( !defined( ( $null->process( [qw/a b c d e f g h i j/] ) )[0] ) );

my $notinto = DataFlow::Proc::Null->new( policy => 'Scalar' );
ok( !defined( ( $notinto->process() )[0] ) );
