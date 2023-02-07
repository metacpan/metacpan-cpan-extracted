package Biblio::Citation::Compare;

use 5.0;
use strict;
use warnings;
use Text::LevenshteinXS qw(distance);
use HTML::Entities;
use Text::Names qw/samePerson cleanName parseName parseName2/;
use Text::Roman qw/isroman roman2int/;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	sameWork sameAuthors toString extractEdition sameAuthorBits sameTitle sameAuthorsLoose
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.57';

# to correct bogus windows entities. unfixable ones are converted to spaces.
my %WIN2UTF = (
    hex('80')=> hex('20AC'),#  #EURO SIGN
    hex('81')=> hex('0020'),           #UNDEFINED
    hex('82')=> hex('201A'),#  #SINGLE LOW-9 QUOTATION MARK
    hex('83')=> hex('0192'),#  #LATIN SMALL LETTER F WITH HOOK
    hex('84')=> hex('201E'),#  #DOUBLE LOW-9 QUOTATION MARK
    hex('85')=> hex('2026'),#  #HORIZONTAL ELLIPSIS
    hex('86')=> hex('2020'),#  #DAGGER
    hex('87')=> hex('2021'),#  #DOUBLE DAGGER
    hex('88')=> hex('02C6'),#  #MODIFIER LETTER CIRCUMFLEX ACCENT
    hex('89')=> hex('2030'),#  #PER MILLE SIGN
    hex('8A')=> hex('0160'),#  #LATIN CAPITAL LETTER S WITH CARON
    hex('8B')=> hex('2039'),#  #SINGLE LEFT-POINTING ANGLE QUOTATION MARK
    hex('8C')=> hex('0152'),#  #LATIN CAPITAL LIGATURE OE
    hex('8D')=> hex('0020'),#  #UNDEFINED
    hex('8E')=> hex('017D'),#  #LATIN CAPITAL LETTER Z WITH CARON
    hex('8F')=> hex('0020'),#  #UNDEFINED
    hex('90')=> hex('0020'),#  #UNDEFINED
    hex('91')=> hex('2018'),#  #LEFT SINGLE QUOTATION MARK
    hex('92')=> hex('2019'),#  #RIGHT SINGLE QUOTATION MARK
    hex('93')=> hex('201C'),#  #LEFT DOUBLE QUOTATION MARK
    hex('94')=> hex('201D'),#  #RIGHT DOUBLE QUOTATION MARK
    hex('95')=> hex('2022'),#  #BULLET
    hex('96')=> hex('2013'),#  #EN DASH
    hex('97')=> hex('2014'),#  #EM DASH
    hex('98')=> hex('02DC'),#  #SMALL TILDE
    hex('99')=> hex('2122'),#  #TRADE MARK SIGN
    hex('9A')=> hex('0161'),#  #LATIN SMALL LETTER S WITH CARON
    hex('9B')=> hex('203A'),#  #SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
    hex('9C')=> hex('0153'),#  #LATIN SMALL LIGATURE OE
    hex('9D')=> hex('0020'),#  #UNDEFINED
    hex('9E')=> hex('017E'),#  #LATIN SMALL LETTER Z WITH CARON
    hex('9F')=> hex('0178')#  #LATIN CAPITAL LETTER Y WITH DIAERESIS
);
my $PARENS = '\s*[\[\(](.+?)[\]\)]\s*';
my $QUOTE = '"“”`¨´‘’‛“”‟„′″‴‵‶‷⁗❛❜❝❞';
my @ED_RES = (
    '(first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)',
    '([1-9])\s?\w{2,5}\s[ée]d',
    '\bv\.?(?:ersion)?\s?([0-9IXV]+)',
    '\s([IXV0-9]+)(?:$|:)'
);

#die "no" unless "2nd edition" =~ /$EDITION/i;

#my $TITLE_SPLIT = '(?:\?|\:|\.|!|\&quot;|[$QUOTE]\b)';
my $TITLE_SPLIT = '(?:\?|\:|\.|!)';

sub sameAuthors {
    my ($list1, $list2, %opts) = @_;
    return 0 if $#$list1 != $#$list2 and $opts{strict};
    if ($#$list2 > $#$list1) {
        my $t = $list1;
        $list1 = $list2;
        $list2 = $t;
    }
    for (my $i = 0; $i <= $#$list2; $i++) {
        return 0 unless grep { samePerson($list2->[$i],$_, %opts) } @$list1;
    }
    return 1;
}

sub firstAuthor {
    my $e = shift;
    my $a = $e->{authors};
    if ($#$a > -1) {
        return $a->[0];
    } else {
        return undef;
    }
}

