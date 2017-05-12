
package Class::DBI::Lite;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';
use Carp qw( cluck confess );
use SQL::Abstract;
use SQL::Abstract::Limit;
use Class::DBI::Lite::Iterator;
use Class::DBI::Lite::Pager;
use Class::DBI::Lite::RootMeta;
use Class::DBI::Lite::EntityMeta;
use Digest::MD5 'md5_hex';
use POSIX 'ceil';
use overload 
  '""'      => sub { eval { $_[0]->id } },
  bool      => sub { eval { $_[0]->id } },
  fallback  => 1;

our $VERSION = '1.034';
our $meta;

our %DBI_OPTIONS = (
  FetchHashKeyName    => 'NAME_lc',
  ShowErrorStatement  => 1,
  ChopBlanks          => 1,
  AutoCommit          => 1,
  RaiseError          => 1,
);

BEGIN {
  use vars qw( $Weaken_Is_Available %Live_Objects );

  $Weaken_Is_Available = 1;
  eval {
	  require Scalar::Util;
	  import Scalar::Util qw(weaken isweak);
  };
  $Weaken_Is_Available = 0 if $@;
}# end BEGIN:


#==============================================================================
# Abstract methods:
sub set_up_table;
sub get_last_insert_id;


#==============================================================================
sub import
{
  my $class = shift;

  no strict 'refs';
  $class->_load_class( ( @{$class.'::ISA'} )[0] );
  if( my $table = eval { ( @{$class.'::ISA'} )[0]->table } )
  {
    $class->set_up_table( $table );
  }# end if()
}# end import()


#==============================================================================
sub clear_object_index
{
  my $s = shift;
  
  my $class = ref($s) ? ref($s) : $s;
  my $key_starter = $s->root_meta->schema . ":" . $class;
  map { delete($Live_Objects{$_}) } grep { m/^$key_starter\:\d+/o } keys(%Live_Objects);
}# end clear_object_index()


#==============================================================================
sub find_column
{
  my ($class, $name) = @_;
  
  my ($col) = grep { $_ eq $name } $class->columns('All')
    or return;
  return $col;
}# end find_column()


#==============================================================================
sub construct
{
  my ($s, $data, $is_void_context) = @_;
  
  my $class = ref($s) ? ref($s) : $s;

  my $PK = $class->primary_column;
  my $key = join ':', grep { defined($_) } ( $s->root_meta->schema, $class, $data->{ $PK } );
  return $Live_Objects{$key} if $Live_Objects{$key};
  
  $data->{__id} = $data->{ $PK };
  $data->{__Changed} = { };
  
  my $obj = bless $data, $class;
  if( $Weaken_Is_Available && ! $is_void_context )
  {
    $Live_Objects{$key} = $obj;
    
    weaken( $Live_Objects{$key} );
    return $Live_Objects{$key};
  }
  else
  {
    return $obj;
  }# end if()
}# end construct()


#==============================================================================
sub deconstruct
{
  my $s = shift;
  
  bless $s, 'Class::DBI::Lite::Object::Has::Been::Deleted';
}# end deconstruct()


#==============================================================================
sub schema { $_[0]->root_meta->schema }
sub dsn    { $_[0]->root_meta->dsn }
sub table  { $_[0]->_meta->{table} }
sub triggers { @{ $_[0]->_meta->{triggers}->{ $_[1] } } }
sub _meta { }
sub set_cache { my ($class, $cache) = @_; $class->_meta->{cache} = $cache }
sub cache { shift->_meta->{cache} }


#==============================================================================
sub _init_meta
{
  my ($class, $entity) = @_;
  
  no strict 'refs';
  no warnings qw( once redefine );
  my $schema = $class->root_meta->schema;
  
  my $_class_meta = Class::DBI::Lite::EntityMeta->new( $class, $schema, $entity );
  
  # If we are re-initializing meta (i.e. changed schema) then remove accessors first:
  foreach my $col ( eval { $class->columns } )
  {
    local $SIG{__WARN__} = sub { };
    *{"$class\::$col"} = undef;
  }# end foreach()
  
  *{"$class\::_meta"} = sub { $_class_meta };
  
  my $pk = ($class->columns('Primary'))[0];
  *{"$class\::primary_column"} = sub { $pk };
  *{"$class\::$pk"} = sub { $_[0]->{$pk} };
  
  # Install the column accessors:
  foreach my $col ( grep { $_ ne $pk } $class->columns )
  {
    my $setter = "_set_$col";
    my $getter = "_get_$col";
    *{"$class\::$setter"} = sub {
      my ($s, $newval) = @_;
        no warnings 'uninitialized';
        return $newval if $newval eq $s->{$col};
        $s->_call_triggers( "before_set_$col", $s->{$col}, $newval );
        $s->{__Changed}->{$col} = {
          oldval => $s->{$col}
        };
        return $s->{$col} = $newval;
    };
    
    *{"$class\::$getter"} = sub {
      shift->{$col};
    };
    
    *{"$class\::$col"} = sub {
      my $s = shift;
      
      exists($s->{$col}) or $s->_flesh_out;
      @_ ? $s->$setter( @_ ) : $s->$getter( @_ );
    };
  }# end foreach()
}# end _init_meta()


#==============================================================================
sub connection
{
  my ($class, @DSN) = @_;
  
  return $class->db_Main unless @DSN;
  
  $class->set_master( @DSN );
  1;
}# end connection()


sub db_RO
{
  my $s = shift;
  
  # If we're inside a transaction or don't have any slaves, return the master:
  unless( $s->db_Main->{AutoCommit} && $s->root_meta->has_slaves )
  {
    return $s->db_Main;
  }# end unless()
  
  # Otherwise return the slave if we have any:
  $s->root_meta->has_slaves ? $s->db_Slave : $s->db_Main;
}# end db_RO()


sub set_master
{
  my ($class, @DSN) = @_;
  my $root = $class->root_meta;
  
  $class->_mk_connection('Main', @DSN);
}# end set_master()


sub set_slaves
{
  my ($class, @connections) = @_;
  
  my $root = $class->root_meta;
  $root->add_slave( $_ ) for grep { $_ } @connections;
  
  # Select a connection at random and use it:
  my $conn = $connections[ int(rand() * @connections) - 1 ];
  $class->_mk_connection('Slave', @$conn);
}# end set_slaves()


