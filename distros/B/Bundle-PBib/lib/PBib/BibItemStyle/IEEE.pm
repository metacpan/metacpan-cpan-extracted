# --*-Perl-*--
# $Id: IEEE.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBib::BibItemStyle::IEEE;
use strict;
#use English;

=head1 package PBib::BibItemStyle::IEEETR;

% IEEE magazin bibliography style


%    numeric labels, order-of-reference, IEEE abbreviations,
%    quotes around article titles, commas separate all fields
%    except after book titles and before "notes".  Otherwise,
%    much like the "plain" family, from which this is adapted.
%
%   History
%    9/30/85	(HWT)	Original version, by Howard Trickey.
%    1/29/88	(OP&HWT) Updated for BibTeX version 0.99a, Oren Patashnik;
%			THIS `ieeetr' VERSION DOES NOT WORK WITH BIBTEX 0.98i.

This is documented at http://computer.org/...refer.html

=cut

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::BibItemStyle::IEEETR;
use vars qw(@ISA);
@ISA = qw(PBib::BibItemStyle::IEEETR);

# used modules
#use ZZZZ;

# module variables
#use vars qw(mmmm);


1;

#
# $Log: IEEE.pm,v $
# Revision 1.1  2002/10/01 21:28:20  ptandler
# well, I didn't implement changes to the IEEE transactions style yet ...
#

