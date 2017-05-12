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
plan tests => 8;

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

  do {
    my $list = eval { $client->nlst->recv };
    diag $@ if $@;
    isa_ok $list, 'ARRAY';
    $list //= [];
    @$list = grep !/^dir2$/, @$list;
    is_deeply [ sort @$list ], [ sort qw( foo.txt bar.txt baz.txt ) ], 'nlst 1';
    #note 'actual:   ' . join(' ', sort @$list);
    #note 'expected: ' . join(' ', sort qw( foo.txt bar.txt baz.txt ));
  };

  do {
    my $list = eval { $client->nlst('dir2')->recv };
    diag $@ if $@;
    isa_ok $list, 'ARRAY';
    $list //= [];
    our $detect;
    # workaround here for Net::FTPServer and pure-ftpd, unlike other wu,vs and pro ftpd does not include the path name
    is_deeply [ sort @$list ], [ sort map { $detect->{pl} || $detect->{pu} || $detect->{xb} ? "$_.txt" : "dir2/$_.txt" } qw( dr.pepper coke pepsi ) ], 'nlst 1';
    #note "list: $_" for @$list;
  };

  $client->quit->recv;
}
