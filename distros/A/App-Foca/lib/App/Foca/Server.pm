#
# App::Foca::Server
#
# Author(s): Pablo Fischer (pablo@pablo.com.mx)
# Created: 06/13/2012 01:44:57 AM UTC 01:44:57 AM
package App::Foca::Server;

=head1 NAME

App::Foca::Server - Foca server

=head1 DESCRIPTION

Foca is an application (a HTTP server using HTTP::Daemon) that allows the
execution of pre-defined commands via, obviously, HTTP.

Well, lets suppose you have a log parser on all your servers and you are in
need to parse all of them, the common way would be to ssh to each host (can
be as simple as ssh'ing to each host or using a multiplex tool) and execute
your parser, but what if your SSH keys or the keys of a user are not there?
It will be a heck of pain to enter your password hundred of times or lets
imagine you want to parse your logs via some automation (like doing it from
an IRC bot or tied to your monitoring solution).. then the problem comes
more complex with SSH and private keys. With Foca you don't need to worry
about those things, the command will get executed and the output will be
returned as a HTTP response.

All commands that Foca knows about it are listed in a YAML file. Foca uses a 
default timeout value for all commands but with this YAML file you can give
a specific timeout to a specific command. All commands are executed with IPC
(open3).

Now the question is.. is Foca secure? Well it depends on you. Depends if you
run it as non-root user and the commands you define. Foca will try to do
things to protect, for example it will reject all requests that have pipes (|),
I/O redirection (>, <, <<, >>), additionally the HTTP request will be validated
before it gets executed via the call of C<validate_request()> (L<App::Foca::Server>
returns true all the time so if you want to add extra functionality please
create a subclass and re-define the method).

=head1 EXAMPLE

    my $server = App::Foca::Server->new(
            port                => $port,
            commands_file       => $commands,
            commands_timeout    => $timeout,
            debug               => $debug);

    $server->run_server();

=head1 EXAMPLE COMMANDS FILE

    commands_dirs:
        - /some/path/over/there/bin

    commands:
        df_path:
            cmd: '/bin/df {%foca_args%} | tail -n1'
        uptime:
            cmd: '/usr/bin/uptime'
        'true':
            cmd: '/bin/true'

The way the example commands file work is: First it will look if there is a 
I<commands_dir> key, this key should have a list of directories (that means
it should be an array reference), Foca will look for all executables inside
the given directories and add them into memory. Second, it will look for the
I<commands> key, this one should be a hash where each key is the name of the
command and it should have B<at least> a I<cmd> key which value should be
the I<real> command to execute.

Please note that when you use the I<commands_dir>, Foca will use the basename
of each executable as the name of the command so if you have /usr/local/foo,
the foca command will be I<foo> while the command it will execute will be
I</usr/local/foo>.

Also, you can override commands found in I<commands_dir> via I<commands>, so
going back to our /usr/local/foo example, you can have this executable
in your /usr/local directory but also have a I<foo> command defined in 
I<commands>, the one that is defined in I<commands> will be the one that
will be used by Foca.

Command parameters are accepted but they should be find or declared in
the I<Foca-Cmd-Params> HTTP header. L<App::Foca::Client> takes care of
preparing the header.

Commands can have place-holders, this means that you can define your command
in the YAML file and the I<real> command can be a combination of pipes. If your
command needs some parameters then you can use I<{%foca_args%}> and it will
be replaced with whatever parameters are found in the HTTP header 
I<Foca-Cmd-Params>.

There are two ways to update the list of commands once the server started: One
is by obviously restarting it and the other one is via localhost send a
HTTP request to localhost:yourport/reload.

=cut
use strict;
use warnings;
use Cache::FastMmap;
use Data::Dumper;
use Fcntl;
use File::Basename;
use FindBin;
use HTTP::Status qw(:constants status_message);
use IPC::Cmd qw(run_forked);
use Linux::Proc::Net::TCP;
use Moose;
use Time::HiRes qw(time);
use YAML::Syck qw(LoadFile);
# Foca libs/modules
use App::Foca::Server::HTTP;
use App::Foca::Tools::Logger;

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

# Some constants
use constant {
    FOCA_RUN_RC_OK              => 100,
    FOCA_RUN_RC_FAILED_CMD      => 200,
    FOCA_RUN_RC_MISSING_CMD     => 300,
    FOCA_RUN_RC_TIMEOUT_CMD     => 400};

=head1 Attributes

=over 4

=item B<commands_file>

YAML file with the supported commands.

=cut
has 'commands_file' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1);

