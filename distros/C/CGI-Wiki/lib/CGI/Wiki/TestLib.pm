package CGI::Wiki::TestLib;

use strict;
use Carp "croak";
use CGI::Wiki;
use CGI::Wiki::TestConfig;

use vars qw( $VERSION @wiki_info );
$VERSION = '0.03';

=head1 NAME

CGI::Wiki::TestLib - Utilities for writing CGI::Wiki tests.

=head1 DESCRIPTION

When 'perl Makefile.PL' is run on a CGI::Wiki distribution,
information will be gathered about test databases etc that can be used
for running tests. CGI::Wiki::TestLib gives convenient access to this
information.

=head1 SYNOPSIS

  use strict;
  use CGI::Wiki::TestLib;
  use Test::More;

  my $iterator = CGI::Wiki::TestLib->new_wiki_maker;
  plan tests => ( $iterator->number * 6 );

  while ( my $wiki = $iterator->new_wiki ) {
      # put some test data in
      # run six tests
  }

Each time you call C<< ->next >> on your iterator, you will get a
fresh blank wiki object. The iterator will iterate over all configured
search and storage backends.

=cut

my %configured = %CGI::Wiki::TestConfig::config;

my %datastore_info;
foreach my $dbtype (qw( MySQL Pg SQLite )) {
    if ( $configured{$dbtype}{dbname} ) {
        my %config = %{ $configured{$dbtype} };
	my $store_class = "CGI::Wiki::Store::$dbtype";
	my $setup_class = "CGI::Wiki::Setup::$dbtype";
        $datastore_info{$dbtype} = {
                                     class  => $store_class,
                                     setup_class => $setup_class,
                                     params => {
                                                 dbname => $config{dbname},
		       		                 dbuser => $config{dbuser},
				                 dbpass => $config{dbpass},
			                         dbhost => $config{dbhost},
                                               },
                                   };
    }
}

my %dbixfts_info;
# DBIxFTS only works with MySQL.
if ( $configured{dbixfts} && $configured{MySQL}{dbname} ) {
    my %config = %{ $configured{MySQL} };
    $dbixfts_info{MySQL} = {
                             db_params => {
                                            dbname => $config{dbname},
		       		            dbuser => $config{dbuser},
				            dbpass => $config{dbpass},
			                    dbhost => $config{dbhost},
                                          },
                           };
}

my %sii_info;
# Test the MySQL SII backend, if we can.
if ( $configured{search_invertedindex} && $configured{MySQL}{dbname} ) {
    my %config = %{ $configured{MySQL} };
    $sii_info{MySQL} = {
                         db_class  => "Search::InvertedIndex::DB::Mysql",
                         db_params => {
                                        -db_name    => $config{dbname},
                                        -username   => $config{dbuser},
                                        -password   => $config{dbpass},
	   	                        -hostname   => $config{dbhost} || "",
                                        -table_name => 'siindex',
                                        -lock_mode  => 'EX',
                                      },
                       };
}

# Test the Pg SII backend, if we can.  It's not in the main S::II package.
eval { require Search::InvertedIndex::DB::Pg; };
my $sii_pg = $@ ? 0 : 1;
if (    $configured{search_invertedindex}
     && $configured{Pg}{dbname}
     && $sii_pg
   ) {
    my %config = %{ $configured{Pg} };
    $sii_info{Pg} = {
                      db_class  => "Search::InvertedIndex::DB::Pg",
                      db_params => {
                                     -db_name    => $config{dbname},
                                     -username   => $config{dbuser},
                                     -password   => $config{dbpass},
	   	                     -hostname   => $config{dbhost},
                                     -table_name => 'siindex',
                                     -lock_mode  => 'EX',
                                   },
                    };
}

# Also test the default DB_File backend, if we have S::II installed at all.
if ( $configured{search_invertedindex} ) {
    $sii_info{DB_File} = {
                  db_class  => "Search::InvertedIndex::DB::DB_File_SplitHash",
                  db_params => {
                                 -map_name  => 't/sii-db-file-test.db',
                                 -lock_mode  => 'EX',
                               },
                         };
}

my $plucene_path;
# Test with Plucene if possible.
if ( $configured{plucene} ) {
    $plucene_path = "t/plucene";
}

# @wiki_info describes which searches work with which stores.

# Database-specific searchers.
push @wiki_info, { datastore_info => $datastore_info{MySQL},
                   dbixfts_info   => $dbixfts_info{MySQL} }
  if ( $datastore_info{MySQL} and $dbixfts_info{MySQL} );
push @wiki_info, { datastore_info => $datastore_info{MySQL},
                   sii_info       => $sii_info{MySQL} }
  if ( $datastore_info{MySQL} and $sii_info{MySQL} );
push @wiki_info, { datastore_info => $datastore_info{Pg},
                   sii_info       => $sii_info{Pg} }
  if ( $datastore_info{Pg} and $sii_info{Pg} );

