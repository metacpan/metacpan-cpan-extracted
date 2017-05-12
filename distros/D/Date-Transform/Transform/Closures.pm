package Date::Transform::Closures;

use 5.006;
use strict;
use warnings;
use Carp;
use Switch 'Perl6';
use Tie::IxHash;

require Exporter;
use AutoLoader qw(AUTOLOAD);
our @ISA = qw(  Exporter );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Date::Transform ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS =
  ( 'all' => [qw( mk_set_filter_input mk_passthru mk_function)] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = qw( mk_set_filter_input mk_passthru mk_function );

our $VERSION = '0.11';

## SUBROUTINE: mk_set_filter_input
##  Generates a function that sets the key of Tie::IxHash
##  The key of the object is set to the value of the evaluated function.
##
##	Usage: $fn = mk_set_filter_input( $key, $f);
##				Tie::IxHash_obj->$fn
##
sub mk_set_filter_input {

    my $key      = shift;
    my $function = shift;

    my $new_function =

      sub {

        my $self = shift;
        $self->{filter}->{input}
          ->STORE( $key, $self->{filter}->{matches}->$function );

      };

    return $new_function;
}

## SUBROUTINE: mk_passthrough
## Generates a function that returns the value of the Tie::IxHash
## The value returned is specified by the passed argument key.
## * In the anonymous function, $self will be a Tie::IxHash object,
##	Input Object.
##
##	Usage: $fn = mk_passthru( $key );
##				Tie::IxHash_obj->$fn
sub mk_passthru {

    my $key = shift;
    carp("No key provided for passthru\n") if ( !defined $key );

    my $function = sub {

        my $self  = shift;
        my $value = $self->FETCH($key);

        return $value;

    };

    return $function;
}

## SUBROUTINE: mk_function
## 	returns a closure that applies $function to the value(s)
##	of the key(s), @keys
##
## usage: mk_function( ref_to_function, Tie::IxHash_keys object );
##
sub mk_function {

    my $function = shift;
    my @keys     = @_;

    ## print "@keys\n";

    my $new_function = sub {

        my $matches = shift;
        my @inputs  = map { $matches->FETCH($_) } @keys;

        return &$function(@inputs);

    };

    return $new_function;

}    # END SUBROUTINE: mk_function

1;

__END__;