use strict;
use warnings;
use 5.010;
use Test::More;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use File::Temp qw( tempdir );
use File::Spec;
use FindBin ();
require "$FindBin::Bin/lib.pl";

plan skip_all => 'requires client and server on localhost' if $ENV{AEF_REMOTE};
plan tests => 10;

our $config;
my $remote = $config->{dir} = tempdir( CLEANUP => 1 );

my $local = tempdir( CLEANUP => 1 );

foreach my $passive (0,1)
{

  my $client = AnyEvent::FTP::Client->new( passive => $passive );

  prep_client( $client );

  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;

  do {
    open my $fh, '>', "$local/data.$passive";
    binmode $fh;
    print $fh "data$_\n" for 1..200;
    close $fh;
  };
  
  $client->stor("data.$passive", "$local/data.$passive")->recv;

  my $size = -s "$local/data.$passive";
  is $size && -s "$remote/data.$passive", $size, "size of remote file is $size";  
  $size = $client->size("data.$passive")->recv;
  is $size, -s "$local/data.$passive", "size returned from remote file is correct";

  my $expected = do {
    open my $fh, '>>', "$local/data.$passive";
    binmode $fh;
    print $fh "xorxor$_\n" for 1..300;
    close $fh;
    
    open $fh, '<', "$local/data.$passive";
    binmode $fh;
    local $/;
    my $data = <$fh>;
    close $fh;
    $data;
  };
  
  do {
    open my $fh, '<', "$local/data.$passive";
    binmode $fh;
    seek $fh, $client->size("data.$passive")->recv, 0;
    $client->appe("data.$passive", $fh)->recv;
    close $fh;
  };
  
  $size = -s "$local/data.$passive";
  is $size && -s "$remote/data.$passive", $size, "size of remote file is $size";  
  $size = $client->size("data.$passive")->recv;
  is $size, -s "$local/data.$passive", "size returned from remote file is correct";
  
  my $actual = do {
    open my $fh, '<', "$remote/data.$passive";
    binmode $fh;
    local $/;
    my $data = <$fh>;
    close $fh;
    $data;
  };
  
  is $actual, $expected, "files match";
  
  $client->quit->recv;
}

