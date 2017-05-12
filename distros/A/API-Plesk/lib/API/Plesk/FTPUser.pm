
package API::Plesk::FTPUser;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

#TODO
sub add {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    my @sort_fields = (
        'name',
        'password',
        'home',
        'create_non_existent',
        'quota',
        'permissions',
        [qw(site-id site-name)],        
    );
    my @required_fields = (
        'name',
        'password',
        [qw(site-id site-name)],        
    );

    $self->check_required_params(\%params, @required_fields);
    
    my $data = $self->sort_params(\%params, @sort_fields);

    return $bulk_send ? $data : 
        $self->plesk->send('ftp-user', 'add', $data);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};
    my $data = { 
        filter  => @_ > 2 ? \%filter : '',
    };

    return $bulk_send ? $data : 
        $self->plesk->send('ftp-user', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    my $filter    = delete $params{filter} || '';
   
     my @sort_fields = (
        'name',
        'password',
        'home',
        'create_non_existent',
        'quota',
        'permissions',
    );

    my $data = {
        filter  => $filter,
        values  => $self->sort_params(\%params, @sort_fields),
    };

    return $bulk_send ? $data : 
        $self->plesk->send('ftp-user', 'set', $data);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('ftl-user', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::Site -  Managing sites (domains).

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->site->get(..);

=head1 DESCRIPTION

Module manage sites (domains).

=head1 METHODS

=over 3

=item add(%params)

=item get(%params)

=item set(%params)

=item del(%params)

=item get_physical_hosting_descriptor(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
