#!/usr/bin/perl -w
use strict;
use FindBin;
use File::Spec;
use CGI::Wiki::TestConfig;

my @tests;
BEGIN {
  @tests = grep {     defined $CGI::Wiki::TestConfig::config{$_}
                  and ref $CGI::Wiki::TestConfig::config{$_} eq "HASH"
                  and defined $CGI::Wiki::TestConfig::config{$_}->{dbname}
                } sort keys %CGI::Wiki::TestConfig::config;
};

use Test::More tests => 2 + 12*scalar @tests;

BEGIN {
  use_ok( "CGI::Wiki" );
  use_ok( "CGI::Wiki::Simple::Setup" );
};

use vars qw(%dbargs);

SKIP: {
  skip "Need a database to test CGI interaction", 12*scalar @tests
    unless $CGI::Wiki::TestConfig::configured;

  for my $dbtype (@tests) {
    %dbargs = %{$CGI::Wiki::TestConfig::config{$dbtype}};
    $dbargs{dbtype} = $dbtype;

    sub one_connection(&) {
      my $store = CGI::Wiki::Simple::Setup::get_store( %dbargs );
      isa_ok( $store, 'CGI::Wiki::Store::Database' );
      my $wiki = CGI::Wiki->new( store => $store, search => undef );

      shift->($store,$wiki);

      undef $wiki;
      $store->dbh->disconnect;
    };

		my (@nodes,$nodes);

    CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, nocontent => 1, silent => 1 );
		one_connection { $nodes = $_[1]->store->dbh->selectall_arrayref("select * from content")};
		is_deeply($nodes, [], "$dbtype: Setup an empty database");

    CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, silent => 1 );
		one_connection { @nodes = sort $_[1]->list_all_nodes };
		cmp_ok(scalar @nodes, '>', 0, "$dbtype: Stored some initial nodes");
		my @initial_nodes = @nodes;

		one_connection {
		  CGI::Wiki::Simple::Setup::commit_content( wiki => $_[1], silent => 1,
		    nodes => [ { title => '__non_existing_test_node', content => "Created by $0"} ] );
		  @nodes = sort $_[1]->list_all_nodes;
		};
		is(scalar @nodes, scalar @initial_nodes+1, "$dbtype: Stored one additional node")
		  or do { diag "Expected :",@nodes; diag "Got :", @nodes };

		{
		  my $warned;
		  local $SIG{__WARN__} = sub { $warned++ };
		  CGI::Wiki::Simple::Setup::setup( %dbargs, force => 0, silent => 1 );
		  is($warned, scalar @initial_nodes, "$dbtype: We warn instead of overwriting existing nodes");
		};

    my @last_nodes = @nodes;
		one_connection { @nodes = sort $_[1]->list_all_nodes;	};
		is_deeply(\@nodes, \@last_nodes, "Node count stays the same");

		CGI::Wiki::Simple::Setup::setup( %dbargs, clear => 1, silent => 1 );
		one_connection { $nodes = $_[1]->store->dbh->selectall_arrayref("select * from content")};
		isnt($nodes, undef, "Got a valid result for clear");
		@nodes = sort map { $_->[0] } @$nodes;
		is_deeply(\@nodes, \@initial_nodes, "$dbtype: Setup an empty database");
	};
};
