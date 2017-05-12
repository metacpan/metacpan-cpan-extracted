package Biblio::Citation::Parser::Jiao::Utility;

######################################################################
#
# ParaTools::Citation::Parser::Jiao::Utility;
#
######################################################################
#
#  This file is part of ParaCite Tools
#  Based on Zhuoan Jiao's (zj@ecs.soton.ac.uk) citation parser (available
#  at http://arabica.ecs.soton.ac.uk/code/doc/ReadMe.html)
#
#  The code is relatively unchanged, except to bring into compliance
#  with the ParaCite metadata style, and to allow interoperability with
#  the other parsers.
#
#  Copyright (c) 2002 University of Southampton, UK. SO17 1BJ.
#
#  ParaTools is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  ParaTools is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with ParaTools; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
######################################################################

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&normalisation &normalise_html &normalise_name 
             &normalise_date &normalise_journal &num_of_figures);

$VERSION = '0.01';

#
# Normalisation utilities
#
sub normalisation {
        my($Text) = @_;
        # replace embedded '\n' with ' '
	$Text =~ s/^\s+//s;
	$Text =~ s/\s+$//s;
	$Text =~ s/\s+/ /g; # Use single space
#        while ($Text =~ /.+?\n.+?/g) {
#               $Text =~ s/(.+?)\n(.+?)/$1 $2/
#               };
	$Text =~ s/``(.*?)''/"$1"/sg; # Replace ``A Paper Title'' with "A Paper Title"

        $Text =~ s/\s*-\s*/-/g; # remove space around '-'
        $Text =~ s/\s*'\s*/'/g; # remove space around '
        $Text =~ s/\s*:\s*/:/g; # remove space around :
        $Text =~ s/\(\s+/\(/g;  # ( 1998) ==> (1998)
        $Text =~ s/\s+\)/\)/g;  # (1998 ) ==> (1998)
 #       while ($Text =~/--/g) {$Text =~ s/--/-/}; # use single '-'.
	$Text =~ s/--+/-/g;
        $Text =~ s/~//g;   # remove '~' (e.g. C.~B.~Hanna)
        $Text =~ s/[,;\s]+$//;    # remove last ',;\s' on a line
        # 'Nr.' caused error in 'find_jnl_name', i.e. it became as
        # 'journal name' if not removed. (see: arXiv:quant-ph/9905016)
        $Text =~ s/([,;])\s*Nr\.\s*(\d+[,;])/$1$2/i; 
        # "[12] For example, R. Machleidt, ...Phys. Rep. 149, 1 (1987)
        $Text =~ s/^([^a-z]+)for example\W+/$1/i;
        # '[18] *** G. Do Dang, ... (arXiv:nucl-th/9911081)
        $Text =~ s/\*+//g;
	# Phys. Rev. D56 => Phys. Rev. D. 56
	$Text =~ s/phys.{1,6}rev.{1,6}([a-z])(\d+)/PHYS. REV. $1 $2/ig;
	# Physica 34 D => Physic D 34
	$Text =~ s/physica\s+(\d+)\s+([a-z])/PHYSICA $2 $1/ig;
	# Nucl. Phys. B567 => Nucl. Phys. B
	$Text =~ s/nuc.{1,6}phys.{1,6}\s+([a-z])(\d+)/NUCL. PHYS. $1 $2/ig;
        return $Text;
        };
 
sub chr_valid {
	my $c = shift;
	if( $c < 128 || $c > 255 ) {
		return chr($c);
	} else {
		return ' ';
	}
}

