use strict;
use warnings;
use DBIx::DBHResolver;
use FindBin;
use Test::More;

our $CONFIG_YAML_FILE = "$FindBin::Bin/db.conf.yaml";
our @CONFIG_PERL_FILES = ( "$FindBin::Bin/db1.conf.perl", "$FindBin::Bin/db2.conf.perl" );
our $CONFIG      = +{
    connect_info => {
        DB_W => {
            dsn      => 'dbi:mysql:dbname=user;host=db_w',
            user     => 'hoge',
            password => undef,
            attrs    => {
                AutoCommit => 0,
                PrintError => 0,
                RaiseError => 1,
                Warn       => 0,
            },
        },
        DB_R1 => {
            dsn      => 'dbi:mysql:dbname=user;host=db_r1',
            user     => 'hoge',
            password => undef,
            attrs    => {
                AutoCommit => 0,
                PrintError => 0,
                RaiseError => 1,
                Warn       => 0,
            },
        },
        DB_R2 => {
            dsn      => 'dbi:mysql:dbname=user;host=db_r2',
            user     => 'hoge',
            password => undef,
            attrs    => {
                AutoCommit => 0,
                PrintError => 0,
                RaiseError => 1,
                Warn       => 0,
            },
        },
    },
    clusters => { DB_R => [qw(DB_R1 DB_R2)], },
};

sub test_config {
    my $r = shift;

    is_deeply( $r->config, +{}, 'empty config before calling load method' );
    $r->load($CONFIG_YAML_FILE);
    is_deeply( $r->config, $CONFIG, 'loaded config from yaml file' );
    $r->config(+{});
    $r->load(@CONFIG_PERL_FILES);
    is_deeply( $r->config, $CONFIG, 'loaded config from perl files' );

    done_testing;
}

subtest 'using as static class' => sub {
    my $r = 'DBIx::DBHResolver';
    test_config($r);
};

subtest 'using as object' => sub {
    my $r = DBIx::DBHResolver->new;
    test_config($r);
};

done_testing;
