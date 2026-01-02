package DBIx::Auto::Migrate;

our $VERSION = "0.8";

use v5.16.3;
use strict;
use warnings;

use DBI;

sub _check_defined_sub {
    my ( $caller, $sub ) = @_;
    if ( !$caller->can($sub) ) {
        die
"To import '@{[__PACKAGE__]}' in '$caller' you must implement the '$sub' subroutine";
    }
}

sub import {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::finish_auto_migrate"} = sub {
        _migrations_finish($caller);
    };
}

sub _migrations_finish {
    my ($caller) = @_;
    _check_defined_sub( $caller, 'migrations' );
    _check_defined_sub( $caller, 'dsn' );
    _check_defined_sub( $caller, 'user' );
    _check_defined_sub( $caller, 'pass' );
    my $extra;
    if ( defined( my $extra_sub = $caller->can('extra') ) ) {
        $extra = $extra_sub->();
    }
    $extra //= {};
    my ( $dsn, $user, $pass ) = ( $caller->dsn, $caller->user, $caller->pass );

    if ( 'HASH' ne ref $extra ) {
        die "${caller}::extra should return a hashref or undef";
    }
    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${caller}::connect"} = sub {
            _connect_wrapper( $caller, 'connect', $dsn, $user, $pass, $extra );
        };
        *{"${caller}::connect_cached"} = sub {
            _connect_wrapper( $caller, 'connect_cached', $dsn, $user, $pass,
                $extra );
        };

    }
}

sub _connect_wrapper {
    my ( $caller, $sub, $dsn, $user, $pass, $extra ) = @_;
    my $dbh = DBI->can($sub)->(
        'DBI', $dsn, $user, $pass,
        {
            RaiseError => 1,
            Callbacks  => {
                connected => sub {
                    eval {shift->do('set timezone = UTC')};
                    return;
                }
            },
            %$extra,
        },
    );
    _migrate( $caller, $dbh );
    return $dbh;
}

sub _migrate {
    my ( $caller, $dbh ) = @_;
    local $dbh->{RaiseError} = 0;
    local $dbh->{PrintError} = 0;
    my @migrations = $caller->can('migrations')->();
    if ( _get_current_migration($dbh) > @migrations ) {
        warn "Something happened there, wrong migration number.";
    }
    if ( _get_current_migration($dbh) >= @migrations ) {
        say STDERR "Migrations already applied.";
        return;
    }
    _apply_migrations( $dbh, \@migrations );

}

sub _apply_migrations {
    my $dbh        = shift;
    my $migrations = shift;
    for ( my $i = _get_current_migration($dbh) ; $i < @$migrations ; $i++ ) {
        local $dbh->{RaiseError} = 1;
        my $current_migration = $migrations->[$i];
        my $migration_number  = $i + 1;
        _apply_migration( $dbh, $current_migration, $migration_number );
    }
}

sub _get_current_migration {
    my $dbh    = shift;
    my $result = $dbh->selectrow_hashref( <<'EOF', undef, 'current_migration' );
SELECT value FROM options WHERE name = ?;
EOF
    return int( $result->{value} // 0 );
}

sub _apply_migration {
    my $dbh               = shift;
    my $current_migration = shift;
    my $migration_number  = shift;
    {
        eval { $dbh->do($current_migration); };
        if ($@) {
            die "$current_migration\n failed with: $@";
        }
    }
    my $success = eval {
    $dbh->do( <<'EOF', undef, 'current_migration', $migration_number );
INSERT INTO options (name, value)
VALUES (?, ?) 
EOF
	    1;
    };
    if (!$success) {
	    $dbh->do( <<'EOF', undef,  $migration_number, 'current_migration' );
UPDATE options
SET value = ?
WHERE name = ?
EOF
    }
}
1;

=pod

=encoding utf-8

=head1 NAME

DBIx::Auto::Migrate - Wrap your database connections and automatically apply db migrations.

=head1 SYNOPSIS

 package MyCompany::DB;
 
 use v5.16.3;
 use strict;
 use warnings;

 use DBIx::Auto::Migrate;

 finish_auto_migrate;

 sub create_index {
 	my ($table, $column) = @_;
 	if (!$table) {
 		die 'Index requires table';
 	}
 	if (!$column) {
 		die 'Index requires column';
 	}
 	return "CREATE INDEX index_${table}_${column} ON $table ($column)";
 }

 sub migrations {
 	return (
 		'CREATE TABLE options (
 			id BIGSERIAL PRIMARY KEY,
 			name TEXT,
 			value TEXT,
 			UNIQUE (name)
 		)',
 		create_index(qw/options name/),
 		'CREATE TABLE users (
 			id BIGSERIAL PRIMARY KEY,
 			uuid TEXT NOT NULL,
 			username TEXT NOT NULL,
 			name TEXT NOT NULL,
 			surname TEXT NOT NULL,
 			UNIQUE(username)
 		)',
 		create_index(qw/users uuid/),
 		create_index(qw/users username/),
 	);
 }

 sub dsn {
 	return 'dbi:Pg:dbname=my_fancy_app_db';
 }

 sub user {
 	return 'user';
 }

 sub pass {
 	return 'supertopsecretdbpass';
 }

 sub extra {
 	{
 		PrintError => 1,
 	}
 }

