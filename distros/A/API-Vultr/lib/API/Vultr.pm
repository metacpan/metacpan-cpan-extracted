package API::Vultr;

use 5.008;

use strict;
use warnings;

use Carp qw(croak);
use URI  qw();

our $VERSION = '0.001';

sub _make_uri {
    my ( $self, $path, %query ) = @_;

    my $uri = URI->new( 'https://api.vultr.com/v2' . $path );
    if (%query) {
        $uri->query_form(%query);
    }

    return $uri->as_string;
}

sub _request {
    my ( $self, $method, $uri, $body ) = @_;

    if ( not( defined $body ) ) {
        my $lc_method = lc $method;
        return $self->ua->$lc_method( $uri,
            Authorization => 'Bearer ' . $self->{api_key} );
    }
    else {
        my $request = HTTP::Request->new( uc $method, $uri );
        $request->header( 'Content-Type' => 'application/json' );
        $request->content($body);
        return $self->ua->request($request);
    }
}

sub api_key {
    my ( $self, $setter ) = @_;

    if ( defined $setter ) {
        return $self->{api_key} = $setter;
    }

    return $self->{api_key};
}

sub ua {
    my ( $self, $setter ) = @_;

    if ( defined $setter ) {
        return $self->{ua} = $setter;
    }

    return $self->{ua};
}

sub new {
    my ( $class, %args ) = @_;

    croak
      qq{You must specify an API key when creating an instance of API::Vultr}
      unless exists $args{api_key};

    my $self = { %args, ua => LWP::UserAgent->new( timeout => 10 ) };

    return bless( $self, __PACKAGE__ );
}

# ACCOUNT #

sub get_account_info {
    my $self = shift;
    return $self->_request( 'get', $self->_make_uri('/account') );
}

# APPLICATIONS #

sub get_applications {
    my $self = shift;
    return $self->_request( 'get', $self->_make_uri('/applications') );
}

# BACKUPS #

sub get_backups {
    my ( $self, %query ) = @_;
    return $self->_request( 'get', $self->_make_uri( '/backups', %query ) );
}

sub get_backup_by_id {
    my ( $self, $id ) = @_;
    return $self->_request( 'get', $self->_make_uri( '/backups/' . $id ) );
}

# INSTANCES #

sub list_instances {
    my ( $self, %query ) = @_;
    return $self->_request( 'get', $self->_make_uri( '/instances', %query ) );
}

sub create_instance {
    my ( $self, %body ) = @_;
    return $self->_request( 'post', $self->_make_uri('/instances'), {%body} );
}

sub get_instance_by_id {
    my ( $self, $id ) = @_;

    croak qq{ID cannot be undefined when calling get_instance_by_id.}
      unless defined $id;

    return $self->_request( 'get', $self->_make_uri( '/instances/' . $id ) );
}

sub delete_instance_by_id {
    my ( $self, $id ) = @_;

    croak qq{ID cannot be undefined when calling get_instance_by_id.}
      unless defined $id;

    return $self->_request( 'delete', $self->_make_uri( '/instances/' . $id ) );
}

sub halt_instances {
    my ( $self, @ids ) = @_;

    croak qq{Expected list of ids, instead got undef.}
      unless @ids;

    return $self->_request(
        'post',
        $self->_make_uri('/instances/halt'),
        { instance_ids => [@ids] }
    );
}

sub reboot_instances {
    my ( $self, @ids ) = @_;

    croak qq{Expected list of ids, instead got undef.}
      unless @ids;

    return $self->_request(
        'post',
        $self->_make_uri('/instances/reboot'),
        { instance_ids => [@ids] }
    );
}

sub start_instances {
    my ( $self, @ids ) = @_;

    croak qq{Expected list of ids, instead got undef.}
      unless @ids;

    return $self->_request(
        'post',
        $self->_make_uri('/instances/start'),
        { instance_ids => [@ids] }
    );
}

sub get_instance_bandwidth {
    my ( $self, $id, %query ) = @_;

    croak qq{Expected scalar id as second argument, instead got $id.}
      unless defined $id;

    return $self->_request( 'get',
        $self->_make_uri( '/instances/' . $id . '/bandwidth', %query ) );
}

sub get_instance_neighbours {
    my ( $self, $id ) = @_;

    croak qq{Expected scalar id as second argument, instead got $id.}
      unless defined $id;

    return $self->_request( 'get',
        $self->_make_uri( '/instances/' . $id . '/neighbours' ) );
}

