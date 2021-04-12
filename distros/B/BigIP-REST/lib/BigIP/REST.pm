package BigIP::REST;

use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.1';

sub new {
    my ($class, %params) = @_;

    croak "missing url parameter" unless $params{url};

    my $url   = $params{url};
    my $agent = LWP::UserAgent->new();

    $agent->timeout($params{timeout})
        if $params{timeout};
    $agent->ssl_opts(%{$params{ssl_opts}})
        if $params{ssl_opts} && ref $params{ssl_opts} eq 'HASH';

    my $self = {
        url   => $url,
        agent => $agent
    };
    bless $self, $class;

    return $self;
}

sub create_session {
    my ($self, %params) = @_;

    croak "missing username parameter" unless $params{username};
    croak "missing password parameter" unless $params{password};

    my $result = $self->_post(
        "/mgmt/shared/authn/login",
        username          => $params{username},
        password          => $params{password},
        loginProviderName => 'tmos'
    );

    $self->{agent}->default_header('X-F5-Auth-Token' => "$result->{token}->{token}");
}

sub get_certificates {
    my ($self, %params) = @_;

    my @parameters;
    if ($params{partition}) {
        push @parameters, '$filter=partition%20eq%20' . $params{partition};
    }
    if ($params{properties}) {
        push @parameters, '$select=' . $params{properties};
    }

    my $url = "/mgmt/tm/sys/file/ssl-cert";
    if (@parameters) {
        $url .= '/?' . join('&', @parameters);
    }

    my $result = $self->_get($url);

    return $result;
}

sub get_virtual_addresses {
    my ($self, %params) = @_;

    my @parameters;
    if ($params{partition}) {
        push @parameters, '$filter=partition%20eq%20' . $params{partition};
    }
    if ($params{properties}) {
        push @parameters, '$select=' . $params{properties};
    }

    my $url = "/mgmt/tm/ltm/virtual-address";
    if (@parameters) {
        $url .= '/?' . join('&', @parameters);
    }

    my $result = $self->_get($url);

    return $result;
}

sub get_virtual_servers {
    my ($self, %params) = @_;

    my @parameters;
    if ($params{partition}) {
        push @parameters, '$filter=partition%20eq%20' . $params{partition};
    }
    if ($params{properties}) {
        push @parameters, '$select=' . $params{properties};
    }
    if ($params{expandSubcollections}) {
        push @parameters, 'expandSubcollections=' . $params{expandSubcollections};
    }

    my $url = "/mgmt/tm/ltm/virtual";
    if (@parameters) {
        $url .= '/?' . join('&', @parameters);
    }

    my $result = $self->_get($url);

    return $result;
}

sub get_pools {
    my ($self, %params) = @_;

    my @parameters;
    if ($params{partition}) {
        push @parameters, '$filter=partition%20eq%20' . $params{partition};
    }
    if ($params{properties}) {
        push @parameters, '$select=' . $params{properties};
    }

    my $url = "/mgmt/tm/ltm/pool";
    if (@parameters) {
        $url .= '/?' . join('&', @parameters);
    }

    my $result = $self->_get($url);

    return $result;
}

sub _post {
    my ($self, $path, %params) = @_;

    my $content = to_json(\%params);

    my $response = $self->{agent}->post(
        $self->{url} . $path,
        'Content-Type' => 'application/json',
        'Content'      => $content
    );

    my $result = eval { from_json($response->content()) };

    if ($response->is_success()) {
        return $result;
    } else {
        if ($result) {
            croak "server error: " . $result->{message};
        } else {
            croak "communication error: " . $response->message()
        }
    }
}

sub _get {
    my ($self, $path, %params) = @_;

    my $url = URI->new($self->{url} . $path);
    $url->query_form(%params);

    my $response = $self->{agent}->get($url);

    my $result = eval { from_json($response->content()) };

    if ($response->is_success()) {
        return $result;
    } else {
        if ($result) {
            croak "server error: " . $result->{message};
        } else {
            croak "communication error: " . $response->message()
        }
    }
}

1;
__END__

=head1 NAME

BigIP::REST - REST interface for BigIP

=head1 DESCRIPTION

This module provides a Perl interface for communication with BigIP load-balancer
using REST interface.

=head1 SYNOPSIS

    use BigIP::REST;

    my $bigip = BigIP::REST->new(
        url => 'https://my.bigip.tld'
    ):
    $bigip->create_session(
        username => 'user',
        password => 's3cr3t',
    );
    my $certs = $bigip->get_certs();

=head1 CLASS METHODS

=head2 BigIP::REST->new(url => $url, [ssl_opts => $opts, timeout => $timeout])

Creates a new L<BigIP::REST> instance.

=head1 INSTANCE METHODS

=head2 $bigip->create_session(username => $username, password => $password)

Creates a new session token for the given user.

=head2 $bigip->get_certificates([ partition => $partition, properties => $properties ])

Return the list of certificates.

Available parameters:

=over

=item partition => $partition

Filter objects list to given partition.

=item properties => $properties

Filter objects properties to the given ones, as a comma-separated list.

=back

=head2 $bigip->get_virtual_addresses([ partition => $partition, properties => $properties ])

Return the list of virtual addresses.

Available parameters:

=over

=item partition => $partition

Filter objects list to given partition.

=item properties => $properties

Filter objects properties to the given ones, as a comma-separated list.

=back

=head2 $bigip->get_virtual_servers([ partition => $partition, properties => $properties ])

Return the list of virtual servers.

Available parameters:

=over

=item partition => $partition

Filter objects list to given partition.

=item properties => $properties

Filter objects properties to the given ones, as a comma-separated list.

=back

=head2 $bigip->get_pools([ partition => $partition, properties => $properties ])

Return the list of pools.

Available parameters:

=over

=item partition => $partition

Filter objects list to given partition.

=item properties => $properties

Filter objects properties to the given ones, as a comma-separated list.

=back

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.
