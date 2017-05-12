#! perl -wT

use Test::More;

use_ok( 'App::EC2Cssh' );
ok( my $app = App::EC2Cssh->new({ set => 'bla' }) , "Ok can build a command");

done_testing();
