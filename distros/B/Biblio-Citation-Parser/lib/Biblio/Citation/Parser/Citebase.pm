package Biblio::Citation::Parser::Citebase;

######################################################################
#
# Biblio::Citation::Parser::CiteBase; 
#
######################################################################
#
#  This file is part of ParaCite Tools (http://paracite.eprints.org/developers/)
#
#  Copyright (c) 2004 University of Southampton, UK. SO17 1BJ.
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

=pod

=head1 NAME

Biblio::Citation::Parser::Citebase - Citebase's citation parsing module

=head1 DESCRIPTION

This module is an updated (and hopefully improved) version of Zhuoan Jiao's citation-parsing modules.

=head1 SYNOPSIS

	use Biblio::Citation::Parser::Citebase;
	$parser = new Biblio::Citation::Parser::Citebase([$source_identifier]);
	$metadata = $parser->parse($citation);
	print "Author: ", $metadata->{aufirst}, " ", $metadata->{aulast}, "\n";

=cut

use strict;
use utf8;
use Time::localtime; # optional, used by OpCit project.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Biblio::Citation::Parser::Jiao::Utility qw(normalisation normalise_html);
use Text::Unidecode; # Used so we can just use a-z to match lowercase letters

use Exporter;
@ISA = qw(Exporter);
 
@EXPORT = qw();
@EXPORT_OK = qw(&normalise_name &normalise_date
		&num_of_figures &print_out);
#@EXPORT_OK = qw(&normalise_name &normalisation &normalise_date
#		&normalise_html &num_of_figures &print_out);

=pod

=item $p = new Biblio::Citation::Parser::Citebase([$citation],[$source_identifier]);

Create a new citation parser, optionally parsing $citation with $source_identifier. If a citation is given the return blessed hash will contain the structured data.

=cut

sub new {
        my ($class,$citation,$sidentifier) = @_;
	$class = ref $class ? $class->{'_class'} : $class; # I'm sure there's a better way of doing this
	my $self;
	if( $citation ) {
		my %args = (
			_class=>$class,
			sourceID=>$sidentifier,
			text=>$citation,
			rest_text=>$citation,
		);
		@args{qw(
			aufull aulast aufirst auinit authors atitle
			title volume issue supl spage year targetURL
			rest_text date targetID featureID
			jnl_spos jnl_epos num_of_fig
		)} = ();
		$self = bless \%args, $class;
		$self->find_metadata();
		$self->find_featureID();

		# OpenURL mapping
		$self->{'id'} = $self->{'targetID'};
		$self->{'pages'} = $self->{'spage'};
	} else {
		$self = bless {_class=>$class}, $class;
	}
	return $self;
}

=pod

=item $md = $p->parse($citation, [$source_identifier]);

Parses a string, $citation, and returns a blessed hash of the structured data.

=cut

# This is a very nasty hack to allow this method
sub parse { new(@_) }

sub initialize {
        my $cite = shift;
	my $text = shift || die "Requires citation text to parse";
	my $sidentifier = shift;

        $cite->{'text'}   = $text;
        $cite->{'aufull'} = undef;
        $cite->{'aulast'} = undef;
        $cite->{'aufirst'}= undef;
        $cite->{'auinit'} = undef;
	$cite->{'authors'}= undef;
        $cite->{'atitle'} = undef;
        $cite->{'title'} = undef;
        $cite->{'volume'} = undef;
        $cite->{'issue'}  = undef;
	$cite->{'supl'}	= undef;
        $cite->{'spage'}  = undef;
        $cite->{'year'}   = undef;
	$cite->{'targetURL'}  = undef;

	$cite->{'rest_text'} = $text; 	
	$cite->{'date'}      = undef;
	$cite->{'sourceID'}  = $sidentifier;
	$cite->{'targetID'}  = undef;
	$cite->{'featureID'} = undef;	
	$cite->{'jnl_spos'}  = undef;
	$cite->{'jnl_epos'}  = undef;
	$cite->{'num_of_fig'}= undef;

	$cite->find_metadata();
	$cite->find_featureID();

	# OpenURL mapping
	$cite->{'id'} = $cite->{'targetID'};
	$cite->{'pages'} = $cite->{'spage'};
}

#
# Actions 
#
sub pre_process {
	my $cite = shift;
	my $Text = shift || $cite->{'text'};

	$Text = normalisation($Text);
	$Text = normalise_date($Text);
	$Text = normalise_html($Text);
	# remove front label to get accurate $nFig 
	# (Note: do not perform this for arXiv ref. like: "46(4), 90 (1993)")
	# [Smith, 1998], [1], (1), (1a) ... 
	$Text =~ s/^\s*[\[(]\s*  # bracket
		   ([^\])]+?)\s* # content
	           [\])]\s*//x;  # bracket

	# "1. Gary Smith, ...." 
	$Text =~ s/^\d+\s*\.\s+//;
	# "1 Gary Smith, ...."
	$Text =~ s/^\s*\d+ ([A-Z])/$1/;
	# "2) Brand, P. ..."    
	$Text =~ s/^[\[\(]?\s*\w+\s*[\])]\s*//; 
 
	$cite->{'rest_text'} = $Text;

	my $nFig = num_of_figures($Text);
	$cite->{'num_of_fig'} = $nFig;	

	return $Text;
}

sub find_metadata {
	my $cite = shift;

	return 0 if (!defined($cite->{'text'}));

	my $Text = $cite->pre_process($cite->{'text'});

	$cite->{'targetID'} = $cite->complete_targetID($cite->find_targetID($cite->{'text'}));

	# find URL
        $cite->find_url();  

	my $nFig = $cite->{'num_of_fig'};

	# find the authors
	if ($cite->find_authors()) {
	      $cite->find_first_author()
	      };

	# find article titile
	$cite->find_atitle(); 

	# only process references to 'journal' articles.
        return 0 if ($nFig == 0) ; # no number, ignore.
        return 0 if ($nFig >= 8); # too many numbers, maybe an error, ignore.
        # return 0 if ($cite->{'rest_text'} =~ /\W(proc.|proceedings) of /i);    

	# extract 'supplement' first before find_vol_no_pg_year()
	$cite->find_supplement();

        if ($cite->find_vol_no_pg_year() or
            $cite->find_vol_pg_year()) {
 
                $cite->find_jnl_name();
                return 1
                };

	if ($cite->guess_vol_no_pg()) {
		$cite->find_jnl_name();
		return 1;
		};

        if ($cite->find_vol_no() or
            $cite->find_vol_supl()) {
 
                $cite->find_jnl_name();
                $cite->find_page();
                $cite->find_year();
 
                return 1;
                };

        if ($cite->guess_vol_pg()) {
		$cite->find_year(); 
                $cite->find_jnl_name();
 
                return 1;
                };
 
        if ($cite->guess_vol_year()) {

		$cite->find_page(); 
                $cite->find_jnl_name();
 
                return 1;
                };


	my $Count = 0; 
        $Count++ if ($cite->find_year());
        $Count++ if ($cite->find_vol());
	$Count++ if ($cite->find_issue());
	$Count++ if ($cite->find_supplement());
        $Count++ if ($cite->find_jnl_name());
        $Count++ if ($cite->find_page());
 
        return 1 if ($Count >=2 );

# Last-ditch get any three numbers
	$cite->three_figs if $nFig <= 4;

        # too few metadata 
        return 0
}

