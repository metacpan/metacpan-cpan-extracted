package Class::DBI::FormBuilder::Meta::Table;
use strict;
use warnings;
use Carp();

use List::Util();

use Class::DBI::FormBuilder::Meta::Column;

use base qw( Class::Accessor );

__PACKAGE__->mk_accessors( qw( dbh cdbi_class _columns_hash catalog schema ) );

=head1 NAME

Class::DBI::FormBuilder::Meta::Table

=head1 DESCRIPTION

Access to column metadata.

=head1 METHODS

=over 4

=item instance( $cdbi, %args )

Returns an instance for the C<$cdbi> class (C<$cdbi> can be a class name or object). 

The C<%args> hash is optional. Keys can be C<catalog> and C<schema>, which are also 
available as accessors. Both default to C<undef>.

=item catalog

Get/set the catalog.

=item schema

Get/set the schema.

=item dbh

Get/set the DBI database handle (you probably don't want to set it).

=item cdbi_class

Get/set the CDBI class (you probably don't want to set it).

=cut

{
    # per-process instances, keyed by CDBI class
    my %Instances;
                                  
    # must be a singleton, loading meta is a fairly expensive operation (the queries can return 
    # lots of data)
    sub instance
    {
        my ( $proto, $cdbi, %args ) = @_;
        
        $cdbi && UNIVERSAL::isa( $cdbi, 'Class::DBI' ) or 
                    Carp::croak( "Must supply a CDBI class or object (got '$cdbi')" );
        
        my $cdbi_class = ref $cdbi || $cdbi;
        
        return $Instances{$cdbi_class} if $Instances{$cdbi_class};
        
        # first time - build a new object
        
        my $self = bless { _columns_hash => {} }, ref $proto || $proto;
        
        $self->cdbi_class($cdbi_class);
        
        $self->dbh( $cdbi_class->db_Main );
        
        $self->catalog( $args{catalog} || undef );
        
        $self->schema( $args{schema} || undef );
        
        $self->_load_meta;
        
        $Instances{$cdbi_class} = $self;
        
        return $self;
    }
}

sub _load_meta
{
    my ( $self ) = @_;
    
    die "Meta already loaded" if keys %{ $self->_columns_hash };
    
    my $dbh   = $self->dbh;
    my $table = $self->cdbi_class->table;
    
    #$dbh->{FetchHashKeyName} = 'NAME_lc';
    
    # undef does not constrain the data returned for that key
    # I'm suspicious that setting catalog and schema to undef might break RDBMSs that actually 
    # do supply that information. 
    
    # '%' is a search pattern for columns - matches all columns
    if ( my $sth = $dbh->column_info( $self->catalog, $self->schema, $table, '%' ) )
    {
        $dbh->errstr && die "Error getting column info sth: " . $dbh->errstr;
        $self->_load_type_meta( $sth );    
    }
    else
    {
        $self->_load_typeless_meta;        
    }
}

# typeless db e.g. sqlite
sub _load_typeless_meta
{
    my ( $self ) = @_;

    $self->cdbi_class->set_sql( fb_meta_dummy => 'SELECT * FROM __TABLE__ WHERE 1=0' )
        unless $self->cdbi_class->can( 'sql_fb_meta_dummy' );

    my $sth = $self->cdbi_class->sql_fb_meta_dummy;
    
    $sth->execute or die "Error executing column info: "  . $sth->errstr;;
    
    # see 'Statement Handle Attributes' in the DBI docs for a list of available attributes
    my $cols  = $sth->{NAME};
    my $types = $sth->{TYPE};
    # my $sizes = $sth->{PRECISION};    # empty
    # my $nulls = $sth->{NULLABLE};     # empty
    
    # we haven't actually fetched anything from the sth, so need to tell DBI we're not going to
    $sth->finish;
    
    my $order = 0;
    
    foreach my $col ( @$cols )
    {
        my $meta;
        
        $meta->{nullable}    = 1;
        $meta->{is_nullable} = 'yes';
        
        # in my limited testing, the columns are returned in the same order as they were defined in the schema
        $meta->{ordinal_position} = $order++;
        
        # type_name is taken literally from the schema, but is not actually used by sqlite, 
        # so it can be anything, e.g. varchar or varchar(xxx) or VARCHAR etc.
        $meta->{type_name} = _fixup_type( shift( @$types ) );  
        
        $self->_add_column( $col, $meta );
    }
}

# $type may be something like varchar(255) from sqlite
sub _fixup_type
{
    my ( $type ) = @_;
    $type =~ s/\(.+$//;
    return $type;
}

sub _load_type_meta
{
    my ($self, $sth) = @_;
    
    while ( my $row = $sth->fetchrow_hashref )
    {
        my ($meta, $col_name);
        
        foreach my $key ( @{ Class::DBI::FormBuilder::Meta::Column->column_attributes } )
        {
            my $value = $row->{$key} || $row->{ uc $key };
            $meta->{$key} = $value;
            $col_name = $row->{COLUMN_NAME} || $row->{column_name};
        }
        
        $self->_add_column($col_name, $meta);    
    }
}

sub _add_column
{
    my ( $self, $name, $meta ) = @_;
    
    $self->_columns_hash->{$name} = Class::DBI::FormBuilder::Meta::Column->new($self, $name, $meta);
}

=item column_deep_type( $field )

Returns the type of the field. If C<$field> refers to a relationship (e.g. C<has_many> or  
C<might_have>), returns the type of the column in the related table.

=cut

# $col might be a related (has_many or might_have) accessor - i.e. it refers to a column in 
# another table, in which case, the type of the column in that table is returned
sub column_deep_type
{
    my ($self, $field) = @_;
    
    Carp::croak "Must supply a column name - got a ref - '$field' " . ref($field) if ref $field;
    
    my $them = $self->cdbi_class;
    
    my $column = $self->column($field);
    
    return $column->type if $column;
    
    # no such column - must be a related accessor
    
    my ($other, $rel_type) = $self->related_class_and_rel_type($field);
    
    Carp::croak "Non-existent column '$field' in '$them' is not related to anything" unless $other;
    
    my $meta = $them->meta_info($rel_type, $field);
    
    my $fk = $meta->{args}->{foreign_key};
    
    my $other_meta = $self->instance($other);
    
    my $type = $other_meta->column($fk)->type if $fk;            

    die "No type detected for column '$field' in '$them' or column '$fk' in '$other'" unless $type;
    
    return $type;
}

=item related_class_and_rel_type( $field )

=cut 

sub related_class_and_rel_type
{
    my ( $self, $field ) = @_;
    
    my $them = $self->cdbi_class;
    
    my @rel_types = keys %{ $them->meta_info };

    my $related_meta = List::Util::first { $_ } map { $them->meta_info( $_ => $field ) } @rel_types;
    
    return unless $related_meta;

    my $rel_type = $related_meta->name;
                  
    my $mapping = $related_meta->{args}->{mapping} || [];
    
    my $related_class;
 
    if ( @$mapping ) 
    {
        #use Data::Dumper;
        #my $foreign_meta = $related_meta->foreign_class->meta_info( 'has_a' );
        #die Dumper( [ $mapping, $rel_type, $related_meta, $foreign_meta ] );
        $related_class = $related_meta->foreign_class
                                      ->meta_info( 'has_a' )
                                      ->{ $$mapping[0] }
                                      ->foreign_class;
    
        #my $accessor = $related_meta->accessor;   
        #my $map = $$mapping[0];                        
    }
    else 
    {
        $related_class = $related_meta->foreign_class;
    }
    
    return ($related_class, $rel_type);    
}

=item column( $col_name )

If C<$col_name> is a column in this class, returns a L<Class::DBI::FormBuilder::Meta::Column> 
object for that column. Otherwise, returns C<undef>. 

=cut

# returns a CDBI::FB::Meta::Column object or undef - e.g. if asked for a has_many field
# note: column_deep_type relies on the undef for related columns
sub column
{
    my ($self, $col_name) = @_;
    
    my $h = $self->_columns_hash;
    
    Carp::croak "meta not loaded" unless $h;
    
    return $h->{ $col_name };
}

=item columns()

Returns L<Class::DBI::Column> objects, in the same order as defined in the database.

=back

=cut

sub columns
{
    my ( $self, $group ) = @_;

    $group ||= 'All';

    my @columns = $self->cdbi_class->columns( $group );
    
    my @ordered = map  { $_->[0] }
                  sort { $a->[1] <=> $b->[1] }
                  grep { Carp::croak "Bad column " . $_->[0] . " has order: " . $_->[1] unless defined $_->[1]; $_ }
                  map  { [ $_, $self->column( $_->name )->order ] }
                  @columns;
                  
    return @ordered;
}

1;


__END__


$VAR1 = { catalogue schema   table            column           meta
          '' => {
                  '' => {
                          'consultant' => {
                                            '_telephone' => {
                                                              'COLUMN_DEF' => '',
                                                              'mysql_values' => undef,
                                                              'NUM_PREC_RADIX' => undef,
                                                              'COLLATION_CAT' => undef,
                                                              'TABLE_SCHEM' => undef,
                                                              'DOMAIN_NAME' => undef,
                                                              'COLLATION_NAME' => undef,
                                                              'REMARKS' => undef,
                                                              'mysql_type_name' => 'varchar(64)',
                                                              'COLUMN_SIZE' => '64',
                                                              'SCOPE_NAME' => undef,
                                                              'TYPE_NAME' => 'VARCHAR',
                                                              'UDT_NAME' => undef,
                                                              'NULLABLE' => 0,
                                                              'DATA_TYPE' => 12,
                                                              'TABLE_NAME' => 'consultant',
                                                              'DOMAIN_SCHEM' => undef,
                                                              'CHAR_SET_CAT' => undef,
                                                              'COLLATION_SCHEM' => undef,
                                                              'CHAR_SET_NAME' => undef,
                                                              'DECIMAL_DIGITS' => undef,
                                                              'UDT_CAT' => undef,
                                                              'SCOPE_CAT' => undef,
                                                              'TABLE_CAT' => undef,
                                                              'CHAR_OCTET_LENGTH' => undef,
                                                              'BUFFER_LENGTH' => undef,
                                                              'IS_NULLABLE' => 'NO',
                                                              'MAX_CARDINALITY' => undef,
                                                              'ORDINAL_POSITION' => 18,
                                                              'UDT_SCHEM' => undef,
                                                              'COLUMN_NAME' => '_telephone',
                                                              'DTD_IDENTIFIER' => undef,
                                                              'mysql_is_pri_key' => '',
                                                              'SQL_DATA_TYPE' => 12,
                                                              'CHAR_SET_SCHEM' => undef,
                                                              'IS_SELF_REF' => undef,
                                                              'DOMAIN_CAT' => undef,
                                                              'SCOPE_SCHEM' => undef,
                                                              'SQL_DATETIME_SUB' => undef
                                                            },
                                                            
{
    my %MetaMap = reverse ( COLUMN_DEF        => 'default',
                            COLUMN_SIZE       => 'size',
                            DECIMAL_DIGITS    => 'digits',
                            NULLABLE          => 'nullable',    # 0 => no, 1 => yes, 2 => unknown
                            IS_NULLABLE       => 'is_nullable', # no, yes, ''
                            ORDINAL_POSITION  => 'order',
                            TYPE_NAME         => 'type',
                            # mysql_values      => '',
                            # mysql_type_name   => '',
                            );
                    
    sub column_metaXXX
    {
        my ( $self, $column, $key ) = @_;
        
        Carp::croak "No key to query on" unless $key;
        
        my @columns = ref $column eq 'ARRAY' ? @$column : ( $column );
        
        do { Carp::croak( "Must supply CDBI column object" ) unless UNIVERSAL::isa( $_, 'Class::DBI::Column' ) } 
            for @columns;
        
        my $k = $MetaMap{ $key } || $key;
        
        my $meta = $self->meta || die 'no meta';
        
        my @rv = map { $meta->{ $_->name }->{ $k } } @columns;
        
        # be careful with calling context e.g. 
        #   my $type = lc $me->column_meta( $them, $col, 'type' );
        # instead of
        #   my $type = lc scalar $me->column_meta( $them, $col, 'type' );
        return @rv > 1 ? @rv : $rv[0];
    }
}
