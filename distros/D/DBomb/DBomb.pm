package DBomb;

=head1 NAME

DBomb - Database Object Mapping

=cut

use strict;
use warnings;
use DBomb::Util qw(is_same_value);
use DBomb::Query;
use Carp::Assert;
use Carp qw(cluck);
use base qw(DBomb::DBH::Owner);
use base qw(Exporter);

our $VERSION = '$Revision: 1.26 $';

our %EXPORT_TAGS = ( 'all' => [qw( PlaceHolder ) ]);
Exporter::export_ok_tags('all');
sub PlaceHolder { DBomb::Query::PlaceHolder() }



__PACKAGE__->mk_classdata('tables');
__PACKAGE__->mk_classdata('databases');
__PACKAGE__->mk_classdata('one_to_manys');
__PACKAGE__->mk_classdata('todo_after_resolve');
__PACKAGE__->mk_classdata('did_resolve');

__PACKAGE__->tables(+{}); ## table_name -> table_info
__PACKAGE__->databases(+{}); ## TODO
__PACKAGE__->one_to_manys([]); ## List of OneToMany objects
__PACKAGE__->todo_after_resolve([]); ## [ [ CODEREF, $args_list, caller] , ... ]


## eval { DBomb->resolve };
sub resolve
{
    my $class = shift;

    if (defined $class->did_resolve){
        my ($package, $filename, $line, $subroutine) = @{$class->did_resolve};
        cluck("DBomb::resolve was already called. The first time was from $package\:\:$subroutine at $filename line $line ");
    }
    $class->did_resolve([caller(1)]);

    for(values %{$class->tables}){
        $_->resolve;
    }

    for (@{$class->todo_after_resolve}){
        my ($coderef, $args, $caller_info) = @$_;
        eval {
            $coderef->(@$args);
        };
        if ($@) {
            ## The coderef failed.
            my ($package, $filename, $line, $subroutine) = map{defined($_)?$_:''} @$caller_info;
            die("$filename\:$line in $package\:\:$subroutine\:  $@\n");
        }
    }
}

## returns a table_info object or undef
## $class->resolve_table_name($database,$tname)
sub resolve_table_name
{
##TODO: database not used
    my ($class,$database,$table_name) = @_;
        assert(@_ == 3, 'parameter count');
        assert(UNIVERSAL::isa($class,__PACKAGE__));
        assert(defined($table_name), "resolve_table_info requires a table name");
    return $table_name if UNIVERSAL::isa($table_name,'DBomb::Meta::TableInfo');
    return $class->tables->{$table_name} if exists $class->tables->{$table_name};

    ## Ok, it's not a table name. maybe it is a package name.

    for (values %{$class->tables}){
        next unless UNIVERSAL::isa($_,'DBomb::TableInfo');

        ## TODO: compare database name too.
        return $_ if is_same_value($_->class, $table_name);
    }

    undef; ## not found
}

## push code to be run after resolve. caller information is for error handling
## do_after_resolve(sub{...}, $args, [caller])
sub do_after_resolve
{
    my ($class,$coderef,$args, $caller) = @_;
        assert(UNIVERSAL::isa($coderef,'CODE'), 'do_after_resolve requires a coderef');
        assert(UNIVERSAL::isa($args,'ARRAY'), 'do_after_resolve requires an args listref');
        assert(UNIVERSAL::isa($caller,'ARRAY'), 'do_after_resolve requires a caller listref');
        assert(@$caller >= 4, 'do_after_resolve requires a valid caller list.');

    push @{$class->todo_after_resolve}, [ $coderef, $args, $caller];
}

1;
__END__

