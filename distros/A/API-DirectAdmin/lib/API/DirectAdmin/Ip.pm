package API::DirectAdmin::Ip;

use Modern::Perl '2010';

use base 'API::DirectAdmin::Component';

our $VERSION = 0.05;

# Return list of IP
# INPUT
# Admin connect params
sub list {
    my ($self ) = @_;

    my $responce = $self->directadmin->query(
	command => 'CMD_API_SHOW_RESELLER_IPS',
    );

    return $responce->{list} if ref $responce eq 'HASH';
    return [];
}

# Add Ip
# INPUT
# Admin connect params
# ip = 'IP.AD.DRE.SS'
# status = free|shared|owned (optional)
sub add {
    my ($self, $params ) = @_;
   
    my %add_params = (
	action   => 'add',
	add      => 'Submit',
	netmask  => '255.255.255.0',
	notify   => 'no',
    );
    
    my %params = (%$params, %add_params);
    
    return $self->directadmin->query(
	params  => \%params,
	method	=> 'POST',
	command => 'CMD_API_IP_MANAGER',
	allowed_fields => 'ip
			   action
			   add
			   netmask
			   notify
			   status',
    );
}

# Delete Ip
# INPUT
# Admin connect params
# select0 = 'IP.AD.DRE.SS'
sub remove {
    my ($self, $params ) = @_;
    
    my %add_params = (
	action   => 'select',
	delete   => 'Delete',
    );
    
    my %params = (%$params, %add_params);
    
    return $self->directadmin->query(
	params  => \%params,
	method	=> 'POST',
	command => 'CMD_API_IP_MANAGER',
	allowed_fields => 'select0
			   action
			   delete',
    );
}

1;
