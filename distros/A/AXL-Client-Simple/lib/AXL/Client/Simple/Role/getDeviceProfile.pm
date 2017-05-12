package AXL::Client::Simple::Role::getDeviceProfile;
use Moose::Role;

has getDeviceProfile => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_getDeviceProfile {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'getDeviceProfile',
        transport => $self->transporter->compileClient(
            action => 'CUCM:DB ver=7.1' ),
    );
}

no Moose::Role;
1;

