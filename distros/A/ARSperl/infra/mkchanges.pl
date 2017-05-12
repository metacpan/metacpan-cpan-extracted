#!/usr/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/infra/mkchanges.pl,v 1.9 2008/11/24 15:40:23 jeffmurphy Exp $
#
# mkchanges.pl [-t] -f changes.dat
#
# generate a "CHANGES" or "changes.html" file
# based on the "changes.dat" file
#
# jeff murphy
# jcmurphy@hot-sauce.org
#
# this code is available under the terms of the GNU license or the
# Perl Artistic License (your choice).

use strict;
use FileHandle;
use vars qw{$opt_t $opt_f};
use Getopt::Std;

getopts('tf:');

my ($html) = defined($opt_t)?0:1;

if((!defined($opt_f)) || (! -e "$opt_f")) {
	die "usage: mkchanges.pl [-t] -f changes.dat > outputfile
-t    text output (default = html)
-f    changes.dat input file
";
}

my($f) = new FileHandle($opt_f, "r");
die "open($opt_f) failed: $!" if !defined($f);

if($html) {
	headerHTML();
} else {
	headerTXT();
}

while(<$f>) {
	next if /^\#/;
	if(/^released=(\S+)\s+version=(.*)/) {
		if($html) {
			spewHTML($f, $1, $2);
		} else {
			spewTXT($f, $1, $2);
		}
	}
}
$f->close();

if($html) {
	footerHTML();
} else {
	footerTXT();
}

exit 0;


sub spewHTML {
	my ($f, $rel, $ver) = (shift, shift, shift);
	my ($first)     = 1;
	my ($beenthere) = 0;
	my ($count)     = 0;
  
	while(<$f>) {
		chomp;
		s/\r//g;

		if(/^$/) {
			print "</table></td></tr></table>\n\n<P>\n\n";
			return;
		}

		if(/^(\S+)/) {
			my $who = $1;
			my $cc  = ' ';

			s/^$who//;
			if($who =~ /^\!/) {
				$cc = '!';
				$who =~ s/^\!//;
			}

			s/^\s+//g;

			if($first) {
				$first = 0;
				print "
    <TABLE CELLSPACING='0'
      CELLPADDING='2'
      WIDTH='100%'
      BORDER='0' 
      BGCOLOR='black'>
      <TR>
	<TD width='100%'>
	  <TABLE CELLSPACING='0' CELLPADDING='3' WIDTH='100%' BORDER='0'
	    BGCOLOR='lightblue'>
	    <tr><td colspan='2'>
  <table width='100%' border='0'><tr>
	      <td width='50%'>Released: <B>$rel</B></td>
              <td width='50%'>Version: <B>$ver</B></td>
  </tr></table></td>
            </tr>";
			}


			if($beenthere) {
				print "</font></td></tr>\n";
			}

			$count++;
			my ($bgc) = "\#dddddd";

			$bgc = "\#eeeeee" if($count % 2);

			print "<tr bgcolor='$bgc'><td width='10%'>($who)</td><td width='90%'>";
			$beenthere = 1;
			if($cc eq "!") {
				print "<font color='red'>";
			} else {
				print "<font color='black'>";
			}
			print "$_ \n";
		} else {
			s/^\s+//g;
			print "$_ ";
		}
	}
}

sub spewTXT {
	my ($f, $rel, $ver) = (shift, shift, shift);
	my ($bq) = 0;

	print "Released: $rel Version: $ver\n\n";
	while(<$f>) {
		chomp;

		s/<[\/]{0,1}U>/_/gi;
		$bq = 1 if(/\<BLOCKQUOTE\>/i);
		$bq = 0 if(/\<\/BLOCKQUOTE>/i);
		s/<[\/]{0,1}BLOCKQUOTE>/\ /gi;
		s/<[\/]{0,1}BR>/\ /gi;
		s/&gt;/>/g;
		s/&lt;/</g;
		s/\r//g;

		if(/^$/) {
			print "\n\n";
			return;
		}

		if(/^(\S+)/) {
			my $who = $1;
			my $cc  = ' ';

			s/^$who//;
			if($who =~ /^\!/) {
				$cc = '!';
				$who =~ s/^\!//;
			}

			s/^\s+//g;

			printf("\n%5.5s %s %s\n",
			       "($who)", $cc, $_);
		} else {
			s/^\s+//g;
			my $fmt = "%5.5s %s %s\n"; 
			$fmt = "%s %s\t\t%s\n" if $bq;
			printf($fmt, ' ', ' ', $_);
		}
	}

}


sub headerHTML {
	print "<html><head><title> ARSperl: Revision History </title></head>\n";
	print "
<body bgcolor='white' text='black'><h2>Changes for ARSperl</h2>
 <table  border='0'>
 <tr><td>BM</td><td>=</td><td>Bill Middleton {wjm at metronet.com}</td></tr>
 <tr><td>GDF</td><td>=</td><td>G. David Frye {gdf at uiuc.edu}</td></tr>
 <tr><td>JCM</td><td>=</td><td>Jeff Murphy {jeffmurphy at sourceforge.net}</td></tr>
 <tr><td>JWM</td><td>=</td><td>Joel Murphy {jmurphy at buffalo.edu}</td></tr>
 <tr><td>TS</td><td>=</td><td>Thilo Stapff {tstapff at sourceforge.net}</td></tr>
 <tr><td>CL</td><td>=</td><td>Chris Leach {Chris.Leach at kaz-group.com}</td></tr>
 <tr><td>JL</td><td>=</td><td>John Luthgers {jls17 at gmx.net}</td></tr>
 </table>
 <P>
 The following lists the changes that have been made
 for each release of ARSperl.
 <P>
 Items in <font color='red'>red</font> 
 denote changes that are incompatible with
 previous versions of ARSperl and may require altering of some ARSperl
 scripts.<P>
";
}

sub footerHTML {
	print "\n<P>\n<PRE>\$Header\$</PRE></body></html>\n";
}

sub headerTXT {
	print "CHANGES for ARSperl

Revision history for ARSperl.

BM  = Bill Middleton <wjm at metronet.com>
GDF = G. David Frye  <gdf at uiuc.edu>
JCM = Jeff Murphy    <jcmurphy at buffalo.edu>
JWM = Joel Murphy    <jmurphy at buffalo.edu>
TS  = Thilo Stapff   <tstapff at sourceforge.net>
CL  = Chris Leach    <Chris.Leach at kaz-group.com>
JL  = John Luthgers  <jls17 at gmx.net>

Note: items preceeded by a '!' denoted changes that are incompatible with
previous versions of arsperl and may require altering of some arsperl
scripts.\n\n
";
}

sub footerTXT {
	print "\n\narsperl\@arsperl.org\n\n\$Header\$\n\n";
}
