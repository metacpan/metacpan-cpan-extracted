package App::EvalServer;
BEGIN {
  $App::EvalServer::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::EvalServer::VERSION = '0.08';
}

use strict;
use warnings FATAL => 'all';

# we want instant child process reaping
sub POE::Kernel::USE_SIGCHLD () { return 1 }

use File::Spec::Functions qw<catdir catfile rel2abs>;
use File::Temp qw<tempdir>;
use POE;
use POE::Filter::JSON;
use POE::Filter::Reference;
use POE::Filter::Stream;
use POE::Wheel::SocketFactory;
use POE::Wheel::ReadWrite;
use POE::Wheel::Run;
use POSIX qw<mkfifo>;
use Time::HiRes qw<time>;

my @inc = map { +'-I' => rel2abs($_) } @INC;
my $CHILD_PROGRAM = [
    $^X, @inc, '-MApp::EvalServer::Child',
    '-e', 'App::EvalServer::Child::run()'
];

my %LANGS = (
    perl    => 'Perl',
    pl      => 'Perl',
    ruby    => 'Ruby',
    rb      => 'Ruby',
    php     => 'PHP',
    deparse => 'Deparse',
    python  => 'Python',
    py      => 'Python',
    lua     => 'Lua',
    j       => 'J',
);

sub new {
    my ($package, %args) = @_;
    my %defaults = (
        host    => 'localhost',
        port    => 14400,
        user    => 'nobody',
        timeout => 10,
        limit   => 50,
    );

    while (my ($key, $value) = each %defaults) {
        $args{$key} = $value if !defined $args{$key};
    }

    return bless \%args, $package;
}

sub run {
    my ($self) = @_;

    if ($self->{daemonize}) {
        require Proc::Daemon;
        eval {
            Proc::Daemon::Init->();
            $poe_kernel->has_forked();
        };
        chomp $@; 
        die "Can't daemonize: $@\n" if $@;
    }

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                _shutdown
                sig_die
                fatal_signal
                server_failure
                new_client
                client_read
                client_write
                client_error
                spawn_eval
                eval_stdin
                eval_stdout
                eval_stderr
                eval_result
                eval_timeout
                eval_sig_child
            )],
        ],
    );

    return;
}

sub _start {
    my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];

    $self->{server} = POE::Wheel::SocketFactory->new(
        BindAddress  => $self->{host},
        BindPort     => $self->{port},
        SuccessEvent => 'new_client',
        FailureEvent => 'server_failure',
        Reuse        => 'yes',
    );

    $self->{session_id} = $session->ID;
    $kernel->sig(DIE => 'sig_die');
    $kernel->sig(INT => 'fatal_signal');
    $kernel->sig(TERM => 'fatal_signal');
    return;
}

sub sig_die {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};

    my @errors = ( 
        "Event $ex->{event} in session ".$ex->{dest_session}->ID." raised exception:",
        "    $ex->{error_str}",
    );
    warn "$_\n" for @errors;

    $kernel->sig_handled();
    return;
}

sub fatal_signal {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $kernel->yield('_shutdown');
    $kernel->sig_handled();
    return;
}

sub server_failure {
    my ($self, $operation, $error) = @_[OBJECT, ARG0, ARG2];
    delete $self->{server};
    warn "$operation failed: $error\n";
    return;
}

sub new_client {
    my ($self, $handle) = @_[OBJECT, ARG0];

    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $handle,
        Filter       => POE::Filter::JSON->new(),
        InputEvent   => 'client_read',
        FlushedEvent => 'client_write',
        ErrorEvent   => 'client_error',
    );

    $self->{clients}{$wheel->ID} = $wheel;
    return;
}

sub client_read {
    my ($kernel, $self, $input, $wheel_id) = @_[KERNEL, OBJECT, ARG0, ARG1];

    my $client = $self->{clients}{$wheel_id};

    if (ref $input ne 'HASH') {
        $client->put({ error => 'JSON data must be a hash' });
    }
    elsif (!defined $input->{lang}) {
        $client->put({ error => 'No language specified' });
    }
    elsif (!defined $LANGS{lc $input->{lang}}) {
        $client->put({ error => 'Language not supported' });
    }
    elsif (!defined $input->{code}) {
        $client->put({ error => 'Code is missing' });
    }
    else {
        $kernel->yield(
            'spawn_eval',
            $wheel_id,
            $LANGS{lc $input->{lang}},
            $input->{code},
            $input->{stdin},
        );
    }

    return;
}

