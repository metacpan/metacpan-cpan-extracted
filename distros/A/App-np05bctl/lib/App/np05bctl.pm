package App::np05bctl;
our $VERSION = "1.04";

=head1 NAME

np05bctl -- Command line utility for accessing the Synaccess NP-05B networked power strip

=head1 SYNOPSIS

    $ np05bctl --addr=10.1.2.3 --user=bob --pass=w00t login pset 3 1
    ["login", "OK"]
    ["pstat", "OK", {"1": 0, "2": 0, "3": 1, "4": 0, "5": 0}]

    $ np05bctl --addr=10.1.2.3 -p stat
    [
       "stat",
       "OK",
       {
          "eth": "on",
          "gw": "192.168.1.1",
          "ip": "10.1.2.3",
          "mac": "00:90:c2:12:34:56",
          "mask": "255.255.0.0",
          "model": "NP-05B",
          "port_http": "80",
          "port_telnet": "23",
          "power_hr": {
             "1": 0,
             "2": 0,
             "3": 1,
             "4": 0,
             "5": 0
          },
          "s_gw": "192.168.1.1",
          "s_ip": "10.1.2.3",
          "s_mask": "255.255.0.0",
          "source": "static",
          "src_ip": "0.0.0.0"
       }
    ]

=head1 DESCRIPTION

C<np05bctl> is a light wrapper around L<Device::Power::Synaccess::NP05B>, providing its functionality as a command line utility.

Please see L<Device::Power::Synaccess::NP05B> for details.

=head1 OPTIONS

   -p         Pretty-format json output
   -q         Do not print results of command to stdout
   --addr=<#> Dotted IP address of NP-05B (default: 192.168.1.100)
   --user=<s> Username for logging into NP-05B (default: admin)
   --pass=<s> Password for logging into NP-05B (default: admin)

=head1 COMMANDS

Command results are written to stdout as JSON of one of the two formats:

    [<operation>, "OK", <optional JSON object>]
    [<operation>, "ERROR", <error description>]

Commands may be stacked.  For instance, to authenticate and then turn on ports 3 and 4:

    np05bctl login pset 3 1 pset 4 1
    ["login", "OK"]
    ["pstat", "OK", {"1": 0, "2": 0, "3": 1, "4": 0, "5": 0}]
    ["pstat", "OK", {"1": 0, "2": 0, "3": 1, "4": 1, "5": 0}]

=over 4

=item login

Authenticate with the C<NP-05B>.  Depending on your configuration this might not be necessary.

=item pset X Y

Turn outlet I<X> on (I<Y>=1) or off (I<Y>=2).

For the author's five-port device, the valid range for I<X> is 1..5

=item pstat

Show which outlets are on or off.

=item stat

Dump the NP-05B's system configuration.

=back

=head1 NO WARRANTY
 
This software is provided "as-is," without any express or implied
warranty. In no event shall the author be held liable for any damages
arising from the use of the software.

=head1 BUGS

At the time of this writing, following C<login> with C<stat> does not work correctly. If you have configured your C<NP-05B> to allow unauthenticated commands, C<stat> without C<login> works fine. This is a fairly heinous bug and the author will be fixing it.

=head1 TO DO

Support additional features as they become implemented in L<Device::Power::Synaccess::NP05B> (also developed by this author).

=head1 AUTHOR

TTK Ciar E<lt>ttk@ciar.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2017 TTK Ciar

=head1 LICENSE

You may use and distribute this program under the same terms as Perl itself.

=cut
