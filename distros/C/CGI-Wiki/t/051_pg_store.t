use strict;
use CGI::Wiki;
use CGI::Wiki::Store::Pg;
use CGI::Wiki::Setup::Pg;
use CGI::Wiki::TestConfig;
use Test::More tests => 9;

my $class = "CGI::Wiki::Store::Pg";

eval { $class->new; };
ok( $@, "Failed creation dies" );

my %config = %{$CGI::Wiki::TestConfig::config{Pg}};
my ($dbname, $dbuser, $dbpass, $dbhost) = @config{qw(dbname dbuser dbpass dbhost)};

SKIP: {
    skip "No Postgres database configured for testing", 8 unless $dbname;

    {
      my $store = eval { $class->new( dbname => $dbname,
                                      dbuser => $dbuser,
                                      dbpass => $dbpass,
                                      dbhost => $dbhost );
                       };
      is( $@, "", "Creation doesn't die when given connection params" );
      isa_ok( $store, $class );
      ok( $store->dbh, "...and has set up a database handle" );
    }

    {
      my $dsn = "dbi:Pg:dbname=$dbname";
      $dsn .= ";host=$dbhost" if $dbhost;
      my $dbh = DBI->connect( $dsn, $dbuser, $dbpass );
      my $store = eval { $class->new( dbh => $dbh ); };
      is( $@, "", "Creation doesn't die when given a dbh" );
      isa_ok( $store, $class );
      ok( $store->dbh, "...and we can retrieve the database handle" );
      $dbh->disconnect;
    }

    CGI::Wiki::Setup::Pg::cleardb({ dbname => $dbname,
                                    dbuser => $dbuser,
                                    dbpass => $dbpass,
                                    dbhost => $dbhost });
    CGI::Wiki::Setup::Pg::setup({ dbname => $dbname,
                                  dbuser => $dbuser,
                                  dbpass => $dbpass,
                                  dbhost => $dbhost });

    SKIP: {
        eval { require Hook::LexWrap; require Test::MockObject; };
        skip "either Hook::LexWrap or Test::MockObject not installed", 2 if $@;

        my $store = $class->new( dbname => $dbname,
                                 dbuser => $dbuser,
                                 dbpass => $dbpass,
                                 dbhost => $dbhost );
        my $wiki = CGI::Wiki->new( store => $store );

        # Write some test data.
        $wiki->write_node( "Home", "This is the home node." )
          or die "Couldn't setup";

        # White box testing - override verify_node_checksum to first verify the
        # checksum and then if it's OK set up a new wiki object that sneakily
        # writes to the node before letting us have control back.
        my $temp;
        $temp = Hook::LexWrap::wrap( # fully qualify since we're requiring
            'CGI::Wiki::Store::Database::verify_checksum',
            post => sub {
                undef $temp; # Don't want to wrap our sneaking-in
                my $node = $_[1];
                my $evil_store = $class->new( dbname => $dbname,
                                              dbuser => $dbuser,
                                              dbpass => $dbpass,
                                              dbhost => $dbhost );
                my $evil_wiki = CGI::Wiki->new( store => $evil_store );
                my %node_data = $evil_wiki->retrieve_node($node);
                $evil_wiki->write_node($node, "foo", $node_data{checksum})
                    or die "Evil wiki got conflict on writing";
        } );

        # Now try to write to a node -- it should fail.
        my %node_data = $wiki->retrieve_node("Home");
        ok( ! $wiki->write_node("Home", "bar", $node_data{checksum}),
            "write_node handles overlapping write attempts correctly" );

        # Check actual real database errors croak rather than flagging conflict
        %node_data = $wiki->retrieve_node("Home");
        my $dbh = $store->dbh;
        $dbh->disconnect;
        # Mock a database handle.  Need to mock rollback() and disconnect()
        # as well to avoid warnings that an unmocked method has been called
        # (we don't actually care).
        my $fake_dbh = Test::MockObject->new();
        $fake_dbh->mock("do", sub { die "Dave told us to"; });
        $fake_dbh->set_true("rollback");
        $fake_dbh->set_true("disconnect");
        $store->{_dbh} = $fake_dbh;
        eval {
            $store->check_and_write_node( node     => "Home",
                                          content  => "This is a node.",
                                          checksum => $node_data{checksum} );
        };
        ok( $@ =~ /Dave told us to/, "...and croaks on database error" );
    }
}