sub normalise_html {
        my($Text) = @_;
 
	use utf8;

        # remove <BR> tag
        $Text =~ s/<BR>//ig;
	# Convert HTML entities to Unicode
	$Text =~ s/\&#x(\w+);/chr_valid(hex($1))/eg;
	$Text =~ s/\&#(\d+);/chr_valid($1)/eg;
        $Text =~ s/&(\w)acute[;,]/$1/g;   # a ' on top of (\w)
        $Text =~ s/&(\w)cedil[;,]/$1/g;   # a 'tail' under (\w), e.g Francios
        $Text =~ s/&(\w)grave[;,]/$1/g;    # a ` on top of (\w)
        $Text =~ s/&(\w)tilde[;,]/$1/g;
        $Text =~ s/&(\w)uml[;,]/$1e/g;   # a '..' on top of (\w)
        $Text =~ s/&(\w)slash[;,]/$1/g;
        #$Text =~ s/&#-88;(\w)/$1/g;   # as &(\w)uml (see astro-ph/9811179)
        $Text =~ s/&#-\d+;\s*(\w)/$1/g;
        $Text =~ s/&szlig[;,]/ss/g;       
        $Text =~ s/&amp[;,]/ and /g;
        $Text =~ s/&#20;\s*(\w)/$1/g;      # a ~ on top of (\w)
        $Text =~ s/\/?i&gt;//g;  # cogprints
        $Text =~ s/&[a-z]+;//g;  # otherwise ';' cause ref line break.
#       $Text =~ s/&#\d+;//g;    # e.g. '&#21' in 'hep-th/0001001 [99]'.
        $Text =~ s/\\"(\w)/$1e/g;  #  G\"unter => Gueter
 
        $Text =~ s/\^//g;  # remove ^
        $Text =~ s/([A-Z])\s*&\s*([A-Z])/$1 and $2/g;  # replace '&' with 'and'
        $Text =~ s/[, ]+& / and /;
        # remove HTML markups (<b></b><i></i> etc.)
        $Text =~ s/<[a-z\/]{1,3}>//ig;
        return $Text
}
 
 
sub normalise_name {
        my($Text) = @_;
        my $Suffix = '';
        $Text =~ s/~//;    # remove typo
        # Jr.
        if ($Text =~ s/[, \.]+(Jr|Sr|Snr)\.?\s*$//i){
                $Suffix = $1
                }
        elsif ($Text =~ s/([, \.]+)(Jr|Sr|Snr)[. ]/$1/i){
                $Suffix = $2
            };
 
        # van der Buren D => D van der Buren"
        if ($Text =~ /^\s*(((van|von|de|den|der)\s+)+)(\S\S+)\s+(.+)/i) {
                $Text = "$5 $1 $4"  
                };
        $Text =~ s/\s+/ /g; # single space
        $Text =~ s/^\W+//;
        $Text =~ s/\s+$//;
        # "A. Smith" => "A.Smith"
        $Text =~ s/([a-z])s+\./$1\./ig;
        # Ghisellini G. A. ==> G.A. Ghisellini
        # Konenkov D. Yu. => D.Yu. Konenkov
        if ($Text =~ /^([^\s.]{2,})\s+(([A-Z][a-zA-Z]?\W+)*)([A-Z][a-zA-Z]?)\W*$/) {
                $Text = "$2$4 $1"
                };
 
        $Text = "$Text $Suffix" if ($Suffix);
        $Text = tdb_normalise_name($Text);
        return $Text;
        };         

# Based on Tim's Authors::splitauthors and Authors::_cmonauthor();
# This subroutine is called simply because we want the author names
# to be transformed to a same style used by Tim's programs. Otherwise
# a join on author names in Publication and Reference tables will
# miss a lot of targets.
sub tdb_normalise_name{
        my $author = shift;
 
        # Strip any brackets
        $author =~ s/\s*\([^\)]*\)\s*//g;
        # Get rid of any dashes (except for dashes like Hu-Su)
        $author =~ s/(\W)-/$1/g;
        # Remove any "the"s, e.g. The OPAL Collaboration
        $author =~ s/\bthe\s+//ig;
        # Sort out Jr/Jr.
        $author =~ s/,?\sJr\.?/_Jr/ig;
 
        $author =~ s/[\{\}]//g; # Remove any specialisations
        $author =~ s/\\.//g;    # Remove any escapes
        # Convert Convert Hawking S. to S.Hawking (already done - zj)
        # ($author =~ /(\w\w+)\s+([\.\w\s]+\.)$/) && ($author = $2.$1);  
        $author =~ s/\.\s/\./g; # Convert S.W. Hawking to S.W.Hawking
        $author =~ s/([A-Z])\s/$1\./g; # Convert S W Hawking to S.W.Hawking
        ($author = lc($author)) && ($author =~ s/\b(\w)/\U$1/g);
                 # Convert STEPHEN_HAWKING to Stephen_Hawking
        $author =~ s/\s/_/g;  # Convert Stephen W.Hawking to Stephen_W.Hawking
        $author =~ s/\.\.+/\./g; # Remove double dots
        return $author;
}                       


