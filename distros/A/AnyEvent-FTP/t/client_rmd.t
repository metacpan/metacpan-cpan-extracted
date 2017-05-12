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
plan tests => 2;

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

my $client = AnyEvent::FTP::Client->new;

prep_client( $client );

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;
$client->type('I')->recv;
$client->cwd($config->{dir})->recv;

do {
  my $dir_name = File::Spec->catdir($config->{dir}, 'foo');
  mkdir $dir_name;
  my $ret = eval { $client->rmd('foo')->recv; };
  diag $@ if $@;
  isa_ok $ret, 'AnyEvent::FTP::Response';
  ok !-d $dir_name, "dir removed: $dir_name";
  rmdir $dir_name if -d $dir_name;
};
  
$client->quit->recv;