sub sameWork {

 	my ($e, $c, $threshold,$loose,$nolinks,%opts) = @_;

    my $debug = $opts{debug} || 0;

    $loose = 0 unless defined $loose;
    $threshold = 0.15 unless $threshold;
    $opts{loose} = 1 if $loose;
  
    if ($debug) {
        warn "sameWork 1: " . toString($e);
        warn "sameWork 2: " . toString($c);
    }

    if (defined $e->{doi} and length $e->{doi} and defined $c->{doi} and length $c->{doi}) {
        if ($e->{doi} eq $c->{doi}) {
            # we don't use doi to say 1 because often we have dois that are for a whole issue
            # however same doi lowers the threshold
            $threshold /= 2 if $e->{doi} eq $c->{doi};
            $loose = 1;
            $opts{loose} = 1;
        } else {
            return 0;
        }
    }

	return 0 if (!$c);

    # normalize encoding of relevant fields
    local $e->{title} = decodeHTMLEntities($e->{title});
    local $c->{title} = decodeHTMLEntities($c->{title});

    # first check if authors,date, and title are almost literally the same
    my $tsame = (lc $e->{title} eq lc $c->{title}) ? 1 : 0;
    my $asame = sameAuthors($e->{authors},$c->{authors},strict=>1);
    my $asame_loose = $asame || sameAuthors($e->{authors},$c->{authors},strict=>0); #asame_loose will be 1 while same is 0 when there are extra authors in one paper but all overlap authors match
    my $asame_bits = $asame_loose || sameAuthorBits($e->{authors},$c->{authors});
    my $dsame = (defined $e->{date} and defined $c->{date} and $e->{date} eq $c->{date}) ? 1 : 0;

    if ($debug) {
        warn "tsame: $tsame";
        warn "asame: $asame";
        warn "asame_loose: $asame_loose";
        warn "asame_bits: $asame_bits";
        warn "dsame: $dsame";
    }

    return 1 if ($tsame and $asame and $dsame);

	# if authors quite different, not same
    if (!$asame_bits) {
        warn "authors too different" if $debug;
     	return 0;
    }
    # at this point the authors are plausibly the same

    # check dates
    my $date_wildcards = '^forthcoming|in press|manuscript|unknown|web$';
    my $compat_dates = ($dsame or ($e->{date} && $e->{date} =~ /$date_wildcards/) or ($c->{date} && $c->{date} =~ /$date_wildcards/));
    if (!$dsame and !$compat_dates) {

        #disabled for most cases because we want to conflate editions and republications for now. 
        if ($e->{title} =~ /^Introduction.?$/ or $e->{title} =~ /^Preface.?$/) {
            return 0 if ($e->{source} and $e->{source} ne $c->{source}) or 
                        ($e->{volume} and $e->{volume} ne $c->{volume});
        }

        # numeric dates
        if ($e->{date} and $e->{date} =~ /^\d\d\d\d$/ and $c->{date} and $c->{date} =~ /^\d\d\d\d$/) {
            my $date_diff = $e->{date} - $c->{date};            
            # quite often people misremember dates so we permit some slack
            # we will consider the dates compat if they close in time
            # if dates are far apart, we know they are not exactly the same publicatoins. 
            # but they might be reprints of the same thing, which we want to conflate. 
            if ($date_diff > 3 or $date_diff < -3) {
                if ($asame_bits) {
                    $threshold /= 2;
                    warn "dates different, lowering similarity threshold" if $debug;
                } else {
                    warn "dates+authors too different" if $debug;
                    return 0;
                }

            } else {
                # nearby date
                $threshold /= 2;
            }

        } else {
            #messed up dates, assume the worst
            $threshold /=2;
        }

    } else {
        $loose = 1 if $asame_loose or $asame_bits;
    }
    



    warn "pre title length" if $debug;
	# if title very different in lengths and do not contain ":" or brackets, not the same
	return 0 if !$tsame and (
                    abs(length($e->{title}) - length($c->{title})) > 20 
                    and
					($e->{title} !~ /$TITLE_SPLIT/ and $c->{title} !~ /$TITLE_SPLIT/)
                    and
					($e->{title} !~ /$PARENS/ and $c->{title} !~ /$PARENS/)
				); 	

	# Compare links
#    if (!$nolinks) {
#        foreach my $l (@{$e->{links}}) {
#            print "Links e:\n" . join("\n",$e->getLinks);
#            print "Links c:\n" . join("\n",$c->getLinks);
#            return 1 if grep { $l eq $_} @{$c->{links}};
#        }
#    }

    warn "pre loose mode: loose = $loose" if $debug;

    #print "threshold $lname1,$lname2: $threshold\n";
	# ok if distance short enough without doing anything
	#print "distance: " . distance(lc $e->{title},lc $c->{title}) / (length($e->{title}) +1) . "\n";

	# perform fuzzy matching
   	#my $str1 = "$e->{date}|$e->{title}";
	my $str1 = lc _strip_non_word($e->{title});
	my $str2 = lc _strip_non_word($c->{title});

    # check for edition strings
    my $ed1 = extractEdition($str1);
    my $ed2 = extractEdition($str2);
    warn "ed1: $ed1" if $debug;
    warn "ed2: $ed2" if $debug;
    $loose =1 if $ed1 and $ed2 and $ed1 == $ed2 and !$dsame and $asame_loose;

    return 0 if ($ed1 and !$ed2) or ($ed2 and !$ed1) or ($ed1 && $ed1 != $ed2);
    warn "not diff editions" if $debug;

    # remove brackets 
    my ($parens1,$parens2);
    $str1 =~ s/$PARENS//g;
    $parens1 = $1;
    $str2 =~ s/$PARENS//g;
    $parens2 = $1;
    return 0 if $parens1 && $parens2 && numdiff($parens1,$parens2);

    warn "the text comparison is: '$str1' vs '$str2'" if $debug;

    warn "pre number check" if $debug;
	# if titles differ by a number, not the same
	return 0 if numdiff($str1,$str2);

    # ultimate test
    #dbg("$str1\n$str2\n");
    #dbg(my_dist_text($str1,$str2));
    my $score = (my_dist_text($str1,$str2) / (length($str1) +1));
    
    warn "score: $score (threshold: $threshold)" if $debug;
    #print $score . "<br>\n";
 	return 1 if ( $score < $threshold);

	# now if loose mode and only one of the titles has a ":" or other punctuation, compare the part before the punc with the other title instead
    if ($loose) {

        warn "loose: $str1 -- $str2" if $debug;

        if ($e->{title} =~ /(.+?)\s*$TITLE_SPLIT\s*(.+)/) {

            my $str1 = _strip_non_word($1);
            if ($c->{title} =~ /(.+?)\s*$TITLE_SPLIT\s*(.+)/) {
                return 0;
            } else {
                if (my_dist_text($str1,$str2) / (length($str1) +1)< $threshold) {
                    return 1;
                }
            }

        } elsif ($c->{title} =~ /(.+?)\s*$TITLE_SPLIT\s*(.+)/) {

            my $str2 = _strip_non_word($1);
            if (my_dist_text($str1,$str2) / (length($str1) +1)< $threshold) {
                return 1;
            }

        } else {

            return 0;

        }
    }
        
    return 0;
}