sub switch_slave
{
  my ($class, $trace) = @_;
  
  my $old_slave = $class->root_meta->slaves->[0];
  $class->_mk_connection('Slave', @{ $class->root_meta->random_slave } );
  my $new_slave = $class->root_meta->slaves->[0];
  
  warn "[Debug] Switched slave from $old_slave->[0] to $new_slave->[0]\n"
    if $trace;
}# end switch_slave()

our $root_metas = { };
sub _mk_connection
{
  my ($class, $name, @DSN) = @_;
  
  # Set up the root meta:
  no strict 'refs';
  no warnings 'redefine';
#  unless( $class->_has_root_meta )
  my $meta_key = join ':', ( $class );
  unless( $root_metas->{ $meta_key } )
  {
    $root_metas->{$meta_key} = Class::DBI::Lite::RootMeta->new(
      \@DSN
    );
    my $caller = caller(2);
    *{ "$caller\::root" } = sub { $caller };
    *{ $class->root . "::root_meta" } = sub {
    #  use Data::Dumper; warn Dumper($root_metas); 
      return $root_metas->{$meta_key};
    };
#    ${ $class->root . "::_has_root_meta" } = 1;
  }# end unless()
  
  # Connect:
  undef(%Live_Objects);
  local $^W = 0;
  $class->set_db($name => @DSN, {
		RaiseError => 1,
		AutoCommit => 1,
		PrintError => 0,
		Taint      => 1,
#		RootClass  => "DBIx::ContextualFetch"
  });
}# end _mk_connection()


#==============================================================================
sub root
{
  __PACKAGE__;
}# end root()


#==============================================================================
sub root_meta
{
  my $s = shift;
  
  no strict 'refs';
  my $root = $s->root;

  ${"$root\::root_meta"};
}# end root_meta()

sub _has_root_meta { no strict 'refs'; my $root = $_[0]->root; ${"$root\::_has_root_meta"} }


#==============================================================================
sub id
{
  $_[0]->{ $_[0]->primary_column };
}# end id()


#==============================================================================
my %ok_types = (
  All       => 1,
  Essential => 1,
  Primary   => 1,
);
sub columns
{
  my ($s) = shift;
  
  
  if( my $type = shift(@_) )
  {
    confess "Unknown column group '$type'" unless $ok_types{$type};
    if( my @cols = @_ )
    {
      $s->_meta->columns->{$type} = \@cols;
    }
    else
    {
      # Get: my ($PK) = $class->columns('Primary');
      return @{ $s->_meta->columns->{$type} };
    }# end if()
  }
  else
  {
    return @{ $s->_meta->columns->{All} };
  }# end if()

}# end columns()


#==============================================================================
sub retrieve_all
{
  my ($s) = @_;
  
  return $s->retrieve_from_sql(  );
}# end retrieve_all()


#==============================================================================
sub retrieve
{
  my ($s, $id) = @_;
  
  if( my $data = $s->_call_triggers( before_retrieve => $id ) )
  {
    return $s->construct( $data );
  }# end if()
  
  my ($obj) = $s->retrieve_from_sql(<<"", $id);
    @{[ $s->primary_column ]} = ?

  return unless $obj;
  $obj->_call_triggers( after_retrieve => $obj );
  return $obj;
}# end retrieve()


#==============================================================================
sub create
{
  my $s = shift;
  
  my $data = ref($_[0]) ? $_[0] : { @_ };
  
  my $PK = $s->primary_column;
  my %create_fields = map { $_ => $data->{$_} }
                        grep { exists($data->{$_}) && $_ ne $PK }
                          $s->columns('All');
  
  my $pre_obj = bless {
    __id => undef,
    __Changed => { },
    %create_fields
  }, ref($s) ? ref($s) : $s;
  
  # Cal the "before" trigger:
  $pre_obj->_call_triggers( before_create => \%create_fields );
  
  # Changes may have happened to the original creation data (from the trigger(s)) - re-evaluate now:
  %create_fields =  map { $_ => $pre_obj->{$_} }
                      grep { defined($pre_obj->{$_}) && $_ ne $PK }
                        $pre_obj->columns('All');
  $data = { %$pre_obj  };
  
  my @fields  = map { $_ } sort grep { exists($data->{$_}) } keys(%create_fields);
  my @vals    = map { $data->{$_} } sort grep { exists($pre_obj->{$_}) } keys(%create_fields);
  
  my $sql = <<"";
    INSERT INTO @{[ $s->table ]} (
      @{[ join ',', @fields ]}
    )
    VALUES (
      @{[ join ',', map {"?"} @vals ]}
    )

  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: create($sql, values[" . join( ",", map {qq('$_')} @vals) . "])";
  }# end if()
  
  my $sth = $s->db_Main->prepare_cached( $sql );
  $sth->execute( @vals );
  my $id = $s->get_last_insert_id
    or confess "ERROR - CANNOT get last insert id";
  $sth->finish();
  
  my $new_obj = $s->construct( {
    %$pre_obj,
    $PK => $id,
  }, defined wantarray );
  $pre_obj->discard_changes;

  $new_obj->_call_triggers( after_create => $new_obj );
  $new_obj->update if $new_obj->{__Changed};
  $new_obj;
}# end create()


#==============================================================================
sub do_transaction
{
  my ($s, $code) = @_;
  
  local $s->db_Main->{AutoCommit};
  my ($res, @res);
  wantarray ? @res = eval { $code->( ) } : $res = eval { $code->( ) };
  
  if( my $trans_error = $@ )
  {
    eval { $s->dbi_rollback };
    if( my $rollback_error = $@ )
    {
      confess join "\n\t",  "Both transaction and rollback failed:",
                            "Transaction error: $trans_error",
                            "Rollback Error: $rollback_error";
    }
    else
    {
      confess join "\n\t",  "Transaction failed but rollback succeeded:",
                            "Transaction error: $trans_error";
    }# end if()
  }
  else
  {
    # Success:
    $s->dbi_commit;
    wantarray ? return @res : return $res;
  }# end if()
}# end do_transaction()


