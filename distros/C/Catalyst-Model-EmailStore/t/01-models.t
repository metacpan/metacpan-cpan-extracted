#!/usr/bin/perl
use strict;
use warnings;
use lib './t/lib';

use Test::More;

our $tmp;

BEGIN {
  eval{ require DBD::SQLite; };
  plan skip_all => "Can't use DBD::SQLite"  if $@;

  use File::Temp qw//;
  $tmp = File::Temp->new
	 ( TEMPLATE => 'tempXXXXX', DIR => File::Spec->tmpdir(), SUFFIX => '.db');
  my $dbfile = $tmp->filename;
  diag( "Using dbfile: $dbfile" );

  # prepare the email store database
  system 'perl', '-e', "use Email::Store 'dbi:SQLite:${dbfile}';",
	 '-e', 'Email::Store->setup(0)';

  require TestApp::Model::EmailStore;
  TestApp::Model::EmailStore->config->{dsn} = "dbi:SQLite:${dbfile}";
}

package TestApp;

use Catalyst qw[-Engine=Test];

__PACKAGE__->config( name => qw/TestApp/, home => './t/' );
__PACKAGE__->setup();

package main;

require Catalyst::Test;
Catalyst::Test->import( qw/TestApp/ );

my @components = grep{ ref($_) =~ /^TestApp::Model::EmailStore::/ }
  values %{ TestApp->components };

# now we finally know how much to test
plan tests => ( 4 * scalar @components ) + 2;

my $m = TestApp->model( 'EmailStore' );
isa_ok( $m, qw/Catalyst::Model::EmailStore/ );
ok( scalar(@components) >= 9, 'At least the min amount of components loaded' );

foreach ( @components ) {
  isa_ok( $_, 'Email::Store::DBI' );
  isa_ok( $_, 'TestApp::Model::EmailStore' );
  my $provides = ref $_;
  $provides =~ s/^TestApp::Model::EmailStore/Email::Store/;
  isa_ok( $_, $provides );
  my $model = ref $_;
  $model =~ s/^TestApp::Model:://;

  # is will call stringify by default which is not what we want here
  is( ref( TestApp->model( $model )), ( ref($_) || 'No referece!' ),
		"Model $model is known to Catalyst" );
}

END {
  unlink './t/test.db';
}
