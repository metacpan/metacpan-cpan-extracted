use strict;
use warnings;
use Log::Any::Test;
use DBIx::ThinSQL;
use DBIx::ThinSQL::SQLite
  qw/create_sqlite_sequence create_functions create_methods/;
use File::chdir;
use Log::Any '$log';
use Path::Tiny;
use Test::Fatal qw/exception/;
use Test::More;

sub run_in_tempdir (&) {
    my $sub = shift;
    my $cwd = $CWD;
    my $tmp = Path::Tiny->tempdir( CLEANUP => 1 );

    local $CWD = $tmp;
    $sub->();

    $CWD = $cwd;
}

subtest "create_functions", sub {
    isa_ok \&create_functions, 'CODE';

    run_in_tempdir {

        my $db = DBIx::ThinSQL->connect( 'dbi:SQLite:dbname=test.sqlite3',
            undef, undef, { RaiseError => 1, PrintError => 0 } );

        my @funcs = (
            qw/debug create_sequence currval nextval sha1
              sha1_hex sha1_base64 agg_sha1 agg_sha1_hex agg_sha1_base64/
        );
        foreach my $func (@funcs) {
            ok exception { $db->do("select $func()") },
              "no existing func $func";
        }

        like exception { create_functions() }, qr/usage:/, 'usage';

        like exception { create_functions( 1, 2 ) },
          qr/handle has no sqlite_create_function/,
          'usage no handle';

        like exception { create_functions( $db, 'unknown' ) },
          qr/unknown function/,
          'unknown function';

        create_functions( $db, qw/debug/ );

        my $str = 'RaNdOm';    # just a random string
        $db->do("select debug('$str', '$str', 1)");
        $log->contains_ok( qr/$str $str 1/, 'debug logged all args' );

        $db->do(q{select debug("select ? || ? || ?", 'lazy','fox','jump')});
        $log->contains_ok( qr/lazyfoxjump/, 'debug select with bind values' );

        $db->do(
            q{select debug("
            select 1 || 2 || 1 || 4")}
        );
        $log->contains_ok( qr/1214/, 'debug select with leading space' );

        create_functions( $db, qw/create_sequence currval nextval/ );

        # manually create sqlite_sequence
        $db->do('create table x(id integer primary key autoincrement)');
        $db->do('drop table x');

        like exception { $db->selectrow_array("select nextval('testseq')") },
          qr/no such table/, 'seq not found';

        $db->do(q{select create_sequence('testseq')});
        $db->do(q{select create_sequence('testseq2')});

        my ($res) = $db->selectrow_array(q{select currval('testseq')});
        is $res, 0, 'currval';

        ($res) = $db->selectrow_array(q{select nextval('testseq')});
        is $res, 1, 'nextval';

        ($res) = $db->selectrow_array(q{select currval('testseq')});
        is $res, 1, 'currval again';

        ($res) = $db->selectrow_array(q{select nextval('testseq')});
        is $res, 2, 'nextval';

        ($res) = $db->selectrow_array(q{select currval('testseq')});
        is $res, 2, 'currval again';

      SKIP: {
            plan skip_all => 'require Digest::SHA for sha functions'
              unless eval { require Digest::SHA };

            create_functions( $db, qw/sha1 sha1_hex sha1_base64/ );

            $db->do(<<_ENDSQL_);
CREATE TABLE x(
    val varchar NOT NULL PRIMARY KEY,
    sbytes blob,
    shex char(40),
    sbase64 varchar
);
_ENDSQL_

            $db->do(<<_ENDSQL_);
CREATE TRIGGER trigx AFTER INSERT ON x
FOR EACH ROW
BEGIN
    UPDATE
        x
    SET
        sbytes = CAST(sha1(NEW.val) AS BLOB),
        shex = sha1_hex(NEW.val),
        sbase64 = sha1_base64(NEW.val)
    WHERE
        val = NEW.val
    ;
END;
_ENDSQL_

            $db->do(<<_ENDSQL_);
INSERT INTO x(val) VALUES(1);
_ENDSQL_

            my $sha1        = Digest::SHA::sha1(1);
            my $sha1_hex    = Digest::SHA::sha1_hex(1);
            my $sha1_base64 = Digest::SHA::sha1_base64(1);

            my ( $bytes, $hex, $base64 ) = $db->selectrow_array(
                q{
                select sbytes,shex,sbase64 from x where val=1    
            }
            );

            is $bytes,  $sha1,        'sha1';
            is $hex,    $sha1_hex,    'sha1_hex';
            is $base64, $sha1_base64, 'sha1_base64';

            ( $bytes, $hex, $base64 ) = $db->selectrow_array(
                q{
                select sha1(1,2,3), sha1_hex(1,2,3), sha1_base64(1,2,3)
            }
            );

            $sha1 = Digest::SHA::sha1( 1, 2, 3 );
            $sha1_hex = Digest::SHA::sha1_hex( 1, 2, 3 );
            $sha1_base64 = Digest::SHA::sha1_base64( 1, 2, 3 );

            is $bytes,  $sha1,        'sha1 multi-argument';
            is $hex,    $sha1_hex,    'sha1_hex multi-argument';
            is $base64, $sha1_base64, 'sha1_base64 multi-argument';

            subtest 'aggregate hash' => sub {
                create_functions( $db,
                    qw/agg_sha1 agg_sha1_hex agg_sha1_base64/ );

                # More than two arguments
                like
                  exception { $db->selectrow_array(q{select agg_sha1(1,2,3)}); }
                , qr/wrong number of arguments/, 'agg_sha1 only two argument';

                like exception {
                    $db->selectrow_array(q{select agg_sha1_hex(1,2,3)});
                }, qr/wrong number of arguments/,
                  'agg_sha1_hex only two argument';

                like exception {
                    $db->selectrow_array(q{select agg_sha1_base64(1,2,3)});
                }, qr/wrong number of arguments/,
                  'agg_sha1_base64 only two argument';

                # Just the right number of arguments

                my ($hash) = $db->selectrow_array(
                    q{ select agg_sha1(1,1) from (select 1) });

                is $hash, Digest::SHA::sha1(1), 'agg_sha1 single';

                ($hash) = $db->selectrow_array(
                    q{ select agg_sha1(1,NULL) from (select 1) });

                is $hash, Digest::SHA::sha1(1), 'agg_sha1 single sort by null';

                ($hash) = $db->selectrow_array(
                    q{ select agg_sha1(NULL,NULL) from (select 1) });

                is $hash, Digest::SHA::sha1(), 'agg_sha1 null sort by null';

                $db->do(q{CREATE TABLE y( id INTEGER, rev INTEGER)});
                $db->do('insert into y(id,rev) values(1,3)');
                $db->do('insert into y(id,rev) values(2,2)');
                $db->do('insert into y(id,rev) values(3,1)');

                ($hash) =
                  $db->selectrow_array(q{ select agg_sha1(id,id) from y });

                is $hash, Digest::SHA::sha1( 1, 2, 3 ), 'agg_sha1 multi';

                ($hash) =
                  $db->selectrow_array(q{ select agg_sha1(id,rev) from y});

                is $hash, Digest::SHA::sha1( 3, 2, 1 ),
                  'agg_sha1 multi reverse';

                ($hash) =
                  $db->selectrow_array(q{ select agg_sha1_hex(id,id) from y });

                is $hash, Digest::SHA::sha1_hex( 1, 2, 3 ), 'agg_sha1_hexmulti';

                ($hash) =
                  $db->selectrow_array(q{ select agg_sha1_hex(id,rev) from y});

                is $hash, Digest::SHA::sha1_hex( 3, 2, 1 ),
                  'agg_sha1_hex multi reverse';

                ($hash) = $db->selectrow_array(
                    q{ select agg_sha1_base64(id,id) from y });

                is $hash, Digest::SHA::sha1_base64( 1, 2, 3 ),
                  'agg_base64 multi';

                ($hash) = $db->selectrow_array(
                    q{ select agg_sha1_base64(id,rev) from y});

                is $hash, Digest::SHA::sha1_base64( 3, 2, 1 ),
                  'agg_base64 multi reverse';

                $db->do('insert into y(id,rev) values(4,NULL)');

                ($hash) =
                  $db->selectrow_array(q{ select agg_sha1(id,rev) from y });

                is $hash, Digest::SHA::sha1( 4, 3, 2, 1 ), 'agg_sha1 multi';

                ($hash) =
                  $db->selectrow_array(q{ select agg_sha1(rev,rev) from y });

                is $hash, Digest::SHA::sha1( 1, 2, 3 ), 'agg_sha1 multi';
              }

        }
    }
};

subtest "create_methods", sub {
    isa_ok \&create_methods, 'CODE';

    run_in_tempdir {
        my $db = DBIx::ThinSQL->connect( 'dbi:SQLite:dbname=test.sqlite3',
            undef, undef, { RaiseError => 1, PrintError => 0 } );

        my @methods = (qw/create_sequence currval nextval/);
        foreach my $method (@methods) {
            ok !$db->can($method), "no existing method $method";
        }

        like exception { create_methods('unknown') },
          qr/unknown method/,
          'unknown method';

        create_methods(qw/create_sequence currval nextval/);

        create_sqlite_sequence($db);

        $db->create_sequence('testseq');

        my $res = $db->currval('testseq');
        is $res, 0, 'currval';

        $res = $db->nextval('testseq');
        is $res, 1, 'nextval';

        $res = $db->currval('testseq');
        is $res, 1, 'currval again';

        $res = $db->currval('testseq');
        is $res, 1, 'currval again';

        create_functions( $db, qw/currval/ );

        ($res) = $db->selectrow_array(q{select currval('testseq')});
        is $res, 1, 'method/function match';

        # Can only test this after sqlite_sequence has already been created
        like exception { $db->nextval('unknown') },
          qr/no such table/, 'nextval seq not found';

        like exception { $db->currval('unknown') },
          qr/unknown sequence/, 'currval seq not found';

    };
};

done_testing();