#==============================================================================
sub update
{
  my $s = shift;
  confess "$s\->update cannot be called without an object" unless ref($s);
  
  return 1 unless eval { keys(%{ $s->{__Changed} }) };
  
  $s->_call_triggers( before_update => $s );
  
  my $changed = $s->{__Changed};
  foreach my $field ( grep { $changed->{$_} } sort keys(%$s) )
  {
    $s->_call_triggers( "before_update_$field", $changed->{$field}->{oldval}, $s->{$field} );
  }# end foreach()
  
  
  # Make our SQL:
  my @fields  = map { "$_ = ?" } grep { $changed->{$_} } sort keys(%$s);
  my @vals    = map { $s->{$_} } grep { $changed->{$_} } sort keys(%$s);
  my $sql = <<"";
    UPDATE @{[ $s->table ]} SET
      @{[ join ', ', @fields ]}
    WHERE @{[ $s->primary_column ]} = ?

  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: update($sql, values[" . join( ",", map {qq('$_')} @vals) . "])";
  }# end if()
  my $sth = $s->db_Main->prepare_cached( $sql );
  $sth->execute( @vals, $s->id );
  $sth->finish();
  
  foreach my $field ( grep { $changed->{$_} } sort keys(%$s) )
  {
    my $old_val = $changed->{$field}->{oldval};
    $s->_call_triggers( "after_update_$field", $old_val, $s->{$field} );
  }# end foreach()
  
  $s->{__Changed} = undef;
  $s->_call_triggers( after_update => $s );
  return 1;
}# end update()


#==============================================================================
sub delete
{
  my $s = shift;
  
  confess "$s\->delete cannot be called without an object" unless ref($s);
  
  $s->_call_triggers( before_delete => $s );
  
  my $sql = <<"";
    DELETE FROM @{[ $s->table ]}
    WHERE @{[ $s->primary_column ]} = ?

  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: delete($sql, values[" . $s->id . "])\n";
  }# end if()
  my $sth = $s->db_Main->prepare_cached( $sql );
  $sth->execute( $s->id );
  $sth->finish();
  
  my $deleted = bless { $s->primary_column => $s->id }, ref($s);
  my $key = join ':', grep { defined($_) } ($s->root_meta->{schema}, ref($s), $s->id );
  $s->_call_triggers( after_delete => $deleted );
  delete($Live_Objects{$key});
  undef(%$deleted);
  
  undef(%$s);

  $s->deconstruct;
}# end delete()


#==============================================================================
sub ad_hoc
{
  my ($s, %args) = @_;
  
  my $sth = $s->db_RO->prepare( $args{sql} );
  $args{args} ||= [ ];
  $args{isa}  ||= 'Class::DBI::Lite';
  $sth->execute( @{ $args{args} } );
  my @data = ( );
  require Class::DBI::Lite::AdHocEntity;
  while( my $rec = $sth->fetchrow_hashref )
  {
    push @data, Class::DBI::Lite::AdHocEntity->new(
      isa         => $args{isa},
      sql         => \$args{sql},
      args        => $args{args},
      primary_key => $args{primary_key},
      data        => $rec,
    );
  }# end while()
  $sth->finish();
  
  return wantarray ? @data : Class::DBI::Lite::Iterator->new( \@data );
}# end ad_hoc()


#==============================================================================
sub retrieve_from_sql
{
  my ($s, $sql, @bind) = @_;
  
  $sql = "SELECT @{[ join ', ', $s->columns('Essential') ]} " . 
         "FROM @{[ $s->table ]}" . ( $sql ? " WHERE $sql " : "" );

  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: search*($sql, values[" . join( ",", map {qq('$_')} @bind) . "])";
  }# end if()
  SCOPE: {
    my $sth = $s->db_RO->prepare_cached( $sql );
    $sth->execute( @bind );
    
    return $s->sth_to_objects( $sth, $sql );
  }
}# end retrieve_from_sql()


#==============================================================================
sub sth_to_objects
{
  my ($s, $sth, $sql) = @_;
  
  my $class = ref($s) ? ref($s) : $s;
  my @vals;
  while( my $rec = $sth->fetchrow_hashref )
  {
    push @vals, $rec;
  }# end while()
  $sth->finish();
  
  return $s->_prepare_result( @ vals );
}# end sth_to_objects()


#==============================================================================
sub search
{
  my ($s, %args) = @_;

  my @cached = grep { $_ } $s->_call_triggers( before_search => \%args );
  if( @cached )
  {
    return $s->_prepare_result( @cached );
  }# end if()
  
  my $sql = "";
  my @sql_parts = map { "$_ = ?" } sort keys(%args);
  my @sql_vals  = map { $args{$_} } sort keys(%args);
  $sql .= join ' AND ', @sql_parts;

  my @vals = $s->retrieve_from_sql( $sql, @sql_vals );
  $s->_call_triggers( after_search => ( \%args, \@vals ) );
  return $s->_prepare_result( @vals );
}# end search()


sub _prepare_result
{
  my ($class, @vals) = @_;
  if( wantarray )
  {
    my @out = map { $class->construct( $_ ) } @vals;
    return @out;
  }
  else
  {
    my $iter = Class::DBI::Lite::Iterator->new(
      [
        map { $class->construct( $_ ) } @vals
      ]
    );
    return $iter;
  }# end if()
}# end _prepare_result()


#==============================================================================
sub count_search
{
  my ($s, %args) = @_;
  
  my $sql = "SELECT COUNT(*) FROM @{[ $s->table ]} WHERE ";

  my @sql_parts = map { "$_ = ?" } sort keys(%args);
  my @sql_vals  = map { $args{$_} } sort keys(%args);
  $sql .= join ' AND ', @sql_parts;
  
  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: count_search($sql, values[" . join( ",", map {qq('$_')} @sql_vals) . "])";
  }# end if()
  SCOPE: {
    my $sth = $s->db_RO->prepare_cached( $sql );
    $sth->execute( @sql_vals );
    my ($count) = $sth->fetchrow;
    $sth->finish();
    
    return $count;
  };
}# end count_search()


#==============================================================================
sub search_like
{
  my ($s, %args) = @_;
  
  my $sql = "";

  my @sql_parts = map { "$_ LIKE ?" } sort keys(%args);
  my @sql_vals  = map { $args{$_} } sort keys(%args);
  $sql .= join ' AND ', @sql_parts;
  
  return $s->retrieve_from_sql( $sql, @sql_vals );
}# end search_like()


#==============================================================================
sub count_search_like
{
  my ($s, %args) = @_;
  
  my $sql = "SELECT COUNT(*) FROM @{[ $s->table ]} WHERE ";

  my @sql_parts = map { "$_ LIKE ?" } sort keys(%args);
  my @sql_vals  = map { $args{$_} } sort keys(%args);
  $sql .= join ' AND ', @sql_parts;
  
  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: count_search_like($sql, values[" . join( ",", map {qq('$_')} @sql_vals) . "])";
  }# end if()
  SCOPE: {
    my $sth = $s->db_RO->prepare_cached( $sql );
    $sth->execute( @sql_vals );
    my ($count) = $sth->fetchrow;
    $sth->finish();
    
    return $count;
  };
}# end count_search_like()


