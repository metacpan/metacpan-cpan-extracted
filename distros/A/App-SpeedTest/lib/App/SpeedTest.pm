#!/usr/bin/perl

package App::SpeedTest;

use strict;
use warnings;

our $VERSION = "0.19";

1;
__END__

=encoding UTF-8

=head1 NAME

App::SpeedTest - Command-line interface to speedtest.net

=head1 SYNOPSIS

 $ speedtest [ --no-geo | --country=NL ] [ --list | --ping ] [ options ]

 $ speedtest --list
 $ speedtest --ping --country=BE
 $ speedtest
 $ speedtest -s 4358
 $ speedtest --url=http://ookla.extraip.net
 $ speedtest -q --no-download
 $ speedtest -Q --no-upload

=head1 DESCRIPTION

The provided perl script is a command-line interface to the
L<speedtest.net|http://www.speedtest.net/> infrastructure so that
flash is not required

It was written to feature the functionality that speedtest.net offers
without the overhead of flash or java and the need of a browser.

=head1 Raison-d'Ãªtre

The tool is there to give you a quick indication of the achievable
throughput of your current network. That can drop dramatically if
you are behind (several) firewalls or badly configured networks (or
network parts like switches, hubs and routers).

It was inspired by L<speedtest-cli|https://github.com/sivel/speedtest-cli>,
a project written in python. But I neither like python, nor did I like the
default behavior of that script. I also think it does not take the right
decisions in choosing the server based on distance instead of speed. That
B<does> matter if one has fiber lines. I prefer speed over distance.

=head1 Command-line Arguments

=over 2

=item -? | --help
X<-?>
X<--help>

Show all available options and then exit.

=item -V | --version
X<-V>
X<--version>

Show program version and exit.

=item --man
X<--man>

Show the builtin manual using C<pod2man> and C<nroff>.

=item --info
X<--info>

Show the builtin manual using C<pod2text>.

