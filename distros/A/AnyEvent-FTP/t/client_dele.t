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
plan tests => 6;

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

my $client = AnyEvent::FTP::Client->new;

prep_client( $client );

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;
$client->type('I')->recv;
$client->cwd($config->{dir})->recv;

do {
  my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
  do { open my $fh, '>', $fn; close $fh; };
  
  ok -e $fn, "created file";
  
  my $ret = eval { $client->dele('foo.txt')->recv; };
  diag $@ if $@;
  isa_ok $ret, 'AnyEvent::FTP::Response';
  
  ok !-e $fn, "deleted file";
};
  
do {
  my $fn = File::Spec->catfile($config->{dir}, 'bar.txt');

  ok !-e $fn, "created file";
  
  eval { $client->dele('foo.txt')->recv; };
  my $res = $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  
  ok !-e $fn, "deleted file";
};
  
$client->quit->recv;
