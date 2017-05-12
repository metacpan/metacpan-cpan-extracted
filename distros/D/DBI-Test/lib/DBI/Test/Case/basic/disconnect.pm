package DBI::Test::Case::basic::disconnect;

use strict;
use warnings;

use parent qw(DBI::Test::Case);

use Test::More;
use DBI::Test;

sub run_test
{
    my @DB_CREDS = @{ $_[1] };
    my %SQLS = (
                 'SELECT' => 'SELECT 1+1',
                 'INSERT' => undef
               );

    {    #Basic test
        my $dbh = connect_ok(@DB_CREDS, "basic connect");

        ok( $dbh->disconnect(), "Disconnect" );

        #Disconnect should clear the active flag of a database handle
        ok( !$dbh->{Active}, 'dbh is inactive' );
    }

    SKIP:
    {    #Test that disconnect prints a warning if it disconncets on an active statementhandler
            #Q: Does it print an warning even though PrintWarn is false?
        my $dbh = connect_ok(@DB_CREDS, "basic connect");
	skip("Invalid SQL for some engines", 1);

        #Create  statementhandler
        my $sth = prepare_ok( $dbh, $SQLS{SELECT}, undef, "prepare $SQLS{SELECT}");    #TODO : some SELECT should go inside here, or?
        execute_ok($sth, "execute $SQLS{SELECT}" );

        my $warnings = 0;

        #Make sure we fetch the local
        local $SIG{__WARN__} = sub {
            $warnings++ if ( shift() =~ m/^DBI::db/ );
        };

        #The statementhandler should have more rows to fetch
        ok( $dbh->disconnect(), "Disconnect" );
        # cmp_ok( $warnings, '>', 0, "Catched a warning" );
    }

    {    #Negative test
            #TODO how should we force it to fail. Mock DBD\DBI?

      TODO:
        {
            local $TODO = "Must make an API to make the disconnecct fail";
	    my $dbh = connect_ok(@DB_CREDS, "basic connect");

            #Put code to make disconnect fail in here
            ok( !$dbh->disconnect(), "Disconnect failure" );
            #Check that $DBI::err && $DBI::errstr is set
            #It should be set after a failed call
            ok( $DBI::err,    '$DBI::err is set' );
            ok( $DBI::errstr, '$DBI::errstr is set' );

            #Disconnect failed. The Active flag should still be true
            ok( $dbh->{Active}, 'dbh is still active' );
        }

    }

    {    #Check that disconnect does print an error when PrintError is true
            #TODO how should we force it to fail. Mock DBD\DBI?

      TODO:
        {
            local $TODO = "Must make an API to make the disconnecct fail";
	    my $dbh = connect_ok(@DB_CREDS[ 0 .. 2 ], { PrintError => 1 }, "connect with PrintError");

            my @warnings = ();
            #Make sure we fetch the local
            local $SIG{__WARN__} = sub {
                my ( $called_from, $warning ) = @_;    # to find out Carping methods
                my $warn_kind = $called_from eq 'Carp' ? 'carped' : 'warn';
                my @warning_stack = split /\n/, $warning;    # some stuff of uplevel is included
                push( @warnings, $warning_stack[0] );
            };

            #TODO : force disconncet to fail

            #Put code to make disconnect fail in here
            ok( !$dbh->disconnect(), "Disconnect failure" );
            cmp_ok( scalar(@warnings), '>', 1, "Warning recorded" );
        }
    }

    {    #Check that disconnect does dies on fail when RaiseError is set
            #TODO how should we force it to fail. Mock DBD\DBI?

      TODO:
        {
            local $TODO = "Must make an API to make the disconnecct fail";
            my $dbh = DBI->connect( @DB_CREDS[ 0 .. 2 ], { RaiseError => 1 } );
            isa_ok( $dbh, 'DBI::db' );

            #TODO : force disconncet to fail

            #Put code to make disconnect fail in here
            eval { $dbh->disconnect(); };
            ok( $@, "Disconnect raised error" );
        }
    }
    done_testing();
}

1;
