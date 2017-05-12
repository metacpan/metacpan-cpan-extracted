package Catalyst::Plugin::Authentication::Credential::HTTP::User;

use base 'LWP::UserAgent';

sub credentials {
   my ($self,$user,$pass)=@_;
   @{$self->{credentials}}=($user,$pass);
}
sub get_basic_credentials {
    my $self = shift;
    return @{$self->{credentials}};
}

1;

=head1 NAME

Catalyst::Plugin::Authentication::Credential::HTTP::User - Wrapper for LWP::UserAgent

=head1 DESCRIPTION

A thin wrapper for L<LWP::UserAgent> to make basic auth simpler.

=head1 METHODS

=head2 credentials

now takes just a username and password

=head2 get_basic_credentials

Returns the set credentials, takes no options.

=head1 AUTHOR

Marcus Ramberg <mramberg@cpan.org

=head1 LICENSE

This software is licensed under the same terms as perl itself.
