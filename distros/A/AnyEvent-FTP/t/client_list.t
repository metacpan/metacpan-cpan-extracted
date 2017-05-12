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
plan tests => 4;

our $config;
$config->{dir} = tempdir( CLEANUP => 1 );

foreach my $name (qw( foo bar baz ))
{
  my $fn = File::Spec->catfile($config->{dir}, "$name.txt");
  open my $fh, '>', $fn;
  close $fh;
}

my $dir2 = File::Spec->catdir($config->{dir}, "dir2");
mkdir $dir2;

foreach my $name (qw( dr.pepper coke pepsi ))
{
  my $fn = File::Spec->catfile($config->{dir}, 'dir2', "$name.txt");
  open my $fh, '>', $fn;
  close $fh;
}

foreach my $passive (0,1)
{

  my $client = AnyEvent::FTP::Client->new( passive => $passive );

  prep_client( $client );

  $client->connect($config->{host}, $config->{port})->recv;
  $client->login($config->{user}, $config->{pass})->recv;
  $client->type('I')->recv;
  $client->cwd($config->{dir})->recv;

  subtest 'listing with directory' => sub {
    plan tests => 6;
    my $list = eval { $client->list->recv };
    diag $@ if $@;
    isa_ok $list, 'ARRAY';
    $list //= [];
    # wu-ftpd
    shift @$list if $list->[0] =~ / \d+$/i;
    # Net::FTPServer
    shift @$list if $list->[0] =~ /\s\.$/;
    shift @$list if $list->[0] =~ /\s\.\.$/;
    is scalar(@$list), 4, 'list length 4';
    is scalar(grep /foo.txt$/, @$list), 1, 'has foo.txt';
    is scalar(grep /bar.txt$/, @$list), 1, 'has bar.txt';
    is scalar(grep /baz.txt$/, @$list), 1, 'has baz.txt';
    is scalar(grep /dir2$/, @$list), 1, 'has dir2';
    #note "list: $_" for @$list;
  };


  subtest 'listing in sub directory' => sub {
    plan tests => 5;
    my $list = eval { $client->list('dir2')->recv };
    diag $@ if $@;
    isa_ok $list, 'ARRAY';
    $list //= [];
    # wu-ftpd
    shift @$list if $list->[0] =~ / \d+$/i;
    # Net::FTPServer
    shift @$list if $list->[0] =~ /\s\.$/;
    shift @$list if $list->[0] =~ /\s\.\.$/;
    is scalar(@$list), 3, 'list length 3';
    is scalar(grep /dr.pepper.txt$/, @$list), 1, 'has dr.pepper.txt';
    is scalar(grep /coke.txt$/, @$list), 1, 'has coke.txt';
    is scalar(grep /pepsi.txt$/, @$list), 1, 'has pepsi.txt';
    #note "list: $_" for @$list;
  };

  $client->quit->recv;
}