=item B<commands>

Hash reference with a list of supported commands. Basically the content of
C<commands_file>.

=cut
has 'commands' => (
    is          => 'ro',
    isa         => 'HashRef');

=item B<port>

Where to listen for requests?

=cut
has 'port' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1);

=item B<commands_timeout>

Global timeout for all commands. Default to 1min (60 seconds).

=cut
has 'commands_timeout' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 60);

=item B<tmp_dir>

Temporary directory, for cache.

=cut
has 'tmp_dir' => (
    is          => 'rw',
    isa         => 'Str',
    default     => '/tmp');

=item B<debug>

Debug/verbose mode, turned off by default.

=cut
has 'debug' => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0);

=item B<server>

L<App::Foca::Server::HTTP> object.

=cut
has 'server' => (
    is          => 'rw',
    isa         => 'Obj');

=item B<cache>

For mmap cache (so we can share cache across processes).

=cut
has 'cache' => (
    is          => 'rw',
    isa         => 'Obj');

=back

=cut

=head1 Methods

=head2 B<run_server()>

Runs the HTTP::Daemon server. it forks on each request.

=cut
sub run_server {
    my ($self) = @_;

    # Do _NOT_ remove this line, this is to make sure we don't leave zombie
    # processes
    local $SIG{CHLD} = 'IGNORE';

    $self->{'server'}   = App::Foca::Server::HTTP->new(
            LocalPort   => $self->{'port'},
            ReuseAddr   => 1,
            Blocking    => 1) || die;
    log_info("Listening on port $self->{'port'}");
    while(my $connection = $self->{'server'}->accept) {
        log_connection($connection->peerhost());
        if (my $pid = fork()) {
            $connection->close;
            undef $connection;
        } else {
            while (my $request = $connection->get_request) {
                my $start = time;
                log_request($connection->peerhost(), $request->uri->path);
                my $response;
                # Special commands?
                if ($connection->peerhost() eq '127.0.0.1') {
                    if ($request->uri->path eq '/reload') {
                        $self->load_commands();
                        $response = $self->build_response(HTTP_OK,
                                "Commands reloaded");
                    } elsif ($request->uri->path eq '/status') {
                        $response = $self->prepare_status_response();
                    }
                }
                $response = $self->prepare_foca_response($connection, $request) unless
                    $response;
                my $lat = (time-$start);
                # Add latency
                $response->header('X-Foca-ResponseTime', sprintf("%.5f", $lat));
                $connection->send_response($response);
                $connection->close;
            }
            exit 0;
        }
    }
    exit 0;
}

=head2 B<prepare_status_response()>

Prepares a response (L<HTTP::Response>) for the /status request. /status
requests returns some stats about Foca server, such as: number of active
connections, number of closed/zombie connections (user connected and left
the connection open with a process that is no longer needed).

=cut
sub prepare_status_response {
    my ($self) = @_;

    my $table = Linux::Proc::Net::TCP->read;

    my ($active_connections, $closed_connections) = (0, 0);
    for my $entry (@$table) {
        if ($entry->local_port == $self->{'port'}) {
            if ($entry->st eq 'CLOSE_WAIT') {
                $closed_connections++;
            } elsif ($entry->st eq 'ESTABLISHED') {
                $active_connections++;
            }
        }
    }
    
    my $body = "active_connections: $active_connections\n";
    $body   .= "closed_connections: $closed_connections\n";

    return $self->build_response(HTTP_OK, $body);
}

=head2 B<prepare_foca_response($connection, $request)>

Prepares a response (L<HTTP::Response>) for a given foca request (L<HTTP::Request>).

