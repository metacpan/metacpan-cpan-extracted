package BoardStreams::Error::JSONRPC;

use Moo;
extends 'BoardStreams::Error';

use BoardStreams::Util 'make_one_line';

use Data::Dump 'dump';
use Carp 'croak';

use experimental 'signatures';

use overload '""' => sub {
    my $text = ref($_[0]) . '=' . dump({
        code_num => $_[0]->code_num,
        message  => $_[0]->message,
        $_[0]->has_data ? (data => $_[0]->data) : (),
    });
    return make_one_line $text;
};

our $VERSION = "v0.0.36";

has '+code' => (
    default => 'jsonrpc_error',
);

has code_num => (
    is       => 'ro',
    isa      => sub ($code) {
        croak "Code '$code' is not an integer" unless !length(ref $code) and $code =~ /^\-?[0-9]+\z/;
    },
    required => 1,
);

has message => (
    is       => 'ro',
    isa      => sub ($message) {
        croak "Message '$message' is not a string" unless !length(ref $message) and defined $message;
    },
    required => 1
);

sub TO_JSON ($self) {
    return {
        code    => int $self->code_num,
        message => $self->message,
        $self->has_data ? (data => $self->data) : (),
    };
}

1;
