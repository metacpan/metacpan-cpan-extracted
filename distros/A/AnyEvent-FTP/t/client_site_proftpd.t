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

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

my $client = AnyEvent::FTP::Client->new;

prep_client( $client );

eval {
  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;
  our $detect;
  unless($detect->{pr})
  {
    $client->quit->recv;
    die "not ProFTPd" unless $detect->{pr};
  }
};
plan skip_all => 'requires Proftpd to test against' if $@;
plan tests => 6;

do {
  my $dir_name = File::Spec->catdir($config->{dir}, 'foo');
  
  do {
    my $res = eval { $client->site->proftpd->mkdir('foo')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
  };

  ok -d $dir_name, "dir foo created";
  
  do {
    my $res = eval { $client->site->proftpd->rmdir('foo')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
  };

  ok !-d $dir_name, "dir foo deleted";
};

do {
  do {
    open(my $fh, '>', File::Spec->catfile($config->{dir}, 'target'));
    close $fh;
  };
  
  do {
    my $res = eval { $client->site->proftpd->symlink('target', 'link')->recv };
    diag $@ if $@;
    isa_ok $res, 'AnyEvent::FTP::Response';
  };
  
  like readlink(File::Spec->catfile($config->{dir}, 'link')), qr{target$}, "link => target";
  
};
  
$client->quit->recv;
