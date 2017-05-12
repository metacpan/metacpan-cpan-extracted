package Data::File::Map;
$Data::File::Map::VERSION = '0.09';
use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( ArrayRef Str HashRef );

use Data::File::Map::Field;

use XML::LibXML;


class_type 'Data::File::Map';

coerce 'Data::File::Map',
     from 'Str',
     via { Data::File::Map->new_from_file( $_ ) };


has 'format' => (        # can be text or csv
    is => 'rw',
    isa => subtype ( 'Str' => where { $_ eq 'csv' || $_ eq 'text' } ),
    default => 'csv',
);

has 'separator' => (     # only for csv files
    is => 'rw',
    isa => 'Str',
    default => '|',
);

has 'fields' => (
    is => 'bare',
    isa => 'ArrayRef',
    traits => [qw( Array )],
    default => sub { [ ] },
    handles => {
        '_add_field' => 'push',
        '_fields' => 'elements',
    },
    lazy => 1,
);

has '_xfields' => (
    is => 'bare',
    isa => 'ArrayRef',
    traits => [qw( Array )],
    handles => {
        '_xfields' => 'elements',
    },
    default => sub {
      [
        map {
          my %field_data;
          @field_data{qw[name position width label]} = ( @$_ );
          Data::File::Map::Field->new(  %field_data );
         } $_[0]->fields
      ]
    },
    lazy => 1,
);

sub fields {

  my ( $self, $want_objects ) = @_;
  
  if ( $want_objects ) {
    return $self->_xfields;
  }
  else {
    return $self->_fields;
  }
  
}

sub add_field {
  
  my ( $self, @args ) = @_;
  
  # if an ArrayRef is given
  if ( @args == 1 && is_ArrayRef($args[0]) ) {
    $self->_add_field( $args[0] );
  }
  # if is a String and a HashRef
  elsif ( @args == 2 && is_Str($args[0]) && is_HashRef( $args[1] )  ) {
    
    # create array to store fields
    my @values = map { exists $args[1]{$_} ? $args[1]{$_} : undef } qw/position width label/;
    
    $self->_add_field( [ $args[0], @values ] );
  }
  # if just a string
  elsif ( @args == 1 && is_Str($args[0])  ) {
    
    $self->_add_field( [ $args[0] ] );
    
  }


  else {
    die "Could not add field, unknown argument format.";
  }
  
  return 
  
}




sub field_names {
    map { $_->[0] } $_[0]->fields;
}

sub get_field {
  
  my ( $self, $name) = @_;
  
  for my $field ( $self->fields(1) ) {
    
        return $field if $field->name eq $name;
    
  }
  
}


sub new_from_file {
    my ( $class, $file ) = @_;
    my $self = $class->new;
    $self->parse_file( $file );
    return $self;
}

sub new_from_string {
    my ( $class, $str ) = @_;
    my $self = $class->new;
    $self->parse_string( $str );
    return $self;
}

sub parse_file {
    my ( $self, $path ) = @_;
    
    die "You must specify a path\n" if ! $path;
    
    die "Could not find file $path\n" if !-e $path || ! -f $path;
    
    my $doc = XML::LibXML->load_xml( location => $path );
    
    $self->_parse_document( $doc );
}

sub parse_string {
    my ( $self, $str ) = @_;
    
    die "You must provide a string to parse\n" if ! $str;
    
    my $doc = XML::LibXML->load_xml( string => $str );
    
    $self->_parse_document( $doc );
}

