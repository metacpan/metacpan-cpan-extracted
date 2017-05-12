#! perl -T
use Test::More;

use App::CSE;


use File::Temp;

my $dir = File::Temp->newdir( CLEANUP => 1 );

{
  #local @ARGV = ( 'help' );

  local @ARGV = ( 'check' , '--idx='.$dir , '--verbose' , 'blablabla' );

  my $cse = App::CSE->new();

  is_deeply( $cse->args() , [ 'blablabla' ], "Ok good args");

  ok( $cse->index_dir() , "Ok index dir");
  is( $cse->index_dir()->absolute() , $dir.'' , "Ok good option taken into account");

  ok( $cse->command()->isa('App::CSE::Command::Check') , "Ok good command instance");
  ok( $cse->main() , "Ok can execute the magic command");
  ok( $cse->options()->{verbose} , "Ok got verbose");
  ok( $cse->dirty_files() , "Ok got dirty files hash");
  # Mark the file blablabla as dirty
  $cse->dirty_files()->{blablabla} = 1;
  ok( $cse->save_dirty_files() , "Ok can save dirty files");
}

## Rebuild a brand new CSE and check the dirty files contain blablabla
{
  local @ARGV = ( 'check' , '--idx='.$dir , '--verbose' , 'blablabla' );
  my $cse = App::CSE->new();
  ok( $cse->dirty_files()->{blablabla} , "Ok blablabla is remembered as being dirty");
}

ok(1);
done_testing();
