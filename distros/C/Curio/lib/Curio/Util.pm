package Curio::Util;
our $VERSION = '0.04';

use Carp qw();

use strictures 2;
use namespace::clean;

use Exporter qw( import );

our @EXPORT = qw(
    croak
    croakf
    subname
);

sub croak {
    local $Carp::Internal{'Curio'} = 1;
    local $Carp::Internal{'Curio::Declare'} = 1;
    local $Carp::Internal{'Curio::Factory'} = 1;
    local $Carp::Internal{'Curio::Role'} = 1;
    local $Carp::Internal{'Curio::Util'} = 1;

    return Carp::croak( @_ );
}

sub croakf {
    my $msg = shift;
    $msg = sprintf( $msg, @_ );
    return croak( $msg );
}

BEGIN {
    if (eval{ require Sub::Name; 1 }) {
        *subname = \&Sub::Name::subname;
    }
    elsif (eval{ require Sub::Util; 1 } and defined &Sub::Util::set_subname) {
        *subname = \&Sub::Util::set_subname;
    }
    else {
        *subname = sub{ return $_[1] };
    }
}

1;