#==============================================================================
sub search_where
{
  my $s = shift;
  
  my $where = (ref $_[0]) ? $_[0]          : { @_ };
  my $attr  = (ref $_[0]) ? $_[1]          : undef;
  my $order = ($attr)     ? delete($attr->{order_by}) : undef;
  my $limit  = ($attr)    ? delete($attr->{limit})    : undef;
  my $offset = ($attr)    ? delete($attr->{offset})   : undef;
  
  my $sql = SQL::Abstract::Limit->new(%$attr, limit_dialect => $s->db_Main );
  my($phrase, @bind) = $sql->where($where, $order, $limit, $offset);
  $phrase =~ s/^\s*WHERE\s*//i;
  
  return $s->retrieve_from_sql($phrase, @bind);
}# end search_where()


#==============================================================================
sub pager
{
  my ($s, $where, $attr) = @_;
  
  unless( $where && keys %$where )
  {
    $where = { 1 => 1 };
  }# end unless()

  foreach(qw( page_size page_number ))
  {
    confess "Required attribute '$_' was not provided"
      unless $attr->{$_};
  }# end foreach()
  
  # Limits:
  my $page_size = $attr->{page_size};
  my $page_number = $attr->{page_number};
  my $offset = $page_number == 1 ? 0 : ($page_number - 1) * $page_size;

  my $order = $attr ? $attr->{order_by} : undef;
  my $sql = SQL::Abstract::Limit->new(%$attr, limit_dialect => $s->db_Main );
  my($phrase, @bind) = $sql->where($where, $order);
  $phrase =~ s/^\s*WHERE\s*//i;
  
  my $total = $s->count_search_where( $where );
  my $total_pages = $total < $page_size ? 1 : POSIX::ceil($total / $page_size);
  
  return Class::DBI::Lite::Pager->new(
    where       => $where,
    order_by    => $order,
    class       => ref($s) ? ref($s) : $s,
    page_number => $page_number,
    page_size   => $page_size,
    total_pages => $total_pages,
    total_items => $total,
    start_item  => $offset + 1,
    stop_item   => $offset + $page_size,
  );
}# end pager()


#==============================================================================
sub sql_pager
{
  my ($s, $args, $attr) = @_;
  
  confess "\$args is required" unless $args;
  foreach( qw( data_sql count_sql ) )
  {
    confess "\$args->{$_} is required" unless $args->{$_};
  }# end foreach()
  $args->{sql_args} ||= [ ];

  foreach(qw( page_size page_number ))
  {
    confess "Required attribute '$_' was not provided"
      unless $attr->{$_};
  }# end foreach()
  
  # Limits:
  my $page_size = $attr->{page_size};
  my $page_number = $attr->{page_number};
  my $offset = $page_number == 1 ? 0 : ($page_number - 1) * $page_size;

  # Get the total items:
  my $sth = $s->db_RO->prepare( $args->{count_sql} );
  $sth->execute( @{ $args->{sql_args} } );
  my ($total) = $sth->fetchrow;
  $sth->finish;
  
  my $total_pages = $total < $page_size ? 1 : POSIX::ceil($total / $page_size);
  
  return Class::DBI::Lite::Pager->new(
    data_sql    => $args->{data_sql},
    count_sql   => $args->{count_sql},
    sql_args    => $args->{sql_args},
    class       => ref($s) ? ref($s) : $s,
    page_number => $page_number,
    page_size   => $page_size,
    total_pages => $total_pages,
    total_items => $total,
    start_item  => $offset + 1,
    stop_item   => $offset + $page_size,
  );
}# end sql_pager()


#==============================================================================
sub dataset
{
  my ($s) = shift;
  require Class::DBI::Lite::Dataset;
  Class::DBI::Lite::Dataset->new( @_ );
}# end dataset()


#==============================================================================
sub count_search_where
{
  my $s = shift;
  
  my $where = (ref $_[0]) ? $_[0] : { @_ };
  my $phrase = "";
  my @bind;
  if( keys( %$where ) == 1 && (keys %$where)[0] eq '1' && (values %$where)[0] eq '1' )
  {
    # No phrase:
  }
  else
  {
    my $abstract = SQL::Abstract::Limit->new();
    ( $phrase, @bind ) = $abstract->where($where);
  }# end if()
  
  my $sql = "SELECT COUNT(*) FROM @{[ $s->table ]} $phrase";
  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: count_search_where($sql, values[" . join( ",", map {qq('$_')} @bind) . "])";
  }# end if()
  SCOPE: {
    my $sth = $s->db_RO->prepare_cached($sql);
    $sth->execute( @bind );
    my ($count) = $sth->fetchrow;
    $sth->finish;
    
    return $count;
  };
}# end count_search_where()


#==============================================================================
sub find_or_create
{
  my ($s, %args) = @_;
  
  my $result = eval {
    $s->do_transaction(sub {
      
      if( my ($obj) = $s->search( %args ) )
      {
        return $obj;
      }# end if()
      
      my $obj = $s->create( %args );
      return $obj;
    });
  };
  if( $@ )
  {
    die $@;
  }# end if()
  
  return $result;
}# end find_or_create()


#==============================================================================
sub belongs_to
{
  my ($class, $method, $otherClass, $fk) = @_;
  
  $class->_load_class( $otherClass );

  $class->_meta->{belongs_to_rels}->{$method} = {
    class => $otherClass,
    fk    => $fk
  };
  
  no strict 'refs';
  *{"$class\::$method"} = sub {
    my $s = shift;
    
    $otherClass->retrieve( $s->$fk );
  };
}# end belongs_to()
*has_a = \&belongs_to;


#==============================================================================
sub has_many
{
  my ($class, $method, $otherClass, $fk) = @_;
  
  $class->_load_class( $otherClass );
  $class->_meta->{has_many_rels}->{$method} = {
    class => $otherClass,
    fk    => $fk,
  };
  
  no strict 'refs';
  *{"$class\::$method"} = sub {
    my ($s, $args, $attrs) = @_;
    $args = { } unless $args;
    $args->{ $fk } = $s->id;
    $attrs ||= { };
    $otherClass->search_where( $args, $attrs );
  };
  
  *{"$class\::add_to_$method"} = sub {
    my $s = shift;
    my %options = ref($_[0]) ? %{$_[0]} : @_;
    $otherClass->create(
      %options,
      $fk => $s->id,
    );
  };
}# end has_many()


