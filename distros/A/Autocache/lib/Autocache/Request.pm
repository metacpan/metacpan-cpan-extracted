package Autocache::Request;

use Any::Moose;

use Autocache::Logger qw(get_logger);

has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'normaliser' => (
    is => 'ro',
    required => 1,
);

has 'generator' => (
    is => 'ro',
    required => 1,
);

has 'args' => (
    is => 'ro',
    isa => 'ArrayRef',
    required => 1,
);

has 'context' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'key' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_key
{
    my ($self) = @_;
    get_logger()->debug( "_build_key" );
    return sprintf 'AC-%s-%s-%s',
        $self->context,
        $self->name,
        $self->normaliser->( @{$self->args} );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
