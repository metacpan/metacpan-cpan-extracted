#!/usr/bin/perl
# -*-cperl-*-
#
# App::NoodlePay - Convenient way to securely send Bitcoin from cold storage
# Copyright (c) Ashish Gulhati <noodlepay at hash.neo.tc>
#
# $Id: lib/App/NoodlePay.pm v1.006 Tue Jun 19 01:28:57 PDT 2018 $

package App::NoodlePay;

use warnings;
use strict;

use Wx qw (:everything);
use Wx::Event qw (EVT_BUTTON);
use GD::Barcode::QRcode;
use Math::Prime::Util qw(fromdigits todigitstring);
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.006 $' =~ /\s+([\d\.]+)/;

1;

__END__

=head1 NAME

App::NoodlePay - Convenient way to securely send Bitcoin from cold storage

=head1 VERSION

 $Revision: 1.006 $
 $Date: Tue Jun 19 01:28:57 PDT 2018 $

=head1 SYNOPSIS

  noodlepay.pl [--offline] [--online]

=head1 DESCRIPTION

noodlepay.pl (Noodle Pay) enables the use of an air-gapped wallet
running on a device such as a Noodle Air (L<http://www.noodlepi.com>)
to easily and securely send Bitcoin payments.

Noodle Pay is much more convenient to use than hardware wallets, and
doesn't require single-purpose hardware. The Noodle Air device is a
general purpose Linux computer, which can be used for many other
applications as well.

Noodle Pay uses the Electrum wallet's command line mode to create,
sign and publish Bitcoin transactions.

To use Noodle Pay to send Bitcoin from cold storage, you would first
create a cold storage wallet using Electrum on a Noodle Air. Then you
copy the master public key from the Noodle Air to a Noodle Pi, and
create a "watching-only wallet" on the Noodle Pi.

Now you can receive funds to your cold storage wallet and keep track
of them using your watching-only wallet on the Noodle Pi (or any other
computer).

To spend funds from your cold storage wallet, you run noodlepay.pl on
the Noodle Pi, and "noodlepay.pl --offline" on the Noodle Air. Click
"Send" on the Noodle Pi, and enter the amount, scan the destination
address QR code, and enter the transaction fee amount.

A QR code then pops up on the screen, which you scan on the Noodle Air
by clicking "Sign". You're then asked to confirm the transaction, and
if you do a QR code pops up, which you now scan on the Noodle
Pi. You're then asked for confirmation to broadcast the transaction,
and when you click OK it is broadcast.

Your private keys always stay secure on the offline Noodle Air.

Noodle Pay provides a truly mobile, wire-free and convenient cold
storage payment solution. Most hardware wallets require the use of a
desktop or laptop computer, and a USB cable to connect it to the
hardware wallet device.

Compared to other hardware wallet solutions, Noodle Pay also greatly
simplifies physically securing your private keys, and keeping
backups. You can simply pop the MicroSD card out of the Noodle Air,
and keep it physically secure. For backups, you can just duplicate the
MicroSD card, and keep multiple copies in safe locations.

=head1 CONFIGURATION

The $electrum variable at the top of noodlepay.pl should be set to the
path or command required to run electrum on your system.

=head1 OPTION SWITCHES

=head2 --offline

Use this switch when running the app offline on a Noodle Air.

=head2 --online

Use this switch to have the app sign transactions directly on Noodle
Pi rather than delegating signing to an air-gapped Noodle Air.

=head1 PREREQUISITES

Currently this app is designed to work on Noodle Pi / Noodle
Air devices, and requires the following programs to be
available:

* electrum

* zbarcam

* v4l2-ctl

* xvkbd

=head1 SEE ALSO

L<http://www.noodlepi.com>

L<http://www.noodlepay.com>

=head1 AUTHOR

Ashish Gulhati, C<< <noodlepay at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-noodlepay at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-NoodlePay>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::NoodlePay

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-NoodlePay>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-NoodlePay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-NoodlePay>

=item * Search CPAN

L<http://search.cpan.org/dist/App-NoodlePay/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
