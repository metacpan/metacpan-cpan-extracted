# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of DBIx-RoboQuery
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package DBIx::RoboQuery;
{
  $DBIx::RoboQuery::VERSION = '0.032';
}
# git description: v0.031-6-gaa2e204

BEGIN {
  $DBIx::RoboQuery::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Very configurable/programmable query object

use Carp qw(carp croak);
use DBIx::RoboQuery::ResultSet ();
use DBIx::RoboQuery::Util ();
use Template 2.22; # Template Toolkit

# no warnings 'once';
my $_template_stash_private = $Template::Stash::PRIVATE;


sub new {
  my $class = shift;
  my %opts = @_ == 1 ? %{ $_[0] } : @_;

  # Params::Validate not currently warranted
  # (since it's still missing the "mutually exclusive" feature)

  # defaults
  my $self = {
    drop_columns => [],
    key_columns => [],
    resultset_class => "${class}::ResultSet",
    variables => {},
    template_tr_name => 'template',
  };

  bless $self, $class;

  foreach my $var ( $self->_pass_through_args() ){
    $self->{$var} = $opts{$var} if exists($opts{$var});
  }

  DBIx::RoboQuery::Util::_ensure_arrayrefs($self);

  croak(q|Cannot include both 'sql' and 'file'|)
    if exists($opts{sql}) && exists($opts{file});

  # if the string is defined that's good enough
  if( defined($opts{sql}) ){
    $self->{template} = ref($opts{sql}) ? ${$opts{sql}} : $opts{sql};
  }
  # the file path should at least be a true value
  elsif( my $f = $opts{file} ){
    open(my $fh, '<', $f)
      or croak("Failed to open '$f': $!");
    $self->{template} = do { local $/; <$fh>; };
  }
  else {
    croak(q|Must specify one of 'sql' or 'file'|);
  }

  $self->prepare_transformations();

  $self->{tt} ||= Template->new({
    ABSOLUTE => 1,
    STRICT => 1,
    VARIABLES => {
      query => $self,
      %{$self->{variables}}
    },
    %{ $self->{template_options} || {} },
  })
    or die "$class error: Template::Toolkit failed: $Template::ERROR\n";

  return $self;
}

# convenience method for subclasses

sub _arrayref_args {
  qw(
    bind_params
    drop_columns
    key_columns
    order
  );
}


sub bind {
  my ($self, @bind) = @_;

  my $bound = $self->{bind_params} ||= [];

  # auto-increment placeholder index unless all three values were passed
  unshift @bind, ++$self->{bind_params_index}
    unless @bind == 3;

  # always push (don't set $bound->[$index]) because we're just going
  # to pass all of these to bind_param() in order
  push @$bound, \@bind;

  # convenience for putting directly into place in sql
  return $bind[0] =~ /^\d+$/ ? '?' : $bind[0];
}


sub bound_params {
  return @{ $_[0]->{bind_params} || [] };
}


sub bound_values {
  return map { $_->[1] } $_[0]->bound_params;
}


sub drop_columns {
  my ($self) = shift;
  $self->{drop_columns} = [DBIx::RoboQuery::Util::_flatten(@_)]
    if @_;
  return @{$self->{drop_columns}};
}


sub key_columns {
  my ($self) = shift;
  $self->{key_columns} = [DBIx::RoboQuery::Util::_flatten(@_)]
    if @_;
  return @{$self->{key_columns}};
}


sub order {
  my ($self) = shift;
  if( @_ ){
    $self->{order} = [DBIx::RoboQuery::Util::_flatten(@_)]
  }
  # only if not previously set (empty arrayref counts as being set)
  elsif( !$self->{order} ){
    $self->{order} = [
      DBIx::RoboQuery::Util::order_from_sql(
        $self->sql, $self)
    ]
  }
  return @{$self->{order}};
}

# convenience method: args allowed in the constructor

sub _pass_through_args {
  (
    $_[0]->_arrayref_args,
  qw(
    dbh
    default_slice
    prefix
    resultset_class
    squeeze_blank_lines
    suffix
    template_options
    transformations
    template_private_vars
    template_tr_name
    variables
  ));
}


sub prepare_transformations {
  my ($self) = @_;

  return
    unless my $tr = $self->{transformations};

  # assume a simple hash is a hash of named subs
  if( ref $tr eq 'HASH' ){
    require Sub::Chain::Group;

    # the name of the template func can be changed (or disabled)
    if( my $tr_name = $self->{template_tr_name} ){
      # add the template callback to the subs (with $self embedded)
      $tr = {
        %$tr,
        $tr_name => $self->template_tr_callback,
      }
        if ! exists $tr->{ $tr_name };
    }

    $self->{transformations} =
      Sub::Chain::Group->new(
        chain_class => 'Sub::Chain::Named',
        chain_args  => {subs => $tr},
        hook_as_hash => 1,
      );
  }

  # return nothing
  return;
}


sub pre_process_sql {
  my ($self, $sql) = @_;
  $sql = $self->{prefix} . $sql if defined $self->{prefix};
  $sql = $sql . $self->{suffix} if defined $self->{suffix};
  return $sql;
}


sub prefer {
  my ($self) = shift;
  push(@{ $self->{preferences} ||= [] }, @_);
}

sub _process_template {
  my ($self, $template, $vars) = @_;
  my $output = '';

  # this is a regexp for vars that are considered private (will appear undef in template)
  local $Template::Stash::PRIVATE = $self->{template_private_vars}
    if exists $self->{template_private_vars};

  $self->{tt}->process($template, $vars, \$output)
    or die($self->{tt}->error(), "\n");

  return $output;
}


sub resultset {
  my ($self) = shift;
  # cache this object to avoid confusion
  return $self->{resultset} ||= do {
    # taint check
    (my $class = $self->{resultset_class}) =~ s/[^a-zA-Z0-9_:']+//g;
    # make sure it's loaded first
    eval "require $class";
    die $@ if $@;

    $class->new($self);
  }
}


sub sql {
  my ($self, $vars) = @_;
  my $output;

  # Cache the result to avoid duplicating function calls,
  # directives, template logic, etc.
  # Plus it shouldn't need to be run more than once.
  if( exists $self->{processed_sql} ){
    $output = $self->{processed_sql};
  }
  else {
    $vars ||= {};
    my $sql = $self->pre_process_sql($self->{template});
    $output = $self->_process_template(\$sql, $vars);

    # this is fairly naive, but for SQL would usually be fine
    $output =~ s/\n\s*\n+/\n/g
      if $self->{squeeze_blank_lines};

    $self->{processed_sql} = $output;
  }
  return $output;
}


sub transform {
  my ($self, @tr) = @_;

  croak("Cannot transform without 'transformations'")
    unless my $tr = $self->{transformations};

  $tr->append(@tr);
}

# shortcuts


sub tr_fields {
  my ($self, $name, $fields, @args) = @_;
  return $self->transform($name, fields => $fields, args => [@args]);
}

sub tr_groups {
  my ($self, $name, $groups, @args) = @_;
  return $self->transform($name, groups => $groups, args => [@args]);
}


sub tr_row {
  my ($self, $name, $hooks, @args) = @_;
  return $self->transform($name, hooks => $hooks, args => [@args]);
}


sub template_tr_callback {
  my ($self) = @_;
  return sub {
    my ($row, $template) = @_;
    # (updating the hash should work, but if not this would: '[% _save_row(row) %]')
    $template = '[% ' . $template . ' %]';
    $self->_process_template(\$template, {row => $row});
    return $row;
  };
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS dbh sql resultset TODO arrayrefs cpan
testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto
metadata placeholders metacpan

=head1 NAME

DBIx::RoboQuery - Very configurable/programmable query object

=head1 VERSION

version 0.032

=head1 SYNOPSIS

  my $template_string = <<SQL;
  [%
    CALL query.key_columns('user_id');
    CALL query.drop_columns('favorite_smell');
    CALL query.prefer('favorite_smell != "wet dog"');
    CALL query.transform('format_date', {fields => 'birthday'});
  %]
    SELECT
      name,
      user_id,
      dob as birthday,
      favorite_smell
    FROM users
    WHERE dob < [% query.bind(minimum_birthdate()) %]
  SQL

  # create query object from template
  my $query = DBIx::RoboQuery->new(
    sql => $template_string,       # (or use file => $filepath)
    dbh => $dbh,                   # handle returned from DBI->connect()
    transformations => {           # functions available for transformation
      format_date => \&arbitrary_date_format,
      trim => sub { (my $s = $_[0]) =~ s/^\s+|\s+$//g; $s },
    },
    variables => {                 # variables for use in template
      minimum_birthdate => \&arbitrary_date_function,
    }
  );

  # transformations (and other configuration) can be specified in the sql
  # template or in your code if you know you'll always want certain ones
  $query->transform('trim', group => 'non_key_columns');

  my $resultset = $query->resultset;

  $resultset->execute;
  my @non_key = $resultset->non_key_columns;
  # do something where i want to know the difference between key and non-key columns

  # get records (with transformations applied and specified columns dropped)
  my $records = $resultset->hash;            # like DBI/fetchall_hashref
  # OR: my $records = $resultset->array;     # like DBI/fetchall_arrayref

=head1 DESCRIPTION

This robotic query object can be configured to help you
get exactly the result set that you want.

It was designed to run in a completely automated (unmanned) environment and
read in a template that both builds the desired SQL query dynamically
and configures the query output.
It should be usable anywhere you desire
a highly configurable query and result set.

It (and its companion L<ResultSet|DBIx::RoboQuery::ResultSet>)
provide various methods for configuring/declaring
what to expect and what to return.
It aims to be as informative as you might need it to be.

The following enhancements are possible:

=over 4

=item *

The query can be built with templates
(currently L<Template::Toolkit|Template>)
which allows for perl variables and functions
to interpolate and/or generate the SQL

=item *

The output can be transformed (using L<Sub::Chain::Group>).
You can specify multiple transformations per field
and you can specify transformations that operate on the whole row.
This way you can set the value of one field based on the value of another.

See L</transform> (and the C<tr_*> shortcuts),
L</template_tr_callback>,
C<template_tr_name> (in L</new>)
and L<Sub::Chain::Group/HOOKS>
for more information.

=item *

TODO: list more

=back

See note about L</SECURITY>.

=head1 METHODS

=head2 new

  my $query = DBIx::RoboQuery->new(%opts); # or \%opts

Constructor;  Accepts a hash or hashref of options:

=over 4

=item *

C<sql>

The SQL query [template] in a string;
This can be a reference to a string in case your template [query]
is large and it makes you feel better to pass it by reference.

=item *

C<file>

The file path of a SQL query [template] (mutually exclusive with C<sql>)

=item *

C<dbh>

A database handle (the return of C<< DBI->connect() >>)

=item *

C<default_slice>

The default slice of the records returned;
It is not used by the query but merely passed to the ResultSet object.
See L<DBIx::RoboQuery::ResultSet/array>.

=item *

C<drop_columns>

An arrayref of columns to be dropped from the resultset;  See L</drop_columns>.

=item *

C<key_columns>

An arrayref of [primary key] column names;  See L</key_columns>.

=item *

C<order>

An arrayref of column names to specify the sort order;  See L</order>.

=item *

C<prefix>

A string to be prepended to the SQL before parsing the template

=item *

C<squeeze_blank_lines>

Boolean; If enabled, empty lines (or lines with only whitespace)
will be removed from the compiled template.
This can make it easier to look at sql that has a lot of template directives.
(Disabled by default.)

=item *

C<suffix>

A string to be appended  to the SQL before parsing the template

=item *

C<template_options>

A hashref of options that will be merged into the options to
L<< Template->new()|Template >>
You can use this to overwrite the default options, but be sure to use the
C<variables> options rather than including C<VARIABLES> in this hash
unless you don't want the default variables to be available to the template.

=item *

C<template_private_vars>

B<Not normally needed>

This is a regexp (which defaults to C<$Template::Stash::PRIVATE>
(which defaults to C<qr/^[_.]/>)).
Any template variables that match will not be accessible in the template
(but will return undef, which will throw an error under C<STRICT> mode).
If you want to access "private" variables (including "private" hash keys)
in your templates (the main query template or any templates passed to L</prefer>)
you should set this to C<undef> to tell L<Template> not to check variable names.

=item *

C<template_tr_name>

If you pass a hashref for C<transformations> the module will install
a sub that allows you to modify a row using the template syntax.
By default it is named C<template>,
but you may use this attribute to specify and alternate name
(or use C<undef> to disable the addition of this transformation sub).

=item *

C<transformations>

An instance of L<Sub::Chain::Group>
(or a hashref (See L</prepare_transformations>.))

=item *

C<variables>

A hashref of variables made available to the template

=back

=head2 bind

  $query->bind($value);
  $query->bind($value, \%attr);
  $query->bind($p_num, $value, \%attr);

Bind a value to a placeholder in the query.
The provided arguments are saved and eventually passed to L<DBI/bind_param>.

This can be useful for passing dynamic values
through the database driver's quoting mechanism.

For convenience a placeholder is returned
so that the method can be called in place in a query template:

  # in template:
  WHERE field = [% query.bind(value) %]

The placeholder will be the standard C<?> if the index is an integer,
or it will simply return the placeholder otherwise
which can be useful for drivers that allow named parameters:

  WHERE field = [% query.bind(':foo', value, {}) %]
  # becomes 'WHERE field = :foo'

If you don't want the placeholder added to your query
use the template's syntax to discard it.
For example, with L<Template::Toolkit>:

  [% CALL query.bind(value) %]

For convenience the placeholder (C<$p_num>) will be filled in automatically
(a simple incrementing integer starting at 1)
unless you provide all three arguments
(in which case they are passed as-is to L<DBI/bind_param>).

B<Note> that the index only auto-increments if you don't supply one
(by sending all three arguments):

  $query->bind($a);         # placeholder 1
  $query->bind($b, {});     # placeholder 2
  $query->bind(2, $c, {});  # overwrite placeholder 2
  $query->bind($d);         # placeholder 3   (a total of 3 bound parameters)
  $query->bind(4, $e, {});  # placeholder 4   (a total of 4 bound parameters)
  $query->bind($f);  # auto-inc to 4 (which will overwrite the previous item)

So don't mix the auto-increment with explicit indexes
unless you know what you are doing.

Consistency and simplicity was chosen over the complexity
added by special cases based on comparing the provided index
to the current (if any) auto-increment.

=head2 bound_params

  my @bound = $query->bound_params;
  # returns ( [ 1, "foo" ], [ 2, "bar", { TYPE => SQL_VARCHAR } ] )

Returns a list of arrayrefs representing parameters bound to the query.
Each arrayref is structured to be flattened and passed to L<DBI/bind_param>.
Each will contain it's index (or placeholder), value,
and possibly a hashref or value to hint at the data-type.

=head2 bound_values

This is a wrapper around L</bound_params>
that returns only the values:

  my @bound = $query->bound_values;
  # returns ("foo", "bar")

B<Note>: Values are returned in the order they were bound.
If L</bind> is used in any way other than the default auto-increment manner
the order (or even the number) of the values may be confusing and unhelpful.
In that case you probably want to use L</bound_params>
and get the values out manually.
This behavior may be improved in the future and should not be relied upon.
(Suggestions and patches for improved behavior are welcome.)
The behavior of this method
when L</bind> is used only in the default auto-increment manner
will not change.

=head2 drop_columns

  # get
  my @drop_columns = $query->drop_columns;
  # set
  $query->drop_columns(@columns_to_ignore);

Accessor for the list of columns to drop (remove) from the resultset;
This works like the L</key_columns> method.

Drop columns can be useful if you need a particular column in
the query but don't really want the column in the resultset.
Some databases are inconsistent with allowing the use of a non-selected
column in an C<ORDER BY> clause, for instance.

Drop columns can also be useful if you want to compare the value of a column
in a preference statement (see L</prefer>)
but don't want the column in the actual resultset.

It may be most useful to set this value from within the template
(see L</SYNOPSIS>).

=head2 key_columns

  # get
  my @key_columns = $query->key_columns;
  # set
  $query->key_columns('id', 'fk_id');
  # empty
  $query->key_columns([]);

Accessor for the list of [primary] key columns for the query;

Any arrayrefs provided (when setting the list) will be flattened.
This allows you to empty the list by sending an empty arrayref
(if you have a reason to do so).

L<DBIx::RoboQuery::ResultSet/hash> sends the key columns
to L<DBI/fetchall_hashref> to define I<unique> records.

It may be most useful to set this value from within the template
(see L</SYNOPSIS>).

=head2 order

  # get
  my @order = $query->order;
  # set
  $query->order(@column_order);

Accessor for the list of the column names of the sort order of the query;

This is a getter/setter which works like L</key_columns>
with one exception:
If the value has never been set
it is initialized to the list of columns from the C<ORDER BY> clause
of the sql statement as returned from
L<DBIx::RoboQuery::Util/order_from_sql>.
If there is no C<ORDER BY> clause or the statement cannot be parsed
an empty list will be returned.

It may be most useful to set this value from within the template
(see L</SYNOPSIS>), especially if your C<ORDER BY> clause is complex.

=head2 prepare_transformations

This method (called from the constructor)
prepares the C<transformations> attribute
(if one was passed to the constructor).

This method provides a shortcut for convenience:
If C<transformations> is a simple hash,
it is assumed to be a hash of named subs and is passed to
L<Sub::Chain::Group/new>
as the C<subs> key of the C<chain_args> hashref.
See L<Sub::Chain::Group> and L<Sub::Chain::Named>
for more information about these.

If you pass your own instance of L<Sub::Chain::Group>
this method will do nothing.
It is mostly here to help a subclass use a different module
for transformations if desired.

Additionally, if you pass in a hash ref
it will add a sub to the transformations hash named C<template>
(or the value you pass as C<template_tr_name> to the constructor)
if a sub by that name doesn't already exist.
It uses L</template_tr_callback> to create the code ref.

=head2 pre_process_sql

Prepend C<prefix> and append C<suffix>.
Called from L</sql> before processing the template
with the template engine.

=head2 prefer

  $query->prefer("color == 'red'", "color == 'green'");
  $query->prefer("smell == 'good'");

Accepts one or more rules to determine which record to choose
if you use C<< resultset->hash() >> and multiple records are found
for any given key field(s).

The "rules" are strings that will be processed by the templating engine
of the query object (currently L<Template::Toolkit|Template>).
The record's fields will be available as variables.

Each rule will be tested with each record and the first one to match
will be returned.

So considering the above example,
the following code will return the second record since it will match
one of the rules first.

  $resultset->preference(
    {color => 'blue',  smell => 'good'},
    {color => 'green', smell => 'bad'}
  );

The rules are tested in the order they are set,
and the records are processed in reverse order
(to be compatible with the "last one in wins" logic of L<DBI/fetchall_hashref>).

See
L<DBIx::RoboQuery::ResultSet/hash> and
L<DBIx::RoboQuery::ResultSet/preference>
for more information.

=head2 resultset

  my $resultset = $query->resultset;

This is a convenience method which returns a
L<DBIx::RoboQuery::ResultSet> object based upon this query.

To avoid confusion it caches the result
so that multiple calls to resultset()
will return the same object (rather than creating new ones).

If you desire a new resultset
(which will create a new L<DBI> statement handle)
or you desire to pass options
different than the attributes on the query,
you can manually call L<DBIx::RoboQuery::ResultSet/new>:

  my $resultset = DBIx::ResultSet->new($query, %other_options);

B<NOTE>: The ResultSet constructor calls L</sql>
before initializing the object
so that any configuration done to the query in the template
will be passed to the object at initialization.

=head2 sql

  $query->sql;
  $query->sql({extra => variable});

Process the SQL template and return the result.

This method caches the result of the processed template
to avoid unexpected side effects of calling any
configuration directives (that might be in the template) multiple times.

B<NOTE>: This method gets called (without arguments)
when a resultset is created (to ensure that the query is fully
configured before copying its attributes to the ResultSet).
If you need to pass extra template variables
(that were not passed to L</new>)
you should call this method (with those variables)
before instantiating any resultset objects.

=head2 transform

  $query->transform($sub, %opts);
  $query->transform($sub, fields => [qw(fld1 fld2)], args => []);

Add a transformation to be applied to the result data.

The default implementation simply passes the arguments
to L<Sub::Chain::Group/append>.

=head2 tr_fields

Shortcut for calling L</transform> on fields.

  $query->tr_fields("func", "fld1", "arg1", "arg2");

Is equivalent to

  $query->transform("func", fields => "fld1", args => ["arg1", "arg2"]);

The second parameter (the fields) can be either a single string
or an array ref.

=head2 tr_groups

Just like L</tr_fields> but the second parameter is for groups.

=head2 tr_row

  $query->tr_row("func", "before", @args);

This is a shortcut for calling L</transform> with a
"before" or "after" hook that operates on the whole row:

  $query->transform("func", hook => "before", @args);

=head2 template_tr_callback

This returns a code ref that can be included in the C<transformations> hash.
This is used internally by L</prepare_transformations>
but is available separately in case you need to add it manually
(if you're passing a C<transformations> object to the constructor
rather than a hash ref).

The sub returned by this method accepts a hashref
and a template string (without the C<[% %]>),
processes the template string (passing the hashref as a var named "row"),
and returns the hash ref (in case it was modified by the template):

  my $cb = $query->template_tr_callback;
  $cb->({foo => 'bar'}, q[ row.baz = "qux" ]);
  # returns { foo => 'bar', baz => 'qux' };

=for Pod::Coverage result results

=for test_synopsis my $dbh; # NOTE: This SYNOPSIS is read in and tested in t/synopsis.t

=head1 SECURITY

B<NOTE>: B<Obviously> this module is B<not> designed to take in external user input
since the SQL queries are passed through a templating engine.

This module is intended for use in internal environments
where you are the source of the query templates.

=head1 SEE ALSO

=over 4

=item *

L<DBIx::RoboQuery::ResultSet>

=item *

L<DBI>

=item *

L<Template::Toolkit|Template>

=back

=head1 TODO

=over 4

=item *

Allow for other templating engines (or none at all)

=item *

Consider an option for including direction (C<ASC>/C<DESC>) in L</order>

=item *

Write a lot more tests

=item *

Allow binding an arrayref and returning '?,?,?'

=item *

Accept bind variables in the constructor?

=item *

Add support for L<DBIx::Connector>?

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc DBIx::RoboQuery

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/DBIx-RoboQuery>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-RoboQuery>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/DBIx-RoboQuery>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/DBIx-RoboQuery>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=DBIx-RoboQuery>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=DBIx::RoboQuery>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dbix-roboquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-RoboQuery>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/DBIx-RoboQuery>

  git clone https://github.com/rwstauner/DBIx-RoboQuery.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
