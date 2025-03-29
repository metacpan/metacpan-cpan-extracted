package DBIx::QuickDB::Pool;
use strict;
use warnings;

our $VERSION = '0.000038';

use Carp qw/croak/;
use Fcntl qw/:flock/;
use File::Path qw/remove_tree make_path/;
use Digest::SHA qw/sha1_hex/;
use Scalar::Util qw/refaddr/;
use Time::HiRes qw/time/;

use DBIx::QuickDB;

use DBIx::QuickDB::Util::HashBase qw{
    +cache_dir
    +instance_dir

    <library

    +databases

    update_checksums
    purge_old
    verbose
    show_diag
};

sub import {
    my $class  = shift;
    my %params = @_;

    $params{library} ||= caller;

    my $inst = $class->new(%params);

    $inst->export();
}

sub init {
    my $self = shift;

    croak "'cache_dir' is a required_attribute" unless $self->{+CACHE_DIR};

    croak "'cache_dir' must point to an existing directory"
        unless -d $self->{+CACHE_DIR};

    croak "'$self->{+INSTANCE_DIR}' must be an existing directory"
        if $self->{+INSTANCE_DIR} && !-d $self->{+INSTANCE_DIR};

    $self->{+LIBRARY} //= caller(1);

    $self->{+VERBOSE}          //= 0;
    $self->{+PURGE_OLD}        //= 0;
    $self->{+UPDATE_CHECKSUMS} //= 1;

    $self->{+DATABASES} //= {};
}

sub clear_old_cache {
    my $self = shift;
    my ($age) = @_;

    my $dir = $self->{+CACHE_DIR};

    opendir(my $dh, $dir) or die "Could not open cache dir '$dir': $!";
    for my $name (readdir($dh)) {
        next if $name =~ m/\./;

        my $full = "$dir/$name";
        next unless -d $full;

        my $file = "$full/cloned";
        next unless -f $file;

        open(my $fh, '<', $file) or next;
        chomp(my $stamp = <$fh>);

        next unless $age <= (time - $stamp);

        eval {
            remove_tree($full, {safe => 1});
            unlink("$full.lock") if -e "$full.lock";
            unlink("$full.READY") if -e "$full.READY";
            1;
        } or warn $@;
    }
}

sub export {
    my $self = shift;

    my $library = $self->{+LIBRARY};

    my $qdb    = sub { $self };
    my $build  = sub { $self->add_db(@_, caller => [caller()]) };
    my $db     = sub { $self->fetch_db(@_, caller => [caller()]) };
    my $driver = sub { $self->add_driver(@_, caller => [caller()]) };

    no strict 'refs';
    *{"$library\::QDB_POOL"} = $qdb;
    *{"$library\::driver"}   = $driver;
    *{"$library\::build"}    = $build;
    *{"$library\::db"}       = $db;

    push @{"$library\::EXPORT_OK"} => 'db';
}

sub throw {
    my $self = shift;
    my ($msg, %params) = @_;
    my $caller = $params{caller} || [caller(1)];
    die "$msg at $caller->[1] line $caller->[2].\n";
}

sub alert {
    my $self = shift;
    my ($msg, %params) = @_;
    my $caller = $params{caller} || [caller(1)];
    warn "$msg at $caller->[1] line $caller->[2].\n";
}

sub diag {
    my $self = shift;
    my ($msg, %params) = @_;
    my $show = $self->{+VERBOSE} || $self->{+SHOW_DIAG};
    return unless $show;

    # Only append caller info when asked
    if (my $caller = $params{caller}) {
        $msg .= " at $caller->[1] line $caller->[2].";
    }

    if ($show > 1) {
        print STDERR "$msg\n";
    }
    else {
        print STDOUT "$msg\n";
    }

    return;
}

