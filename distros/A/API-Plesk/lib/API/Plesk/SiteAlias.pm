
package API::Plesk::SiteAlias;

use strict;
use warnings;

use Carp;

use base 'API::Plesk::Component';

#TODO
sub create {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, [qw(site-id name)]);

    return $bulk_send ? \%params : 
        $self->plesk->send('site-alias', 'create', \%params);
}

sub get {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send};

    my $data = { 
        filter  => @_ > 2 ? \%filter : '',
    };

    return $bulk_send ? $data : 
        $self->plesk->send('site-alias', 'get', $data);
}

sub set {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send}; 
    
    return $bulk_send ? \%params : 
        $self->plesk->send('site-alias', 'set', \%params);
}

sub del {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    my $data = {
        filter  => @_ > 2 ? \%filter : ''
    };

    return $bulk_send ? $data : 
        $self->plesk->send('site-alias', 'del', $data);
}

1;

__END__

=head1 NAME

API::Plesk::SiteAlias -  Managing site aliases.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->site_alias->get(..);

=head1 DESCRIPTION

Module manage sites (domains).

=head1 METHODS

=over 3

=item create(%params)

=item get(%params)

=item set(%params)

=item del(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
