package API::DirectAdmin;

use Modern::Perl '2010';
use LWP::UserAgent;
use HTTP::Request;
use Data::Dumper;
use Carp;
use URI;

our $VERSION = 0.09;
our $DEBUG   = '';
our $FAKE_ANSWER = '';

# for init subclasses
init_components(
    domain => 'Domain',
    mysql  => 'Mysql',
    user   => 'User',
    dns    => 'DNS',
    ip     => 'Ip',
);

# init
sub new {
    my $class = shift;
    $class = ref ($class) || $class;
    
    my $self = {
        auth_user   => '',
        auth_passwd => '',
        host        => '',
        ip          => '',
        debug       => $DEBUG,
	    allow_https => 1,
	    fake_answer => $FAKE_ANSWER,
        (@_)
    };

    confess "Required auth_user!"   unless $self->{auth_user};
    confess "Required auth_passwd!" unless $self->{auth_passwd};
    confess "Required host!"        unless $self->{host};

    return bless $self, $class;
}

# initialize components
sub init_components {
    my ( %c ) = @_;
    my $caller = caller;

    for my $alias (  keys %c ) {

        my $item = $c{$alias};

        my $sub = sub {
            my( $self ) = @_;
            $self->{"_$alias"} ||= $self->load_component($item);
            return $self->{"_$alias"} || confess "Not implemented!";
        };
        
        no strict 'refs';
 
        *{"$caller\::$alias"} = $sub;
    }
}

# loads component package and creates object
sub load_component {
    my ( $self, $item ) = @_;

    my $pkg = ref($self) . '::' . $item;

    my $module = "$pkg.pm";
       $module =~ s/::/\//g;

    local $@;
    eval { require $module };
    if ( $@ ) {
	confess "Failed to load $pkg: $@";
    }

    return $pkg->new(directadmin => $self);

}

# Filter hash
# STATIC(HASHREF: hash, ARRREF: allowed_keys)
# RETURN: hashref only with allowed keys
sub filter_hash {
    my ($self, $hash, $allowed_keys) = @_;
    
    return {} unless defined $hash;
    
    confess "Wrong params" unless ref $hash eq 'HASH' && ref $allowed_keys eq 'ARRAY';

    my $new_hash = { };

    foreach my $allowed_key (@$allowed_keys) {
        if (exists $hash->{$allowed_key}) {
            $new_hash->{$allowed_key} = $hash->{$allowed_key};
        }
        elsif (exists $hash->{lc $allowed_key}) {
            $new_hash->{$allowed_key} = $hash->{lc $allowed_key};
        };
    }

    return $new_hash;
}

# all params derived from get_auth_hash
sub query {
    my ( $self, %params ) = @_;

    my $command   = delete $params{command};
    my $fields    = $params{allowed_fields} || '';

    my $allowed_fields;
    warn 'query_abstract ' . Dumper( \%params ) if $self->{debug};

    confess "Empty command" unless $command;

    $fields = "host port auth_user auth_passwd method allow_https command $fields";
    @$allowed_fields = split /\s+/, $fields;

    my $params = $self->filter_hash( $params{params}, $allowed_fields );

    my $query_string = $self->mk_full_query_string( {
        command => $command,
        %$params,
    } );

    carp Dumper $query_string if $self->{debug};
    
    my $server_answer =  $self->process_query(
        method        => $params{method} || 'GET',
        query_string  => $query_string,
        params 	      => $params,
    );
    
    carp Dumper $server_answer if $self->{debug};

    return $server_answer;
}

# Kill slashes at start / end string
# STATIC(STRING:input_string)
sub kill_start_end_slashes {
    my ($self ) = @_;

    for ( $self->{host} ) {
        s/^\/+//sgi;
        s/\/+$//sgi;
    }

    return 1;
}

# Make full query string 
# STATIC(HASHREF: params)
# params:
# host*
# port*
# param1
# param2 
# ...
sub mk_full_query_string {
    my ( $self, $params ) = @_;

    confess "Wrong params: " . Dumper( $params ) unless ref $params eq 'HASH' 
                                                        && scalar keys %$params
                                                        && $self->{host}
                                                        && $params->{command};

    my $allow_https = defined $params->{allow_https} ? $params->{allow_https} : $self->{allow_https};
    delete $params->{allow_https};
   
    my $host        = $self->{host};
    my $port        = $self->{port} || 2222;
    my $command     = delete $params->{command};
    my $auth_user   = $self->{auth_user};
    my $auth_passwd = $self->{auth_passwd};

    $self->kill_start_end_slashes();

    my $query_path = ( $allow_https ? 'https' : 'http' ) . "://$auth_user:$auth_passwd\@$host:$port/$command?";
    return $query_path . $self->mk_query_string($params);
}