sub add_db {
    my $self = shift;
    my ($name, %params) = @_;

    my $from      = $params{from}                or $self->throw("You must specify a 'from' database", %params);
    my $from_spec = $self->{+DATABASES}->{$from} or $self->throw("Cannot build '$name' from '$from' which has not been defined");

    $self->throw("Database '$name' is already defined", %params)
        if $self->{+DATABASES}->{$name};

    $self->throw("'build' is a required argument", %params)
        unless $params{build};

    $self->throw("'$params{build}' is not a valid builder, it must be either a coderef, or a class method on '$self->{+LIBRARY}'", %params)
        unless $params{build} && ref($params{build}) eq 'CODE' || $self->{+LIBRARY}->can($params{'build'});

    $self->throw("A checksum sub or method name is required")
        unless $params{checksum};

    unless (ref($params{checksum}) eq 'CODE' || $self->{+LIBRARY}->can($params{checksum})) {
        $self->throw(
            "'$params{checksum}' is not a valid checksum calculator, it must be either a coderef or a class method on '$self->{+LIBRARY}'",
            %params,
        );
    }

    $self->{+DATABASES}->{$name} = {%params, name => $name, driver => $from_spec->{driver}};

    return;
}

sub add_driver {
    my $self = shift;
    my ($driver, %params) = @_;

    my $name = $params{name};
    unless ($name) {
        $name = $driver;
        $name =~ s/^.*:://g;
        $params{name} = $name;
    }

    $self->throw("Database '$name' is already defined", %params)
        if $self->{+DATABASES}->{$name};

    $driver = "DBIx::QuickDB::Driver::$driver"
        unless $driver =~ s/^\+// || $driver =~ m/^DBIx::QuickDB::Driver::/;

    my $file = $driver;
    $file =~ s{::}{/}g;
    $file .= ".pm";
    eval { require $file; 1 } or $self->throw("Could not load driver '$driver': $@", %params);

    my ($viable, $why_not) = $driver->viable({bootstrap => 1, autostart => 1, load_sql => 1});
    $self->throw("Driver '$driver' is not viable:\n$why_not\n")
        unless $viable;

    $params{driver} = $driver;
    $params{checksum} //= \&driver_checksum;

    unless (ref($params{checksum}) eq 'CODE' || $self->{+LIBRARY}->can($params{checksum})) {
        $self->throw(
            "'$params{checksum}' is not a valid checksum calculator, it must be either a coderef or a class method on '$self->{+LIBRARY}'",
            %params,
        );
    }

    $self->{+DATABASES}->{$name} = \%params;

    return;
}

sub fetch_db {
    my $self = shift;
    my ($name, %params) = @_;

    my $spec = $self->{+DATABASES}->{$name};

    $self->throw("Invalid database name: $name", %params)
        unless $spec;

    delete $params{caller};

    my $from = $self->vivify_db($spec);

    my %add_args;
    if (my $dir = $self->{+INSTANCE_DIR}) {
        require File::Temp;
        $add_args{dir} = File::Temp::tempdir("$ENV{USER}-XXXXXX", CLEANUP => 0, DIR => $dir);
    }

    return $from->clone(autostart => 1, autostop => 1, cleanup => 1, %add_args, %{$spec->{clone_args} || {}}, %params);
}

sub vivify_db {
    my $self = shift;
    my ($spec) = @_;

    my ($db, $csum) = $self->cache_check($spec);

    return $db if $db;

    $spec->{built_checksum} = $csum;
    my $dir = "$self->{+CACHE_DIR}/$spec->{name}-$csum";
    $spec->{dir} = $dir;

    # Already built, we can use it.
    if (-e "$dir.READY") {
        $self->diag("$$ Found existing '$spec->{name}' database at '$dir'...");
        return $spec->{db} = $self->reclaim($dir => $spec);
    }

    my $lock    = "$dir.lock";
    my $lock_fh = $self->lock($lock);

    # Another process got the lock first and built the db, start the loop over to build it.
    if (-e "$dir.READY") {
        # Unlock immedietly to unblock other processes
        $self->unlock($lock_fh, $lock);
        $self->diag("$$ Previous lock holder built the '$spec->{name}' db...");
        $db = $self->reclaim($dir => $spec);
    }
    else {
        $db = $self->build_db($dir => $spec, stop => 1);
        # Unlock AFTER building
        $self->unlock($lock_fh, $lock);
    }

    $db->stop() if $db->started;

    return $spec->{db} = $db;
}

