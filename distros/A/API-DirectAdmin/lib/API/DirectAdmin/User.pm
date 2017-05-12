package API::DirectAdmin::User;

use Modern::Perl '2010';
use Carp;

use base 'API::DirectAdmin::Component';

our $VERSION = 0.06;

# Return list of users (only usernames)
sub list {
    my ($self ) = @_;

    my $responce = $self->directadmin->query(
	command => 'CMD_API_SHOW_ALL_USERS',
    );

    return $responce->{list} if ref $responce eq 'HASH';
    return [];
}

# Create a New User
# params: username, domain, passwd, passwd2, package, ip, email
sub create {
    my ($self, $params ) = @_;
    
    my %add_params = (
	action   => 'create',
	add      => 'submit',
	notify 	 => 'no',
    );
    
    my %params = (%$params, %add_params);

    my $responce = $self->directadmin->query(
	params         => \%params,
	command        => 'CMD_API_ACCOUNT_USER',
	allowed_fields =>
	   'action
	    add
	    notify
	    username
	    domain
	    passwd
	    passwd2
	    package
	    ip
	    email',
    );

    carp "Creating account: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;
}

# Suspend user
# params: select0
sub disable {
    my ($self, $params ) = @_;
     
     my %add_params = (
	suspend	 => 'Suspend',
	location => 'CMD_SELECT_USERS',
    );
    
    my %params = (%$params, %add_params);
    
     my $responce = $self->directadmin->query(
	command        => 'CMD_API_SELECT_USERS',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'location
			   suspend
			   select0',
    );

    carp "Suspend account: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;
}

# Unsuspend user
# params: select0
sub enable {
    my ($self, $params ) = @_;
     
     my %add_params = (
	suspend	 => 'Unsuspend',
	location => 'CMD_SELECT_USERS',
    );
    
    my %params = (%$params, %add_params);
    
    my $responce = $self->directadmin->query(
	command        => 'CMD_API_SELECT_USERS',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'location
			   suspend
			   select0',
    );

    carp "Unsuspend account: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;    
    
}

# Delete user
# params: select0
sub delete {
    my ($self, $params ) = @_;
     
     my %add_params = (
	confirmed => 'Confirm',
	delete    => 'yes',
    );
    
    my %params = (%$params, %add_params);

    my $responce = $self->directadmin->query(
	command        => 'CMD_API_SELECT_USERS',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'confirmed
			   delete
			   select0',
    );

    carp "Delete account: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;
}

# Change passwd
# params: username, passwd, passwd2
sub change_password {
    my ($self, $params ) = @_;

    my $responce = $self->directadmin->query(
	command        => 'CMD_API_USER_PASSWD',
	method	       => 'POST',
	params         => $params,
	allowed_fields => 'passwd
			   passwd2
			   username',
    );

    carp "Change passwd account: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;
}

# Change package for user
# params: user, package
sub change_package {
    my ($self, $params ) = @_;
    
    my $package = $params->{package};

    unless ( $self->{fake_answer} ) {
	unless ( $package ~~ $self->show_packages() ) {
	    return {error => 1, text => "No such package $package on server"};
	} 
    }
    
    my %add_params = (
	action => 'package',
    );
    
    my %params = (%$params, %add_params);
    
    my $responce = $self->directadmin->query(
	command        => 'CMD_API_MODIFY_USER',
	method	       => 'POST',
	params         => \%params,
	allowed_fields => 'action
			   package
			   user',
    );
    
    carp "Change package: $responce->{text}, $responce->{details}" if $self->{debug};
    return $responce;
}

# Show a list of user packages
# no params
sub show_packages {
    my ($self ) = @_;

    my $responce = $self->directadmin->query(
	command => 'CMD_API_PACKAGES_USER',
    )->{list};

    return $responce;
}

# Show user config
# params: user
sub show_user_config {
    my ( $self, $params ) = @_;

    my $responce = $self->directadmin->query(
	command => 'CMD_API_SHOW_USER_CONFIG',
	params  => $params,
	allowed_fields => 'user',
    );

    return $responce;
}

1;
