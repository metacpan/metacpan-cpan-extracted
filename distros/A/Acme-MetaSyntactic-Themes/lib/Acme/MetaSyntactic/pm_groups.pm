package Acme::MetaSyntactic::pm_groups;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.032';
__PACKAGE__->init();

our %Remote = (
    source  => 'http://www.pm.org/groups/perl_mongers.xml',
    extract => sub {
        return
            map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            map { s/#/Pound_/g; $_ }
            map { s/&([aeiouy])(?:acute|grave|circ|uml);/$1/g; $_ }
            $_[0] =~ m!<group id="\d+" status="active">\s*<name>\s*([^<]+)\s*</nam!g;
    },
);

1;

=head1 NAME

Acme::MetaSyntactic::pm_groups - The Perl Mongers groups theme

=head1 DESCRIPTION

List all the B<active> Perl Mongers groups, as described in the master
Perl Mongers file L<http://www.pm.org/groups/perl_mongers.xml>.

=head1 CONTRIBUTOR

Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2026-01-12 - v1.032

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.056.

=item *

2021-04-30 - v1.031

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.055.

=item *

2019-07-29 - v1.030

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.053.

=item *

2018-10-29 - v1.029

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.052.

=item *

2017-11-13 - v1.028

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.051.

=item *

2017-06-12 - v1.027

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.050.

=item *

2016-03-21 - v1.026

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.049.

=item *

2015-10-19 - v1.025

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.048.

=item *

2015-08-10 - v1.024

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.047.

=item *

2015-06-08 - v1.023

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.046.

=item *

2015-02-02 - v1.022

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.045.

=item *

2015-01-05 - v1.021

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.044.

=item *

2014-08-18 - v1.020

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.041.

=item *

2014-06-16 - v1.019

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.040.

=item *

2014-04-07 - v1.018

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.017

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.038.

=item *

2013-10-14 - v1.016

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.037.

=item *

2013-09-16 - v1.015

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.036.

=item *

2013-07-29 - v1.014

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.035.

=item *

2013-07-22 - v1.013

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.034.

=item *

2013-06-17 - v1.012

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.033.

=item *

2013-06-03 - v1.011

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.032.

=item *

2013-03-25 - v1.010

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.031.

=item *

2013-02-18 - v1.009

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.030.

=item *

2013-01-14 - v1.008

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.029.

=item *

2012-11-19 - v1.007

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.028.

=item *

2012-10-29 - v1.006

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.025.

=item *

2012-10-22 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.024.

=item *

2012-09-10 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.018.

=item *

2012-08-27 - v1.003

Added support for accented group names
in Acme-MetaSyntactic-Themes version 1.016.

=item *

2012-06-25 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.007.

=item *

2012-05-28 - v1.001

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.003.

=item *

2012-05-07 - v1.000

Updated with changes since November 2006, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-11-06

Updated from the source web site in Acme-MetaSyntactic version 0.99.

=item *

2006-10-09

Updated from the source web site in Acme-MetaSyntactic version 0.95.

=item *

2006-09-25

Updated from the source web site in Acme-MetaSyntactic version 0.93.

=item *

2006-09-11

Updated from the source web site in Acme-MetaSyntactic version 0.91.

=item *

2006-080-14

Updated from the source web site in Acme-MetaSyntactic version 0.87.

=item *

2006-07-10

Updated from the source web site in Acme-MetaSyntactic version 0.82.

=item *

2006-06-19

Updated from the source web site in Acme-MetaSyntactic version 0.79.

=item *

2006-06-05

Updated from the source web site in Acme-MetaSyntactic version 0.77.

=item *

2006-05-01

Updated from the source web site in Acme-MetaSyntactic version 0.72.

=item *

2006-03-06

Updated from the source web site in Acme-MetaSyntactic version 0.64.

=item *

2006-02-13

Updated from the source web site in Acme-MetaSyntactic version 0.61.

=item *

2006-02-06

Updated from the source web site in Acme-MetaSyntactic version 0.60.

=item *

2006-01-23

Updated from the source web site in Acme-MetaSyntactic version 0.58.

=item *

2006-01-09

Updated from the source web site in Acme-MetaSyntactic version 0.56.

=item *

2005-11-21

Introduced in Acme-MetaSyntactic version 0.49.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Austin_pm
Berlin_pm
Birmingham_pm
Boston_pm
Dahut_pm
DC_pm
Houston_pm
Kichij_ji_pm
London_pm
Los_Angeles_pm
Okinawa_pm
Oslo_pm
Paris_pm
Philadelphia_pm
Purdue_pm
SanDiego_pm
SanFrancisco_pm
Sh_nan_pm
Sonoma_pm
Sydney_pm
Toronto_pm
Vienna_pm
