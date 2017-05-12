# NAME

App::Sv - Event-based multi-process supervisor

# SYNOPSIS

    my $sv = App::Sv->new(
        run => {
          x => 'plackup -p 3010 ./sites/x/app.psgi',
          y => {
            cmd => 'plackup -p 3011 ./sites/y/app.psgi'
            start_retries => 5,
            restart_delay => 1,
            start_wait => 1,
            stop_wait => 2,
            umask => '027',
            user => 'www',
            group => 'www'
          },
        },
        global => {
          listen => '127.0.0.1:9999',
          umask => '077'
        },
    );
    $sv->run;



# DESCRIPTION

This module implements an event-based multi-process supervisor.

It takes a list of commands to execute, forks a child and starts each one and
then monitors their execution. If one of the processes dies, the supervisor
will restart it after `restart_delay` seconds. If a process respawns during
`restart_delay` for `start_retries` times, the supervisor gives up and stops
it indefinitely.

You can send SIGTERM to the supervisor process to kill all children and exit.

You can also send SIGINT (Ctrl-C on your terminal) to restart the processes. If
a second SIGINT is received and no child process is currently running, the
supervisor will exit. This allows you to tap Ctrl-C twice in quick succession
in a terminal window to terminate the supervisor and all child processes.



# METHODS

## new

    my $sv = App::Sv->new({ run => {...}, global => {...}, log => {...} });

Creates a supervisor instance with a list of commands to monitor. It accepts
an anonymous hash with the following options:

- run

    A hash reference with the commands to execute and monitor. Each command can be
    a string, or a hash reference.

- run->{$name}->{cmd}

    A command to execute and monitor, along with command line options. Each
    command should be a string or an array reference. This can also be passed
    as `run->{$name}` if no other options are specified. In this case the
    supervisor will use the default values for the requred parameters.

- run->{$name}->{code}

    A code reference to execute an monitor. This should be a code reference or
    an array containing a code reference as the first element and the arguments
    to be passed to the code reference as the subsequent elements. It can also
    be passed as `run->{$name}` if no other options are specified in which
    case the default parameters are used. The `run->{$name}->{code}`
    and `run->{$name}->{cmd}` options are mutually exclusive.

- run->{$name}->{start\_retries}

    Specifies the number of execution attempts. For every command execution that
    fails within `restart_delay`, a counter is incremented until it reaches this
    value when no further execution attempts are made and the service is marked as 
    _fatal_. Otherwise the counter is reset. A null value disables restart; for 
    negative values restart is attempted indefinitely. The default value for this
    option is 8 start attempts.

- run->{$name}->{restart\_delay}

    Delay service restart by this many seconds. The default is 1 second. For null
    and negative values, the default is used.

- run->{$name}->{start\_wait}

    Number of seconds to wait before checking if the service is up and running and
    updating its state accordingly. The default is 1 second. For null and negative
    values, the default is used.

- run->{$name}->{stop\_wait}

    Number of seconds to wait before checking if the service has stopped and
    sending it SIGKILL if it hasn't. The default is 0, meaning forced service
    shutdown is disabled. For null and negative values, the default is used.

- run->{$name}->{umask}

    This option sets a custom umask in the child, before executing the command.
    Its value should be a string containing the octal digits.

- run->{$name}->{cwd}

    This option changes the child's working directory. Its value should be a
    string representing a path.

- run->{$name}->{setsid}

    This option specifies if a new session shall be created for the child, thus
    setting it as the process group leader. The default is 1, meaning yes.

- run->{$name}->{env}

    This option sets a custom %ENV in the child, before executing the command.
    Its value should be a hash reference containing the environment variables.

- run->{$name}->{user}

    Specifies the user name to run the command as.

- run->{$name}->{group}

    Specifies the group to run the command as.

- global

    A hash reference with the global configuration.

- global->{listen}

    The `host:port` to listen on. Also accepts unix domain sockets, in which case
    the host part should be `unix:/` and the port part should be the path to the
    socket. If this is a TCP socket, then the host part should be an IP address.

- global->{umask}

    This option sets the umask for the supervisor process. Its value is converted
    to octal. This acts as a global umask when no `run->{$name}->{umask}`
    option is set.

- log

    A hash reference with the logging options.

- log->{level}

    Enables logging at the given level and all lower (higher priority) levels. This
    should be an integer between 1 (fatal) and 9 (trace). For the actual names, see
    [AnyEvent::Log](https://metacpan.org/pod/AnyEvent::Log). If `SV_DEBUG` is set, this defaults to 8 (debug), otherwise
    it defaults to 5 (warn).

- log->{file}

    If this option is set, all the log messages are appended to this file. By
    default messages go to STDOUT or STDERR, whichever is open. By default logging
    goes to STDOUT.

- log->{ts\_format}

    This option defines timestamp format for the log messages, using `strftime`.
    The default format is "%Y-%m-%dT%H:%M:%S%z".

## run

    $sv->run;

Starts the supervisor, forks and executes all the services in child processes
and monitors each one.

This method returns when the supervisor is stopped with either a SIGINT or a
SIGTERM.

# ENVIRONMENT

- SV\_DEBUG 

    If set to a true value, the supervisor will show debugging information.

# AUTHOR

Gelu Lupaş <gvl@cpan.org>

# CONTRIBUTORS
 

- Pedro Melo <melo@simplicidade.org>

# SEE ALSO

[App::SuperviseMe](https://metacpan.org/pod/App::SuperviseMe), [ControlFreak](https://metacpan.org/pod/ControlFreak), [Supervisor](https://metacpan.org/pod/Supervisor)

# COPYRIGHT AND LICENSE
 

Copyright (c) 2011-2014 the App::Sv ["AUTHOR"](#AUTHOR) and ["CONTRIBUTORS"](#CONTRIBUTORS) as listed
above.
 

This is free software, licensed under:
 

    The Artistic License 2.0 (GPL Compatible)s
