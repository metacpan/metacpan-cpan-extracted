#!/usr/bin/perl -w
package DBIx::VersionedSubs;
use strict;
use DBI;
use POSIX qw(strftime);
use base 'Class::Data::Inheritable';

=head1 NAME

DBIx::VersionedSubs - all your code are belong into the DB

=head1 SYNOPSIS

    package My::App;
    use strict;
    use base 'DBIx::VersionedSubs';

    package main;
    use strict;

    My::App->startup($dsn);
    while (my $request = Some::Server->get_request) {
        My::App->update_code; # update code from the DB
        My::App->handle_request($request);
    }

And C<handle_request> might look like the following in the DB:

    sub handle_request {
        my ($request) = @_;
	my %args = split /[=;]/, $request;
	my $method = delete $args{method};
	no strict 'refs';
	&{$method}( %args );
    }

See C<eg/> for a sample HTTP implementation of a framework based
on this concept.

=head1 ABSTRACT

This module implements a minimal driver to load 
your application code from a database into a namespace
and to update that code whenever the database changes.

=head1 TABLES USED

This module uses two tables in the database, C<code_live> and C<code_history>.
The C<code_live> table stores the current version of the code and is used to
initialize the namespace. The C<code_history> table stores all modifications
to the C<code_live> table, that is, insertions, deletions and modifications
of rows in it. It is used to determine if the code has changed and what
changes to apply to the namespace to bring it up to par with the
database version.

The two tables are presumed to have a layout like the following:

    create table code_live (
        name varchar(256) not null primary key,
        code varchar(65536) not null
    );

    create table code_history (
        version integer primary key not null,
        timestamp varchar(15) not null,
        name varchar(256) not null,
        action varchar(1) not null, -- IUD, redundant with old_* and new_*
        old_code varchar(65536) not null,
        new_code varchar(65536) not null
    );

Additional columns are ignored by this code. It is likely prudent
to create an index on C<code_history.version> as that will be used
for (descending) ordering of rows.

=cut

__PACKAGE__->mk_classdata($_)
    for qw(dbh code_version code_live code_history code_source verbose);

use vars qw'%default_values $VERSION';

$VERSION = '0.08';

%default_values = (
    dbh          => undef,
    code_source  => {},
    code_live    => 'code_live',
    code_history => 'code_history',
    code_version => 0,
    verbose      => 0,
);

=head1 CLASS METHODS

=head2 C<< Package->setup >>

Sets up the class data defaults:

    code_source  => {}
    code_live    => 'code_live',
    code_history => 'code_history',
    code_version => 0,
    verbose      => 0,

C<code_source> contains the Perl source code for all loaded functions.
C<code_live> and C<code_history> are the names of the two tables
in which the live code and the history of changes to the live code
are stored. C<code_version> is the version of the code when it
was last loaded from the database.

The C<verbose> setting determines if progress gets output to
C<STDERR>.
Likely, this package variable will get dropped in favour of
a method to output (or discard) the progress.

=cut

sub setup {
    my $package = shift;
    warn "Setting up $package defaults"
        if $package->verbose;
    my %defaults = (%default_values,@_);
    for my $def (keys %defaults) {
        if (! defined $package->$def) {
            $package->$def($defaults{$def});
        };
    }
    $package;
};

=head2 C<< Package->connect DSN,User,Pass,Options >>

Connects to the database with the credentials given.

If called in void context, stores the DBI handle in the
C<dbh> accessor, otherwise returns the DBI handle.

If you already have an existing database handle, just
set the C<dbh> accessor with it instead.

=cut

sub connect {
    my ($package,$dsn,$user,$pass,$options) = @_;
    if (defined wantarray) {
        DBI->connect($dsn,$user,$pass,$options)
            or die "Couldn't connect to $dsn/$user/$pass/$options";
    } else {
        $package->dbh(DBI->connect($dsn,$user,$pass,$options));
    }
};

=head2 C<< Package->create_sub NAME, CODE >>

Creates a subroutine in the Package namespace.

If you want a code block to be run automatically
when loaded from the database, you can name it C<BEGIN>.
The loader code basically uses

    package $package;
    *{"$package\::$name"} = eval "sub { $code }"

so you cannot stuff attributes and other whatnot 
into the name of your subroutine, not that you should.

One name is special cased - C<BEGIN> will be immediately
executed instead of installed. This is most likely what you expect.
As the code elements are loaded by C<init_code> in alphabetical
order on the name, your C<Aardvark> and C<AUTOLOAD> subroutines
will still be loaded before your C<BEGIN> block runs.

