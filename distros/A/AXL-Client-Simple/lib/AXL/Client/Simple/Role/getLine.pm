package AXL::Client::Simple::Role::getLine;
use Moose::Role;

has getLine => (
    is => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);

sub _build_getLine {
    my $self = shift;
    return $self->wsdl->compileClient(
        operation => 'getLine',
        transport => $self->transporter->compileClient(
            action => 'CUCM:DB ver=7.1' ),
    );
}

no Moose::Role;
1;

