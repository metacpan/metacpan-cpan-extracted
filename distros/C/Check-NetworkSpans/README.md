# Check-NetworkSpans

This a Nagios style check that checks network spans forwarded from a
switch to a system running Suricata or the like is configured properly.

The folowing checks are done.

- interfaces are up
- traffic is seen on those interfaces
- span has the required number of packets
- TCP/UDP packets are seen for the expected ports
- bi-directional TCP/UDP traffic is seen

Gathering packets is done via tshark, this ensures packets
encapsulated in VLAN packets are handled.

First IP of every interface can automatically be ignored and others
manually specified. Purpose of ignoring this traffic is to ensure that
traffic for the system it is running on is ignored should in a worse
case scenario it be ran on a system in which the ingestion interface
and management interface is the same.

# INSTALLATION

## FreeBSD

```
pkg install p5-Rex p5-Regexp-IPv6 p5-Data-Dumper p5-String-ShellQuote p5-JSON p5-App-cpanminus
cpanm Check::NetworkSpans
```

## Debian

```
apt-get install rex libdata-dumper-perl libstring-shellquote-perl libjson-perl cpanminus
cpanm Check::NetworkSpans
```

## From Source

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Check::NetworkSpans
	perldoc check_networkspans

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        https://rt.cpan.org/NoAuth/Bugs.html?Dist=Check-NetworkSpans

    CPAN Ratings
        https://cpanratings.perl.org/d/Check-NetworkSpans

    Search CPAN
        https://metacpan.org/release/Check-NetworkSpans


# LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