=cut
sub prepare_foca_response {
    my ($self, $connection, $request) = @_;

    my $headers = $request->headers;
    my $method  = $request->method;        
    # Ok, we getting GET or HEAD? the only ones we allow
    if (grep($method eq uc $_, qw(GET HEAD))) {
        # We got params?
        my $params = $headers->header('Foca-Cmd-Params') || '';
        # *sanitize* the parameters
        $params = $self->_sanitize_parameters($params);
        # Ok, which command?
        my $command = $request->uri->path || '';
        if ($command =~ m#^/foca/(\S+)(\/)?#) {
            $command = $1;
        }
        # We got command?
        unless ($command) {
            return $self->build_response(HTTP_NOT_ACCEPTABLE,
                    "Missing command");
        }
        # Cool, now load the commands from memory
        my $commands = $self->{'cache'}->get('foca_commands');
        $commands = {} unless $commands;
        unless ($commands) {
            log_error("There are no commands available");
            return $self->build_response(HTTP_NOT_IMPLEMENTED, "No commands available");
        }
        # Ok, the command is valid?
        unless ($commands->{$command}) {
            return $self->build_response(HTTP_NOT_FOUND, "Unknown command");
        }
        # Validate request
        my ($is_valid, $msg) = $self->validate_request($command, $request);
        unless ($is_valid) {
            if ($msg) {
                return $self->build_response(HTTP_FORBIDDEN, $msg);
            } else {
                return $self->build_response(HTTP_FORBIDDEN);
            }
        }
        
        my ($code, $output) = $self->run_cmd(
                $connection,
                $command,
                $commands->{$command},
                $params);
        # Ok, we got a command, now lets 
        if ($code == FOCA_RUN_RC_OK) {
            return $self->build_response(HTTP_OK, $output);
        } elsif ($code == FOCA_RUN_RC_TIMEOUT_CMD) {
            return $self->build_response(HTTP_REQUEST_TIMEOUT, 'Timed out'); 
        } else {
            return $self->build_response(HTTP_INTERNAL_SERVER_ERROR, $output);
        }
    }
}

=head2 B<build_response($code, $body)>

Builds a HTTP response (C<HTTP::Response>) based on the given HTTP status code
and optionally adds a body.

Returns a C<HTTP::Response> so it can be send via the opened connection.

=cut
sub build_response {
    my ($self, $code, $body) = @_;

    my $res = HTTP::Response->new($code, status_message($code));

    my %default_headers = (
            pragma        => "must-revalidate, no-cache, no-store, expires: -1",
            no_cache      => 1,
            expires       => -1,
            cache_control => "no-cache, no-store, must-revalidate",
            content_type  => 'text/plain',
            );
    while(my($k, $v) = each %default_headers) {
        $res->header($k, $v);
    }
    # A body?
    $res->content($body) if $body;
    return $res;
}

=head2 B<validate_request($command, $request)>

re-define this method if you want to add some extra security. By default all
requests are valid at this point.

=cut
sub validate_request {
    my ($self, $command, $request) = @_;

    return 1;
}

=head2 B<run_cmd($connection, $name, $cmd, $params)>

Runs whatever the command is and sets a timeout to it. If it takes too long
then it will try to kill the process.

Depending on the settings given to the command it will return the STDOUT or
STDERR or even both. The rules are:

=over 4

=item 1. On success it will look for STDOUT, if nothing is there then it looks in
STDERR. If nothing is foudn in STDERR and STDOUT then an empty string is
returned.

=item 2. On error it will look for STDERR first, if nothing is there then it
looks in STDOUT. If nothing is there then it returns an empty string.

=back

Both STDOUT and STDERR can be returned if the command is defined as follows:

    server_uptime:
        cmd: '/usr/bin/uptime'
        capture_all: 'y'

