use strict;
use warnings;

use Test::More tests => 27;
use_ok('DBIx::CheckConnectivity');
use_ok('DBIx::CheckConnectivity::Driver::SQLite');
use_ok('DBIx::CheckConnectivity::Driver::Pg');
use_ok('DBIx::CheckConnectivity::Driver::mysql');

my $error;

use Test::MockModule;
my $dbi = Test::MockModule->new('DBI');
use Carp;
$dbi->mock();
$dbi->mock(
    connect => sub {
        shift;    # shift the class
        my $dsn      = shift;
        my $user     = shift;
        my $password = shift;
        my $attr     = shift;
        is_deeply(
            $attr,
            { RaiseError => 0, PrintError => 0 },
            'we do not want to raise or print error by default'
        );

        if ( $dsn =~ /not_exist/ ) {
            if ( $dsn =~ /mysql/ ) {
                DBI::errstr('unknown database');
            }
            elsif ( $dsn =~ /Pg/ ) {
                DBI::errstr('not exist');
            }
            else {
                DBI::errstr('');
            }
        }
        elsif ( $password =~ /wrong/ ) {
            DBI::errstr('wrong password');
        }
        else {
            DBI::errstr('');
            return 1;
        }
        return;
    },
    do => sub {
        return 1;
    },
    errstr => sub {
        if (@_) {
            $error = shift;
        }
        else {
            return $error;
        }
    }
);

ok( check_connectivity( dsn => 'dbi:SQLite:database=xx;' ),
    'normal SQLite driver' );
ok( check_connectivity( dsn => 'dbi:Pg:database=xx;' ), 'normal pg driver' );
ok( check_connectivity( dsn => 'dbi:mysql:database=xx;' ),
    'normal mysql driver' );
ok( check_connectivity( dsn => 'dbi:Oracle:database=xx;' ),
    'normal oracle driver' );
ok( !check_connectivity( dsn => 'dbi:Pg:database=not_exist;' ),
    'pg with not_exist db' );
is( $error, 'not exist', 'err' );
is_deeply(
    [ check_connectivity( dsn => 'dbi:Pg:database=not_exist;' ) ],
    [ undef, 'not exist' ],
    'list context'
);
ok( !check_connectivity( dsn => 'dbi:mysql:database=not_exist;' ),
    'mysql with not_exist db' );
is( $error, 'unknown database', 'err' );
is_deeply(
    [ check_connectivity( dsn => 'dbi:mysql:database=not_exist;' ) ],
    [ undef, 'unknown database' ],
    'list context'
);

ok(
    !check_connectivity(
        dsn      => 'dbi:Pg:database=xx;',
        password => 'wrong'
    ),
    'pg with wrong password'
);
is( $error, 'wrong password', 'err' );
is_deeply(
    [ check_connectivity( dsn => 'dbi:Pg:database=xx;', password => 'wrong' ) ],
    [ undef, 'wrong password' ],
    'list context'
);
