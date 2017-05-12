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
plan tests => 32;

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

my $fn = File::Spec->catfile($config->{dir}, 'foo.txt');
do {
  open my $fh, '>', $fn;
  say $fh "line 1";
  say $fh "line 2";
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
    my $dest_fn = File::Spec->catdir(tempdir( CLEANUP => 1 ), 'foo.txt');

    my $ret = eval { $client->retr('foo.txt', $dest_fn)->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    my @data = split /\015?\012/, do {
      open my $fh, '<', $dest_fn;
      local $/;
      <$fh>;
    };
    is $data[0], 'line 1';
    is $data[1], 'line 2';
  };

  do {
    my $data = '';
    my $xfer = eval { $client->retr('foo.txt') };
    isa_ok $xfer, 'AnyEvent::FTP::Client::Transfer';
    $xfer->on_open(sub {
      my $handle = shift;
      $handle->on_read(sub {
        $handle->push_read(sub {
          $data .= $_[0]{rbuf};
          $_[0]{rbuf} = '';
        });
      });
    });
    
    my $ret = eval { $xfer->recv };
    isa_ok $ret, 'AnyEvent::FTP::Response';
    my @data = split /\015?\012/, $data;
    is $data[0], 'line 1';
    is $data[1], 'line 2';
  };
  
  do {
    my $data = '';
    my $ret = eval { $client->retr('foo.txt', sub { $data .= shift })->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    my @data = split /\015?\012/, $data;
    is $data[0], 'line 1';
    is $data[1], 'line 2';
  };

  do {
    my $data = '';
    my $ret = eval { $client->retr('foo.txt', \$data)->recv; };
    diag $@ if $@;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    my @data = split /\015?\012/, $data;
    is $data[0], 'line 1';
    is $data[1], 'line 2';
  };

  do {
    my $data = '';
    open my $fh, '>', \$data;
    my $ret = eval { $client->retr('foo.txt', $fh)->recv; };
    diag $@ if $@;
    close $fh;
    isa_ok $ret, 'AnyEvent::FTP::Response';
    my @data = split /\015?\012/, $data;
    is $data[0], 'line 1';
    is $data[1], 'line 2';
  };

  $client->quit->recv;
}
