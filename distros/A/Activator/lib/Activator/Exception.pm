package Activator::Exception;

use warnings;
use strict;

# override throw to accept shortcut
sub throw {
    my ( $pkg, $obj, $code, $extra ) = @_;
    $pkg->SUPER::throw( error => $obj,
			code => $code,
			extra => $extra );
}

# TODO: make this thing do dictionary/lexicon lookups, with support in
# $extra as well. Maybe $extra could "dict-><key>".

# TODO: make this take 2 args, update all of Activator

# NOTE: this is always called from SUPER::as_string
sub full_message {
    my $self = shift;

    my $msg = $self->description .': ' . $self->error;
    my $code  = $self->code;
    my $extra = $self->extra;
    $msg .= " $code" if $code;
    $msg .= " $extra" if $extra;
    return $msg;
}

# TODO: implement
sub as_xml {}
sub as_json {}


# define exceptions here
use Exception::Class (
    'Activator::Exception' => {
        description => 'Activator exception',
        fields => [ qw( code extra ) ]
    },
    'Activator::Exception::DB' => {
        isa => 'Activator::Exception',
        description => 'Activator DB exception',
    },
    'Activator::Exception::Dictionary' => {
        isa => 'Activator::Exception',
        description => 'Activator Dictionary exception',
    },
    'Activator::Exception::Options' => {
        isa => 'Activator::Exception',
        description => 'Activator Options exception',
    },
    'Activator::Exception::Config' => {
        isa => 'Activator::Exception',
        description => 'Activator Config exception',
    },
    'Activator::Exception::Registry' => {
        isa => 'Activator::Exception',
        description => 'Activator Registry exception',
    },
    'Activator::Exception::Log' => {
        isa => 'Activator::Exception',
        description => 'Activator Log exception',
    },
    'Activator::Exception::Emailer' => {
        isa => 'Activator::Exception',
        description => 'Activator Emailer exception',
    },

);

1;

__END__

new exceptions template:

    'Activator::Exception' => {
        isa => 'Activator::Exception',
        description => '',
    },
