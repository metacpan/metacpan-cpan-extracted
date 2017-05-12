package Class::DBI::FormBuilder::Meta::Column;
use strict;
use warnings;

use base qw( Class::Accessor Class::Data::Inheritable );

BEGIN
{
    # this is the list of column meta that we are interested in - add more items if wanted
    __PACKAGE__->mk_classdata( 'column_attributes', [ qw( column_def         column_size     decimal_digits 
                                                          nullable           is_nullable  
                                                          ordinal_position   type_name foo
                                                            
                                                          mysql_values       mysql_type_name ) ] );
    
    __PACKAGE__->mk_accessors( qw( name table column_attributes ), @{ __PACKAGE__->column_attributes } );

}
    
use overload '""' => 'name';

*order   = \&ordinal_position;
*digits  = \&decimal_digits;
*size    = \&column_size;
*default = \&column_def;

=head1 NAME

Class::DBI::FormBuilder::Meta::Column

=head1 DESCRIPTION

Access to column metadata.

=head1 METHODS

=over 4

=item new($table, $name, $meta)

Returns a new meta object for the column. 

Stringifies to the column's C<name>.

=cut

sub new
{
    my ($proto, $table, $name, $meta) = @_;
    
    my $self = bless { table => $table, # reference to table meta object
                       name  => $name,
                       %$meta,
                       }, ref($proto) || $proto;    
                       
    return $self;
}

=item table

Returns the L<Class::DBI::FormBuilder::Table> object associated with this column. 

=back

=head2 Column attribute accessors

=over 4

=item name 

=item order

=item ordinal_position   

Alias for C<order>.

=item digits

=item decimal_digits 

Alias for C<digits>.
                                                          
=item size

=item column_size   

Alias for C<size>.  

=item default

=item column_def  

Alias for C<default>.       

=item nullable           

=item is_nullable  
                                                          
=item type

=item type_name

Alias for C<type>.
                                                            
=item mysql_values       

=item mysql_type_name

=cut

sub type
{
    my ( $self ) = @_;
    
    my $type = $self->type_name || die "No type_name for $self";

    return lc $type;
}

=item options

Returns the possible values for an enumerated column, and whether the 
column can store multiple value.

Currently only implemented for MySQL C<enum> (multiple is false) and 
C<set> (multiple is true) column types, but should be easy to support 
other databases that offer similar column types.

=back

=cut

sub options
{
    my ($self) = @_;
    
    my $type = $self->type;
    
    my $series = $type =~ /^(?:set|enum)$/o ? $self->mysql_values : [];
    
    my $multiple = 1 if $type eq 'set';
    
    return $series, $multiple;   
}


1;


__END__

    # it's reversed because I typed them out the wrong way round
    my %MetaMap = reverse ( column_def        => 'default',
                            column_size       => 'size',
                            decimal_digits    => 'digits',
                            #nullable          => 'nullable',    # 0 => no, 1 => yes, 2 => unknown
                            #is_nullable       => 'is_nullable', # no, yes, ''
                            ordinal_position  => 'order',
                            #type_name         => 'type',
                            # mysql_values      => '',
                            # mysql_type_name   => '',
                            );
                            
    # provide friendly default, size, digits, order and type methods
    no strict 'refs';
    *{ "$MetaMap{ $_ }" } = \&$_ for keys %MetaMap;