=head1 SYNOPSIS

  # First, generate the modules from the db.
  $ dbomb-gen -u john -p xxx --all --gen-modules --split-dir=. --module-prefix="Foo"  dbname
 
  # Use them..
  use DBI;
  use DBomb;
  DBomb->dbh(DBI->connect(...));

  package Customer;
  use base qw(DBomb::Base);

  Customer->def_data_source  ('my_db', 'cust_tbl');
  Customer->def_column       ('cust_id',  { accessor => 'id', auto_increment => 1 });
  Customer->def_column       ('name'};
  Customer->def_accessor     ('address',  { column => 'addr'});
  Customer->def_accessor     ('affiliate_id');
  Customer->def_accessor     ('now', { expr => 'now()', cache => 0} );

  Customer->def_primary_key  ([qw(cust_id  cust_loc)]);
  Customer->def_key          ([qw(name affiliate_id)]);


  Customer->def_has_a        ('affiliate', 'Affiliate', +{})
  Customer->def_has_a        ('affiliate', [qw(name aff_id)], 'Affiliate_table', [qw(c_name id)]);

  Customer->def_has_many     ('orders', 'Order',+{})
  Customer->def_has_many     ('orders', 'Order', ['cust_id'], ['id'],+{});
  Employee->def_has_many     ('supervisors', 'Supervisor',
                                            new DBomb::Query->select('super_id')
                                            ->from('emp_super')
                                            ->join('employee')
                                            ->using('emp_id')
                                            ->where(+{emp_id => '?'}), sub { shift->emp_id });

  Customer->def_select_group ([qw(name address)]);

  ## Main program
  package main;
  use DBomb;
  use Customer;
  use Some_Other_DBO_Object;

  DBomb->resolve(); # IMPORTANT! Do this once, after all 'use' objects.


  $all_customers = Customer->selectall_arrayref;
  for  (@$all_customers){
      $_->name( ucfirst lc $_->name );
      $_->update;
  }

  Customer->insert->values($name, $addr, $afid)->insert;
  Customer->insert({ name => $name, addr => $addr, affiliate_id => $afid});
  $cust = new Customer();
      $cust->name($name);
      $cust->address($addr);
      $cust->affiliate_id($afid);
      $cust->insert;
  new DBomb::Query::Insert(qw(name addr affiliate_id))
    ->into('cust_tbl')
    ->values($name,$addr,$afid)
    ->insert;

  Customer->update->set( 'name', $new_name )->where({ cust_id => $cust_id })->update;
  new DBomb::Query::Update->set( name => '$new_name' )->where( "cust_id = $cust_id")->update;
  $cust = new Customer($cust_id);
      $cust->name($new_name);
      $cust->update;


=head1 DESCRIPTION

DBomb is a mapping from database tables (or joins) to perl objects. The object accessors are columns
in the table (or join).

There are currently two layers to DBomb, described below.

=head2 LAYER 1 - DBomb::Query

The DBomb::Query layer is a set of simple object wrappers around standard SQL
statements, which maintain their own $dbh and $sth handles, and can remember
bind_values.  Here is an example:

    my $rows = new DBomb::Query($dbh)
             ->select(@column_names)
             ->from($table)
             ->selectall_arrayref(@values);

    # Same thing:
    my $rows = $dbh->selectall_arrayref(
            "SELECT @{[join q/,/, @column_names]} FROM $table" );

When used alone (without LAYER 2), the DBomb::Query objects offers a few
advantages over straight DBI calls:

=head3 Advantages of using DBomb::Query over DBI

=over

=item * Bind values can be assigned at any time.

=item * Hides SQL and prevents string errors.

=item * Cleaner code.

=back

However, the real power comes in Layer 2, where DBomb methods return partially constructed
DBomb::Query objects.


=head2 LAYER 2 - DBomb::Base

The DBomb::Base layer consists of a base class (DBomb::Base) and some glue to the
DBomb::Query layer.  The base class is intended to be subclassed for each table,
view, and join in your database. Your subclass will define mappings to
the database tables and columns, and will inherit useful
methods for storing and retrieving its underlying data. The following
example assumes that the 'Customer' object mappings have been defined
already (as in the SYNOPSIS):

    my $c = new Customer();
    $c->name($name);
    $c->insert;
    $c->update;
    $c->delete;

