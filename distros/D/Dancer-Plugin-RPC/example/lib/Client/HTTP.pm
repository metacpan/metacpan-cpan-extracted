package Client::HTTP;
use Moo::Role;
use Types::Standard qw( InstanceOf Maybe HashRef Int );

with 'MooseX::Log::Log4perl::Easy';

use URI;
use HTTP::Tiny;

our $VERSION = '0.90';

has base_uri => (
    is     => 'ro',
    isa    => InstanceOf ['URI::http', 'URI::https'],
    coerce => sub { return URI->new($_[0]); }
);
has client => (
    is  => 'lazy',
    isa => InstanceOf['HTTP::Tiny'],
);
has ssl_opts => (
    is      => 'ro',
    isa     => Maybe[HashRef],
    default => undef
);
has timeout => (
    is      => 'ro',
    isa     => Int,
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

use namespace::autoclean;
1;

=head1 COPYRIGHT

(c) MMXVII - Abe Timmerman <abeltje@cpan.org>

=cut
