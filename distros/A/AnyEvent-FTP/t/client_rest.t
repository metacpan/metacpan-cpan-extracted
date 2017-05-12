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

my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
do {
  open my $fh, '>', $fn;
  print $fh "012345678901234567890";
  close $fh;
};

foreach my $passive (0,1)
{

  my $client = AnyEvent::FTP::Client->new( passive => $passive );

  prep_client( $client );

  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;

  do {
    my $data = '0123456789';
    my $ret1 = eval { $client->rest(10)->recv; };
    diag $@ if $@;
    isa_ok $ret1, 'AnyEvent::FTP::Response';
    
    my $ret2 = eval { $client->retr('foo.txt', sub { $data .= shift }, restart => length $data)->recv; };
    diag $@ if $@;
    isa_ok $ret2, 'AnyEvent::FTP::Response';
    is $data, "012345678901234567890", 'data = "012345678901234567890"';
  };

  $client->quit->recv;
}
