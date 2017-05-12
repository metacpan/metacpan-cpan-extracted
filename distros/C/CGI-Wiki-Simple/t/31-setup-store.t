#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec;
use Carp qw( croak );
use CGI::Wiki::TestConfig;
use CGI::Wiki::TestConfig::Utilities;

use Test::More tests => 2 + 12* $CGI::Wiki::TestConfig::Utilities::num_stores;

BEGIN {
  use_ok( "CGI::Wiki" );
  use_ok( "CGI::Wiki::Simple::Setup" );
};

use vars qw( %dbargs );

SKIP: {
  skip "Database tests not configured", 12*$CGI::Wiki::TestConfig::Utilities::num_stores
    unless $CGI::Wiki::TestConfig::configured;

  my %stores = CGI::Wiki::TestConfig::Utilities->stores;

  my ($storename,$store);
  while (($storename,$store) = each %stores) {

    SKIP: {
      skip "Store $storename not configured for testing", 12
        unless $store;

      # We need to dispose of that store, but we'll steal the parameters :
      $dbargs{$_} = $store->$_ for (qw(dbname dbuser dbpass));

      my $storename = ref $store;
      $storename =~ m!^CGI::Wiki::Store::(.+)!
        or croak "Unknown wiki store subclass $storename";
      $dbargs{dbtype} = $1;

      $store->dbh->disconnect;
      undef $store;

      sub one_connection(&) {
        my $store = CGI::Wiki::Simple::Setup::get_store( %dbargs );
        isa_ok( $store, 'CGI::Wiki::Store::Database' );
        my $wiki = CGI::Wiki->new( store => $store, search => undef );
        shift->($store,$wiki);
        undef $wiki;
      };

      my (@nodes,$nodes);

      CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, nocontent => 1, silent => 1 );
      one_connection { $nodes = $_[1]->store->dbh->selectall_arrayref("select * from content")};
      is_deeply($nodes, [], "$storename: Setup an empty database");

      CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, silent => 1 );
      one_connection { @nodes = sort $_[1]->list_all_nodes };
      cmp_ok(scalar @nodes, '>', 0, "$storename: Stored some initial nodes");
      my @initial_nodes = @nodes;

      one_connection {
        CGI::Wiki::Simple::Setup::commit_content( wiki => $_[1], silent => 1,
          nodes => [ { title => '__non_existing_test_node', content => "Created by $0"} ] );
        @nodes = sort $_[1]->list_all_nodes;
      };
      is(scalar @nodes, scalar @initial_nodes+1, "$storename: Stored one additional node")
        or do { diag "Expected :",@nodes; diag "Got :", @nodes };

      {
        my $warned;
        local $SIG{__WARN__} = sub { $warned++ };
        CGI::Wiki::Simple::Setup::setup( %dbargs, force => 0, silent => 1 );
        is($warned, scalar @initial_nodes, "$storename: We warn instead of overwriting existing nodes");
      };

      my @last_nodes = @nodes;
      one_connection { @nodes = sort $_[1]->list_all_nodes; };
      is_deeply(\@nodes, \@last_nodes, "Node count stays the same");

      CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, silent => 1 );
      one_connection { $nodes = $_[1]->store->dbh->selectall_arrayref("select * from content")};
      isnt($nodes, undef, "Got a valid result for clear");
      @nodes = sort map { $_->[0] } @$nodes;
      is_deeply(\@nodes, \@initial_nodes, "$storename: Setup an empty database");
    };
	};
};
