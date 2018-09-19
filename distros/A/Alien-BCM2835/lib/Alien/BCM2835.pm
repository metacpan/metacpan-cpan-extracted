#
# $Id: BCM2835.pm 60 2018-09-18 01:47:22Z stro $
#

package Alien::BCM2835;

use strict;
use warnings;

use parent 'Alien::Base';

our $VERSION = '1.056';

1;

# ABSTRACT: Alien installation of bcm2835 library

#pod =head1 NAME
#pod
#pod Alien::BCM2835
#pod
#pod =head1 VERSION
#pod
#pod 1.056
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module download and builds external bcm2835 library.
#pod
#pod bcm2835 is the Broadcom BCM2835 library that provides access to GPIO and other functions on the Broadcom BCM 2835
#pod chip, as used in Raspberry Pi.
#pod
#pod You can use L<Device::BCM2835> to access GPIO and other functions on Raspberry Pi.
#pod
#pod http://www.airspayce.com/mikem/bcm2835/
#pod
#pod =head1 AUTHOR
#pod
#pod Serguei Trouchelle E<stro@cpan.org>
#pod
#pod =cut
