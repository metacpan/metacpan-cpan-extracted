#!/usr/bin/perl -Tw

use strict;
use warnings;
{
    use Test::More ( tests => 4 );
    use DBI;
    use Storable;
}

my ( @Mock_Rows,
     $Schema_Hr,     $Filename,        $Dsn,
     %Expect_Schema, $Expect_Filename, $Expect_Dsn );
{
    @Mock_Rows = (
        ['mock_table'],
        {   'Extra'   => 'AUTO_INCREMENT',
            'Type'    => 'Int(11)',
            'Field'   => 'Id',
            'Default' => undef,
            'Null'    => 'NO',
            'key'     => 'PRI'
        },
        {   'Extra'   => '',
            'Type'    => 'Varchar(100)',
            'Field'   => 'Data',
            'Default' => undef,
            'Null'    => 'YES',
            'key'     => ''
        },
        {   'Extra'   => '',
            'Type'    => 'Timestamp',
            'Field'   => 'Created',
            'Default' => 'CURRENT_TIMESTAMP',
            'Null'    => 'NO',
            'key'     => ''
        },
    );

    %Expect_Schema = (
        'mock_db.mock_table' => [
            {   'default' => '',
                'extra'   => 'auto_increment',
                'type'    => 'int(11)',
                'key'     => 'pri',
                'null'    => 'no',
                'field'   => 'Id'
            },
            {   'default' => '',
                'extra'   => '',
                'type'    => 'varchar(100)',
                'key'     => '',
                'null'    => 'yes',
                'field'   => 'Data'
            },
            {   'default' => 'current_timestamp',
                'extra'   => '',
                'type'    => 'timestamp',
                'key'     => '',
                'null'    => 'no',
                'field'   => 'Created'
            }
        ]
    );

    # FIXME Broken test for cross platform ...
    $Expect_Filename = '/tmp/tndbo.mock_db.schema';

    $Expect_Dsn = 'DBI:mysql:database=mock_db;host=dickclark;port=1234, joe, eoj';
}

INIT {

    $::{'DBIx::TNDBO::Mockup::'} = { 'ISA' => ['DBIx::TNDBO'] };

    no warnings qw( redefine once );

    *DBIx::TNDBO::Mockup::credentials = sub {
        return {
            user   => 'joe',
            pass   => 'eoj',
            driver => 'mysql',
            host   => 'dickclark',
            port   => '1234',
        };
    };

    *Storable::store = sub {
        ( $Schema_Hr, $Filename ) = @_;
        return;
    };

    *DBI::connect = sub {
        my ( $class, @args ) = @_;
        {   package _mock_dbh;
            sub new {
                my ( $class, $dsn, $user, $pass ) = @_;
                $Dsn = "$dsn, $user, $pass";
                return bless {
                    dsn  => $dsn,
                    user => $user,
                    pass => $pass,
                }, $class;
            }
            sub prepare {
                my ( $self, $sql ) = @_;
                {   package _mock_sth;
                    sub new {
                        my ( $class, $sql ) = @_;
                        return bless \$sql, $class;
                    }
                    sub execute { return 1; }
                    sub rows { return 1; }
                    sub fetchrow {
                        return if !@Mock_Rows;
                        return @{ shift @Mock_Rows };
                    }
                    sub fetchrow_hashref {
                        return if !@Mock_Rows;
                        return shift @Mock_Rows;
                    }
                }
                return _mock_sth->new( $sql );
            }
        }
        return _mock_dbh->new( @args );
    };
}

use_ok( 'DBIx::TNDBO', 'mock_db' )
    || exit;

# This covers end-to-end for
#    import(), credentials(), _read_schema(), _get_dbh()
{
    is( $Dsn, $Expect_Dsn,                  'correct DSN and credentials' );
    is_deeply( $Schema_Hr, \%Expect_Schema, 'stored correct schema' );
    is( $Filename, $Expect_Filename,        'stored to correct filename' );
}

__END__
