
package API::Plesk::User;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

my @gen_info_fields = qw(
    cname
    login
    passwd
    owner-guid
    owner-external-id
    name
    contact-info
    status
    external-id
);

sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $gen_info  = $params{gen_info} || confess "Required gen_info parameter!";
    my $roles  = $params{roles} || confess "Required roles parameter!";

    $self->check_required_params($gen_info, qw(name login passwd));
    
    my $unsorteddata = {
        'gen-info' => $self->sort_params($params{gen_info}, @gen_info_fields),
        roles => $roles,
    };
    my $data = $self->sort_params($unsorteddata, qw(gen-info roles));

    return $bulk_send ? $data : 
        $self->plesk->send('user', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = { 
        filter => @_ > 2 ? \%filter : '',
        dataset => [ {'gen-info' => ''}, {roles => ''} ]
    };

    return $bulk_send ? $data : 
        $self->plesk->send('user', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $filter    = $params{filter}   || '';
    my $gen_info  = $params{gen_info} || '';

    $gen_info || confess "Required gen_info or stat parameter!";

    my $data = {
        filter  => $filter,
        values => {
            gen_info => $gen_info,
        }
    };

    return $bulk_send ? $data :
        $self->plesk->send('user', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('user', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Customer -  Managing user (e.g. auxiliary) accounts.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->user->add(..);
    $response = $api->user->get(..);
    $response = $api->user->set(..);
    $response = $api->user->del(..);

=head1 DESCRIPTION

Module manage user (e.g. auxiliary) accounts.

Filters used by get,del etc. are as follows:
%filter => {
        guid => xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        # or
        owner-guid => xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        # or
        external-id => xx
        # or
        owner-external-id => xx
}


=head1 METHODS

=over 3

=item add(%params)

Method adds users to Plesk Panel.

    %params = (
        # required
        gen_info => {
            login => 'mike', # required
            passwd => '12345', # required
            name => 'Mike', # required
            owner-guid => # one of this or
            owner-external-id => # this required
            ...    
        }
        # required
        roles => {
            name => 'WebMaster',
            ...
    );

=item get(%params)

Method gets user data.

    %params = ( %filter );

=item set(%params)

Method sets user data.

    %params = (
        filter   => {...},
        gen_info => {...}
    );

=item del(%params)

Method deletes user from Plesk Panel.

    %params = ( %filter );

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
