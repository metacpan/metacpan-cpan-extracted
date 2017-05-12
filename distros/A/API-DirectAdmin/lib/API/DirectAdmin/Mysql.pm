package API::DirectAdmin::Mysql;

use Modern::Perl '2010';
use Data::Dumper;
use Carp;

use base 'API::DirectAdmin::Component';

our $VERSION = 0.05;

# Create database for user
# Connection data MUST BE for user: auth_user => 'admin_login|user_login'
# auth_passwd => 'admin_passwd'
#    INPUT
#    name	=> 'DBNAME',
#    passwd	=> 'DBPASSWD',
#    passwd2	=> 'DBPASSWD',
#    user	=> 'DBLOGIN',
sub adddb {
    my ($self, $params ) = @_;
    
    $params->{action} = 'create';
    
    carp 'params ' . Dumper($params) if $self->{debug};
    
    my $responce = $self->directadmin->query(
	command        => 'CMD_API_DATABASES',
	method	       => 'POST',
	params         => $params,
	allowed_fields => 'action
			   name
			   passwd
			   passwd2
			   user',
    );
    
    carp '$responce ' . Dumper(\$responce) if $self->{debug};
    
    return $responce if $responce;    

    return 'FAIL';
}

# Delete database for user
# Connection data MUST BE for user: auth_user => 'admin_login|user_login'
# auth_passwd => 'admin_passwd'
#    INPUT
#    select0	=> 'DBNAME',
#    domain	=> 'DOMAIN.COM',
sub deldb {
    my ($self, $params ) = @_;
    
    $params->{action} = 'delete';

    carp 'params ' . Dumper($params) if $self->{debug};

    my $responce = $self->directadmin->query(
	command        => 'CMD_API_DATABASES',
	method	       => 'POST',
	params         => $params,
	allowed_fields => 'action
			   select0',
    );
    
    carp '$responce ' . Dumper(\$responce) if $self->{debug};
    
    return $responce if $responce;    

    return 'FAIL';
}

# Get list of databases for authorized user.
# No params.
sub list {
    my ($self ) = @_;

    my $responce = $self->directadmin->query(
	command        => 'CMD_API_DATABASES',
	method	       => 'GET',
    );

    carp '$responce ' . Dumper($responce) if $self->{debug};

    return $responce->{list} if ref $responce eq 'HASH';
    return [];
}

1;
