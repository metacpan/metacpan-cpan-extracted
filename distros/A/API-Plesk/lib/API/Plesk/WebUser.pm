
package API::Plesk::WebUser;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

#TODO
sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, qw(site-id login));

    my $data = $self->sort_params(\%params, qw(site-id login password password-type ftp-quota services));

    return $bulk_send ? $data : 
        $self->plesk->send('webuser', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = { 
        filter  => @_ > 2 ? \%filter : '',
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webuser', 'get', $data);
}

sub get_prefs {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = { 
        filter  => @_ > 2 ? \%filter : '',
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webuser', 'get-prefs', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    my $filter    = delete $params{filter} || '';
    
    my $data = {
        filter  => $filter,
        values  => $self->sort_params(\%params, qw(password password-type ftp-quota services)),
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webuser', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('webuser', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::WebUser -  Managing webusers.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->webuser->get(..);

=head1 DESCRIPTION

Module manage webusers.

=head1 METHODS

=over 3

=item add(%params)

=item get(%params)

=item get_prefs(%params)

=item set(%params)

=item del(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
