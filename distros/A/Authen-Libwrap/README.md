# NAME

Authen::Libwrap - access to Wietse Venema's TCP Wrappers library

# SYNOPSIS

    use Authen::Libwrap qw( hosts_ctl STRING_UNKNOWN );

    # we know the remote username (using identd)
    $rc = hosts_ctl(
      "programname",
          "hostname.domain.com",
          "10.1.1.1",
          "username"
    );
    print "Access is ", $rc ? "granted" : "refused", "\n";

    # we don't know the remote username
    $rc = hosts_ctl(
      "programname",
          "hostname.domain.com",
          "10.1.1.1"),
    );
    print "Access is ", $rc ? "granted" : "refused", "\n";

    # use a socket instead
    my $client = $listener->accept();
    $rc = hosts_ctl( "programname" $socket );
    print "Access is ", $rc ? "granted" : "refused", "\n";

# DESCRIPTION

The Authen::Libwrap module allows you to access the hosts\_ctl() function from
the popular TCP Wrappers security package.  This allows validation of
network access from perl programs against the system-wide `hosts.allow`
file.

If any of the parameters to hosts\_ctl() are not known (i.e. username due to
lack of an identd server), the constant STRING\_UNKNOWN may be passed to
the function.

# FUNCTIONS

Authen::Libwrap has only one function, though it can be invoked
in several ways.  In each case, an true return code indicates that
the connection is allowed per the rules in `hosts.allow` and an
undef value indicates the opposite.

## hosts\_ctl($daemon, $hostname, $ip\_addr, \[ $user \] )

Takes three mandatory and one optional argument. `$daemon` is the service
for which access is being requested (like 'ftpd' or 'sendmail').
`$hostname` is the name of the host requesting access. `$ip_addr` is the
IP address of the host in dotted-quad notation. `$user` is the name of the
user requesting access. If unknown, $user can be omitted; STRING\_UNKNOWN
will be passed in it's place.

## hosts\_ctl($daemon, $socket, \[ $user \] )

If you have a socket (be it a glob, glob reference or an IO::Socket::INET,
you can pass that as the second argument. The hostname and IP address will
be determined using this socket. If the hostname or IP address cannot be
determined from the socket, STRING\_UNKNOWN will be passed in their place.

# DEBUGGING

If you want to see the arguments that will be passed to the C function
hosts\_ctl(), set $Authen::Libwrap::DEBUG to a true value.

# EXPORTS

Nothing unless you ask for it.

hosts\_ctl optionally

STRING\_UNKNOWN optionally

# EXPORT\_TAGS

- **functions**

        hosts_ctl

- **constants**

        STRING_UNKNOWN

- **all**

    everything the module has to offer.

# CONSTANTS

    STRING_UNKNOWN

# BUGS AND FEATURES

Please report any bugs or feature requests (and a pull request for bonus points)
 through the issue tracker at [https://github.com/drmuey/p5-Authen-Libwrap/issues](https://github.com/drmuey/p5-Authen-Libwrap/issues).

- **twist** in `hosts.allow`

    Calls to hosts\_ctl() which match a line in `hosts.allow` that uses the
    "twist" option will terminate the running perl program.  This is not a bug
    in Authen::Libwrap per se -- libwrap uses exec(3) to replace the running
    process with the specified program, so there's nothing to return to.

    Some operating systems ship with a default catch-all rule in `hosts.allow`
    that uses the twist option.  You may have to modify this configuration to
    use Authen::Libwrap effectively.

- Test suite is not comprehensive

    The test suite isn't very comprehensive because the path to hosts.allow is
    set when libwrap is built and I can't tell what the user's rules are. I can
    make sure the function calls don't die, but I can't really tell if any call
    to hosts\_ctl should give back a true or false value.

# TODO

In early 2003 I was contacted by another Perl developer who had developed an
XS interface to libwrap that covered more of the API than mine did.
Originally he offered it as a patch to my module, but at the time I wasn't
in a position to actively maintain anything on CPAN, so I suggested that he
upload it himself. I unfortunately lost the email thread to a disk crash.

As of December 2003 I don't see any other modules professing to support
libwrap om CPAN. If that person is still out there, please get in contact
with me, otherwise I'll plan on implementing some of these TODOs in the new
year:

- provide support for hosts\_access and request\_\* functions
- develop an OO interface

# SEE ALSO

[Authen::Tcpdmatch](https://metacpan.org/pod/Authen::Tcpdmatch), a Pure Perl module that can parse hosts.allow and
hosts.deny if you don't need all the underlying features of libwrap.

hosts\_access(3), hosts\_access(5), hosts\_options(5)

Wietse's tools and papers page:
[ftp://ftp.porcupine.org/pub/security/index.html](ftp://ftp.porcupine.org/pub/security/index.html).

# AUTHOR

James FitzGibbon, &lt;jfitz@CPAN.org>
