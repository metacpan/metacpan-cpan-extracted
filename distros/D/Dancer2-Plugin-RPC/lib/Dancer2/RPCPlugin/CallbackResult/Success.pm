package Dancer2::RPCPlugin::CallbackResult::Success;
use Moo;

our $VERSION = '2.00';

with 'Dancer2::RPCPlugin::CallbackResult';

has success => (
    is      => 'ro',
    isa     => sub { $_[0] == 1 },
    default => 1,
);

=head1 NAME

Dancer2::RPCPlugin::CallbackResult::Success - Class for success

=head1 DESCRIPTION

=head2 new()

Constructor, does not allow any arguments.

=head2 success()

Returns 1;

=cut

sub _as_string {
    my $self = shift;
    return "success";
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

E<copy> MMXXII - Abe Timmerman <abeltje@cpan.org>

=cut
