#! perl -T
use Test::More;

use App::CSE;

use File::Temp;
use Path::Class::Dir;

use File::Slurp;

use Log::Log4perl qw/:easy/;
# Log::Log4perl->easy_init($TRACE);

use File::BaseDir qw//;
unless( File::BaseDir::data_files('mime/globs') ){
    plan skip_all => 'No mime-info database on the machine. The shared-mime-info package is available from http://freedesktop.org/';
}


my $idx_dir = File::Temp->newdir( CLEANUP => 1 );
# Avoid leaving context cleanup.
my $c_dir = File::Temp->newdir( CLEANUP => 1 );
my $content_dir = Path::Class::Dir->new( $c_dir );

my $bonjour_file = $content_dir->file('bonjour_file.txt');
File::Slurp::write_file($bonjour_file.'', 'bonjour' );

{
  ## Index and search the content dir
  local @ARGV = (  '--idx='.$idx_dir, 'bonjour', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hits");
}

{
  # Touch the file (write it again) and check it is now dirty
  sleep(1); # Let one second go.
  File::Slurp::write_file($bonjour_file.'', 'bonsoir' );
  local @ARGV = (  '--idx='.$idx_dir, 'bonjour', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  is( $cse->command()->hits->total_hits() , 1 , "Ok got one hit for bonjour, even if the file now says bonsoir");
  ok( $cse->dirty_files()->{$bonjour_file.''} , "Ok this file is now dirty");
}

{
  # Update and check the dirt is gone.
  local @ARGV = ( 'update', '--idx='.$idx_dir, '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  ok( $cse->command()->isa('App::CSE::Command::Update') , "Ok good command class");
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  ok( ! $cse->dirty_files()->{$bonjour_file.''} , "Ok dirt is gone");
}

{
  ## Search for bonjour, check we cannot find anything.
  local @ARGV = (  '--idx='.$idx_dir, 'bonjour', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  is( $cse->command()->hits()->total_hits() , 0 , "Ok got zero hit on bonjour");
}

{
  ## Search for bonsoir
  local @ARGV = (  '--idx='.$idx_dir, 'bonsoir', '--dir='.$content_dir.'');
  my $cse = App::CSE->new();
  is( $cse->command()->execute(), 0 , "Ok execute has terminated just fine");
  is( $cse->command()->hits()->total_hits() , 1 , "Ok got one hits");
}


ok(1);
done_testing();
