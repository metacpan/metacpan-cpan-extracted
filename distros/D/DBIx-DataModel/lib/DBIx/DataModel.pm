#----------------------------------------------------------------------
package DBIx::DataModel;
#----------------------------------------------------------------------
# see POD doc at end of file

use 5.010;
use warnings;
use strict;
use version;
use MRO::Compat;
use DBIx::DataModel::Meta::Utils qw/does/;

our $VERSION = '3.13';

# compatibility setting : see import()
our $COMPATIBILITY = $VERSION; # from 2.20, no longer automatic compatibility

sub import {
  my ($class, %args) = @_;
  if (exists $args{-compatibility}) {
    $COMPATIBILITY = $args{-compatibility} # explicit number
                  || $VERSION;             # undef : means no compatibility
  }

  require DBIx::DataModel::Compatibility::V1
    if version->parse($COMPATIBILITY) < version->parse("1.99");
  require DBIx::DataModel::Compatibility::V0
    if version->parse($COMPATIBILITY) < version->parse("1.00");
}


sub define_schema {
  my ($class, %params) = @_;

  require DBIx::DataModel::Meta::Schema;
  my $meta_schema = DBIx::DataModel::Meta::Schema->new(%params);
  return $meta_schema;
}

sub Schema { # syntactic sugar for ->define_schema()
  my $class             = shift;
  my $schema_class_name = shift;
  my %params  = scalar(@_) == 1 && does($_[0], 'HASH') ? %{$_[0]} : @_;
  my $meta_schema = $class->define_schema(class => $schema_class_name, %params);
  return $meta_schema->class;
}


1; # End of DBIx::DataModel

__END__

=head1 NAME

DBIx::DataModel - UML-based Object-Relational Mapping (ORM) framework

=head1 INTRODUCTION

C<DBIx::DataModel> is a framework for building Perl
abstractions (classes, objects and methods) that interact
with relational database management systems (RDBMS).
Working above the L<DBI|DBI> module, it provides facilities for generating SQL queries,
joining tables automatically, navigating through the results,
converting values, building complex datastructures and packaging
the results in various formats.

This framework is complex and rich in functionalities, so a fair amount of
time is needed for discovering the documentation and experimenting with the
various features.

More explanations are given in the L</DESCRIPTION> section below,
after the synopsis.

=head1 VERSION

This is the 3rd generation of C<DBIx::DataModel>.
Compatibility layers with older versions may be
L<loaded on demand|DBIx::DataModel::Compatibility::V1>.
Changes are documented in L<DBIx::DataModel::Doc::Delta_v3>,
L<DBIx::DataModel::Doc::Delta_v2>
and L<DBIx::DataModel::Doc::Delta_v1>.


=head1 SYNOPSIS

This section is a short appetizer on the main features
of C<DBIx::DataModel>. The first part is about schema declaration;
the second part is about how to use that schema in database requests.


=head2 in file "My/Schema.pm" (schema declaration)

=head3 Schema 

Load C<DBIx::DataModel>.

  use DBIx::DataModel;

Declare the schema, either in shorthand notation :

  DBIx::DataModel->Schema('My::Schema');

or in verbose form :

  DBIx::DataModel->define_schema(
    class => 'My::Schema',
    %options,
  );

This automatically creates a Perl class named C<My::Schema>.

Various parameters may be specified within C<%options>, like
for example special columns to be filled automatically 
or to be ignored in every table : 

  my $last_modif_generator = sub {$ENV{REMOTE_USER}.", ".scalar(localtime)};
  my %options = (
    auto_update_columns => {last_modif => $last_modif_generator},
    no_update_columns   => [qw/date_modif time_modif/],
  );

=head3 Types

Declare a "column type" with some handlers, either in shorthand notation :

  My::Schema->Type(Date =>
     from_DB  => sub {$_[0] =~ s/(\d\d\d\d)-(\d\d)-(\d\d)/$3.$2.$1/},
     to_DB    => sub {$_[0] =~ s/(\d\d)\.(\d\d)\.(\d\d\d\d)/$3-$2-$1/},
     validate => sub {$_[0] =~ m/(\d\d)\.(\d\d)\.(\d\d\d\d)/},
   );

or in verbose form :

  My::Schema->metadm->define_type(
    name     => 'Date',
    handlers => {
      from_DB  => sub {$_[0] =~ s/(\d\d\d\d)-(\d\d)-(\d\d)/$3.$2.$1/},
      to_DB    => sub {$_[0] =~ s/(\d\d)\.(\d\d)\.(\d\d\d\d)/$3-$2-$1/},
      validate => sub {$_[0] =~ m/(\d\d)\.(\d\d)\.(\d\d\d\d)/},
    });