=cut
sub run_cmd {
    my ($self, $connection, $name, $cmd, $params) = @_;

    my $output = '';
    if ($cmd->{'cmd'}) {
        my $capture_all = 0;
        if ($cmd->{'capture_all'}) {
            $capture_all = ($cmd->{'capture_all'} eq 'y');
        }
        my @foca_cmd;
        # For the args, the cmd has a {%args%} parameter?
        if ($cmd->{'cmd'} =~ /\{\%foca_args\%\}/) {
            my $cmd = $cmd->{'cmd'};
            if ($params) {
                $cmd =~ s/\{\%foca_args\%\}/$params/g;
            } else {
                $cmd =~ s/\{\%foca_args\%\}//g;
            }
            @foca_cmd = $cmd;
        } else {
            @foca_cmd = $cmd->{'cmd'};
            push(@foca_cmd, $params) if $params;
        }
        
        my $timeout  = $cmd->{'timeout'} ?
            int($cmd->{'timeout'}) : $self->{'commands_timeout'};
        
        my ($result, $out, $err, $error_msg, @foca_cmd_pids, $in);
        eval {
            my $ip = $connection->peerhost();
            log_info("Command - $name [timeout: $timeout][ip $ip] - About to run @foca_cmd");
            $result = run_forked("@foca_cmd", {
                    child_in => \$in,
                    timeout  => $timeout});
        };
        if ($result->{'timeout'} == $timeout) {
            return (FOCA_RUN_RC_TIMEOUT_CMD, 'Timed out');
        }
        # Ok, sometimes because of SIG{CHLD} we get exit codes of 255
        # with no stderr which foca thinks the command failed but it really did not,
        # so lets check if we got stderr too, if we did not then the command was 
        # OK (unless of course there is a real: 'y' command). Check anything >
        # than 1 cause 1 is by default an error (like /bin/false which wont
        # return nothing to STDERR...)
        if ($result->{'exit_code'} > 1) {
            unless ($result->{'stderr'}) {
                if (defined $cmd->{'real'}) {
                    if ($cmd->{'real'} ne 'y') {
                        # Force OK
                        $result->{'exit_code'} = 0;
                    }
                } else {
                    # Force OK
                    $result->{'exit_code'} = 0;
                }
            }
        }

        if ($result->{'exit_code'} > 0) {
            my $output = '';
            if ($capture_all) {
                $output = $result->{'merged'};
            } else {
                if ($out) {
                    $output = $result->{'stdout'};
                }
                if ($err) {
                    $output = $result->{'stderr'};
                }
            }
            $output = $result->{'merged'} unless $output;
            $output = $@ unless $output;
            $output = $result->{'err_msg'} unless $output;
            $output =~ s#Can't ignore signal CHLD, forcing to default.(\n)?##g;
            return (FOCA_RUN_RC_FAILED_CMD, $output);
        } else {
            my $output = '';
            if ($capture_all) {
                $output = $result->{'merged'};
            } else {
                if ($out) {
                    $output = $result->{'stdout'};
                }
                if ($err) {
                    $output = $result->{'stderr'};
                }
            }
            $output = $result->{'merged'} unless $output;
            $output =~ s#Can't ignore signal CHLD, forcing to default.(\n)?##g;
            return (FOCA_RUN_RC_OK, $output);
        }
    } else {
        return (FOCA_RUN_RC_MISSING_CMD, 'Missing command in commands file');
    }
}

=head2 B<load_commands()>

Load the commands YAML file and stores it in memory with L<Cache::FastMnap>

=cut
sub load_commands {
    my ($self) = @_;

    log_info("Loading commands from $self->{'commands_file'}");
    
    if (-f $self->{'commands_file'}) {
        my $commands = LoadFile($self->{'commands_file'});
        if ($commands->{'commands'}) {
            $self->{'commands'} = $commands->{'commands'};
        } else {
            $self->{'commands'} = {};
        }
        # We have dirs?
        if (defined $commands->{'commands_dirs'}) {
            foreach my $dir (@{$commands->{'commands_dirs'}}) {
                next unless (-d $dir);
                foreach my $file (glob("$dir/*")) {
                    next unless (-x $file);
                    my $base = basename($file);
                    if (defined $self->{'commands'}->{$base}) {
                        log_warn("Command $base is already defined");
                    } else {
                        log_debug("Adding $base (fullpath $file)");
                        $self->{'commands'}->{$base} = {
                            'cmd' => $file};
                    }
                }
            }
        }
    } else {
        log_error("Commands file does NOT exists");
        $self->{'commands'} = {};
    }
    # Store
    $self->{'cache'}->set('foca_commands', $self->{'commands'});
}

######################## PRIVATE / PROTECTED METHODS ##########################
sub BUILD {
    my ($self) = @_;

    $self->{'cache'} = Cache::FastMmap->new(
            share_file      => $self->{'tmp_dir'} . '/foca_server_mmap',
            init_file       => 1,
            empty_on_exit   => 1,
            unlink_on_exit  => 1);
    # Ok, load commands
    $self->load_commands();

    init_logger();
    use_debug() if $self->{'debug'};
}

sub _sanitize_parameters {
    my ($self, $parameters_str) = @_;

    # No pipes
    $parameters_str =~ s/\|//g;
    # No quotes
    $parameters_str =~ s/\'//g;
    $parameters_str =~ s/\"//g;
    # No IO redirection
    $parameters_str =~ s/>//g;
    $parameters_str =~ s/<//g;
    # No ;..
    $parameters_str =~ s/;//g;
    # Remove backticks
    $parameters_str =~ s/\`//g;
    return $parameters_str;
}

=head1 COPYRIGHT

Copyright (c) 2010-2012 Yahoo! Inc. All rights reserved.

=head1 LICENSE

This program is free software. You may copy or redistribute it under
the same terms as Perl itself. Please see the LICENSE file included
with this project for the terms of the Artistic License under which 
this project is licensed.

=head1 AUTHORS

Pablo Fischer (pablo@pablo.com.mx)

=cut
1;

