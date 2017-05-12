package CGI::Wiki::TestConfig::Utilities;

use strict;

use CGI::Wiki::TestConfig;

use vars qw( $num_stores $num_combinations $VERSION );
$VERSION = '0.06';

=head1 NAME

CGI::Wiki::TestConfig::Utilities - Utilities for testing CGI::Wiki things (deprecated).

=head1 DESCRIPTION

Deprecated - use L<CGI::Wiki::TestLib> instead.

=cut

my %stores;

foreach my $dbtype (qw( MySQL Pg SQLite )) {
    if ($CGI::Wiki::TestConfig::config{$dbtype}->{dbname}) {
        my %config = %{$CGI::Wiki::TestConfig::config{$dbtype}};
	my $store_class = "CGI::Wiki::Store::$dbtype";
	eval "require $store_class";
	my $store = $store_class->new( dbname => $config{dbname},
				       dbuser => $config{dbuser},
				       dbpass => $config{dbpass},
				       dbhost => $config{dbhost} );
	$stores{$dbtype} = $store;
    } else {
	$stores{$dbtype} = undef;
    }
}

$num_stores = scalar keys %stores;

my %searches;

# DBIxFTS only works with MySQL.
if ( $CGI::Wiki::TestConfig::config{dbixfts} && $stores{MySQL} ) {
    require CGI::Wiki::Search::DBIxFTS;
    my $dbh = $stores{MySQL}->dbh;
    $searches{DBIxFTSMySQL} = CGI::Wiki::Search::DBIxFTS->new( dbh => $dbh );
} else {
    $searches{DBIxFTSMySQL} = undef;
}

# Test the MySQL SII backend, if we can.
if ( $CGI::Wiki::TestConfig::config{search_invertedindex} && $stores{MySQL} ) {
    require Search::InvertedIndex::DB::Mysql;
    require CGI::Wiki::Search::SII;
    my %dbconfig = %{$CGI::Wiki::TestConfig::config{MySQL}};
    my $indexdb = Search::InvertedIndex::DB::Mysql->new(
                       -db_name    => $dbconfig{dbname},
                       -username   => $dbconfig{dbuser},
                       -password   => $dbconfig{dbpass},
	   	       -hostname   => $dbconfig{dbhost} || "",
                       -table_name => 'siindex',
                       -lock_mode  => 'EX' );
    $searches{SIIMySQL} = CGI::Wiki::Search::SII->new( indexdb => $indexdb );
} else {
    $searches{SIIMySQL} = undef;
}

# Test the Pg SII backend, if we can.
eval { require Search::InvertedIndex::DB::Pg; };
my $sii_pg = $@ ? 0 : 1;
if ( $CGI::Wiki::TestConfig::config{search_invertedindex} && $stores{Pg}
     && $sii_pg ) {
    require Search::InvertedIndex::DB::Pg;
    require CGI::Wiki::Search::SII;
    my %dbconfig = %{$CGI::Wiki::TestConfig::config{Pg}};
    my $indexdb = Search::InvertedIndex::DB::Pg->new(
                       -db_name    => $dbconfig{dbname},
                       -username   => $dbconfig{dbuser},
                       -password   => $dbconfig{dbpass},
	   	       -hostname   => $dbconfig{dbhost},
                       -table_name => 'siindex',
                       -lock_mode  => 'EX' );
    $searches{SIIPg} = CGI::Wiki::Search::SII->new( indexdb => $indexdb );
} else {
    $searches{SIIPg} = undef;
}

# Also test the default DB_File backend, if we have S::II installed at all.
if ( $CGI::Wiki::TestConfig::config{search_invertedindex} ) {
    require Search::InvertedIndex;
    require CGI::Wiki::Search::SII;
    my $indexdb = Search::InvertedIndex::DB::DB_File_SplitHash->new(
                       -map_name  => 't/sii-db-file-test.db',
                       -lock_mode  => 'EX' );
    $searches{SII} = CGI::Wiki::Search::SII->new( indexdb => $indexdb );
} else {
    $searches{SII} = undef;
}

my @combinations; # which searches work with which stores.
push @combinations, { store_name  => "MySQL",
		      store       => $stores{MySQL},
		      search_name => "DBIxFTSMySQL",
		      search      => $searches{DBIxFTSMySQL} };
push @combinations, { store_name  => "MySQL",
		      store       => $stores{MySQL},
		      search_name => "SIIMySQL",
		      search      => $searches{SIIMySQL} };
push @combinations, { store_name  => "Pg",
		      store       => $stores{Pg},
		      search_name => "SIIPg",
		      search      => $searches{SIIPg} };

# All stores are compatible with the default S::II search, and with no search.
foreach my $store_name ( keys %stores ) {
    push @combinations, { store_name  => $store_name,
			  store       => $stores{$store_name},
			  search_name => "SII",
			  search      => $searches{SII} };
    push @combinations, { store_name  => $store_name,
			  store       => $stores{$store_name},
			  search_name => "undef",
			  search      => undef };
}

foreach my $comb ( @combinations ) {
    # There must be a store configured for us to test, but a search is optional
    $comb->{configured} = $comb->{store} ? 1 : 0;
}

$num_combinations = scalar @combinations;

sub reinitialise_stores {
    my $class = shift;
    my %stores = $class->stores;

    my ($store_name, $store);
    while ( ($store_name, $store) = each %stores ) {
        next unless $store;

        my $dbname = $store->dbname;
        my $dbuser = $store->dbuser;
        my $dbpass = $store->dbpass;
        my $dbhost = $store->dbhost;

        # Clear out the test database, then set up tables afresh.
        my $setup_class = "CGI::Wiki::Setup::$store_name";
        eval "require $setup_class";
        {
          no strict "refs";
          &{"$setup_class\:\:cleardb"}($dbname, $dbuser, $dbpass, $dbhost);
          &{"$setup_class\:\:setup"}($dbname, $dbuser, $dbpass, $dbhost);
        }
    }
}

sub stores {
    return %stores;
}

sub combinations {
    return @combinations;
}

=head1 SEE ALSO

L<CGI::Wiki::TestLib>, the replacement for this module.

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
