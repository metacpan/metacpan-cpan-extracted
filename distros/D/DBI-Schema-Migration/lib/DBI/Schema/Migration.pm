package DBI::Schema::Migration;

use 5.24.0;

use strict;
use warnings;

use feature 'say';
use English;
use Exporter 'import';

use Moo;
use Term::ANSIColor 'colored';
use File::Slurper 'read_text';
use File::Basename;
use Scalar::Util 'blessed';

use constant {
    UP   => 'up',
    DOWN => 'down',
};

our $VERSION = '1.00';

has dbh => (
    is       => 'ro',
    requires => 1,
    isa      => sub {
        if ( not blessed $_[0]
            and not $_[0]->isa('DBI::db') )
        {
            say colored( "$_[0] is not DBI::db", 'red' );
            exit;
        }
    },
);

has dir => (
    is       => 'ro',
    required => 1,
);

sub init {
    my ($self) = @_;

    my @sql = <DATA>;
    my $sql = join '', @sql;

    if ( $self->_is_applied_migrations_table_exists() ) {
        say colored( 'Table applied_migrations already exists', 'yellow' );
        return 1;
    }

    else {
        $self->dbh->do($sql)
            or say colored( $self->dbh->errstr, 'red' )
            and exit;

        say colored(
            'Table applied_migrations successfully created',
            'green'
        );

        return 1;
    }
}

sub up {
    my ( $self, $num ) = @_;

    if ( not $self->_is_applied_migrations_table_exists() ) {
        say $self->_applied_migrations_not_exist_phrase();
        exit;
    }

    $self->dbh->{AutoCommit} = 0;

    my $dir  = $self->_detect_dir;
    my @dirs = sort $self->_dir_listing($dir);

    $num = $num || @dirs;
    my $completed = 0;

    for (@dirs) {
        if ( not $num ) {
            last;
        }

        elsif ( not $self->_is_migration_applied($_) ) {
            $self->_run_migration( $dir, $_, UP );
            $completed++;
            $num--;
        }
    }

    my $rows = $self->dbh->commit;

    if ( $rows < 0 ) {
        say colored( 'Could not run migrations', 'red' ) and exit;
    }

    $self->dbh->{AutoCommit} = 1;

    say colored( "Migration up:$completed", 'green' );

    return 1;
}

sub down {
    my ( $self, $num ) = @_;

    if ( not $self->_is_applied_migrations_table_exists() ) {
        say $self->_applied_migrations_not_exist_phrase();
        exit;
    }

    $self->dbh->{AutoCommit} = 0;

    my $dir  = $self->_detect_dir;
    my @dirs = sort { $b cmp $a } $self->_dir_listing($dir);

    $num = $num || @dirs;
    my $completed = 0;

    for (@dirs) {
        if ( not $num ) {
            last;
        }

        elsif ( $self->_is_migration_applied($_) ) {
            $self->_run_migration( $dir, $_, DOWN );
            $completed++;
            $num--;
        }
    }

    my $rows = $self->dbh->commit;
    if ( $rows < 0 ) {
        say colored( 'Could not rollback migrations', 'red' );
        exit;
    }

    $self->dbh->{AutoCommit} = 1;

    say colored( "Migration down:$completed", 'green' );

    return 1;
}

sub _is_applied_migrations_table_exists {
    my ($self) = @_;

    my $sth =
        $self->dbh->table_info( '%', '%', 'applied_migrations', 'TABLE' );
    my @row = $sth->fetchrow_array;

    $sth->finish;

    return @row ? 1 : 0;
}

sub _applied_migrations_not_exist_phrase {
    return colored(
        'Table applied_migrations does not exists. You should run init first',
        'red'
    );
}

sub _detect_dir {
    my ($self) = @_;

    my @dirs = (
        $self->dir,
        $ENV{PWD} . $self->dir,
        $ENV{PWD} . '/' . $self->dir,
        $ENV{PWD} . '/' . dirname($PROGRAM_NAME) . '/' . $self->dir,
    );

    for (@dirs) {
        if ( -d $_ ) {
            return $_;
        }
    }

    say colored(
        "Dir $self->{dir} does not exists, try to specify full path",
        'red'
    );
    exit;
}

sub _dir_listing {
    my ( $self, $dir ) = @_;

    opendir my $dh, $dir
        or say colored( "Couldn't open dir '$dir': $ERRNO", 'red' )
        and exit;
    my @dirs = readdir $dh;
    closedir $dh;

    return grep { !/^\.|\.{2}$/m } @dirs;
}