sub get_instance_iso_status {
    my ( $self, $id ) = @_;

    croak qq{Expected scalar id as second argument, instead got $id.}
      unless defined $id;

    return $self->_request( 'get',
        $self->_make_uri( '/instances/' . $id . '/iso' ) );
}

sub detach_iso_from_instance {
    my ( $self, $id ) = @_;

    croak qq{Expected scalar id as second argument, instead got $id.}
      unless defined $id;

    return $self->_request( 'post',
        $self->_make_uri( '/instances/' . $id . '/iso/detach' ) );
}

sub attach_iso_to_instance {
    my ( $self, $id, $iso_id ) = @_;

    croak qq{Expected scalar id as second argument, instead got $id.}
      unless defined $id;

    croak qq{Expected scalar iso_id as second argument, instead got $iso_id.}
      unless defined $iso_id;

    return $self->_request(
        'post',
        $self->_make_uri( '/instances/' . $id . '/iso/attach' ),
        { iso_id => $iso_id }
    );
}

# ISO #

sub get_isos {
    my ( $self, %query ) = @_;
    return $self->_request( $self->_make_uri( '/iso', %query ) );
}

sub create_iso {
    my ( $self, %body ) = @_;
    return $self->_request( $self->_make_uri('/iso'), {%body} );
}

1;

=encoding utf8

=head1 Name

API::Vultr

=head1 Synopsis

A simple, and inuitive interface to the L<Vultr Api|https://https://www.vultr.com/api> using L<LWP::UserAgent>.

This does not cover the entire Vultr API, but instead intends to be very
extendible allowing for easy contributions. Basically, I have what I need,
if you need more feel free to add it!

=head1 Example

    use API::Vultr;
    use Data::Dumper qw(Dumper);

    my $vultr_api = API::Vultr->new(api_key => $ENV{VULTR_API_KEY});

    my $create_response = $vultr_api->create_instance(
        region => 'ewr',
        plan => 'vc2-6c-16gb',
        label => 'My Instance',
        os_id => 215,
        user_data => 'QmFzZTY4EVsw32WfsGGHsjKJI',
        backups => 'enabled',
        hostname => 'hostname'
    );

    if ($create_response->is_success) {
        print Dumper($create_response->decoded_content);
    }
    else {
        die $create_response->status_line;
    }

=head1 API

=head2 ua

Set, or get the L<LWP::UserAgent> associated L<API::Vultr> instance.

=head2 api_key

Set, or get the Vultr API key associated with the L<API::Vultr> instance.

=head2 get_account_info

Retrieve the account information associated with your API key.

L<Vultr API Reference|https://www.vultr.com/api/#tag/account/operation/get-account>

=head2 get_applications

Retrieve applications associated with your API key.

L<Vultr API Reference|https://www.vultr.com/api/#tag/application/operation/list-applications>

=head2 get_backups

Get a list of all backups associated with your API key.

L<Vultr API Reference|https://www.vultr.com/api/#tag/backup/operation/list-backups>

=head2 get_backup_by_id

Get information on a specific backup by its id.

L<Vultr API Reference|https://www.vultr.com/api/#tag/backup/operation/get-backup>

=head2 list_instances

Get a list of all instances associated with your API key.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/list-instances>

=head2 create_instance

Create a Vultr instance.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/create-instance>

=head2 get_instance_by_id

Find an instance by its id.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/get-instance>

=head2 delete_instance_by_id

Delete an instance by its id.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/delete-instance>

=head2 halt_instances

Halt a list of instances by their ids.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/halt-instances>

=head2 reboot_instances

Reboot a list of instances by their ids.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/reboot-instances>

=head2 start_instances

Reboot a list of instances by their ids.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/start-instances>

=head2 get_instance_bandwidth

Get the remaining bandwidth of a given instance.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/get-instance-bandwidth>

=head2 get_instance_neighbours

Get a list of instances in the same location as the specified instance.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/get-instance-neighbors>

=head2 get_instance_iso_status

Get the ISO status for an instance.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/get-instance-iso-status>

=head2 detach_iso_from_instance

Detach an ISO from a specified instance.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/detach-instance-iso>

=head2 attach_iso_to_instance

Attach an ISO to a specified instance.

L<Vultr API Reference|https://www.vultr.com/api/#tag/instances/operation/attach-instance-iso>

=cut
