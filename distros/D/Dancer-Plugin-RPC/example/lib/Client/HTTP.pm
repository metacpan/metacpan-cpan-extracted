package Client::HTTP;
use Moo::Role;

with 'MooseX::Log::Log4perl::Easy';

use Scalar::Util 'blessed';
use URI;
use HTTP::Tiny;

our $VERSION = '0.90';

has base_uri => (
    is  => 'ro',
    isa => sub {
        die "Invalid URI ($_[0])" unless blessed($_[0]) =~ m{^URI::https?$};
    },
    coerce => sub { return URI->new($_[0]); }
);
has client => (
    is  => 'lazy',
    isa => sub { die "Invalid user-agent" unless blessed($_[0]) eq 'HTTP::Tiny' },
);
has ssl_opts => (
    is      => 'ro',
    default => undef
);
has timeout => (
    is      => 'ro',
    default => 300
);

requires 'call';

sub _build_client {
    my $self = shift;
    return HTTP::Tiny->new(
        agent      => "Dancer-Plugin-RPC-do-rpc/$VERSION",
        verify_SSL => 0,
        timeout    => $self->timeout,
    );
}

1;

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