This does I<not> create a Perl class; it just defines an internal datastructure
that will be attached to some columns in some tables. Here are some other
examples of column types :

  # 'percent' conversion between database (0.8) and user (80)
  My::Schema->metadm->define_type(
    name     => 'Percent',
    handlers => {
      from_DB  => sub {$_[0] *= 100 if $_[0]},
      to_DB    => sub {$_[0] /= 100 if $_[0]},
      validate => sub {$_[0] =~ /1?\d?\d/}),
    });
  
  # lists of values, stored as scalars with a ';' separator
  My::Schema->metadm->define_type(
    name     => 'Multivalue',
    handlers => {
     from_DB  => sub {$_[0] = [split /;/, $_[0] || ""]     },
     to_DB    => sub {$_[0] = join ";", @$_[0] if ref $_[0]},
    });
  
  # adding type information for the DBD handler to inform Oracle about XML data
  My::Schema->metadm->define_type(
    name     => 'XML',
    handlers => {
     to_DB    => sub {$_[0] = [{dbd_attrs => {ora_type => ORA_XMLTYPE}}, $_[0]]
                        if $_[0]},
    });

=head3 Tables

Declare the tables, either in shorthand notation :

  #                    Perl Class   DB Table     Primary key
  #                    ==========   ========     ===========
  My::Schema->Table(qw/Employee     T_Employee   emp_id     /)
            ->Table(qw/Department   T_Department dpt_id     /)
            ->Table(qw/Activity     T_Activity   act_id     /);

or in verbose form :

  My::Schema->metadm->define_table(
    class       => 'Employee',
    db_name     => 'T_Employee',
    primary_key => 'emp_id',
  );
  My::Schema->metadm->define_table(
    class       => 'Department',
    db_name     => 'T_Department',
    primary_key => 'dpt_id',
  );
  My::Schema->metadm->define_table(
    class       => 'Activity',
    db_name     => 'T_Activity',
    primary_key => 'act_id',
  );

Each table then becomes a Perl class prefixed with the Schema name,
i.e. C<My::Schema::Employee>, etc.


=head3 Column types within tables

Declare column types within these tables :

  #                                          type name  => applied_to_columns
  #                                          =========     ==================
  My::Schema::Employee->metadm->set_column_type(Date    => qw/d_birth/);
  My::Schema::Activity->metadm->set_column_type(Date    => qw/d_begin d_end/);
  My::Schema::Activity->metadm->set_column_type(Percent => qw/activity_rate/);

=head3 Associations

Declare associations or compositions in UML style, either in
shorthand notation :

  #                           class      role     multiplicity  join
  #                           =====      ====     ============  ====
  My::Schema->Composition([qw/Employee   employee   1           emp_id /],
                          [qw/Activity   activities *           emp_id /])
            ->Association([qw/Department department 1                  /],
                          [qw/Activity   activities *                  /]);


or in verbose form :

  My::Schema->define_association(
    kind => 'Composition',
    A    => {
      table        => My::Schema::Employee->metadm,
      role         => 'employee',
      multiplicity => 1,
      join_cols    => [qw/emp_id/],
    },
    B    => {
      table        => My::Schema::Activity->metadm,
      role         => 'activities',
      multiplicity => '*',
      join_cols    => [qw/emp_id/],
    },
  );
  My::Schema->define_association(
    kind => 'Association',
    A    => {
      table        => My::Schema::Department->metadm,
      role         => 'department',
      multiplicity => 1,
    },
    B    => {
      table        => My::Schema::Activity->metadm,
      role         => 'activities',
      multiplicity => '*',
    },
  );

Declare a n-to-n association

  My::Schema->Association([qw/Department departments * activities department/],
                          [qw/Employee   employees   * activities employee/]);
  # or
  My::Schema->define_association(
    kind => 'Association',
    A    => {
      table        => My::Schema::Department->metadm,
      role         => 'departments',
      multiplicity => '*',
      join_cols    => [qw/activities department/],
    },
    B    => {
      table        => My::Schema::Employee->metadm,
      role         => 'employees',
      multiplicity => '*',
      join_cols    => [qw/activities employee/],
    },
  );




=head3 Adding methods into the generated classes

For details that could not be expressed in a declarative way,
just add a new method into the table class :

  package My::Schema::Activity;
  
  sub active_period {
    my $self = shift;
    $self->{d_begin} or croak "activity has no d_begin";
    $self->{d_end} ? "from $self->{d_begin} to $self->{d_end}"
                   : "since $self->{d_begin}";
  }

