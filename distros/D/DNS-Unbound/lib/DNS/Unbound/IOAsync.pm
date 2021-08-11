package DNS::Unbound::IOAsync;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

DNS::Unbound::IOAsync - L<DNS::Unbound> for L<IO::Async>

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new();

    my $unbound = DNS::Unbound::IOAsync->new($loop);

    $unbound->resolve_async("perl.org", "A")->then(
        sub {
            my $result = shift;

            # ...
        }
    )->finally( sub { $loop->stop() } );

    $loop->run();

=head1 DESCRIPTION

This class provides native L<IO::Async> compatibility for L<DNS::Unbound>.

Note that this class’s C<new()> requires an L<IO::Async::Loop> instance
to be passed. (See the L</SYNOPSIS>.)

=cut

#----------------------------------------------------------------------

use parent (
    'DNS::Unbound::EventLoopBase',
    'DNS::Unbound::FDFHStorer',
);

use IO::Async::Handle ();

my %INSTANCE_LOOP;
my %INSTANCE_HANDLE;

# perl -MData::Dumper -MIO::Async::Loop -MDNS::Unbound::IOAsync -e'my $loop = IO::Async::Loop->new(); DNS::Unbound::IOAsync->new($loop)->resolve_async("perl.org", "A")->then( sub { print Dumper shift } )->finally( sub { $loop->stop() } ); $loop->run()'

sub new {
    my ($class, $loop, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $INSTANCE_LOOP{$self} = $loop;

    my $handle = IO::Async::Handle->new(
        read_handle => $self->_get_fh(),
        on_read_ready => $self->_create_process_cr(),
    );
    $INSTANCE_HANDLE{$self} = $handle;

    $loop->add($handle);

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    delete $INSTANCE_LOOP{$self};
    delete $INSTANCE_HANDLE{$self};

    return $self->SUPER::DESTROY();
}

1;
