#! perl -T
use Test::More;

use App::CSE;

my $cse = App::CSE->new();

{
  local @ARGV = ( 'help' , '--verbose' );
  ok( $cse->version() , "Ok got a version");
  ok( $cse->command()->isa('App::CSE::Command::Help') , "Ok good command instance");
  ok( $cse->main() , "Ok can execute the magic command");
  ok( $cse->options()->{verbose} , "Ok verbose is set");
}

ok(1);
done_testing();
