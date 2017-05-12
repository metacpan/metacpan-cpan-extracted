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
plan tests => 11;

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

my $client = AnyEvent::FTP::Client->new;

prep_client( $client );

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;
$client->type('I')->recv;
$client->cwd($config->{dir})->recv;

do {
  my $from = File::Spec->catfile($config->{dir}, 'foo.txt');
  do { open my $fh, '>', $from; close $fh; };
  my $to   = File::Spec->catfile($config->{dir}, 'bar.txt');
  
  ok  -e $from, "EX: $from";
  ok !-e $to,   "NO: $to";
  
  my $res1 = eval { $client->rnfr($from)->recv };
  diag $@ if $@;
  isa_ok $res1, 'AnyEvent::FTP::Response';
  
  my $res2 = eval { $client->rnto($to)->recv };
  diag $@ if $@;
  isa_ok $res2, 'AnyEvent::FTP::Response';
  
  ok !-e $from, "NO: $from";
  ok  -e $to,   "EX: $to";
};
  
do {
  my $from = File::Spec->catfile($config->{dir}, 'pepper.txt');
  do { open my $fh, '>', $from; close $fh; };
  my $to   = File::Spec->catfile($config->{dir}, 'coke.txt');
  
  ok  -e $from, "EX: $from";
  ok !-e $to,   "NO: $to";
  
  my $res = eval { $client->rename($from, $to)->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  
  ok !-e $from, "NO: $from";
  ok  -e $to,   "EX: $to";
};
  
$client->quit->recv;
