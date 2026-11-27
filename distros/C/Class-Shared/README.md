## Name

Class::Shared - Keep one instance of a class and let other processes call it

## Synopsis

The usual way to use this distribution is through [Class::Shared::Frontend](https://metacpan.org/pod/Class%3A%3AShared%3A%3AFrontend).
Each example below is a different real-world pattern.

```perl
# 1. The simplest case: share one class between many processes.
use Class::Shared::Frontend;

my $simple = Class::Shared::Frontend->new('Class::Simple');

$simple->foo('hello');          # runs in the shared backend
print $simple->foo(), "\n";     # prints "hello"

# 2. Give the class its constructor arguments.  They are used once, when
#    the object is made, and must be plain data (no code references).
my $logger = Class::Shared::Frontend->new('My::Logger',
    ctor => [ level => 'debug', file => '/var/log/app.log' ],
);

my @all = $logger->lines();     # list context is kept
my $n   = $logger->lines();     # scalar context is kept too

# 3. Use a backend on another machine, over TLS with client certificates.
my $remote = Class::Shared::Frontend->new('Class::Simple',
    host       => 'classhost.example.com',
    port       => 7000,
    tls_ca     => 'ca.pem',
    tls_cert   => 'client.pem',
    tls_key    => 'client-key.pem',
    token_file => '/etc/class-shared/token',
);

# 4. Look after the backend yourself, from the shell.
#      class-shared start        # start it in the background
#      class-shared status       # ask what it is doing
#      class-shared stop         # ask it to stop

# 5. Use the helper functions to write your own client.
use Class::Shared ();

my $dir = Class::Shared::default_dir();
my ($ok, $why) = Class::Shared::ensure_dir($dir);
die "cannot use $dir: $why" unless $ok;

my $socket = Class::Shared::socket_path($dir);
```

## Description

Perl has no equivalent of a shared library for classes: every process loads
its own copy of `Class/Simple.pm`, runs its own constructors and keeps its
own state.  For a large class used by many short lived processes that is a lot
of memory and a lot of start up time.

Class::Shared moves the code into one process and lets the others keep a small
proxy: a [Class::Shared::Frontend](https://metacpan.org/pod/Class%3A%3AShared%3A%3AFrontend) standing in for one object, held by a
[Class::Shared::Backend](https://metacpan.org/pod/Class%3A%3AShared%3A%3ABackend) that loaded the class once and does the work.

```
client process            singleton backend process
--------------            -------------------------
Frontend (object #1)  --socket-->  Class::Shared::Backend
Frontend (object #2)  --socket-->  |-- Class::Simple (code, loaded once)
Frontend (object #3)  --socket-->  |-- object #1
                                   |-- object #2
                                   `-- object #3
```

So there is one copy of the class in the system and as many objects as there are
frontends: `Class::Shared::Frontend->new('Class::Simple', ...)` is one call
to `Class::Simple->new(...)`, in the backend.

The arguments for that constructor go in `ctor`, as an array reference:
`ctor => [verbose => 1]` is
`Class::Simple->new(verbose => 1)`.  They are used once, when the
frontend connects and asks the backend for the object, and they travel over the
socket, so they must be plain data -- a code reference cannot be sent.  If the
constructor dies, the frontend's `new` dies too, naming the class and the error
the backend reported.

[Class::Shared::Frontend](https://metacpan.org/pod/Class%3A%3AShared%3A%3AFrontend) lists every option this constructor takes.

The frontend never loads the target class, so it stays cheap.  An object lives
as long as the connection that made it; when the frontend goes, the backend
destroys the object, so its `DESTROY` runs once, in the backend.

One backend serves every class its clients ask for.  A client names the class it
wants in its first message, the handshake, and the backend loads that module
then, once per class, however many clients ask for it.  The backend may be on
this machine (a unix socket, see `Class::Shared::default_dir`) or on another
one (TCP).

Class::Shared is for Unix-like systems: unix sockets, POSIX directory
permissions and `fork` are what make a backend reachable, private and
startable.  See ["PLATFORMS"](#platforms).

This page documents the helper functions that the frontend, the backend and the
command line program share.  Start with [Class::Shared::Frontend](https://metacpan.org/pod/Class%3A%3AShared%3A%3AFrontend) if you only
want to use a shared class.

### Words Used in This Documentation

- backend

    The one process that loads the class and holds the real objects.

- frontend

    The small stand-in object in your own process.  It forwards each method call to
    the backend and gives you back the answer.

- unix socket

    A special file that two programs on the same machine use to talk to each other.
    Its file permissions decide who may connect.

- TCP

    The way programs on different machines talk to each other over a network.  Here
    it is always protected by TLS.

- TLS

    Encryption for a network connection.  Each side also shows a certificate to
    prove who it is.

- certificate, CA

    A certificate is a small file that says "this key belongs to this name".  A CA
    (certificate authority) is the organisation, or your own private key pair, that
    signs certificates so others can trust them.

- fingerprint

    A short code (SHA-256) that identifies exactly one certificate.  A client can
    trust one certificate by its fingerprint instead of trusting a CA.

- token

    A shared secret, kept in a file, that both sides of a TCP connection know.  It
    proves that each message came from somebody who has the secret.

- frame

    One message on the wire: a length, then the data.  See
    [Class::Shared::Protocol](https://metacpan.org/pod/Class%3A%3AShared%3A%3AProtocol).

- handshake

    The first message a client sends.  It names the class the client wants.

- context

    Perl's idea of what the caller wants back from a call: a list, one value, or
    nothing (void).  Class::Shared keeps the context you used.

## Functions

None is exported.  They are used by the frontend and the backend, and may be
useful when writing your own client.  Call each one with its full name, for
example `Class::Shared::validate_class($name)`.

A function either returns its answer or, when it cannot, dies with a message
that begins `Class::Shared:` and ends with a new line.  The one exception is
`ensure_dir`, which returns a pair so that the reason can be shown to the user.

The schemas in each **API SPECIFICATION** follow the conventions of
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) (for input) and [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) (for output).  They
describe the function for people and for tools.  The code does not call those
two modules, and this distribution does not depend on them.

### Validate\_Class

```perl
my $class = Class::Shared::validate_class($class);
```

Checks that `$class` looks like a Perl package name, and returns it unchanged.
Use it before you pass a name to `require` or build a file name from it.

A valid name is one or more words joined by `::`.  Each word starts with an
English letter or an underscore and then has letters, digits or underscores.
So `Class::Simple` and `My_Class2` are valid, and `2Bad`, `Foo::` and
`Foo-Bar` are not.

**Side effects:** none.

**Dies** with `Class::Shared: no class name given` if `$class` is undef or
empty, and with `Class::Shared: 'NAME' is not a valid class name` otherwise.
The domains and boundaries these two messages divide are listed under
**API SPECIFICATION** below, and `t/domain.t` tests every one of them.

#### Api Specification

##### Input

```perl
{
    class => {
        type     => 'string',
        position => 0,
        optional => 0,
        min      => 1,
        matches  => qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/,
    },
}
```

##### Domains

```perl
valid    one or more ASCII words, each starting with a letter or "_" and
         continuing with letters, digits or "_", joined by "::"
invalid  undef, the empty string, a leading digit in any word, an empty
         word, any other separator, any non-ASCII character

partition                representative           result
-------------------------------------------------------------
one word                 Foo                      accepted
several words            Foo::Bar::Baz            accepted
digits and underscores   My_Class2, A::_2         accepted
length 1                 A, _                     accepted
empty string             ""                       dies: no class name
leading digit            2Foo                     dies
empty word               Foo::, ::Foo, A:::B      dies
hyphen, space or dot     Foo-Bar, Foo Bar         dies
non-ASCII letter         "M" + U+00FC + "ller"    dies
emoji, RTL override      U+1F600, U+202E          dies

Boundary values: length 0 dies, length 1 is the smallest accepted.  There
is no maximum: a 40,000 character name is accepted, because the check does
not repeat a group (perl 5.26 stops a repeated group at 32,766 repeats).
Only the pattern in this specification can match, so the answer is
untainted and safe to use as a module name.
```

##### Output

```perl
{ type => 'string', matches => qr/\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/ }
```

### Read\_Secret

```perl
my $secret = Class::Shared::read_secret('/etc/class-shared/token');
```

Reads a shared secret (a token) from a file and returns it.  The whole file is
read as bytes.  White space at the end, including the final new line, is
removed.  White space at the start, and any inside the secret, is kept.

Never put a secret on a command line, where other users can see it.  Give its
file name instead and let this function read it.

**Side effects:** opens, reads and closes the file.

**Dies** if no file name is given, if the file cannot be read, if it is larger
than 65536 bytes (which also refuses an endless file such as `/dev/zero`), or
if the secret is empty after the end of it has been trimmed.

#### Api Specification

##### Input

```perl
{
    path => { type => 'string', position => 0, optional => 0, min => 1 },
}
```

##### Domains

```
valid    a path to a readable file whose content, after trailing white
         space is removed, is 1 to 65536 bytes
invalid  undef, the empty path, an unreadable path, a directory, a file
         larger than 65536 bytes, and a file that is empty after trimming

partition            representative        result
-----------------------------------------------------------
1 byte               "a"                   accepted
trailing white space "secret \r\n"         trimmed
leading white space  "  secret"            kept
white space only     "\n\t "               dies: is empty
0 bytes              ""                    dies: is empty
65536 bytes          "a" x 65536           accepted
65537 bytes          "a" x 65537           dies: too large

Boundary values: 0 bytes dies, 1 byte is the smallest accepted, 65536
bytes is the largest accepted, 65537 dies.  The size is counted in bytes,
so the limit is the same for a UTF-8 or a binary secret.  The content is
returned as bytes, unchanged and not decoded, so an embedded NUL and a
multibyte character cost exactly what they occupy in the file.
```

##### Output

```perl
{ type => 'string', min => 1 }
```

### Normalise\_Fingerprint

```perl
my $pin = Class::Shared::normalise_fingerprint(
    'AB:CD:...:EF'    # 32 pairs of hex digits, as openssl prints them
);
```

Turns the SHA-256 fingerprint of a certificate into the one form the TLS layer
wants: `sha256$` followed by 64 lower case hexadecimal digits.

It accepts 64 hex digits, or 32 pairs of hex digits separated by colons, with or
without a leading `sha256$`.  Upper or lower case digits are fine.  The prefix
itself must be lower case.  To get a fingerprint from a certificate file, run
`openssl x509 -in server.pem -noout -fingerprint -sha256` and copy the part
after the equals sign.

**Side effects:** none.

**Dies** if no value is given, or if the value is not a SHA-256 fingerprint.

#### Api Specification

##### Input

```perl
{
    value => {
        type     => 'string',
        position => 0,
        optional => 0,
        matches  => qr/\A(?:sha256\$)?(?:(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}|[0-9A-Fa-f]{64})\z/,
    },
}
```

##### Domains

```
valid    exactly 64 hexadecimal digits, or 32 pairs of two hexadecimal
         digits separated by ":", with or without a lower case "sha256$"
         prefix
invalid  any other length, any other separator, an upper case prefix, and
         any character that is not a hexadecimal digit

partition             representative         result
----------------------------------------------------------
64 digits             0102...1f20             accepted
32 colon-separated    01:02:...:1f:20          accepted
sha256$ prefix        sha256$0102...           accepted
upper case digits     0102...1F20             accepted, lower cased
upper case prefix     SHA256$0102...           dies
63 or 65 digits       one short, one long      dies
31 or 33 pairs        one short, one long      dies
spaces or hyphens     01 02 03..., 01-02-03    dies
non-ASCII character   U+00FC, U+1F600, U+202E  dies

Boundary values: the plain form is valid at exactly 64 characters (63 and
65 die); the colon form is valid at exactly 95 (94 and 96 die).  The
prefix is removed and every digit is lower cased; all invalid values are
echoed in the message byte for byte, without being decoded.
```

##### Output

```perl
{ type => 'string', matches => qr/\Asha256\$[0-9a-f]{64}\z/ }
```

### Client\_Tls\_Options

```perl
my %tls = Class::Shared::client_tls_options(
    cert => 'client.pem',
    key  => 'client-key.pem',
    ca   => 'ca.pem',
);
my $socket = IO::Socket::SSL->new(PeerAddr => $host, PeerPort => $port, %tls);
```

Returns the options a TLS client needs, as a flat list of key and value pairs
that you can pass straight to `IO::Socket::SSL->new`.  It exists so that
the frontend and the command line program cannot disagree about what "verify the
backend" means.

Give `cert` and `key` (the certificate this client shows), and then either
`ca` or `fingerprint`.  With `ca`, the backend's certificate must be signed
by that CA and must name the host you connect to.  With `fingerprint` (the
output of ["normalise\_fingerprint"](#normalise_fingerprint)), exactly one certificate is trusted, and
its name and its signer do not matter.  Verification is always on.

This function does not check that the files exist, and does not check that you
gave only one of `ca` and `fingerprint`.  The caller does that.

**Side effects:** loads [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL).  Nothing else loads it.

**Dies** if [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) is not installed.

#### Api Specification

##### Input

```perl
{
    cert        => { type => 'string', optional => 0 },
    key         => { type => 'string', optional => 0 },
    ca          => { type => 'string', optional => 1 },
    fingerprint => { type => 'string', optional => 1,
                     matches => qr/\Asha256\$[0-9a-f]{64}\z/ },
}
```

##### Domains

```perl
valid    cert and key, then either ca or fingerprint (or neither, which
         the caller is expected to have refused already)
invalid  nothing is refused here: this function checks neither that the
         files exist nor that ca and fingerprint are not both given

partition            representative                  result
---------------------------------------------------------------
ca given             ca => "ca.pem"                  SSL_ca_file
fingerprint given    sha256$ + 64 lower hex digits   pin, no CA
both given           ca and fingerprint              the pin wins
neither given        cert and key only               SSL_ca_file undef
multibyte path       /etc/U+00FC/client.pem          passed through

Output boundaries: the flat list has five pairs with a CA and seven with a
pin, so ten and fourteen elements.  SSL_verify_mode is "verify the peer"
in every partition, and SSL_version is the same for both ends.
```

##### Output

```perl
{
    type   => 'arrayref',
    min    => 10,
    max    => 14,
    description => 'a flat list of option name and value pairs: SSL_version, SSL_cert_file, SSL_key_file, SSL_verify_mode, and either SSL_ca_file or (SSL_fingerprint, SSL_force_fingerprint, SSL_verifycn_scheme)',
}
```

### Dir\_of

```perl
my $dir = Class::Shared::dir_of('/run/user/1000/class-shared/x.sock');
# '/run/user/1000/class-shared'
```

Returns the directory part of a path, so that the answer can always be used.  A
path with no directory part, such as `x.sock`, gives `.` (the current
directory).  A file directly in the top directory, such as `/x.sock`, gives `/`.

**Side effects:** none.

#### Api Specification

##### Input

```perl
{ path => { type => 'string', position => 0, optional => 0 } }
```

##### Domains

```
partition            representative    result
-------------------------------------------------
bare file name       x.sock            .
file in the root     /x.sock           /
nested file          /a/b/c            /a/b
trailing slash       a/b/              a
doubled separator    a//b              a
empty path           ""                .

The answer is never empty, so it can always be used: a path with no
directory part gives ".".  There is no length boundary.  A multibyte
directory part is returned unchanged, with no encoding or decoding.
```

##### Output

```perl
{ type => 'string', min => 1 }
```

### Default\_Dir

```perl
my $dir = Class::Shared::default_dir();
my $dir = Class::Shared::default_dir(dir => '/tmp/mine');
```

Returns the directory that holds this user's sockets.  The first of these that
applies wins:

1. the `dir` you pass;
2. the environment variable `CLASS_SHARED_DIR`;
3. `$ENV{XDG_RUNTIME_DIR}/class-shared`, if `XDG_RUNTIME_DIR` names a directory
that exists;
4. `/run/user/UID/class-shared`, if `/run/user/UID` exists (UID is the effective
user id);
5. a per-user directory under the system temporary directory.

The path is kept short on purpose, because it ends up inside a socket address,
which has a small size limit.  It is per user because the socket is a trust
boundary.

**Side effects:** reads the environment and checks whether directories exist.  It
does not create anything; use ["ensure\_dir"](#ensure_dir) for that.

**Dies** if the directory name contains a NUL byte, which would end the name
early in a system call and so name a different place.  Under taint mode
(`-T`) the name is untainted here, because everything made in it is checked by
["ensure\_dir"](#ensure_dir) before it is trusted.

#### Api Specification

##### Input

```perl
{ dir => { type => 'string', optional => 1, min => 1 } }
```

##### Domains

```
The first partition that applies wins, so they are ordered:

rank  partition                             result
-----------------------------------------------------------------
1     dir given and not empty               the dir, unchanged
2     CLASS_SHARED_DIR set and not empty    that value
3     XDG_RUNTIME_DIR names a directory     that directory/class-shared
4     /run/user/UID exists                  that directory/class-shared
5     none of the above                     tmpdir/class-shared-UID

invalid: a name containing a NUL byte dies at any rank, because a system
call would end the name there and so name a different place.  The empty
string is not invalid: it means "not given" and falls through to the next
rank.  A multibyte name is returned unchanged, not encoded.  Nothing is
created, so a rank may name a directory that does not exist yet.
```

##### Output

```perl
{ type => 'string', min => 1 }
```

### Ensure\_Dir

```perl
my ($ok, $why) = Class::Shared::ensure_dir($dir);
die "cannot use $dir: $why" unless $ok;
```

Makes sure `$dir` exists and that nobody else can put a socket in it.  It
returns `(1, undef)` on success or `(0, $why_not)` when the directory is not
safe.  It is refused if

- it cannot be created or inspected;
- it belongs to a different user (anybody who owns the directory could pretend to
be the backend); or
- group or other users can write to it.

If the directory is missing it is created with mode 0700.  Only the last part of
the path is created: the parent directory must already exist.

**Side effects:** may create one directory.

**Dies** (and does not return a pair) if no directory is given, or on a perl
without unix sockets.

#### Api Specification

##### Input

```perl
{ dir => { type => 'string', position => 0, optional => 0, min => 1 } }
```

##### Domains

```
valid    a path whose last part exists, or can be created, as a directory
         owned by this user with neither the group write bit (0020) nor
         the other write bit (0002) set
invalid  undef, the empty path, a path whose parent is missing, a path
         that is not a directory, a directory owned by another user, and
         a directory with either write bit set

partition              representative    result
-----------------------------------------------------
does not exist         tmp/fresh         (1, undef), mode 0700
exists, mode 0700      tmp/private       (1, undef)
exists, mode 0755      tmp/open          (1, undef)
exists, mode 0777      tmp/writable      (0, reason)
exists, mode 0770      group writable    (0, reason)
exists, mode 0702      other writable    (0, reason)
parent missing         tmp/absent/child  (0, "cannot create ...")
a plain file           tmp/file          (0, "cannot create ...")
empty or undef         ""                dies

Boundary values: the boundary is the write mask 0022, not a single mode:
0700 is the most private mode created and 0777 the most open refused, but
0755 is accepted because others may read and search, not write.  Only the
last part of the path is created, so a missing parent is a refusal, not a
recursive mkdir.  A multibyte name is created as given.
```

##### Output

```perl
{
    type   => 'arrayref',
    min    => 2,
    max    => 2,
    schema => [
        { type => 'boolean', description => '1 when the directory is safe to use' },
        { type => 'string',  optional => 1, description => 'undef on success, otherwise the reason' },
    ],
}
```

### Socket\_Path

```perl
my $path = Class::Shared::socket_path();
my $path = Class::Shared::socket_path('/tmp/mine');
```

Returns the path of the backend socket inside `$dir`, or inside the default
directory (see ["default\_dir"](#default_dir)) if none is given.  The file name is always
`class-shared.sock`.  There is one socket for every class, because the client
chooses the class and not the listener.

**Side effects:** none.  The directory and the socket are not created.

**Dies** on a perl without unix sockets, or if the result is longer than 100
characters (see ["check\_socket\_path"](#check_socket_path)).

#### Api Specification

##### Input

```perl
{ dir => { type => 'string', position => 0, optional => 1, min => 1 } }
```

##### Domains

```
valid    no argument, or a directory name, such that the socket path is
         1 to 100 characters
invalid  a directory name that makes the path longer than 100 characters,
         which dies with the message documented under L</check_socket_path>

partition                     representative      result
------------------------------------------------------------------
default directory             ()                  .../class-shared.sock
a directory                   /tmp                /tmp/class-shared.sock
path exactly 100 characters   dir of 82 chars     accepted
path 101 characters           dir of 83 chars     dies

The file name is always "class-shared.sock", so the boundary is reached
through the directory: with a 17 character file name the largest usable
directory is 82 characters.  Nothing is created and nothing is checked for
existence.
```

##### Output

```perl
{ type => 'string', min => 1, max => 100 }
```

### Check\_Socket\_Path

```perl
my $path = Class::Shared::check_socket_path($path);
```

Returns `$path` if it is short enough to be a socket address, and dies if it
is not, or if no path is given at all.  The limit is 100 characters, which is
less than the operating system's limit so that the code stays portable.  Without this check the system would cut
a long path short without saying so, and a client and a backend could end up
using two different sockets.

The frontend, the backend and `class-shared` all use it for a `socket` that
you give yourself, as well as for the path that `socket_path` builds.

**Side effects:** none.

**Dies** with `Class::Shared: no socket path given` if `$path` is undef or
empty, and with `Class::Shared: socket path 'PATH' is N characters, more than
the 100 allowed; set CLASS_SHARED_DIR or pass dir => to a shorter
directory` if it is too long.

#### Api Specification

##### Input

```perl
{ path => { type => 'string', position => 0, optional => 0, min => 1 } }
```

##### Domains

```perl
valid    a non-empty path of 1 to 100 characters
invalid  undef, the empty path, and any path longer than 100 characters

partition          representative   result
-------------------------------------------------
length 1           /                accepted
length 99          ...              accepted
length 100         ...              accepted, the maximum
length 101         ...              dies
length 0 or undef  ""               dies

Boundary values: 100 is accepted and 101 dies; 0 and undef die.  The limit
is 100 characters and is below the operating system's.  A multibyte path is
counted in characters and returned unchanged.  This function does not check
that a socket can use its characters: see L</ENCODING>.
```

##### Output

```perl
{ type => 'string', min => 1, max => 100 }
```

### Poll\_Pause

```
Class::Shared::poll_pause();
```

Sleeps for one polling interval (`$Class::Shared::POLL_INTERVAL`, 0.02
seconds).  Every loop that waits for a socket or a lock uses it, so that none of
them spins the processor and all of them wake at the same rate.

**Side effects:** sleeps.  It returns nothing.

#### Api Specification

##### Input

```
{ }
```

##### Domains

```
Takes no input, so it has one partition.  The output is the empty list
(undef in scalar context).  The only observable effect is a sleep of
C<$Class::Shared::POLL_INTERVAL> seconds, 0.02, which is the same for
every loop that waits for a socket or a lock.
```

##### Output

```perl
{ type => 'undef' }
```

### Detach\_Standard\_Streams

```perl
my ($ok, $why) = Class::Shared::detach_standard_streams('/path/to/log');
```

Used when a backend goes into the background.  It reopens standard input on the
null device (`/dev/null`) and standard output and standard error on the log
file, so that the process holds no terminal and its messages land in a file.  If
the log file cannot be opened, they go to the null device instead, because a
backend that cannot write a log should still run.

It returns `(1, undef)`, or `(0, $why)` if a stream could not be reopened.  The
caller decides whether that matters: the backend treats it as fatal.

**Side effects:** replaces STDIN, STDOUT and STDERR of the current process.  Do
not call it in a program that still needs them.

#### Api Specification

##### Input

```perl
{ log => { type => 'string', position => 0, optional => 0, min => 1 } }
```

##### Domains

```
valid    any log path: one that can be opened for appending, and one that
         cannot (the streams then go to the null device and the call still
         succeeds, because a backend that cannot log should still run)
invalid  none by value: an unopenable path is a documented fallback, not
         an error

partition            representative        result
---------------------------------------------------------
writable log         /tmp/backend.log      (1, undef), file created
log in a missing dir /absent/backend.log    (1, undef), null device

The refusal path, C<(0, $why)>, exists for a failure to reopen a stream
after the log was opened, such as a descriptor limit; it cannot be
provoked by the value of the path alone.  The call replaces STDIN, STDOUT
and STDERR of the current process, so a test makes it in a child.
```

##### Output

```perl
{
    type   => 'arrayref',
    min    => 2,
    max    => 2,
    schema => [
        { type => 'boolean' },
        { type => 'string', optional => 1 },
    ],
}
```

## Package Variables

These can be changed with `local` in a test or a special program.  Most users
never need to.

- `$Class::Shared::VERSION`

    The version of the distribution.

- `$Class::Shared::PROTOCOL_VERSION`

    The version of the wire protocol, now 2.  A backend refuses a client that speaks
    a different one.  It is raised whenever the protocol changes in a way old
    clients cannot understand.

- `$Class::Shared::MAX_SOCKET_PATH`

    The longest socket path this module will make or accept: 100 characters.

- `$Class::Shared::POLL_INTERVAL`

    How long, in seconds, the waiting loops sleep between looks: 0.02.

- `$Class::Shared::UNIX_TRUST_REASON`

    The sentence explaining why a unix socket needs no token and no TLS.  The
    backend, the frontend and the command line all quote it, so they use the same
    words.

## Encoding

Class::Shared moves text between processes, so it matters which parts accept
more than plain English letters.

- Arguments, results and error text: full Unicode.

    The arguments you pass to a method, the `ctor` list, the values a method
    returns and the text of an exception all travel through [Storable](https://metacpan.org/pod/Storable), which
    keeps Perl strings exactly as they are.  Accented letters, Chinese, Japanese,
    Arabic and emoji all arrive unchanged, with their "UTF-8 flag" kept.  This was
    checked with a round trip of `"caf\x{e9}"`, `"\x{1F600}"` and a Japanese word.

    Bytes and characters are kept apart.  A byte string comes back as a byte string
    and a character string as a character string.  So decode your input (for
    example with [Encode](https://metacpan.org/pod/Encode)) before you send it, and encode it when you print it.

- Class names: ASCII only.

    A class name may contain only the letters A to Z (either case), digits and
    underscores, joined by `::`.  A class with non-ASCII letters in its name is
    refused by ["validate\_class"](#validate_class), even though Perl itself would allow it.

- Method names: ASCII is safe.

    A method name is passed on as given.  Use ASCII names; a name that does not
    exist is reported as "has no method".

- Secrets (token, token file): ASCII only.

    Use only ASCII characters in a token.  The token file is read as bytes, but a
    `token` you give in your program is a Perl string.  The word `caf\x{e9}` has
    different bytes in the two forms and so gives a different digest, and a
    character above code point 255 stops the digest from being calculated at all.
    Both sides would then fail to agree, and the connection is refused.

- File and directory names: ASCII is safest.

    Paths (`dir`, `socket`, `log`, certificate files) are handed to the operating
    system as they are.  Non-ASCII names work if every program uses the same bytes,
    but they are not tested here.  The 100 character limit on a socket path counts
    characters.  Perl gives a socket one byte for each character up to code point
    255, so an accepted path is not cut short.  A path with a higher character in a
    character string cannot be used as a socket: connecting or binding dies with
    `Wide character`.  Encode such a name to bytes first; each byte then counts
    towards the limit.

- Fingerprints: hexadecimal digits only.

    See ["normalise\_fingerprint"](#normalise_fingerprint).

- The backend log: be careful.

    The log file has no encoding layer.  Text that has only characters up to code
    point 255 (such as `caf\x{e9}`) is written as one byte per character, which is
    not UTF-8.  Text with a higher character (such as an emoji) is written as UTF-8
    and Perl prints a `Wide character` warning.  A log that contains both is mixed.
    Log lines are mostly the backend's own English messages; the main way for other
    text to appear is an error from your own class.

## Common Pitfalls

- Class variables are shared by every client.

    Each frontend has its own object, but all objects of a class live in one
    process, so a package variable (`our $COUNT`) or other class data is shared by
    all clients.  A change made by one client is seen by all the others.  Keep state
    in the object, not in the package.

- The backend is one process: it does one thing at a time.

    A slow method makes every other client wait, whatever class they use.

- The backend's environment is not yours.

    Setting `$ENV{FOO}`, calling `chdir`, or opening a file in your own process
    changes nothing in the backend.  Pass what a method needs as arguments.

- Only plain data can cross.

    Strings, numbers, `undef`, array references and hash references can be sent.
    Code references, file handles and tied or inside-out objects cannot.  An
    argument that cannot be sent makes the call fail.  In this version the failure
    is reported as "lost the backend" and it also closes the connection, so the
    object is gone.  Check your arguments before the call.

- Context is kept, so list rules still apply.

    A method that returns `(1, 2, 3)` gives the last value, 3, in scalar context.
    That is normal Perl, and it is the same through a frontend.

- `undef` is a value.

    `undef` is sent and returned faithfully.  A method that returns `undef` in list
    context gives a list of one element, not an empty list.

- `ensure_dir` returns a pair; the other functions die.

    Test `$ok`, the first value of the pair.  The pair as a whole is never an empty
    list, so testing the list itself tells you nothing.

- `ensure_dir` makes only one directory.

    If the parent does not exist, it fails with "No such file or directory".  Create
    the parent first.

- An over-long socket path is refused.

    Keep `dir` or `socket` short (100 characters at most).

- A token file's trailing white space is removed.

    A secret whose last character is meant to be a space or a new line cannot be
    stored in a token file.  Use ordinary printable characters.

- A unix socket takes no token and no TLS.

    Passing one is an error, on purpose, so that it never looks like extra
    protection.

## Transport Security

Authentication belongs to the transport, and the two transports are
deliberately different.

A unix socket is created mode 0600 in a directory only its owner can write to,
so the kernel has already decided who may connect: there is no token and no TLS,
and no frame carries a digest.  The backend, the frontend and [class-shared](https://metacpan.org/pod/class-shared)
refuse both for a unix socket rather than let either look like a defence.

TCP is the opposite case.  A port is reachable by anybody who can route to it,
and treating a frame means running what the sender put in it, so a TCP listener
is a TLS listener: it needs a certificate and its key to prove which backend it
is, and a CA to check client certificates against, and it will not start without
all three.  Clients must present a certificate that CA signed, and must verify
the backend's certificate against the CA that signed it -- name included -- or
against a pinned SHA-256 fingerprint of that one certificate, which stands in
for both the CA and the name.  A client whose certificate the backend cannot
verify is dropped during the handshake and never receives a frame.

TLS answers who is on the other end and makes the bytes unreadable.  The token is
kept on top of it, as a second and independent check: with a token every frame
in both directions carries an HMAC-SHA-256 of its body, and the digest is
verified before [Storable::thaw](https://metacpan.org/pod/Storable%3A%3Athaw) sees the body.  So a client that has a
certificate but not the shared secret still cannot make the backend
deserialise, and so run, bytes of its choosing.  The digest authenticates one
frame; TLS authenticates the connection and encrypts it.  Both, because either
one alone has been enough to lose a system.

See ["SECURITY" in Class::Shared::Backend](https://metacpan.org/pod/Class%3A%3AShared%3A%3ABackend#SECURITY) for the backend's side of it and
[Class::Shared::Protocol](https://metacpan.org/pod/Class%3A%3AShared%3A%3AProtocol) for the framing.

### Making the Certificates

A TCP listener needs four files: a CA, the listener's certificate and key, and
a certificate for every client.  OpenSSL makes them in three steps.  The CA's
key signs certificates and is not needed on the machines that use them.

```
# 1. A CA of your own.
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout ca-key.pem -out ca.pem -subj '/CN=Class::Shared CA' \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign'
```

The listener's certificate has to name the address clients connect to, in
`subjectAltName`: a `DNS:` entry for a hostname, an `IP:` entry for an
address, or both.

```
# 2. The listener's certificate.  Put your own addresses in server.ext.
printf 'subjectAltName = DNS:classhost.example.com, IP:127.0.0.1\n' > server.ext
printf 'extendedKeyUsage = serverAuth\n' >> server.ext
openssl req -new -newkey rsa:2048 -nodes -subj '/CN=classhost.example.com' \
    -keyout server-key.pem -out server.csr
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem \
    -CAcreateserial -days 3650 -out server.pem -extfile server.ext
```

Each client needs a certificate of its own.  The backend cannot tell one from
another beyond this, so give each client, or each pair of them, their own.

```
# 3. A client certificate.
printf 'extendedKeyUsage = clientAuth\n' > client.ext
openssl req -new -newkey rsa:2048 -nodes -subj '/CN=class-shared client' \
    -keyout client-key.pem -out client.csr
openssl x509 -req -in client.csr -CA ca.pem -CAkey ca-key.pem \
    -CAcreateserial -days 3650 -out client.pem -extfile client.ext
```

The listener is given three of the files:

```
class-shared start --listen tcp:0.0.0.0:7000 \
    --token-file /etc/class-shared/token \
    --tls-cert server.pem --tls-key server-key.pem --tls-ca ca.pem
```

and every client the other three:

```perl
my $simple = Class::Shared::Frontend->new('Class::Simple',
    host       => 'classhost.example.com',
    port       => 7000,
    tls_ca     => 'ca.pem',
    tls_cert   => 'client.pem',
    tls_key    => 'client-key.pem',
    token_file => '/etc/class-shared/token',
);
```

A frontend that pins the listener's certificate instead of trusting the CA skips
`tls_ca` and passes `tls_fingerprint` the digest that
`openssl x509 -in server.pem -noout -fingerprint -sha256` prints.  That works
with a self-signed certificate too, and then the CA is only needed for the
clients.  `t/certs/make-certs.sh` in the distribution generates this set, plus
a second CA and impostor certificates, for the tests.

## Limitations

- A unix socket is not encrypted: file permissions decide who may connect, and
anything that can read the socket can read the traffic on it.  TCP is always
TLS, and has no unencrypted mode.
- One backend per directory answers one call at a time, so a slow method delays
every client of that backend, whatever class they are using.
- Each frontend is one connection: many objects in one process means many file
descriptors in both processes.
- Arguments and return values travel through [Storable](https://metacpan.org/pod/Storable); filehandles, code
references and tied or inside-out objects do not.
- An object cannot outlive its connection, so it cannot be handed to another
process; it lives exactly as long as the frontend that made it.
- The backend is a separate process, so nothing about your process reaches it
unless you send it.  Setting `$ENV{FOO}` in a frontend does not set it in the
backend, and a method that reads `%ENV` (or `chdir`, or a global, or a file
handle) sees the backend's environment, not yours: its `%ENV` is the one the
backend was started with, and every client shares those values.  Pass such
state as arguments if it matters, or set the environment when you start the
backend.
- A client may call a method only by its plain name.  A package-qualified name
such as `Other::Package::function` is refused, and so are `new`, `DESTROY`
and `AUTOLOAD`.  This is not a sandbox: a client that has passed the
transport's authentication can already make the backend load any module and
call the methods of what it constructs, so the backend is only as safe as the
clients allowed to reach it.

## Platforms

Unix-like systems only.  A backend needs three things this distribution cannot
do without:

- unix domain sockets, which is how a frontend reaches a backend on this machine
and starts one when there is none;
- POSIX directory permissions, which are the whole of a unix socket's
authentication: the socket is mode 0600 inside a directory only its owner can
write to, so the kernel decides who may connect;
- a real `fork`, which is how a frontend starts a backend in the background.

A perl without unix domain sockets can run none of it, so that is the question
the check asks, rather than a list of operating systems: a Cygwin perl has the
sockets and works.  Windows has had the sockets since Windows 10, but an
MSWin32 perl still cannot run a backend: its `stat` reports the same mode bits
for every directory, so none there can be shown to be owner-only and
`Class::Shared::ensure_dir` refuses them all.

The refusal names what is missing: `Class::Shared::ensure_dir` and
`Class::Shared::socket_path` die with that explanation on a perl without the
sockets, and `Class::Shared::ensure_dir` refuses the directories it cannot
show to be owner-only.

It installs there anyway, and `Makefile.PL` says so as it runs.  Refusing to
install would take away [Class::Shared::Protocol](https://metacpan.org/pod/Class%3A%3AShared%3A%3AProtocol), which is pure Perl and can
talk to a backend from a machine that cannot run one, and would leave such a
platform with nothing to report but a failed install.

The wire protocol, [Class::Shared::Protocol](https://metacpan.org/pod/Class%3A%3AShared%3A%3AProtocol), is pure Perl and loads on any
platform, so it can be used to talk to a backend from a machine that cannot run
one.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Class-Shared/coverage/)

[Class::Shared::Frontend](https://metacpan.org/pod/Class%3A%3AShared%3A%3AFrontend), [Class::Shared::Backend](https://metacpan.org/pod/Class%3A%3AShared%3A%3ABackend),
[Class::Shared::Protocol](https://metacpan.org/pod/Class%3A%3AShared%3A%3AProtocol), [class-shared](https://metacpan.org/pod/class-shared).

## Hacking

`README.md` is generated from the POD in this file and must never be edited
by hand.  After changing the POD, run `make readme`, which calls
`maint/regen-readme`; it converts the POD with [Pod::Github](https://metacpan.org/pod/Pod%3A%3AGithub)'s
`pod2github`, the converter whose `##` headings, fenced Perl blocks and
MetaCPAN links are the style the committed front page uses.  `pod2markdown`
does not reproduce it.

[Pod::Github](https://metacpan.org/pod/Pod%3A%3AGithub) is a development requirement, so `cpanm --installdeps
\--with-develop .` installs everything needed to regenerate the front page.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes what each function does in the Z notation, a way of
writing exactly what a program promises using sets and logic.  You do not need
it to use the module.  Read the plain text above first.

Z uses mathematical symbols, so this is the only part of the file that is not
plain ASCII.  A short key:

```perl
x? input        x! output        x' the value of x after the operation
=>  implies     /\  and          \/  or          ~  not
|->  maps to    <->  relation    +->  partial function (each input at most one answer)
seq  a sequence (an ordered list)    # the length of a sequence
```

In the Z text below the symbols are the usual Unicode ones.

### Basic Types

```
[CHAR]                                  all characters
STRING   == seq CHAR
STRING⊥  == STRING ∪ {⊥}                a string, or undef
PATH     == STRING
MAXPATH  == 100
RESULT[X] ::= value⟨⟨X⟩⟩ | dies⟨⟨STRING⟩⟩    a function returns X, or dies with a message
IDENT    == the strings that start with a letter or _ and continue with letters, digits or _
CLASSNAME == { c : STRING | ∃ parts : seq₁ IDENT • c = join(⟨"::"⟩, parts) }
HEX64    == the strings of exactly 64 hexadecimal digits
FP       == { f : STRING | f ∈ HEX64 ∨ f is 32 pairs of hex digits separated by ":" }
```

### Validate\_Class

```
┌─ ValidateClass ─────────────────────────────────────────
│ class? : STRING⊥
│ out!   : RESULT[STRING]
├─────────────────────────────────────────────────────────
│ class? ∈ CLASSNAME ⇒ out! = value(class?)
│ class? ∉ CLASSNAME ⇒ ∃ m : STRING • out! = dies(m)
└─────────────────────────────────────────────────────────
```

### Read\_Secret

```
┌─ ReadSecret ────────────────────────────────────────────
│ path?  : STRING⊥
│ files  : PATH ⇸ STRING                  the file system, as bytes
│ out!   : RESULT[STRING]
├─────────────────────────────────────────────────────────
│ path? ∈ dom files ∧ trim(files(path?)) ≠ ⟨⟩
│     ⇒ out! = value(trim(files(path?)))
│ path? ∉ dom files ∨ trim(files(path?)) = ⟨⟩ ∨ path? = ⊥
│     ⇒ ∃ m : STRING • out! = dies(m)
│ files' = files                          nothing is changed
└─────────────────────────────────────────────────────────
```

where `trim` removes white space from the end only.

### Normalise\_Fingerprint

```
┌─ NormaliseFingerprint ──────────────────────────────────
│ value? : STRING⊥
│ out!   : RESULT[STRING]
├─────────────────────────────────────────────────────────
│ value? = ⟨"sha256$"⟩ ⌢ f ∨ value? = f, for some f ∈ FP
│     ⇒ out! = value(⟨"sha256$"⟩ ⌢ lower(strip_colons(f)))
│ otherwise ⇒ ∃ m : STRING • out! = dies(m)
└─────────────────────────────────────────────────────────
```

### Client\_Tls\_Options

```
┌─ ClientTlsOptions ──────────────────────────────────────
│ cert?, key? : STRING
│ ca?, fingerprint? : STRING⊥
│ out! : RESULT[seq (STRING × VALUE)]
├─────────────────────────────────────────────────────────
│ fingerprint? ≠ ⊥ ⇒ out! = value(base ⌢ pin)
│ fingerprint? = ⊥ ⇒ out! = value(base ⌢ ⟨("SSL_ca_file", ca?)⟩)
│ SSL_verify_mode ∈ base is always "verify the peer"
└─────────────────────────────────────────────────────────
```

### Dir\_of

```
┌─ DirOf ─────────────────────────────────────────────────
│ path? : STRING
│ dir!  : STRING
├─────────────────────────────────────────────────────────
│ dir! = dirname(path?)       ("." when path? has no directory part)
│ dir! ≠ ⟨⟩
└─────────────────────────────────────────────────────────
```

### Default\_Dir

```
┌─ DefaultDir ────────────────────────────────────────────
│ dir? : STRING⊥ ; env : STRING ⇸ STRING ; isdir : ℙ PATH ; euid : ℕ
│ dir! : STRING
├─────────────────────────────────────────────────────────
│ dir? ≠ ⊥ ∧ dir? ≠ ⟨⟩ ⇒ dir! = dir?
│ else "CLASS_SHARED_DIR" ∈ dom env ∧ env(..) ≠ ⟨⟩ ⇒ dir! = env("CLASS_SHARED_DIR")
│ else env("XDG_RUNTIME_DIR") ∈ isdir ⇒ dir! = env("XDG_RUNTIME_DIR") / "class-shared"
│ else "/run/user/" ⌢ euid ∈ isdir ⇒ dir! = that / "class-shared"
│ else dir! = tmpdir / ("class-shared-" ⌢ euid)
│ isdir' = isdir                          nothing is created
└─────────────────────────────────────────────────────────
```

### Ensure\_Dir

```
┌─ EnsureDir ─────────────────────────────────────────────
│ dir?  : STRING⊥
│ fs    : PATH ⇸ (owner : ℕ × mode : ℕ)   the directories that exist
│ euid  : ℕ
│ out!  : RESULT[𝔹 × STRING⊥]
├─────────────────────────────────────────────────────────
│ dir? = ⊥ ∨ dir? = ⟨⟩ ∨ ¬ UnixSockets ⇒ ∃ m • out! = dies(m)
│ dir? ∉ dom fs ∧ parent(dir?) ∈ dom fs ⇒ fs' = fs ⊕ {dir? ↦ (euid, 8#700)}
│ dir? ∈ dom fs' ∧ owner(fs'(dir?)) = euid ∧ mode(fs'(dir?)) ∧ 8#022 = 0
│     ⇒ out! = value(true, ⊥)
│ otherwise (and no dying) ⇒ ∃ why : STRING • out! = value(false, why)
└─────────────────────────────────────────────────────────
```

### Socket\_Path

```
┌─ SocketPath ────────────────────────────────────────────
│ dir? : STRING⊥
│ out! : RESULT[PATH]
├─────────────────────────────────────────────────────────
│ ¬ UnixSockets ⇒ ∃ m • out! = dies(m)
│ let p = default_dir(dir?) / "class-shared.sock" in
│     UnixSockets ∧ #p ≤ MAXPATH ⇒ out! = value(p)
│     UnixSockets ∧ #p > MAXPATH ⇒ ∃ m • out! = dies(m)
└─────────────────────────────────────────────────────────
```

### Check\_Socket\_Path

```
┌─ CheckSocketPath ───────────────────────────────────────
│ path? : STRING⊥
│ out!  : RESULT[PATH]
├─────────────────────────────────────────────────────────
│ path? ≠ ⊥ ∧ 0 < #path? ≤ MAXPATH ⇒ out! = value(path?)
│ path? = ⊥ ∨ #path? = 0           ⇒ ∃ m • out! = dies(m)
│ path? ≠ ⊥ ∧ #path? > MAXPATH     ⇒ ∃ m • out! = dies(m)
└─────────────────────────────────────────────────────────
```

### Poll\_Pause

```
┌─ PollPause ─────────────────────────────────────────────
│ clock, clock' : ℝ
├─────────────────────────────────────────────────────────
│ clock' ≥ clock + POLL_INTERVAL          it returns nothing
└─────────────────────────────────────────────────────────
```

### Detach\_Standard\_Streams

```
┌─ DetachStandardStreams ─────────────────────────────────
│ log? : PATH ; stdin, stdout, stderr : STREAM ; writable : ℙ PATH
│ out! : 𝔹 × STRING⊥
├─────────────────────────────────────────────────────────
│ stdin' = null
│ log? ∈ writable ⇒ stdout' = stderr' = file(log?) ∧ out! = (true, ⊥)
│ log? ∉ writable ⇒ stdout' = stderr' = null      ∧ out! = (true, ⊥)
│ any reopen fails ⇒ ∃ why • out! = (false, why)
└─────────────────────────────────────────────────────────
```

### The Unix Socket Probe (Internal)

```
┌─ UnixSocketProbe ───────────────────────────────────────
│ cache, cache' : {unknown, yes, no}
├─────────────────────────────────────────────────────────
│ cache = unknown ⇒ cache' ∈ {yes, no}    asked once, by naming a socket and
│                                         trying socketpair; both must work
│ cache ≠ unknown ⇒ cache' = cache        the answer never changes in a run
└─────────────────────────────────────────────────────────
```

## State Diagram

The functions in this file keep almost no state.  The one piece they do keep is
the answer to "can this perl make a unix socket?", which is worked out once,
the first time it is needed, and then never changes.

```
              both tries work
+---------+ -------------------------> +---------+ <---+
| UNKNOWN |                            | UNIX_OK |     | every later call
+---------+ ---+                       +---------+ ----+ (no change)
               |  try fails
               |                       +---------+ <---+
               +---------------------> | NO_UNIX |     | every later call
                                       +---------+ ----+ (calls die)
```

A directory, as seen by ["ensure\_dir"](#ensure_dir), moves through these states.  The
function does not remember them; they describe what it finds and what it does.

```
+---------+   mkdir 0700 works    +---------+
| MISSING | --------------------> | PRESENT |   (it existed, or was just made)
+---------+                       +---------+
     |                              |      |
     | mkdir fails                  |      | I own it, and group and
     | (parent missing, no          |      | other cannot write to it
     |  permission, ...)            |      v
     |                              |   +------+
     |                              |   | SAFE |   returns (1, undef)
     |                              |   +------+
     |                              | someone else owns it, or
     |                              | group or other can write to it
     v                              v
  +------------------------------------+
  | REFUSED   returns (0, $why)        |
  +------------------------------------+
```

- UNKNOWN to UNIX\_OK or NO\_UNIX

    Trigger: the first call to `socket_path` or `ensure_dir` (or the check in
    `Makefile.PL`).  Action: try to name a unix socket (`pack_sockaddr_un`) and to
    make a pair of connected ones (`socketpair`).  The
    answer is stored in `$Class::Shared::UNIX_SOCKETS` and is never asked again.

- UNIX\_OK, no change

    Trigger: any later call.  Action: none; `socket_path` and `ensure_dir` work as
    described above.

- NO\_UNIX, no change

    Trigger: any later call to `socket_path` or `ensure_dir`.  Action: the call
    dies with a message saying that this perl has no unix sockets.

- MISSING to PRESENT

    Trigger: `ensure_dir` on a directory that does not exist but whose parent does.
    Action: `mkdir` with mode 0700.

- MISSING to REFUSED

    Trigger: the `mkdir` fails, for example because the parent does not exist.
    Action: return `(0, $reason)`.

- PRESENT to SAFE

    Trigger: `ensure_dir` finds that this user owns the directory and that group
    and other users cannot write to it.  Action: return `(1, undef)`.

- PRESENT to REFUSED

    Trigger: `ensure_dir` finds a different owner, or that group or other users can
    write to it.  Action: return `(0, $reason)`.

## Licence and Copyright

Copyright 2026 Nigel Horne.

Class::Shared is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by the
Free Software Foundation.

Class::Shared is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the `LICENSE` file for the full text.

If you use it, please let me know.