sub three_figs {
	my $self = shift;
	my $Text = $self->{'text'};

	# Remove the year
	return unless $Text =~ s/\(((?:19|20)\d{2})\)//;
	$self->{year} = $1;

	return unless $self->{year} or $Text =~ s/((?:19|20)\d{2})//;
	$self->{year} = $1;

	return unless $Text =~ s/(\d+)\s*-\s*[a-z]{0,2}(\d+)//i;
	$self->{spage} = $1;
	$self->{epage} = $2;

	return unless $` =~ /(\d+)\D+/;
	$self->{volume} = $1;

	return 1;
}

my @arXiv = qw(astro-ph cond-mat gr-qc hep-ex hep-lat hep-ph hep-th
		math-ph nucl-ex nucl-th physics quant-ph
		adap-org alg-geom chao-dyn chem-ph cmp-lg
		comp-gas cs dg-ga funct-an math mtrl-th
		neuro-cel neuro-dev neuro-sys nlin nlin-sys
		patt-sol plasm-ph q-alg solv-int supr-con
		math.AG math.AT math.AP math.CT math.CA math.CO math.CV
		math.DG math.DS math.FA math.GM math.GN math.GT
		math.GR math.HO math.KT math.LA math.LO math.MP
		math.MG math.NT math.NA math.OA math.OC math.PR math.QA
		math.RT math.RA math.SC math.SP math.SG);
my %subarXiv;
my $subarXivre = '';
foreach my $sa (@arXiv) {
	my $re = $sa;
	$re =~ s/(\W)/$1?/g;
	$subarXivre .= "(?:$re)|";
	$re =~ s/\W//g;
	$sa =~ s/^math(\.\w\w)/math/i; # Fix to make maths identifiers match
	$subarXiv{$re} = $sa;
}
chop($subarXivre);
$subarXivre = "($subarXivre)\\s*.\\s*(\\d{7})";

sub complete_targetID {
	my $self = shift;
	my $tid = shift || return;

	return $tid if $tid =~ /^oai:/;

	my $sid = $self->{'sourceID'};
	if( !defined($sid) && $tid =~ /^$subarXivre.*$/oi ) {
		my ($sa,$no) = ($1,$2);
		$sa =~ s/\W//g;
		return "oai:arXiv.org:".$subarXiv{$sa}."/".$no;
	}
	if( !$sid ) {
		warn "Warning: Unable to expand \"$tid\" as no sourceID given";
		return;
	}
	return unless ($sid =~ /oai\:([^\:]+)\:([^\:\/]+)/);
	my ($axv, $subaxv) = ($1,$2);

	$tid =~ s/.(\d{7})/\/$1/;
	if( $tid =~ /^[a-zA-Z]{2}/ && $tid =~ /^$subarXivre.*$/oi ) {
		my ($sa,$no) = ($1,$2);
		$sa =~ s/\W//g;
		return "oai:$axv:".$subarXiv{$sa}."/".$no; # normalise subarXiv component
	}
	if( $tid =~ /^\d/ ) {
		return "oai:$axv:$subaxv\/$tid";
	}
	return;
}

# Copied (mostly) from Parser::arXivCite
sub find_targetID {
	my ($self,$cite) = @_;

	# remove multiple spacing/tabs etc.
	$cite =~ s/\s+/ /sg;
	# remove space around '.' (math. DG => math.DB)
	$cite =~ s/\s*\.\s*/\./sg;

	# e.g. cond-mat/9910162
	if( $cite =~ /\b((?:\w+-\w+).\d{7})(?:v\d+)?\b/ && $1 =~ /($subarXivre)/oi ) {
		return $1;
	}

	# e.g. math.GB/9912001
	if( $cite =~ /\b((?:\w+\.\w+).\d{7})(?:v\d+)?\b/ && $1 =~ /($subarXivre)/oi ) {
		return $1;
	}

	# e.g. math/AG0206084, see oai:arXiv.org:math/0301128
	if( $cite =~ /\b((?:\w+\/\w\w)\d{7})(?:v\d+)?\b/ ) {
		my $id = $1;
		$id =~ s/(\w+)\/(\D+)/$1.$2\//;
		if( $id =~ /($subarXivre)/oi ) {
			return $1;
		}
	}

	# e.g. physics/9912001
	if( $cite =~ /\b((?:\w+).\d{7})(?:v\d+)?\b/ && $1 =~ /($subarXivre)/oi ) {
		return $1;
	}

	# e.g. 9912001
	if( $cite =~ /\b(\d{2})([01][0-9])(\d{3})\b/ ) {
		my ($year, $month, $i) = ($1,$2,$3);
		if( $year < 91 ) {
			$year += 2000;
		} else {
			$year += 1900;
		}
		my $cyear = localtime->year() + 1900;
		if( $month >= 1 && $month <= 12 && $year <= $cyear ) {
			return $1.$2.$3;
		}
	}

	return;
}

sub find_atitle {
	my $cite = shift;
	my $Text = $cite->{'rest_text'};
  
	# title is quoted.
	# return 0 if ($Text !~  /(['"])/); # 
	# my $Qt = $1;
	# ignore ' case, because author nams may contain ', e.g.
	#    A. I. L'vov, V. A. Petrun'kin, and M. Schumacher, 
        #    Phys. Rev. C 55, 359 (1997)
	return 0 if ($Text !~  /"/);

	if ($Text =~ /"(.+?)"\s*\.?/ and 
    	    word_count($1) >= 2) {
		my $Guess_title = $1;
		return 0 if ($Guess_title =~ /^http:/i);
	       
		$cite->{'atitle'} = $Guess_title;
		# use ';' !  
		# $Text =~ s/$Qt(.+?)$Qt\s*\.?/;/o;
		# $Text =~ s/"[^"]+"\s*\.?/;/;
		$Text =~ s/"[^"]+"/" "/;
		# $Text =~ s/[,;.]\s*[,;.]/,/g; # doesn't work
		while ($Text =~ /[,;.]\s*[,;.]/g) { 
			$Text =~ s/[,;.]\s*[,;.]/,/
			};	
		$Text =~ s/^[;" ]+//;
		$cite->{'rest_text'} = $Text;
		return 1
		};

	return 0
}

# for the OpCit Project .
sub find_featureID {
	my $cite = shift;

	my $featureID = '';
	$featureID .= "v$cite->{'volume'}" if ($cite->{'volume'});
	$featureID .= ":n$cite->{'issue'}" if ($cite->{'issue'});
	$featureID .= ":s$cite->{'supl'}"  if ($cite->{'supl'});
	$featureID .= ":p$cite->{'spage'}" if ($cite->{'spage'});
	$featureID .= ":y$cite->{'year'}"  if ($cite->{'year'});

	# tidy up
	# $featureID =~ s/:[nsp]\s*:/:/g; # doesn't work.
	while ($featureID =~ /:[nsp]\s*:/g) {
               $featureID =~ s/:[nsp]\s*:/:/
               };
	$featureID =~ s/^://;
	$featureID =~ s/\s+//g;

	my @Features = split(':', $featureID);

	# ignore those having too few metadata
	if (scalar(@Features) >= 2) {
		# standardize
		$featureID = lc($featureID);
		$cite->{'featureID'} = $featureID;
		};
	}

sub create_refID {
	my $cite = shift;
	my $refID;
        if ($cite->{'targetID'}) {
  	   $cite->{refID} = $cite->{'sourceID'}.':'.$cite->{'targetID'};
	   }
	elsif ($cite->{'featureID'}) {
	   $cite->{refID} = $cite->{'sourceID'}.':'.$cite->{'featureID'};	
	   };
	}

sub find_authors {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};
 
        my $aText = locate_authors($Text);
        return 0 if ($aText eq '' or $aText =~ /^\W+$/);
 
        my @Chunks  = ();
        @Chunks = split(/\s*[,;:\&]\s*/, $aText);
 
        # ignore text longer than 4 words (don't count initials)
        return 0 if (word_count($Chunks[0])>4 and no_initials($Chunks[0])); 
		
	my($author, $Authors) = ('','');
        while (@Chunks) { 
            if (scalar(@Chunks)==1) {
                    last if !full_name($Chunks[0]);
                    $author = normalise_name($Chunks[0]); 
		    $Authors = "$Authors:$author";
                    last   
		    };
 

            # (1) forename and surname are not separated by [,;].
	    if (full_name($Chunks[0])){
                if ($Chunks[1] =~ /^\s*Jr\.?\s*$/i) {
                        $author = "$Chunks[0], $Chunks[1]";
                        $author = normalise_name($author);
                        $Authors = "$Authors:$author";
                        splice(@Chunks, 0, 2); # remove the first two
                        next
                        }
                elsif (!only_initials($Chunks[1])) {
                        $author = normalise_name($Chunks[0]);
                        $Authors = "$Authors:$author";
                        shift(@Chunks);
                        next
                        }
                }
	    elsif (full_name($Chunks[1])) {
			# $Chunks[0] is not a name, skip. 
			shift @Chunks;
			next 
		};

            # (2) forename and surname are separated by [,;].
            # Ignore text containing too many words.
            my $aFull = "$Chunks[0] $Chunks[1]";
	    my @abbr = ();
            last if (word_count($aFull) > 4);
	    last if ($aFull =~ /[\d\/]+/);
	    
	    # journal title maybe mixed up with the name 
	    last if (@abbr = ($aFull =~ /\w\w\./g) and (@abbr >= 2)); 

            # surname first.
	    # "Oemler, A., Jr.  and  Lynds, C. R. 1975, ApJ, 199, 558"
	    if (scalar(@Chunks) > 2) {
                if (is_surname($Chunks[0]) and
                    has_initials($Chunks[1]) and
		    $Chunks[2] =~ /^\s*Jr\.?\s*$/i) {
                        $author = "$Chunks[1] $Chunks[0], Jr";
                        $author = normalise_name($author);
                        $Authors = "$Authors:$author";
                        splice(@Chunks, 0, 3); # remove the first three 
                        next
                        };
		};

	    # surname first
	    # "Reisenegger, A.  and  Miralda-Escude, J. 1995, ApJ, 449, 476 
            if (is_surname($Chunks[0]) and
                has_initials($Chunks[1])) {
		    if ($Chunks[1] =~ /(.+?\.?)\s*Jr\.?\s*$/i){
                        $author = "$1 $Chunks[0], Jr";
		        }
		    else 
		       {
			$author = "$Chunks[1] $Chunks[0]"; 
			};
                    $author = normalise_name($author);
                    $Authors = "$Authors:$author";
                    splice(@Chunks, 0, 2); # remove the first two
                    next
                    };
 
            # forename first
            if (only_initials($Chunks[0]) and
                is_surname($Chunks[1])) { 
                    if ($Chunks[0] =~ /(.+?[. ])\s*Jr\.?\s*$/i){
                        $author = "$1 $Chunks[1], Jr";
                        }
                    else
                       {
                        $author = $aFull 
                        };                                      
                    $author = normalise_name($author);
                    $Authors = "$Authors:$author";
                    splice(@Chunks, 0, 2); # remove the first two
                    next
                    };
 
            #  'Liu, Gong', hard to tell which is the surname;
            if (no_initials($Chunks[0]) and
                no_initials($Chunks[1])) {
                    if (word_count($aFull) <= 4 ) {
                            $author = normalise_name($aFull);
                            $Authors = "$Authors:$author";
                            splice(@Chunks, 0, 2); # remove the first two
                            next
                            }
            };
 
            # cannot determin the author name
            last 
 
            }; # end of while
	
	return 0 if ($Authors eq '');
	$Authors =~ s/^://;	
	$cite->{'authors'} = $Authors;
        } 

sub find_first_author {
	my $cite = shift;
	
	return 0 if (!defined($cite->{'authors'}));

	my ($author) = split(':', $cite->{'authors'}, 2);
	$cite->{'aufull'} = $author;
	if( $author =~ /(.*)[\s\._]([^\s\.]+)/ ) {
		$cite->{'aulast'} = $2;
		$cite->{'aufirst'} = $1;
	}
}

# locate_authors 
sub locate_authors {
	my $Text = shift;

	$Text =~ s/^\s*For .*?review(s)?\W+//i;
	$Text =~ s/^\s*(see )?also //i;
	$Text =~ s/^\s*see[, ]\s*for example\W+//i;
	$Text =~ s/^\s*see e\.g\.\W+//i;
	my $aText = $Text;

        # author name(s) is assumed to be in front of a consecutive
        # 4 words, e.g. J. A. Harvey. String Duality and Non-supersymmetric
        # Strings.
	# if ($Text =~ /\b([\w\-'`"]+\s+){3,}[\w\-'"]+\b/){
	if ($Text =~ /\.\s+([\w\-'`"]+\s+){3,}[\w\-'"]{2,}\b/){ 
                $aText = $`;
                };

	if ($Text =~ /[,;]\s*([\w\-'`"]{2,}\s+){3,}[\w\-'"]{2,}\b/) {
		$aText = $`;	
		};
	# the above has truncated too much.
	# "S. Popescu and Sudbery G. A. Multi-particle entanglement ..."
	if (only_initials($aText)) {
		$aText = $Text
		};

	if ($aText =~ /[,:; ]\s*[a-z][\w\-'"]*\s+([a-z0-9\-'"]+\s+)*?[a-z0-9\-'"]{4,}(\b|$)/) { # "[6] M.Gotay, Constraints, reduction and quantization, 
		   # J. Math. Phys. (1986) 2051.
                $aText = $`;
                };
 
	# Or before the following sybmols.
        # if ($aText =~ /["\[\(]/) {
	if ($aText =~ /[:"\[\(]/) {
                $aText = $`
                };


	# before '/', e.g. "Halzen F. astro-ph/0001001"
	if ($aText =~ /\S+\//) {
		$aText = $` 
		};

	# before any number
	if ($aText =~ /\d+/i) {
		$aText = $`
		};

	# "14. A. J. Leggett, in Percolation, Localization and ..."
	# or "M. Göckeler, et al., hep-lat/9608033."
	if ($aText =~ /[,;: ]\s*(?:in )|(?:et\.?\s+al\.?\b)/i) {
		$aText = $`
		};

	# last author name after 'and'.
	if ($aText =~ /[,; ]\s*and ([^,;:]+)[,:;]([^,;:]+)/i) {
	    my $Aft1 = $1;
	    my $Aft2 = $2;
	    if (full_name($Aft1)) {
		$aText = $` .", $Aft1";
		} else {
		$aText = $` .", $Aft1, $Aft2"
		}
	    };

	# 
        # tidy up 
	#
	# remove non-alphabets 
	$aText =~ s/^[^a-z]+//i;
	$aText =~ s/^by //i;
	$aText =~ s/[,; ]+and /,/i;
	$aText =~ s/[,; ]+et\.?\s+al\.?([,; ]+|$)/, et al,/i;
	$aText =~ s/[,;:.]+\s*$//;
        return $aText
        };  

# This subroutine needs re-written; not in use now. 
sub locate_book {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};
 
        if ($Text =~ /\W+in\s+(.+?)\W+(ed|eds|edited)\.?(\W|$)/) {
                $$cite{book} = $1;
                return 1
                };
        return 0
 
        }  

sub find_vol_no {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};
 
        if  ($Text =~ s/[,;. ]\s*(?:volume|vol|v)?\.?\s*(\d+)\s*[ ,;]\s*(?:n|no|issue|\#)\.?\s*(\d+)\b/$1/is) {
 
                $cite->{'volume'} = $2;
                $cite->{'issue'}  = $3;
                $cite->{'jnl_epos'} = length($`);
                $cite->{'rest_text'} = $Text;
                return 1
                }
        else { return 0}
        }

sub find_vol_supl {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};
 
        if  ($Text =~ s/(\s|,|;|\.)\s*(?:volume|vol|v)?\.?\s*(\d+)\s*[\s,;]\s*(?:supl|supplement)\.?\s*(\d+)\b/$1/is) {
 
                $cite->{'volume'} = $2;
                $cite->{'supl'}  = $3;
                $cite->{'jnl_epos'} = length($`);
                $cite->{'rest_text'} = $Text;
                }
        }


sub find_vol {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};

        if ($Text =~ s/[,;:\. ]\s*(?:volume|vol)[\. ]\s*([a-z]*\d+[a-z]*)\b//i) {
                $cite->{'volume'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };      

	# "..., Vol9 ..."
        if ($Text =~ s/[,;:\. ]\s*(?:volume|vol)(\d+[a-z]*)\b//i) {
                $cite->{'volume'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };                                                              

	if ($Text =~ s/[,;:\. ]\s*(?:volume|vol)(\d+[a-z]*)\b//i) {
		$cite->{'volume'} = $1;
		$cite->{'rest_text'} = $Text; 
		return
		};

	# beware: "Smith, V. 1990, Phys. Rev. A. v. 10 ..."
	while ($Text =~ /[,;\. ]\s*V\s*[\. ]\s*([a-z]*\d+[a-z]*)\b/ig){
		my $Guess_vol = $1;
		next if ($Guess_vol =~ /(19|20)\d\d/);

		$cite->{'volume'} = $Guess_vol;
		$Text =~ s/[,;\. ]\s*V\s*[\. ]\s*[a-z]*\d+[a-z]\b//i;
		$cite->{'rest_text'} = $Text;
		return  
		};

	# "... v10, ..."
        if ($Text =~ s/[,;:\. ]\s*V(\d+[a-z]*)\b//i) {
                $cite->{'volume'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };                                                              
        } 

sub find_issue {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};

	if ($Text =~ s/[,;:. ]\s*(?:number|issue|num|no|Nr|\#)[. ]\s*([a-z]*\d+[a-z]*)\b//i) {
		$cite->{'issue'} = $1;
		$cite->{'rest_text'} = $Text; 
		return
                };

	# e.g. " ...No10, ..."
	if ($Text =~ s/[,;:. ]\s*(?:number|issue|num|no|Nr)(\d+[a-z]*)\b//i) {
		$cite->{'issue'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };    

	while ($Text =~ /[,;:. ]\s*N\s*[. ]\s*([a-z]*\d+[a-z]*)\b/ig){ 
		my $Guess_issue = $1;
		next if ($Guess_issue =~ /(19|20)\d\d/); 

		$cite->{'issue'} = $Guess_issue;
		$Text =~ s/[,;. ]\s*N\s*[. ]\s*[a-z]*\d+[a-z]*\b//i;
		return
		};

	        if ($Text =~ s/[,;:. ]\s*(?:n|\#|\#\s+)(\d+[a-z]*)\b//i) {
                $cite->{'issue'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };
                         

}

sub find_supplement {
	my $cite = shift; 
	my $Text = $cite->{'rest_text'};

	if ($Text =~ s/[,;:. ]\s*(?:suppl|supplement)\.?\s*(\d+)\b//i) {
		$cite->{'supl'} = $1;
		$cite->{'num_of_fig'} = $cite->{'num_of_fig'} - 1;
		$cite->{'rest_text'} = $Text
		}
	}


sub find_url {
	my $cite = shift;
	my $Text = $cite->{'rest_text'};

	if ($Text =~ s/\b(http:\/\/[^\s]+)['"]>/ /i){
		$cite->{'targetURL'} = $1;
		$cite->{'rest_text'} = $Text;
		return 1
		};

	if ($Text =~ s/\b(http:\/\/[^\s>]+)(?:\s|$)/ /i){
                $cite->{'targetURL'} = $1;
                $cite->{'targetURL'} =~ s/[.,;]$//;
                $cite->{'rest_text'} = $Text;
		return 1
		};

	return 0
	}

sub find_page {
        my $cite = shift;
        my $Text = $cite->{'rest_text'};

	# keep the order of the pattern matching.

	# '... p.20, p 20, ...'
        if ($Text =~ s/[,;:. ]\s*(?:pages|page|pp)\s*[.# ]\s*([a-z]*\d+[a-z]*)\b//i) {
                $cite->{'spage'} = $1;
                $cite->{'rest_text'} = $Text;
		return
                };

	# " ... pp20, ..." 
        if ($Text =~ s/[,;:. ]\s*(?:pages|page|pp)(\d+[a-z]*)\b//i) {
                $cite->{'spage'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };                                                              

	# ... p. 1990-1993
        if  ($Text =~ s/[,;. ]\s*(?:p)\s*[. ]\s*
                     ([a-z]*\d+[a-z]*)\s*\-\s*[a-z]*d+[a-z]*\b//xi) {
	
		$cite->{'spage'} = $1; 
        	$cite->{'rest_text'} = $Text;        
		return
                };     

	# Beaware "Smith P. 1990, ..., p. 100"
	while ($Text =~ /[,;. ]\s*p\s*[. ]\s*([a-z]*\d+[a-z]*)\s*(?!\-)/ig){
		my $Guess_page = $1;
		next if ($Guess_page =~ /(19|20)\d\d/);

		$cite->{'spage'} = $Guess_page;
		$Text =~ s/[,;. ]\s*p\s*[. ]\s*[a-z]*\d+[a-z]*\s*(?!\-)//i;
		$cite->{'rest_text'} = $Text;
		return
		};

        # " ... p20, ..."
        if ($Text =~ s/[,;:. ]\s*p(\d+[a-z]*)\b//i) {
                $cite->{'spage'} = $1;
                $cite->{'rest_text'} = $Text;
                return
                };                                                              
        }


sub find_year {
        my $cite = shift;
 
        return 1 if ($cite->{'year'});
 
        my $Text = $cite->{'rest_text'};
 
        # priority is given to (1989) type.
        if ($Text =~ s/\(((19|20)\d\d)\w?\)//) {
                $cite->{'year'} = $1;
                $cite->{'rest_text'} = $Text;
                return 1
                };
 
        # year like numbers not before/after a '-'
        # e.g. 1966-1988 may indicate a page range.
        if ($Text =~ /[^\w\-"]((19|20)\d\d)\w?([^\w\-"]|$)/i) {
 
                $cite->{'year'} = $1;
                $Text =~ "\Q$` $'\E";
                $cite->{'rest_text'} = $Text;
                return 1
                };
 
        return 0;
        }

# Apt'e, C., et al. ACM Transactions on Information Systems 12, 3, 233-251
sub guess_vol_no_pg {
	my $cite = shift;
        return 1 if ($cite->{'volume'} and $cite->{'issue'} and
                     $cite->{'spage'});
        return 0 if ($cite->{'num_of_fig'} < 3);

	my $Text = $cite->{'rest_text'};

        # change (1,1) alike to ().
        $Text =~ s/\(\d+\s*,\s*\d+\s*\)/\(\)/g;        
	$Text =~ s/\(\d+\s*;\s*\d+\s*\)/\(\)/g;

        if ($Text =~
          /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?) # volume
           [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
           [^\w\/.-]+(?:pages|page|pp|p)?\.?
                \s*([a-z]*?\d+[a-z]*?)(?:\s*-\s*[a-z]*?\d+[a-z]*?)?
              (\W*|$)/xi) {
 
                $cite->{'volume'} = $1;
                $cite->{'issue'}  = $2;
                $cite->{'spage'}  = $3;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1  
	};

	return 0

}


# '15:190' (15A:190-195, 14-15:190-180, or "Astrophys. J. 8, 103");
# Called this after '{find_vol_{no}_pg_year}' failed.
sub guess_vol_pg {
        my $cite = shift;
        return 1 if ($cite->{'volume'} and $cite->{'spage'});
        return 0 if ($cite->{'num_of_fig'} < 2);
 
        my $Text = $cite->{'rest_text'};

        # change (1,1) alike to ().
        $Text =~ s/\(\d+\s*,\s*\d+\s*\)/\(\)/g;
        $Text =~ s/\(\d+\s*;\s*\d+\s*\)/\(\)/g;    

        # 15A:190-195 type
        if ($Text =~ s/[^\w\/.-]([a-z]*?\d+[a-z]*?)\s*:\s*([a-z]*?\d+[a-z]*?)\s*
                      (-\s*[a-z]*?\d+[a-z]*?)?(\W|$)/$4/xi) {
                $cite->{'volume'}  = $1;
                $cite->{'spage'} = $2;
                $cite->{'jnl_epos'} = length($`) + 1;

                $cite->{'rest_text'} = $Text;
                return 1
                };

	# Astrophys. J. Lett., 452, p.L91-L93
	# AIP, vol 307, p.117, New York (1994). 
	# Pub. Astron. Soc. Japan, 2000,  p.52  
        if ($Text =~ 
                 /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?) # volume
                 [^\w\/.-]*,\s*(?:p|pp|page|pages)[. ]\s*([a-z]*?\d+[a-z]*?)\s*
                 (-\s*[a-z]*?\d+[a-z]*?)?(?:\W|$)/xi) {

		my $Guess_vol = $1;
		$cite->{'spage'} = $2;
		my $Guess_jnl_epos = length($`) + 1; # prematch
 
		if ($Guess_vol =~ /^(19|20)\d\d[a-z]?$/i) {
			$cite->{'year'}   = $Guess_vol;
			$cite->{'rest_text'} =~
			  s/([^\w\/.-])(?:volume|vol\.?|v\.?)?\s*[a-z]*?\d+[a-z]*?\s*,\s*(?:p|pp|page|pages)\s*\.?[a-z]*?\d+[a-z]*?\s*(-\s*[a-z]*?\d+[a-z]*?)?(\W|$)/$1/i;
			return 0
			};
                $cite->{'volume'} = $Guess_vol;
		$cite->{'jnl_epos'} = $Guess_jnl_epos;
		$cite->{'rest_text'} =~
                       s/([^\w\/.-])[a-z]*?\d+[a-z]*?\s*,\s*(?:p|pp|page|pages)\s*\.?[a-z]*?\d+[a-z]*?\s*(-\s*[a-z]*?\d+[a-z]*?)?(\W|$)/$1/i;
                return 1
                };

	# Elias, J. 1994, NOAO Newsletter, No. 37, 1 
        if ($Text =~
                 /[^\w\/.-](?:n|no|num|issue)[. ]\s*([a-z]*?\d+[a-z]*?) # volume
                 [^\w\/.-]*,\s*(?:p|pp|page|pages)?\.?\s*([a-z]*?\d+[a-z]*?)\s*
                 (-\s*[a-z]*?\d+[a-z]*?)?(?:\W|$)/xi) {
 
                $cite->{'issue'} = $1;
                $cite->{'spage'} = $2;
                $cite->{'jnl_epos'} = length($`) + 1; # prematch           
		$cite->{'rest_text'} =~
		     s/([^\w\/.-])(?:n|no|num|issue)[. ]\s*[a-z]*?\d+[a-z]*?[^\w\/.-]*,\s*(?:p|pp|page|pages)?\.?\s*([a-z]*?\d+[a-z]*?)\s*(-\s*[a-z]*?\d+[a-z]*?)?(?:\W|$)/$1/i;
		return 1
		};

	# match page range.
	# Phys. Rev. A 4, 52-60 
	# Pub. Astron. Soc. Japan, 1998, 52-60
        if ($Text =~ /[^\w\/.-]([a-z]*?\d+[a-z]*?)     # volume or year
                      [^\w\/.-]*[, ]\s*([a-z]*?\d+[a-z]*?)\s*	    # pages
                      -\s*[a-z]*?\d+[a-z]*?(?:[^\w-]|$)/xi) {

                my $Guess_vol  = $1;
                $cite->{'spage'} = $2;
                my $Guess_jnl_epos = length($`) + 1; # prematch
		    
                if ($Guess_vol =~ /^(19|20)\d\d[a-z]?$/i) {
                        $cite->{'year'}   = $Guess_vol;
			$cite->{'rest_text'} =~
			  s/([^\w\/.-])[a-z]*?\d+[a-z]*?\s*[, ]\s*([a-z]*?\d+[a-z]*?)\s*-\s*[a-z]*?\d+[a-z]*?(?:[^\w\/.-]|$)/$1/i;
			return 0
			};
                $cite->{'volume'} = $Guess_vol;
		$cite->{'jnl_epos'} = $Guess_jnl_epos;
                $cite->{'rest_text'} =~ s/([^\w\/.-])[a-z]*?\d+[a-z]*?\s*,\s*([a-z]*?\d+[a-z]*?)\s*-\s*[a-z]*?\d+[a-z]*?(?:[^\w\/.-]|$)/$1/i;

                return 1
                }; 

	# Phys. Rev. B 38, 2297. (Phys. Rev. B 38 2297) 
	# Pub. Astron. Soc. Japan, 2000, 52.
        if ($Text =~ /[^\w\/.-]([a-uw-z]*?\d+[a-z]*?)
              [^\w\/.-]*[, ]\s*([a-z]?\d+[a-z]?)(?:[^\w\/.-]|$)/xi) {

		my $Guess_vol  = $1; 
		my $Guess_page = $2;
                $cite->{'jnl_epos'} = length($`) + 1;

                if ($Guess_vol =~ /^(19|20)\d\d[a-z]?$/i) {
                        $cite->{'year'}   = $Guess_vol;
                } else {
                        $cite->{'volume'} = $Guess_vol;
                };

                if ($Guess_page =~ /^(19|20)\d\d[a-z]?$/i) {
                        $cite->{'year'} = $Guess_page;
                } else {
                        $cite->{'spage'} = $Guess_page;
                };
                 
                $cite->{'rest_text'} =~
                    s/([^\w\/.-])[a-z]*?\d+[a-z]*?[^\w\/.-]*[, ]\s*[a-z]*?\d+[a-z]*?(?:[^\w\/.-]|$)/$1/i;
		return 1 if ($cite->{'volume'} and $cite->{'spage'});
                return 0 
                };
 
        return 0
        }; 

#
# G. Smith and H. Gray; Pub. Astron. Soc. Japan, 2000, vol. 52
# To find $cite->{'jnl_epos'} currectly. Note that '2000' may be
# regarded as the journal name (by subroutine find_vol).
sub guess_vol_year {
        my $cite = shift;
        return 0 if ($cite->{'num_of_fig'} < 2);
 
        my $Text = $cite->{'rest_text'};

        # change (1,1) alike to ().
        $Text =~ s/\(\d+\s*,\s*\d+\s*\)/\(\)/g;
        $Text =~ s/\(\d+\s*;\s*\d+\s*\)/\(\)/g;    
 
        if ($Text =~
             /[^\w\/.-]\(?((19|20)\d\d)\w?\)?[^\w\/.-]*
             (?:volume|vol|v)\W*([a-oq-z]*?\d+[a-z]*?)(\W|$)/xis) {
 
                $cite->{'year'} = $1;
                $cite->{'volume'}  = $3;
                $cite->{'jnl_epos'} = length($`);
 
                return 1
                };  

	# be aware: "Workshop on ..., p30 (1999)."
	if ($Text =~
	     /[^\w\/.-](?:volume|vol|v)?\W*([a-oq-z]?\d+[a-z]?)
	      [^\w\/.-]+\(?((19|20)\d\d)\w?\)?(\W|$)/xis) {
		$cite->{'volume'} = $1;
		$cite->{'year'}   = $2;
		$cite->{'jnl_epos'} = length($`);

		return 1
		};
	       
        return 0
        };
 
sub find_vol_no_pg_year {
        my $cite = shift;
        return 1 if ($cite->{'volume'} and $cite->{'issue'} and
                     $cite->{'spage'} and $cite->{'year'});
        return 0 if ($cite->{'num_of_fig'} < 4);
 
        my $Text = $cite->{'rest_text'};

        # change (1,1) alike to ().
        $Text =~ s/\(\d+\s*,\s*\d+\s*\)/\(\)/g;
        $Text =~ s/\(\d+\s*;\s*\d+\s*\)/\(\)/g;    

        # Keep the following order of texting $Text;
        # Important: check 'year' at the end first.
 
        # (A.1):
        # 'year' is at the end, within bracket.
        # ..., v.517, no. 1, p.190-200, (1999)
        # ..., 11(2), 100-105, (1999) 
        if ($Text =~
	  /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?) # volume
           [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
           [^\w\/.-]+(?:pages|page|pp|p)?\.?
                \s*([a-z]*?\d+[a-z]*?)(?:\s*-\s*[a-z]*?\d+[a-z]*?)?
              \W*\(((19|20)\d\d)[a-z]*?\)(\W|$)/xi) {
 
                $cite->{'volume'} = $1;
		$cite->{'issue'}  = $2;
                $cite->{'spage'}  = $3;
                $cite->{'year'}   = $4;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
            };
 
        # (A.2) 'year' is in the middle, within bracket.
        #  ..., 4(2), (1999), 100-105
        if ($Text =~
          /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?)   # volume
           [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
           \W*\(((19|20)\d\d)[a-z]*?\)                           # year
              \W*(?:pages|page|pp|p)?\.?\s*([a-z]*?\d+[a-z]*?)(\W|$)/xi) {
 
                $cite->{'volume'} = $1;
		$cite->{'issue'}  = $2;
                $cite->{'year'}   = $3;
                $cite->{'spage'}  = $5;
                $cite->{'jnl_epos'} = length($`) + 1;

                return 1
                };
 
        # (A.3.1) 'year' is at the beginning, within bracket, after
	# journal title;
        # ...., (1999), 517, no. 1, p.190-200
        if ($Text =~
	  /\(((19|20)\d\d)[a-z]*?\)[,.;\s:]*            # year
           (?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]*?\d+[a-z]*?)(\W|$)/ix)
        {
                $cite->{'year'}   = $1;
                $cite->{'volume'} = $3;
                $cite->{'issue'}  = $4;
                $cite->{'spage'}  = $5;
		$cite->{'jnl_epos'} = length($`);

                return 1;
                };

        # (A.3.2) 'year' is at the beginning, within bracket, before
	# journal title;
        # ..., (1999),..., 517, no. 1, p.190-200
        if ($Text =~
          /\(((19|20)\d\d)[a-z]*?\)                   # year
	  ([^(]+?)
	  [^\w\/.-](?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
          [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
          [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]*?\d+[a-z]*?)(\W|$)/ix){
                $cite->{'year'}   = $1;
                $cite->{'volume'} = $4;
                $cite->{'issue'}  = $5;
                $cite->{'spage'}  = $6;

	#	$cite->{'jnl_spos'} = length($`);
	#	$cite->locate_jnl_epos();
		$cite->{'jnl_epos'} = length($`) + length($1) +
				      length($3);
                return 1;
                };  
 
 
        # (B.1):
        # 'year' is at the end, but not in bracket;
        # ..., v.517, no. 1, p.190-200, 1999
        # ...,   517, no. 1, p.190-200, 1999
        if ($Text =~
	  /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?)   # volume
           [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
           [^\w\/.-]+(?:pages|page|pp|p)?\.?
                \s*([a-z]*?\d+[a-z]*?)(?:\s*-\s*[a-z]*?\d+[a-z]*?)?
           [^\w(:\/.-]+?((19|20)\d\d)[a-z]?\s*(?![)-])/xi) { 
 
                $cite->{'volume'} = $1;
                $cite->{'issue'}  = $2;
                $cite->{'spage'}  = $3;
                $cite->{'year'}   = $4;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
                };
 
 
        # (B.2): 'year' is in the middle, but not in bracket.
        #  4(2), 1999, 100-105
        if ($Text =~
	  /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?)   # volume
           [^\w\/.-]+(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?) # issue
           [^\w(:\/.-]+?\s*((19|20)\d\d)[a-z]?                      # year
           \s*[^\w\/.)-]+?\s*(?:pages|page|pp|p)?\.?\s*([a-z]*?\d+[a-z]*?)(\W|$)/xi) {
 
                $cite->{'volume'} = $1;
                $cite->{'issue'}  = $2;
                $cite->{'year'}   = $3;
                $cite->{'spage'}  = $5;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
                };
 
        # (B.3.1): 'year' is at beginning, not in bracket, after title;
        # ..., 1999, v.517, no. 1, p.190-200
        #   " ... 1890-1999", MNRAS, 2000, 4:1, p 1990
        if ($Text =~
             /[^"(\/.-]\s*((19|20)\d\d)[a-z]?[,;\.\s]+     # year
              (?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume 
	       [^\w\/.-]+?(?:n|no|number|issue|\#)?\.?\s*([a-z]*?\d+[a-z]*?)
              [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]*?\d+[a-z]*?)(\W|$)/ix)
        {
                $cite->{'year'}   = $1;
                $cite->{'volume'} = $3;
		$cite->{'issue'}  = $4;
		$cite->{'spage'}  = $5;
		$cite->{'jnl_epos'} = length($`) + 1;
                return 1
                };
 
        # (B.3.2): 'year' is at beginning, not in bracket, before title;
        # 1999, ..., v.517, no. 1, p.190-200
        # 1999, ...,   517, no. 1, p.190-200
        # 1999, ..., 517(1), 190-200
        # NB: 1999, "... 1.5 factor ....", 517(1), 190-200
        # NB: B. Greene, editors, "Fields, Strings and Duality, TASI 1996",
        #     pages 421-540, World Scientific, 1997.
        #   " ... 1890-1999", MNRAS, 2000, 4:1, p 1990
        if ($Text =~
             /(?:^|[^"(\/.-])\s*((19|20)\d\d)[a-z]?     # year
	      [^\w:")(\/-][^(]*?
	      [^\w\/.-](?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
              [^\w\/.-]+?(?:n|no|number|issue|\#)?\.?\s*([a-z]?\d+[a-z]?)
              [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]*?\d+[a-z]*?)(\W|$)/ix)
        {
                $cite->{'year'}   = $1;
                $cite->{'volume'} = $3;
                $cite->{'issue'}  = $4;
                $cite->{'spage'}  = $5;

		$cite->{'jnl_spos'} = length($`);
		$cite->locate_jnl_epos(); 
                return 1
                }; 
        return 0
        };
            

# For cases where 'vol, page, year' can be identified correctly.
sub find_vol_pg_year {
        my $cite = shift;
        return 1 if ($cite->{'volume'} and $cite->{'spage'} and
                     $cite->{'year'});
        return 0 if ($cite->{'num_of_fig'} < 3);
 
        my $Text = $cite->{'rest_text'};

        # change (1,1) alike to ().
        $Text =~ s/\(\d+\s*,\s*\d+\s*\)/\(\)/g;
        $Text =~ s/\(\d+\s*;\s*\d+\s*\)/\(\)/g;    
 
        # (A.1) 'year' is at the end, within bracket.
        # ......, vol.8:100, (1999)
        # ......,     8:100, (1999)
        #                       ~~~~
        if ($Text =~
	   /(?:^|[^\w\/.-])(?:volume|vol\.?|v\.?)?\s*([a-z]*\d+[a-z]*) # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?
             \s*([a-z]?\d+[a-z]?)(?:\s*-\s*[a-z]?\d+[a-z]?)?
             \W*\(((19|20)\d\d)[a-z]?\)(\W|$)/xi) {
 
                $cite->{'volume'}  = $1;
                $cite->{'spage'} = $2;
                $cite->{'year'} = $3;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
                };
 
        # (A.2) 'year' is in the middle, within bracket.
        # ......, 8, (1999), 100-105
        if ($Text =~
          /(?:^|[^\w\/.-])(?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?) # volume
           \W*\(((19|20)\d\d)[a-z]?\)                  # year
             \W*(?:pages|page|pp|p)?\.? 
               \s*([a-z]?\d+[a-z]?)(?:\s*-\s*[a-z]?\d+[a-z]?)?(\W|$)/xi) {
 
                $cite->{'volume'}  = $1;
                $cite->{'year'} = $2;
                $cite->{'spage'} = $4;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
                }; 
 
        # (A.3.1.) 'year' is at beginning, within bracket, after title;
        # ......, (1999) 517, 190-200
        if ($Text =~
          /\(((19|20)\d\d)[a-z]?\)[,;\.\s]*       # year
           (?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/ix){
                $cite->{'year'} = $1;
                $cite->{'volume'} = $3;
                $cite->{'spage'}= $4;
		$cite->{'jnl_epos'} = length($`);
 
                return 1;
                };

        # (A.3.1.1) 'year' is at beginning, within bracket, after title;
        # not 'vol', buy 'No.@, e.g."..., (1999) No. 517, 190-200
        if ($Text =~
          /\(((19|20)\d\d)[a-z]?\)[,;\.\s]*       # year
           (?:number|no|n)\.?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/ix){
                $cite->{'year'} = $1;
                $cite->{'volume'} = $3;
                $cite->{'spage'}= $4;
                $cite->{'jnl_epos'} = length($`);
 
                return 1;
                };                                                              
 

        # (A.3.2.) 'year' is at beginning, within bracket, before title;
        # ..., (1999),..., 517, p.190-200
        if ($Text =~
          /\(((19|20)\d\d)[a-z]?\)        # year
           [^(]+?
           [^\w\/.-](?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/ix){
                $cite->{'year'}   = $1;
                $cite->{'volume'} = $3;
                $cite->{'spage'}  = $4;

		$cite->{'jnl_spos'} = length($`);
		$cite->locate_jnl_epos();
                return 1;
                };  

        # (B.1) 'year' is at the end, but not in bracket.
        # ......, vol.8:100, 1999
        # ......,     8:100, 1999
        # NB: ..., 1999, 8(1900)
        #                  ~~~~
        if ($Text =~
	  /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?) # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?
                \s*([a-z]?\d+[a-z]?)(?:\s*-\s*[a-z]?\d+[a-z]?)? # page
           [^\w:(\/.-]+\s*((19|20)\d\d)[a-z]?\s*(?![)-])/xi) {
 
                $cite->{'volume'}  = $1;
                $cite->{'spage'} = $2;
                $cite->{'year'} = $3;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
                };
 
        # (B.2) 'year' is in the middle, but not in brackets;
        # ... 8, 1999, p.100
        # ... 8, 1999, 100-105
        if ($Text =~
	  /[^\w\/.-](?:volume|vol\.?|v\.?)?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w:(\/.-]+?\s*((19|20)\d\d)[a-z]?                     # year   
           [^\w\/.)-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/xi)
        {
                $cite->{'volume'}  = $1;
                $cite->{'year'} = $2;
                $cite->{'spage'} = $4;
                $cite->{'jnl_epos'} = length($`) + 1;
 
                return 1
                };

        # (B.3.1) 'year' is at the beginning,not in bracket, after title;
        # ..., 1999, 8, p1990
        if ($Text =~
          /[^\w\/.(-]\s*((19|20)\d\d)[a-z]?[,;\.\s]+
           (?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/ix){
                $cite->{'year'}   = $1;
                $cite->{'volume'} = $3;
                $cite->{'spage'}  = $4;
                $cite->{'jnl_epos'} = length($`)+1;
                return 1
                }; 

        # (B.3.1.1) 'year' is at the beginning,not in bracket, after title;
        # no 'vol', but 'no.' e.g. ..., 1999, No. 8, p1990
        if ($Text =~
          /[^\w\/.(-]\s*((19|20)\d\d)[a-z]?[,;\.\s]+
           (?:number|no|n)\.?\s*([a-z]*?\d+[a-z]*?)  # no volume, but issues
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/ix){
                $cite->{'year'}   = $1;
                $cite->{'issue'} = $3;
                $cite->{'spage'}  = $4;
                $cite->{'jnl_epos'} = length($`)+1;
                return 1
                };                                                              

 
        # (B.3.2) 'year' is at beginning, not in bracket, before title;
        #  1999, ..., 8(100)
        if ($Text =~
	  /((^|[^"\/.(-])\s*)(((19|20)\d\d)[a-z]?)	       # year
	   ([^\w:")(\/][^(]*?)
           [^\w\/.-](?:volume|vol|v)?\.?\s*([a-z]*?\d+[a-z]*?)  # volume
           [^\w\/.-]+(?:pages|page|pp|p)?\.?\s*([a-z]?\d+[a-z]?)(\W|$)/ix){
                $cite->{'year'}   = $4;
                $cite->{'volume'} = $7;
                $cite->{'spage'}  = $8;
	
		# $cite->{'jnl_spos'} = length($`);	
		# $cite->locate_jnl_epos();
		$cite->{'jnl_epos'} = length($`) + length($1) + 
                                      length($3) + length($6);
                return 1
                };
 
        return 0
} 


# This subroutine is only called when the journal title is between
# 'year' and 'vol/page', e.g. (a lot in astro-ph/)
# Barnes, J., Efstathiou, G., 1987, ApJ, 319, 575
# For other cases, the cite{'jnl_epos'} is determined while trying to
# find out the vol, page, year, i.e. in 'find_vol_no_pg_year' kind
# of subroutines.
#
sub locate_jnl_epos {
 
        my $cite = shift;
	my $sPos = $cite->{'jnl_spos'};
        my $Text = substr($cite->{'rest_text'}, $sPos);
 
       # $Text =~ s/(\W+)(?:pages|page|pp|p)\W*(\d+)/$1$2/;
       # $Text =~ s/-\d+[a-z]*?//;  # pp100-105
 
        # Before 'volume'
        if ($Text =~ /\b(?:volume|vol\.?|v\.?)\s*[a-z]*?\d+[a-z]*?(?![.0-9])/i) {
                $cite->{'jnl_epos'} = length($`) + $sPos;
                return 1
                }; 

	# (1997) Phys. Rev. E56, No.3, 2875 
	# (1997) Phys. Rev. A50, p.160
	if ($Text =~ /
               [^\w\/.-](?:volume|vol\.?|v\.?)?\s*[a-z]*?\d+[a-z]*? # volume
               [^\w\/.-]+(?:n |n.|no |no.|number |issue |\#|p |p.|pp.|page )\s*[a-z]*?\d+[a-z]*?
               (?:\W|$)/xi) {
		$cite->{'jnl_epos'} = length($`) + $sPos + 1 ;
		return 1
		};

        # Before any two consecutive numbers, but not '123-127' style page.
        #   Bertelli, G., 1999, ApJ, 517(1), ....
        #   ApJ, 517:1, ...
        #   ApJ, 517:367-380.
        #Beaware: J.K. Lanyi. 1999. Structure of bacteriorhodopsin at 1.55
        #         angstrom resolution J. Mol. Bio. 291:899-911        ~~~~!
        if ($Text =~ /[^\w\/.-][a-z]*?\d+[a-z]*?\s*[,:(\s]\s*
                       [a-z]?\d+[a-z]?(\W|$)/xi) {
                $cite->{'jnl_epos'} = length($`) + $sPos + 1;
                return 1
                };
 
        return 0
        };


sub find_jnl_name {
        my $cite = shift;
 
        return 1 if ($cite->{'title'});
        return 0 if (! $cite->{'jnl_epos'});

        # Assumption: journal name usually starts after a ',;'
        # or " which is used to enclose the article title,
        # and does not contain those symbols (i.e. ,;")
        #
        my $Text = substr($cite->{'rest_text'}, 0, $cite->{'jnl_epos'});
	my $Guess_jnl;

	# Linden, N., et al. quantph/9711016 and Fortsch. Phys. 46, 567 (1998)
	#if ($Text =~ m{[^/]+/\w+\s*(.+)$}) {
	#	$Text = $1 
	#	};

   LOOP:
	# remove trailing symbols   
	$Text =~ s/\s*[,;":\/\[\(]*\s*$//s;  

	# ignore anything in brackets (head/tail position)
	$Text =~ s/\W*\([^\)]+\)?\W*$//;
	$Text =~ s/^\s*\([^\)]+\)\W+//;

	return 0 if ($Text eq '');

	# quite many citations are like this:
	# "P. Reiter, et al:Phys. Rev. Lett. 82 (1999) 509"
	# hard to separate name from journal title. Other cases
	# are: '..., J.PHY.G:NUCL.PART.PHY.'. Have to compramise.
	if ($Text =~ /([^,;":?\/\[]+)$/) {
                $Guess_jnl = $1;
		$Guess_jnl =~ s/^['`]?\s*//;
                $Guess_jnl =~ s/\s+$//; 

		# ignore things in brackets
		$Guess_jnl =~ s/\W*\([^\)]+\)?\W*$//;  
		$Guess_jnl =~ s/^\([^\)]+\)\W*//;

		# journal name should begin and contain alphabet, 
                # not only numbers; and should be longer than one
                # character. First remove 'year'
		$Guess_jnl =~ s/^.*?\(?(19|20)\d\d\w*\)?\W*//;
		if ($Guess_jnl =~ /^[a-z]\W*$/i) {
                        $Text =~ s/[^,;":?\/\[]+$//;
                        goto LOOP
                        };      

		# No captital letters
		if ($Guess_jnl !~ /[A-Z]/) {
			$Text =~ s/[^,;":?\/\[]+$//; 
			goto LOOP
			};

		# "Report of ... Conf.:1. Introduction. Canadian Medical Association Journal"
                if ($Guess_jnl !~ /^[a-z]+/i) {
			my @gWords = split(/\s+/, $Guess_jnl);

			if (scalar(@gWords) <= 3) { 
                        	$Text =~ s/[^,;":?\/]+$//;
                        	goto LOOP
				}
                        };

		$Text = $Guess_jnl;
		}
	else {
		$Text =~ s/^[`']?\s*//;
		$Text =~ s/\s*$//;

		# 'title' is after 'year' (other cases are dealt by
        	# $cite->{'jnl_epos'} in 'find_vol_{no}_pg_year()'..
        	if ($Text =~ /[,\s\(]+(19|20)\d\d[,\s\)]+\s*/) {
                	$Text = $'
                	};
		};
 
	my $end_dot = 0;
	$end_dot = 1 if ($Text =~ /\.$/);
        my @Title_words = ();
        my @Words = ();
	my $i = 0;

        # process from the end of the $Text to see if
        # a $Parts[$i] is (still) a part of a journal name.  
        my @Parts = split(/\s*\.\s*/, $Text);
        for ($i = $#Parts; $i>=0; $i--) {
		next if ($Parts[$i] !~ /[a-z]/i);

		# author name may be mixed into the journal title 
		# e.g. "Popescu S. and G. A. Sudbery. J. of Phy ..."
		if ($i > 0 and $Parts[$i-1] =~ /^([A-Z][a-z]* )*and\s+[A-Z]$/) {
			last 
		};
		if ($i > 1 and $Parts[$i-2] =~ /^([A-Z][a-z]* )*and\s+[A-Z]$/) {
			last if ($Parts[$i-1] =~ /^[A-Z]$/);
		};

		# author name may be mixed into the journal title
		# e.g. "and Sudbery A. Multi-particle ..."
		if ($i > 0 and $Parts[$i] =~ /^[A-Z]$/) {
			# less than 4 words.
			if ($Parts[$i-1] =~ /^\S+\s+\S+(\s+\S+){0,2}$/ and	
			    $Parts[$i-1] =~ /^(and )?[A-Z].+?[A-Z]$/){
				last
				}
			};

                push(@Title_words, $Parts[$i]);
		last if $i == 0;   # necessary test

		last if ($Parts[$i-1] =~ /et\s+al$/i);
		last if ($Parts[$i-1] =~ /^\s*\d+$/);

                @Words = split(/\s+/, $Parts[$i-1]);
		# stop if more than 4 words in $Parts[$i-1],
		# i.e. $Parts[$i-1] seems to contain article title,
		# not the journal name. However, be aware of:
		# "... method for propagating interfaces J. Comput. Phys." 
		# next if (scalar(@Words) <= 2 and
		next if (scalar(@Words) <= 2 and $Parts[$i-1] !~ /^\d/); 

		if (scalar(@Words) <= 4 and
		    $Parts[$i-1] =~ /^([A-Z][a-z]*\s+){0,3}[A-Z][a-z]*$/){
			next
			}; 
 
		my $w = pop(@Words);
		# if ($w =~ /^[A-Z]$/ or $w =~ /^[A-Z][a-z]+$/) {
		if ($w =~ /^J$/ or $w =~ /^[A-Z][a-z]+$/) {
			push(@Title_words, $w)
			};

		last
		};
        if (scalar(@Title_words) == 1) {
                $cite->{'title'} = $Title_words[0]
                }
        else {
                my @Title_words_real = reverse(@Title_words);
                $cite->{'title'} = join('.', @Title_words_real);
             };

	$cite->{'title'} = "$cite->{'title'}\." if ($end_dot == 1);
	 
        # normalise it
        $cite->{'title'} = normalise_journal($cite->{'title'});
        return 1
        };
           


sub full_name {
        my $Text = shift;

	$Text =~ s/(^|s*)Jr[. ]//i;

	return 1 if ($Text =~ /^\s*et al\s*$/i);

	return 0 if ($Text =~/^in /i);
	return 0 if ($Text !~ /[A-Z]/); # no upper case letter
	return 0 if ($Text =~ /\d+/); # $Text contains title.
	return 0 if ($Text =~ / (e-print|archive)s? /i);
	return 0 if ($Text =~ /\b(Collaboration|Review)\b/i);

	my $wCount = word_count($Text);
	return 0 if $wCount > 4;

	# "van Albada" or "van den Bergh" (surname only)
	return 0 if ($Text =~ /^((von|van|de|den|der)\s+)+\S\S+\s*$/i);
        # "van Buren D"
        return 1 if ($Text =~ /^(von|van|de|den|der)\s+\S\S+\s+([a-z]+\s*)+$/i);    
	# (journal name)
	return 0 if ($Text =~ /\b(Phy\.|Physics|Journal|The)\b/i);
	# "J. Mod. Phys. D";  "Prog.Theor.Phys."
	return 0 if ($Text =~ /^([a-z]+\.\s*)+[a-z]?\s*$/i);
	# "Phys Rev A"
	# return 0 if ($Text =~ /^([a-z][a-z]+(\.| )){2,}[a-z]\.?\s*$/i);
	my @Abbr = ();
	# "Class. Quantum Grav."
	return 0 if (@Abbr = ($Text =~ /\S\S+?\./g) and
		     scalar(@Abbr) >1);
	# "Nuovo Cim. B 44, 1 (1966)."
	return 0 if ($Text =~ /\w\w\w+\./);
	
	# 'W. B. Burton', 'Burton W. B.', 'W B Burton', etc.
	if (has_surname($Text) and
            has_initials($Text) and
	    $wCount >= 1 and
	    $wCount < 5 ) {
		return 1
		};

        # 'Vivek Agrawal', 'Liu Xin' types; hard to distinguish
        #  surname/firstname.
        if ($wCount >= 2 and 
            $wCount <= 3  and
	    no_initials($Text)) {
                return 1
                };   

        return 0
        };
 
sub no_initials {
        my $Text = shift;

	# do not count 'Jr.'	
	$Text =~ s/(\W)Jr\.?\s*$/$1/i;
	return 0 if ($Text =~ /(^| )[a-z]\./i);
	return 0 if ($Text =~ /(^| )[a-z]( |$)/i);

        return 1;
        }; 

sub only_initials {
        my $Text = shift;

	return 0 if ($Text =~ /^[a-z]{2,} /i);
	return 0 if ($Text =~ /\.?\s*[a-z][a-z]+$/i);

        my @Words = split(/[\.\s]/, $Text);
        my $Word;
        foreach $Word (@Words) { return 0 if (length($Word) >= 2)};
 
        return 1
        };

sub is_surname  {
	my ($Text) = @_;
	$Text =~ s/ Jr\W+$//i;

        return 0 if ($Text =~ / (e-print|archive)s? /i);
        return 0 if ($Text =~ /\bCollaboration\b/i);        

	return 1 if ($Text =~ /^(\s*[a-z][\-'a-z]+){1,3}$/i);
	# return 1 if ($Text =~ /^\s*[a-z]+[\-'a-z]+\s*$/i);

	return 0
	}

sub has_surname {
	my $Text = unidecode(shift);

	return 0 if ($Text =~ /\d+/);
	return 1 if ($Text =~ /^[a-z]{2,}[\s\-\']/i);
	# return 1 if ($Text =~ /[a-z]{2,}$/i);
	return 1 if ($Text =~ /[\-\'\s.][a-z][a-z]+(\s+Jr\.?)?\s*$/i);
	return 0
	}

sub has_initials {
	my $Text = unidecode(shift);

	return 0 if ($Text =~ /\d+/);
	return 1 if ($Text =~ /^\s*[']?\s*[A-Z](\s|\.|$)/);
	return 1 if ($Text =~ /(^|\s|\.)[a-z](\s|\.|$)/i);
                                                             
	return 0
	}

# mainly used to count 'words' in author names 
sub word_count {
        my ($Text) = @_;

	#$Text =~ s/^[\s.]+//;
	#my @Words = split(/[\s.]+/, $Text);
	# return scalar(@Words);

	$Text =~ s/ (von|van|de|den|der) //g;
	$Text =~ s/^\s+//;
	$Text =~ s/\s+$//;
	my @Words_all = split(/\s+/, $Text);
	# ignore initials in names.
	# e.g. "C.A.R. Sa de Melo" is a name
	my @Words;
	my $W;
	while (@Words_all) {
		$W = shift @Words_all;
		push(@Words, $W) if ($W !~ /^[a-z]\.?$/i);
		};
        return scalar(@Words); 
        };
#
# Normalisation utilities
#
sub normalisation_old {
die;
        my($Text) = @_;
	# replace embedded '\n' with ' '
	$Text =~ s/^\s+//s;
	$Text =~ s/\s+$//s;
        while ($Text =~ /.+?\n.+?/sg) {
	       $Text =~ s/(.+?)\n(.+?)/$1 $2/s
	       };
        $Text =~ s/\s*-\s*/-/g; # remove space around '-'
        $Text =~ s/\s*'\s*/'/g; # remove space around '
	$Text =~ s/\s*:\s*/:/g; # remove space around :
        $Text =~ s/\(\s+/\(/g;  # ( 1998) ==> (1998)
        $Text =~ s/\s+\)/\)/g;  # (1998 ) ==> (1998)
        while ($Text =~/--/g) {$Text =~ s/--/-/}; # use single '-'.
	$Text =~ s/~//g;   # remove '~' (e.g. C.~B.~Hanna)
        $Text =~ s/\s+/ /g; # use single space;
	$Text =~ s/[,;\s]+$//;    # remove last ',;\s' on a line
        # 'Nr.' caused error in 'find_jnl_name', i.e. it became as
        # 'journal name' if not removed. (see: arXiv:quant-ph/9905016)
        $Text =~ s/([,;])\s*Nr\.\s*(\d+[,;])/$1$2/i;
	# "[12] For example, R. Machleidt, ...Phys. Rep. 149, 1 (1987)
	$Text =~ s/^([^a-z]+)for example\W+/$1/i;	
	# '[18] *** G. Do Dang, ... (arXiv:nucl-th/9911081)
	$Text =~ s/\*+//g;
	# Phys. Rev. D56 => Phys. Rev. D. 56
	$Text =~ s/phys.{1,6}rev.{1,6}([a-z])(\d+)/Phys. Rev. $1 $2/ig;
        return $Text;
        }; 

sub normalise_html_old {
die;
        my($Text) = @_;
 
        # remove <BR> tag
        $Text =~ s/<BR>//ig;
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
        $Text =~ s/&#\d+;//g;    # e.g. '&#21' in 'hep-th/0001001 [99]'.
        $Text =~ s/\\"(\w)/$1e/g;  #  G\"unter => Gueter
 
        $Text =~ s/\^//g;  # remove ^
	$Text =~ s/([A-Z])\s*&\s*([A-Z])/$1 and $2/g;  # replace '&' with 'and'
	# remove HTML markups (<b></b><i></i> etc.)
	$Text =~ s/<[a-z\/]{1,3}>//ig;
        return $Text
        }; 


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
        $Text =~ s/(\w)\.\s+/\U$1\./ig;
        # Ghisellini G. A. ==> G.A. Ghisellini
	# Konenkov D. Yu. => D.Yu. Konenkov
        if ($Text =~ /^([^\s.]{2,})\s+(([A-Z][\w]?\W+)*)([A-Z][\w]?)\W*$/) {
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
	# Can't handle case reliably in international character sets
#	$author = lc($author);
#	$author =~ s/\b(\w)/\U$1/g;
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
	}
        $N = scalar(@Nlist);
        return $N
}  


sub remove_extra_spc {
        my($Text) = @_;
        $Text =~ s/^\s+//;
        $Text =~ s/\s+$//;
        $Text =~ s/\s\s/ /g; 
        return $Text
        };  

#
# To assist accessing of the citation meta data. 
#
sub srcText {
        my $cite = shift;
        return $cite->{'text'};
}

sub targetIdentifier {
	return $_[0]->{'targetID'};
}

sub targetURL {
	return $_[0]->{'targetURL'};
}

sub authors {
	return $_[0]->{'authors'};
}

sub list_authors {
	my $cite = shift; 
	return $cite->{'authors'}
}

sub aufull {
	return $_[0]->{'aufull'};
}

sub first_author {
        my $cite = shift;
        return $cite->{'aufull'};
}

sub aulast {
	my $cite = shift;
	return $cite->{'aulast'};
}

sub aufirst {
        my $cite = shift;
        return $cite->{'aufirst'};
}

sub auinit {
        my $cite = shift;
        return $cite->{'auinit'};
}                         

# journal title
sub title {
	my $cite = shift;
	return $cite->{'title'};
}

# article title
sub atitle {
	my $cite = shift;
	return $cite->{'atitle'};
}

sub volume {
        my $cite = shift;
        return $cite->{'volume'};
}

sub issue {
        my $cite = shift;
        return $cite->{'issue'};
}

sub supplement {
        my $cite = shift;
        return $cite->{'supl'};
}

sub year {
        my $cite = shift;
        return $cite->{'year'};
}
 
sub startpage {
        my $cite = shift;
        return $cite->{'spage'};
}                                                                               

sub endpage {
	return $_[0]->{'epage'};
}

sub journal {
        my $cite = shift;
        return $cite->{'title'};
}

sub featureID {
	my $cite = shift;
	return $cite->{'featureID'}
}


sub mysql_load_file {
	my $cite = shift;

	my $tm = localtime;
	my ($year,$mon,$mday);
	$year = $tm->year + 1900;
	$mon  = $tm->mon + 1;
	$mday = $tm->mday;
	my $TimeStamp = $year.'-'.$mon.'-'.$mday;
	$cite->{'date'} = $TimeStamp;

	print "$cite->{'date'}\t";
	print "$cite->{'sourceID'}\t";

	($cite->{'featureID'}) ? print "$cite->{'featureID'}\t"
			     : print "\\N\t";

	($cite->{'targetID'}) ? print "$cite->{'targetID'}\t"
			    : print "\\N\t";

	($cite->{refID}) ? print "$cite->{refID}\t"
			 : print "\\N\t";

	($cite->{'targetURL'}) ? print "$cite->{'targetURL'}\t"
			     : print "\\N\t";

	($cite->{'text'}) ? print "$cite->{'text'}\t"
			: print "\\N\t";
	
	($cite->{'aufull'}) ? print "$cite->{'aufull'}\t"
			  : print "\\N\t";

        ($cite->{'aulast'}) ? print "$cite->{'aulast'}\t"
                          : print "\\N\t";      

        ($cite->{'aufirst'}) ? print "$cite->{'aufirst'}\t"
                          : print "\\N\t";     

        ($cite->{'auinit'}) ? print "$cite->{'auinit'}\t"
                          : print "\\N\t"; 

	($cite->{'atitle'}) ? print "$cite->{'atitle'}\t"
			  : print "\\N\t";
	
	($cite->{'title'}) ? print "$cite->{'title'}\t"
			  : print "\\N\t";

	($cite->{'volume'}) ? print "$cite->{'volume'}\t"
			  : print "\\N\t";

	($cite->{'issue'}) ? print "$cite->{'issue'}\t"
			 : print "\\N\t";

	($cite->{'supl'}) ? print "$cite->{'supl'}\t"
                        : print "\\N\t";

	($cite->{'spage'}) ? print "$cite->{'spage'}\t"
                         : print "\\N\t";

	($cite->{'year'}) ? print "$cite->{'year'}"
                        : print "\\N";
	print "\n";
	}

sub print_out {  
	my $cite = shift;
	return if (!defined($cite->{'text'}));
	print '-'x70,"\n";
	print "$cite->{'text'} \n", '-'x70, "\n";
	print "sourceID:  \t$cite->{'sourceID'}\n" if ($cite->{'sourceID'});
	print "Authors: \t$cite->{'authors'}\n" if ($cite->{'authors'});
	print "First Author: \t$cite->{'aufull'}\n" if ($cite->{'aufull'});
        print "Article title:\t$cite->{'atitle'}\n" if ($cite->{'atitle'});
        print "Journal: \t$cite->{'title'}\n" if ($cite->{'title'});
        print "Volume: \t$cite->{'volume'}\n" if ($cite->{'volume'});
        print "Issue:  \t$cite->{'issue'} \n" if ($cite->{'issue'});
        print "Supplement: \t$cite->{'supl'} \n" if ($cite->{'supl'});
        print "Start Page: \t$cite->{'spage'}\n" if ($cite->{'spage'});
        print "Year: \t\t$cite->{'year'}\n" if ($cite->{'year'});
        print "targetURL: \t$cite->{'targetURL'}\n" if ($cite->{'targetURL'});
	print "featureID: \t$cite->{'featureID'}\n" if ($cite->{'featureID'});
	print "targetID:  \t$cite->{'targetID'}\n" if ($cite->{'targetID'});
        };
 
1;   
  
