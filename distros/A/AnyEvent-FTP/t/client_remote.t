use strict;
use warnings;
use 5.010;
use Test::More tests => 58;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use File::Temp qw( tempdir );
use File::Spec;
use FindBin ();
require "$FindBin::Bin/lib.pl";

$ENV{AEF_REMOTE} //= tempdir( CLEANUP => 1 );

our $config;
our $detect;

foreach my $passive (0,1)
{

  my $client = AnyEvent::FTP::Client->new( passive => $passive );

  prep_client( $client );

  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;

  isa_ok $client->cwd($ENV{AEF_REMOTE})->recv, 'AnyEvent::FTP::Response';
  
  do {
    my $dir = $client->pwd->recv;
    is $dir, net_pwd($ENV{AEF_REMOTE}), "dir = " .net_pwd($ENV{AEF_REMOTE});
  };

  my $dirname = join '', map { chr(ord('a') + int(rand(23))) } (1..10);
  
  isa_ok $client->mkd($dirname)->recv, 'AnyEvent::FTP::Response';
  isa_ok $client->cwd($dirname)->recv, 'AnyEvent::FTP::Response';

  SKIP: {
    skip 'wu-ftpd throws an exception on empty directory', 2 if $detect->{wu};
    my $res = $client->nlst->recv;
    isa_ok $res, 'ARRAY';
    is scalar(@$res), 0, 'list empty';
    if(scalar(@$res) > 0)
    {
      diag "~~~ nlst ~~~";
      diag $_ for @$res;
      diag "~~~~~~~~~~~~";
    }
  };
  
  isa_ok $client->stor('foo.txt', \"here is some data eh\n")->recv, 'AnyEvent::FTP::Response';
  
  do {
    my $res = $client->nlst->recv;
    isa_ok $res, 'ARRAY';
    is scalar(@$res), 1, 'list not empty';
    is $res->[0], 'foo.txt';
  };
  
  do {
    my $res = $client->list->recv;
    isa_ok $res, 'ARRAY';
    is scalar(grep /foo.txt$/, @$res), 1, 'has foo.txt in listing';
  };
  
  do {
    my $data = '';
    isa_ok $client->retr('foo.txt', \$data)->recv, 'AnyEvent::FTP::Response';
    is $data, "here is some data eh\n", 'retr ok';
  };

  isa_ok $client->appe('foo.txt', \"line 2\n")->recv, 'AnyEvent::FTP::Response';

  do {
    my $data = '';
    isa_ok $client->retr('foo.txt', \$data)->recv, 'AnyEvent::FTP::Response';
    is $data, "here is some data eh\nline 2\n", 'retr ok';
  };

  isa_ok $client->rename('foo.txt', 'bar.txt')->recv, 'AnyEvent::FTP::Response';

  do {
    my $res = $client->nlst->recv;
    isa_ok $res, 'ARRAY';
    is scalar(@$res), 1, 'list not empty';
    is $res->[0], 'bar.txt';
  };
  
  do {
    my $res = $client->list->recv;
    isa_ok $res, 'ARRAY';
    is scalar(grep /bar.txt$/, @$res), 1, 'has bar.txt in listing';
  };

  do {
    my $data = "here is some data";
    isa_ok $client->retr('bar.txt', \$data, restart => do { use bytes; length $data})->recv, 'AnyEvent::FTP::Response';
    is $data, "here is some data eh\nline 2\n", 'rest, retr ok';
  };

  isa_ok $client->dele('bar.txt')->recv, 'AnyEvent::FTP::Response';

  # ...  
  
  isa_ok $client->cdup->recv, 'AnyEvent::FTP::Response';
  isa_ok $client->rmd($dirname)->recv, 'AnyEvent::FTP::Response';
  isa_ok $client->quit->recv, 'AnyEvent::FTP::Response';
}

