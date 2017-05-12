package Data::File::Map::Field;
$Data::File::Map::Field::VERSION = '0.09';
{
  $Data::File::Map::Field::VERSION = '0.02.1';
}


use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

has 'name' => (
    is => 'rw',
    isa => 'Str',
);

has 'label' => (
    is => 'rw',
    isa => 'Str|Undef',
    default => '',
);

has 'position' => (
    is => 'rw',
    isa => 'Maybe[Int]',
    trigger => sub {
        my ( $self, $newval, $oldval ) = @_;
        if ( $newval =~ /\./ ) {
            my ( $pos, $width ) = split '.', $newval;
            $self->set_width( $width );
            $self->set_position( $pos );
        }
    }
);

has 'width' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);


1;