=head3 Data tree expansion

Declare how to automatically expand objects into data trees

  My::Schema::Activity->metadm->define_auto_expand(qw/employee department/);

=head3 Automatic schema generation

  perl -MDBIx::DataModel::Schema::Generator      \
       -e "fromDBI('dbi:connection:string')" --  \
       -schema My::New::Schema > My/New/Schema.pm

See L<DBIx::DataModel::Schema::Generator>.



=head2 in file "my_client.pl" (schema usage)

=head3 Connecting the schema to the database

  use My::Schema;
  use DBI;
  my $dbh = DBI->connect($dsn, ...);
  My::Schema->dbh($dbh);                     # single-schema mode
  # or
  my $schema = My::Schema->new(dbh => $dbh); # multi-schema mode

=head3 Simple data retrieval

Search employees whose name starts with 'D'
(the select API is taken from L<SQL::Abstract::More>)

  my $empl_D = My::Schema->table('Employee')->select(
    -where => {lastname => {-like => 'D%'}},
  );

idem, but we just want a subset of the columns, and order by age.

  my $empl_F = My::Schema->table('Employee')->select(
    -columns  => [qw/firstname lastname d_birth/],
    -where    => {lastname => {-like => 'F%'}},
    -order_by => 'd_birth',
  );

Print some info from employees.

  foreach my $emp (@$empl_D) {
    print "$emp->{firstname} $emp->{lastname}, born $emp->{d_birth}\n";
  }

As demonstrated here, each database row is just a Perl hashref, with
database columns as hash keys (unlike most other ORMs where columns
are accessed through method calls).

Column 'd_birth' is directly printable because it
has been automatically converted to the appropriate format
through the 'from_DB' handler associated with column type 'date'.


=head3 Methods to follow joins

Follow the joins through path methods

  foreach my $act (@{$emp->activities}) {
    printf "working for %s from $act->{d_begin} to $act->{d_end}", 
      $act->department->{name};
  }

Path methods can take arguments too, like C<select()>

  my $recent_activities
    = $dpt->activities(-where => {d_begin => {'>=' => '2005-01-01'}});
  my @recent_employees
    = map {$_->employee(-columns => [qw/firstname lastname/])}
          @$recent_activities;

=head3 Data export : just regular hashrefs

Export the data : get related records and insert them into
a data tree in memory; then remove all class information and 
export that tree.

  $_->expand('activities') foreach @$empl_D;
  My::Schema->unbless($empl_D);
  my $export = {employees => $empl_D};
  use Data::Dumper; print Dumper ($export); # export as PerlDump
  use XML::Simple;  print XMLout ($export); # export as XML
  use JSON;         print to_json($export); # export as Javascript
  use YAML;         print Dump   ($export); # export as YAML

B<Note>: the C<unbless> step is optional; it is proposed here
because some exporter modules will not work if they
encounter a blessed reference.


=head3 Database join

Select columns from several tables through a database join

  my $lst = My::Schema->join(qw/Employee activities department/)
                      ->select(-columns => [qw/lastname dept_name d_begin/],
                               -where   => {d_begin => {'>=' => '2000-01-01'}});

Same thing, but forcing INNER joins

  my $lst = My::Schema->join(qw/Employee <=> activities <=> department/)
                      ->select(...);


=head3 Statements and pagination

Instead of retrieving directly a list of records, get a
L<statement|DBIx::DataModel::Statement> :

  my $statement 
    = My::Schema->join(qw/Employee activities department/)
                ->select(-columns   => [qw/lastname dept_name d_begin/],
                         -where     => {d_begin => {'>=' => '2000-01-01'}},
                         -result_as => 'statement');

Retrieve a single row from the statement

  my $single_row = $statement->next or die "no more records";

Retrieve several rows at once

  my $rows = $statement->next(10); # arrayref

Go to a specific page and retrieve the corresponding rows

  my $statement 
    = My::Schema->join(qw/Employee activities department/)
                ->select(-columns   => [qw/lastname dept_name d_begin/],
                         -result_as => 'statement',
                         -page_size => 10);
  
  $statement->goto_page(3);    # absolute page positioning
  $statement->shift_pages(-2); # relative page positioning
  my ($first, $last) = $statement->page_boundaries;
  print "displaying rows $first to $last:";
  some_print_row_method($_) foreach @{$statement->page_rows};


=head3 Efficient use of statements 

