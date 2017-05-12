use strict;
use CGI::Wiki;
use CGI::Wiki::TestLib;
use Test::More tests => ( 1 + 3 * scalar @CGI::Wiki::TestLib::wiki_info );

# Test failed creation.  Note this has a few tests missing.
eval { CGI::Wiki->new; };
ok( $@, "Creation dies if no store supplied" );

# Test successful creation, for each configured store/search combination.
my @wiki_info = @CGI::Wiki::TestLib::wiki_info;

foreach my $infoid ( @wiki_info ) {
    my %wiki_config;

    # Test store instantiation.
    my %datastore_info = %{ $infoid->{datastore_info } };
    my $class =  $datastore_info{class};
    eval "require $class";
    my $store = $class->new( %{ $datastore_info{params} } );
    isa_ok( $store, $class );
    $wiki_config{store} = $store;

    # Test search instantiation.
    SKIP: {
        skip "No search configured for this combination", 1
          unless ($infoid->{dbixfts_info} or $infoid->{sii_info}
                  or $infoid->{plucene_path} );
        if ( $infoid->{dbixfts_info} ) {
            my %fts_info = %{ $infoid->{dbixfts_info} };
            require CGI::Wiki::Store::MySQL;
            my %dbconfig = %{ $fts_info{db_params} };
            my $dsn = CGI::Wiki::Store::MySQL->_dsn( $dbconfig{dbname},
                                                     $dbconfig{dbhost}  );
            my $dbh = DBI->connect( $dsn, $dbconfig{dbuser}, $dbconfig{dbpass},
                       { PrintError => 0, RaiseError => 1, AutoCommit => 1 } )
              or die "Can't connect to $dbconfig{dbname} using $dsn: "
                        . DBI->errstr;
            require CGI::Wiki::Search::DBIxFTS;
            my $search = CGI::Wiki::Search::DBIxFTS->new( dbh => $dbh );
            isa_ok( $search, "CGI::Wiki::Search::DBIxFTS" );
            $wiki_config{search} = $search;
        } elsif ( $infoid->{sii_info} ) {
            my %sii_info = %{ $infoid->{sii_info} };
            my $db_class = $sii_info{db_class};
            my %db_params = %{ $sii_info{db_params} };
            eval "require $db_class";
            my $indexdb = $db_class->new( %db_params );
            require CGI::Wiki::Search::SII;
            my $search = CGI::Wiki::Search::SII->new(indexdb =>$indexdb);
            isa_ok( $search, "CGI::Wiki::Search::SII" );
            $wiki_config{search} = $search;
        } elsif ( $infoid->{plucene_path} ) {
            require CGI::Wiki::Search::Plucene;
            my $search = CGI::Wiki::Search::Plucene->new( path => $infoid->{plucene_path} );
            isa_ok( $search, "CGI::Wiki::Search::Plucene" );
            $wiki_config{search} = $search;
        }
    } # end of SKIP for no search

    # Test wiki instantiation.
    my $wiki = CGI::Wiki->new( %wiki_config );
    isa_ok( $wiki, "CGI::Wiki" );

}