#==============================================================================
sub has_one
{
  my ($class, $method, $otherClass, $fk) = @_;
  
  $class->_load_class( $otherClass );
  $class->_meta->{has_one_rels}->{$method} = {
    class => $otherClass,
    fk    => $fk,
  };
  
  no strict 'refs';
  *{"$class\::$method"} = sub {
    my $s = shift;
    my ($item) = $otherClass->search( $fk => $s->id )
      or return;
    return $item;
  };
  
  *{"$class\::set_$method"} = sub {
    my $s = shift;
    my %options = ref($_[0]) ? %{$_[0]} : @_;
    $otherClass->create(
      %options,
      $fk => $s->id,
    );
  };
}# end has_one()


#==============================================================================
sub add_trigger
{
  my ($s, $event, $handler) = @_;
  
  confess "add_trigger called but the handler is not a subref"
    unless ref($handler) eq 'CODE';
  
  $s->_meta->{triggers}->{$event} ||= [ ];
  my $handlers = $s->_meta->{triggers}->{$event};
  return if grep { $_ eq $handler } @$handlers;

  push @$handlers, $handler;
}# end add_trigger()


#==============================================================================
sub _call_triggers
{
  my ($s, $event) = @_;

  $s->_meta->{triggers}->{ $event } ||= [ ];
  return unless my @handlers = @{ $s->_meta->{triggers}->{ $event } };
  shift;shift;
  my @return_values;
  my $return_value;
  foreach my $handler ( @handlers )
  {
    if( wantarray )
    {
      eval {
        my @val = $handler->( $s, @_ );
        push @return_values, @val if @val;
        1;
      } or confess $@;
    }
    else
    {
      eval {
        $return_value = $handler->( $s, @_ );
        1;
      } or confess $@;
    }# end if()
  }# end foreach()
  
  return wantarray ? @return_values : $return_value;
}# end _call_triggers()


#==============================================================================
sub dbi_commit
{
  my $s = shift;
  return if $s->db_Main->{AutoCommit};
  $s->db_Main->commit( @_ );
}# end dbi_commit()


#==============================================================================
sub remove_from_object_index
{
  my $s = shift;
  my $obj = $Live_Objects{ $s->get_cache_key };
  delete($Live_Objects{ $s->get_cache_key });
  undef(%$obj);
}# end remove_from_object_index()


sub get_cache_key
{
  my $s = shift;
  if( my $id = shift )
  {
    my $class = ref($s) ? ref($s) : $s;
    return join ':', ( $s->root_meta->{schema}, $class, $id );
  }
  else
  {
    return $s->root_meta->{schema} . ':' . ref($s) . ':' . $s->id
  }# end if()
}# end get_cache_key()


sub as_hashref
{
  my $s = shift;
  my %data = %$s;
  delete( $data{__Changed} );
  delete( $data{__id} );
  \%data;
}# end as_hashref()


#==============================================================================
sub dbi_rollback
{
  my $s = shift;
  $s->db_Main->rollback( @_ );
}# end dbi_rollback()


#==============================================================================
sub discard_changes
{
  my $s = shift;
  
  map {
    $s->{$_} = $s->{__Changed}->{$_}->{oldval}
  } keys(%{$s->{__Changed}});
  
  $s->{__Changed} = { };
  
  1;
}# end discard_changes()


#==============================================================================
*_load_class = \&load_class;
sub load_class
{
  my (undef, $class) = @_;
  
  (my $file = "$class.pm") =~ s/::/\//g;
  unless( $INC{$file} )
  {
    eval {
      require $file;
      $class->import;
    };
  }# end unless();
}# end load_class()


#==============================================================================
sub trace
{
  my $s = shift;
  $s->_meta->trace( @_ );
}# end trace()


#==============================================================================
sub _flesh_out
{
  my $s = shift;
  
  my @missing_fields = grep { ! exists($s->{$_}) } $s->columns('All');
  my $sql = <<"";
    SELECT @{[ join ', ', @missing_fields ]}
    FROM @{[ $s->table ]}
    WHERE @{[ $s->primary_column ]} = ?

  my $sth = $s->db_RO->prepare($sql);

  if( $s->_meta->trace )
  {
    my $class = ref($s) || $s;
    cluck "$class: flesh_out($sql, values[" . $s->id . "])";
  }# end if()
  $sth->execute( $s->id );
  my $rec = $sth->fetchrow_hashref;
  $sth->finish();
  
  $s->{$_} = $rec->{$_} foreach @missing_fields;
  return 1;
}# end _flesh_out()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  if( $s->{__Changed} && keys(%{ $s->{__Changed} }) )
  {
    my $changed = join ', ', sort keys(%{ $s->{__Changed} });
    cluck ref($s) . " #$s->{__id} DESTROY'd without saving changes to $changed";
  }# end if()
  
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()

{
  # This is deleted-object-heaven:
  package
    Class::DBI::Lite::Object::Has::Been::Deleted;

  use overload 
    '""'      => sub { '' },
    bool      => sub { undef },
    fallback  => 1;
}


sub lock_table;
sub unlock_table;

1;# return true:


=pod

=head1 NAME

Class::DBI::Lite - Lightweight ORM for Perl

=head1 SYNOPSIS

Please take a look at L<Class::DBI::Lite::Tutorial> for an introduction to using this module.

=head1 DESCRIPTION

C<Class::DBI::Lite> offers a simple way to deal with databases in an object-oriented way.

One class (the B<Model> class) defines your connection to the database (eg: connectionstring, username and password)
and your other classes define interaction with one table each (your B<entity> classes).

The Entity classes subclass the Model class and automatically inherit its connection.

C<Class::DBI::Lite> relies heavily on L<Ima::DBI::Contextual>, L<SQL::Abstract> and L<Scalar::Util>.

C<Class::DBI::Lite> does not leak memory and is well-suited for use within mod_perl, Fast CGI, CGI
and anywhere else you might need it.

=head1 BACKGROUND

I used L<Class::DBI> for a few years, a few years ago, on a very large project, under mod_perl.
This was back in 2002-2003 when the ORM (Object-Relational Mapper) scene was still fairly new.

While it saved me a great deal of typing, I was amazed at the complexity of C<Class::DBI>'s internal code.
After some time I found myself spending more effort working around problems caused by C<Class::DBI>
than I could stand.

Many people encountered the same problems I encountered (transactions, database connection sharing issues, performance, etc)
and they all went and began writing L<DBIx::Class>.