sub sameAuthorsLoose {
  my ($a, $b) = @_;
  my $asame = sameAuthors($a,$b,strict=>1);
  my $asame_loose = $asame || sameAuthors($a,$b,strict=>0);
  return $asame_loose || sameAuthorBits($a,$b);
}

sub sameAuthorBits {
    my ($a, $b) = @_;
    my (@alist, @blist);
    for (@$a) { 
        my $v = lc $_; # we copy so we don't modify the original
        $v =~ s/[,\.]//g;
        #$v =~ s/(\p{Ll})(\p{Lu})/$1 $2/g;
        push @alist, split(/\s+/, $v); 
    }
    for (@$b) { 
        my $v = lc $_;
        $v =~ s/[,\.]//g;
        #$v =~ s/(\p{Ll})(\p{Lu})/$1 $2/g;
        push @blist, split(/\s+/, $v); 
    }
    #use Data::Dumper;
    @alist = sort @alist;
    @blist = sort @blist;
    #print Dumper(\@alist);
    #print Dumper(\@blist);
    return 0 if $#alist != $#blist;
    for (my $i=0; $i<= $#alist; $i++) {
        return 0 if lc $alist[$i] ne lc $blist[$i];
    }
    return 1;
}

#wip
#sub author_bits {
#    my $list_ref = shift;
#    my @new;
#    for (@$list_ref) { 
#        my $v = $_; # we copy so we don't modify the original
#        $v =~ s/,//;
#        $v =~ s/(\p{Ll}\p
#        push @alist, split(/\s+/, $v); 
#    }
#}

