# ============================================================================
package Business::UPS::Tracking::Role::Base;
# ============================================================================
use utf8;
use 5.0100;

use Moose::Role;

no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Try::Tiny;
use Path::Class::File;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Role::Base - Helper role
  
=head1 DESCRIPTION

This role provides accessors for the UPS webservice credentials. 
The credentials can be provided when constructing a new object, or optionally
stored in a configuration file.

=head1 ACCESSORS

=head2 AccessLicenseNumber

UPS tracking service access license number

=head2 UserId

UPS account username

=head2 Password

UPS account password

=head2 config

Optionally you can retrieve all or some UPS webservice credentials from a
configuration file. This accessor holds the path to this file.
Defaults to C<~/.ups_tracking>

Example configuration file:

 <?xml version="1.0"?>
 <UPS_tracing_webservice_config>
    <AccessLicenseNumber>1CFFED5A5E91B17</AccessLicenseNumber>
    <UserId>myupsuser</UserId>
    <Password>secret</Password>
 </UPS_tracing_webservice_config>
 
=cut

has 'config' => (
    is       => 'rw',
    isa      => 'Str',
    default  => sub {
        Path::Class::File->new( $ENV{HOME}, '.ups_tracking' )->stringify;
    },
    documentation => 'UPS tracking webservice access config file'
);

has 'AccessLicenseNumber' => (
    is          => 'rw',
    required    => 1,
    isa         => 'Str',
    lazy_build  => 1,
    predicate   => '_has_AccessLicenseNumber',
    documentation   => 'UPS webservice license number (Can be set via the ups_tracking config file)',
);
has 'UserId' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy_build  => 1,
    predicate   => '_has_UserId',
    documentation   => 'UPS webservice user id (Can be set via the ups_tracking config file)',
);
has 'Password' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    lazy_build  => 1,
    predicate   => '_has_Password',
    documentation   => 'UPS webservice password (Can be set via the ups_tracking config file)',
);


sub _build_AccessLicenseNumber {
    my ($self) = @_;
    
    $self->_build_config();
    
    if ($self->_has_AccessLicenseNumber) {
        return $self->AccessLicenseNumber;
    }
}

sub _build_UserId {
    my ($self) = @_;
    
    $self->_build_config();
    
    if ($self->_has_UserId) {
        return $self->UserId;
    }
}

sub _build_Password {
    my ($self) = @_;
    
    $self->_build_config();
    
    if ($self->_has_Password) {
        return $self->Password;
    }
}

sub _build_config {
    my ($self) = @_;
    
    unless (-e $self->config) {
        Business::UPS::Tracking::X->throw('Could not find UPS tracking webservice access config file at "'.$self->config.'"');
    }
    
    my $parser = XML::LibXML->new();
    
    try {
        my $document = $parser->parse_file( $self->config );
        my $root = $document->documentElement();
        
        my $params = {};
        foreach my $param ($root->childNodes) {
            my $method = $param->nodeName;
            next
                unless grep { $_ eq $method } qw(AccessLicenseNumber UserId Password);
            $params->{$method} = $param->textContent;
            $self->$method($param->textContent); 
        }
        return 1;
    } catch {
        my $e = $_ || 'Unknwon error';
        Business::UPS::Tracking::X->throw('Could not open/parse UPS tracking webservice access config file at '.$self->config.' : '.$e);
    };
    
    unless ($self->_has_AccessLicenseNumber 
        && $self->_has_UserId
        && $self->_has_Password) {
        Business::UPS::Tracking::X->throw('AccessLicenseNumber,UserId and Passwortd must be provided or set via a config file located at '.$self->config);
    }
    
    return;
}

no Moose::Role;
1;
