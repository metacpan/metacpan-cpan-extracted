# NAME

App::Prove::Plugin::MySQLPool - pool of Test::mysqld-s reused while testing

# SYNOPSIS

    prove -j4 -PMySQLPool t
      or
    prove -j4 -PMySQLPool=MyApp::Test::DB t

# DESCRIPTION

App::Prove::Plugin::MySQLPool is a [prove](https://metacpan.org/pod/prove) plugin to speedup your tests using a pool of [Test::mysqld](https://metacpan.org/pod/Test%3A%3Amysqld)s.

If you're using Test::mysqld, and have a lot of tests using it, annoyed by the mysql startup time slowing your tests, this module is for you.

This module launches -j number of Test::mysqld instances first.

Next, each mysqld instance optionally calls

    MyApp::Test::DB->prepare( $mysqld );

You can CREATE TABLEs using [GitDDL](https://metacpan.org/pod/GitDDL) or [DBIx::Class::Schema::Loader](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASchema%3A%3ALoader) or others,
or bulk insert master data before start testing.

MyApp::Test::DB only needs to implement a `prepare` sub.
`prepare` is called only once per -j number of mysqld instances,
and is called before your first .t file get tested.

    # MyApp::Test::DB
    sub prepare {
        my ($package, $mysqld) = @_;
        my $gd = GitDDL->new( dsn => $mysqld->dsn, ... );
        $gd->deploy;
    }

Use $ENV{ PERL\_TEST\_MYSQLPOOL\_DSN } like following in your test code.

    my $dbh = DBI->connect( $ENV{ PERL_TEST_MYSQLPOOL_DSN } );

Since this module reuses mysqlds,
you'd better erase all rows inserted at the top of your tests.

    $dbh->do( "TRUNCATE $_" ) for @tables;

If you need customize my.cnf, you may want to implement `my_cnf` method in MyApp::Test::DB.

    # MyApp::Test::DB
    sub my_cnf {
        +{
            "skip-networking" => "",
            "character-set-server" => "utf8mb4",
        };
    }

This config is used before launching Test::mysqld instances.
So you can set non-dynamic system variables.

# AUTHOR

Masakazu Ohtsuka <o.masakazu@gmail.com>

# SEE ALSO

[prove](https://metacpan.org/pod/prove), [Test::mysqld](https://metacpan.org/pod/Test%3A%3Amysqld)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
