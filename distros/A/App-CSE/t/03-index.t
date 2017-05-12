#! perl -T
use Test::More;

use App::CSE;


use File::Temp;
use Path::Class::Dir;

use Log::Log4perl qw/:easy/;
# Log::Log4perl->easy_init($DEBUG);


use File::BaseDir qw//;
unless( File::BaseDir::data_files('mime/globs') ){
    plan skip_all => 'No mime-info database on the machine. The shared-mime-info package is available from http://freedesktop.org/';
}


{
  #local @ARGV = ( 'help' );

  my $idx_dir = File::Temp->newdir( CLEANUP => 1 );
  my $content_dir = Path::Class::Dir->new('t/toindex');

  local @ARGV = ( 'index' , '--idx='.$idx_dir , '--dir='.$content_dir.'' );

  my $cse = App::CSE->new({ cseignore => $content_dir->file('cseignore') });

  ok( $cse->cseignore(), "Ok found cse ignore file");
  ok( $cse->ignore_reassembl() , "Ok got an ignore regexp");
  ok( ! $cse->ignore_reassembl()->match('will-be-indexed') , "Ok no match");
  ok( $cse->ignore_reassembl()->match('/a/b/c-ignored') , "Ok got match");

  # is_deeply( $cse->args() , [ $content_dir ], "Ok good args");

  is( $cse->options()->{dir} , $content_dir , "Ok good dir option");

  ok( $cse->index_dir() , "Ok index dir");
  is( $cse->index_dir() , $idx_dir.'' , "Ok good option taken into account");

  ok( $cse->command()->isa('App::CSE::Command::Index') , "Ok good command instance");
  is( $cse->command()->dir_index() , $content_dir , "Ok good index dir");
  is( $cse->main() , 0 ,  "Ok can execute the magic command just fine");
}

ok(1);
done_testing();
