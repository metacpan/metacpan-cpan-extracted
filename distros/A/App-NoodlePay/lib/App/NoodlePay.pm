#!/usr/bin/perl
# -*-cperl-*-
#
# App::NoodlePay - Convenient way to securely send Bitcoin from cold storage
# Copyright (c) 2017 Ashish Gulhati <noodlepay at hash.neo.tc>
#
# $Id: lib/App/NoodlePay.pm v1.002 Mon Sep 25 18:56:05 PDT 2017 $

package App::NoodlePay;

use warnings;
use strict;

use Wx qw (:everything);
use Wx::Event qw (EVT_BUTTON);
use GD::Barcode::QRcode;
use Math::Prime::Util qw(fromdigits todigitstring);
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.002 $' =~ /\s+([\d\.]+)/;

1;

__END__

=head1 NAME

App::NoodlePay - Convenient way to securely send Bitcoin from cold storage

=head1 VERSION

 $Revision: 1.002 $
 $Date: Mon Sep 25 18:56:05 PDT 2017 $

=head1 SYNOPSIS

  noodlepay.pl [--offline]

=head1 DESCRIPTION

noodlepay.pl (Noodle Pay) emables the use of an air-gapped wallet
running on a device such as a Noodle Unsnoopable
(L<http://www.noodlepi.com>) to easily and securely send Bitcoin
payments.

Noodle Pay is much easier to use than hardware wallets, and doesn't
require single-purpose hardware. The Noodle Unsnoopable device is a
general purpose Linux computer, which can be used for many other
applications as well.

=head1 PREREQUISITES

Currently this app is designed to work on Noodle Pi / Noodle
Unsnoopable devices, and requires the following programs to be
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

Copyright (c) 2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
