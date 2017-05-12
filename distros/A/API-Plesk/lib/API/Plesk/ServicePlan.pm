
package API::Plesk::ServicePlan;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use base 'API::Plesk::Component';

my @header_fields = qw(
    owner-id
    owner-login
);

my @other_fields = qw(
    mail
    limits
    log-rotation
    preferences
    hosting
    performance
    permissions
    external-id
    name
);

my @main_fields = ( @header_fields, @other_fields );

sub get {
    my ($self, %params) = @_;
    my $bulk_send = delete $params{bulk_send};

    my $filter = delete $params{filter} || '';
    my $data = [
        { filter => $filter },
        @{ $self->sort_params( \%params, @main_fields ) },
    ];

    return $bulk_send ? $data : 
        $self->plesk->send('service-plan', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    my $filter    = delete $params{filter} || '';
    
    $self->check_hosting(\%params);

    my $data = [
        { filter  => $filter },
        @{$self->sort_params(\%params, @main_fields)},
    ];

    return $bulk_send ? $data : 
        $self->plesk->send('service-plan', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('service-plan', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::ServicePlan -  Managing service plans.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->service_plan->get(...);
    $response = $api->service_plan->set(...);
    $response = $api->service_plan->del(...);

=head1 DESCRIPTION

Module manage service plans.

=head1 METHODS

=over 3

=item get(%params)

=item setarams)

=item del(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut

