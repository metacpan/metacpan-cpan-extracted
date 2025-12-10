package Business::NAB::FileContainer;
$Business::NAB::FileContainer::VERSION = '0.01';
# undocument abstract class

use strict;
use warnings;
use feature qw/ signatures /;
use autodie qw/ :all /;
use Carp    qw/ croak /;

use Moose;
no warnings qw/ experimental::signatures /;

use Business::NAB::Types qw/ decamelize /;

sub new_from_file (
    $self,
    $parent,
    $file,
    $sub_class_map,
    $split_char = undef,
) {
    open( my $fh, '<', $file );

    while ( my $line = <$fh> ) {

        $line =~ s/\r\n$//;

        my ( $type ) = $split_char
            ? ( split( $split_char, $line ) )[ 0 ]
            : substr( $line, 0, 1 );

        next if !length( $type );

        my $sub_class = $sub_class_map->{ $type };
        my $attr      = decamelize( $sub_class );
        my $push      = "add_${attr}";

        $sub_class || croak( "Unrecognised record type ($type) at line $." );
        $sub_class = "${parent}::${sub_class}";

        my $Instance = $sub_class->new_from_record( $line );

        $self->$push( $Instance );
    }

    return $self;
}

1;
