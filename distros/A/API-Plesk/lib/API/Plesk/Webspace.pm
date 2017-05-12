
package API::Plesk::Webspace;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

my @gen_setup_fields = qw(
    name
    owner-id
    owner-login
    owner-guid
    owner-external-id
    htype
    ip_address
    status
    external-id
);

my @main_fields = qw(
    gen_setup
    hosting    
    limits     
    prefs      
    performance
    permissions
    plan-id
    plan-name
    plan-guid
    plan-external-id
);

sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};
    my $gen_setup = $params{gen_setup} || confess "Required gen_setup parameter!";

    $self->check_hosting(\%params);

    $self->check_required_params(\%params, [qw(plan-id plan-name plan-guid plan-external-id)]);
    $self->check_required_params($gen_setup, qw(name ip_address));

    $params{gen_setup} = $self->sort_params($gen_setup, @gen_setup_fields);
    
    my $data = $self->sort_params(\%params, @main_fields);

    return $bulk_send ? $data :
        $self->plesk->send('webspace', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $dataset   = {gen_info => ''};
    
    if ( my $add = delete $filter{dataset} ) {
        $dataset = { map { ( $_ => '' ) } ref $add ? @$add : ($add) };
        $dataset->{gen_info} = '';
    }

    my $data = { 
        filter  => @_ > 2 ? \%filter : '',
        dataset => $dataset,
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    my $filter    = delete $params{filter} || '';
    my $gen_setup = $params{gen_setup};
    
    $params{gen_setup} = $self->sort_params($gen_setup, @gen_setup_fields) if $gen_setup;
    $self->check_hosting(\%params);

    my $data = [
        { filter  => $filter },
        { values  => $self->sort_params(\%params, @main_fields) },
    ];

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'del', $data);
}

sub add_plan_item {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    my $filter    = delete $params{filter} || '';

    my $name = $params{name} || confess "Required name field!";    
    my $data = {
        filter      => $filter,
        'plan-item' => { name => $name },
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'add-plan-item', $data);
}

sub add_subscription {
    my ($self, %params) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    
    $self->check_required_params(\%params, [qw(plan-guid plan-external-id)]);

    my $data = $self->sort_params(\%params, 'filter', [qw(plan-guid plan-external-id)]);

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'add-subscription', $data);
}

sub remove_subscription {
    my ($self, %params) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    
    $params{filter} ||= '';

    $self->check_required_params(\%params, [qw(plan-guid plan-external-id)]);

    my $data = $self->sort_params(\%params, 'filter', [qw(plan-guid plan-external-id)]);

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'remove-subscription', $data);
}

sub switch_subscription {
    my ($self, %params) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    
    $params{filter} ||= '';

    $self->check_required_params(\%params, [qw(plan-guid plan-external-id no-plan)]);

    my $data = $self->sort_params(\%params, 'filter', [qw(plan-guid plan-external-id no-plan)]);

    return $bulk_send ? $data : 
        $self->plesk->send('webspace', 'switch-subscription', $data);
}


1;

__END__

=head1 NAME

API::Plesk::Webspace -  Managing subscriptions (webspaces).

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->webspace->add(..);
    $response = $api->webspace->del(..);

=head1 DESCRIPTION

Module manage subscriptions (webspaces).

=head1 METHODS

=over 3

=item add(%params)

=item get(%params)

=item set(%params)

=item del(%params)

=item add_plan_item(%params)

=item add_subscription(%params)

=item remove_subscription(%params)

=item switch_subscription(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
