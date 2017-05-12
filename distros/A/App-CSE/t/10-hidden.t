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


my $idx_dir = File::Temp->newdir( CLEANUP => 1 );
my $content_dir = File::Temp->newdir( CLEANUP => 1 );

my $original_content_dir = Path::Class::Dir->new('t/toindex');
File::Copy::Recursive::dircopy($original_content_dir , $content_dir);

my $cse;
{
  ## Searching just for bonjour
  local @ARGV = ( 'bonjour' ,  '--idx='.$idx_dir  , '--dir='.$content_dir );
  $cse = App::CSE->new({ cseignore => undef });
  ok( $cse->command()->isa('App::CSE::Command::Search') , "Ok its a search command");
  is_deeply( $cse->args() , [ 'bonjour' ] );
}


my @hidden_files = ( './.cse.idx/snapshot_5h.json.temp',
                     '.cse/index.json',
                 );

foreach my $hidden_file ( @hidden_files ){
    my $hidden = 0;
    ok( ! $cse->ignore_reassembl()->match( $hidden_file ), "Matching $hidden_file" );
    $cse->is_file_valid($hidden_file, { on_hidden => sub{ $hidden = 1; } });
    is( $hidden , 1 , "Hidden is 1 for file $hidden_file");
}


my @not_hidden = ( './toto.txt' , 'toto' , 'toto.txt' ,
                   './lib/App/CSE/Command/Watch.pm',
                   'lib/App/CSE/Command/Bla.pm',
                   'lib/App/CSE/Command/Bla',
                   'lib/App/CSE/./Command/Bla',
                 );
foreach my $not_hidden_file ( @not_hidden ){
  my $hidden = 0;
  $cse->is_file_valid($not_hidden_file, { on_hidden => sub{ $hidden = 1; } });
  is( $hidden , 0 , "Hidden is 0 for file $not_hidden_file");
}


ok(1);
done_testing();
