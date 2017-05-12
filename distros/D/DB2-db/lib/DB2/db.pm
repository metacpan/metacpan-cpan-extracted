package DB2::db;

use diagnostics;
use strict;
use warnings;
use DBI;
use Carp;
use List::MoreUtils qw(none);
use User::pwent;
use File::Spec;

our $VERSION = '0.25';

my %localDB;
our $debug = exists $ENV{DB2_db_debug} ? $ENV{DB2_db_debug} + 0 : undef;

sub _debug
{
    if ($debug)
    {
        if ($debug > 1)
        {
            require Carp;
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            Carp::cluck(@_);
        }
        else
        {
            warn @_;
        }
    }
}

=head1 NAME

DB2::db - Framework wrapper around DBD::DB2 for a specific database

=head1 SYNOPSIS

  package myDB;
  use DB2::db
  our @ISA = qw( DB2::db );

  ...

  use myDB;

  my $db  = myDB->new;
  my $tbl = $db->get_table('myTable');
  my $row = $tbl->find($id);

=head1 DESCRIPTION

The DB2::db module can simplify your interaction with a DB2 database using
the DBI module.  The cost is generally a little bit of speed since it
cannot know which columns you may be interested in.  This is not always
bad since you may not know either.

Please note that unlike many of the DBIx::* modules, this framework is
intended to create your tables (and database) as well as manage them.  Most
DBIx modules will assume your tables are already created and leave the ability
to recreate your tables up to you.  The design for DB2::db is intended to
allow you to develop on one machine and deploy on another with a little 
less effort.  In exchange, however, it can be significantly more
work to set up your perl scripts in the first place.  That said, the extra
work in setting up your perl modules is probably only a little more than
the work it would require to create a DDL script to create all your tables.

=head1 SETUP

Prior to using your db object, you will need to set $ENV{DB2INSTANCE}.
This is so the DB2 driver will be able to figure out your instance.  DB2::db
defaults to an instance called 'db2ee':

    BEGIN {$ENV{DB2INSTANCE} = 'db2ee' unless $ENV{DB2INSTANCE}};

The default instance for DB2 is "db2inst1" on Unix, and "db2" on Windows.
Thus this default is equally wrong everywhere.  If you want to change this
default outside of a BEGIN block, you must do so before creating your
DB2::db object.

=cut

BEGIN {$ENV{DB2INSTANCE} = 'db2ee' unless exists $ENV{DB2INSTANCE}};

=head1 FUNCTIONS

Some functions you have to override to get any meaningful use - these
are the generics of the framework.  Others you may call.  Yet others
should not be called at all.

=over 4

=item C<new>

Do not override this one.  This will return a cached version of your
database object if there is one.  Also known as the singleton approach.
If you need to initialise it, you're best off doing so after creation
in your own method.

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class || __PACKAGE__;

    return $localDB{$class} if ($localDB{$class});

    my $self = {};
    bless $self, $class;

    (my $base_pkg = $class) =~ s/::[^:]+$//;
    $self->{PKG_GROUP} = $base_pkg;
    $self->setup_row_table_relationships();

    $localDB{$class} = $self;
}

=item C<db_name>

Override this, returning the database name that will be connected to
with this object.  Failure to override will result in a crash quickly.

=cut

sub db_name { 
    my $self = shift;
    my %dsn = $self->_dsn();
    $dsn{database} || confess 'need to override db_name or dsn'
}

=item C<dsn>

Override this returning a hash with keys for database, host, and port
for constructing the dsn.  Useful if the database may not be local.

If you override dsn to just return C<db =E<gt> $db_name>, this should
be equivalent to overriding db_name.  This can give more flexibility as
to which db to use - allowing you to use a remote db for production, but
a local db for development, for example.

=cut

