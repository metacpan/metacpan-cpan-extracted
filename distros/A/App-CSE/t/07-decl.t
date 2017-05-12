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

## Testing the decl field
{
  ## Searching for some_method
  local @ARGV = (  '--idx='.$idx_dir, 'some_method', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( $cse->command()->hits() , "Ok got hits");
  is( $cse->command()->hits()->total_hits() , 2 , "Ok two hits");
}

SKIP: {
    skip "Perl too old.", 3  unless ( $] ge '5.14' );
    ## Searching for some method, but excluding the declaration
    local @ARGV = (  '--idx='.$idx_dir, 'some_method', '-decl:some_method', '--dir='.$content_dir.'');
    my $cse = App::CSE->new();
    is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
    ok( $cse->command()->hits() , "Ok got hits");
    is( $cse->command()->hits()->total_hits() , 1 , "Ok one hit only");
};

ok(1);
done_testing();