For fetching related rows : prepare a statement before the loop, execute it
at each iteration.

  my $statement = $schema->table($name)->join(qw/path1 path2/);
  $statement->prepare(-columns => ...,
                      -where   => ...);
  my $list = $schema->table($name)->select(...);
  foreach my $obj (@$list) {
    my $related_rows = $statement->execute($obj)->all;
    # or
    my $related_rows = $statement->bind($obj)->select;
    ... 
  }

Fast statement : each data row is retrieved into the same
memory location (avoids the overhead of allocating a hashref
for each row). This is faster, but such rows cannot be accumulated
into an array (they must be used immediately) :

  my $fast_stmt = ..->select(..., -result_as => "fast_statement");
  while (my $row = $fast_stmt->next) {
    do_something_immediately_with($row);
  }


=head3 Other kinds of results

  my $json = $source->select(..., -result_as => 'json');
  my $yaml = $source->select(..., -result_as => 'yaml');
  my $tree = $source->select(..., -result_as => [categorize => ($key1, $key2)]);
  $source->select(..., -result_as => [tsv  => $name_of_tab_separated_file]);
  $source->select(..., -result_as => [xlsx => $name_of_Excel_file]);
  ...


=head3 Insert

  my $table = $schema->table($table_name);

  # if the primary key is supplied by the client
  $table->insert({pk_column => $pk_val, col1 => $val1, col2 => $val2, ...});

  # if the primary key is generated by the database
  my $id = $table->insert({col1 => $val1, col2 => $val2, ...});
  #  This assumes your DBD driver implements last_insert_id.

  # insert multiple records using a list of arrayrefs -- first arrayref 
  # defines column names
  $table->insert( [qw/  col1    col2    /],
                  [qw/  val11   val12   /],
                  [qw/  val22   val22   /], );

  # alternatively, insert multiple records expressed as a list of hashes
  $table->insert(
      {col1 => val11, col2 => val12},
      {col1 => val21, col2 => val22},
  );

  # insert into a related table (the foreign key will be filled automatically)
  $an_employee->insert_into_activities({d_begin => $today,
                                        dpt_id  => $dpt});


=head3 Update

  # update on a set of columns, primary key included
  my $table = $schema->table($table_name);
  $table->update({pk_column => $pk, col1 => $val1, col2 => $val2, ...});

  # update on a set of columns, primary key passed separately
  $table->update(@primary_key, {col1 => $val1, col2 => $val2, ...});

  # update all records matching some condition
  $table->update(-set   => {col1 => $val1, col2 => $val2, ...},
                 -where => \%condition);

  # update() invoked as instance method instead of class method
  $obj->update({col1 => $val1, ...}); # updates specified columns
  $obj->update;                       # updates all columns stored in memory


=head3 Delete

  # delete() as class method
  my $table = $schema->table($table_name);
  $table->delete(@primary_key);

  # delete all records matching some condition
  $table->delete(-where => \%condition);

  # delete() as instance method
  $obj->delete;


=head1 DESCRIPTION

=head2 Perl ORMs

There are many other CPAN modules offering 
somewhat similar features, like
L<DBIx::Class|DBIx::Class>,
L<Rose::DB::Object|Rose::DB::Object>,
L<Jifty::DBI|Jifty::DBI>,
L<Fey::ORM|Fey::ORM>,
just to name a few ...
there is more than one way to do it!
Frameworks in this family are called
I<object-relational mappings> (ORMs)
-- see L<http://en.wikipedia.org/wiki/Object-relational_mapping>.


=head2 Strengths of C<DBIx::DataModel>

The L<DESIGN|DBIx::DataModel::Doc::Design> chapter of this
documentation explains the main design decisions of
C<DBIx::DataModel>. Some of the strong points are :

=over

=item *

centralized, UML-style declaration of tables and relationships
(instead of many files with declarations such as 'has_many', 'belongs_to',
etc.)

=item *

limited coupling with the database schema : there is no need to declare
every column of every table; C<DBIx::DataModel> only needs to know
about tables, associations, primary keys and foreign keys

=item *

exposure of database operations like joins, bulk updates, subqueries,
etc.  The database is not hidden behind object-oriented programming
concepts, as some other ORMs try to do, but rather made to explicitly
collaborate with the object-oriented layer.

=item *

efficiency through a very lightweight infrastructure (row objects
are just blessed hashrefs) and through
fine tuning of interaction with the DBI layer
(prepare/execute, fetch into reusable memory location, etc.)

=item *

usage of L<SQL::Abstract::More> for an improved API
over L<SQL::Abstract> (named parameters, additional clauses,
simplified 'order_by', support for values with associated datatypes, etc.)

