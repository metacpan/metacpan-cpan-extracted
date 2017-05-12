#! perl -T
use Test::More;

use Log::Log4perl qw/:easy/;


# Log::Log4perl->easy_init($TRACE);
binmode STDOUT , ':utf8';
binmode STDERR , ':utf8';


use App::CSE;

use Carp::Always;

use File::Temp;
use Path::Class::Dir;

use File::BaseDir qw//;
unless( File::BaseDir::data_files('mime/globs') ){
    plan skip_all => 'No mime-info database on the machine. The shared-mime-info package is available from http://freedesktop.org/';
}



my $idx_dir = File::Temp->newdir( CLEANUP => 1 );
my $content_dir = Path::Class::Dir->new('t/toindex');

# We are trying to cover as many languages from http://langpop.corger.nl/
# as possible.

{
  ## Searching for some javascript.
  local @ARGV = (  '--idx='.$idx_dir, 'javascriptIsGreat', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hit");
}

{
  ## Searching for 'isgreat' in javascript
  local @ARGV = (  '--idx='.$idx_dir, 'isgreat', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hit");
}


{
  ## Searching for some ruby
  local @ARGV = (  '--idx='.$idx_dir, 'ruby');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 3 , "Ok got two hits (one is a directory)");
}

{
  ## Searching for some text file
  local @ARGV = (  '--idx='.$idx_dir, 'search_for_text');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hit");
}

{
  ## Searching a file that is really too big
  local @ARGV = (  '--idx='.$idx_dir, 'really_big');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 0, "Ok got zero hit");
}

{
  ## Searching in ini file
  local @ARGV = (  '--idx='.$idx_dir, 'ini_file_section' );
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got zero hit");
}

{
  ## Searching a template toolkit file
  local @ARGV = (  '--idx='.$idx_dir, 'template_toolkit mime:application/x-templatetoolkit');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching a java file
  local @ARGV = (  '--idx='.$idx_dir, 'Java mime:text/x-java');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching for CSharp
  local @ARGV = (  '--idx='.$idx_dir, 'CSHarp mime:text/x-csharp');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching for php_test
  local @ARGV = (  '--idx='.$idx_dir, 'php_test');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching for pythonesque
  local @ARGV = (  '--idx='.$idx_dir, 'pythonesque');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching for hypertext (from the XHTML file).
  local @ARGV = (  '--idx='.$idx_dir, 'HyperText');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching for this_is_an_html_file (from the HTML file).
  local @ARGV = (  '--idx='.$idx_dir, 'This_is_an_html_file');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

{
  ## Searching for c_plus_plus (from the .cc and .cpp file).
  local @ARGV = (  '--idx='.$idx_dir, 'c_plus_plus');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 2, "Ok got two hits. One from the .cc and one from the .cpp");
}

{
  ## Searching for head_h (from the .h file).
  local @ARGV = (  '--idx='.$idx_dir, 'head_h');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1, "Ok got one hit");
}

ok(1);
done_testing();
