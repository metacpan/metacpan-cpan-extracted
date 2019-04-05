package App::Spoor;

use v5.10;
use strict;
use warnings;

=head1 NAME

App::Spoor - A CPanel client for the Spoor service

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module (for now) only contains code to provide a naive implementation of a client for the
Spoor API that plays nicely with CPanel.

It is built with the following principles in mind:

=over

=item * Minimise the impact of the code on the existing CPanel instance

=item * Minimise the footprint on the host, by keeping the dependencies to a bare minimum

=item * Be as transparent as possible about the data that is being submitted

=back

Within the above context, App::Spoor consists of 3 main parts:

=over

=item * Scripts running under systemd that tail the CPanel access, error and login logs

=item * A transmitter script (also running under systemd) that communicates with the Spoor API

=item * A module that registers functionality for tracking changes to mail forwarding within the CPanel standardised hook framework

=back

=head2 Installing

Before installing the module, you will need to enable the logging of successful logins via WHM. At the time of writing,
this can be found by navigating to Server Configuration -> Tweak Settings -> Logging.

Once you have installed the module run the following from the commandline:

    spoor_installer

It will setup a config file, some persistence directories, a number of systemd unit files and it will also create the
file that will register functionality against CPanel's standardised hooks.

Once it has completed, it will list a number of actions that must be performed (as root)before the installation is complete:

    systemctl enable spoor-access-follower.service
    systemctl enable spoor-error-follower.service
    systemctl enable spoor-login-follower.service
    systemctl enable spoor-transmitter.service
    systemctl start spoor-access-follower.service
    systemctl start spoor-error-follower.service
    systemctl start spoor-login-follower.service
    systemctl start spoor-transmitter.service
    cd /usr/local/cpanel/bin/
    ./manage_hooks add module SpoorForwardHook

The install script will create a number of directories, a config file for Spoor as well as several systemd unit files. 

=head2 Operation

App::Spoor operates on a simple principe of tailing CPanel's access, error and login log files. The follower services 
monitor the log files and if they come across an item of interest, they create a JSON-representation of the event and
write it to /var/lib/spoor/parsed.

The transmitter service monitors /var/lib/spoor/parsed for any changes and sends these to the Spoor API. If a transmission 
recives a response of HTTP 202, the JSON file is moved to /var/lib/spoor/transmitted, otherwise it remains in /var/lib/spoor/parsed and
the transmitter will keep on retrying, pretty much until the end of time.

=head2 Uninstalling

To uninstall,do the following (the below assumes that you are using cpanminus):

    cd /usr/local/cpanel/bin/
    ./manage_hooks delete module SpoorForwardHook

    systemctl stop spoor-access-follower.service
    systemctl stop spoor-error-follower.service
    systemctl stop spoor-login-follower.service
    systemctl stop spoor-transmitter.service
    systemctl disable spoor-access-follower.service
    systemctl disable spoor-error-follower.service
    systemctl disable spoor-login-follower.service
    systemctl disable spoor-transmitter.service

    rm -rf /etc/spoor
    rm -rf /var/lib/spoor

    cpanm --uninstall App::Spoor

=head2 Windows

For now, App::Spoor does not support Windows installations.

=cut

=head1 AUTHOR

Rory McKinley, C<< <rorymckinley at capefox.co> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-spoor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Spoor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Spoor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Spoor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Spoor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-Spoor>

=item * Search CPAN

L<https://metacpan.org/release/App-Spoor>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Rory McKinley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::Spoor
