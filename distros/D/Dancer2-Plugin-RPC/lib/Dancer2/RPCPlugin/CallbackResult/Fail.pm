package Dancer2::RPCPlugin::CallbackResult::Fail;
use Moo;

our $VERSION = '2.00';

with 'Dancer2::RPCPlugin::CallbackResult';

=head1 NAME

Dancer2::RPCPlugin::CallbackResult::Fail - Class for failure

=head2 new()

Constructor, allows named arguments:

=over

=item error_code => $code

=item error_message => $message

=item success => 0

=back

=cut

has error_code => (
    is       => 'ro',
    isa      => sub { $_[0] =~ /^[+-]?\d+$/ },
    required => 1,
);
has error_message => (
    is       => 'ro',
    required => 1,
);
has success => (
    is      => 'ro',
    isa     => sub { $_[0] == 0 },
    default => 0,
);

sub _as_string {
    my $self = shift;
    return sprintf("fail (%s => %s)", $self->error_code, $self->error_message);
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
