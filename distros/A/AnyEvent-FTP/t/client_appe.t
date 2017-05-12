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
plan tests => 12;

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

foreach my $passive (0,1)
{

  my $client = AnyEvent::FTP::Client->new( passive => $passive );

  prep_client( $client );

  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd(translate_dir($config->{dir}))->recv;

  my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');

  do {
    open my $fh, '>', $fn;
    say $fh "line1";
    close $fh;
  };
  
  do {
    my $data = 'line2';
    my $ret = eval { $client->appe('foo.txt', \$data)->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    ok -e $fn, 'remote file exists';
    my @remote = split /\015?\012/, do {
      open my $fh, '<', $fn;
      local $/;
      <$fh>;
    };
    is scalar(@remote), 2, 'two lines';
    is $remote[0], 'line1', 'line 1 = line1';
    is $remote[1], 'line2', 'line 2 = line2';
  };
  
  unlink $fn;
  ok !-e $fn, 'remote file deleted';

  $client->quit->recv;
}