L<DBIx::Class> went in a direction away from the database while I wanted to get closer to
the database.  As close as I could possibly get without wasting time.  I also wanted
to keep some simple logic in my Entity classes (those classes that represent individual tables).
I didn't want my ORM to do too much magic, think too much or do anything not immediately apparent.
I didn't care about many-to-many relationships or automatic SQL join clauses.  Vendor-specific
LIMIT expressions simply were not a concern of mine.

So...I reimplemented (most) of the C<Class::DBI> interface in a way that I preferred.  I left out some
things that didn't matter to me (eg: many-to-many relationships, column groups) and added some things
I needed frequently (eg: transactions, single-field triggers, mod_perl compatibility).

=head1 PHILOSOPHY

C<Class::DBI::Lite> is intended to minimize the boiler-plate code typically written
in most applications.  It is not intended to completely insulate developers from
interacting with the database directly.

C<Class::DBI::Lite> is not a way to avoid I<learning> SQL - it is a way to avoid I<writing>
boring, repetitive, "boiler-plate" SQL.

=head1 PUBLIC PROPERTIES

=head2 connection( $dsn, $username, $password )

Sets the DSN for your classes.

  package App::db::model;
  
  use base 'Class::DBI::Lite::mysql';
  
  __PACKAGE__->connection('DBI:mysql:dbname:localhost', 'username', 'password' );

=head2 db_Main

Returns the active database handle in use by the class.

Example:

  my $dbh = App::db::artist->db_Main;
  my $sth = $dbh->prepare("select * from artists");
  $sth->execute();
  ...

=head2 table

Returns the name of the table that the class is assigned to.

Example:

  print App::db::artist->table; # 'artists'

=head2 columns

Returns a list of field names in the table that the class represents.

Given the following table:

  create table artists (
    artist_id   integer unsigned not null primary key auto_increment,
    name        varchar(100) not null,
  ) engine=innodb charset=utf8;

We get this:

  print join ", ", App::db::artist->columns;
  # artist_id, name

=head2 trace( 1:0 )

(New in version 1.018)

Setting C<trace> to 1 or 0 will turn on or off SQL logging to STDERR.

Example:

  # Start seeing all the SQL:
  App::db::artist->trace( 1 );
  
  # We will see some SQL when the next line is executed:
  my @users = App::db::artist->search_like( name => 'Rob%' );
  
  # Turn it off again:
  App::db::artist->trace( 0 );

By default, C<trace> is turned off.

=head1 STATIC METHODS

=head2 create( %info )

Creates a new object and returns it.

Example:

  my $artist = App::db::artist->create( name => 'Bob Marley' );

=head2 find_or_create( %info )

Using C<%info> a search will be performed.  If a matching result is found it is returned.  Otherwise
a new record will be created using C<%info> as arguments.

Example:

  my $artist = App::db::artist->find_or_create( name => 'Bob Marley' );

=head2 retrieve( $id )

Given the id of a record in the database, returns that object.

Example:

  my $artist = App::db::artist->retrieve( 1 );

Same as the following SQL:

  SELECT *
  FROM artists
  WHERE artist_id = 1

=head2 retrieve_all( )

Returns all objects in the database table.

Example:

  my @artists = App::db::artist->retrieve_all;

Same as the following SQL:

  SELECT * FROM artists

B<NOTE:> If you want to sort all of the records or do paging, use C<search_where>
like this:

  my @artists = App::db::artist->search_where({ 1 => 1}, {order_by => 'name DESC'});

Same as the following SQL:

  SELECT *
  FROM artists
  WHERE 1 = 1
  ORDER BY name DESC

That "C<WHERE 1 = 1>" is a funny way of telling the database "give them all to me".

=head2 has_many( ... )

Declares a "one-to-many" relationship between this two classes.

  package App::db::artist;
  ...
  __PACKAGE__->has_many(
    albums  =>
      'App::db::album' =>
        'album_id'
  );

The syntax is:

  __PACKAGE__->has_many(
    $what_they_are_called =>
      $the_class_name =>
        $the_foreign_key_field_from_the_other_class
  );

The result is this:

  my @albums = $artist->albums;
  $artist->add_to_albums( name => 'Legend' );

That's the same as:

  my @albums = App::db::artist->search(
    artist_id => $artist->id
  );

=head2 belongs_to( ... )

Declares that instances "this" class exists only as a feature of instances of another class.

For example, "songs" exist as features of "albums" - not the other way around.

Example:

  package App::db::album;
  ...
  __PACKAGE__->belongs_to(
    artist  =>
      'App::db::artist' =>
        'artist_id'
  );

So that's:

  __PACKAGE__->belongs_to(
    $the_method_name =>
      $the_class_name =>
        $my_foreign_key_field
  );

=head2 construct( $hashref )

Blesses the object into the given class, even if we don't have all the information
about the object (as long as we get its primary field value).

Example:

  for( 1..5 ) {
    my $artist = App::db::artist->construct({ artist_id => $_ });
    
    # name is automatically "fleshed out":
    print $artist->name;
  }

=head2 eval { do_transaction( sub { ... } ) }

Executes a block of code within the context of a transaction.

Example:

  # Safely update the name of every album:
  eval {
    App::db::artist->do_transaction( sub {
    
      # Your transaction code goes here:
      my $artist = App::db::artist->retrieve( 1 );
      foreach my $album ( $artist->albums ) {
        $album->name( $artist->name . ': ' . $album->name );
        $album->update;
      }
    });
  };
  
  if( $@ ) {
    # There was an error:
    die $@;
  }
  else {
    # Everything was OK:
  }

=head2 search( %args )

Returns any objects that match all elements in C<%args>.

Example:

  my @artists = App::db::artist->search( name => 'Bob Marley' );
  
  my $artist_iterator = App::db::artist->search( name => 'Bob Marley' );

Returns an array in list context or a L<Class::DBI::Lite::Iterator> in scalar context.

=head2 search_like( %args )

Returns any objects that match all elements in C<%args> using the C<LIKE> operator.

Example:

  my @artists = App::db::artist->search_like( name => 'Bob%' );
  
  my $artist_iterator = App::db::artist->search_like( name => 'Bob%' );

Returns an array in list context or a L<Class::DBI::Lite::Iterator> in scalar context.

Both examples would execute the following SQL:

  SELECT * FROM artists WHERE name LIKE 'Bob%'

=head2 search_where( \%args, [\%sort_and_limit] )