The C<BEGIN> block will be called with the package name in C<@_>.

Also, names like C<main::foo> or C<Other::Package::foo> are possible
but get stuffed below C<$package>. The practice doesn't get saner there.

=cut

sub create_sub {
    my ($package,$name,$code) = @_;
    my $package_name = ref $package || $package;

    my $ref = $package->eval_sub($package_name,$name,$code);
    if ($ref) {
        if ($name eq 'BEGIN') {
            $ref->($package);
            return undef
        } else {
            no strict 'refs';
            no warnings 'redefine';
            *{"$package\::$name"} = $ref;
            $package->code_source->{$name} = $code;
            #warn "Set $package\::$name to " . $package->code_source->{$name};
            return $ref
        };
    };
}

=head2 C<< Package->eval_sub PACKAGE, NAME, CODE >>

Helper method to take a piece of code and to return
a code reference with the correct file/line information.

Raises a warning if code doesn't compile. Returns
the reference to the code or C<undef> if there was an error.

=cut

sub eval_sub {
    my ($self,$package,$name,$code) = @_;
    my $perl_code = <<CODE;
        package $package;
#line $package/$name#1
        sub {$code} 
CODE

    my $ref = eval $perl_code;
    if (my $err = $@) {
        warn $perl_code . "\n$package\::$name>> $err";
	return undef
    } else {
        return $ref
    };
};

=head2 C<< Package->destroy_sub $name >>

Destroy the subroutine named C<$name>. For the default
implementation, this replaces the subroutine with a
dummy subroutine that C<croak>s.

=cut

sub destroy_sub {
    my ($package,$name) = @_;
    $package->create_sub($name,<<ERROR_SUB);
        use Carp qw(croak);
        croak "Undefined subroutine '$name' called"
ERROR_SUB
    delete $package->code_source->{$name};
};

=head2 C<< Package->live_code_version >>

Returns the version number of the live code
in the database.

This is done with a C< SELECT max(version) FROM ... > query,
so this might scale badly on MySQL which (I hear) is bad
with queries even against indexed tables. If this becomes
a problem, changing the layout to a single-row table which
stores the live version number is the best approach.

=cut

sub live_code_version {
    my ($package) = @_;
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL', $package->code_history);
        SELECT max(version) FROM %s
SQL
    $sth->execute();
    my ($result) = $sth->fetchall_arrayref();
    $result->[0]->[0] || 0
}

=head2 C<< Package->init_code >>

Adds / overwrites subroutines/methods in the Package namespace
from the database.

=cut

sub init_code {
    my ($package) = @_;
    my $table = $package->code_live;
    #warn "Loading code for $package from $table";
    my $sql = sprintf <<'SQL', $table;
        SELECT name,code FROM %s
            ORDER BY name
SQL

    my $sth = $package->dbh->prepare_cached($sql);
    $sth->execute();
    while (my ($name,$code) = $sth->fetchrow()) {
        $package->create_sub($name,$code);
    }

    $package->code_version($package->live_code_version);
};

=head2 C<< Package->update_code >>

Updates the namespace from the database by loading
all changes.

Note that if you have/use closures or iterators,
these will behave weird if you redefine a subroutine
that was previously closed over.

=cut

sub update_code {
    my ($package) = @_;
    my $version = $package->code_version || 0;
    #warn "Checking against $version";
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL', $package->code_history);
        SELECT distinct name,action,new_code,version FROM %s
            WHERE version > ?
            ORDER BY version DESC
SQL

    $sth->execute($version);

    my %seen;

    my $current_version = $version || 0;
    while (my ($name,$action,$code,$new_version) = $sth->fetchrow()) {
        next if $seen{$name}++;
        
        warn "Reloading $name"
            if $package->verbose;
        $current_version = $current_version < $new_version 
                         ? $new_version
                         : $current_version;

        if ($action eq 'I') {
            $package->create_sub($name,$code);
        } elsif ($action eq 'U') {
            $package->create_sub($name,$code);
        } elsif ($action eq 'D') {
	    $package->destroy_sub($name);
        };
    }
    $package->code_version($current_version);
};

=head2 C<< Package->add_code_history Name,Old,New,Action >>

Inserts a new row in the code history table.

This
would be done with triggers on a real database,
but my development target includes MySQL 3 and 4.

=cut

