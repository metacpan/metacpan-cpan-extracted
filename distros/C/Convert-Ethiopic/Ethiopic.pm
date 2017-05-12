package Convert::Ethiopic;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
#
#  Correct the below to where you will install Et.so and libeth.so.
#  If already in your load path then comment out altogether.
#
$ENV{'LD_LIBRARY_PATH'} = '/home2/ethionet/HTML/cgi';

#
#  You shouldn't need these...
#
# $ENV{'LD_PRELOAD'} = '/home2/ethionet/HTML/cgi/libeth.so.0.3.3';
# $ENV{'LD_LIBRARY_PATH'} = '/home2/ethionet/HTML/cgi';

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	LibEthVersion
	LibEthVersionName
	ConvertEthiopicString
	ConvertEthiopicFile
	ConvertEthiopicFileToString
	ArabToEthiopic
	isLeapYear
	isEthiopicLeapYear
	isEthiopianHoliday
	getEthiopicMonth
	getEthiopicDayOfWeek
	getEthiopicDayName
    isBogusEthiopicDate
    isBogusGregorianDate
	FixedToEthiopic
	EthiopicToFixed
	FixedToGregorian
	GregorianToFixed
    EthiopicToGregorian
    GregorianToEthiopic
    easctime
);
$VERSION = '0.12';

bootstrap Convert::Ethiopic $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Ethiopic - Perl extension for the Ethiopic information processing library.

=head1 SYNOPSIS

  use Convert::Ethiopic;

=head1 DESCRIPTION

Convert::Ethiopic.pm is an interface to the LibEth Ethiopic programmers library.

Convert::Ethiopic.pm is I<not> a comprehensive interface to the LibEth library.
The LibEth Perl module is the minimal interface required by the "Zobel"
implementation of the LiveGe'ez Remote Processing Protocol.

=head1 STATUS

This is the third release of the LibEth Perl module and requires the "LibEth"
library version 0.35c or later.

The LibEth Perl Module is very early in its life cycle, extensions will be
made to further utilize the LibEth library through Perl as the need arises.

=head1 BUGS

None known at this time.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

perl(1).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=cut
