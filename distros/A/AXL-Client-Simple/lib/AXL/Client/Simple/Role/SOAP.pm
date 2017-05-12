package AXL::Client::Simple::Role::SOAP;
use Moose::Role;

use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use File::ShareDir ();

has transporter => (
    is => 'ro',
    isa => 'XML::Compile::Transport::SOAPHTTP',
    lazy_build => 1,
);

sub _build_transporter {
    my $self = shift;
    return XML::Compile::Transport::SOAPHTTP->new(
        address => (sprintf 'https://%s:%s@%s:8443/axl/',
            $self->username, $self->password, $self->server),
        keep_alive => 0,
    );
}

has wsdl => (
    is => 'ro',
    isa => 'XML::Compile::WSDL11',
    lazy_build => 1,
);

sub _build_wsdl {
    my $self = shift;

    XML::Compile->addSchemaDirs( $self->schema_path );
    my $wsdl = XML::Compile::WSDL11->new('AXLAPI.wsdl');
    $wsdl->importDefinitions('AXLSoap.xsd');

    return $wsdl;
}

has schema_path => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_schema_path {
    my $self = shift;
    return File::ShareDir::dist_dir('AXL-Client-Simple');
}

no Moose::Role;
1;