sub _strip_non_word {
    my $str = shift;
    #abbreviation "volume" v
    $str =~ s/\bvolume\b/v/gi;
    $str =~ s/\bvol\.?\b/v/gi;
    $str =~ s/\bv\.\b/v/gi;

  $str =~ s/[^[0-9a-zA-Z\)\]\(\[]+/ /g;
    $str =~ s/\s+/ /g;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str; 
}

my %nums = (
    first => 1,
    second => 2,
    third => 3,
    fourth => 4,
    fifth => 5,
    sixth => 6,
    seventh => 7,
    eighth => 8,
    ninth => 9,
    tenth => 10,
);
sub extract_num {
    my $s = shift;
    if ($s =~ /\b(\d+)/) {
        return $1;
    }
    if (isroman($s)) {
        return roman2int($s);
    }

    for my $n (keys %nums) {
        if ($s =~ /\b$n\b/i) {
            return $nums{$n};
        }

    }
    return $s;
}

sub extractEdition {
    my $s = shift;
    for my $re (@ED_RES) {
        if ($s =~ /$re/i) {
            return extract_num($1);
        }
    }
    return undef;
}

sub numdiff {
  my ($s1,$s2) = @_;
  my @n1 = ($s1 =~ /\b([IXV0-9]{1,4}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|eleventh|twelveth|1st|2nd|3rd|4th|5th|6th|7th|8th|9th|10th|11th|12th)\b/ig);
  my @n2 = ($s2 =~ /\b([IXV0-9]{1,4}|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|eleventh|twelveth|1st|2nd|3rd|4th|5th|6th|7th|8th|9th|10th|11th|12th)\b/ig);
  #print "In s1:" . join(",",@n1) . "\n";
  #print "In s2:" . join(",",@n2) . "\n";
  return 0 if $#n1 ne $#n2;
  for (0..$#n1) {
      return 1 if lc $n1[$_] ne lc $n2[$_];
  }
  return 0;
}


sub my_dist_text {
	my $a = lc shift;
	my $b = lc shift;
	$a =~ s/_/ /g;
	$b =~ s/_/ /g;
	return distance($a, $b);

}
sub decodeHTMLEntities {
    my $in = shift;
    $in =~ s/&([\d\w\#]+);/&safe_decode($1)/gei;
    return $in;
}

sub safe_decode {
    my $in = shift;
    if (substr($in,0,1) eq '#') {
        my $num = substr($in,1,1) eq 'x' ? hex(substr($in,1)) : substr($in,1);
        # we check and fix cp1232 entities
        return ($num < 127 or $num > 159) ? 
            HTML::Entities::decode_entities("&$in;") :
            HTML::Entities::decode_entities("&#" . $WIN2UTF{$num} . ";");
    } else {
            HTML::Entities::decode_entities("&$in;")
    }
}

sub toString {
    my $h = shift;
    return join("; ",@{$h->{authors}}) . " ($h->{date}) $h->{title}\n";
}

sub sameTitle {
  my ($a, $b, $threshold,$loose,$nolinks,%opts) = @_;
  return sameWork({ title => $a }, { title => $b }, $threshold,$loose,$nolinks,%opts);
}

1;
__END__

=head1 NAME

Biblio::Citation::Compare - Perl extension for performing fuzzy comparisons between bibliographic citations

=head1 SYNOPSIS

  use Biblio::Citation::Compare 'sameWork','sameAuthors';

  sameWork(
    # first item
    {
        authors => ['Bourget, D','Lukasiak, Zbigniew'],
        title => "A paper with such and such a title",
        date => 2010
    },
    # second item
    {
        authors => ['Bourget, David J. R.','Lukasiak, Zbigniew'],
        title => "A paper with such nd such a tlitle",
        date => undef
    }
  );

  # true!

  sameAuthors(
    ['Dave Bourget','Z Lukasiak'],
    ['Bourget DJR','Zbigniew Z. Lukasiak']
  );

  # true!


=head1 DESCRIPTION

This module exports two subroutines which perform fuzzy comparisons between citations (described using Perl hashes) and author lists. The subroutine attempt to determine if the citations and author lists refer to the same works and ordered lists of authors, respectively.

=head1 SUBROUTINES

=head2 sameWork(hashref citation1, hashref citation2): boolean

Takes as input two citations in a simple format illustrated in the synopsis. Returns true iff the two citations plausibly refer to the same work. A number of factors are taken into account to make the evaluation resistant to random variations. Among them: names are normalized and compared fuzzily using L<Text::Names>, allowances are made for random typos, allowances are made for short and long versions of titles (esp with titles containing a colon), small but important variations as in "Paper title part 1" and "Paper title part 2" are taken into account. The algorithm has been used to merge multiple data sources on L<PhilPapers.org>. 

Some advanced additional parameters are not explained here; they can only be explained by pointing to the source code. Their use should not normally be necessary.

=head2 sameAuthors(arrayref list1, arrayref list2): boolean

Returns true if the two lists are plausibly lists of the same authors. This is merely a convenient wrapper over L<Text::Names>::samePerson.

=head2 EXPORT

None by default.

=head1 SEE ALSO

See also L<Text::Names> for name normalization.

=head1 AUTHOR

David Bourget, http://www.dbourget.com 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by David Bourget

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
