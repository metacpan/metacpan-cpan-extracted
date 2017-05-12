
package API::Plesk::SiteBuilder;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

#TODO
sub assign_trial_site {
    my ( $self, %params ) = @_;
    my $bulk_send = delete $params{bulk_send};

    $self->check_required_params(\%params, qw(pp-site-guid sb-site-uuid));
    
    return $bulk_send ? \%params : 
        $self->plesk->send('sitebuilder', 'assign-trial-site', \%params);
}

1;

__END__

=head1 NAME

API::Plesk::SiteBuilder -  Managing SiteBuilder sites.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->sitebuilder->assign_trial_site(...);

=head1 DESCRIPTION

Module manage SiteBuilder sites.

=head1 METHODS

=over 3

=item assign_trial_site(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