sub cache_check {
    my $self = shift;
    my ($spec) = @_;

    # If we do not have 'update_checksums' set then we do not re-check every time.
    return ($spec->{db}, $spec->{built_checksum})
        if $spec->{db} && $spec->{built_checksum} && !$self->{+UPDATE_CHECKSUMS};

    my $valid = 1;

    my $meth = $spec->{checksum} or die "Database '$spec->{name}' has no checksum method";
    my $csum = $self->{+LIBRARY}->$meth(name => $spec->{name}, qdb => $self, spec => $spec);

    my $parent_changed = 0;
    if (my $from = $spec->{from}) {
        my ($parent, $psum) = $self->cache_check($self->{+DATABASES}->{$from});

        unless ($parent) {
            $parent_changed = 1;
            $valid = 0;
        }

        # Composite checksum

        $self->diag("$$ Combining checksums from '$spec->{name}': '$csum' and parent '$from': '$psum'...");
        $csum = sha1_hex("$psum$csum");
        $self->diag("$$ Combined checksum from '$spec->{name}' and parent '$from': '$csum'.");
    }

    # shorten the checksum to 10 characters for shorter dir names
    # This is mainly because unix sockets have a max filename of 107 bites.
    # Sometimes the temp dir + other temp dirs before our socket make the
    # length too much.
    $csum = substr($csum, 0, 10);

    my $old = $spec->{built_checksum};

    $valid &&= $old;
    $valid &&= $spec->{db} ? 1 : 0;
    $valid &&= $old eq $csum;
    $valid &&= !$parent_changed;

    return ($spec->{db}, $csum) if $valid;

    $self->diag("$$ Invalidated '$spec->{name}' due to " . ($parent_changed ? 'parent' : 'checksum') . " change...")
        if $old || $spec->{db};

    delete $spec->{db};
    delete $spec->{built_checksum};

    remove_tree($spec->{dir}, {safe => 1}) if $self->{+PURGE_OLD};

    delete $spec->{dir};

    return (undef, $csum);
}

sub build_db {
    my $self = shift;
    my ($dir, $spec, %params) = @_;

    # Create the dir, deleting it if it exists
    remove_tree($dir, {safe => 1}) if -d $dir;
    make_path($dir);
    $spec->{dir} = $dir;

    my $db;
    if ($spec->{from}) {
        $db = $self->build_via_clone($dir, $spec);
    }
    else {
        $db = $self->build_via_driver($dir, $spec);
    }

    $db->stop if $params{stop};

    $self->diag("$$ Built new db '$spec->{name}', marking as ready!");
    open(my $ready, '>', "$dir.READY") or die "Could not create ready file '$dir.READY': $!";
    print $ready "1\n";
    close($ready);

    return $db;
}

sub build_via_clone {
    my $self = shift;
    my ($dir, $spec) = @_;

    $self->diag("$$ Building new db '$spec->{name}' from existing db '$spec->{from}'...");

    my $from_spec = $self->{+DATABASES}->{$spec->{from}};
    my $from      = $self->vivify_db($from_spec);

    $self->write_clone_stamp($from);
    $spec->{driver} = $from_spec->{driver};
    $spec->{driver_args} //= $from_spec->{driver_args};
    $spec->{clone_args}  //= $from_spec->{clone_args};

    my $db = $from->clone(%{$spec->{clone_args} || {}}, dir => $dir, autostart => 0, autostop => 1, verbose => $self->{+VERBOSE});

    $db->start();
    my $builder = $spec->{build};
    $self->{+LIBRARY}->$builder($db, name => $spec->{name}, dir => $dir, qdb => $self);

    return $db;
}

sub build_via_driver {
    my $self = shift;
    my ($dir, $spec) = @_;

    $self->diag("$$ Building new base db '$spec->{name}'...");

    my $db = $spec->{driver}->new(
        %{$spec->{driver_args} || {}},
        dir       => $dir,
        verbose   => $self->{+VERBOSE},
        autostart => 0,
        autostop  => 1,
    );

    $db->bootstrap();

    if (my $builder = $spec->{build}) {
        $db->start();
        $self->{+LIBRARY}->$builder($db, name => $spec->{name}, dir => $dir, qdb => $self);
    }

    $self->write_clone_stamp($db);

    return $db;
}

sub write_clone_stamp {
    my $self = shift;
    my ($db) = @_;

    my $stamp = time();
    open(my $fh, '>', $db->dir . '/cloned') or die "$!";
    print $fh $stamp, "\n";
    close($fh);

    return $stamp;
}

