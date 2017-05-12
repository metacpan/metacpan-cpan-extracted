package DBI::Test::Case::basic::prepare;

use strict;
use warnings;

use parent qw(DBI::Test::Case);

use Test::More;

sub run_test
{
    my @DB_CREDS = @{ $_[1] };
    my %SQLS = (
                 'SELECT' => 'SELECT 1+1',
                 'INSERT' => undef
               );

    {    #Basic test
        my $dbh = DBI->connect(@DB_CREDS);
        isa_ok( $dbh, 'DBI::db' );

        my $sth;
        eval { $sth = $dbh->prepare( $SQLS{SELECT} ); };
        ok( !$@, "Prepared query" );
      SKIP:
        {
            skip "Could not prepare query", 1 if !$sth;
            isa_ok( $sth, 'DBI::st' );
        }
    }

    {    #Prepare should fail

      TODO:
        {
            local $TODO = "Must have an API to make prepare fail";
            my $dbh = DBI->connect( @DB_CREDS[ 0 .. 2 ], {} );
            isa_ok( $dbh, 'DBI::db' );

            #Do something so that prepare fails

            my $sth = $dbh->prepare( $SQLS{SELECT} );
            ok( !$sth, "Prepared failed" );
            #Check that $DBI::err && $DBI::errstr is set
            #It should be set after a failed call
            ok( $DBI::err,    '$DBI::err is set' );
            ok( $DBI::errstr, '$DBI::errstr is set' );
        }
    }

    {    #Prepare should print a warning if PrintError is set

      TODO:
        {
            local $TODO = "Must have an API to make prepare fail";
            my $dbh = DBI->connect( @DB_CREDS[ 0 .. 2 ], { PrintError => 1 } );
            isa_ok( $dbh, 'DBI::db' );

            my $warnings = 0;

            #Make sure we fetch the local
            local $SIG{__WARN__} = sub {
                $warnings++;    #TODO : Must be the correct warning
            };

            #Do something so that prepare fails

            my $sth = $dbh->prepare( $SQLS{SELECT} );
            ok( !$sth, "prepare failed" );
            cmp_ok( $warnings, '>', 0, "Recorded a warning" );
        }
    }
    {                           #Prepare should die if RaiseError is set

      TODO:
        {
            local $TODO = "Must have an API to make prepare fail";
            my $dbh = DBI->connect( @DB_CREDS[ 0 .. 2 ], { RaiseError => 1 } );
            isa_ok( $dbh, 'DBI::db' );

            #Do something so that prepare fails

            my $sth;
            eval { $sth = $dbh->prepare( $SQLS{SELECT} ); };
            ok( $@,    "prepare died" );
            ok( !$sth, 'sth is undef' );
        }
    }

    done_testing();
}

1;