sub _parse_document {
    my ( $self, $doc ) = @_;
    
    my $root = $doc->documentElement;
    
    # determine format
    {
        my ( $node ) = $root->getChildrenByTagName( 'format' );
        if ( $node ) {
            my $value = $node->textContent;
            $self->set_format( $value );
        }
    }
    
    # determine separator
    {
        my ( $node ) = $root->getChildrenByTagName( 'separator' );
        if ( $node ) {
            my $value = $node->textContent;
            $self->set_separator( $value );
        }
    }
    
    # determine fields
    {
        my ( $node ) = $root->getChildrenByTagName( 'fields' );
        
        if ( $node ) {
            
            if ( $self->format eq 'csv' ) {
                
                for my $field ( $node->getChildrenByTagName( 'field' ) ) {
                    
                    my $name = $field->textContent;
                    
                    my $item = [ $name || '' ];
                    $self->add_field( $item );
                }
                
            }
            elsif ( $self->format eq 'text' ) {
                
                for my $field ( $node->getChildrenByTagName( 'field' ) ) {
                    
                    my $name = $field->getAttribute('name') || $field->textContent;
                    
                    my $label = $field->getAttribute('label') ||  $field->textContent;
                    
                    my $position  = $field->getAttribute('position');
                    
                    my $width = $field->getAttribute('width');
                    
                    my ( $pos, $w );
                    if ( $position ) {
                        ( $pos, $w ) = split /\./, $position;
                    }
                    
                    $w = $width if $width;
                    
                    if ( $pos && $w ) {
                        my $item = [ $name, $pos, $w, $label];
                        $self->add_field( $item );
                    }
                    else {
                        die "No position/width specified for field ($name)\n";
                    }
                    
                    
                }
                
            }
        }
    }
}





## DEPRECREATE THESE FUNCTIONS
sub read {
    my ( $self, $line ) = @_;
    
    chomp $line;
    
    my %rec;
    
    if ( $self->format eq 'csv' ) {
        
        my $sep = $self->separator;
        
        @rec{$self->field_names} = split /$sep/, $line;
        delete $rec{''};
    }
    elsif ( $self->format eq 'text' ) {
        no warnings;
        @rec{ $self->field_names } = map {
            my $val = substr( $line, $_->[1] - 1, $_->[2] );
            $val ||= '';
            $val =~ s/^\s+//;
            $val =~ s/\s+$//;
            $val;
        } $self->fields;
        
    }
    
    return \%rec;
}

sub read_file {
    my ( $self, $path ) = @_;
    
    if ( ! -e $path ) {
        die "File ($path) does not exist.\n";
    }
    
    my @records;
    
    open my $file, '<', $path or die "Could not open file ($path) for reading.\n";
    flock $file, 2;
    
    while ( <$file> ) {
        push @records, $self->read( $_ );
    }
    
    close $file;
    
    return @records;
}

1;


__END__

=pod

=head1 NAME

Data::File::Map - Read data file definitions stored as XML

=head1 SYNOPSIS

    use Data::File::Map;

    # load data file definition

    $map = Data::File::Map->new_from_file( 'path/to/map.xml' );

    # read records from a data file using the map

    open FILE, 'data.txt' or die "Could not open file.";
    
    while( <FILE> ) {
        
        $record = $map->read( $_ );
        
    }
    
    close FILE;

=head1 DESCRIPTION

Data::File::Map will allow you to read in a data file definition stored as XML. The map
can then be used to parse records in a data file. Handles delimited and formatted text
data.

=head1 ATTRIBUTES

=over 4

=item format

The format of the data file. Can be either C<csv> for delimited files or 'text'
for formatted ascii files.

=over 4

=item isa: Str['text'|'csv']

=item default: csv

=back

=item separator

Used to separate variables in a csv file. This is a regular expression.

=over 4

=item isa: String['text'|'csv']

=item default: \|

=back

=back

=head1 METHODS

=over 4

=item add_field \@attributes

Attribute order is name, position, width, label;

=item add_field $name, [\%attributes]

Add a field to the map. If C<\%attributes> is supplied, the position, width, and label
attributes will be stored.

=item fields [$want_objects]

Returns a list of ArrayRefs containing information about the fields in the definition.
The format off the ArrayRefs is C<[$field_name, $position, $width]>. Position and width
will only be defined in C<text> files. If C<$want_objects> will return a list of
C<Data::File::Map::Field> objects.


=item field_names

Returns a list of field names in the order defined in the definition file.

=item get_field $name

Returns the L<Data::File::Map::Field> object with the given name.

=item new

Create a new L<Data::File::Map> instance.

=item new_from_file $path

Create a new L<Data::File::Map> instance and load definition from a file.

=item new_from_string $string

Create a new L<Data::File::Map> instance and load definition from a string.

=item parse_file $path

Load definition from a file.

=item parse_string $string

Load definition from a string.

=item read $line

Takes a line from a data file and uses the definition to extaract the variables.
Returns a HashRef with field names as keys.

=item read_file $path

Calls C<read> on each line in the given file and returns an array of records.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2013 Jeffrey Ray Hallock.
    
=head1 LICENSE

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut


