package Crypt::Perl::X::Base;

use strict;
use warnings;

use Carp ();

sub new {
    my ( $class, $string, $props_hr ) = @_;

    $class->_check_overload();

    my %attrs = $props_hr ? %$props_hr : ();

    return bless [ $string, \%attrs ], $class;
}

sub get {
    my ( $self, $attr ) = @_;

    #Do we need to clone this? Could JSON suffice, or do we need Clone?
    return $self->[1]{$attr};
}

sub to_string {
    my ($self) = @_;

    return sprintf '%s: %s', ref($self), $self->[0];
}

#----------------------------------------------------------------------

my %_OVERLOADED;

sub _check_overload {
    my ( $class, $str ) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    $_OVERLOADED{$class} ||= eval qq{
        package $class;
        use overload (q<""> => __PACKAGE__->can('__spew'));
        1;
    };

    #Should never happen as long as overload.pm is available.
    warn if !$_OVERLOADED{$class};

    $@ = $eval_err;

    return;
}

sub __spew {
    my ($self) = @_;

    my $spew = $self->to_string();

    if ( substr( $spew, -1 ) ne "\n" ) {
        $spew .= Carp::longmess();
    }

    return $spew;
}

1;
