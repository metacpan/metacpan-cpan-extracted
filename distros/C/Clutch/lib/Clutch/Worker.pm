package Clutch::Worker;
use strict;
use warnings;
use parent qw(Exporter);
use IO::Socket::INET;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use Clutch::Utils;
use Parallel::Prefork;

our @EXPORT = qw(
    new
    run
    setup_listener
    accept_loop
    handle_connection
    register_function
    dispatch
    do_request
    do_request_background
    cascade
);

my $FUNCTIONS = +{};
my $CONTEXT;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    %args = (
        address              => undef,
        functions            => $FUNCTIONS,
        timeout              => 10,
        max_workers          => 0,
        spawn_interval       => 0,
        err_respawn_interval => undef,
        max_reqs_per_child   => 100,
        %args,
    );

    my $self = bless \%args, $class;
    $CONTEXT = $self;
    $self;
}

sub setup_listener {
    my $self = shift;

    $self->{listen_sock} ||= IO::Socket::INET->new(
        Listen    => SOMAXCONN,
        LocalAddr => $self->{address},
        Proto     => 'tcp',
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    ) or die "failed to listen to port $self->{address}:$!";

    # set defer accept
    if ($^O eq 'linux') {
        setsockopt($self->{listen_sock}, IPPROTO_TCP, 9, 1)
            and $self->{_using_defer_accept} = 1;
    }
}

sub run {
    my $self = shift;
    $self->setup_listener();

    if ($self->{max_workers} != 0) {
        my %pm_args = (
            max_workers => $self->{max_workers},
            trap_signals => {
                TERM => 'TERM',
                HUP  => 'TERM',
            },
        );
        if (defined $self->{spawn_interval}) {
            $pm_args{trap_signals}{USR1} = [ 'TERM', $self->{spawn_interval} ];
            $pm_args{spawn_interval} = $self->{spawn_interval};
        }
        if (defined $self->{err_respawn_interval}) {
            $pm_args{err_respawn_interval} = $self->{err_respawn_interval};
        }
        my $pm = Parallel::Prefork->new(\%pm_args);
        while ($pm->signal_received !~ /^(TERM|USR1)$/) {
            $pm->start and next;
            $self->accept_loop;
            $pm->finish;
        }
        $pm->wait_all_children;
    } else {
        # run directly
        local $SIG{TERM} = sub { exit 0; };
        while (1) {
            $self->accept_loop;
        }
    }
}

sub accept_loop {
    my $self = shift;

    my $proc_req_count = 0;

    while (! defined $self->{max_reqs_per_child} || $proc_req_count < $self->{max_reqs_per_child}) {
        local $SIG{PIPE} = 'IGNORE';
        if (my $conn = $self->{listen_sock}->accept) {
            ++$proc_req_count;

            $self->{_is_deferred_accept} = $self->{_using_defer_accept};

            $conn->blocking(0)
                or die "failed to set socket to nonblocking mode:$!";
            $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                or die "setsockopt(TCP_NODELAY) failed:$!";

            $self->handle_connection($conn);
        }
    }
}

sub handle_connection {
    my ($self, $conn) = @_;

    my $buf = '';
    my $req = +{};

    while (1) {
        my $rlen = Clutch::Utils::read_timeout(
            $conn, \$buf, $MAX_REQUEST_SIZE - length($buf), length($buf), $self->{timeout}, $self
        ) or return;

        Clutch::Utils::parse_read_buffer($buf, $req)
          and last;
    }

    if (Clutch::Utils::support_cmd($req->{cmd})) {
        my $cmd_method = 'do_' . $req->{cmd};
        $self->$cmd_method($conn, $req);
    }
    else {
        $self->do_error($conn, $req);
    }

    return;
}

sub do_error {
    my ($self, $conn, $req) = @_;
    Clutch::Utils::write_all($conn, Clutch::Utils::make_response('CLIENT_ERROR: unknow command'), $self->{timeout}, $self);
    $conn->close();
}

sub do_request {
    my ($self, $conn, $req) = @_;

    my $code = $self->{functions}->{$req->{function}};
    my $res  = $code ? ($code->($req->{args}) || '')
                     : "ERROR: unknow function";

    Clutch::Utils::write_all($conn, Clutch::Utils::make_response($res), $self->{timeout}, $self);

    $conn->close();
}

sub do_request_background {
    my ($self, $conn, $req) = @_;

    my $code = $self->{functions}->{$req->{function}};
    my $res  = $code ? "OK" : "ERROR: unknow function";

    Clutch::Utils::write_all($conn, Clutch::Utils::make_response($res), $self->{timeout}, $self);
    $conn->close();

    $code && $code->($req->{args});

    return;
}

sub cascade {
    my ($function, $args) = @_;

    my $code = $CONTEXT->{functions}->{$function};
    $code ? ($code->($args) || '') : "ERROR: unknow function";
}

sub register_function ($$) { ## no critic
    my ($function, $code) = @_;
    $FUNCTIONS->{$function} = $code;
}
 
1;
__END__

=head1 NAME

Clutch::Worker - distributed job system's worker class

=head1 SYNOPSIS

    # worker
    package Your::Worker;
    use strict;
    use warnings;
    use Clutch::Worker;
    
    register_function(
        'echo' => sub {
            my $args = shift;
            $$ .':'. $args; # return worker process response.
        }
    );
    1;

    # worker start script by single process
    #! perl
    use strict;
    use warnings;
    use Your::Worker;
    Your::Worker->new(
        {
            address => "$ip:$port",
        }
    )->run(); # stop by TERM signal to this process

    # worker start script by multi prefork process
    #! perl
    use strict;
    use warnings;
    use Your::Worker;
    Your::Worker->new(
        {
            address            => "$ip:$port",
            max_workers        => $worker_num,
            max_reqs_per_child => $max_reqs_per_child,
        }
    )->new();

=head1 EXPORT WORKER FUNCTION

=head2 register_function($function_name, $callback_coderef);

=over

=item $function_name

worker process function name.

client process specific this functin name.

=item $callback_coderef

client process call the function, execute thid $callback_coderef.

$callback_coderef's first argument is a client request parameter.

=back

=head2 cascade($function_name, $args);

call self worker function.

=over

=item $function_name

worker process function name.

=item $args

worker argument.

=back

=head1 USAGE

=head2 my $worker = Your::Worker->new(\%opts);

=over

=item $opts{address}

worker process listen address.

=item $opts{timeout}

seconds until timeout (default: 10)

=item $opts{max_workers}

number of worker processes (default: 0)

if max_workers is 0, worker start single process mode.

if you specific max_workers Zero or more, do prefork worker process.

=item $opts{spawn_interval}

if set, worker processes will not be spawned more than once than every given seconds.
 Also, when SIGHUP is being received, no more than one worker processes will be collected every given seconds.
 This feature is useful for doing a "slow-restart".
 See http://blog.kazuhooku.com/2011/04/web-serverstarter-parallelprefork.html for more information. (dedault: none)

=item $opts{max_reqs_per_child}

max. number of requests to be handled before a worker process exits (default: 100)

=cut