# used to normalise values
sub _dsn
{
    my $self = shift;
    my %dsn = $self->dsn();
    if (keys %dsn)
    {
        %dsn = map {
            lc $_ => $dsn{$_}
        } keys %dsn;

        # allow shortnames (as per odbc)
        $dsn{database} ||= $dsn{db}   if exists $dsn{db};
        $dsn{hostname} ||= $dsn{host} if exists $dsn{host};

        $dsn{protocol} ||= 'TCPIP' if scalar keys %dsn > 1;
    }
    %dsn;
}

sub dsn { () }

=item C<user_name>

Override this if necessary.  The default is no user, which will imply
that the current user (however that is defined for your platform) will
be the user for authentication purposes.  Usually you will need to
get this information before creation of your database object.

=cut

sub user_name { undef }

=item C<user_pw>

Similar to C<user_name>, override if necessary.  Should be overridden
if user_name is overridden.  Must return the unencrypted password.

=cut

sub user_pw   { undef }

=item C<connect_attr>

This is used for any connection-specific parameters needed for the
underlying DBD::DB2 object.  The default is to turn off AutoCommit
(since this framework handles commits already).  Example:

    sub connect_attr {
        my $self = shift;
        my %attr = (
                    %{$self->SUPER::connect_attr()}, 
                    LongReadLen => 102400,
                   );
        \%attr;
    }

=cut

sub connect_attr {
    { AutoCommit => 0, PrintError => 1 }
}

=item C<setup_row_table_relationships>

Override this to tell DB2::db about your tables.  Call
add_row_table_relationship once for each table (see its documentation
below).

B<Order is important.>  The order will be preserved and used
when attempting to create the database.  Ensure the tables are listed
in such an order that C<FOREIGNKEY>s always point to tables that will be
created before the current table.

=cut

sub setup_row_table_relationships
{
    my $self = shift;
    carp 'should override setup_row_table_relationships';
    my $rln = $self->get_row_table_relationships();
    for my $h (@$rln)
    {
        $self->add_row_table_relationship(%$h,IS_FULL_PKG_NAME => 1);
    }
}

=item C<add_row_table_relationship>

While initialising the row/table relationships, call this in the order of
the tables that would need to be created.

    $self->add_row_table_relationship(
                                      ROW => 'MyRow',
                                      TABLE => 'MyTable',
                                      %other_options
                                     )

Do this once for each table you have.

Note that if ROW is missing, it will be assumed to be the same as Table,
but with an R suffix.  e.g., C<$self-E<gt>add_row_table_relationship(TABLE =E<gt> 'tbl')>
will assume that the Row's object type is C<tblR>

Other options include:

=over 4

=item IS_FULL_PKG_NAME

If this is true, it is assumed that you have fully qualified your
package names for both the row and the table.  Otherwise, the default
is to use the same package as your database object is in.  For example,
if your object is in the package My (e.g., C<My::db>), then specifying C<ROW =E<gt>
'MyRow'> implies C<My::MyRow> instead.  This can save a bunch of typing if
you have a deeply-nested package tree, or if you decide to change the
package later.

=item ROW_IS_FULL_PKG_NAME

=item TABLE_IS_FULL_PKG_NAME

Specific to the ROW and TABLE, respectively.

=back

=cut

# Needs to be optimised better (part of the whole point, isn't it?)

sub add_row_table_relationship
{
    my $self = shift;
    my $options = $_[0];
    unless (ref $options and ref $options eq 'HASH')
    {
        $options = { @_ };
    }

    $options->{TABLE} = $self->{PKG_GROUP} . '::' . $options->{TABLE}
        unless $options->{IS_FULL_PKG_NAME} or $options->{TABLE_IS_FULL_PKG_NAME};
    if ($options->{ROW})
    {
        $options->{ROW} = $self->{PKG_GROUP} . '::' . $options->{ROW}
        unless $options->{IS_FULL_PKG_NAME} or $options->{ROW_IS_FULL_PKG_NAME};
    }
    else
    {
        $options->{ROW} = $options->{TABLE} . 'R';
    }

    push @{$self->{RELN}{MASTER}}, { map { $_ => $options->{$_} } qw(ROW TABLE) };
}

