package Data::Object::Autobox::Autoload::Float;

use 5.010;
use strict;
use warnings;

use parent 'Data::Object::Autobox::Common';

use Carp         'confess';
use Data::Object 'type_float';
use Scalar::Util 'blessed';

sub AUTOLOAD {
    my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;

    my $delegate = 'Data::Object::Float';
    my $self     = $_[0] = type_float $_[0];

    confess "Undefined subroutine &${delegate}::$method called"
        unless blessed $self && $self->isa($delegate);

    confess "Can't locate object method \"$method\" via package \"$delegate\""
        unless my $source = $self->can($method);

    goto $source; # delegate to Data::Object::Float ...
}

1;
