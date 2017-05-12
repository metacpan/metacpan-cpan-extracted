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

  is( $cse->index_meta->{version} , '-unknown-' , "Ok good unknown version");

  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hit");

  is( $cse->index_meta->{version} , $cse->version() , "Ok good version in index meta");
}

{
  ## Build the object, but not the index again.
  local @ARGV = (  '--idx='.$idx_dir, 'javascriptIsGreat', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->index_meta->{version} , $cse->version() , "Ok good version in index meta");
  ok( $cse->index_meta->{index_time} , "Ok got an index time");
}




ok(1);
done_testing();