=item C<add_table>

Same as C<add_row_table_relationship>, except that the first parameter is the
table name, and the rest are options.  For example,

    $self->add_table("tbl", ROW => "tbl::row");

is exactly the same as:

    $self->add_row_table_relationship(TABLE => "tbl", ROW => "tbl::row");

Which means that if you follow conventions, you only need to specify:

    $self->add_table("tbl");

if your row package is C<tblR>.  Order is still important.  C<add_table>
and C<add_row_table_relationship> can be intermingled.

=cut

sub add_table
{
    my $self = shift;
    my $tbl = shift;
    my %options = @_;
    $options{TABLE} = $tbl;
    $self->add_row_table_relationship(\%options);
}

=item C<add_tables>

And, finally, a shortcut to calling add_table repeatedly if you're just
using the defaults anyway.

    $self->add_tables(qw/
                      tbl1
                      tbl2
                      /);

=cut

sub add_tables
{
    my $self = shift;
    local $_;
    $self->add_table($_) foreach @_;
}

=item C<get_row_table_relationships>

B<OBSOLETE> - Use setup_row_table_relationships instead.

Override this with the DB2::Table/DB2::Row relationships.  This will be
used to extrapolate what objects to create for each query.  DB2::Table
objects will be instantiated as required, but no sooner.

Format of expected output:
   [
       { ROW => 'Row_type_1', TABLE => 'Table_type_1' },
       { ROW => 'Row_type_2', TABLE => 'Table_type_2' },
   ]

The order of these hashrefs is important.  The order is used in
determining what order to create the tables during table creation in
C<create_db>.

I<Types> mean package names.  "Classes" for you Java and C++ types out there.
When DB2::db needs to create a row object to handle the data retrieved from
the database table, it will look up in this array what to C<use>, and
then create a new object of the designated type.

=cut

sub get_row_table_relationships
{
    confess 'need to override setup_row_table_relationships';
}

=item C<set_default_package>

Changes the default package for both tables and rows while adding tables.

For example:

    package My::db;

    #...

    $self->add_table('foo'); # My::foo and My::fooR
    $self->set_default_package('Your');
    $self->add_table('bar'); # Your::bar and Your::barR

=cut

sub set_default_package
{
    my $self = shift;
    $self->{PKG_GROUP} = shift;
}

sub _get_rows_to_tables {
    my $self = shift;
    unless ($self->{RELN}{ROW})
    {
        $self->{RELN}{ROW} = {
            map { $_->{ROW} => $_->{TABLE} } @{$self->{RELN}{MASTER}}
        };
    }
    $self->{RELN}{ROW};
}
sub _get_tables_to_rows {
    my $self = shift;
    unless ($self->{RELN}{TABLE})
    {
        $self->{RELN}{TABLE} = {
            map { $_->{TABLE} => $_->{ROW} } @{$self->{RELN}{MASTER}}
        };
    }
    $self->{RELN}{TABLE};
}
# This would be:
#    keys %{shift->_get_tables_to_rows}
# but order is important.
sub _get_tables {
    my $self = shift;
    unless ($self->{RELN}{TABLE_ORDER})
    {
        $self->{RELN}{TABLE_ORDER} = [
                                      map { $_->{TABLE} } @{$self->{RELN}{MASTER}}
                                     ];
    }
    @{$self->{RELN}{TABLE_ORDER}};
}

=item C<get_row_type_for_table>

While you should not need this, it is available to request the type
name of the DB2::Row class given a table type name.

=cut

