package DBomb::Base::Defs;

=head1 NAME

DBomb::Base::Defs - Table definition routines.

=head1 SYNOPSIS

  package Customer;
  use base qw(DBomb::Base);

  Customer->def_data_source  ('my_db', 'Customer');
  Customer->def_accessor     ('cust_id', { column => 'id', auto_increment => 1 });
  Customer->def_column       ('id',      { accessor => 'id', auto_increment => 1 }); # Same thing!
  Customer->def_accessor     ('name'};
  Customer->def_accessor     ('address');
  Customer->def_accessor     ('affiliate_id');
  Customer->def_accessor     ('database_time', { expr => 'now()'} );


  ## Explicit key creation
  Customer->def_primary_key  ([qw(id cust_loc)]);
  Customer->def_key          ([qw(name affiliate_id)]);

  ## Relationship based on primary key
  Customer->def_has_a        ('affiliate', 'Affiliate', +{})
  Customer->def_has_many     ('orders', 'Order',+{})

  ## Relationship explicitly defined
  Customer->def_has_a        ('affiliate', [qw(name aff_id)], 'Affiliate_table', [qw(c_name id)]);
  Customer->def_has_many     ('orders', 'Order', ['cust_id'], ['id'],+{});

  ## Relationship based on a join
  Employee->def_has_many     ('supervisors', 'Supervisor',
                                            new DBomb::Query->select('super_id')
                                            ->from('emp_super')
                                            ->join('employee')
                                            ->using('emp_id')
                                            ->where(+{emp_id => '?'}), sub { shift->emp_id });


  ## select multiple columns at once for speed
  Customer->def_select_group ([qw(name address)]);

  ## name the select_group so you can refer to it later
  Customer->def_select_group ('reports' => [qw(name affiliate)]);

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.11 $';

use Carp qw(carp croak);
use Carp::Assert;
use DBomb::Generator qw(gen_accessor);
use DBomb::Meta::TableInfo;
use DBomb::Meta::ColumnInfo;
use DBomb::Meta::HasA;
use DBomb::Meta::HasMany;
use DBomb::Meta::HasQuery;
use DBomb::Meta::OneToMany;

##
## Public API subroutines
##

sub  def_data_source  {  _dbo_def_data_source(@_)  }
sub  def_accessor     {  _dbo_def_accessor(@_)     }
sub  def_column       {  _dbo_def_column(@_)     }
sub  def_primary_key  {  _dbo_def_primary_key(@_)  }
sub  def_key          {  _dbo_def_key(@_)  }
sub  def_has_a        {  my @args = @_; DBomb->do_after_resolve(\&_dbo_def_has_a,\@args,[caller(0)]) }
sub  def_has_many     {  my @args = @_; DBomb->do_after_resolve(\&_dbo_def_has_many,\@args,[caller(0)]) }
sub  def_select_group {  _dbo_def_select_group(@_) }

##
## Private subroutines
##

sub _dbo_def_data_source
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my ($database,$table) = @_;

# TODO: $database not used
    assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');

    my $tinfo = $class->_dbo_table_info(DBomb->tables->{$table} = DBomb::Meta::TableInfo->factory_new($table, $class));
}

sub _dbo_def_accessor
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my ($accessor, $opts) = (@_);
    my $tinfo = $class->_dbo_table_info;

    assert(defined($tinfo), 'def_accessor requires dbo_def_data_source');
    assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');
    assert((defined($accessor) && !ref($accessor)),'valid accessor name');

    $opts ||= +{};
    $opts->{'accessor'} = $accessor;
    $opts->{'column'} = $accessor unless exists $opts->{'column'};
    $opts->{'column'} = $opts->{'expr'} if exists $opts->{'expr'};

    my $cinfo = new DBomb::Meta::ColumnInfo($tinfo, $opts->{'column'}, $opts);

    ## create the accessor
    {
        no strict qw(refs);
        *{ $class .'::'. $cinfo->accessor } = sub{ shift->_dbo_column_accessor($cinfo,@_) };
    }
}

## Define a column.
sub _dbo_def_column
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my ($column_name, $opts) = (@_);
    my $tinfo = $class->_dbo_table_info;

        assert(defined($tinfo), 'def_column requires dbo_def_data_source');
        assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');
        assert((defined($column_name) && !ref($column_name)),'valid column name');

    $opts ||= +{};
    $opts->{'column'} = $column_name;
    $opts->{'accessor'} ||= $column_name;
    $class->_dbo_def_accessor( $opts->{'accessor'}, $opts);
}

sub _dbo_def_key
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my ($columns_list, $opts) = @_;
    my $tinfo = $class->_dbo_table_info;

    assert(defined($tinfo), 'def_key requires a data_source');
    assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');

    ## replace  col names with colinfo objs.
    $columns_list = [$columns_list] unless ref $columns_list;
    $columns_list = [map { assert((exists $tinfo->columns->{$_}),
                        "column $_ must be defined before it can be used in a key");
                        $tinfo->columns->{$_} } @$columns_list];

    ## create the key
    my $key = new DBomb::Meta::Key($columns_list, $opts);

    return $key;
}

