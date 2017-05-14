package AnyEvent::eris::Client;
# ABSTRACT: eris pub/sub Client

use strict;
use warnings;
use Carp;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use List::Util;
use Scalar::Util;
use Parse::Syslog::Line 'parse_syslog_line';

# we recognize these
my @PROTOCOL_LINE_PREFIXES = (
    'Subscribe to :',
    'Receiving ',
    'Full feed enabled',
    'EHLO Streamer',
);

sub new {
    my ( $class, %opts ) = @_;

    my $self = bless {
        RemoteAddress  => '127.0.0.1',
        RemotePort     => 9514,
        ReturnType     => 'hash',
        Subscribe      => undef,
        Match          => undef,
        MessageHandler => undef,
        %opts,
    }, $class;

    $opts{'MessageHandler'}
        or AE::log fatal => 'You must provide a MessageHandler';

    ref $opts{'MessageHandler'} eq 'CODE'
        or AE::log fatal => 'You need to specify a subroutine reference to the \'MessageHandler\' parameter.';

    $self->_connect;

    return $self;
}

sub _connect {
    my $self = shift;

    my $block           = $self->{'ReturnType'} eq 'block';
    my $separator       = $block ? "\n" : '';
    my ( $addr, $port ) = @{$self}{qw<RemoteAddress RemotePort>};

    # FIXME: TODO item for this
    #        in second thought, this should just be removed because
    #        it's meant for internal manual buffering, which we don't need
    $block
        and AE::log fatal => 'Block option not supported';

    Scalar::Util::weaken( my $inner_self = $self );

    $self->{'_client'} ||= tcp_connect $addr, $port, sub {
        my ($fh) = @_
            or AE::log fatal => "Connect failed: $!";

        my $hdl; $hdl = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub {
                AE::log error => $_[2];
                $_[0]->destroy;
                $inner_self->{'_reconnect_timer'} = AE::timer 10, 0, sub {
                    undef $inner_self->{'_reconnect_timer'};
                    $inner_self->_connect;
                };
            },

            on_eof   => sub { $hdl->destroy; AE::log info => 'Done.' },

            on_read  => sub {
                $hdl->push_read (line => sub {
                    my ($hdl, $line) = @_;

                    List::Util::first {
                        substr( $line, 0, length $_ ) eq $_
                    } @PROTOCOL_LINE_PREFIXES and return;

                    $inner_self->handle_message( $line, $hdl );
                });
            },
        );

        $inner_self->{'buffer'} = '';

        # FIXME: should this really be in a timer?
        # all the actions relating to a socket are deferred anyway
        $inner_self->{'_setup_pipe_timer'} = AE::timer 0, 0, sub {
            undef $inner_self->{'_setup_pipe_timer'};
            $inner_self->setup_pipe($hdl);
        };
    };

    return $self;
}

sub setup_pipe {
    my ( $self, $handle ) = @_;

    # Parse for Subscriptions or Matches
    my %data;
    foreach my $target (qw(Subscribe Match)) {
        if ( defined $self->{$target} ) {
            my @data = ref $self->{$target} eq 'ARRAY'
                     ? @{ $self->{$target} }
                     : $self->{$target};

            @data = map lc, @data if $target eq 'Subscribe';
            next unless scalar @data > 0;
            $data{$target} = \@data;
        }
    }

    # Check to make sure we're doing something
    keys %data
        or AE::log fatal => 'Must specify a subscription or a match parameters!';

    # Send the Subscription
    foreach my $target ( sort keys %data ) {
        my $subname = 'do_' . lc $target;
        $self->$subname( $handle, $data{$target} );
    }
}

sub do_subscribe {
    my ( $self, $handle, $subs ) = @_;

    if ( List::Util::first { $_ eq 'fullfeed' } @{$subs} ) {
        $handle->push_write("fullfeed\n");
    } else {
        $handle->push_write(
            'sub '                 .
            join( ', ', @{$subs} ) .
            "\n"
        );
    }
}

sub do_match {
    my ( $self, $handle, $matches ) = @_;
    $handle->push_write(
        'match '                  .
        join( ', ', @{$matches} ) .
        "\n"
    );
}

sub handle_message {
    my ( $self, $line, $handle ) = @_;

    my $msg;
    my $success = eval {
        no warnings;
        $msg = parse_syslog_line($line);
        1;
    } or do {
        my $error = $@ || 'Zombie error';
        AE::log error => "Could not parse line: $line ($error)\n";
    };

    $success && $msg or return;

    # Try the Message Handler, eventually we can do statistics here.
    eval {
        $self->{'MessageHandler'}->($msg);
        1;
    } or do {
        my $error = $@ || 'Zombie error';
        AE::log error => "MessageHandler failed: $error";
    };
}

1;

__END__

=pod

=head1 DESCRIPTION

L<AnyEvent::eris::Client> is an L<AnyEvent> version of
L<POE::Component::Client::eris> - a simple pub/sub implementation,
written by Brad Lhotsky.

Since I don't actually have any use for it right now, it's not
actively maintained. Might as well release it. If you're interested in
taking over it, just let me know.

For now the documentation is sparse but the tests should be clear
enough to assist in understanding it.