sub get_row_type_for_table
{
    my $self = shift;
    my $table_type = shift;
    my $conv = $self->_get_tables_to_rows;
    my $row_type = exists $conv->{$table_type} ? $conv->{$table_type} : $table_type . 'R';

    # only try to grab it if it doesn't already exist.
    no strict 'refs';
    unless (exists ${"${row_type}::ISA"}[0])
    {
        # If the row-type is given, try loading it.  Rather than using
        # eval STR to eval "require $row_pm", we do it ourselves.  This
        # is slightly faster (Benchmark shows about 20% faster).
        (my $row_pm = $row_type . '.pm') =~ s.::./.g;
        eval { require $row_pm; 1 } or do
        # if the row type doesn't exist, we'll just create it ourselves.
        {
            my $table = $self->get_table($table_type);
            my $base_type = $table->get_base_row_type();

            eval "package $row_type; use base '$base_type'; 1" or
                croak($@);
        }
    }
    $row_type;
}

=item C<get_table>

Returns the singleton table object (instantiated if necessary) given
its type name.  If only one table is known about that ends with the given
name, it will be returned (shortcut).

For example, $mydb->get_table('Foo') will get the table object if it's
really called Bar::Foo, Baz::Foo, Bar::Baz::Foo, or just Foo, but not
Baz::FooBar or Baz::BarFoo.  But only if there is only a single match.  
If there is more than one match, then the call will fail.  If a case-sensitive
match fails to find any matches, then a case-insensitive match is attempted.

=cut

sub _guess_table
{
    my $self = shift;
    my $tbl  = shift;
    $tbl =~ s./+.::.g;
    $tbl =~ s.:::+.::.g;

    # "normal" cases.
    return $tbl if exists $self->{TABLES}{$tbl};

    my $tbl_to_rows = $self->_get_tables_to_rows;
    return $tbl if exists $tbl_to_rows->{$tbl};

    # shortcuts.
    return $self->{SHORTNAME_TABLES}{$tbl} if exists $self->{SHORTNAME_TABLES}{$tbl};

    # if there isn't a shortcut (yet), see if we can create one.
    # only can do this if it's unique!
    my @candidates = grep { /::\Q$tbl\E$/ } keys %$tbl_to_rows;

    # if no match yet, try case independant.
    @candidates = grep { /::\Q$tbl\E$/i } keys %$tbl_to_rows
        if scalar @candidates == 0;

    if (scalar @candidates == 1)
    {
        $self->{SHORTNAME_TABLES}{$tbl} = $candidates[0];
        return $self->{SHORTNAME_TABLES}{$tbl};
    }
    undef;
}

sub get_table
{
    my $self = shift;
    my $table = shift;
    my $table_type = $self->_guess_table($table);
    if ($table_type and exists $self->_get_tables_to_rows->{$table_type})
    {
        unless (ref $self->{TABLES}{$table_type})
        {
            no strict 'refs';
            unless ($table_type and exists ${"${table_type}::ISA"}[0])
            {
                (my $table_pm = $table_type) =~ s.::./.g;
                $table_pm .= '.pm';
                eval { require $table_pm };
                croak $@ if $@;
            }
            $self->{TABLES}{$table_type} = $table_type->new($self);
        }
        $self->{TABLES}{$table_type}
    }
    else
    {
        carp("Unknown type: $table");
        undef;
    }
}

=item C<get_table_for_row_type>

Similar to C<get_row_type_for_table>, you should not need this.  Gets
the table I<object> for the given row type name.

=cut

sub get_table_for_row_type
{
    my $self = shift;
    my $row_type = shift;
    my $conv = $self->_get_rows_to_tables;
    if (exists $conv->{$row_type})
    {
        $self->get_table($conv->{$row_type});
    }
    else
    {
        undef;
    }
}

# default is "true", so we want to make sure we take that into consideration
sub _is_autocommit
{
    my $self = shift;
    my $connect_attr = $self->connect_attr;

    not exists $connect_attr->{AutoCommit} or $connect_attr->{AutoCommit};
}

=item C<connection>

Returns the DBD::DB2 object that contains the actual connection to the
database, performing the connection if required.

=cut