=item *

clear conceptual distinction between

=over

=item *

data sources         (tables and joins),

=item *

database statements  (stateful objects representing stepwise building
                      of an SQL query and stepwise retrieval of results),

=item *

data rows            (lightweight hashrefs containing nothing but column
                      names and values)

=back 

=item *

simple syntax for joins, with the possibility to override default
INNER JOIN/LEFT JOIN properties, and with clever usage of Perl
multiple inheritance for simultaneous access to the methods of all
tables that participate in that join

=item *

nested, cross-database transactions

=item *

choice between 'single-schema' mode (default, more economical) 
and 'multi-schema' mode (optional, more flexible, but a little
more costly in memory)

=back


=head2 Limitations

Here are some limitations of C<DBIx::DataModel>, in comparison
with other Perl ORMs :

=over

=item no schema versioning

C<DBIx::DataModel> knows very little about the database
schema (only tables, primary and foreign keys, and possibly
some columns, if they need special 'Types'); therefore
it provides no support for schema changes (and seldom
needs to know about them).

=item no object caching nor 'dirty columns'

C<DBIx::DataModel> does not keep track of data mutations
in memory, and therefore provides no support for automatically
propagating changes into the database; the client code has to
explicitly manage C<insert> and C<update> operations.

=item no 'cascaded update' nor 'insert or update'

Cascaded inserts and deletes are supported, but not cascaded updates.
This would need 'insert or update', which is not supported.

=back


=head1 INDEX TO THE DOCUMENTATION

Although the basic principles are quite simple, there are many
details to discuss, so the documentation is quite long.
In an attempt to accommodate for different needs of readers,
the documentation has been structured as follows :

=over

=item * 

The L<DESIGN|DBIx::DataModel::Doc::Design> chapter covers the
architecture of C<DBIx::DataModel>, its main distinctive features and
the motivation for such features; it is of interest if you are
comparing various ORMs, or if you want to globally understand
how C<DBIx::DataModel> works, and what it can or cannot do.
This chapter also details the concept of 
L<statements|DBIx::DataModel::Doc::Glossary/"STATEMENT OBJECTS">.


=item *

The L<QUICKSTART|DBIx::DataModel::Doc::Quickstart> chapter
is a guided tour that 
summarizes the main steps to get started with the framework.

=item *

The L<REFERENCE|DBIx::DataModel::Doc::Reference> chapter
is a complete reference to all methods, structured along usage steps :
creating a schema, populating it with table and associations,
parameterizing the framework, and finally data retrieval and
manipulation methods.

=item *

The L<COOKBOOK|DBIx::DataModel::Doc::Cookbook> chapter
provides some recipes for common ORM tasks.

=item *

The L<INTERNALS|DBIx::DataModel::Doc::Internals> chapter
documents the internal structure of the framework, for programmers
who might be interested in extending it.


=item *

The L<GLOSSARY|DBIx::DataModel::Doc::Glossary> 
defines terms used in this documentation,
and points to the software constructs that
implement these terms.

=item *

The L<DELTA_v3|DBIx::DataModel::Doc::Delta_v3>,
L<DELTA_v2|DBIx::DataModel::Doc::Delta_v2>
and L<DELTA_v1|DBIx::DataModel::Doc::Delta_v1> chapters
summarize the differences between major versions.


=item *

The L<DBIx::DataModel::Schema::Generator|DBIx::DataModel::Schema::Generator>
documentation explains how to automatically generate a schema from
a C<DBI> connection, from a L<SQL::Translator|SQL::Translator> description
or from an existing L<DBIx::Class|DBIx::Class> schema.


=back

Presentation slides are also available at
L<http://www.slideshare.net/ldami/dbix-datamodel-endetail>

=head1 SIDE-EFFECTS

Upon loading, L<DBIx::DataModel::Join> adds a coderef
into global C<@INC> (see L<perlfunc/require>), so that it can
generate a class on the fly when retrieving frozen
objects from L<Storable/thaw>. This should be totally harmless unless
you do some very special things with C<@INC>.


=head1 SUPPORT AND CONTACT

Bugs should be reported via the CPAN bug tracker at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-DataModel>.

Sources are stored in an open repository at
L<http://github.com/damil/DBIx-DataModel>.



=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 ACKNOWLEDGEMENTS

Thanks to

  Ross Attril
  Cedric Bouvier
  Terrence Brannon
  Alex Solovey
  Sergiy Zuban

who contributed with ideas, bug fixes and/or improvements.


=head1 COPYRIGHT AND LICENSE

Copyright 2005-2018 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
