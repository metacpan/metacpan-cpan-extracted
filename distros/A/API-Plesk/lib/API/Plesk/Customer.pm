
package API::Plesk::Customer;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

my @gen_info_fields = qw(
    cname
    pname
    login
    passwd
    status
    phone
    fax
    email
    address 
    city 
    state
    pcode
    country 
    owner-id
);

sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $gen_info  = $params{gen_info} || confess "Required gen_info parameter!";

    $self->check_required_params($gen_info, qw(pname login passwd));
    
    my $data = {
        gen_info => $self->sort_params($params{gen_info}, @gen_info_fields)
    };

    return $bulk_send ? $data : 
        $self->plesk->send('customer', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = { 
        filter => @_ > 2 ? \%filter : '',
        dataset => [ {gen_info => ''}, {stat => ''} ]
    };

    return $bulk_send ? $data : 
        $self->plesk->send('customer', 'get', $data);
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
        $self->plesk->send('customer', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('customer', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Customer -  Managing customer accounts.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->customer->add(..);
    $response = $api->customer->get(..);
    $response = $api->customer->set(..);
    $response = $api->customer->del(..);

=head1 DESCRIPTION

Module manage customer accounts.

=head1 METHODS

=over 3

=item add(%params)

Method adds customer to Plesk Panel.

    %params = (
        # required
        gen_info => {
            pname => 'Mike',
            login => 'mike',
            passwd => '12345',
            ...            
        }
    );

=item get(%params)

Method gets customer data.

    %params = (
        filter => {...}
    );

=item set(%params)

Method sets customer data.

    %params = (
        filter   => {...},
        gen_info => {...}
    );

=item del(%params)

Method deletes customer from Plesk Panel.

    %params = (
        filter => {...}
    );

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