Returns any objects that match all elements in C<%args> as specified by C<%sort_and_limit>.

Returns an array in list context or a L<Class::DBI::Lite::Iterator> in scalar context.

Example 1:

  my @artists = App::db::artist->search_where({
    name => 'Bob Marley'
  });

Same as this SQL:

  SELECT *
  FROM artists
  WHERE name = 'Bob Marley'

Example 2:

  my @artists = App::db::artist->search_where({
    name => 'Bob Marley'
  }, {
    order_by => 'name ASC LIMIT 0, 10'
  });

Same as this SQL:

  SELECT *
  FROM artists
  WHERE name = 'Bob Marley'
  ORDER BY name
  LIMIT 0, 10

Example 3:

  my @artists = App::db::artist->search_where([
    name => { '!=' => 'Bob Marley' },
    genre => 'Rock',
  ]);

Same as this SQL:

  SELECT *
  FROM artists
  WHERE name != 'Bob Marley'
  OR genre = 'Rock'

Because C<search_where> uses L<SQL::Abstract> to generate the SQL for the database,
you can look there for more detailed examples.

Specifying OrderBy, Limit and Offset separately:

  my @artists = App::db::artist->search_where({
    name => 'Bob Marley'
  }, {
    order_by  => 'name ASC',
    limit     => $how_many,
    offset    => $start_where,
  });

So if your C<$how_many> were 10, and your C<$start_where> were zero (C<0>) then that would be the same as:

  SELECT *
  FROM artists
  WHERE name = 'Bob Marley'
  ORDER BY name ASC
  LIMIT 0, 10

=head2 count_search( %args )

Returns the number of records that match C<%args>.

Example:

  my $count = App::db::album->count_search( name => 'Greatest Hits' );

=head2 count_search_like( %args )

Returns the number of records that match C<%args> using the C<LIKE> operator.

Example:

  my $count = App::db::artist->count_search_like(
    name  => 'Bob%'
  );

=head2 count_search_where( \%args )

Returns the number of records that match C<\%args>.

Examples:

  my $count = App::db::album->count_search_where({
    name  => { LIKE => 'Best Of%' }
  });
  
  my $count = App::db::album->count_search_where({
    genre => { '!=' => 'Country/Western' }
  });

As with C<search_where()>, the C<count_search_where()> class method uses L<SQL::Abstract>
to generate the SQL for the database.

=head2 sth_to_objects( $sth )

Takes a statement handle that is ready to fetch records from.  Returns the results
as objects.

Example:

  my $sth = App::db::artist->db_Main->prepare("SELECT * FROM artists");
  $sth->execute();
  my @artists = App::db::artist->sth_to_objects( $sth );

This method is very useful for when your SQL query is too complicated for C<search_where()>.

=head2 add_trigger( $event => \&sub )

Specifies a callback to be executed when a specific event happens.

Examples:

  package App::db::artist;
  ...
  __PACKAGE__->add_trigger( after_create => sub {
    my ($self) = @_;
    
    warn "You just created a new artist: " . $self->name;
  });

There are 6 main trigger points at the class level and 2 trigger points for
every field:

=head3 Class Triggers

=head4 before_create( $self )

Called just before a new record is created.  C<$self> is a hashref blessed into
the object's class and contains only the values that were provided for its creation.

So, given this trigger:

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( before_create => sub {
    my ($self) = @_;
    
    warn "ID = '$self->{album_id}', Name = '$self->{name}";
  });

If we ran this code:

  my $album = App::db::album->create( name => 'Legend' );

We would see this output:

  ID = '', Name = 'Legend'

Because the value for C<album_id> has not been assigned by the database it does
not yet have a value.

=head4 after_create( $self )

Called just after a new record is created.  C<$self> is the new object itself.

So given this trigger:

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( after_create => sub {
    my ($self) = @_;
    
    warn "ID = '$self->{album_id}', Name = '$self->{name}";
  });

If we ran this code:

  my $album = App::db::album->create( name => 'Legend' );

We would see this output:

  ID = '1', Name = 'Legend'

=head4 before_update( $self )

Called just before changes are saved to the database.  C<$self> is the object
to be updated.

Example:

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( before_update => sub {
    my ($self) = @_;
    
    warn "About to update album " . $self->name;
  });

=head4 after_update( $self )

Called just after changes are saved to the database.  C<$self> is the object
that was updated.

Example:

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( after_update => sub {
    my ($self) = @_;
    
    warn "Finished updating album " . $self->name;
  });

B<NOTE:> If you make changes to C<$self> from within an C<after_update> you could
enter into a recursive loop in which an update is made that causes an update to
be made which causes an update to be made which causes an update to be made which causes an update to be made which
causes an update to be made which causes an update to be made which causes an update to be made which
causes an update to be made which causes an update to be made which causes an update to be made which
causes an update to be made which causes an update to be made which causes an update to be made which
causes an update to be made which causes an update to be made which causes an update to be made which
causes an update to be made which causes an update to be made which causes an update to be made which...and so on.

B<DO NOT DO THIS>:

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( after_update => sub {
    my ($self) = @_;
    
    # This will cause problems:
    warn "Making a recursive problem:";
    $self->name( 'Hello ' . rand() );
    $self->update;
  });

=head4 before_delete( $self )

Called just before something is deleted.

Example:

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( before_delete => sub {
    my ($self) = @_;
    
    warn "About to delete " . $self->name;
  });

=head4 after_delete( {$primary_field => $id} )

Called just after something is deleted.

B<NOTE:> Since the object itself is deleted from the database B<and> memory, all
that is left is the id of the original object.

So, given this trigger...

  package App::db::album;
  ...
  use Data::Dumper;
  __PACKAGE__->add_trigger( after_delete => sub {
    my ($obj) = @_;
    
    warn "Deleted an album: " . Dumper($obj);
  });

...we might see the following output:

  Deleted an album: $VAR1 = {
    album_id => 123
  };

=head3 Field Triggers

=head4 before_update_<field>( $self, $old_value, $new_value )

Called just B<before> a field's value is updated.

So, given the following trigger...

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( before_update_name => sub {
    my ($self, $old_value, $new_value) = @_;
    
    warn "About to change name from '$old_value' to '$new_value'";
  });

...called with the following code...

  my $artist = App::db::artist->create( name => 'Bob Marley' );
  my $album = $artist->add_to_albums( name => 'Legend' );
  
  # Now change the name:
  $album->name( 'Greatest Hits' );
  $album->update; # <--- the trigger is called right here.