# Make query string
# STATIC(HASHREF: params)
sub mk_query_string {
    my ($self, $params) = @_;

    return '' unless ref $params eq 'HASH' && scalar keys %$params;

    my %params = %$params;

    my $result = join '&', map { "$_=$params{$_}" } sort keys %params;

    return $result;
}

# Get + deparse
# STATIC(STRING: query_string)
sub process_query {
    my ( $self, %params ) = @_;

    my $query_string = $params{query_string};
    my $method 	     = $params{method};

    confess "Empty query string" unless $query_string;

    my $answer = $self->{fake_answer} ? $self->{fake_answer} : $self->mk_query_to_server( $method, $query_string, $params{params} );
    carp $answer if $self->{debug};

    return $answer;
}

# Make request to server and get answer
# STATIC (STRING: query_string)
sub mk_query_to_server {
    my ( $self, $method, $url, $params ) = @_;
    
    unless ( $method ~~ [ qw( POST GET ) ] ) {
        confess "Unknown request method: '$method'";
    }

    confess "URL is empty" unless $url;

    my $content;
    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new( $method, $url );
    
    if ( $method eq 'GET' ) {
	my $response = $ua->request( $request );
	$content = $response->content;
    }
    else { # Temporary URL for making request
	my $temp_uri = URI->new('http:');
	$temp_uri->query_form( $params );
	$request->content( $temp_uri->query );
	$request->content_type('application/x-www-form-urlencoded');
	my $response = $ua->request($request);
	$content = $response->content;
    }
    
    warn "Answer: " . $content if $self->{debug};
    
    return $content if $params->{noparse};
    return $self->parse_answer($content);
}

# Parse answer
sub parse_answer {
    my ($self, $response) = @_;

    return '' unless $response;
    
    my %answer;
    $response =~ s/&#60br&#62|&#\d+//ig; # Some trash from answer
    $response =~ s/\n+/\n/ig;
    my @params = split /&/, $response;
    
    foreach my $param ( @params ) {
	my ($key, $value) = split /=/, $param;
	if ( $key =~ /(.*)\[\]/ ) { # lists
	    push @{ $answer{$1} },  $value;
	}
	else {
	    $answer{$key} = $value;
	}
    }

    return \%answer || '';
}

1;

__END__


=head1 NAME

