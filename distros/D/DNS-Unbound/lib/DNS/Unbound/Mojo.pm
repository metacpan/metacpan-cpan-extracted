package DNS::Unbound::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound::Mojo - L<DNS::Unbound> for L<Mojolicious>

=head1 SYNOPSIS

    my $unbound = DNS::Unbound::Mojo->new();

    $unbound->resolve_p("perl.org", "A")->then(
        sub {
            my $result = shift;

            # ...
        }
    )->wait();

=head1 DESCRIPTION

This class provides native L<Mojolicious> compatibility for L<DNS::Unbound>.

In particular:

=over

=item * C<resolve_p()> is an alias for C<resolve_async()>.

=item * Returned promises subclass L<Mojo::Promise> (rather than
L<Promise::ES6>) by default.

=back

=cut

#----------------------------------------------------------------------

use parent (
    'DNS::Unbound::EventLoopBase',
    'DNS::Unbound::FDFHStorer',
);

use DNS::Unbound::AsyncQuery::MojoPromise ();

use Mojo::IOLoop ();
use Mojo::Promise ();

# perl -MData::Dumper -MDNS::Unbound::Mojo -e'DNS::Unbound::Mojo->new()->resolve_async("perl.org", "A")->then( sub { print Dumper shift } )->wait()'

my %INSTANCE_HANDLE;

use constant _DEFAULT_PROMISE_ENGINE => 'Mojo::Promise';

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    my $fh = $self->_get_fh();

    Mojo::IOLoop->singleton()->reactor()->io(
        $fh,
        $self->_create_process_cr(),
    )->watch($fh, 1, 0);

    $INSTANCE_HANDLE{$self} = $fh;

    return $self;
}

*resolve_p = __PACKAGE__->can('resolve_async');

sub DESTROY {
    my ($self) = @_;

    my $fh = delete $INSTANCE_HANDLE{$self};

    Mojo::IOLoop->singleton()->reactor()->remove($fh) if $fh;

    return $self->SUPER::DESTROY();
}

1;
