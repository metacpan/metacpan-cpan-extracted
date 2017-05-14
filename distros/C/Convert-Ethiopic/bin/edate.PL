#!/usr/bin/perl -w

use strict;
use Convert::Ethiopic;
use Convert::Ethiopic::System;
use Getopt::Std;

# use diagnostics;

my $default_lang  = $amh;

sub usage
{
	print_version();
	print STDERR <<EOF;
Usage: edate [options]
  Without options:  ዓርብ ሚያዝያ 8 19:01:26 1991
  where [options] can be:
    -a         Format with ዓመተ ምሕረት:
                  ዓርብ ሚያዝያ 8 19:04:15 1991 ዓ.ም
    -/         Format with '/' between ዓ.ም (goes with -a):
                  ዓርብ ሚያዝያ 8 19:04:29 1991 ዓ/ም
    -,         Format with Ethiopic comma after day of week:
                  ዓርብ፣ ሚያዝያ 8 19:04:36 1991
    -d         Format day of month with Ethiopic numerals:
                  ዓርብ ሚያዝያ ፰ 19:04:56 1991
    -h         Format with Ethiopian hour system:
                  ዓርብ ሚያዝያ 8 13:05:01 1991
    -l [lang]  Change default language as per: -l amh or -l tir :
                  ዓርቢ ሚያዝያ 8 19:24:01 1991
    -n         Format with Ethiopic wordspace:
                  ዓርብ፡ሚያዝያ፡8፡19:05:10፡1991
    -q         Format with word "day" after day of month: 
                  ዓርብ ሚያዝያ 8 ቀን 19:05:15 1991
    -y         Format year with Ethiopic numerals:
                  ዓርብ ሚያዝያ 8 19:05:21 ፲፱፻፺፩
    -?         Print this message and quit.
EOF
	exit;

}


sub print_version
{
	print STDERR "This is edate version $Convert::Ethiopic::VERSION.\n";
}


sub SetLC
{
my ($LCInfo) = $WITHUTF8;
my (%options);

	getopts ('a,hdynq?/l:', \%options);

	usage if ( $options{'?'} );

	my ($lang) = ( $options{l} ) 
	              #   Assume either Tigrigna or Amharic for now.
	              ? ( ( $options{l} =~ /ti/ ) ? $tir : $amh )
	              : $default_lang
	              ;

	$LCInfo |= $WITHAM        if ( $options{a} );
	$LCInfo |= $WITHDAYCOMMA  if ( $options{','} );
	$LCInfo |= $WITHETHHOUR   if ( $options{h} );
	$LCInfo |= $WITHETHDATE   if ( $options{d} );
	$LCInfo |= $WITHETHYEAR   if ( $options{y} );
	$LCInfo |= $WITHNETEB     if ( $options{n} );
	$LCInfo |= $WITHQEN       if ( $options{q} );
	$LCInfo |= $WITHSLASH     if ( $options{'/'} );

	undef ( %options );
	return ( $lang, $LCInfo );

}


main:
{
	print easctime ( localtime, $eng, SetLC(@_) );
}


__END__


=head1 NAME

edate -- print date and time in Amharic or Tigrigna with locale options

=head1 FORMAT

edate.pl [options]

=head1 SYNOPSIS

C<edate.pl -c -q -a -y -l tir>

Please see the help

	edate.pl -?

for short usage info.

=head1 DESCRIPTION

edate.pl is the Perl analogue of "edate" which comes with the LibEth library.
edate.pl also requires LibEth and the Ethiopic:: module which is itself an
interface to LibEth.  edate.pl does not yet fully emulate the capabilities of
LibEth edate but that is an eventual goal.

=head1 OPTIONS

Note:  C<edate.pl -?> will present the same information with examples in UTF8
(which chokes under standard man output).

=over 4

=item -a

Format with Amete Mehret.

=item -/

Format with '/' between Amete Mehret (goes with C<-a>).

=item -c

Format with Ethiopic comma after day of week.

=item -d

Format day of month with Ethiopic numerals.

=item -h

Format with Ethiopian hour system.

=item -l [lang]

Change default language as per: C<-l amh> or C<-l tir> .

=item -n

Format with Ethiopic wordspace.

=item -q

Format with word "day" after day of month.

=item -y

Format year with Ethiopic numerals.

=item -?

Print help message and quit.

=head1 SEE ALSO

perl(1).  Et(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=cut
