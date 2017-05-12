#! perl -T

use strict;

use Test::More;

use App::CSE;


use File::Slurp;
use File::Temp;
use File::Copy::Recursive;

use Path::Class::Dir;

use Log::Log4perl qw/:easy/;
# Log::Log4perl->easy_init($INFO);


use File::BaseDir qw//;
unless( File::BaseDir::data_files('mime/globs') ){
  plan skip_all => 'No mime-info database on the machine. The shared-mime-info package is available from http://freedesktop.org/';
}

unless( $ENV{TEST_SLOW} ){
  plan skip_all => 'Do not run this test. unless TEST_SLOW=1';
}


my $idx_dir = File::Temp->newdir( CLEANUP => 1 );
my $content_dir = File::Temp->newdir( CLEANUP => 1 );

my $original_content_dir = Path::Class::Dir->new('t/toindex');
File::Copy::Recursive::dircopy($original_content_dir , $content_dir);

# {
#   ## Indexing the content dir
#   local @ARGV = ( 'index' , '--idx='.$idx_dir , $content_dir.'' );
#   my $cse = App::CSE->new();
#   is( $cse->main() , 0 ,  "Ok can execute the magic command just fine");
# }

{
  ## Searching just for bonjour
  local @ARGV = ( 'bonjour' ,  '--idx='.$idx_dir  , '--dir='.$content_dir );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok its a search command");
  is_deeply( $cse->args() , [ 'bonjour' ] );
}

my $watcher_pid;

{
  # Watch for changes.
  local @ARGV = ( 'watch' , '--idx='.$idx_dir  , '--dir='.$content_dir );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Watch') , "Ok we have a watch command");
  is( $cse->command()->execute() , 0 , "Ok can execute that");
}


{
  ## Get the watcher_pid
  local @ARGV = ( 'check' , '--idx='.$idx_dir );

  my $cse = App::CSE->new();
  ok( $watcher_pid = $cse->index_meta->{'watcher.pid'} , "Ok got a watcher PID");
  ( $watcher_pid ) = ( $watcher_pid =~ /(\d+)/ );
}

# Create a new pm file and check we can search for it.
  my $code = q|package My::Shiny::Package

sub abcdefg123{
   ...
}

|;
  my $filename =
    Path::Class::Dir->new( $content_dir )->file('package.pm')->absolute->stringify();
  File::Slurp::write_file($filename , $code );

{
  # Search a few times (timeout is 10 * 5 seconds
  my $can_continue = 20;
  my $total_hits = 0;
  my $sleep_time = 1;
  do{
    local @ARGV = ( 'abcdefg123' , '--idx='.$idx_dir );
    my $cse = App::CSE->new();
    $cse->command()->execute();
    $total_hits = $cse->command()->hits()->total_hits();
  } while( $can_continue-- &&  !$total_hits  && sleep($sleep_time++) );

  cmp_ok( $total_hits , '>' , 0  , "Ok, total hits is positive before we time out");
}


# Remove the file and see that we cannot find it a bit later
unlink $filename;
{
  my $can_continue = 20;
  my $total_hits = 0;
  my $sleep_time = 1;
  do{
    local @ARGV = ( 'abcdefg123' , '--idx='.$idx_dir );
    my $cse = App::CSE->new();
    $cse->command()->execute();
    $total_hits = $cse->command()->hits()->total_hits();
  } while( $can_continue-- &&  $total_hits  && sleep($sleep_time++) );

  is( $total_hits , 0  , "Ok, total hits is 0 before the timeout");
}



{
  # Time to unwatch
  local @ARGV = ( 'unwatch' , '--idx='.$idx_dir );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Unwatch') , "Ok good command");
  is( $cse->command()->execute() , 0 , "Ok can execute that");
}

{
  local @ARGV = ( 'unwatch' , '--idx='.$idx_dir );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Unwatch') , "Ok good command");
  is( $cse->command()->execute() , 1 , "Ok executing that is a mistake");
}


{
  # Kill 9 the watcher pid, just in case.
  kill( 9 , $watcher_pid );
}


ok(1);
done_testing();