...we would see the following output:

  About to change the name from 'Legend' to 'Greatest Hits'

=head4 after_update_<field>( $self, $old_value, $new_value )

Called just B<after> a field's value is updated.

So, given the following trigger...

  package App::db::album;
  ...
  __PACKAGE__->add_trigger( after_update_name => sub {
    my ($self, $old_value, $new_value) = @_;
    
    warn "Changed name from '$old_value' to '$new_value'";
  });

...called with the following code...

  my $artist = App::db::artist->create( name => 'Bob Marley' );
  my $album = $artist->add_to_albums( name => 'Legend' );
  
  # Now change the name:
  $album->name( 'Greatest Hits' );
  $album->update; # <--- the trigger is called right here.

...we would see the following output:

  Changed the name from 'Legend' to 'Greatest Hits'

=head2 find_column( $name )

Returns the name of the column, if the class has that column.

Example:

  if( App::db::artist->find_column('name') ) {
    warn "Artists have names!";
  }

=head2 get_table_info( )

Returns a L<Class::DBI::Lite::TableInfo> object fully-populated with all of the
information available about the table represented by a class.

So, given the following table structure:

  create table artists (
    artist_id   integer unsigned not null primary key auto_increment,
    name        varchar(100) not null
  ) engine=innodb charset=utf8;

Here is the example:

  my $info = App::db::artist->get_table_info();
  
  my $column = $info->column('name');
  warn $column->name;           # 'name'
  warn $column->type;           # varchar
  warn $column->length;         # 100
  warn $column->is_pk;          # '0' (because it's not the Primary Key)
  warn $column->is_nullable;    # 0 (because `not null` was specified on the table)
  warn $column->default_value;  # undef because no default value was specified
  warn $column->key;            # undef because not UNIQUE or PRIMARY KEY
  
  foreach my $column ( $info->columns ) {
    warn $column->name;
    warn $column->type;
    warn $column->length;
    warn $column->is_pk;
    ...
    # If the column is an 'enum' field:
    warn join ', ', @{ $column->enum_values };
  }

=head2 pager( \%where, { order_by => 'fields ASC', page_number => 1, page_size => 10 } )

Returns a L<Class::DBI::Lite::Pager> object.

Example:

  # Step 1: Get our pager:
  my $pager = App::db::artist->pager({
    name => { LIKE => 'Bob%' }
  }, {
    order_by    => 'name ASC',
    page_number => 1,
    page_size   => 20,
  });
  
  # Step 2: Show the items in that recordset:
  foreach my $artist ( $pager->items ) {
    # Do stuff with $artist:
    print $artist->name;
  }

See L<Class::DBI::Lite::Pager> for more details and examples.

=head2 sql_pager( { data_sql => $str, count_sql => $str, sql_args => \@array }, { page_number => 1, page_size => 10 } )

Returns a L<Class::DBI::Lite::Pager> object.

Example:

  # Step 1: Get our pager:
  my $pager = App::db::artist->sql_pager({
    data_sql  => "SELECT * FROM artists WHERE name LIKE ?",
    count_sql => "SELECT COUNT(*) FROM artists WHERE name LIKE ?",
    sql_args  => [ 'Bob%' ],
  }, {
    page_number => 1,
    page_size   => 20,
  });
  
  # Step 2: Show the items in that recordset:
  foreach my $artist ( $pager->items ) {
    # Do stuff with $artist:
    print $artist->name;
  }

See L<Class::DBI::Lite::Pager> for more details and examples.

=head1 OBJECT METHODS

=head2 Field Methods

For each of the fields in your table, an "accessor" method will be created.

So, given the following table structure:

  create table artists (
    artist_id   integer unsigned not null primary key auto_increment,
    name        varchar(100) not null,
  ) engine=innodb charset=utf8;

And the following class:

  package App::db::artist;
  
  use strict;
  use warnings 'all';
  use base 'My::Model';
  
  __PACKAGE__->set_up_table('artists');
  
  1;# return true:

The C<App::db::artist> class would have the following methods created:

=over 4

=item * artist_id

Returns the value of the C<artist_id> field the database.  This value is read-only
and cannot be changed.

=item * name

Gets or sets the value of the C<name> field the database.

To get the value of the C<name> field, do this:

  my $value = $artist->name;

To set the value of the C<name> field, do this:

  $artist->name( "New Name" );

To save those changes to the database you must call C<update>:

  $artist->update;

=back

=head2 Overriding Setters and Getters

The accessors/mutators ("setters" and "getters") can be individually overridden
within your entity class by implementing C<_set_foo($self, $value)> or
C<_get_foo($self)> methods.

B<NOTE:> In practice this may be more useful for the C<_get_*> methods, as the C<_set_*>
methods are usually best left to triggers.

=head2 id

Always returns the value of the object's primary column.

Example:

  $album->id == $album->album_id;
  $artist->id == $artist->artist_id;

=head2 update()

Causes any changes to an object to be saved to the database.

Example:

  $artist->name( 'Big Bob' );
  $artist->update;

=head2 delete()

Deletes the object from the database.  The object is then re-blessed into the special
class C<Class::DBI::Lite::Object::Has::Been::Deleted>.

Example:

  $album->delete;

=head2 discard_changes()

Causes any changes made to the object that have not been stored in the database
to be forgotten.

Example:

  my $artist = App::db::artist->create( name => 'Bob Marley' );
  $artist->name( 'Big Bob' );
  
  $artist->discard_changes;

=head1 ADVANCED TOPICS

=head2 Master/Slave Configuration

In your My::db::model class:

Instead of:

  __PACKAGE__->connection( $dsn, $user, $pass );

Do this:

  __PACKAGE__->set_master( $dsn, $user, $pass );

  __PACKAGE__->set_slaves(
    [ $dsn1, $user1, $pass1 ],
    [ $dsn2, $user2, $pass2 ],
    [ $dsn3, $user3, $pass3 ],
  );

Your slaves will be shuffled.

Writes will always* go to the master, reads will always go to the slaves.

*Unless you are inside of a transaction, in which case all reads will also go to the master.

If you want to switch to a different slave, call 'switch_slave' on your main model class:

  My::db::model->switch_slave();

In an ASP4 environment you could add a line like that to an ASP4::RequestFilter.

=head1 SEE ALSO

L<Class::DBI::Lite::Tutorial>

=head1 AUTHOR

Copyright John Drago <jdrago_999@yahoo.com>.  All rights reserved.

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as perl itself.

=cut

