package Class::DBI::ClassGenerator;

use strict;
use warnings;
use DBI;

use File::Spec;

use vars qw($VERSION);

$VERSION = '1.04';

=head1 NAME

Class::DBI::ClassGenerator - generate Class::DBI sub-class modules from a
pre-exsting database's structure.

=head1 SUPPORT

This module is unsupported, unloved, unmaintained, and DEPRECATED. No
bugs will be fixed. No patches will be accepted. No users will be helped.
All bug reports will be either ignored or rejected.

I strongly recommend that you switch from using Class::DBI to using
L<DBIx::Class> instead, and L<DBIx::Class::Schema::Loader> instead of this
module.

Unless, that is, someone else takes over ownership.

=head1 SUBROUTINES

=head2 create

This takes the following named parameters:

=over

=item directory (compulsory)

The name of the directory into which to drop the generated classes.  If
it doesn't exist it will be created.  Sub-directories will be created
under here as appropriate.

    directory => 'lib'

=item connect_info (compulsory)

An arrayref of the DSN, username and password to connect to the database.

    connect_info => ['dbi:mysql:dbname', 'username', 'password']

=item base_class (compulsory)

The name of the base class that all your table classes will inherit their
database connection from.

    base_class => 'MyApp::DB'

=item tables (optional)

A hashref whose keys are table names in the database and the values are
the classnames you desire.

    tables => {
        artists => 'MyApp::Artist',
        tracks  => 'MyApp::Track',
        albums  => 'MyApp::Album',
        ...
    }

If you leave this out, the code will assume
that you want classes for all tables, and that their names should be
generated thus:

    The first character of the tablename is converted to uppercase;

    An underscore followed by a character becomes the character, in
    uppercase

    The base class name and :: is prepended.

This is probably a close approximation for what you want anyway.

=back

It returns a list of all the files created.

=cut

sub create {
    my %params = @_;
    die(__PACKAGE__."::create: no directory specified\n")
        unless($params{directory});
    die(__PACKAGE__."::create: no connect_info specified\n")
        unless($params{connect_info});
    die(__PACKAGE__."::create: no base class specified\n")
        unless($params{base_class});

    mkdir($params{directory});
    die("Couldn't create $params{directory}: $!\n")
        unless(-d $params{directory});

    my $dbh = _get_dbh($params{connect_info});
    my $db_driver = _get_db_driver($params{connect_info});

    # get tables from DB if necessary
    $params{tables} = {
        map {
            $_ => _table_to_class($params{base_class}, $_)
        } $db_driver->_get_tables($dbh)
    } unless(ref($params{tables}));

    # get columns from DB
    $params{tables} = {
        map {
            $_ => {
                classname => $params{tables}->{$_},
                columns   => { $db_driver->_get_columns($dbh, $_) }
            }
        } keys %{$params{tables}}
    };

    my @files_created = ();

    foreach my $table (keys %{$params{tables}}) {
        my $pks = join(' ',
            grep { $params{tables}->{$table}->{columns}->{$_}->{pk} }
            keys %{$params{tables}->{$table}->{columns}}
        );
        my $nonpks = join(' ',
            grep { !$params{tables}->{$table}->{columns}->{$_}->{pk} }
            keys %{$params{tables}->{$table}->{columns}}
        );
        my $classfile = File::Spec->catfile(
            $params{directory},
            split('::', $params{tables}->{$table}->{classname}.'.pm')
        );
        _mkdir($params{directory}, $params{tables}->{$table}->{classname});
        open(my $classfilefh, '>', $classfile) ||
            die("Can't write $classfile: $!\n");
        print $classfilefh "package ".$params{tables}->{$table}->{classname}.";\n";
        print $classfilefh "use base '$params{base_class}';\n\n";
        print $classfilefh "__PACKAGE__->table('$table');\n";
        print $classfilefh "__PACKAGE__->columns(Primary => qw($pks));\n";
        print $classfilefh "__PACKAGE__->columns(Others  => qw($nonpks));\n";
        close($classfilefh);
        # system("cat $classfile");
        push @files_created, $classfile;
    }

    my $basefile = File::Spec->catfile(
        _mkdir($params{directory}, $params{base_class}),
        (split(/::/, $params{base_class}))[-1].'.pm'
    );
    open(my $basefilefh, '>', $basefile) ||
        die("Can't write $basefile: $!\n");
    print $basefilefh "package $params{base_class};\nuse base 'Class::DBI';\n\n";
    print $basefilefh "$params{base_class}->connection('".
        join("', '", @{$params{connect_info}}).
    "');\n\n";
    print $basefilefh "use $_;\n" foreach(
        map {
            $params{tables}->{$_}->{classname}
        } keys %{$params{tables}}
    );
    close($basefilefh);
    push @files_created, $basefile;
    # system("cat $basefile");
    

    return @files_created;
}

# create a directory hierarchy for a class. Takes the base dir and
# class name.  Given, eg, ('lib', 'Foo::Bar::Baz') it will create
# lib/Foo and lib/Foo/Bar.  Returns the name of the last directory
# created.

sub _mkdir {
    my($base, $class) = @_;
    my @components = split(/::/, $class);
    pop @components; # remove last bit - that's a filename
    my $dir = $base;
    while(@components) {
        $dir = File::Spec->catdir($dir, shift(@components));
        mkdir $dir || die("Couldn't create $dir: $!\n");
    }
    return $dir;
}

# given a DSN/username/password arrayref, get a DBH
sub _get_dbh { DBI->connect(@{$_[0]}); }

# given a DSN/username/password arrayref, load and return the C::DBI::CG::DBD::blah
sub _get_db_driver {
    my $dsn = shift;
    my $db_driver = __PACKAGE__.'::DBD::'.
        (split(':', $dsn->[0]))[1];
    eval "use $db_driver";
    die(
        __PACKAGE__.
        ": can't find db-specific code for ".
        $dsn->[0].
        "\n:$@\n"
    ) if($@);
    return $db_driver;
}

# map a table name to a classname. Takes a base class name and a table
# name, returns a classname
sub _table_to_class {
    my($base, $table) = @_;
    $table =~ s/(^|_)(.)/uc($2)/eg;
    join('::', $base, $table);
}

=head1 BUGS and WARNINGS

This should be considered to be pre-production code.  It's probably chock
full of exciting bugs.

=head1 DATABASES SUPPORTED

MySQL and SQLite are supported "out-of-the-box".  Adding other databases
is a simple matter of writing a "driver" module with two simple methods.
You are encouraged to upload such modules to the CPAN yourself.

L<Class::DBI::ClassGenerator::Extending>, for how to interrogate other
databases.

=head1 AUTHOR, COPYRIGHT and LICENCE

Written by David Cantrell E<lt>david@cantrell.org.ukE<gt>

Copyright 2008-2009 Outcome Technologies Ltd

This software is free-as-in-speech software, and may be used, distributed,
and modified under the terms of either the GNU General Public Licence
version 2 or the Artistic Licence. It's up to you which one you use. The
full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=cut

1;
