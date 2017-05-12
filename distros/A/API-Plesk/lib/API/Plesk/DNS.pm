
package API::Plesk::DNS;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

sub add_rec {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    my @fields = (
        [qw(site-id site-alias-id)],
        'type',
        'host',
        'value'
    );

    $self->check_required_params(\%params, @fields);
    my $data = $self->sort_params(\%params, @fields, 'opt');

    return $bulk_send ? $data : 
        $self->plesk->send('dns', 'add_rec', $data);
}

sub get_rec {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $template = delete $filter{template};
    

    my $data = [
        { filter  => @_ > 2 ? \%filter : '' },
        ( $template ? {template => $template} : () ),
    ];

    return $bulk_send ? $data : 
        $self->plesk->send('dns', 'get_rec', $data);
}

sub del_rec {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $template = delete $filter{template};

    my $data = [
        { filter  => $self->prepare_filter(\%filter) },
        ( $template ? {template => $template} : () ),
    ];

    return $bulk_send ? $data : 
        $self->plesk->send('dns', 'del_rec', $data);
}

sub get_soa {
    my ( $self, %filter ) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = [
        { filter  => @_ > 2 ? \%filter : '' }
    ];

    return $bulk_send ? $data : 
        $self->plesk->send('dns', 'get', $data);
}

1;