sub normalise_date {
        my($Text) = @_;
 
        # 12-14 Dec.
        $Text =~ s/[^\w\/][0-3][0-9]?[a-z]*?(\s*\-\s*[0-3][0-9]?[a-z]*?)?\s+
                    (Jan[\.\s]|January\b|Feb[\.\s]|February\b|
                     Mar[\.\s]|March\b|Apr[\.\s]|April\b|May|
                     Jun[\.\s]|June\b|Jul[\.\s]|July\b|Aug[\.\s]|August\b|
                     Sep[\.\s]|September\b|Oct[\.\s]|October\b|
                     Nov[\.\s]|November\b|Dec[\.\s]|December\b)//xig;
 
        # Dec 12-14
        $Text =~ s/(Jan[\.\s]|January\b|Feb[\.\s]|February\b|
                    Mar[\.\s]|March\b|Apr[\.\s]|April\b|May|
                    Jun[\.\s]|June\b|Jul[\.\s]|July\b|Aug[\.\s]|August\b|
                    Sep[\.\s]|September\b|Oct[\.\s]|October\b|
                    Nov[\.\s]|November\b|Dec[\.\s]|December\b)
                    [^\w\/]*[0-3][0-9]?[a-z]*?(\s*\-\s*[0-3][0-9]?[a-z]*?)?\b//xig;
 
        return $Text;
        };
 
                    
sub normalise_journal {
        my($Text) = @_;
        $Text =~ s/^in\s+//i;  # "in ..."
        $Text =~ s/^(see )?also\s+//i;  # "also ...";
        $Text =~ s/\s*:\s*/:/g;
        $Text =~ s/\s\s/ /g;   # single space;
        $Text =~ s/\.\s/\./g;  # "J. Physics" => "J.Physics"
        $Text =~ s/\.\(/\. \(/g;
 
        $Text =~ s/^\W+//;
        $Text =~ s/[^\w.]+$//;
 
        # remove anything in brackets at the end.
        $Text =~ s/\s*\([^)]+$//;     # e.g. R. Ram, J. Phys. (Paris
        $Text =~ s/^[^(]+\)\s*//; # e.g. a) R. Ram, J. Phys. 10, 120, 1998
 
        # unify cases
        #($Text = lc($Text)) && ($Text =~ s/\b(\w)/\U$1/g);
        $Text = uc($Text);
        return $Text;
        };     


sub num_of_figures {
        my($Text) = @_;
        my($N, @Nlist);
        $N = 0;
        @Nlist =();
 
        $Text = normalisation($Text);
        # e.g. "p. 24-26" regarded as one number.
        # ignore 'N = 2' kind of equations, and
        # ignore '25th' kinds (e.g. Proc. 25th ICRC).
        # ignore 'protein Aquaporin-1 in ...'
        # ignore 'hep-th/9901001'
        # ignore ' ... 1.55, ...'
        while ($Text =~ /(?:^|\b)[a-z]*(\d+)([a-z]*)
                          (?:-[a-z]*\d+[a-z]*)*
                          (?:\b|$)/gix) {
                next if ($2 =~ /^th$/i);
                next if ($' =~ /^\.\d+/);
                next if ($` =~ /\d+\.$/);
                next if ($` =~ /[=<>\/-]\s*$/);
                push(@Nlist, $1);
                };
        $N = scalar(@Nlist);
        return $N
        }
 
 
sub remove_extra_spc {
        my($Text) = @_;
        $Text =~ s/^\s+//;
        $Text =~ s/\s+$//;
        $Text =~ s/\s\s+/ /g;
        return $Text
        };           

1;

__END__

=head1 NAME

ParaTools::Citation::Parser::Jiao::Utility - Perl module containing text processing subroutines.

=head1 SYNOPSIS

  use ParaTools::Citation::Parser::Jiao::Utility;

=head1 DESCRIPTION

This module is called by ParaTools::Citation::Parser::Jiao.pm.

=head1 AUTHOR  

Original Author:
Zhuoan Jiao <zj@ecs.soton.ac.uk>

=cut
