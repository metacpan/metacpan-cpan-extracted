use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Requires;
use DBIx::DBHResolver;

test_requires 'DBD::SQLite';

sub test_connect {
    my %specs = @_;
    my ( $resolver, $desc ) = @specs{qw/resolver desc/};

    subtest $desc => sub {
        $resolver->config(
            +{
                clusters     => +{},
                connect_info => +{
                    MAIN => +{
                        dsn      => 'dbi:SQLite:dbname=./t/test.db',
                        user     => '',
                        password => '',
                        attrs    => +{ RaiseError => 1, AutoCommit => 0, },
                    },
                },
            }
        );
        my $dbh;
        lives_ok { $dbh = $resolver->connect('MAIN'); } 'retrieve dbh';
        isa_ok( $dbh, 'DBI::db' );
        ok( $dbh->{Active}, 'DBI::db is active' );
        done_testing;
    };
}

test_connect(
    resolver => 'DBIx::DBHResolver',
    desc     => 'as static class',
);

test_connect(
    resolver => DBIx::DBHResolver->new,
    desc     => 'as object',
);

unlink 't/test.db' if -f 't/test.db';

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
