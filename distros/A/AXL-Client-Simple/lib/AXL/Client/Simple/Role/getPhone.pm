package AXL::Client::Simple::Role::getPhone;
use Moose::Role;

has getPhone => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_getPhone {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'getPhone',
        transport => $self->transporter->compileClient(
            action => 'CUCM:DB ver=7.1' ),
    );
}

no Moose::Role;
1;