And elsewhere:

 my $dbh = MyCompany::DB->connect;
 my $dbh = MyCompany::DB->connect_cached;

=head1 DESCRIPTION

Sometimes is convenient to be able to make server or desktop programs that
use a database with the ability to be automatically have their database
upgraded in runtime.

This module comes from a snippet of code I was copying all the time between
different projects with different database engines such as PostgreSQL and SQLite,
it is time to stop copying logic like this between projects and make public
my way to apply database migrations defined in code in a extensible way.

It is only possible to migrate forward so be careful.

To check an example project that uses this code you can check L<https://github.com/sergiotarxz/Perl-App-RSS-Social>

=head1 SUBS TO IMPLEMENT IN YOUR OWN DATABASE WRAPPER

=head2 migrations

 sub migrations {
 	return (
 		'CREATE TABLE options (
 			id BIGSERIAL PRIMARY KEY,
 			name TEXT,
 			value TEXT,
 			UNIQUE (name)
 		)',
 		'CREATE TABLE users (
 			id BIGSERIAL PRIMARY KEY,
 			uuid TEXT NOT NULL,
 			username TEXT NOT NULL,
 			name TEXT NOT NULL,
 			surname TEXT NOT NULL,
 			UNIQUE(username)
 		)',
 	);
 }

Returns a list of migrations, creating a options table in the first migration is
obligatory since it is internally used to keep track of the current migration number.

=head2 dsn

 sub dsn {
 	return 'dbi:Pg:dbname=my_fancy_app_db';
 }

Returns a valid DSN for L<DBI>, you can use any logic to return this, even reading a database config file.

=head2 user

 sub user { 'mydbuser' }

Returns a valid user for L<DBI>, you can use any logic to return this, even reading a database config file.

=head2 pass

 sub pass { 'mypass' }

Returns a valid password for L<DBI>, you can use any logic to return this, even reading a database config file.

=head2 extra

 sub extra {
 	{
 		PrintError => 1,
 	}
 }

You can optionally implement this method to pass extra options to L<DBI>, the
return must be a hashref or undef.

=head1 FINALIZING THE DATABASE WRAPPER CLASS

 finish_auto_migrate();

Calling this method will ensure your class is completely ready to be used,
you can do it at any point if every prerequisite is available.

=head1 METHODS AUTOMATICALLY AVAILABLE IN YOUR WRAPPER

=head2 connect

 my $dbh = MyCompany::DB->connect;

Same as L<DBI>::C<connect> but without taking any argument.

=head2 connect_cached

 my $dbh = MyCompany::DB->connect_cached;

Same as L<DBI>::C<connect_cached> but without taking any argument.

=head1 BUGS AND LIMITATIONS

Tries to be database independent, but I cannot really ensure it.

More testing is needed.

=head1 AUTHOR

SERGIOXZ - Sergio Iglesias

=head1 CONTRIBUTORS

SERGIOXZ - Sergio Iglesias

=head1 COPYRIGHT

Copyright © Sergio Iglesias (2025)

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
