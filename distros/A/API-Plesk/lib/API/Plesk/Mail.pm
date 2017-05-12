
package API::Plesk::Mail;

use strict;
use warnings;

use Carp;
use Data::Dumper;

use base 'API::Plesk::Component';

sub enable {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    return $bulk_send ? \%filter : 
        $self->plesk->send('mail', 'enable', \%filter);
}

sub disable {
    my ($self, %filter) = @_;
    my $bulk_send = delete $filter{bulk_send}; 

    return $bulk_send ? \%filter : 
        $self->plesk->send('mail', 'disable', \%filter);
}


1;

__END__

=head1 NAME

API::Plesk::Mail -  Managing mail on Domain Level.

=head1 SYNOPSIS

    $api = API::Plesk->new(...);
    $response = $api->mail->enable(..);

=head1 DESCRIPTION

Module manage mail on Domain Level.

=head1 METHODS

=over 3

=item enable(%params)

=item disable(%params)

=back

=head1 AUTHOR

Ivan Sokolov <lt>ivsokolov@cpan.org<gt>

=cut
