package DBIx::QuickORM::Test;
use strict;
use warnings;

use Test2::V0;
use Test2::IPC qw/cull/;
use List::Util qw/first/;
use Importer Importer => 'import';

use DBIx::QuickORM::Util qw/debug/;

our @EXPORT = qw{
    psql
    mysql
    mariadb
    percona
    sqlite
    debug

    do_for_all_dbs
};

sub psql     { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'PostgreSQL', @args}) } or diag(clean_err($@)) }
sub mysql    { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'MySQL',      @args}) } or diag(clean_err($@)) }
sub mysqlcom { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'MySQLCom',   @args}) } or diag(clean_err($@)) }
sub mariadb  { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'MariaDB',    @args}) } or diag(clean_err($@)) }
sub percona  { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'Percona',    @args}) } or diag(clean_err($@)) }
sub sqlite   { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'SQLite',     @args}) } or diag(clean_err($@)) }

my @SETS = (
    {name => 'system_postgresql', ver => '',   db => \&psql,     dialect => 'PostgreSQL',       dbi => ['Pg'],               quickdb => 'PostgreSQL', env => {}},
    {name => 'postgresql9',       ver => '9',  db => \&psql,     dialect => 'PostgreSQL',       dbi => ['Pg'],               quickdb => 'PostgreSQL', env => {PATH => "$ENV{HOME}/dbs/postgresql9/bin:$ENV{PATH}"}},
    {name => 'postgresql17',      ver => '17', db => \&psql,     dialect => 'PostgreSQL',       dbi => ['Pg'],               quickdb => 'PostgreSQL', env => {PATH => "$ENV{HOME}/dbs/postgresql17/bin:$ENV{PATH}"}},
    {name => 'sqlite',            ver => '',   db => \&sqlite,   dialect => 'SQLite',           dbi => ['SQLite'],           quickdb => 'SQLite',     env => {}},
    {name => 'system_mysql',      ver => '',   db => \&mysql,    dialect => 'MySQL',            dbi => ['mysql', 'MariaDB'], quickdb => 'MySQL',      env => {}},
    {name => 'mariadb10',         ver => '10', db => \&mariadb,  dialect => 'MySQL::MariaDB',   dbi => ['mysql', 'MariaDB'], quickdb => 'MariaDB',    env => {PATH => "$ENV{HOME}/dbs/mariadb10/bin:$ENV{PATH}"}},
    {name => 'mariadb11',         ver => '11', db => \&mariadb,  dialect => 'MySQL::MariaDB',   dbi => ['mysql', 'MariaDB'], quickdb => 'MariaDB',    env => {PATH => "$ENV{HOME}/dbs/mariadb11/bin:$ENV{PATH}"}},
    {name => 'percona8',          ver => '8',  db => \&percona,  dialect => 'MySQL::Percona',   dbi => ['mysql', 'MariaDB'], quickdb => 'Percona',    env => {PATH => "$ENV{HOME}/dbs/percona8/bin:$ENV{PATH}"}},
    {name => 'mysqlcom8',         ver => '8',  db => \&mysqlcom, dialect => 'MySQL::Community', dbi => ['mysql', 'MariaDB'], quickdb => 'MySQLCom',   env => {PATH => "$ENV{HOME}/dbs/mysql8/bin:$ENV{PATH}"}},
);

sub clean_err {
    my $err = shift;

    my @lines = split /\n/, $err;

    my $out = "";
    while (@lines) {
        my $line = shift @lines;
        next unless $line;
        last if $out && $line =~ m{^Aborting at.*DBIx/QuickDB\.pm};

        $out = $out ? "$out\n$line" : $line;
    }

    return $out;
}

our $END_DELAY = 0;
sub do_for_all_dbs(&;@) {
    my $code = shift;
    my %only = map { $_ => 1 } @_;
    require Parallel::Runner;
    my $pr = Parallel::Runner->new(
        $ENV{DBIXQORM_TEST_CONCURRENCY} // ($ENV{USER} eq 'exodist' ? 16 : 4),
        iteration_callback => \&cull,
    );

    my ($pkg, $file, $line) = caller;

    for my $set (@SETS) {
        next if @_ && !$only{$set->{name}};
        for my $dbi (@{$set->{dbi}}) {
            cull();
            $pr->run(sub {
                subtest "$set->{name} x DBD::$dbi" => sub {
                    $ENV{$_} = $set->{env}->{$_} for keys %{$set->{env}};
                    my $qdb = "DBIx::QuickDB::Driver::$set->{quickdb}";
                    my $have_qdb = eval { require "DBIx/QuickDB/Driver/$set->{quickdb}.pm"; my ($v, $why) = $qdb->viable({load_sql => 1, bootstrap => 1}); $v || die $why } or note $@;
                    my $have_dbi = eval { require "DBD/$dbi.pm"; 1 } or note $@;

                    unless ($have_qdb && $have_dbi) {
                        skip_all "Skipping $set->{name} (DBD::$dbi)...";
                        return;
                    }
                    note "Running $set->{name} (DBD::$dbi)";

                    {
                        no strict 'refs';
                        no warnings 'redefine';
                        *{"$pkg\::curdb"}      = $set->{db};
                        *{"$pkg\::curname"}    = sub { $set->{name} };
                        *{"$pkg\::curdbi"}     = sub { "DBD::$dbi" };
                        *{"$pkg\::curqdb"}     = sub { $set->{quickdb} };
                        *{"$pkg\::curdialect"} = sub { $set->{dialect} };
                    }

                    my $lc_dial = lc($set->{dialect});
                    $lc_dial =~ s/::/_/g;

                    my $prefix;
                    if ($pkg->can('SCHEMA_DIR')) {
                        $prefix = $pkg->SCHEMA_DIR;
                    }
                    else {
                        $prefix = $file;
                        $prefix =~ s{\.t$}{}g;
                    }

                    my $sql_file = "${prefix}/$lc_dial";
                    my @check = ( "${sql_file}$set->{ver}.sql", "${sql_file}.sql" );
                    push @check => "${prefix}/mariadb.sql" if $sql_file =~ m/mariadb/;
                    push @check => "${prefix}/mysql.sql" if $sql_file =~ m/(mysql|mariadb)/;
                    $sql_file = first { -f $_ } @check;
                    my $db;
                    if ($sql_file) {
                        note "Loading SQL file: $sql_file\n";
                        $db = $set->{db}->(load_sql => [quickdb => $sql_file]);
                    }
                    else {
                        note "No sql file found, skipping...\n";
                        $db = $set->{db}->();
                    }

                    $code->($db);

                    sleep $END_DELAY if $END_DELAY;
                };
            }, 'force_fork');
        }
    }

    $pr->finish;
}

1;
