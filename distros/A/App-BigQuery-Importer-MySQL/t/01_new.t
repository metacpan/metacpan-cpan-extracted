use strict;
use Test::More 0.98;
use Test::Fatal;

use App::BigQuery::Importer::MySQL;

our $origin_args = {
    src             => 'src.table',
    dst             => 'dst.table',
    allow_text_type => 0,
    mysqlhost       => 'localhost',
    mysqluser       => 'user',
    mysqlpassword   => 'pass',
    project_id      => 'pjid',
    progs           => {
        mysql  => '/path/to/mysql',
        gsutil => '/path/to/gsutil',
        bq     => '/path/to/bq',
    }
};

subtest 'all_args' => sub {
    my $args = { %$origin_args };
    is exception {
        my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
    }, undef, "create ok";
};

subtest 'no src' => sub {
    my $args = { %$origin_args };
    $args->{src} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/src is required/,
        "no src in args died as expected",
    );
};

subtest 'no dst' => sub {
    my $args = { %$origin_args };
    $args->{dst} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/dst is required/,
        "no dst in args died as expected",
    );
};

subtest 'no mysqlhost' => sub {
    my $args = { %$origin_args };
    $args->{mysqlhost} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/mysqlhost is required/,
        "no mysqlhost in args died as expected",
    );
};

subtest 'no mysqluser' => sub {
    my $args = { %$origin_args };
    $args->{mysqluser} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/mysqluser is required/,
        "no mysqluser in args died as expected",
    );
};

subtest 'no mysqlpassword' => sub {
    my $args = { %$origin_args };
    $args->{mysqlpassword} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/mysqlpassword is required/,
        "no mysqlpassword in args died as expected",
    );
};

subtest 'no project_id' => sub {
    my $args = { %$origin_args };
    $args->{project_id} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/project_id is required/,
        "no project_id in args died as expected",
    );
};

subtest 'no progs' => sub {
    my $args = { %$origin_args };
    $args->{progs} = undef;
    like(
        exception {
            my $mysqlbq = App::BigQuery::Importer::MySQL->new($args);
        },
        qr/progs is required/,
        "no progs in args died as expected",
    );
};

done_testing;