sub add_code_history {
    my ($package,$name,$old_code,$new_code,$action) = @_;
    my $ts = strftime('%Y%m%d-%H%M%S',gmtime());
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL',$package->code_history);
        INSERT INTO %s (name,old_code,new_code,action,timestamp) VALUES (?,?,?,?,?)
SQL
    $sth->execute($name,$old_code,$new_code,$action,$ts);
}

=head2 C<< Package->update_sub name,code >>

Updates the code for the subroutine C<Package::$name>
with the code given.

Note that the update only happens in the database, so the change
will only take place on the next roundtrip / code refresh.

This cannot override subroutines that don't exist in the database.

=cut

sub update_sub {
    my ($package,$name,$new_code) = @_;
    $package->add_code_history($name,$package->code_source->{$name},$new_code,'U');
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL',$package->code_live);
        UPDATE %s SET code=?
        WHERE name=?
SQL
    $sth->execute($new_code,$name);
};


=head2 C<< Package->insert_sub name,code >>

Inserts the code for the subroutine C<Package::$name>.

Note that the insert only happens in the database, so the change
will only take place on the next roundtrip / code refresh.

This can also be used to override methods / subroutines that
are defined elsewhere in the Package:: namespace.

=cut

sub insert_sub {
    my ($package,$name,$new_code) = @_;
    $package->add_code_history($name,'',$new_code,'I');
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL',$package->code_live);
        INSERT INTO %s (name,code) VALUES (?,?)
SQL
    $sth->execute($name,$new_code);
};

=head2 C<< Package->redefine_sub name,code >>

Inserts or updates the code for the subroutine C<Package::$name>.

Note that the change only happens in the database, so the change
will only take place on the next roundtrip / code refresh.

This can be used to override methods / subroutines that
are defined in the database, elsewhere in the Package:: 
namespace or not at all.

=cut

sub redefine_sub {
    my ($package,$name,$new_code) = @_;
    
    if (! eval { $package->update_sub($name,$new_code) }) {
        warn "Inserting $name"
            if $package->verbose;
        $package->insert_sub($name,$new_code)
    }
};

=head2 C<< Package->delete_sub name,code >>

Deletes the code for the subroutine C<Package::$name>.

Note that the update only happens in the database, so the change
will only take place on the next roundtrip / code refresh.

If you delete the row of a subroutine that overrides a subroutine
declared elsewhere (for example in Perl code), the non-database Perl code
will not become
visible to the Perl interpreter until the next call to
C<< Package->init_code >>,
that is, likely until the next process restart. This will lead to very
weird behaviour, so don't do that.

=cut

sub delete_sub {
    my ($package,$name,$new_code) = @_;
    $package->add_code_history($name,$package->code_source->{$name},'','D');
    my $sth = $package->dbh->prepare_cached(sprintf <<'SQL',$package->code_live);
        -- here's a small race condition
        -- - delete trumps insert/update
        DELETE FROM %s WHERE name = ?
SQL
    $sth->execute($name);
};

=head2 C<< Package->startup(DBIargs) >>

Shorthand method to initialize a package
from a database connection.

If C<< Package->dbh >> already returns a true
value, no new connection is made.

This method is equivalent to:

    if (! Package->dbh) {
        Package->connect(@_);
    };
    Package->setup;
    Package->init_code;

=cut

sub startup {
    my $package = shift;
    if (! $package->dbh) {
        $package->connect(@_);
    };
    $package->setup;
    $package->init_code;
}

=head1 BEST PRACTICES

The most bare-bones hosting package looks like the following (see also
C<eg/lib/My/App.pm> in the distribution):

    package My::App;
    use strict;
    use base 'DBIx::VersionedSubs';

Global variables are best declared within the C<BEGIN> block. You will find
typos or use of undeclared variables reported to C<STDERR> as the
subroutines get compiled.

=head1 TODO

=over 4

=item * Implement closures (marked via a bare block)

=item * Find a saner way instead of C<< ->setup >> and C<%default_values>
for configuring the initial class values while still preventing hashref
usage across packages. The "classic" approach of using Class::Data::Inheritable
means that there is the risk of sharing the C<code_source> reference across
namespaces which is wrong. Maybe the accessor should simply be smart
and depend on the namespace it was called with instead of a stock accessor

=item * Discuss whether it's sane
to store all your code with your data in the database.
It works well for L<http://perlmonks.org/> and the
Everything Engine.

=back

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 CREDITS

Tye McQueen for suggesting the module name

=head1 SEE ALSO

The Everything Engine, L<http://everydevel.everything2.com/>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 ALTERNATIVE NAMES

DBIx::Seven::Days, Nothing::Driver, Corion's::Code::From::Outer::Space

=cut

1;
