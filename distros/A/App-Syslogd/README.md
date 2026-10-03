## Name

App::Syslogd - A small UDP syslog receiver that writes a CSV file

## Version

Version 0.002.0

## Synopsis

### 1. Run a Syslog Server

This is what the program `etc/syslogd` does.  It listens for messages
until it receives SIGTERM or SIGINT (Ctrl-C).

```perl
    use App::Syslogd;

    my $server = App::Syslogd->new(
            port => 5514,                           # 514 needs root
            file => '/var/log/syslogd/remote.csv',
    );
    $server->open_socket()->reopen_log();   # fail now, not later
    print $server->i18n('listening', {
            address => $server->address(),
            port => $server->port(),
    }), "\n";
    $server->run();                         # waits here until stopped
    print $server->i18n('shutdown', { count => $server->count() }), "\n";
```

### 2. Decode One Message, Without a Network or a File

`parse_message()` uses no state, so you can call it on the class.

```perl
    use App::Syslogd;

    my $record = App::Syslogd->parse_message('<34>su: authentication failure');
    print "facility $record->{facility}, severity $record->{severity}\n";
    # facility 4, severity 2
```

### 3. Record Messages That Your Own Code Received

Use this when your program already has a socket loop, for example an event
loop that watches many sockets.

```perl
    use App::Syslogd;
    use IO::Socket::IP;

    my $recorder = App::Syslogd->new(file => '/var/log/remote.csv', resolve => 0);
    $recorder->reopen_log();

    my $socket = IO::Socket::IP->new(LocalPort => 5514, Proto => 'udp')
            or die "Cannot listen: $IO::Socket::errstr";
    while(my $peer = $socket->recv(my $datagram, 65535)) {
            $recorder->process($datagram, $peer);
    }
```

### 4. Use a Socket That Someone Else Opened, for a Fixed Time

Pass the socket to `new()`, for example one received from systemd socket
activation, or one opened before giving up root.  `stop()` ends `run()`.

```perl
    my $server = App::Syslogd->new(socket => $already_bound_socket, file => $file);

    local $SIG{ALRM} = sub { $server->stop() };
    alarm(3600);            # stop after one hour
    $server->run();
```

### 5. Change How the Sender Is Written in the Log

`_peer_name()` is protected: a subclass may replace it.

```perl
    package My::Syslogd;
    use parent 'App::Syslogd';
    use Socket ();

    # Write "name [address]" instead of just the name
    sub _peer_name {
            my ($self, $peer) = @_;
            my $name = $self->SUPER::_peer_name($peer);
            my (undef, $address) = Socket::getnameinfo($peer, Socket::NI_NUMERICHOST());
            return "$name [$address]";
    }
```

## Description