sub _data_source {
    my $self = shift;
    my %dsn = $self->_dsn();
    if (scalar keys %dsn > 1)
    {
        "dbi:DB2:" . join '; ', map { 
            uc($_) . "=$dsn{$_}" 
        } grep {
            exists $dsn{$_}
        } qw(database hostname port protocol uid pwd);
    }
    else
    {
        "dbi:DB2:" . uc ($dsn{database} || $dsn{db})
    }
}

sub connection
{
    my $self = shift;
    unless ($self->{dbh} and $self->{dbh}{Active})
    {
        $self->{dbh} = DBI->connect($self->_data_source,
                                    $self->user_name,
                                    $self->user_pw,
                                    $self->connect_attr);
    }
    $self->{dbh}
}

=item C<disconnect>

Disconnects from the database (happens automatically, so shouldn't be
needed).

=cut

sub disconnect
{
    my $self = shift;
    if ($self and $self->{dbh})
    {
        $self->{dbh}->commit unless $self->_is_autocommit;
        $self->{dbh}->disconnect;
    }
    delete $self->{dbh};
}

=item C<create_db>

This is used as part of the setup of the database.  It will go through
all the known tables and create them after first creating the database.
It is assumed that the person running this has authority to do so.

To initialise your entire system, just run:

    perl -M[your_db_type] -e '[your_db_type]->create_db'

For example:

    perl -MMy::db -e 'My::db->create_db'

=cut

sub create_db
{
    my $self = shift;
    $self = $self->new unless ref $self;

    require Sys::Hostname;

    my %dsn = $self->_dsn();
    if (not keys %dsn or
        scalar keys %dsn == 1 or
        $dsn{hostname} eq 'localhost' or
        $dsn{hostname} eq Sys::Hostname::hostname())
    {
        unless ($self->{quiet})
        {
            print '*' x 50, "\n";
            print ' ' x 15, "setting up ", $self->db_name, "\n";
            print '*' x 50, "\n";
        }

        if (none { $_ eq $self->_data_source() } DBI->data_sources('DB2'))
        {
            unless ($self->{quiet})
            {
                print "  ---> creating database\n";
            }
            my $opts = $self->create_db_opts();
            $opts = (defined $opts and length $opts) ? " $opts" : "";

            eval {
                my $insthome = getpwnam($ENV{DB2INSTANCE})->dir();
                $ENV{PATH} = File::Spec->catdir($insthome, qw(sqllib bin)) . ':' . $ENV{PATH};
            };

            system("db2", "create db " . $self->db_name() . $opts);
        }
    }

    my $dbh = $self->connection;
    die "Cannot connect to " . $self->db_name() unless $dbh;

    for my $tbl ($self->_get_tables)
    {
        $self->get_table($tbl)->create_table();
    }
    $self->disconnect;
}

=item C<create_db_opts>

Override this to specify any create db options during database create.

Default is to set the pagesize to 32 K.

=cut

sub create_db_opts
{
    'pagesize 32 K';
}

sub DESTROY
{
    my $self = shift;
    delete $localDB{ref $self};
    if ($self->{dbh})
    {
        $self->disconnect;
    }
}

=back

=head1 AUTHOR

Darin McBride <dmcbride@naboo.to.org>

This framework evolved out of frustration writing reusable DDL to
create tables.  Once I had some objects that did that, it was slow
extention to the point where they were usable for everything I could
think of.

Most of the features here are because I'm incredibly lazy.  I like to solve
problems, but only twice.  The first time is to learn it, the second time
is to use my new knowledge.  After that, I expect the computer to do it
for me.

=head1 CREDITS

Much thanks to DB2PERL for help with the DBI, and DBD::DB2 in
particular, including some bug fixes (both in DBD::DB2 and in DB2::db),
and feature enhancements to DBD::DB2 that came a little earlier than
originally planned.

=head1 COPYRIGHT

The DB2::db and associated modules are Copyright 2001-2008, Darin McBride.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 BUGS

Support for using this framework on a VIEW is completely missing.

=head1 SEE ALSO

DBI, DBD::DB2

=cut

1;
