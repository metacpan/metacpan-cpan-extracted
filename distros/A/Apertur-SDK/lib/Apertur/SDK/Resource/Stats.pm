package Apertur::SDK::Resource::Stats;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub get {
    my ($self) = @_;
    return $self->{http}->request('GET', '/api/v1/stats');
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Stats - Account statistics

=head1 DESCRIPTION

Retrieves account-level usage statistics.

=head1 METHODS

=over 4

=item B<get()>

Returns a hashref with usage statistics for the authenticated account.

=back

=cut