This distribution has two parts: the module App::Syslogd, and the program
`etc/syslogd` that wraps it.  Installing from CPAN installs only the
module.  The program is not installed by `make install`; copy it by hand
(see ["INSTALLATION"](#installation)).

### What Syslog Is

Many machines (servers, routers, printers, firewalls) can send their log
messages over the network with the _syslog_ protocol.  Each message is one
UDP packet, called a _datagram_.  A message usually starts with a number in
angle brackets, the _PRI_ (priority), for example `<34>`.  The PRI
holds two smaller numbers:

- **facility** = PRI divided by 8, rounded down (0 to 23).  It says which
part of the system sent the message, for example 4 means "security".
- **severity** = the remainder of PRI divided by 8 (0 to 7).  It says how
serious the message is: 0 is "emergency" and 7 is "debug".

So `<34>` means facility 4 (34 / 8 = 4) and severity 2 (34 - 32 = 2).

### What This Module Does

It waits for syslog datagrams and adds one line to a CSV file for each one.
The first line of a new file names the columns:

```
    "Host","facility","severity","msg"
    "router.example.com","4","2","su: authentication failure"
```

- **Host** is the name of the machine that sent the message.  The name
is found with the normal system lookup (`/etc/hosts`, then DNS) and
remembered for a few minutes.  If no name is found, or if you turn names
off, the IP address is written instead.  IPv4 and IPv6 both work.  Whoever
controls an address controls its reverse-DNS name, so control characters in
a name are written as `\xNN`, as in the message.
- **facility** and **severity** come from the PRI.  If the PRI is missing
or not valid, the message is still kept: it is recorded as facility 1,
severity 5 ("user.notice"), and the whole datagram becomes the message.
RFC 3164 section 4.3.3 asks for this.  A valid PRI is a number from 0 to 191
with no extra leading zeros.
- **msg** is the rest of the datagram.  Line endings at the end are
removed.  Other control characters, including a newline in the middle, are
written as `\xNN` (for example `\x0A`).  So every message is exactly one
line, and nobody can create a fake extra line by sending a newline.

### Other Behaviour

- Signal **SIGHUP** closes and reopens the log file.  Log rotation tools
such as logrotate use this: they rename the file, then send SIGHUP, and the
server starts a new file.
- Signals **SIGTERM** and **SIGINT** stop the server cleanly.
- The log file is created so that only its owner can read it (mode
0600).  The server will not write through a symbolic link or a hard link, or
into a file that another user owns.  An existing file that is not empty
must start with the column-names line, so the server only ever adds to its
own logs: even as root, a wrong setting cannot make it append to (or change
the permissions of) some other file, such as `/etc/passwd`.  This protects
against attacks that trick a root process into overwriting a file.  (Windows
is weaker here: see ["LIMITATIONS"](#limitations).)
- Datagrams up to 65535 bytes (the largest UDP size) are read
completely.  Datagrams shorter than 2 characters are ignored.

## Command Line

The program `etc/syslogd` is a small wrapper around this module:

```
    /usr/local/etc/syslogd [--port 514] [--address 0.0.0.0] [--file /var/log/syslog/syslog.csv]
            [--no-resolve] [--language en]
```

- `--port` - the UDP port to listen on.  The default is 514, the
standard syslog port.  Ports below 1024 need root.
- `--address` - the local address to listen on.  The default
`0.0.0.0` means "every IPv4 address of this machine".  Use `::` for IPv6.
- `--file` - the CSV log file.  The default is
`/var/log/syslog/syslog.csv`.  The directory must exist and be writable by
the user that runs the server (see ["INSTALLATION"](#installation)).  On Debian, Ubuntu and
their derivatives `/var/log/syslog` is the system log file, so give
`--file` there (see ["LIMITATIONS"](#limitations)).
- `--no-resolve` - write IP addresses instead of host names.  This is
faster on a busy server.
- `--language` - the language of the program's own messages, for example
`en`.  By default it comes from the environment (`LANG` and similar).

Send **SIGHUP** to reopen the log file.  Send **SIGTERM**, or press Ctrl-C, to
stop.

### Log Rotation

Rotate the log by renaming it and then sending SIGHUP, so that the server
starts a new file.  See ["SAMPLE CONFIGURATION"](#sample-configuration) for logrotate and
newsyslog settings.

## Installation

Install the module from CPAN:

```
    cpanm App::Syslogd
```

or from a git checkout:

```
    perl Makefile.PL && make && make test && sudo make install
```

Then copy the program by hand, and create the directory for the default
log file (the server does not create directories):

```
    sudo cp etc/syslogd /usr/local/etc/
    sudo mkdir -m 700 /var/log/syslog
```

Make that directory belong to the user that runs the server, if it is not
root.  On Debian and Ubuntu `/var/log/syslog` is already a file; use
another directory and `--file` there.

`make install` does not install the program on purpose.  It would put it in
a `bin` directory, and a program called `syslogd` there could hide the
system's own `/usr/sbin/syslogd`.

To use a git checkout without installing the module, copy the module next to
the program:

```
    sudo cp -r lib/App /usr/local/lib/
```

The program looks for modules in `../lib` relative to itself (that is
`/usr/local/lib` after installation, or `lib/` in a git checkout), and also
in Perl's normal module directories.

## Sample Configuration

These samples run the server as its own user, `syslogd`, writing to
`/var/log/syslog/remote.csv`.  Adjust the names and paths to suit.

Three things shape them:

- The server only writes to a log file that it owns (see
["DESCRIPTION"](#description)), so the file must live in a directory the `syslogd` user
can write to.
- The server does not put itself in the background and writes no
process-id file: run it under a service manager that keeps it in the
foreground (systemd), or through `daemon(8)` (FreeBSD).
- The service is called `app-syslogd` (`app_syslogd` on FreeBSD)
so that it does not clash with the operating system's own syslog daemon.

Create the user first, for example:

```
    # Linux
    useradd --system --no-create-home --shell /usr/sbin/nologin syslogd

    # FreeBSD
    pw useradd syslogd -d /nonexistent -s /usr/sbin/nologin -c "App::Syslogd"
    mkdir -p /var/log/syslog && chown syslogd /var/log/syslog && chmod 700 /var/log/syslog
```

### Systemd (Linux)

Save as `/etc/systemd/system/app-syslogd.service`, then run
`systemctl daemon-reload` and `systemctl enable --now app-syslogd`.

```
    [Unit]
    Description=App::Syslogd UDP syslog receiver
    Documentation=https://metacpan.org/pod/App::Syslogd
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    User=syslogd
    Group=syslogd
    # Port 514 is below 1024: grant just that right, not root
    AmbientCapabilities=CAP_NET_BIND_SERVICE
    CapabilityBoundingSet=CAP_NET_BIND_SERVICE
    # Creates /var/log/syslog, owned by the user above
    LogsDirectory=syslog
    LogsDirectoryMode=0700
    ExecStart=/usr/local/etc/syslogd --port 514 --file /var/log/syslog/remote.csv
    # SIGHUP reopens the log after rotation
    ExecReload=/bin/kill -HUP $MAINPID
    Restart=on-failure
    RestartSec=5
    # Hardening: the server needs nothing more
    NoNewPrivileges=yes
    ProtectSystem=strict
    ProtectHome=yes
    PrivateTmp=yes
    PrivateDevices=yes
    RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

    [Install]
    WantedBy=multi-user.target
```

SIGTERM (`systemctl stop`) stops the server cleanly with exit status 0.
The server's start-up and shutdown lines go to the journal
(`journalctl -u app-syslogd`).

### rc.d and Service (FreeBSD)

Save as `/usr/local/etc/rc.d/app_syslogd` (mode 0555), then add
`app_syslogd_enable="YES"` to `/etc/rc.conf` and run
`service app_syslogd start`.

```
    #!/bin/sh

    # PROVIDE: app_syslogd
    # REQUIRE: NETWORKING
    # KEYWORD: shutdown

    . /etc/rc.subr

    name="app_syslogd"
    rcvar="app_syslogd_enable"

    load_rc_config $name

    : ${app_syslogd_enable:="NO"}
    : ${app_syslogd_user:="root"}
    : ${app_syslogd_options:="--port 514 --file /var/log/syslog/remote.csv"}

    pidfile="/var/run/${name}.pid"

    # daemon(8) puts the server in the background and writes the pid
    # file (-p: the server's own pid, so SIGHUP reaches it)
    command="/usr/sbin/daemon"
    command_args="-f -p ${pidfile} -u ${app_syslogd_user} /usr/local/etc/syslogd ${app_syslogd_options}"

    # The running process is "perl /usr/local/etc/syslogd ..."
    procname="/usr/local/etc/syslogd"
    command_interpreter="/usr/local/bin/perl"

    # service app_syslogd reload: reopen the log
    extra_commands="reload"
    sig_reload="HUP"

    run_rc_command "$1"
```

The options go in `app_syslogd_options`, not `app_syslogd_flags`:
`rc.subr` would put `_flags` before `command_args`, that is, give them to
`daemon(8)`.  Binding port 514 needs root on FreeBSD, so the sample runs as
root; to run as `syslogd`, use a port above 1023 (or
[mac\_portacl(4)](http://man.he.net/man4/mac_portacl)) and set `app_syslogd_user="syslogd"`.  The log file
must belong to whichever user runs the server.

### Logrotate (Linux)

Save as `/etc/logrotate.d/app-syslogd`.

```
    /var/log/syslog/remote.csv {
            weekly
            rotate 8
            compress
            delaycompress
            missingok
            # The directory belongs to syslogd, so rotate as that user
            su syslogd syslogd
            # Never copytruncate: see below
            create 0600 syslogd syslogd
            postrotate
                    systemctl reload app-syslogd.service
            endscript
    }
```

Do not use `copytruncate`.  It empties the log in place without telling
the server, which then carries on writing rows to a file with no column
names; at the next reopen the server would refuse that file, because it no
longer starts with the header line.  `create` (or no `create`: the server
makes the file itself on SIGHUP) is what the server expects.

### Newsyslog (FreeBSD)

Add to `/etc/newsyslog.conf` (or a file in `/usr/local/etc/newsyslog.conf.d/`):

```
    # logfilename                    owner:group  mode count size when  flags pid_file                  sig
    /var/log/syslog/remote.csv      root:wheel   600  8     *    @T00  JC    /var/run/app_syslogd.pid  1
```

Creates the new, empty file; signal 1 (SIGHUP) makes the server
reopen it.  Use the owner that runs the server.

### Monit and M/Monit

Add to `/etc/monit/monitrc` (Linux) or `/usr/local/etc/monitrc`
(FreeBSD).  M/Monit collects the results when `monitrc` names it with
`set mmonit`.

```perl
    # Report to M/Monit (optional)
    set mmonit https://monit:monit@mmonit.example.com:8443/collector

    # Linux, with the systemd unit above
    check process app-syslogd matching "/usr/local/etc/syslogd"
            start program = "/bin/systemctl start app-syslogd"
            stop program  = "/bin/systemctl stop app-syslogd"
            if 5 restarts within 5 cycles then alert

    # FreeBSD, with the rc.d script above, use instead:
    #       check process app_syslogd with pidfile /var/run/app_syslogd.pid
    #               start program = "/usr/sbin/service app_syslogd start"
    #               stop program  = "/usr/sbin/service app_syslogd stop"

    # The log must stay private and be written to
    check file app-syslogd-log with path /var/log/syslog/remote.csv
            if failed permission 600 then alert
            if failed uid "syslogd" then alert
            if timestamp > 1 hour then alert
```

Monit's UDP port test is not used: syslog never answers, so a port test
cannot show that messages are being recorded.  The timestamp check does:
change `1 hour` to suit how often your hosts send messages.

## Dependencies

Perl 5.14 or later, and these modules: [autodie](https://metacpan.org/pod/autodie) (which needs
[IPC::System::Simple](https://metacpan.org/pod/IPC%3A%3ASystem%3A%3ASimple)), [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP), [Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext),
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure), [Params::Get](https://metacpan.org/pod/Params%3A%3AGet), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict),
[Readonly](https://metacpan.org/pod/Readonly), [Socket](https://metacpan.org/pod/Socket),
[Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate), [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected) and [Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV).  `Makefile.PL` lists
the minimum versions.

## Files

- `etc/syslogd` - the command-line program.  Install it as
`/usr/local/etc/syslogd`.
- `lib/App/Syslogd.pm` - this module.
- `lib/App/Syslogd/I18N.pm` and `lib/App/Syslogd/I18N/en.pm` - the
messages that people see, and their English text.
- `lib/App/Syslogd/Cache.pm` - the built-in cache for host names.
- `t/` - the tests.  Run them with `prove -l t/`.
- `www/` - a web page that shows the log.  It is only in the git
repository, not in the CPAN distribution.

## Encoding

The module works with **bytes**, not with decoded text.  It never decodes or
encodes anything itself.

- **Datagrams** (`parse_message()`, `process()`, and everything that
`run()` receives) can contain any bytes.  UTF-8 text, other non-ASCII text
and emoji are written to the file exactly as they arrived.  Invalid UTF-8 is
also written unchanged.  Only bytes 0x00 to 0x1F and 0x7F are changed (to
`\xNN`).  Bytes 0x80 to 0x9F are not changed, so a UTF-8 character is never
broken.
- If you call `parse_message()` or `process()` yourself with a Perl
_character_ string (text that came from `decode()`, or that contains a
character above 255, such as an emoji written as `"\x{1F600}"`), first
encode it to bytes, for example with `Encode::encode('UTF-8', $text)`.
Otherwise Perl prints a "Wide character" warning when the line is written.
- **The file name** (`file`) is passed to the operating system as
bytes.  A name with non-ASCII characters must be given as encoded bytes
(normally UTF-8 on Unix).
- **Host names** come from the system resolver.  An international domain
name normally arrives in its ASCII form (`xn--...`).
- **The language tag** (`language`) must be ASCII, for example `en-gb`.
- **Messages from i18n()** are Perl strings.  The English messages are
ASCII, but a value you pass in (for example a file name) is copied into the
message as it is.  If you print a message that contains wide characters,
set an output layer first: `binmode(STDOUT, ':encoding(UTF-8)')`.

## Common Pitfalls

- **undef means "use the default".**  `new(file => undef)` gives the
default file, not an empty file name.  This is useful when you pass options
straight from [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong), but it means you cannot use `undef` to switch
something off.  To turn off host names, use `resolve => 0`.
- **The environment wins over your arguments.**  An
`App__Syslogd__port` environment variable, or a configuration file, changes
the port even when you pass `port` to `new()`.  This is how
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) works.  Check the environment when a setting seems to
be ignored.
- **The options are merged one level deep only.**  Each option you give
replaces the default with the same name; nothing is merged inside a value.
Objects you pass (`cache`, `socket`) are shared, not copied: two servers
given the same `cache` object share their host name answers.
- **True and false.**  `resolve` accepts 1, 0, and the words `true`,
`false`, `yes`, `no`, `on` and `off`.  Any other value, such as 2, is an
error.
- **Order of calls.**  `process()` needs an open log, so call
`reopen_log()` first.  `run()` opens the socket and the log by itself if
you have not.
- **Signals are handled only inside run().**  Before `run()` starts and
after it returns, SIGHUP has its normal effect, which is to end the program.
`run()` puts back your own signal handlers when it returns.
- **stop() before run() does nothing.**  `run()` sets the "running"
flag when it starts, so an earlier `stop()` is forgotten.
- **run() closes everything when it returns.**  If you call `run()`
again, it opens a new socket.  With `port => 0`, the new socket can get
a different port number.
- **A failed reopen stops run().**  If SIGHUP arrives and the log file
cannot be opened (for example, the directory was removed), `run()` dies
with the error.  The socket stays open and the log stays closed.
- **An existing log file is made private.**  `reopen_log()` changes the
file's permissions to 0600 without asking (except on Windows; see
["LIMITATIONS"](#limitations)).
- **Do not rotate with copytruncate.**  Emptying the log in place
leaves the server writing rows with no column names, and the next reopen
then refuses the file.  Rename and send SIGHUP instead (see
["SAMPLE CONFIGURATION"](#sample-configuration)).
- **Only an empty file or one of its own logs is accepted.**  A file
with content must start with the line `"Host","facility","severity","msg"`
(with a Unix or Windows line end), or `reopen_log()` refuses it and leaves
it untouched.  Logs from older versions start with that line too.  To reuse
a file that does not, empty it or remove it first.
- **A short datagram is ignored silently.**  After removing line endings
at the end, a datagram must have at least 2 characters.  `parse_message()`
then returns `undef`, and `process()` writes nothing and does not count it.
- **A missing sender is not an error.**  `process($datagram, undef)`
writes the message with an empty Host column.
- **port() and address() change meaning.**  Before `open_socket()` they
return what you asked for.  After it they return what the system actually
gave, so `port => 0` becomes a real port number.
- **Backslashes are not escaped.**  A message that really contains the
four characters `\x0A` looks the same in the file as an escaped newline.

## Methods

Every method except `parse_message()` and `i18n()` needs an object made by
`new()`; those two also work on the class.  Methods that have nothing
useful to return give back the object, so you can chain calls:

```perl
    App::Syslogd->new(port => 5514)->open_socket()->reopen_log()->run();
```

No method changes the caller's `$_`, `$!` or `$@`, or an `alarm()`
that is counting down.  (A method that dies sets `$@`, as `die` always
does.)

The mathematical description of each method is in
["FORMAL SPECIFICATION"](#formal-specification), and the life cycle of an object is in
["STATE DIAGRAM"](#state-diagram), both at the end of this document.

### New

Purpose: make a new server object.  It does not open the network or the
file yet, so you can create and inspect it without any special permissions.

Args: all optional, given as a list of pairs or as one hash reference.  An
option given as `undef` uses its default.

Every option can also be set outside the program, through
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure): in a configuration file (for example
`~/.conf/app-syslogd.yml`), or in an environment variable named
`App__Syslogd__` followed by the option, such as
`App__Syslogd__port=5514`.  **Those settings win over the arguments given
to new()**.  They are checked in exactly the same way as arguments.

- `port` - the UDP port number, 0 to 65535.  Default 514.  0 means
"let the system choose a free port"; call `port()` after `open_socket()`
to find out which one.
- `address` - the local address to listen on.  Default `0.0.0.0` (all
IPv4 addresses).  Use `::` for IPv6.
- `file` - the CSV log file.  Default `/var/log/syslog/syslog.csv`;
its directory must already exist.
- `resolve` - true (the default) to write host names, false to write
IP addresses.
- `dns_ttl` - how many seconds to remember a host name.  Default 300.
- `dns_cache_bytes` - the most memory, in bytes, used to remember host
names.  Default 262144.  An estimate: see ["new" in App::Syslogd::Cache](https://metacpan.org/pod/App%3A%3ASyslogd%3A%3ACache#new).  It
does not apply to a `cache` you supply.
- `language` - the language of messages, such as `en`.  Default: from
the environment.
- `cache` - your own cache for host names, instead of the built-in
[App::Syslogd::Cache](https://metacpan.org/pod/App%3A%3ASyslogd%3A%3ACache).  Any object with a [CHI](https://metacpan.org/pod/CHI)-style `compute()` method,
for example a [CHI](https://metacpan.org/pod/CHI) cache shared between several servers.
- `socket` - a socket that is already open, instead of opening one.
Any object with a `recv()` method.

Returns: the new object.  Besides the options, it holds the `logger` (a
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) object) and `config_path` that [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)
provides.

Side Effects: reads configuration files and environment variables (see
above).  Does not open the network or the log.  Dies if an option is
unknown, or if an option has a wrong value, wherever the value came from.

Usage:

```perl
    my $server = App::Syslogd->new({ port => 514, resolve => 0 });
```

#### Example

```perl
    # Listen on a port that does not need root, and write addresses only
    my $server = App::Syslogd->new(port => 5514, resolve => 0);

    # Options from Getopt::Long: options not given stay undef = default
    my %opts;
    GetOptions(\%opts, 'port=i', 'file=s');
    my $server2 = App::Syslogd->new(\%opts);
```

#### Api Specification

##### Input

```perl
    {
            port => { type => 'integer', min => 0, max => 65535, optional => 1 },
            address => { type => 'string', min => 1, optional => 1 },
            file => { type => 'string', min => 1, optional => 1 },
            resolve => { type => 'boolean', optional => 1 },
            dns_ttl => { type => 'integer', min => 0, optional => 1 },
            dns_cache_bytes => { type => 'integer', min => 1, optional => 1 },
            language => { type => 'string', min => 1, optional => 1 },
            cache => { type => 'object', can => ['compute'], optional => 1 },
            socket => { type => 'object', can => ['recv'], optional => 1 },
    }
```

Domains (equivalence partitions and boundaries; t/domain.t tests each):

```
    +-----------------+--------------------------------+-----------------------+-------------------------------+
    | Option          | Valid partitions               | Boundaries            | Invalid partitions            |
    +-----------------+--------------------------------+-----------------------+-------------------------------+
    | port            | 0 (the kernel chooses);        | -1 no, 0 yes,         | fractions (514.5), hex        |
    |                 | 1-1023 (needs root);           | 65535 yes, 65536 no   | (0x10), "1_000", text, "",    |
    |                 | 1024-65535.  A numeric string  |                       | non-ASCII digits, references  |
    |                 | is read as its number: " 514 ",|                       |                               |
    |                 | "+514", "0514", "5e2", "5.0"   |                       |                               |
    | address         | IPv4 or IPv6 literal, or a     | 1 character is        | "" (new()); an address this   |
    |                 | host name: any non-empty       | accepted by new()     | machine does not have (fails  |
    |                 | string here                    |                       | in open_socket())             |
    | file            | any non-empty string of bytes; | 1 byte; the system's  | ""; references.  A name over  |
    |                 | non-ASCII names as encoded     | name limit (usually   | the system limit, or an       |
    |                 | (UTF-8) bytes                  | 255 bytes)            | existing file with content    |
    |                 |                                |                       | that does not start with the  |
    |                 |                                |                       | header, fails in reopen_log() |
    | resolve         | true: 1 true TRUE yes on;      | -                     | any other spelling: "", 2,    |
    |                 | false: 0 false FALSE no off    |                       | "Yes", "On", " 1", "t"        |
    | dns_ttl         | whole seconds, 0 or more (0:   | -1 no, 0 yes; no      | fractions, text, references   |
    |                 | names are not reused)          | upper limit           |                               |
    | dns_cache_bytes | whole bytes, 1 or more         | 0 no, 1 yes; no upper | fractions, text, references   |
    |                 |                                | limit                 |                               |
    | language        | any non-empty tag; tags with   | 1 character is        | "" (refused); unknown or      |
    |                 | no lexicon (fr, x, i-klingon)  | accepted              | malformed tags are not an     |
    |                 | fall back to English           |                       | error: they give English      |
    | cache, socket   | an object with compute() /     | -                     | plain hashes, code, globs, an |
    |                 | recv()                         |                       | object without the method     |
    +-----------------+--------------------------------+-----------------------+-------------------------------+
```

`address`, `file` and `language` must not contain a NUL byte (refused:
"must match pattern"): the C library would stop reading at the NUL, so the
server would bind or write somewhere other than the value it reports.

An undef value is in no partition: it means "use the default".  Options
are checked one by one, so the error names the first invalid option even
when the others are at their limits.

##### Output

```perl
    { type => 'object', isa => 'App::Syslogd' }
```

#### Messages

```
    +------------------------------------+--------------------------+-----------------------------+
    | Message (dies)                     | Meaning                  | What to do                  |
    +------------------------------------+--------------------------+-----------------------------+
    | validate_strict: Unknown parameter | An option name is wrong  | Check the spelling against  |
    |   'x'                              |                          |   the list above            |
    | validate_strict: Parameter 'port'  | A value is the wrong     | Use a whole number from 0   |
    |   (x) must be an integer           |   type                   |   to 65535                  |
    | validate_strict: Parameter 'port'  | A number is out of range | Use a value inside the      |
    |   (x) must be no more than 65535   |                          |   range shown above         |
    | validate_strict: Parameter 'X'     | A number is below its    | Use a value inside the      |
    |   (x) must be at least 0, or must  |   minimum (port, dns_ttl |   range in the Domains      |
    |   be a positive number             |   at 0; dns_cache_bytes  |   table                     |
    |                                    |   at 1)                  |                             |
    | validate_strict: Parameter         | Not a true/false value   | Use 1, 0, true, false, yes, |
    |   'resolve' (x) must be a boolean  |                          |   no, on, off, TRUE, FALSE  |
    | validate_strict: Parameter 'X'     | address, file or language| Remove the NUL byte         |
    |   (x) must match pattern ...       |   contains a NUL byte    |                             |
    +------------------------------------+--------------------------+-----------------------------+
```

#### Pseudocode

```
    check the options against the schema (die if one is wrong)
    remove options whose value is undef
    start from the defaults, then copy the options over them
    set the message counter to 0
    choose the message language
    if no cache was given, make an in-memory cache
    make the CSV writer
    return the object
```

### Open\_Socket

Purpose: start listening for UDP datagrams on the configured address and
port.  If the port is below 1024, do this before your program gives up root.

Args: none.

Returns: the object, so you can chain another call.

Side Effects: opens a UDP socket.  Does nothing if a socket is already open,
including one given to `new()`.

Usage:

```
    $server->open_socket();
```

#### Example

```perl
    # Let the system choose a free port, then ask which one it chose
    my $server = App::Syslogd->new(port => 0)->open_socket();
    print 'Listening on port ', $server->port(), "\n";
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::Syslogd' }
```

#### Messages

```perl
    +---------------------------------+---------------------------+------------------------------+
    | Message (dies)                  | Meaning                   | What to do                   |
    +---------------------------------+---------------------------+------------------------------+
    | Could not create a UDP socket   | The system refused: the   | Run as root for ports below  |
    |   on ADDR port N: ERROR         |   port is in use, needs   |   1024, stop the other       |
    |                                 |   root, or the address is |   syslog server, or correct  |
    |                                 |   wrong                   |   the address                |
    +---------------------------------+---------------------------+------------------------------+
```

### Port

Purpose: tell you the UDP port number.

Args: none.

Returns: a whole number from 0 to 65535.  Before `open_socket()` it is the
port you asked for.  After it, it is the port really in use, so
`port => 0` becomes the number the system chose.  If the socket was
given to `new()` and has no `sockport()` method (a simple test double, for
example), it is the port you asked for.

Side Effects: none.

Usage:

```perl
    my $port = $server->port();
```

#### Example

```
    print App::Syslogd->new()->port(), "\n";        # 514
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'integer', min => 0, max => 65535 }
```

Domain: 0 to 65535.  0 only before open\_socket() with `port => 0`;
after open\_socket(), 1 to 65535.

#### Messages

None.

### Address

Purpose: tell you the local address the server listens on.

Args: none.

Returns: a string, such as `0.0.0.0` or `::1`.  Before `open_socket()` it
is the address you asked for.  After it, it is the address the system reports.
If the socket was given to `new()` and has no `sockhost()` method, it is
the address you asked for.

Side Effects: none.

Usage:

```perl
    my $address = $server->address();
```

#### Example

```perl
    print App::Syslogd->new(address => '::')->address(), "\n";      # ::
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'string', min => 1 }
```

#### Messages

None.

### Count

Purpose: tell you how many datagrams have been written to the log.

Args: none.

Returns: a whole number, 0 or more.  Ignored datagrams (shorter than 2
characters) are not counted.  A datagram that could not be written because
the disk was full is counted.

Side Effects: none.

Usage:

```
    print $server->count(), " messages\n";
```

#### Example

```
    $server->reopen_log()->process('<13>hello', $peer);
    print $server->count(), "\n";   # 1
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'integer', min => 0 }
```

Domain: 0 or more; it only ever grows, by one for each datagram that was
not too short.

#### Messages

None.

### Reopen\_Log

Purpose: open the CSV log file, closing it first if it is already open.  Use
it once at the start.  `run()` also calls it when SIGHUP arrives, so that
after a log rotation tool renames the file, a new file is started.

Args: none.

Returns: the object, so you can chain another call.

Side Effects:

- Closes the log file if it is open.
- Creates the file if it does not exist, readable only by its owner.
- Writes the column names if the file is empty.
- Refuses (and does not change) a file with content that does not
start with the column names: only the server's own logs are reused.
- Changes an existing file's permissions to 0600 (not on Windows),
after the checks above.
- Dies, leaving no log open, if the file cannot be used safely.

Usage:

```
    $server->reopen_log();
```

#### Example

```perl
    # Open the log before starting, so that a problem is reported at once
    my $server = App::Syslogd->new(file => '/var/log/remote.csv');
    eval { $server->reopen_log(); 1 } or die "Cannot start: $@";
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::Syslogd' }
```

#### Messages

```
    +-------------------------------+--------------------------------+-------------------------------+
    | Message (dies)                | Meaning                        | What to do                    |
    +-------------------------------+--------------------------------+-------------------------------+
    | Could not open log file F:    | The system could not open the  | Create the directory, or fix  |
    |   ERROR                       |   file.  ERROR is the system's |   its permissions.  Remove a  |
    |                               |   reason.  A symbolic link, a  |   symbolic link or FIFO; give |
    |                               |   directory or a FIFO (named   |   a file name, not a          |
    |                               |   pipe) also gives this        |   directory                   |
    | Refusing to log to F: it must | F is a hard link or another    | Remove F and let the server   |
    |   be a regular file, owned by |   user's file                  |   create it again             |
    |   this user, with exactly one |                                |                               |
    |   link                        |                                |                               |
    | Refusing to log to F: it is   | F has content but is not one   | Check the file setting; empty |
    |   not empty and does not      |   of the server's logs (it     |   or remove F if it really is |
    |   start with the syslog       |   does not start with the      |   meant to be the log         |
    |   header line                 |   column names)                |                               |
    | Could not write to log file   | The column names could not be  | Free some disk space          |
    |   F: ERROR                    |   written to a new file        |                               |
    +-------------------------------+--------------------------------+-------------------------------+
```

### Parse\_Message

Purpose: split one datagram into its facility, severity and message text.
It uses no state and writes nothing, so you can call it on the class and use
it on its own.

Args: one datagram, as a string of bytes.

Returns: `undef` if the datagram is too short to be a message (fewer than 2
characters after removing line endings at the end).  Otherwise a hash
reference with these keys:

- `facility` - 0 to 23.
- `severity` - 0 to 7.
- `message` - the text after the PRI, with control characters
written as `\xNN`.
- `valid` - 1 if the datagram had a valid PRI.  0 if not; then facility
is 1, severity is 5, and `message` is the whole datagram.

Side Effects: none.

Usage:

```perl
    my $record = App::Syslogd->parse_message($datagram);
```

#### Example

```perl
    my $r = App::Syslogd->parse_message("<34>su: 'su root' failed\n");
    # { facility => 4, severity => 2, message => "su: 'su root' failed", valid => 1 }

    $r = App::Syslogd->parse_message("no pri\there");
    # { facility => 1, severity => 5, message => 'no pri\x09here', valid => 0 }

    $r = App::Syslogd->parse_message("x\n");
    # undef: too short
```

#### Api Specification

##### Input

```perl
    {
            datagram => { type => 'string', optional => 1, position => 0 },
    }
```

Domains of the datagram (`message` is the part after the PRI):

```
    +-----------------+-----------------------------------+----------------------------------+
    | Partition       | Examples                          | Result                           |
    +-----------------+-----------------------------------+----------------------------------+
    | too short       | undef, "", "x", "x\n" (fewer than | undef                            |
    |                 | 2 characters after removing       |                                  |
    |                 | trailing CR, LF and NUL)          |                                  |
    | valid PRI       | "<0>" to "<191>", no extra        | facility = PRI div 8 (0-23),     |
    |                 | leading zeros                     | severity = PRI mod 8 (0-7),      |
    |                 |                                   | valid 1                          |
    | invalid PRI     | "<192>", "<013>", "<1000>", "<>", | facility 1, severity 5, the      |
    |                 | no PRI at all                     | whole text, valid 0              |
    | control bytes   | 0x00-0x1F and 0x7F                | written as \xNN                  |
    | other bytes     | UTF-8 (umlauts, emoji, combining  | unchanged, same length           |
    |                 | "Zalgo" marks, the RTL override   |                                  |
    |                 | U+202E), invalid UTF-8, C1 bytes  |                                  |
    | references      | [], {}, code, globs               | dies: A datagram must be a       |
    |                 |                                   | string ...                       |
    +-----------------+-----------------------------------+----------------------------------+
```

Boundaries: length 1 gives undef and 2 gives a record; PRI 191 is valid and
192 is not; PRI 7/8, 15/16, ... are the edges between facilities.  The
largest UDP datagram (65535 bytes) is accepted whole.

##### Output

```perl
    {
            type => 'hashref',
            optional => 1,
            schema => {
                    facility => { type => 'integer', min => 0, max => 23 },
                    severity => { type => 'integer', min => 0, max => 7 },
                    message => { type => 'string', matches => qr/\A[^\x00-\x1F\x7F]*\z/ },
                    valid => { type => 'boolean' },
            },
    }
```

#### Messages

```
    +------------------------------------+------------------------------+-----------------------------+
    | Message (dies)                     | Meaning                      | What to do                  |
    +------------------------------------+------------------------------+-----------------------------+
    | A datagram must be a string (the   | A reference was passed; it   | Pass the received bytes     |
    |   type given was TYPE)             |   would have been recorded   |                             |
    |                                    |   as "ARRAY(0x...)"          |                             |
    +------------------------------------+------------------------------+-----------------------------+
```

A malformed string is recorded, never rejected.  An object that turns
itself into a string (overloads `""`) is accepted as that string.

#### Pseudocode

```perl
    treat undef as an empty string
    remove CR, LF and NUL characters from the end
    if fewer than 2 characters remain: return undef
    if the text is "<" NUMBER ">" REST, where NUMBER is 0 to 191
       written without extra leading zeros:
            valid = 1
    else:
            NUMBER = 13, REST = the whole text, valid = 0
    return {
            facility => NUMBER divided by 8, rounded down,
            severity => remainder of NUMBER divided by 8,
            message  => REST with control characters written as \xNN,
            valid    => valid,
    }
```

### Process

Purpose: write one received datagram to the log.

Args:

- 1. The datagram, as a string of bytes.
- 2. The sender's address, in the packed form that `recv()` returns.
`undef`, or anything that is not a packed address (such as a reference),
gives an empty Host column.

Returns: the object, so you can chain another call.

Side Effects:

- May look up the sender's host name (the answer is remembered).  If
the cache fails (dies) or gives no answer, the IP address is written: a cache
problem never stops the logging.
- Adds one line to the log and adds 1 to `count()`, unless the
datagram is too short, in which case nothing happens.
- If the line cannot be written (for example, the disk is full), it
warns and continues.  That message is lost, but the server keeps working.
If only part of the line fitted, the part is removed again, so the file
never holds a half line and the next message starts on a line of its own.

Usage:

```perl
    my $peer = $socket->recv(my $datagram, 65535);
    $server->process($datagram, $peer);
```

#### Example

```perl
    use Socket qw(pack_sockaddr_in inet_aton);

    my $peer = pack_sockaddr_in(514, inet_aton('192.0.2.1'));
    $server->reopen_log()->process('<13>hello', $peer);
    # The file now ends with: "192.0.2.1","1","5","hello"
```

#### Api Specification

##### Input

```perl
    {
            datagram => { type => 'string', optional => 1, position => 0 },
            peer => { type => 'string', optional => 1, position => 1 },
    }
```

Domains of the sender: a packed IPv4 or IPv6 address gives that address
(or its name); undef, "", short or garbage strings and references give an
empty Host.  The datagram has the domains listed under ["parse\_message"](#parse_message).

##### Output

```perl
    { type => 'object', isa => 'App::Syslogd' }
```

#### Messages

```
    +-----------------------------------+------------------------------+-------------------------------+
    | Message                           | Meaning                      | What to do                    |
    +-----------------------------------+------------------------------+-------------------------------+
    | process() was called before       | No log file is open (dies)   | Call reopen_log() first       |
    |   reopen_log() succeeded          |                              |                               |
    | A datagram must be a string (the  | The datagram was a reference | Pass the received bytes       |
    |   type given was TYPE)            |   (dies)                     |                               |
    | Could not write to log file F:    | The line was not written,    | Free disk space; this message |
    |   ERROR                           |   e.g. disk full, or the CSV |   is lost, later ones are not |
    |                                   |   writer refused (warning)   |                               |
    +-----------------------------------+------------------------------+-------------------------------+
```

### Run

Purpose: the main loop.  Wait for datagrams and write each one to the log,
until told to stop.

Args: none.

Returns: the object, after SIGTERM, SIGINT or `stop()`.

Side Effects:

- Calls `open_socket()` and `reopen_log()` first if they have not been
called.  The socket comes first, so if it cannot be opened, `run()` dies
before the log file is touched.  Starting is all or nothing: if the log
cannot be opened, a socket that `run()` opened itself is closed again
before `run()` dies (a socket you opened, or gave to `new()`, is left
open).

    Why the loop never checks for a socket: `open_socket()` either gives a
    socket or dies (premise 1); the loop only starts after it (premise 2); so
    inside the loop the socket always exists (conclusion).

- While it runs: SIGHUP reopens the log, and SIGTERM or SIGINT stop the
loop.  Your own handlers for these three signals are put back when it
returns.
- When it returns, the socket and the log file are closed.

Usage:

```
    $server->run();
```

#### Example

```perl
    my $server = App::Syslogd->new(port => 5514, file => '/var/log/remote.csv');
    $server->run();         # Ctrl-C to stop
    print $server->i18n('shutdown', { count => $server->count() }), "\n";
    # Syslog server shutting down after recording 42 messages
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::Syslogd' }
```

#### Messages

```
    +---------------------------------+--------------------------------+------------------------------+
    | Message                         | Meaning                        | What to do                   |
    +---------------------------------+--------------------------------+------------------------------+
    | Error receiving a datagram:     | Reading from the network       | Usually nothing: the loop    |
    |   ERROR                         |   failed (warning).  Not given |   continues.  If it repeats, |
    |                                 |   when a signal interrupts the |   check the network          |
    |                                 |   wait                         |                              |
    | Any message of open_socket() or | Starting, or reopening the     | See those methods            |
    |   reopen_log()                  |   log after SIGHUP, failed     |                              |
    |                                 |   (dies)                       |                              |
    +---------------------------------+--------------------------------+------------------------------+
```

#### Pseudocode

```
    open_socket()           (does nothing if a socket is already open)
    if no log is open: reopen_log()
    for the duration of run():
            SIGHUP          -> set "reopen requested"
            SIGTERM, SIGINT -> clear "running"
    set "running"
    while "running":
            if "reopen requested": clear it, then reopen_log()
            wait for a datagram
            if a datagram arrived: process() it
            (a signal ends the wait early, so the flags are seen at once;
             any other read error is a warning, and the loop continues)
    close the socket and the log
    put back the caller's signal handlers
    return the object
```

### Stop

Purpose: ask `run()` to finish.  `run()` returns after the datagram it is
handling, or at once if it is waiting.

Args: none.

Returns: the object.

Side Effects: clears the "running" flag.  Calling it before `run()` has no
effect, because `run()` sets the flag when it starts.

Usage:

```
    $server->stop();
```

#### Example

```perl
    # Run for one minute
    local $SIG{ALRM} = sub { $server->stop() };
    alarm(60);
    $server->run();
```

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    { type => 'object', isa => 'App::Syslogd' }
```

#### Messages

None.

### i18n

Purpose: make a message for people to read, in the server's language.  All
of this module's own messages are made with it, so they can be translated.

Args:

- 1. The message key, for example `listening`.  The keys are in the
table below.
- 2. Optional: a hash reference of values to put into the message, for
example `{ port => 514 }`.  A missing value becomes an empty string.

It also works on the class (`App::Syslogd->i18n(...)`); the language then
comes from the environment.

Returns: the message as a string.  An unknown key does not die: you get the
key and its values back, such as `no_such_key (a=1)`.

Side Effects: none.

Usage:

```perl
    print $server->i18n('listening', { address => '0.0.0.0', port => 514 }), "\n";
```

#### Example

```perl
    print App::Syslogd->i18n('shutdown', { count => 1 }), "\n";
    # Syslog server shutting down after recording 1 message
    print App::Syslogd->i18n('shutdown', { count => 3 }), "\n";
    # Syslog server shutting down after recording 3 messages
```

#### Api Specification

##### Input

```perl
    {
            key => { type => 'string', min => 1, position => 0 },
            args => { type => 'hashref', optional => 1, position => 1 },
    }
```

Domains: `key` is one of the keys in the table below (an unknown key gives
the key back; undef, "" or a reference dies).  `args` is a hash reference
or undef; anything else dies, including `""` and `0`.  Values may be any text, including
non-ASCII characters, which appear unchanged.  For `count`, 1 gives the
singular and every other number (0, 2, -1, 1.5) the plural; text that is
not a number counts as 0.

##### Output

```perl
    { type => 'string' }
```

#### Messages

The keys, the values each one uses, and the English text:

```
    +---------------+------------------------+--------------------------------------------------+
    | Key           | Values                 | English text                                     |
    +---------------+------------------------+--------------------------------------------------+
    | usage         | program                | Usage: PROGRAM [--port <port_number>] ...        |
    | listening     | address, port          | Syslog server listening on ADDRESS UDP port PORT |
    | shutdown      | count                  | Syslog server shutting down after recording      |
    |               |                        |   COUNT message(s)                               |
    | socket_failed | address, port, error   | Could not create a UDP socket on ADDRESS port    |
    |               |                        |   PORT: ERROR                                    |
    | open_failed   | file, error            | Could not open log file FILE: ERROR              |
    | unsafe_file   | file                   | Refusing to log to FILE: it must be a regular    |
    |               |                        |   file, owned by this user, with exactly one     |
    |               |                        |   link                                           |
    | write_failed  | file, error            | Could not write to log file FILE: ERROR          |
    | recv_failed   | error                  | Error receiving a datagram: ERROR                |
    | no_log_open   | (none)                 | process() was called before reopen_log()         |
    |               |                        |   succeeded                                      |
    | not_a_datagram| type                   | A datagram must be a string (the type given was  |
    |               |                        |   TYPE)                                          |
    | missing_key   | (none)                 | A message key is needed                          |
    | bad_values    | type                   | Message values must be a hash reference (the     |
    |               |                        |   type given was TYPE)                           |
    | no_progress   | (none)                 | the system accepted no data (the ERROR part of   |
    |               |                        |   write_failed when a write makes no progress)   |
    | not_cgi       | (none)                 | This program is a server, not a CGI program: it  |
    |               |                        |   will not run from a web server                 |
    | not_a_log     | file                   | Refusing to log to FILE: it is not empty and     |
    |               |                        |   does not start with the syslog header line     |
    | already_running | (none)               | run() is already running                         |
    +---------------+------------------------+--------------------------------------------------+
```

## Security

This module is not a CGI program: it reads no HTTP request, no
`QUERY_STRING`, `PATH_INFO`, cookies or other `HTTP_*` variables, and
never reads standard input.  It writes CSV, not HTML.  Its untrusted
inputs, and what protects against each, are:

```
    +----------------------+--------------------------+----------------------------------------+
    | Input                | Controlled by            | Protection                             |
    +----------------------+--------------------------+----------------------------------------+
    | UDP datagrams        | anyone who can reach the | stored as data only; control           |
    |                      | port                     | characters written as \xNN (no forged  |
    |                      |                          | lines, no terminal escapes); never     |
    |                      |                          | reflected into warnings or errors      |
    | reverse-DNS names    | whoever owns the         | escaped like messages                  |
    |                      | sender's address         |                                        |
    | App__Syslogd__*      | whoever starts the       | validated like arguments; tainted      |
    | variables, config    | server                   | values are refused under perl -T       |
    | files                |                          | (never untainted)                      |
    | LANG, LANGUAGE, LC_* | whoever starts the       | a tag can only select a lexicon        |
    |                      | server                   | package; unknown tags give English     |
    +----------------------+--------------------------+----------------------------------------+
```

It never runs another program (no `system`, `exec`, backticks or piped
`open`), so shell metacharacters in any input are only ever text.  File
names are passed to the system directly, never to a shell.  An existing
file is only reused if it is empty or already one of the server's logs, so
even as root a mistaken or hostile `file` setting cannot make the server
append to, or change the permissions of, a file such as `/etc/passwd`.
Markup such as
`<script>` in a message is stored unchanged: a program that shows the
log in a web page (for example the viewer in `www/`) must HTML-encode it.

## Limitations

- **The default directory is a file on Debian and Ubuntu.**  The
default log is `/var/log/syslog/syslog.csv`, but on Debian, Ubuntu and
their derivatives `/var/log/syslog` is rsyslog's own log file, so the
server cannot start with the default there ("Not a directory").  Give
`file` (or `--file`), for example `/var/log/syslog/syslog.csv` as in
["SAMPLE CONFIGURATION"](#sample-configuration).
- **The default directory must already exist.**  The server does not
create directories: create `/var/log/syslog` (see ["INSTALLATION"](#installation)), or the
server stops with "Could not open log file ...: No such file or directory".
Versions before 0.002.0 logged to `/tmp/syslog.log` by default.
- **The web viewer cannot read the log.**  The file is readable only by
its owner (usually root), but the web pages in `www/` run as the web
server's user.  You must choose between privacy and the viewer, for example
by using a shared group and changing `$LOG_MODE` in the source.
- **It does not give up root.**  Port 514 needs root (or the
CAP\_NET\_BIND\_SERVICE capability), and the server keeps root while it runs.
Better: use a port above 1023 with a firewall redirect, or let systemd open
the socket and pass it with `new(socket => ...)`.
- **No time of arrival.**  A line holds only what the sender put in the
message.  Adding a column would break existing files and the web viewer, so
it needs a migration and has not been done.
- **Host name lookups block.**  Answers are remembered, but the first
message from a host with a slow DNS server makes the loop wait, and the
system may drop datagrams that arrive during the wait.  Use `--no-resolve`
on a busy server.
- **UDP only.**  There is no TCP (RFC 6587) or TLS (RFC 5425).  So
delivery is not guaranteed, and anyone who can reach the port can write to
the log.
- **Only the PRI is decoded.**  Time stamps and host names inside RFC 3164
messages, and RFC 5424 structured data, stay in the `msg` column.
- **Spreadsheet formulas.**  A message that starts with `=`, `+`, `-`
or `@` may run as a formula if you open the file in a spreadsheet.  The
data is kept unchanged on purpose; take care when you open it.
- **Backslashes are not escaped**, so the text `\x0A` and an escaped
newline look the same (see ["COMMON PITFALLS"](#common-pitfalls)).
- **Windows is less protected.**  The module works on Windows, but:
    - Windows has no `O_NOFOLLOW`, so the server cannot refuse a symbolic
    link as the log file.  (Creating a symbolic link on Windows normally needs
    administrator rights, which makes this attack rare.)
    - Mode 0600 does not make the file private: Windows uses access control
    lists, which this module does not change.  An existing file's permissions
    are not changed either, because Windows Perl cannot change the permissions
    of an open file.  Put the log in a folder that only the right users can
    read.
    - There is no `kill -HUP` from outside the process, so log rotation by
    signal is not available.  Stop and restart the server instead.
    - A signal such as Ctrl-C may not interrupt the wait for a datagram, so
    the server may stop only after the next datagram arrives.
- **Do not send the logger's output to this server.**  [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)
gives each object a logger, and a shared configuration file may point it
at syslog.  This module does not log through it today, but if it ever
does, a logger that sends to the same syslog server would feed its own
input back to itself.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes each method exactly, in the Z notation.  You do not
need it to use the module; the descriptions in ["METHODS"](#methods) say the same
things in words.

### State

```
    [ADDRESS, PATH, LANGTAG, SOCKADDR, BYTE, NAME, VALUE]
    PORT == 0 .. 65535
    HEADER == ⟨"Host", "facility", "severity", "msg"⟩
    RECORD == ⟨facility : 0 .. 23, severity : 0 .. 7,
               message : seq BYTE, valid : 𝔹⟩

    Server
      port : PORT ; address : ADDRESS ; file : PATH
      resolve : 𝔹 ; language : LANGTAG
      count : ℕ
      bound, logging, running, hup : 𝔹
      contents : PATH ⇸ seq (seq BYTE)
      ─────────
      running ⇒ bound ∧ logging

    ΞServer ≙ [ ΔServer | θServer' = θServer ]
```

### New

```
    New
      Server'
      args? : NAME ⇸ VALUE
      configured? : NAME ⇸ VALUE    -- files and environment
      ─────────
      let a == ((args? ⊕ configured?) ▷ (VALUE \ {⊥})) ∩ (dom NEW_SCHEMA × VALUE) •
        dom args? ⊆ dom NEW_SCHEMA ∧
        conforms(a, NEW_SCHEMA) ∧
        θServer' = (DEFAULTS ⊕ a) ⊕ {count ↦ 0} ∧
        bound' = (socket ∈ dom a) ∧ ¬logging' ∧ ¬running' ∧ ¬hup'

    NewFail
      ΞServer
      args? : NAME ⇸ VALUE
      error! : STRING
      ─────────
      dom args? ⊈ dom NEW_SCHEMA ∨ ¬ conforms(args?, NEW_SCHEMA) ∨
      ¬ conforms((args? ⊕ configured?) ∩ (dom NEW_SCHEMA × VALUE), NEW_SCHEMA)
```

### Open\_Socket

```
    OpenSocketOk
      ΔServer
      ─────────
      bound' ∧ logging' = logging ∧ count' = count
      (port = 0 ∧ ¬bound ⇒ port' ∈ 1 .. 65535)
      (port ≠ 0 ∨ bound ⇒ port' = port)

    OpenSocketFail
      ΞServer
      error! : STRING
      ─────────
      ¬bound ∧ ¬ canBind(address, port)

    OpenSocket ≙ OpenSocketOk ∨ OpenSocketFail
```

### Port

```
    Port
      ΞServer
      p! : PORT
      ─────────
      p! = port
```

### Address

```
    Address
      ΞServer
      a! : ADDRESS
      ─────────
      a! = address
```

### Count

```
    Count
      ΞServer
      n! : ℕ
      ─────────
      n! = count
```

### Reopen\_Log

```
    ReopenLogOk
      ΔServer
      ─────────
      logging' ∧ bound' = bound ∧ count' = count
      isRegular(file) ∧ ¬ isSymlink(file)
      owner(file) = euid ∧ links(file) = 1 ∧ mode'(file) = 0600
      contents(file) = ⟨⟩ ∨ csv(HEADER) ⊑ contents(file)
      contents(file) = ⟨⟩ ⇒ contents'(file) = ⟨csv(HEADER)⟩
      contents(file) ≠ ⟨⟩ ⇒ contents'(file) = contents(file)

    ReopenLogFail
      ΔServer
      error! : STRING
      ─────────
      ¬logging' ∧ bound' = bound ∧ count' = count
      contents'(file) = contents(file) ∧ mode'(file) = mode(file)

    ReopenLog ≙ ReopenLogOk ∨ ReopenLogFail
```

### Parse\_Message

```
    ParseMessage
      d? : seq BYTE
      r! : RECORD ∪ {⊥}
      ─────────
      let t == stripTrailing({CR, LF, NUL}, d?) •
      #t < 2 ⇒ r! = ⊥
      #t ≥ 2 ∧ (∃ p : 0 .. 191 ; b : seq BYTE •
               t = ⟨'<'⟩ ⁀ canonical(p) ⁀ ⟨'>'⟩ ⁀ b) ⇒
        r! = ⟨facility ↦ p div 8, severity ↦ p mod 8,
              message ↦ escape(b), valid ↦ true⟩
      otherwise ⇒
        r! = ⟨facility ↦ 1, severity ↦ 5,
              message ↦ escape(t), valid ↦ false⟩

    escape : seq BYTE → seq BYTE
    ∀ c : BYTE • escape(⟨c⟩) =
      if c ∈ 0 .. 31 ∪ {127} then "\x" ⁀ hex2(c) else ⟨c⟩
    ∀ s, u : seq BYTE • escape(s ⁀ u) = escape(s) ⁀ escape(u)
```

### Process

```
    ProcessOk
      ΔServer
      d? : seq BYTE ; peer? : SOCKADDR ∪ {⊥}
      ─────────
      logging ∧ bound' = bound ∧ logging'
      ParseMessage(d?) = ⊥ ⇒ count' = count ∧ contents' = contents
      ParseMessage(d?) = r ≠ ⊥ ⇒
        count' = count + 1 ∧
        (writable(file) ⇒
          contents'(file) = contents(file) ⁀ ⟨csv(host(peer?), r)⟩) ∧
        (¬ writable(file) ⇒ contents' = contents)

    host(⊥) = ""
    resolve ⇒ host(p) = reverseName(p) if found, else numeric(p)
    ¬resolve ⇒ host(p) = numeric(p)

    ProcessFail
      ΞServer
      error! : STRING
      ─────────
      ¬logging

    Process ≙ ProcessOk ∨ ProcessFail
```

### Run

```
    Start ≙ (¬bound ∧ OpenSocket ∨ bound ∧ ΞServer) ⨾
            (¬logging ∧ ReopenLog ∨ logging ∧ ΞServer)

    Loop ≙ μ L •
        (¬running ∧ Shutdown)
      □ (running ∧ hup ∧ [ ΔServer | ¬hup' ] ⨾ ReopenLog ⨾ L)
      □ (running ∧ ¬hup ∧ Receive ⨾ Process ⨾ L)

    Shutdown
      ΔServer
      ─────────
      ¬bound' ∧ ¬logging' ∧ ¬running' ∧ count' = count

    Run ≙ Start ⨾ [ ΔServer | running' ] ⨾ Loop

    SIGHUP received during Run      ⇒ hup' = true
    SIGTERM or SIGINT during Run    ⇒ running' = false
```

### Stop

```
    Stop
      ΔServer
      ─────────
      ¬running' ∧ bound' = bound ∧ logging' = logging ∧ count' = count
```

### i18n

```
    I18n
      key? : KEY ; args? : NAME ⇸ VALUE ; out! : STRING
      ─────────
      key? ∈ dom ARGUMENT_ORDER ⇒
        out! = render(lexicon(language, key?),
                      ⟨args?(n) | n ∈ ARGUMENT_ORDER(key?)⟩)
      key? ∉ dom ARGUMENT_ORDER ⇒ key? ⊑ out!
```

### Security Invariants

```
    Commands ≙ { system, exec, readpipe, pipe-open }
    Datagram, Line : seq BYTE

    NoExecution
      ∀ op : operations(App::Syslogd) • calls(op) ∩ Commands = ∅

    LineIntegrity
      ∀ d? : Datagram ; peer? : SOCKADDR •
        #{ l : lines(record(d?, peer?)) } = 1 ∧
        ran record(d?, peer?) ∩ ({0 .. 31} ∪ {127} \ {LF}) = ∅

    NoReflection
      ∀ d? : Datagram ; m : warnings ∪ errors •
        #d? > 2 ⇒ ¬ (stripPRI(d?) ⊑ m)

    NoNul
      ∀ o : {address, file, language} • 0 ∉ ran args?(o)
```

## State Diagram

An object is always in one of six states.  The boxes are the states; the
arrows are the method calls or events that move it from one state to another.
The text in square brackets is what happens during the move.

```perl
                          new()
                            |   [check options; nothing opened]
                            |
                            |       new(socket => S) starts in BOUND instead
                            v
              +---------------------------+
              |           IDLE            |<--------------------------------+
              |  no socket, no log file   |                                 |
              +---------------------------+                                 |
                  |                   |                                     |
     open_socket()|                   |reopen_log()                         |
     [bind UDP    |                   |[open or create file (0600),         |
      socket]     |                   | write header if empty]              |
                  v                   v                                     |
          +---------------+   +---------------+                             |
          |     BOUND     |   |    LOGGING    |<-- process()                |
          | socket open,  |   | log open,     |    [write row, count + 1]   |
          | no log file   |   | no socket     |                             |
          +---------------+   +---------------+                             |
                  |                   |                                     |
      reopen_log()|                   |open_socket()                        |
                  |    +---------+    |                                     |
                  +--->|  READY  |<---+                                     |
                       | socket  |<-- process()   [write row, count + 1]    |
                       | and log |<-- reopen_log() [close, reopen file]     |
                       +---------+                                          |
                            |                                               |
                            | run()   [also allowed from IDLE, BOUND or     |
                            |          LOGGING: opens what is missing;      |
                            v          installs HUP/TERM/INT handlers]      |
                       +---------+                                          |
       datagram ------>|         |   [process(): write row, count + 1]      |
       SIGHUP -------->| RUNNING |   [reopen_log() at top of loop]          |
       read error ---->|         |   [warning; keep going]                  |
                       +---------+                                          |
                            |                                               |
                            | SIGTERM, SIGINT or stop()                     |
                            v         [clear "running" flag]                |
                       +----------+                                         |
                       | STOPPING |   the current wait or datagram ends     |
                       +----------+                                         |
                            |                                               |
                            | loop sees the flag                            |
                            | [close socket and log; restore caller's       |
                            |  signal handlers; run() returns]              |
                            +-----------------------------------------------+
```

### Transition Table

```perl
    +----------+-------------------------------+----------+------------------------------------+
    | From     | Trigger                       | To       | Action / side effect               |
    +----------+-------------------------------+----------+------------------------------------+
    | (none)   | new()                         | IDLE     | options checked and stored         |
    | (none)   | new(socket => S)              | BOUND    | S used as the socket               |
    | IDLE     | open_socket()                 | BOUND    | UDP socket bound                   |
    | IDLE     | reopen_log()                  | LOGGING  | file opened or created, header     |
    | BOUND    | reopen_log()                  | READY    | file opened or created, header     |
    | LOGGING  | open_socket()                 | READY    | UDP socket bound                   |
    | BOUND    | open_socket()                 | BOUND    | nothing (already bound)            |
    | READY    | open_socket()                 | READY    | nothing (already bound)            |
    | LOGGING  | reopen_log()                  | LOGGING  | file closed and opened again       |
    | READY    | reopen_log()                  | READY    | file closed and opened again       |
    | LOGGING  | process()                     | LOGGING  | one row written, count + 1         |
    | READY    | process()                     | READY    | one row written, count + 1         |
    | IDLE,    | run()                         | RUNNING  | open what is missing, install      |
    | BOUND,   |                               |          |   signal handlers, set "running"   |
    | LOGGING, |                               |          |                                    |
    | READY    |                               |          |                                    |
    | RUNNING  | datagram arrives              | RUNNING  | process(): row written, count + 1  |
    | RUNNING  | SIGHUP                        | RUNNING  | log closed and opened again        |
    | RUNNING  | read error (not a signal)     | RUNNING  | warning "Error receiving ..."      |
    | RUNNING  | a write fails (e.g. disk      | RUNNING  | warning "Could not write ...";     |
    |          |   full)                       |          |   that datagram is lost            |
    | RUNNING  | SIGTERM, SIGINT or stop()     | STOPPING | "running" flag cleared             |
    | STOPPING | the wait or datagram ends     | IDLE     | socket and log closed, handlers    |
    |          |                               |          |   restored, run() returns          |
    +----------+-------------------------------+----------+------------------------------------+
```

Failures (the method dies and the object changes as shown):

```
    +----------+-------------------------------+----------+------------------------------------+
    | From     | Trigger                       | To       | Action / side effect               |
    +----------+-------------------------------+----------+------------------------------------+
    | IDLE,    | open_socket() fails           | (same)   | dies "Could not create a UDP       |
    | LOGGING  |                               |          |   socket ..."                      |
    | IDLE,    | reopen_log() fails            | (same)   | dies "Could not open log file ..." |
    | BOUND    |                               |          |   or "Refusing to log ..."         |
    | LOGGING, | reopen_log() fails            | IDLE or  | log closed, then dies "Could not   |
    | READY    |                               | BOUND    |   open log file ..." or            |
    |          |                               |          |   "Refusing to log ..."            |
    | IDLE,    | process()                     | (same)   | dies "process() was called before  |
    | BOUND    |                               |          |   reopen_log() succeeded"          |
    | RUNNING  | SIGHUP, and the reopen fails  | BOUND    | log closed, handlers restored,     |
    |          |                               |          |   run() dies with the error        |
    | IDLE     | run(), and the log cannot be  | IDLE     | the socket run() opened is closed  |
    |          |   opened                      |          |   again; run() dies with the error |
    | BOUND    | run(), and the log cannot be  | BOUND    | the caller's socket is left open;  |
    |          |   opened                      |          |   run() dies with the error        |
    | IDLE,    | run(), and the socket cannot  | (same)   | dies "Could not create a UDP       |
    | LOGGING  |   be opened                   |          |   socket ..."                      |
    | RUNNING  | recv() dies (a broken socket) | READY    | handlers restored; run() dies with |
    |          |                               |          |   the error; socket and log stay   |
    |          |                               |          |   open                             |
    | RUNNING  | run() again (from inside the  | RUNNING  | dies "run() is already running";   |
    |          |   loop)                       |          |   the running loop carries on      |
    | STOPPING | closing the socket dies       | IDLE     | the log is closed anyway; run()    |
    |          |                               |          |   dies with the error              |
    | (none)   | new() with an invalid option  | (none)   | dies "validate_strict: ..."; no    |
    |          |                               |          |   object is made                   |
    +----------+-------------------------------+----------+------------------------------------+
```

`port()`, `address()`, `count()`, `parse_message()` and `i18n()` never
change the state.  `stop()` outside `run()` changes nothing that matters,
because `run()` sets the "running" flag again when it starts.

## License and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