sub _dbo_def_primary_key {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $pk = $class->_dbo_def_key(@_);

    ## register it with the table
    $pk->table_info->primary_key($pk);
    return $pk;
}

## __dbo_def_has_a ('affiliate', [qw(name aff_id)], 'Affiliate_table', [qw(c_name id)]);
## _dbo_def_has_a ($accessor, $many_key, $table, $one_key, $opts)
sub _dbo_def_has_a
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $accessor = shift;
    my ($f_table, $opts, $one_to_many);
    my $tinfo = $class->_dbo_table_info;

        assert(defined($tinfo), 'dbo_def_has_a requires dbo_def_table');
        assert(defined($accessor), 'dbo_def_has_a requires an accessor name');
        assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');

    ## Pop the opts if they exist
    $opts = pop if UNIVERSAL::isa($_[$#$_],'HASH');
    $opts ||= {};

    ## If there is only one arg left, assume it is the foreign table.
    if (@_ == 1){
        $f_table = DBomb->resolve_table_name(undef,shift);
        assert(UNIVERSAL::isa($f_table,'DBomb::Meta::TableInfo'), 'foreign table name failed to resolve');
        $one_to_many = $f_table->guess_one_to_many($tinfo);
        die "Failed to guess one to many relationship from table @{[$f_table->name]} to @{[$tinfo->name]}."
           ." Try using explicit key lists." unless defined $one_to_many;
    }
    else{
        ## It's a full argument list.
        my ($many_key, $one_key);
        ($many_key, $f_table, $one_key) = @_;
        $f_table = DBomb->resolve_table_name(undef,$f_table);
        assert(UNIVERSAL::isa($f_table,'DBomb::Meta::TableInfo'), 'foreign table name failed to resolve');

            assert(defined($many_key), 'dbo_def_has_a requires a many_key');
            assert(defined($f_table), 'dbo_def_has_a requires a foreign table');
            assert(defined($one_key), 'dbo_def_has_a requires a one_key');

        ## Promote scalars to arrays
        $one_key  = [$one_key]  if defined($one_key)  && not ref $one_key;
        $many_key = [$many_key] if defined($many_key) && not ref $many_key;

        if (UNIVERSAL::isa($many_key,'ARRAY')){
            for (@$many_key){ assert(exists($tinfo->columns->{$_}));}
            ## Find a matching key.
            my $new_key = $tinfo->find_key($many_key) or die "key '@{[$tinfo->name]}(@{[join q/, /,@$many_key]})' not found. Did you forget to define a key in package @{[$tinfo->class]}?";
            $many_key = $new_key;
        }

        $one_key = $f_table->primary_key unless defined $one_key;

        if (UNIVERSAL::isa($one_key,'ARRAY')){
            for (@$one_key){ assert(exists($f_table->columns->{$_}));}
            ## Find a matching key.
            my $new_key = $f_table->find_key($one_key) or die "key '@{[$f_table->name]}(@{[join q/, /,@$one_key]})' not found. Did you forget to define a key in package @{[$f_table->class]}?";
            $one_key = $new_key;
        }


        ## Find or create the OneToMany object
        ## TODO: lookup one_to_manys
        $one_to_many = new DBomb::Meta::OneToMany($one_key,$many_key);
    }

    my $has_a = new DBomb::Meta::HasA($one_to_many, $opts);

    ## create the accessor for the has_a object
    {
        no strict qw(refs);
        *{ $class .'::'. $accessor } = sub{ shift->_dbo_has_a_accessor($has_a,@_) };
    }

    ## Replace the accessor for each column in the has_a columns with an enhanced accessor.
    for my $cinfo (@{$has_a->one_to_many->many_key->columns_list}){
        no strict qw(refs);
        no warnings 'redefine';
        *{ $class .'::'. $cinfo->accessor } = sub { shift->_dbo_has_a_column_accessor($cinfo,@_) };
    }

    return $has_a;
}

## _dbo_def_has_many ( $accessor, $table, [$one_columns], [$many_columns], $opts );
## _dbo_def_has_many ( $accessor, $table, $opts );
## _dbo_def_has_many ( $accessor, $table, $query, $bind_routine, $opts )
sub _dbo_def_has_many
{
    my $class = ref($_[0]) ? ref(shift) : shift;

    return $class->_dbo_def_has_query(@_) if UNIVERSAL::isa($_[2],'DBomb::Query');

    my $accessor = shift;
    my $f_table  = shift;
    my ($opts, $one_to_many);
    my $tinfo = $class->_dbo_table_info;

        assert(defined($tinfo), 'dbo_def_has_many requires dbo_def_table');
        assert(defined($accessor) && (not ref $accessor), 'dbo_def_has_many requires an accessor name');
        assert(defined($f_table), 'dbo_def_has_many requires a foreign table name or info');
        assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');

    $f_table = DBomb->resolve_table_name(undef, $f_table);
    assert(UNIVERSAL::isa($f_table,'DBomb::Meta::TableInfo'), "foreign table name '$f_table' failed to resolve");

    ## Pop the opts if they exist
    $opts = pop if UNIVERSAL::isa($_[$#$_],'HASH');
    $opts ||= {};

    ## If there are no args left, guess the key.
    if (@_ == 0){
        $one_to_many = $tinfo->guess_one_to_many($f_table);
        die "Failed to guess one to many relationship from table @{[$tinfo->name]} to @{[$f_table->name]}."
           ." Try using explicit key lists." unless defined $one_to_many;
    }
    else{
        assert(@_ == 2, "number of arguments to def_has_many");
        my ($one_key, $many_key) = @_;

            assert(defined($one_key), 'dbo_def_has_many requires a one_key');
            assert(defined($many_key), 'dbo_def_has_many requires a many_key');

        ## Promote scalars to arrays
        $one_key  = [$one_key]  if defined($one_key)  && not ref $one_key;
        $many_key = [$many_key] if defined($many_key) && not ref $many_key;

        if (UNIVERSAL::isa($many_key,'ARRAY')){
            for (@$many_key){ assert(exists($f_table->columns->{$_}), "column $_ must exist");}
            ## Find a matching key.
            my $new_key = $f_table->find_key($many_key) or die "key '@{[$f_table->name]}(@{[join q/, /,@$many_key]})' not found. Did you forget to define a key in package @{[$f_table->class]}?";
            $many_key = $new_key;
        }

        if (UNIVERSAL::isa($one_key,'ARRAY')){
            for (@$one_key){ assert(exists($tinfo->columns->{$_}), "column $_ must exist");}
            ## Find a matching key.
            my $new_key = $tinfo->find_key($one_key) or die "key '@{[$tinfo->name]}(@{[join q/, /,@$one_key]})' not found. Did you forget to define a key in package @{[$tinfo->class]}?";
            $one_key = $new_key;
        }

        ## Find or create the OneToMany object
        ## TODO: lookup one_to_manys
        $one_to_many = new DBomb::Meta::OneToMany($one_key,$many_key);
    }

    my $has_many = new DBomb::Meta::HasMany($one_to_many, $opts);

    ## create the accessor for the has_many object
    {
        no strict qw(refs);
        *{ $class .'::'. $accessor } = sub{ shift->_dbo_has_many_accessor($has_many, @_) };
    }

    return $has_many;
}

## _dbo_def_has_query ( $accessor, $f_table, $query, sub{return $bind_value},..., $opts )
sub _dbo_def_has_query
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $accessor = shift;
    my $f_table    = shift;
    my $query    = shift;
    my $opts;

    my $tinfo = $class->_dbo_table_info;
    $opts = pop if UNIVERSAL::isa($_[$#$_],'HASH');
    $opts ||= {};
    my @bind_subs = @_;

        assert(defined($tinfo), 'dbo_def_has_many requires dbo_def_table');
        assert(defined($accessor) && (not ref $accessor), 'dbo_def_has_many requires an accessor name');
        assert(UNIVERSAL::isa($class,'DBomb::Base'), 'inherited from DBomb::Base');
        for (@bind_subs){
            assert(UNIVERSAL::isa($_,'CODE'), 'bind value subroutine(s) must be code refs');
        }

    my $has_query = new DBomb::Meta::HasQuery($tinfo, $f_table, $query, [@bind_subs], $opts);

    $has_query->resolve;
    assert(UNIVERSAL::isa($has_query->f_table,'DBomb::Meta::TableInfo'), "f_table name '$f_table' failed to resolve");

    ## Register with table_info
    push @{$tinfo->has_queries}, $has_query;

    ## create the accessor for the has_many object
    {
        no strict qw(refs);
        *{ $class .'::'. $accessor } = sub{ shift->_dbo_has_query_accessor($has_query, @_) };
    }

    return $has_query;
}

## convert column_names to column_info
## _dbo_promote_columns ([ $column,.. ])
sub _dbo_promote_columns
{
    my ($class, $columns_list) = @_;
        assert(UNIVERSAL::isa($class,__PACKAGE__));
        assert(UNIVERSAL::isa($columns_list,'ARRAY'));
    my $a = [];
    for my $c (@$columns_list) {
        unless (UNIVERSAL::isa($c,'DBomb::Meta::ColumnInfo')){
            $c = $class->_dbo_table_info->columns->{$c};
            assert(defined($c), "column '$c' must exist in table @{[$class->_dbo_table_info->name]}");
        }
        push @$a, $c;
    }
    $a
}


## _dbo_def_select_group ([ $cols ])
## _dbo_def_select_group ( $group => [ $cols...] )
sub _dbo_def_select_group
{
    my $class = shift;
    my $columns_list = pop;
    my $group;
    $group = shift if @_;

        assert(UNIVERSAL::isa($class,__PACKAGE__));
        assert(@_ == 0, 'paramter count to def_select_group');
        assert((not defined $group)||(not ref $group), 'group name must be a string');
        assert(UNIVERSAL::isa($columns_list,'ARRAY'), 'expected a listref of columns');

    $columns_list = $class->_dbo_promote_columns($columns_list);
    $class->_dbo_table_info->add_select_group($group, $columns_list);
}

1;
__END__

=head1 CLASS METHODS

=over

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

=back