The layer 2 objects make extensive use of DBomb::Query (Layer 1) objects. Many
Layer 2 methods returns partially constructed DBomb::Query objects. For example,
to build a query on the Customer table, do this:

    my $query = Customer->select->where->({region_code => '?'});
    my $customers = $query->selectall_arrayref($region);
    my $others = $query->selectall_arrayref($other_region);

There are two important things going on here. First, the $query object behaves
like a layer 1 DBomb::Query object, but it fetches Customer I<objects>, not rows.
Second, the query can be cached and reused just like a DBI prepared statement
handle.

=head1 API GUIDELINES

These are the guidelines adhered to by the DBomb public API. Any exceptions you
discover are bugs.

=over

=item 1. Column names may be fully qualified.

Any API method that expects a column name should also accept the fully
qualified column name as "$database.$table.$column". In most cases, the column
name by itself is ok.

=item 2. Keys are listrefs.

All keys (primary keys, foreign keys, etc.) should be specified as a reference
to a perl array containing the column names or values.  For flexibility,
single-column primary keys can be specified as scalars.

=item 3. Methods that look like DBI methods should behave like DBI methods.

Methods with names borrowed from DBI (e.g, prepare(), execute(), selectall_arrayref())
should behave like their DBI counterparts. If you are familiar with DBI, than there
should be no surprises from DBomb.

=item 4. DBomb objects never do more than you expect them to do.

It should be clear from your code whether it triggers a database action.  For
example, if you do not explicitly modify values in a DBomb object by calling
insert(), update(), delete(), etc., then the database should not
be modified. The inverse is also true.

=item 5. All DBomb objects have a dbh() method.

All objects should contain, or have the ability to procure a database handle.
Typically, this is done through package globals -- the top level being
DBomb::dbh(). The idea is that you need only set the $dbh handle once in your
code.

=item 6. A DBI handle ($dbh) can be passed to most methods.

Wherever sensible, DBomb::Query and DBomb::Base methods will accept a $dbh as an
argument. The new(), prepare(), and execute() methods are sensible places to
pass a $dbh handle. The $dbh will be safely plucked from the arguments. For example,

    $query->execute(@bind_values, $dbh, @more_bind_values);

=back


=head1 PUBLIC OBJECTS AND METHODS

This is a partial list of public objects and their methods.

=over

=item DBomb::Query

Represents a query object. You can safely pass a $dbh to most methods, which will be stored for later prepare() and execute() calls.

=over

=item new

 new Query()
 new Query(column_names)
 new Query($dbh,column_names)

=item from

 $q->from($table_name, $table_name...)

=item join

 $q->join($right)
 $q->join($left, $right)

=item right_join

 $q->right_join($right)
 $q->right_join($left, $right)

=item left_join

 $q->left_join($right)
 $q->left_join($left, $right)

=item where

 $q->where(EXPR, @bind_values)

=item and

 $q->and (EXPR, @bind_values)

=item or

 $q->or (EXPR, @bind_values)

=item prepare

 $q->prepare()
 $q->prepare($dbh)

=item execute

 $q->execute(@bind_values)
 $q->execute($dbh,@bind_values)

=item fetchrow_arrayref

 $q->fetchrow_arrayref()

=item fetchall_arrayref

 $q->fetchall_arrayref()

=item fetchcol_arrayref

 $q->fetchcol_arrayref()

=item selectall_arrayref

 $q->selectall_arrayref(@bind_values)
 $q->selectall_arrayref($dbh, @bind_values)

=item selectcol_arrayref

 $q->selectcol_arrayref(@bind_values)
 $q->selectcol_arrayref($dbh, @bind_values)

=item clone

 returns a deep copy. Not finished or tested!
 Note: The database handle will be shared by the clone, and
 the internal statement handle will set to undef in the clone.

=back

=item DBomb::Query::Update

Represents an SQL UPDATE.

=over

=item new

 new()
 new($dbh,[column_names,...])

=item table

 $q->table($table_name)

=item set

 $q->set({ name => value})
 $q->set( name => value)

=item update