=item -v[#] | --verbose[=#]
X<-v>
X<--version>

Set verbose level. Default value is 1. A plain -v without value will set
the level to 2.

=item --simple
X<--simple>

An alias for C<-v0>

=item --all
X<--all>

No (default) filtering on available servers. Useful when finding servers
outside of the country of your own location.

=item -g | --geo
X<-g>
X<--geo>

Use GEO-IP service to find the country your ISP is located. The default
is true. If disable (C<--no-geo>), the server to use will be based on
distance instead of on latency.

=item -cXX | --cc=XX | --country=XX
X<-c>
X<--cc>
X<--country>

Pass the ISO country code to select the servers

 $ speedtest -c NL ...
 $ speedtest --cc=B ...
 $ speedtest --country=D ...

=item -1 | --one-line
X<-1>
X<--ono-line>

Generate a very short report easy to paste in e.g. IRC channels.

 $ speedtest -1Qv0
 DL:   40.721 Mbit/s, UL:   30.307 Mbit/s

=item -B | --bytes
X<-B>
X<--bytes>

Report throughput in Mbyte/s instead of Mbit/s

=item -C | --csv
X<-C>
X<--csv>

Generate the measurements in CSV format. The data can be collected in
a file (by a cron job) to be able to follow internet speed over time.

The reported fields are

 - A timestam (the time the tests are finished)
 - The server ID
 - The latency in ms
 - The number of tests executed in this measurement
 - The direction of the test (D = Down, U = Up)
 - The measure avarage speed in Mbit/s
 - The minimum speed measured in one of the test in Mbit/s
 - The maximum speed measured in one of the test in Mbit/s

 $ speedtest -Cs4358
 "2015-01-24 17:15:09",4358,63.97,40,D,93.45,30.39,136.93
 "2015-01-24 17:15:14",4358,63.97,40,U,92.67,31.10,143.06

=item -P | --prtg
X<-P>
X<--prtg>

Generate the measurements in XML suited for PRTG

 $ speedtest -P
 <?xml version="1.0" encoding="UTF-8" ?>
 <prtg>
   <text>Testing from My ISP (10.20.30.40)</text>
   <result>
     <channel>Ping</channel>
     <customUnit>ms</customUnit>
     <float>1</float>
     <value>56.40</value>
     </result>
   <result>
     <channel>Download</channel>
     <customUnit>Mbit/s</customUnit>
     <float>1</float>
     <value>38.34</value>
     </result>
   <result>
     <channel>Upload</channel>
     <customUnit>Mbit/s</customUnit>
     <float>1</float>
     <value>35.89</value>
     </result>
   </prtg>

=item -l | --list
X<-l>
X<--list>

This option will show all servers in the selection with the distance in
kilometers to the server.

 $ speedtest --list --country=IS
 4998: GreenQloud                     Hafnarfjordur   2066.12 km
 4141: Vodafone                       Reykjavík       2068.59 km
 4820: 365                            Reykjavík       2068.59 km
 4818: Siminn                         Reykjavik       2068.59 km
 1092: Hringidan ehf                  Reykjavik       2068.59 km
 3684: Nova                           Reykjavik       2068.59 km
 3644: Snerpa                         Isafjordur      2222.57 km

=item -p | --ping
X<-p>
X<--ping>

Show a list of servers in the selection with their latency in ms.
Be very patient if running this with L</--all>.

 $ speedtest --ping --cc=BE
 5151: Combell                        Brussels         148.45 km     120 ms
 4812: Universite Catholique de Louva Louvain-La-Neuv  159.41 km     122 ms
 2419: VOO                            Liege            154.15 km     131 ms
 4904: Verixi SPRL                    Louvain-La-Neuv  159.41 km     137 ms
 4320: EDPnet                         Sint-Niklaas     128.45 km     258 ms
 4319: Mobistar NV                    Evere            145.15 km     308 ms
 3457: iGlobe bvba                    Diegem           141.28 km     340 ms
 5867: Teleweb                        Lokeren          141.00 km     541 ms
 2955: Nucleus BVBA                   Antwerp          111.57 km 4000000 ms
 2848: Cu.be Solutions                Diegem           141.28 km 4000000 ms

If a server does not respond, a very high latency is used as default.

=item --url=XXX
X<--url>

=item --ip
X<--ip>

=item -T[#] | --try[=#]
X<-T>
X<--try>

Use the top # (based on lowest latency or shortest distance) from the list
to do all required tests.

 $ speedtest -T3 -c NL -Q2
 Testing for 80.x.y.z : XS4ALL Internet BV (NL)

 Using 4358:  52.33 km      64 ms KPN
 Test download ..                                      Download:   30.497 Mbit/s
 Test upload   ..                                      Upload:     32.366 Mbit/s

 Using 4045:  52.33 km      66 ms SoftLayer Technologies, Inc.
 Test download ..                                      Download:   31.971 Mbit/s
 Test upload   ..                                      Upload:     33.503 Mbit/s

 Using 3386:  52.33 km      67 ms NFOrce Entertainment B.V.
 Test download ..                                      Download:   28.022 Mbit/s
 Test upload   ..                                      Upload:     33.221 Mbit/s

=item -s# | --server=#
X<-s>
X<--server>

Specify the ID of the server to test against. This ID can be taken from the
output of L</--list> or L</--ping>. Using this option prevents fetching the
complete server list and calculation of distances. It also enables you to
always test against the same server.

 $ speedtest -1s4358
 Testing for 80.x.y.z : XS4ALL Internet BV ()
 Using 4358:  52.33 km      64 ms KPN
 Test download ........................................Download:   92.633 Mbit/s
 Test upload   ........................................Upload:     92.552 Mbit/s
 DL:   92.633 Mbit/s, UL:   92.552 Mbit/s

=item -t# | --timeout=#
X<-t>
X<--timeout>

Specify the maximum timeout in seconds.

=item -d | --download
X<-d>
X<--download>

Run the download tests. This is default unless L</--upload> is passed.

=item -u | --upload
X<-u>
X<--upload>

Run the upload tests. This is default unless L</--download> is passed.

=item -q[#] | --quick[=#] | --fast[=#]
X<-q>
X<--quick>
X<--fast>

Don't run the full test. The default test runs 40 tests, sorting on
increasing test size (and thus test duration). Long(er) tests may take
too long on slow connections without adding value. The default value
for C<-q> is 20 but any value between 1 and 40 is allowed.

=item -Q[#] | --realquick[=#]
X<-Q>
X<--realquick>

Don't run the full test. The default test runs 40 tests, sorting on
increasing test size (and thus test duration). Long(er) tests may take
too long on slow connections without adding value. The default value
for C<-Q> is 10 but any value between 1 and 40 is allowed.

=item -mXX | --mini=XX
X<-m>
X<--mini>

Run the speedtest on a speedtest mini server.

=item --source=XX

NYI - mentioned for speedtest-cli compatibility

=back

=head1 EXAMPLES

See L</SYNOPSIS> and L</Command-line arguments>

=head1 DIAGNOSTICS

...

=head1 BUGS and CAVEATS

Due to language implementation, it may report speeds that are not
consistent with the speeds reported by the web interface or other
speed-test tools.  Likewise for reported latencies, which are not
to be compared to those reported by tools like ping.

=head1 TODO

=over 2

=item Improve documentation

What did I miss?

=item Enable alternative XML parsers

XML::Simple is not the recommended XML parser, but it sufficed on
startup. All other API's are more complex.

=back

=head1 PORTABILITY

As Perl has been ported to a plethora of operating systems, this CLI
will work fine on all systems that fulfill the requirement as listed
in Makefile.PL (or the various META files).

The script has been tested on Linux, HP-UX, AIX, and Windows 7.

Debian wheezy will run with just two additional packages:

 # apt-get install libxml-simple-perl libdata-peek-perl

=head1 SEE ALSO

The L<speedtest-cli|https://github.com/sivel/speedtest-cli> project
that inspired me to improve a broken CLI written in python into out
beloved language Perl.

=head1 CONTRIBUTING

=head2 General

I am always open to improvements and suggestions. Use issues at
L<github issues|https://github.com/Tux/speedtest/issues>.

=head2 Style

I will never accept pull request that do not strictly conform to my
style, however you might hate it. You can read the reasoning behind
my preferences L<here|http://tux.nl/style.html>.

I really don't care about mixed spaces and tabs in (leading) whitespace

=head1 WARRANTY

This tool is by no means a guarantee to show the correc6t speeds. It
is only to be used as an indication of the throughput of your internet
connection. The values shown cannot be used in a legal debate.

=head1 AUTHOR

H.Merijn Brand F<E<lt>h.m.brand@xs4all.nlE<gt>> wrote this for his own
personal use, but was asked to make it publicly available as application.

=head1 COPYRIGHT

Copyright (C) 2014-2016 H.Merijn Brand

=head1 LICENSE

This software is free; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