sub client_write {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];
    $self->_remove_client($wheel_id);
    return;
}

sub client_error {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];
    $self->_remove_client($wheel_id);
    return;
}

sub _remove_client {
    my ($self, $client_id) = @_;
    delete $self->{clients}{$client_id};

    for my $eval (values %{ $self->{evals} }) {
        $eval->{wheel}->kill() if $eval->{client_id} == $client_id;
    }
    return;
}

sub spawn_eval {
    my ($kernel, $self, $client_id, $lang, $code, $stdin)
        = @_[KERNEL, OBJECT, ARG0..$#_];
    
    my $tempdir = tempdir(CLEANUP => 1);
    my $result_pipe = catfile($tempdir, 'result_pipe');
    mkfifo($result_pipe, 0700) or die "mkfifo $result_pipe failed: $!";
    my $jail = catdir($tempdir, 'jail');
    mkdir $jail or die "Can't mkdir $jail: $!";

    my $start_time = time;
    my $wheel = POE::Wheel::Run->new(
        Program      => $CHILD_PROGRAM,
        ProgramArgs  => [$tempdir, $result_pipe, $jail, $self->{user},
                         $self->{limit}, $lang, $code, $self->{unsafe}],
        Priority     => 10,
        StdioFilter  => POE::Filter::Stream->new(),
        StderrFilter => POE::Filter::Stream->new(),
        StdinEvent   => 'eval_stdin',
        StdoutEvent  => 'eval_stdout',
        StderrEvent  => 'eval_stderr',
    );
    $self->{pid_to_id}{$wheel->PID} = $wheel->ID;

    if (defined $stdin) {
        $wheel->put($stdin);
    }
    else {
        $wheel->shutdown_stdin();
    }

    open my $pipe_handle, '<', $result_pipe or die "Can't open $result_pipe: $!";

    my $result_wheel = POE::Wheel::ReadWrite->new(
        Handle     => $pipe_handle,
        InputEvent => 'eval_result',
        Filter     => POE::Filter::Reference->new(),
    );
    $self->{pipe_to_id}{$result_wheel->ID} = $wheel->ID;

    my $alarm_id = $kernel->delay_set('eval_timeout', $self->{timeout}, $wheel->ID);
    $self->{evals}{$wheel->ID} = {
        wheel      => $wheel,
        pipe_wheel => $result_wheel,
        pipe_name  => $result_pipe,
        client_id  => $client_id,
        alarm_id   => $alarm_id,
        tempdir    => $tempdir,
        start_time => $start_time,
        return     => {
            stdout     => '',
            stderr     => '',
            output     => '',
        },
    };

    $kernel->sig_child($wheel->PID, 'eval_sig_child');
    return;
}

sub eval_stdout {
    my ($self, $chunk, $wheel_id) = @_[OBJECT, ARG0, ARG1];

    my $eval = $self->{evals}{$wheel_id};
    $eval->{return}{stdout} .= $chunk;
    $eval->{return}{output} .= $chunk;
    return;
}

sub eval_stderr {
    my ($self, $chunk, $wheel_id) = @_[OBJECT, ARG0, ARG1];

    my $eval = $self->{evals}{$wheel_id};
    $eval->{return}{stderr} .= $chunk;
    $eval->{return}{output} .= $chunk;
    return;
}

sub eval_result {
    my ($self, $return, $id) = @_[OBJECT, ARG0, ARG1];
    my $wheel_id = delete $self->{pipe_to_id}{$id};
    my $eval = $self->{evals}{$wheel_id};

    while (my ($key, $value) = each %$return) {
        $eval->{return}{$key} = $value;
    }
    return;
}

sub eval_stdin {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];
    my $wheel = $self->{evals}{$wheel_id}{wheel};
    $wheel->shutdown_stdin();
    return;
}

