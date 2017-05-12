package DBI::Test::Case::basic::connect;

use strict;
use warnings;

use parent qw(DBI::Test::Case);

use Test::More;
use DBI::Test;

sub run_test
{
    my @DB_CREDS = @{$_[1]};

    {
        my $dbh = connect_ok( @DB_CREDS, "basic connect" );

        #Active should be true when you are connected
        #disconnect set Active to false
        ok( $dbh->{Active}, "dbh is active" );
    }

    {    #Testing that the connect attributes are correctly set
      SKIP:
        {
            skip "No attributes provided", 1
              if ( !defined $DB_CREDS[3] || ref( $DB_CREDS[3] ) ne 'HASH' );

            my $dbh = connect_ok( @DB_CREDS, "basic connect" );

            #Check the $dbh->{Attribute} and $dbh->FETCH('Attribute') interface
            foreach my $attr ( keys %{ $DB_CREDS[3] } )
            {
                is( $dbh->{$attr},
                        $DB_CREDS[3]->{$attr},
                        $attr . ' == ' . $DB_CREDS[3]->{$attr} );
                is( $dbh->FETCH($attr),
                        $DB_CREDS[3]->{$attr},
                        $attr . ' == ' . $DB_CREDS[3]->{$attr} );
            }
        }
    }

    {    #Check some default values

        my $dbh = connect_ok( @DB_CREDS[ 0 .. 2 ], {}, "connect without attr" );

        for (qw(AutoCommit PrintError))
        {
            cmp_ok( $dbh->{$_},      '==', 1, $_ . ' == 1' );
            cmp_ok( $dbh->FETCH($_), '==', 1, $_ . ' == 1' );
        }

      TODO:
        {
            #Seems like $^W doesnt honor the use warnings pragma.. Is PrintWarn affected by the pragma, or only the -w cmd flag?
            local $TODO = "PrintWarn should default to true if warnings is enabled. How to check?";
            diag '$^W= ' . $^W . "\n";
            cmp_ok( $dbh->{PrintWarn}, '==',
                    ( ($^W) ? 1 : 0 ),
                    'PrintWarn == ' . ( ($^W) ? 1 : 0 ) );
        }
    }

    {    #Negative test

        #Use a fake dsn that does not exists
        #TODO : Using a invalid dsn does not work. Drivers like SQLite etc will just create a file with that name
        #It isnt so simple we will have to use a DBD that is available. Or do we do them all?
      TODO:
        {
            local $TODO =
              "How to make the connect fail. Just using a wrong dsn doesnt seem to cut it";

            #TODO, make this more portable
            my $dsn = $DB_CREDS[0];
            $dsn =~ s/(dbi:[A-Za-z_\-0-9]+::).+/$1/; $dsn .= "invalid_db";

            #PrintError is on by default, so we should check that we can intercept a warning
            my $warnings = 0;

            #TODO : improve this
            local $SIG{__WARN__} = sub {
                $warnings++;
            };

            connect_not_ok( $dsn, @DB_CREDS[ 1 .. 2 ], {}, "Connection failure" );

            cmp_ok( $warnings, '>', 0, "warning displayed" );

            ok( $DBI::err,    '$DBI::err defined' );
            ok( $DBI::errstr, '$DBI::errstr defined' );
        }
    }

    done_testing();

}

1;