# All stores are compatible with the default S::II search, and with Plucene,
# and with no search.
foreach my $dbtype ( qw( MySQL Pg SQLite ) ) {
    push @wiki_info, { datastore_info => $datastore_info{$dbtype},
                       sii_info       => $sii_info{DB_File} }
      if ( $datastore_info{$dbtype} and $sii_info{DB_File} );
    push @wiki_info, { datastore_info => $datastore_info{$dbtype},
                       plucene_path   => $plucene_path }
      if ( $datastore_info{$dbtype} and $plucene_path );
    push @wiki_info, { datastore_info => $datastore_info{$dbtype} }
      if $datastore_info{$dbtype};
}

=head1 METHODS

=over 4

=item B<new_wiki_maker>

  my $iterator = CGI::Wiki::TestLib->new_wiki_maker;
  while ( my $wiki = $iterator->new_wiki ) {
      # put some test data in
      # run some tests
  }

Each time you call C<< ->new_wiki >> on your iterator, you will get a
fresh blank wiki object. The iterator will iterate over all configured
search and storage backends.

=cut

sub new_wiki_maker {
    my $class = shift;
    my $count = 0;
    my $iterator = \$count;
    bless $iterator, $class;
    return $iterator;
}

=item B<number>

  use Test::More;
  my $iterator = CGI::Wiki::TestLib->new_wiki_maker;
  plan tests => ( $iterator->number * 6 );

Returns the number of new wikis that your iterator will be able to give you.

=cut

sub number {
    return scalar @wiki_info;
}

sub new_wiki {
    my $self = shift;
    return undef if $$self > $#wiki_info;
    my $details = $wiki_info[$$self];
    my %wiki_config;

    # Set up and clear datastore.
    my %datastore_info = %{ $details->{datastore_info } };
    my $setup_class =  $datastore_info{setup_class};
    eval "require $setup_class";
    {
      no strict "refs";
      &{"$setup_class\:\:cleardb"}( $datastore_info{params} );
      &{"$setup_class\:\:setup"}( $datastore_info{params} );
    }
    my $class =  $datastore_info{class};
    eval "require $class";
    $wiki_config{store} = $class->new( %{ $datastore_info{params} } );

    # Set up and clear search object (if required).
    if ( $details->{dbixfts_info} ) {
        my %fts_info = %{ $details->{dbixfts_info} };
        require CGI::Wiki::Store::MySQL;
        my %dbconfig = %{ $fts_info{db_params} };
        my $dsn = CGI::Wiki::Store::MySQL->_dsn( $dbconfig{dbname},
                                                 $dbconfig{dbhost}  );
        my $dbh = DBI->connect( $dsn, $dbconfig{dbuser}, $dbconfig{dbpass},
                       { PrintError => 0, RaiseError => 1, AutoCommit => 1 } )
          or croak "Can't connect to $dbconfig{dbname} using $dsn: " . DBI->errstr;
        require CGI::Wiki::Setup::DBIxFTSMySQL;
        CGI::Wiki::Setup::DBIxFTSMySQL::setup(
                                 @dbconfig{ qw( dbuser dbname dbpass dbhost ) }
                                             );
        require CGI::Wiki::Search::DBIxFTS;
        $wiki_config{search} = CGI::Wiki::Search::DBIxFTS->new( dbh => $dbh );
    } elsif ( $details->{sii_info} ) {
        my %sii_info = %{ $details->{sii_info} };
        my $db_class = $sii_info{db_class};
        eval "use $db_class";
        my %db_params = %{ $sii_info{db_params} };
        my $indexdb = $db_class->new( %db_params );
        require CGI::Wiki::Setup::SII;
        CGI::Wiki::Setup::SII::setup( indexdb => $indexdb );
        $wiki_config{search} = CGI::Wiki::Search::SII->new(indexdb =>$indexdb);
    } elsif ( $details->{plucene_path} ) {
        require CGI::Wiki::Search::Plucene;
        my $dir = $details->{plucene_path};
        unlink <$dir/*>; # don't die if false since there may be no files
        if ( -d $dir ) {
            rmdir $dir or die $!;
	}
        mkdir $dir or die $!;
        $wiki_config{search} = CGI::Wiki::Search::Plucene->new( path => $dir );
    }

    # Make a wiki.
    my $wiki = CGI::Wiki->new( %wiki_config );
    $$self++;
    return $wiki;
}

=back

=head1 SEE ALSO

L<CGI::Wiki>

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003-2004 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CAVEATS

If you have the L<Search::InvertedIndex> backend configured (see
L<CGI::Wiki::Search::SII>) then your tests will raise warnings like

  (in cleanup) Search::InvertedIndex::DB::Mysql::lock() -
    testdb is not open. Can't lock.
  at /usr/local/share/perl/5.6.1/Search/InvertedIndex.pm line 1348

or

  (in cleanup) Can't call method "sync" on an undefined value
    at /usr/local/share/perl/5.6.1/Tie/DB_File/SplitHash.pm line 331
    during global destruction.

in unexpected places. I don't know whether this is a bug in me or in
L<Search::InvertedIndex>.

=cut

1;
