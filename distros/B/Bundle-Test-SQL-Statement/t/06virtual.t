#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

use Params::Util qw(_CODE _ARRAY);

my ( $required, $recommended ) = prove_reqs( { default_recommended(), ( MLDBM => 0 ) } );
show_reqs( $required, $recommended );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();

my @massValues = map { [ $_, ( "a" .. "f" )[ int rand 6 ], int rand 10 ] } ( 1 .. 3999 );

SKIP:
foreach my $test_dbd (@test_dbds)
{
    my $dbh;
    diag("Running tests for $test_dbd");
    my $temp = "";
    # XXX
    # my $test_dbd_tbl = "${test_dbd}::Table";
    # $test_dbd_tbl->can("fetch") or $temp = "$temp";
    $test_dbd eq "DBD::File"      and $temp = "TEMP";
    $test_dbd eq "SQL::Statement" and $temp = "TEMP";

    my %extra_args;
    if ( $test_dbd eq "DBD::DBM" )
    {
        if ( $recommended->{MLDBM} )
        {
            $extra_args{dbm_mldbm} = "Storable";
        }
        else
        {
            skip( 'DBD::DBM test runs without MLDBM', 1 );
        }
    }
    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
                       f_dir      => $testdir,
                       %extra_args,
                    }
                  );

    my ( $sth, $str );
    my $now = time();
    my @timelist;
    for my $hour ( 1 .. 10 )
    {
        push( @timelist, $now - ( $hour * 3600 ) );
    }

    for my $sql (
        split /\n/,
        sprintf( <<"", ($now) x 7, @timelist )
	CREATE $temp TABLE biz (sales INTEGER, class CHAR, color CHAR, BUGNULL CHAR)
	INSERT INTO biz VALUES (1000, 'Car',   'White', NULL)
	INSERT INTO biz VALUES ( 500, 'Car',   'Blue',  NULL )
	INSERT INTO biz VALUES ( 400, 'Truck', 'White', NULL )
	INSERT INTO biz VALUES ( 700, 'Car',   'Red',   NULL )
	INSERT INTO biz VALUES ( 300, 'Truck', 'White', NULL )
	CREATE $temp TABLE baz (ordered INTEGER, class CHAR, color CHAR)
	INSERT INTO baz VALUES ( 250, 'Car',   'White' ), ( 100, 'Car',   'Blue' ), ( 150, 'Car',   'Red' )
	INSERT INTO baz VALUES (  80, 'Truck', 'White' ), (  60, 'Truck', 'Green' ) -- Yes, we introduce new cars :)
	CREATE $temp TABLE numbers (c_foo INTEGER, foo CHAR, bar INTEGER)
	CREATE $temp TABLE trick   (id INTEGER, foo CHAR)
	INSERT INTO trick VALUES (1, '1foo')
	INSERT INTO trick VALUES (11, 'foo')
	CREATE TYPE TIMESTAMP
	CREATE $temp TABLE log (id INT, host CHAR, signature CHAR, message CHAR, time_stamp TIMESTAMP)
	INSERT INTO log VALUES (1, 'bert', '/netbsd', 'Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,', %d)
	INSERT INTO log VALUES (2, 'bert', '/netbsd', '2006, 2007, 2008, 2009, 2010', %d)
	INSERT INTO log VALUES (3, 'bert', '/netbsd', 'The NetBSD Foundation, Inc.  All rights reserved.', %d)
	INSERT INTO log VALUES (4, 'bert', '/netbsd', 'Copyright (c) 1982, 1986, 1989, 1991, 1993', %d)
	INSERT INTO log VALUES (5, 'bert', '/netbsd', 'The Regents of the University of California.  All rights reserved.', %d)
	INSERT INTO log VALUES (6, 'bert', '/netbsd', '', %d)
	INSERT INTO log VALUES (7, 'bert', '/netbsd', 'NetBSD 5.99.39 (BERT) #0: Fri Oct  8 06:23:03 CEST 2010', %d)
	INSERT INTO log VALUES (8, 'ernie', 'rpc.statd', 'starting', %d)
	INSERT INTO log VALUES (9, 'ernie', 'savecore', 'no core dump', %d)
	INSERT INTO log VALUES (10, 'ernie', 'postfix/postfix-script', 'starting the Postfix mail system', %d)
	INSERT INTO log VALUES (11, 'ernie', 'rpcbind', 'connect from 127.0.0.1 to dump()', %d)
	INSERT INTO log VALUES (12, 'ernie', 'sshd', 'last message repeated 2 times', %d)
	INSERT INTO log VALUES (13, 'ernie', 'shutdown', 'poweroff by root:', %d)
	INSERT INTO log VALUES (14, 'ernie', 'shutdown', 'rebooted by root', %d)
	INSERT INTO log VALUES (15, 'ernie', 'sshd', 'Server listening on :: port 22.', %d)
	INSERT INTO log VALUES (16, 'ernie', 'sshd', 'Server listening on 0.0.0.0 port 22.', %d)
	INSERT INTO log VALUES (17, 'ernie', 'sshd', 'Received SIGHUP; restarting.', %d)

                )
    {
        ok( $sth = $dbh->prepare($sql), "prepare $sql on $test_dbd" ) or diag( $dbh->errstr() );
        ok( $sth->execute(), "execute $sql on $test_dbd" ) or diag( $sth->errstr() );
    }

    my @tests = (
        {
           test     => 'GROUP BY one column',
           sql      => "SELECT class,SUM(sales) as foo, MAX(sales) FROM biz GROUP BY class",
           fetch_by => 'class',
           result   => {
                       Car => {
                                MAX   => '1000',
                                foo   => 2200,
                                class => 'Car'
                              },
                       Truck => {
                                  MAX   => '400',
                                  foo   => 700,
                                  class => 'Truck'
                                }
                     },
        },
        {
           test     => "GROUP BY several columns",
           sql      => "SELECT color,class,SUM(sales), MAX(sales) FROM biz GROUP BY color,class",
           fetch_by => [ 'color', 'class' ],
           result   => {
                       Blue => {
                                 Car => {
                                          color => 'Blue',
                                          class => 'Car',
                                          SUM   => 500,
                                          MAX   => 500,
                                        },
                               },
                       Red => {
                                Car => {
                                         color => 'Red',
                                         class => 'Car',
                                         SUM   => 700,
                                         MAX   => 700,
                                       },
                              },
                       White => {
                                  Car => {
                                           color => 'White',
                                           class => 'Car',
                                           SUM   => 1000,
                                           MAX   => 1000,
                                         },
                                  Truck => {
                                             color => 'White',
                                             class => 'Truck',
                                             SUM   => 700,
                                             MAX   => 400,
                                           },
                                }
                     },
        },
        {
           test   => 'AGGREGATE FUNCTIONS WITHOUT GROUP BY',
           sql    => "SELECT SUM(sales), MAX(sales) FROM biz",
           result => [ [ 2900, 1000 ], ]
        },
        {
           test     => 'COUNT(distinct column) WITH GROUP BY',
           sql      => "SELECT distinct class, COUNT(distinct color) FROM biz GROUP BY class",
           fetch_by => 'class',
           result   => {
                       Car => {
                                class => 'Car',
                                COUNT => 3,
                              },
                       Truck => {
                                  class => 'Truck',
                                  COUNT => 1,
                                },
                     },
        },
        {
           test     => 'COUNT(*) with GROUP BY',
           sql      => "SELECT class, COUNT(*) FROM biz GROUP BY class",
           fetch_by => 'class',
           result   => {
                       Car => {
                                class => 'Car',
                                COUNT => 3,
                              },
                       Truck => {
                                  class => 'Truck',
                                  COUNT => 2,
                                },
                     },
        },
        {
           test   => 'ORDER BY on aliased column',
           sql    => "SELECT DISTINCT biz.class, baz.color AS foo FROM biz, baz WHERE biz.class = baz.class ORDER BY foo",
	   result => [
	       [ qw(Car Blue) ], [ qw(Truck Green) ], [ qw(Car Red) ], [ qw(Car White) ], [ qw(Truck White) ],
	   ],
        },
        {
           test        => 'COUNT(DISTINCT *) fails',
           sql         => "SELECT class, COUNT(distinct *) FROM biz GROUP BY class",
           prepare_err => qr/Keyword DISTINCT is not allowed for COUNT/m,
        },
        {
           test => 'GROUP BY required',
           sql  => "SELECT class, COUNT(color) FROM biz",
           execute_err =>
             qr/Column 'biz\.class' must appear in the GROUP BY clause or be used in an aggregate function/,
        },
        {
           test   => 'SUM(bar) of empty table',
           sql    => "SELECT SUM(bar) FROM numbers",
           result => [ [undef] ],
        },
        {
           test   => 'COUNT(bar) of empty table with GROUP BY',
           sql    => "SELECT COUNT(bar),c_foo FROM numbers GROUP BY c_foo",
           result => [ [ 0, undef ] ],
        },
        {
           test   => 'COUNT(*) of empty table',
           sql    => "SELECT COUNT(*) FROM numbers",
           result => [ [0] ],
        },
        {
           test   => 'Mass insert of random numbers',
           sql    => "INSERT INTO numbers VALUES (?, ?, ?)",
           params => \@massValues,
        },
        {
           test        => 'Number of rows in aggregated Table',
           sql         => "SELECT foo AS boo, COUNT (*) AS counted FROM numbers GROUP BY boo",
           result_cols => [qw(boo counted)],
           result_code => sub {
               my $sth = $_[0];
               my $res = $sth->fetch_rows();
               cmp_ok( scalar( @{$res} ), '==', '6', 'Number of rows in aggregated Table' );
               my $all_counted = 0;
               foreach my $row ( @{$res} )
               {
                   $all_counted += $row->[1];
               }
               cmp_ok( $all_counted, '==', 3999, 'SUM(COUNTED)' );
           },
        },
        {
           test   => 'Aggregate functions MIN, MAX, AVG',
           sql    => "SELECT MIN(c_foo), MAX(c_foo), AVG(c_foo) FROM numbers",
           result => [ [ 1, 3999, 2000 ], ],
        },
        {
           test   => 'COUNT(*) internal for nasty table',
           sql    => "SELECT COUNT(*) FROM trick",
           result => [ [2] ],
        },
        {
           test   => 'char_length',
           sql    => "SELECT CHAR_LENGTH('foo')",
           result => [ [3] ],
        },
        {
           test   => 'position',
           sql    => "SELECT POSITION('a','bar')",
           result => [ [2] ],
        },
        {
           test   => 'lower',
           sql    => "SELECT LOWER('A')",
           result => [ ['a'] ],
        },
        {
           test   => 'upper',
           sql    => "SELECT UPPER('a')",
           result => [ ['A'] ],
        },
        {
           test   => 'concat good',
           sql    => "SELECT CONCAT('A','B')",
           result => [ ['AB'] ],
        },
        {
           test   => 'concat bad',
           sql    => "SELECT CONCAT('A',NULL)",
           result => [ [undef] ],
        },
        {
           test   => 'coalesce',
           sql    => "SELECT COALESCE(NULL,'z')",
           result => [ ['z'] ],
        },
        {
           test   => 'nvl',
           sql    => "SELECT NVL(NULL,'z')",
           result => [ ['z'] ],
        },
        {
           test => 'decode',
           sql =>
             q{SELECT DISTINCT DECODE(color,'White','W','Red','R','B') AS cfc FROM biz ORDER BY cfc},
           result => [ ['B'], ['R'], ['W'] ],
        },
        {
           test   => 'replace',
           sql    => q{SELECT REPLACE('zfunkY','s/z(.+)ky/$1/i')},
           result => [ ['fun'] ],
        },
        {
           test   => 'substitute',
           sql    => q{SELECT SUBSTITUTE('zfunkY','s/z(.+)ky/$1/i')},
           result => [ ['fun'] ],
        },
        {
           test   => 'substr',
           sql    => q{SELECT SUBSTR('zfunkY',2,3)},
           result => [ ['fun'] ],
        },
        {
           test   => 'substring',
           sql    => "SELECT DISTINCT color FROM biz WHERE SUBSTRING(class FROM 1 FOR 1)='T'",
           result => [ ['White'] ],
        },
        {
           test   => 'trim',
           sql    => q{SELECT TRIM(' fun ')},
           result => [ ['fun'] ],
        },
        {
           test   => 'soundex match',
           sql    => "SELECT SOUNDEX('jeff','jeph')",
           result => [ [1] ],
        },
        {
           test   => 'soundex no match',
           sql    => "SELECT SOUNDEX('jeff','quartz')",
           result => [ [0] ],
        },
        {
           test   => 'regex match',
           sql    => "SELECT REGEX('jeff','/EF/i')",
           result => [ [1] ],
        },
        {
           test   => 'regex no match',
           sql    => "SELECT REGEX('jeff','/zzz/')",
           result => [ [0] ],
        },
        {
           test => 'SELECT with calculation in WHERE CLAUSE',
           sql =>
             sprintf(
                   "SELECT id,host,signature,message FROM log WHERE time_stamp < (%d - ( 4 * 60 ))",
                   $now ),
           fetch_by => "id",
           result   => {
               8 => {
                      id        => 8,
                      host      => "ernie",
                      signature => "rpc.statd",
                      message   => "starting",
                    },
               9 => {
                      id        => 9,
                      host      => "ernie",
                      signature => "savecore",
                      message   => "no core dump",
                    },
               10 => {
                       id        => 10,
                       host      => "ernie",
                       signature => "postfix/postfix-script",
                       message   => "starting the Postfix mail system",
                     },
               11 => {
                       id        => 11,
                       host      => "ernie",
                       signature => "rpcbind",
                       message   => "connect from 127.0.0.1 to dump()",
                     },
               12 => {
                       id        => 12,
                       host      => "ernie",
                       signature => "sshd",
                       message   => "last message repeated 2 times",
                     },
               13 => {
                       id        => 13,
                       host      => "ernie",
                       signature => "shutdown",
                       message   => "poweroff by root:",
                     },
               14 => {
                       id        => 14,
                       host      => "ernie",
                       signature => "shutdown",
                       message   => "rebooted by root",
                     },
               15 => {
                       id        => 15,
                       host      => "ernie",
                       signature => "sshd",
                       message   => "Server listening on :: port 22.",
                     },
               16 => {
                       id        => 16,
                       host      => "ernie",
                       signature => "sshd",
                       message   => "Server listening on 0.0.0.0 port 22.",
                     },
               17 => {
                       id        => 17,
                       host      => "ernie",
                       signature => "sshd",
                       message   => "Received SIGHUP; restarting.",
                     },

           },
        },
        {
           test => 'SELECT with calculation and logical expression in WHERE CLAUSE',
           sql  => sprintf(
               "SELECT id,host,signature,message FROM log WHERE (time_stamp > (%d - 5)) AND (time_stamp < (%d + 5))",
               $now, $now
           ),
           fetch_by => "id",
           result   => {
                1 => {
                      id        => 1,
                      host      => "bert",
                      signature => "/netbsd",
                      message =>
                        "Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,",
                     },
                2 => {
                       id        => 2,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "2006, 2007, 2008, 2009, 2010",
                     },
                3 => {
                       id        => 3,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "The NetBSD Foundation, Inc.  All rights reserved.",
                     },
                4 => {
                       id        => 4,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "Copyright (c) 1982, 1986, 1989, 1991, 1993",
                     },
                5 => {
                    id        => 5,
                    host      => "bert",
                    signature => "/netbsd",
                    message => "The Regents of the University of California.  All rights reserved.",
                },
                6 => {
                       id        => 6,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => '',
                     },
                7 => {
                       id        => 7,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "NetBSD 5.99.39 (BERT) #0: Fri Oct  8 06:23:03 CEST 2010",
                     },
           },
        },
        {
           test => 'SELECT with calculated items in BETWEEN in WHERE CLAUSE',
           sql  => sprintf(
               "SELECT id,host,signature,message FROM log WHERE time_stamp BETWEEN ( %d - 5, %d + 5)",
               $now, $now
           ),
           fetch_by => "id",
           result   => {
                1 => {
                      id        => 1,
                      host      => "bert",
                      signature => "/netbsd",
                      message =>
                        "Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,",
                     },
                2 => {
                       id        => 2,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "2006, 2007, 2008, 2009, 2010",
                     },
                3 => {
                       id        => 3,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "The NetBSD Foundation, Inc.  All rights reserved.",
                     },
                4 => {
                       id        => 4,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "Copyright (c) 1982, 1986, 1989, 1991, 1993",
                     },
                5 => {
                    id        => 5,
                    host      => "bert",
                    signature => "/netbsd",
                    message => "The Regents of the University of California.  All rights reserved.",
                },
                6 => {
                       id        => 6,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => '',
                     },
                7 => {
                       id        => 7,
                       host      => "bert",
                       signature => "/netbsd",
                       message   => "NetBSD 5.99.39 (BERT) #0: Fri Oct  8 06:23:03 CEST 2010",
                     },
           },
        },
        {
           test => 'MAX() with calculated WHERE clause',
           sql  => sprintf(
               "SELECT MAX(time_stamp) FROM log WHERE time_stamp IN (%d - (2*3600), %d - (4*3600))",
               $now, $now
           ),
           result => [ [ $now - ( 2 * 3600 ) ] ],
        },
        {
           test   => 'calculation in MAX()',
           sql    => "SELECT MAX(time_stamp - 3*3600) FROM log",
           result => [ [ $now - ( 3 * 3600 ) ] ],
        },
        {
           test   => 'Caclulation outside aggregation',
           todo   => "Known limitation. Parser/Engine can not handle properly",
           sql    => "SELECT MAX(time_stamp) - 3*3600 FROM log",
           result => [ [ $now - ( 3 * 3600 ) ] ],
        },
        {
           test   => 'function in MAX()',
           sql    => "SELECT MAX( CHAR_LENGTH(message) ) FROM log",
           result => [ [73] ],
        },
        {
           test   => 'select simple calculated constant from table',
           sql    => "SELECT 1+0 from log",
           result => [ ( [1] ) x 17 ],
        },
        {
           test   => 'select calculated constant with preceedence rules',
           sql    => "SELECT 1+1*2",
           result => [ [3] ],
        },
        {
           test   => 'SELECT not calculated constant',
           sql    => "SELECT 1",
           result => [ [1] ],
        },
    );

    foreach my $test (@tests)
    {
        local $TODO;
	if( $test->{todo} )
	{
	    note( "break here" );
	}
        defined( $test->{todo} ) and $TODO = $test->{todo};
        if ( defined( $test->{prepare_err} ) )
        {
            $sth = $dbh->prepare( $test->{sql} );
            ok( !$sth, "prepare $test->{sql} using $test_dbd fails" );
            like( $dbh->errstr(), $test->{prepare_err}, $test->{test} );
            next;
        }
        $sth = $dbh->prepare( $test->{sql} );
        ok( $sth, "prepare $test->{sql} using $test_dbd" ) or diag( $dbh->errstr() );
        $sth or next;
        if ( defined( $test->{params} ) )
        {
            my $params;
            if ( defined( _CODE( $test->{params} ) ) )
            {
                $params = [ &{ $test->{params} } ];
            }
            elsif ( !defined( _ARRAY( $test->{params}->[0] ) ) )
            {
                $params = [ $test->{params} ];
            }
            else
            {
                $params = $test->{params};
            }

            my $i = 0;
            my @failed;
            foreach my $bp ( @{ $test->{params} } )
            {
                ++$i;
                my $n = $sth->execute(@$bp);
                $n
                  or
                  ok( $n, "$i: execute $test->{sql} using $test_dbd (" . DBI::neat_list($bp) . ")" )
                  or diag( $dbh->errstr() )
                  or push( @failed, $bp );

                # 'SELECT' eq $sth->command() or next;
                # could become funny ...
            }

            @failed or ok( 1, "1 .. $i: execute $test->{sql} using $test_dbd" );
        }
        else
        {
            my $n = $sth->execute();
            if ( defined( $test->{execute_err} ) )
            {
                ok( !$n, "execute $test->{sql} using $test_dbd fails" );
                like( $dbh->errstr(), $test->{execute_err}, $test->{test} );
                next;
            }

            ok( $n, "execute $test->{sql} using $test_dbd" ) or diag( $dbh->errstr() );
            'SELECT' eq $sth->command() or next;

            if ( $test->{result_cols} )
            {
                is_deeply( $sth->col_names(), $test->{result_cols}, "Columns in $test->{test}" );
            }

            if ( $test->{fetch_by} )
            {
                is_deeply( $sth->fetchall_hashref( $test->{fetch_by} ),
                           $test->{result}, $test->{test} );
            }
            elsif ( $test->{result_code} )
            {
                &{ $test->{result_code} }($sth);
            }
            else
            {
                is_deeply( $sth->fetch_rows(), $test->{result}, $test->{test} );
            }
        }
    }
}

done_testing();