Same as prepare->execute

 $q->update()
 $q->update(@bind_values)
 $q->update($dbh,@bind_values)

=item where

 $q->where(EXPR, @bind_values)

=item prepare

 $q->prepare()
 $q->prepare($dbh)

=item execute

 $q->execute()
 $q->execute(@bind_values)
 $q->execute($dbh,@bind_values)

=back


=item DBomb::Query::Insert

Represents an insertion object.

=over

=item new

 new DBomb::Query::Insert()
 new DBomb::Query::Insert(@columns)
 new DBomb::Query::Insert($dbh,[@columns])

=item insert

Same as prepare->execute

 $q->insert()
 $q->insert(@bind_values)
 $q->insert($dbh,@bind_values)

=item columns

 $q->columns(names or infos or values)
 $q->columns([names or infos or values])

=item into

 $q->into($table_name)
 $q->into($table_info)

=item values

 $q->values($values..)
 $q->values(Value objects....)

=item prepare

 $q->prepare()
 $q->prepare($dbh)

=item execute

 $q->execute(@bind_values)
 $q->execute($dbh,@bind_values)

=item clone

returns a deep copy. Not finished or tested!
@note The database handle will be shared by the clone, and
the internal statement handle will set to undef in the clone.


=back


=item DBomb::Query::Delete

=over

=item new

 $d = new DBomb::Query::Delete()
 $d = new DBomb::Query::Delete($dbh)

=item from

 $d->from($tables)

=item delete

Same as prepare->execute.

 $d->delete()
 $d->delete(@bind_values)
 $d->delete($dbh,@bind_values)

=item prepare

 $d->prepare()
 $d->prepare($dbh)

=item execute

 $d->execute()
 $d->execute(@bind_values)
 $d->execute($dbh,@bind_values)

=item where

 $d->where(EXPR, @bind_values)

=item and

 $d->and (EXPR, @bind_values)

=item or

 $d->or (EXPR, @bind_values)

=back


=item DBomb

=over

=item DBomb->resolve()

This static method should be called I<once> from within your application, after
using all DBomb subclasses -- typically upon startup. The main purpose is to
cross-reference all your multi-table relationships (e.g., has_a, has_many).
DBomb->resolve() will croak if it fails.

=back

=item DBomb::Base

This is the base class that provides all the functionality for your subclasses. It is
not meant to be called directly.

=over

=item new

Do I<not> override the new() method. Override the
init() method instead.

 $new_obj = new MyClass()
 $existing_obj = new MyClass($PrimaryKeyValue)

 ## these are not as useful
 $obj = new MyClass($pk_column)
 $obj = new MyClass([$pk_part1, $pk_part2] )
 $obj = new MyClass($dbh)

=item init

DBomb will call the init() method from within new(). The default init() method is empty, and is meant
to be optionally overridden in the subclass. For example,

    sub init {
        my ($self, @args) = @_;
        ## etc.
    }

Where @args contains the arguments that were passed to new() that DBomb::Base did not
recognize. e.g., if you pass a $dbh to new(), then it will not be passed to
through init() because DBomb snatched it up.

=item select

Returns a query that can be used to fetch objects of type MyClass (based on
primary key). The @columns array may be column names, aliases, or accessors.

    $query = MyClass->select(@optional_columns)
    $list_of_MyClass_objects = $query->selectall_arrayref;


=item select_count

Returns a query object that will return C<COUNT(*)> instead of an object.

    MyClass->select_count()

=item selectall_arrayref

Returns a reference to an array of objects of type MyClass.

 MyClass->selectall_arrayref()
 MyClass->selectall_arrayref(@bind_values)
 MyClass->selectall_arrayref($dbh, @bind_values)

=item insert

When called as an object method, it immediately inserts a row in the database.
If any part of the primary key is an auto_increment column, then the new primary key
is fetched. When called as a class method, it returns a DBomb::Query::Insert object.

    $obj->insert; # SQL INSERT was performed.

    $query = MyClass->insert; # SQL was not executed.

=item update

