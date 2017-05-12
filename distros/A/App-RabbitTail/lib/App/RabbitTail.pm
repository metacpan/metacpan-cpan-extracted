package App::RabbitTail;
use Moose;
use Net::RabbitFoot 1.03;
use App::RabbitTail::FileTailer;
use AnyEvent;
use Data::Dumper;
use Moose::Autobox;
use MooseX::Types::Moose qw/ArrayRef Str Int/;
use Try::Tiny qw/ try catch /;
use namespace::autoclean;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

with 'MooseX::Getopt';

has filename => (
    isa => ArrayRef[Str],
    is => 'ro',
    cmd_aliases => ['fn'],
    required => 1,
    traits => ['Getopt'],
);

has routing_key => (
    isa => ArrayRef[Str],
    is => 'ro',
    cmd_aliases => ['rk'],
    default => sub { [ '#' ] },
    traits => ['Getopt'],
);

has max_sleep => (
    isa => Int,
    is => 'ro',
    default => 10,
    documentation => 'The max sleep time between trying to read a line from an input file',
);

has _cv => (
    is => 'ro',
    lazy => 1,
    default => sub { AnyEvent->condvar },
    clearer => '_clear_cv',
);

my $rf = Net::RabbitFoot->new(
    varbose => 1,
)->load_xml_spec();

has _rf => (
    isa => 'Net::RabbitFoot',
    is => 'ro',
    lazy => 1,
    builder => '_build_rf',
    clearer => '_clear_rf',
);

sub _build_rf {
    my ($self) = @_;
    my $rf_conn;
    while (!$rf_conn) {
        try {
            $rf_conn = $rf->connect(
                on_close => sub {
                    warn(sprintf("RabbitMQ connection to %s:%s closed!\n", $self->host, $self->port));
                    $self->_clear_ch;
                    $self->_clear_rf;
                    $self->_cv->send("ARGH");
                },
                map { $_ => $self->$_ }
                qw/ host port user pass vhost /
            );
        }
        catch {
            warn($_);
            sleep 2;
        };
    }
    return $rf_conn;
}

my %defaults = (
    host => 'localhost',
    port => 5672,
    user => 'guest',
    pass => 'guest',
    vhost => '/',
    exchange_type => 'direct',
    exchange_name => 'logs',
    exchange_durable => 0,
);

foreach my $k (keys %defaults) {
    has $k => ( is => 'ro', isa => Str, default => $defaults{$k} );
}

has _ch => (
    is => 'ro',
    lazy => 1,
    builder => '_build_ch',
    clearer => '_clear_ch',
    predicate => '_has_ch',
);

sub _build_ch {
    my ($self) = @_;
    my $ch = $self->_rf->open_channel;
    my $exch_frame = $ch->declare_exchange(
        type => $self->exchange_type,
        durable => $self->exchange_durable,
        exchange => $self->exchange_name,
    )->method_frame;
    die Dumper($exch_frame) unless blessed $exch_frame
        and $exch_frame->isa('Net::AMQP::Protocol::Exchange::DeclareOk');
    return $ch;
}

sub run {
    my $self = shift;
    my $tail_started = 0;
    while (1) {
        $self->_clear_cv;
        $self->_ch; # Build channel before going into the event loop
        $self->tail # Setup all the timers
            unless $tail_started++;
        $self->_cv->recv; # Enter event loop. We will leave here if channel dies..
    }
}

sub tail {
    my $self = shift;
    my $rkeys = $self->routing_key;
    foreach my $fn ($self->filename->flatten) {
        my $rk = $rkeys->shift;
        $rkeys->unshift($rk) unless $rkeys->length;
#        warn("Setup tail for $fn on $rk");
        my $ft = $self->setup_tail($fn, $rk);
        $ft->tail;
    }
}

sub setup_tail {
    my ($self, $file, $routing_key) = @_;
    App::RabbitTail::FileTailer->new(
        max_sleep => $self->max_sleep,
        cb => sub {
            my $message = shift;
            chomp($message);
#            warn("SENT $message to " . $self->exchange_name . " with " . $routing_key);
            if (!$self->_has_ch) {
                warn("DROPPED $message to " . $self->exchange_name . " with " . $routing_key . "\n");
                return;
            }
            $self->_ch->publish(
                body => $message,
                exchange => $self->exchange_name,
                routing_key => $routing_key,
            );
        },
        fn => $file,
    );
}

__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

App::RabbitTail - Log tailer which broadcasts log lines into RabbitMQ exchanges.

=head1 SYNOPSIS

    See the rabbit_tail script shipped with the distribution for simple CLI useage.

    use App::RabbitTail;
    use AnyEvent; # Not strictly needed, but you probably want to
                  # use it yourself if you're doing this manually.

    my $tailer = App::RabbitTail->new(
        # At least 1 filename must be supplied
        filename => [qw/ file1 file2 /],
        # Optional args, defaults below
        routing_key => [qw/ # /],
        host => 'localhost',
        port => 5672,
        user => 'guest',
        pass => 'guest',
        vhost => '/',
        exchange_type => 'direct',
        exchange_name => 'logs',
        exchange_durable => 0,
        max_sleep => 10,
    );
    # You can setup other AnyEvent io watchers etc here.
    $tailer->run; # enters the event loop
    # Or:
    $tailer->tail;

=head1 DECRIPTION

App::RabbitTail is a trivial file tail implementation using L<AnyEvent> IO watchers,
which emits lines from the tailed files into L<http://www.rabbitmq.com/>
via the L<Net::RabbitFoot> client.

Note that this software should be considered experimental.

=head1 BUGS

Plenty. Along with error conditions not being handled gracefully etc.

They will be fixed in due course as I start using this more seriously,
however in the meantime, patches are welcome :)

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Tomas Doran

Licensed under the same terms as perl itself.

=cut