sub _is_migration_applied {
    my ( $self, $migration ) = @_;

    my $sql = 'SELECT migration FROM applied_migrations WHERE migration = ?';
    my $sth = $self->dbh->prepare($sql)
        or say colored( $self->dbh->errstr, 'red' )
        and exit;
    my $rv  = $sth->execute($migration);
    my @row = $sth->fetchrow_array;

    $sth->finish;

    if ( $rv < 0 ) {
        say colored( $sth->errstr );
        exit;
    }

    return @row;
}

sub _run_migration {
    my ( $self, $dir, $migration, $type ) = @_;

    my $filename = "${migration}_$type.sql";
    my $sql      = read_text "$dir/$migration/$filename";
    my $rows     = $self->dbh->do($sql);

    if ( $rows < 0 ) {
        say colored( $self->db->errstr, 'red' );
        exit;
    }

    if ( $type eq UP ) {
        $self->_save_migration($migration);
    }
    else {
        $self->_delete_migration($migration);
    }

    return 1;
}

sub _save_migration {
    my ( $self, $migration ) = @_;

    my $sql = 'INSERT INTO applied_migrations VALUES(?)';
    my $sth = $self->dbh->prepare($sql)
        or say colored( $self->dbh->errstr, 'red' )
        and exit;
    my $rv = $sth->execute($migration);

    $sth->finish;

    return $rv ne '0E0';
}

sub _delete_migration {
    my ( $self, $migration ) = @_;

    my $sql = 'DELETE FROM applied_migrations WHERE migration = ?';
    my $sth = $self->dbh->prepare($sql)
        or say colored( $self->dbh->errstr, 'red' )
        and exit;
    my $rv = $sth->execute($migration);

    $sth->finish;

    return $rv ne '0E0';
}

1;

__DATA__
CREATE TABLE applied_migrations (
    migration TEXT
);

__END__

# ABSTRACT: An easy way to start using migrations.

=pod

=encoding UTF-8

=head1 NAME

DBI::Schema::Migration - An easy way to start using migrations.

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use DBI; # it is assumed that you are using DBI to handle your database connections
    use DBI::Schema::Migration;

    my $driver   = "SQLite"; # just example, you can use mysql, postgres e.t.c
    my $database = "test.db";
    my $dsn      = "DBI:$driver:dbname=$database";
    my $userid   = "";
    my $password = "";
    my $dbh =
        DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) 
        or die $DBI::errstr;

    $migration = DBI::Schema::Migration->new( {
        dbh => $dbh, # connection handler
        dir => 'db/migrations', # path to directory with migrations
    } );

    $migration->init(); # create applied_migrations table

    $migration->up(1);   # run 1 migration
    $migration->up();    # run all migrations

    $migration->down(1); # rollback 1 migration
    $migration->down();  # rollback all migrations

=head1 DESCRIPTION

Schema migration is a tool that helps to apply incremental and reversible changes to you relational database.
You could build cli util or use this class whintin yor ci/cd script.
This module relies on DBI and the database connection it creates.
It only works with migrations written in sql.

Migration in terms of this module is a directory consisting of two files:
    1 *_up.sql   - apply changes
    2 *_down.sql - reverse changes

Example:
    migrations/
   |
   |-- 01_create_table_users/
   |     \
   |      \-- 01_create_table_users_up.sql
   |      |
   |      |-- 01_create_table_users_down.sql
   |
   |-- 02_add_users/
   |     \
   |      \-- 02_add_users_up.sql
   |      |
   |      |-- 02_add_users_down.sql

As you can see, there are some naming conventions:
    1 Migrations starts with a number that determines the order 
    2 Migrations ends with up.sql or down.sql 

Once a migration has been applied, it is stored in the database, and
the migration will not be applied again, until your reverse it with
down method.  

=head2 CONFIGURATION

=over 4

=item I<dbh> - database handler 

=item I<dir> - path to migrations directory, full or relative

=back

=head2 METHODS

=head3 up($num)

Will apply $num migrations or all of them if $num is not specified.

=head3 down($num)

Will reverse $num migrations or all of them if $num is not specified.

=head1 BUGS

If you find one, please let me know.

=head1 SOURCE CODE REPOSITORY

https://github.com/AlexP007/DBI-Migration - fork or add pr.

=head1 AUTHOR

Alexander Panteleev <alexpan at cpan dot org>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Alexander Panteleev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