sub eval_sig_child {
    my ($self, $pid) = @_[OBJECT, ARG1];
    my $wheel_id = delete $self->{pid_to_id}{$pid};

    my $eval = delete $self->{evals}{$wheel_id};
    $poe_kernel->alarm_remove($eval->{alarm_id});
    unlink $eval->{pipe_name};

    # getrusage() in the child doesn't provide wallclock time, so we do it
    $eval->{return}{real_time} = sprintf('%.2f', time() - $eval->{start_time});

    if (defined $self->{clients}{$eval->{client_id}}) {
        my $client = $self->{clients}{$eval->{client_id}};

        if ($eval->{return}{error}) {
            $client->put({ error => $eval->{return}{error} });
        }
        elsif (!exists $eval->{return}{result}) {
            $client->put({ error => 'Child process died before returning a result.' });
        }
        else {
            $client->put($eval->{return});
        }
    }

    return;
}

sub eval_timeout {
    my ($self, $wheel_id) = @_[OBJECT, ARG0];
    my $wheel = $self->{evals}{$wheel_id};
    $wheel->kill();
    return;
}

sub _shutdown {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    delete $self->{server};
    delete $self->{clients};
    $kernel->alarm_remove_all();
    return;
}

sub shutdown {
    my ($self) = @_;
    $poe_kernel->post($self->{session_id}, '_shutdown');
    return;
}

1;

=encoding utf8

=head1 NAME

App::EvalServer - Evaluate arbitrary code in a safe environment

=head1 SYNOPSIS

 use App::EvalServer;

 my $server = App::EvalServer->new(
     port    => 1234,
     timeout => 30,
 );

 $server->run();
 
 # ...
 
 $server->shutdown();

=head1 DESCRIPTION

This application evaluates arbitrary source code in a safe enviroment. It
listens on a TCP port and accepts JSON data desribing a language and some
code to evaluate. The result of the evaluation and some accompanying
information is then returned as back as JSON data. See L</INPUT> and
L</OUTPUT> for details.

=head1 METHODS

=head2 C<new>

Constructs a new C<App::EvalServer> object. Takes the following optional
argunments:

B<'host'>, the host to listen on (default: 'localhost')

B<'port'>, the port to listen on (default: 14400)

B<'user'>, evaluate code as this user (default: 'nobody')

B<'timeout'>, kill the evaluating process after this many seconds (default: 10)

B<'limit'>, resource limit in megabytes (default: 50)

B<'daemonize'>, daemonize the process

B<'unsafe'>, don't chroot or set resource limits (no root needed). Default is
false.

=head2 C<run>

Runs the server. Takes no arguments.

=head2 C<shutdown>

Shuts down the server. Takes no arguments.

=head1 INPUT

To request an evaluation, you need to send a JSON hash containing the
following keys:

B<'lang'>, a string containing the language module suffix, e.g. 'Perl' for
L<App::EvalServer::Language::Perl|App::EvalServer::Language::Perl>.

B<'code'>, a string containing the code you want evaluated.

=head1 OUTPUT

When your request has been processed, you will receive a JSON hash back. If
no errors occurred B<before> the code was evaluated, the hash will contain the
following keys:

=over 4

=item * B<'result'>, containing the result of the evaluation.

=item * B<'stdout'>, a string containing everything that was printed to the
evaluating process' stdout handle.

=item * B<'stderr'>, a string containing everything that was printed to the
evaluating process' stderr handle.

=item * B<'output'> a string containing the merged output (stdout & stderr)
from the evaluating process.

=item * B<'memory'>, the memory use of the evaluating process (as reported by
L<C<(getrusage())[2]>|BSD::Resource/getrusage>).

=item * B<'real_time'>, the real time taken by the evaluating process.

=item * B<'user_time'>, the user time taken by the evaluating process.

=item * B<'sys_time'>, the sys time taken by the evaluating process.

=back

If an error occurred before the code could be evaluated, the only key you
will get is B<'error'>, which tells you what
went wrong.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson (hinrik.sig@gmail.com), C<buu>, and probably
others

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