sub unlock {
    my $self = shift;
    my ($lock_fh, $lock) = @_;

    $self->diag("$$ Releasing lock '$lock'...");
    flock($lock_fh, LOCK_UN) or die "Could not unlock '$lock': $!";
    close($lock_fh);

    return 1;
}

sub lock {
    my $self = shift;
    my ($lock) = @_;

    open(my $lh, '>>', $lock) or die "Could not open lock file '$lock': $!";

    $self->diag("$$ Acquiring lock '$lock'...");
    flock($lh, LOCK_EX) or die "Could not get lock '$lock': $!";
    $self->diag("$$ Lock acquired '$lock'...");

    seek($lh, 0, 0);
    return $lh;
}

sub reclaim {
    my $self = shift;
    my ($dir, $spec) = @_;

    return $spec->{driver}->new(
        %{$spec->{driver_args} || {}},
        dir       => $dir,
        verbose   => $self->{+VERBOSE},
        autostart => 0,
        autostop  => 1,
    );
}

sub driver_checksum {
    my $library = shift;
    my %params  = @_;

    my $spec    = $params{spec};
    my $version = $spec->{driver}->version_string($spec->{driver_args});

    return sha1_hex($version);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Pool - Define a pool of databases to clone on demand.

=head1 DESCRIPTION

This library lets you define a pool of databases to clone on demand. This lets
you incrementally build databases starting with a driver. Each database you
build can either be based of a previous one, or started from scratch.

This tool lets you buid multiple nested clean database trees. You can then
clone instances off these clean ones as needed.

This library can spin up clean copies of databases at any states you define,
and it can do so FAST by cloning data directories instead of building
everything back up from nothing.

This library will build databases on demand, no cost for databases you define
but never use.

This library will rebuild databases when schema files or installed database
version change.

This library can be used by concurrent processes that may try to build/consume
the same databases from the same cache dir.

=head1 DECLARATIVE SYNOPSIS

=head2 YOUR POOL LIBRARY

    package My::Pool;
    use strict;
    use warnings;

    use DBIx::QuickDB::Pool cache_dir => "$ENV{HOME}/databases";

    # This will define a clean database called 'PostgreSQL' that we can always
    # clone, or build on top of.
    driver 'PostgreSQL';

    build schema => (
        # This one will be built on top of a clone of the 'PostgreSQL' clean
        # db.
        from => 'PostgreSQL',

        # You must provide a way to invalidate the current, usually this would
        # return a sha1 of the schema files or similar. If you do not want it
        # to detect changes just have the subroutine return a string such as
        # "never changes".
        checksum => sub { ...; return "something" },

        # Any database you define, apart from drivers, needs a build callback
        build => sub {
            my $class = shift; # The current package
            my ($db) = @_;

            # $db will already be started for you, and will be stopped as soon
            # as this sub returns.

            @ Load the schema
            $db->load_sql(myapp => "path/to/myapp_schema.sql");
        },
    );

    build scenario_foo => (
        from => 'schema',
        checksum => sub { ... },
        build => sub {
            my $class = shift;
            my ($db) = @_;

            ... Load data for scenario 'foo' ...
        },
    );

    build scenario_bar => (
        from => 'schema',
        checksum => sub { ... },
        build => sub {
            my $class = shift;
            my ($db) = @_;

            ... Load data for scenario 'bar' ...
        },
    );

    build scenario_foo_and_bar => (
        from => 'foo',
        checksum => sub { ... },
        build => sub {
            my $class = shift;
            my ($db) = @_;

            ... Load data for scenario 'bar' ...
        },
    );

    1;

=head2 POOL CONSUMERS

    # This will import db() from the My::Pool library.
    use Importer 'My::Pool' => 'db';

    # This will return a new clone of foo, changing it will not effect the
    # original 'foo' built by the library.
    my $clone_of_foo = db('foo');

    # Same for bar
    my $clone_of_bar = db('bar');

    # This gets a NEW clone of 'foo'. Changes in this db will NOT effect
    # $clone_of_foo.
    my $other_clone_of_foo = db('foo');

    ... Change Schema ...

    # This will rebuild schema, then rebuild foo using the new schema.
    # (If update_checksums has not been turned off)
    my $fresh_foo = db('foo');

=head1 EXPORTS

=over 4

=item $pool = QDB_POOL()

This will return the instance of C<DBIx::QuickDB::Pool> associated with your
package.

=item driver $DRIVER

=item driver $DRIVER => (%SPEC)

Define a new driver you can use as a basis for your database states.

C<$DRIVER> can be shorthand C<'PostgreSQL'> or it can be fully qualified if you
prefix it with a '+' C<'+DBIx::QuickDB::Driver::PostgreSQL'>.

The name will be the last part of the driver package name Example:
C<'PostgreSQL'> unless you override it.

The following specifications are allowed:

=over 4

=item name => $NAME

You can use this to override the default database name.

=item checksum => sub { ... }

=item checksum => "method_name"

You can use this to override the default checksum calculator drivers use.
Normally the default will return a sha1 of the version information of the
locally installed database tools.

This can be a subref, or the name of a method defined on your package.

=item build => sub { ... }

=item build => "method_name"

This is not necessary on a driver database, however if you want to do anything
to the clean database before anything builds off of it you can. If you only
have 1 schema to load you can pop it in here instead of creating a schema
specific database. Keep in mind you will have to manage checksum calculation
for both, and this will have to be rebuilt for both schema changes and db tool
version changes.

This can be a subref, or the name of a method defined on your package.

=item driver_args => \%ARGS

You can pass in a hashref of arguments to pass into the driver when
initializing the database:

    driver_args => { verbose => 0, autostart => 0, autostop => 1 },

=item clone_args => \%ARGS

Same as driver_args, except these are used when cloning a database. This will
be inherited by databases that are built off of this one.

=back

=item build $NAME => (from => $PARENT_OR_DRIVER, build => \&BUILDER, checksum => \&CHECKSUM)

=item build $NAME => (from => $PARENT_OR_DRIVER, build => $BUILDER_METHOD_NAME, checksum => $CHECKSUM_METHOD_NAME)

=item build $NAME => (%SPEC)

Define a new database state with the given C<$NAME>.

The following specifications are available:

=over 4

=item from => $PARENT_OR_DRIVER

This specifies the parent database or driver to build off of.

=item build => sub { ... }

=item build => $BUILDER_METHOD_NAME

Any database that is not a base driver needs to do build some kind of state to
be useful. An example is loading schema, or loading fixture data. This is where
you do that.

    sub {
        my $class = shift;
        my ($db) = @_;

        # $db will already be started for you
        $db->load_sql(myapp => "path/to/myapp_schema.sql");

        # $db will be stopped for you automatically.
    }

=item checksum => sub { ... }

=item checksum => $CHECKSUM_METHOD_NAME

This must return a string. If the data this database is built from will never
change you can return a constant string. If the data can change you should
probably either return a version string, or a sha1 of the data.

This is used to check if a database needs to be rebuilt due to external
changes, such as a C<schema.sql> file being modified.

=item clone_args => \%ARGS

You can pass in a hashref of arguments to pass into the driver when
cloning the database:

    clone_args => { verbose => 0, autostart => 0, autostop => 1 },

This will be inherited by databases that are built off of this one. This will
also override any that may have been inherited from a parent.

=back

=item $db = db($NAME)

Fetch a fresh clone of the specified database. This will be an isolated copy
that you can play with. Neither the original nor any other copy will be
effected by anything you do. When you are done simply disgard the copy.

If the database, or ant of its parents have not been built yet, they will be
built before you get your fresh copy. The first time this is called may be
slow, but future calls will use cached data making them very fast.

=item @EXPORT_OK

C<db()> is added to your packages C<@EXPORT_OK> variable on import. This allows
other modules to import the method in order to get clones of the databases you
defined.

    use Importer 'My::Pool' => 'db';

    my $db = db('foo');

=back

=head1 OO SYNOPSIS

    use DBIx::Class::Pool();

    my $pool = DBIx::Class::Pool->new(
        cache_dir => "$ENV{HOME}/databases",
    );

    # This will define a clean database called 'PostgreSQL' that we can always
    # clone, or build on top of.
    $pool->add_driver('PostgreSQL');

    $pool->add_db(
        'schema',

        # This one will be built on top of a clone of the 'PostgreSQL' clean
        # db.
        from => 'PostgreSQL',

        # You must provide a way to invalidate the current, usually this would
        # return a sha1 of the schema files or similar. If you do not want it
        # to detect changes just have the subroutine return a string such as
        # "never changes".
        checksum => sub { ...; return "something" },

        # Any database you define, apart from drivers, needs a build callback
        build => sub {
            my $class = shift; # The current package
            my ($db) = @_;

            # $db will already be started for you, and will be stopped as soon
            # as this sub returns.

            @ Load the schema
            $db->load_sql(myapp => "path/to/myapp_schema.sql");
        },
    );

    $pool->add_db(
        'scenario_foo',
        from => 'schema',
        checksum => sub { ... },
        build => sub {
            my $class = shift;
            my ($db) = @_;

            ... Load data for scenario 'foo' ...
        },
    );

    $pool->add_db(
        'scenario_bar',
        from => 'schema',
        checksum => sub { ... },
        build => sub {
            my $class = shift;
            my ($db) = @_;

            ... Load data for scenario 'bar' ...
        },
    );

    $pool->add_db(
        'scenario_foo_and_bar',
        from => 'foo',
        checksum => sub { ... },
        build => sub {
            my $class = shift;
            my ($db) = @_;

            ... Load data for scenario 'bar' ...
        },
    );

And to then use the databases:

    # This will return a new clone of foo, changing it will not effect the
    # original 'foo' built by the library.
    my $clone_of_foo = $pool->fetch_db('foo');

    # Same for bar
    my $clone_of_bar = $pool->fetch_db('bar');

    # This gets a NEW clone of 'foo'. Changes in this db will NOT effect
    # $clone_of_foo.
    my $other_clone_of_foo = $pool->fetch_db('foo');

    ... Change Schema ...

    # This will rebuild schema, then rebuild foo using the new schema.
    # (If update_checksums has not been turned off)
    my $fresh_foo = $pool->db('foo');

=head1 ATTRIBUTES

=over 4

=item cache_dir => "path/to/cache"

Required.

Can only be specified at import or construction.

No accessors.

=item instance_dir => "path/to/instances"

Normally db's are spun up in the system temp dir. This allows you to provide an
alternate temporary database location.

=item library => $PACKAGE

=item $pkg = $pool->library

Set automatically from caller during construction unless specified.

Can be read, but not modified.

=item update_checksums => $BOOL

=item $bool = $pool->update_checksums()

=item $pool->set_update_checksums($bool)

Defaults to true.

Can be set during construction, or altered at any time.

When true checksums will be recalculated every time a database is requested, if
any checksum has changed since the last time they were built then all db
downstream of the changed checksum will be rebuilt to account for the changes.

Most of the time you want this to be on so that databases are rebuilt if schema
changes or a new version of the drivers are installed. However if you are not
worried about changes, or checksum calculation is expensive for your pool you
can turn this off.

B<NOTE:> even when this is turned on, no exisitng/active databases will be
rebuilt. To get changes you need to close connections tot he db, stop it, and
request it again via C<db($NAME)> or C<< $pool->fetch_db($NAME) >> to get an
updated build.

=item purge_old => $BOOL

=item $bool = $pool->purge_old()

=item $pool->set_purge_old($bool)

Defaults to false.

Can be set during construction or changed at any time.

When true old builds will be deleted from cache whenever they expire.

B<NOTE:> THIS IS NOT RECOMMENDED when multiple processes share a cache dir,
such as during concurrent unit testing.

=item verbose => $POSITIVE_INTEGER

=item $POSITIVE_INTEGER = $pool->verbose()

=item $pool->set_verbose($POSITIVE_INTEGER)

Defaults to C<0>.

Can be set during construction or changed at any time.

When set to C<1> or greater diagnostics messages about what the pool is doing
will be printed. In addition database command output will be displayed unless
you have overriden the verbose parameter in the driver_args or clone_args
settings.

When set to C<2> or greater the diagnostic messages will be sent to STDERR
instead of STDOUT.

When set to C<3> or greater you will also see the output of the copy commands
that clone the database data directories.

=back

=head1 METHODS

=head2 INTERFACE

=over 4

=item $pool->add_driver($DRIVER)

=item $pool->add_driver($DRIVER, %SPEC)

Define a new driver you can use as a basis for your database states.

C<$DRIVER> can be shorthand C<'PostgreSQL'> or it can be fully qualified if you
prefix it with a '+' C<'+DBIx::QuickDB::Driver::PostgreSQL'>.

The name will be the last part of the driver package name Example:
C<'PostgreSQL'> unless you override it.

The following specifications are allowed:

=over 4

=item name => $NAME

You can use this to override the default database name.

=item checksum => sub { ... }

=item checksum => "method_name"

You can use this to override the default checksum calculator drivers use.
Normally the default will return a sha1 of the version information of the
locally installed database tools.

This can be a subref, or the name of a method defined on your package.

=item build => sub { ... }

=item build => "method_name"

This is not necessary on a driver database, however if you want to do anything
to the clean database before anything builds off of it you can. If you only
have 1 schema to load you can pop it in here instead of creating a schema
specific database. Keep in mind you will have to manage checksum calculation
for both, and this will have to be rebuilt for both schema changes and db tool
version changes.

This can be a subref, or the name of a method defined on your package.

=item driver_args => \%ARGS

You can pass in a hashref of arguments to pass into the driver when
initializing the database:

    driver_args => { verbose => 0, autostart => 0, autostop => 1 },

=item clone_args => \%ARGS

Same as driver_args, except these are used when cloning a database. This will
be inherited by databases that are built off of this one.

=back

=item $pool->add_db(from => $PARENT_OR_DRIVER, build => \&BUILDER)

=item $pool->add_db(from => $PARENT_OR_DRIVER, build => $BUILDER_METHOD_NAME)

=item $pool->add_db(%SPEC)

Define a new database state with the given C<$NAME>.

The following specifications are available:

=over 4

=item from => $PARENT_OR_DRIVER

This specifies the parent database or driver to build off of.

=item build => sub { ... }

=item build => $BUILDER_METHOD_NAME

Any database that is not a base driver needs to do build some kind of state to
be useful. An example is loading schema, or loading fixture data. This is where
you do that.

    sub {
        my $class = shift;
        my ($db) = @_;

        # $db will already be started for you
        $db->load_sql(myapp => "path/to/myapp_schema.sql");

        # $db will be stopped for you automatically.
    }

=item checksum => sub { ... }

=item checksum => $CHECKSUM_METHOD_NAME

This must return a string. If the data this database is built from will never
change you can return a constant string. If the data can change you should
probably either return a version string, or a sha1 of the data.

This is used to check if a database needs to be rebuilt due to external
changes, such as a C<schema.sql> file being modified.

=item clone_args => \%ARGS

You can pass in a hashref of arguments to pass into the driver when
cloning the database:

    clone_args => { verbose => 0, autostart => 0, autostop => 1 },

This will be inherited by databases that are built off of this one. This will
also override any that may have been inherited from a parent.

=back

=item $db = $pool->fetch_db($NAME)

Fetch a fresh clone of the specified database. This will be an isolated copy
that you can play with. Neither the original nor any other copy will be
effected by anything you do. When you are done simply disgard the copy.

If the database, or ant of its parents have not been built yet, they will be
built before you get your fresh copy. The first time this is called may be
slow, but future calls will use cached data making them very fast.

=item $pool->clear_old_cache($age_in_seconds);

This will check all database directories in the cashe dir to see when they were
last cloned, if the last clone was at or before the specified age then the dir
will be deleted.

=back

=head2 INTERNAL

Listed for completeness, but you should not use these, except maybe in a
subclass.

=head3 DB BUILDING

=over 4

=item $pool->build_db()

=item $pool->build_via_clone()

=item $pool->build_via_driver()

=item $pool->vivify_db()

=item $pool->reclaim()

=back

=head3 CHECKSUM/CACHE VALIDATION

=over 4

=item $pool->cache_check()

=item $pool->driver_checksum()

=back

=head3 IPC

=over 4

=item $pool->lock()

=item $pool->unlock()

=back

=head3 DIAGNOSTICS

=over 4

=item $pool->throw()

=item $pool->alert()

=item $pool->diag()

=back

=head3 MISC

=over 4

=item $pool->export()

=back

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
