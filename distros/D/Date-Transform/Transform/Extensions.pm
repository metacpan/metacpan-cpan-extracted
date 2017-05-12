package Date::Transform::Extensions;

use 5.006;
use strict;
use warnings;
use Carp;

use Tie::IxHash;

require Exporter;
use AutoLoader qw(AUTOLOAD);
our @ISA = qw( Exporter );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Date::Manip::Transform ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw( Tie::IxHash::IndexFromKey  Tie::IxHash::KeyFromIndex  Tie::IxHash::ValueFromIndex )
    ]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT =
  qw( Tie::IxHash::IndexFromKey  Tie::IxHash::KeyFromIndex  Tie::IxHash::ValueFromIndex);

our $VERSION = '0.11';

# Preloaded methods go here.

## SUBROUTINE: Tie::IxHash::IndexFromKey
## Usage: ixhash_obj->IndexFromKey $key ) => $Index
## Returns the index(position) of the key ,$key
sub Tie::IxHash::IndexFromKey {

    my $self = shift;
    my $key  = shift;

    my @indices = $self->Indices($key);

    return $indices[0];

}    # END SUBROUTINE: Tie::IxHash::Index

## SUBROUTINE: Tie::IxHash::KeyFromIndex
## Usage: $ixhash_obj->KeyFromIndex( $Index ) = $key
##
sub Tie::IxHash::KeyFromIndex {

    my $self  = shift;
    my $index = shift;

    return $self->[1]->[$index];

}    # END SUBROUTINE: tie::IxHash::KeyFromIndex

## SUBROUTINE: Tie::IxHash::ValueFromIndex
sub Tie::IxHash::ValueFromIndex {

    my $self  = shift;
    my $index = shift;

    return $self->FETCH( $self->[1]->[$index] );

}    # END SUBROUTINE: Tie::IxHash::ValueFromIndex

########

1;

__END__;