When called as an object method, it immediately updates the corresponding row
in the database.  If this objects has no primary key value, then an exception
is raised.  When called as a class method, it returns a DBomb::Query::Update
object.

    $obj->update; # SQL UPDATE was performed.

    $query = MyClass->update; # SQL was not executed.

=item delete

When called as an object method, it immediately deletes the row in the database
corresponding to this object.  When called as a class method, it returns a
query that can be used to delete objects from the corresponding table.

 $obj->delete; # SQL DELETE was executed.

 $query = MyClass->delete; # No SQL was executed.

=item def_data_source

Define the data source for this object.

    MyClass->def_data_source( 'database_name', 'table_name');

=item def_accessor ( $accessor_name, \%options )

    Customer->def_accessor( 'id', { column => 'cust_id', auto_increment => 1 } );

Options (explained below):

  column            => NAME
  auto_increment    => BOOLEAN
  select_when_null  => VALUE
  update_when_empty => VALUE
  select_trim       => BOOLEAN
  update_trim       => BOOLEAN
  string_mangle     => BOOLEAN

=over

=item column => NAME

The column name in the database. The default is the accessor name.

=item auto_increment => BOOLEAN

The column value is generated by the database, and should not be INSERTED.

=item select_when_null => VALUE

Select VALUE when a column's value is NULL.

=item update_when_empty => VALUE

Use VALUE instead of the empty string for I<updates and inserts>.

=item select_trim => BOOLEAN

Trim leading and trailing whitespace after selecting the value from the database.

=item update_trim => BOOLEAN

Trim leading and trailing whitespace before I<updating or inserting>.

=item string_mangle => BOOLEAN

Apply all string mangling features to this column. This option is just a shortcut for:

    { select_trim => 1,
      update_trim => 1,
      select_when_null => '',
      update_when_empty => undef }

=back

=item def_column

Same as def_accessor, but the column name is first, and you can't specify
an EXPR as a column. In the options hash, you can provide an C<accessor> key
to rename the accessor.

=item def_has_a

Define a relationship

 MyClass->def_has_a ('affiliate', [qw(name aff_id)], 'Affiliate_table', [qw(c_name id)]);
 MyClass->def_has_a ($accessor, $many_key, $table, $one_key, $opts)

=item def_has_many

Define a relationship.

 MyClass->def_has_many ( $accessor, $table, [$one_columns], [$many_columns], $opts );
 MyClass->def_has_many ( $accessor, $table, $opts );
 MyClass->def_has_many ( $accessor, $table, $query, $bind_routine, $opts )

=item def_select_group

Define a selection group.

 MyClass->def_select_group ([ $cols ])
 MyClass->def_select_group ( $group => [ $cols...] )

=back

=back

=head1 NAMESPACE ISSUES

Since your module ISA DBomb::Base, it inherits all of DBomb::Base's
methods and attributes. Here is a comprehensive list of the methods your
module will inherit. Any omissions should be considered a bug.

=over

=item Public Methods

These methods are documented elsewhere in this manual.

    def_accessor
    def_column
    def_data_source
    def_has_a
    def_has_many
    def_key
    def_primary_key
    def_select_group

    dbh_reader
    dbh_writer
    delete
    init
    insert
    select
    select_count
    selectall_arrayref
    update

=item Private Methods

These methods are private, and should not be overridden by your
modules.

    new            # do not override. use init() instead
    _dbo*         # do not call or override any method named _dbo*

=back

=head1 PERFORMANCE

The DBomb layer does not increase the asymptotic running time of your
code as compared to straight DBI. That should keep most of you happy.

For the rest of you speed freaks, here are the ways that DBomb optimizes for
performance:

=over

=item * calls prepare_cached() instead of prepare()

=item * selectall_arrayref delays object instantiation until necessary

=item * pools reader/writer database handles (TODO)

=item * reuses objects by primary key (TODO)

=back

=head1 VERSION

DBomb $Revision: 1.26 $

=head1 AUTHOR

John Millaway <millaway@cpan.org>

=cut