API::DirectAdmin - interface to the DirectAdmin Hosting Panel API ( http://www.directadmin.com )

=head1 SYNOPSIS

 use API::DirectAdmin;
 
 my %auth = (
    auth_user   => 'admin_name',
    auth_passwd => 'admin_passwd',
    host        => '11.22.33.44',
 );

 # init
 my $da = API::DirectAdmin->new(%auth);

 ### Get all panel IP
 my $ip_list = $da->ip->list();

 unless ($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list) {
    die 'Cannot get ip list from DirectAdmin';
 }

 my $ip  = $ip_list->[0];
 my $dname  = 'reg.ru';
 my $user_name = 'user1';
 my $email = 'user1@example.com';
 my $package = 'newpackage';

 my $client_creation_result = $da->user->create( {
    username => $user_name,
    passwd   => 'user_password',
    passwd2  => 'user_password',
    domain   => $dname,
    email    => $email,
    package  => $package,
    ip       => $ip,
 });

 # Switch off account:
 my $suspend_result = $da->user->disable( {
    select0 => $user_name,
 } );

 if ( $suspend_result->{error} == 1 ) {
    die "Cannot  suspend account $suspend_result->{text}";
 }



 # Switch on account
 my $resume_result = $da->user->enable( {
    select0 => $user_name,
 } );

 if ( $resume_result->{error} == 1 ) {
    die "Cannot Resume account $resume_result->{text}";
 }



 # Delete account
 my $delete_result = $da->user->delete( {
    select0 => $user_name,
 } );

 if ( $delete_result->{error} == 1 ) {
    die "Cannot delete account $delete_result->{text}";
 }
 
 # Custom request
 my %params = (
    action  => 'package',
    package => 'package_name',
    user    => 'username',
 );

 my $responce = $da->query(
    command        => 'CMD_API_MODIFY_USER',
    method	   => 'POST',
    params         => \%params,
    allowed_fields => 'action
		       package
		       user',
 );

=head1 PUBLIC METHODS

=head2 API::DirectAdmin::User

=over

=item list

Return list of users in array ref.

Example:

    my $users_list = $da->users->list();

=item create

Create a new user in DirectAdmin panel.

Example:

    my $result = $da->user->create( {
        username => 'username',
        passwd   => 'user_password',
        passwd2  => 'user_password',
        domain   => 'example.com',
        email    => 'email@example.com',
        package  => 'package_name',
        ip       => 'IP.ADD.RE.SS',
     });

=item delete

Delete DirectAdmin user and all user's data

Note: Some DirectAdmin's API methods required parameter "select0" for choose value from list. Like list of users, databases, ip, etc.

Example:

    my $result = $da->user->delete( {
	select0 => 'username',
    } );

=item disable/enable

Two different methods for disable and enable users with same params.

Example:

    my $disable_result = $da->user->disable( {
        select0 => 'username',
    } );
    
    my $enable_result = $da->user->enable( {
	   select0 => 'username',
    } );

=item change_password

Change password for user

Example:

    my $result = $da->user->change_password( {
        username => 'username',
        passwd   => 'new_password',
        passwd2  => 'new_password',
    } );

=item change_package

Change package (tariff plan) for user

Example:

    my $result = $da->user->change_package( {
        username => 'username',
        package  => 'new_package',
    } );

=item show_packages

Return list of available packages.

Note: If you created packages through administrator user - you must use admin's login and password for authorisation. Obviously, if packages was created by reseller user - use reseller authorisation.

Example:

    my $packages = $da->user->show_packages();

=item show_user_config

Return all user settings.

Example:

    my $user_config = $da->user->show_user_config({ user => 'username' });


=back

=head2 API::DirectAdmin::Domain

=over

=item list

Return list of domains on server.

Example:

    my $domains = $da->domain->list();

=item add

Add new domain to user through you connect to server.

Note: For adding domains for customers and you don't khow their password use: auth_user = 'admin_name|customer_name' in auth hash.

Example:

    my %auth = (
        auth_user   => 'admin_name|customer_name',
	auth_passwd => 'admin_passwd',
        host        => '11.22.33.44',
    );

    # init
    my $da = API::DirectAdmin->new(%auth);
    
    $result = $da->domain->add({
    	domain => 'newdomain.com',
    	php    => 'ON',
    	cgi    => 'ON',
    });

=back
    
=head2 API::DirectAdmin::Mysql

Control users mysql databases

=over

=item list

List of databases from user. Return empty array if databases not found.

Example:

    print $da->mysql->list();

=item adddb

Add database to user. Prefix "username_" will be added to 'name' and 'user';

Example:

    my %auth = (
        auth_user   => 'admin_name|customer',
        auth_passwd => 'admin_passwd',
        host        => '11.22.33.44',
    );

    # init
    my $da = API::DirectAdmin->new(%auth);
    
    my $result = $da->mysql->adddb( {
        name     => 'default', # will be 'customer_default'
        user     => 'default', # will be 'customer_default'
        passwd   => 'password',
        passwd2  => 'password',
    } );

=item deldb

Delete selected database from user.

Example:

    my $result = $da->mysql->deldb({ select0 => 'database_name' });

=back
    
=head2 API::DirectAdmin::Ip

=over

=item list

Return array reference of list ip adresses;

Example:

    my $ip_list = $da->ip->list();

=item add

Add IP address to server config

Example:

    my $result = $da->ip->add({
        ip      => '123.234.123.234',
        status  => 'server',
    });

=item remove

Remove ip from server

Example:

    my $result = $da->ip->remove({
        select0 => '123.234.123.234',
    });

=back
    
=head2 API::DirectAdmin::DNS

Show zones, add and remove records.

=over

=item dumpzone

Return zone structure for domain

Example:

    $da->dns->dumpzone( {domain => 'domain.com'} );

=item add_record

Add zone record to dns for domain. Available types of records: A, AAAA, NS, MX, TXT, PTR, CNAME, SRV

Example:

    my $result = $da->dns->add_record({
        domain => 'domain.com', 
        type   => 'A',
        name   => 'subdomain', # will be "subdomain.domain.com." in record
        value  => '127.127.127.127',
    });

Example with MX record:

    my $result = $da->dns->add_record( { 
        domain  => 'domain.com',
        type    => 'MX',
        name    => 'mx1',
        value   => 10,
    } );

=item remove_record

Remove record from domain zone

Example:

    my $result = $da->dns->remove_record({
        domain => 'domain.com',
        type   => 'A',
        name   => 'subdomain',
        value  => '127.127.127.127',
    });

Example with MX record:

    my $result = $da->dns->remove_record({
        domain => 'domain.com',
        type   => 'mx',
        name   => 'mx1',
        value  => 10,
    });

=back

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:
  Modern::Perl
  LWP::UserAgent
  HTTP::Request
  URI
  Carp 
  Data::Dumper

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012-2013 by Andrey "Chips" Kuzmin <chipsoid@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
