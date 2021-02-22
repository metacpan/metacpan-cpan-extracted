#! perl -T
use Test::More;

use App::CSE;


use File::Temp;
use Path::Class::Dir;

use Log::Log4perl qw/:easy/;
# Log::Log4perl->easy_init($ERROR);

use File::BaseDir qw//;
unless( File::BaseDir::data_files('mime/globs') ){
    plan skip_all => 'No mime-info database on the machine. The shared-mime-info package is available from http://freedesktop.org/';
}


my $idx_dir = File::Temp->newdir( CLEANUP => 1 );
my $content_dir = Path::Class::Dir->new('t/toindex');


# {
#   ## Indexing the content dir
#   local @ARGV = ( 'index' , '--idx='.$idx_dir , $content_dir.'' );
#   my $cse = App::CSE->new();
#   is( $cse->main() , 0 ,  "Ok can execute the magic command just fine");
# }

{
  ## Searching just for bonjour
  local @ARGV = ( 'bonjour' );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok its a search command");
  is_deeply( $cse->args() , [ 'bonjour' ] );
}

{
  # Explicit search for bonjour
  local @ARGV = ( 'search' , 'bonjour' );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok its a search command");
  is_deeply( $cse->args() , [ 'bonjour' ] );
}

{
  # Explicit search for bonjour
  local @ARGV = ( 'bonjour' , '--idx=blabla' );
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok its a search command");
  is( $cse->options()->{idx} , 'blabla' );
  is_deeply( $cse->args() , [ 'bonjour' ] );
}

{
  ## Searching the content dir for bonjour.
  local @ARGV = (  '--idx='.$idx_dir, 'bonjour', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok got search");
  is( $cse->command()->query->to_string() , '(call:bonjour OR content:bonjour OR decl:bonjour OR path:bonjour)' , "Ok got good query");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 2 , "Ok got two hits");
  ok( $cse->index_mtime() , "Ok got index mtime");
}

{
  ## Searching the content dir for exported_method.
  local @ARGV = (  '--idx='.$idx_dir, 'call:exported_method', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok got search");
  is( $cse->command()->query->to_string() , 'call:exported_method');
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hit");
}

{
    # Indexing with .cseignore
    local @ARGV = ( 'index' , '--idx='.$idx_dir , '--dir='.$content_dir.'' );
    my $cse = App::CSE->new({ cseignore => $content_dir->file('cseignore') });
    is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
}

{
  ## Searching the content dir for ignored
  local @ARGV = (  '--idx='.$idx_dir, 'ignored', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 0 , "Ok go zero hit");
}

{
  ## Searching the content_dir/text_files/ for bonjour. Shouldnt not find anything.
  local @ARGV = (  '--idx='.$idx_dir, 'bonjour', $content_dir.'/text_files');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  is( $cse->command()->hits()->total_hits() , 0 , "No hits there.");
}

{
  ## Searhing for bon*. Will find stuff with bonjour, bonnaventure and bonsoir
  local @ARGV = (  '--idx='.$idx_dir, 'bon*', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  # diag($cse->command->query()->to_string());
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  is( $cse->command()->hits()->total_hits() , 3 , "Ok got 3 hits");
}

## Check various queries

{
  # Plain simple term
  local @ARGV = (  '--idx='.$idx_dir, 'hello', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string() , '(call:hello OR content:hello OR decl:hello OR path:hello)');
}

{
  # Plain field term
  local @ARGV = (  '--idx='.$idx_dir, 'content:hello', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string(), 'content:hello');
}

{
  # Single prefix query
  local @ARGV = (  '--idx='.$idx_dir, 'hell*', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string(), 'content:hell*');
}

{
  # Qualified prefix query
  local @ARGV = (  '--idx='.$idx_dir, 'path:hell*', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string(), 'path:hell*');
}

{
  # Qualified composed queries
  local @ARGV = (  '--idx='.$idx_dir, 'path:hell* AND NOT content:helo*', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string(), '(path:hell* AND -content:helo*)');
}

{
  # Qualified composed queries, multi args
  local @ARGV = (  '--idx='.$idx_dir, 'path:hell*', 'AND', 'NOT' , 'content:helo*', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string(), '(path:hell* AND -content:helo*)');
}

{
  # Same in another way
  local @ARGV = (  '--idx='.$idx_dir, 'path:hell*', '-content:helo*', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  use Data::Dumper;
  is($cse->command->query()->to_string(), '(path:hell* AND -content:helo*)');
}

ok(1);
done_testing();
