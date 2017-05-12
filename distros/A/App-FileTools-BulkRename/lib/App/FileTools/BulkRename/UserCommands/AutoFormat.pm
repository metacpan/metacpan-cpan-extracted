package App::FileTools::BulkRename::UserCommands::AutoFormat;
# ABSTRACT: English title rewriting routines.
use strict;
use warnings;

BEGIN
  { our $VERSION = substr '$$Version: 0.07 $$', 11, -3; }

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK=qw(afmt);

use Carp;
use Contextual::Return;
use Text::Autoformat;
use Lingua::EN::Titlecase;

use App::FileTools::BulkRename::Common qw(modifiable);

#
# Our eventual hope is that we can eventually handle a great variety
# of title formats. Initially we went with the recommended
# Text::Autoformat module for everything, but found it inadequate in a
# wide variety of ways, such as rendering "façade" as "FaçAde".
#
# One day we should be able to handle all of the cases
# below. Currently we only do cases 1,2,3 and 9.
#
# 1) Uppercase:
#    "THE VITAMINS ARE IN MY FRESH CALIFORNIA RAISINS"
# 2) Start-Case: Capitalize all words
#    "The Vitamins Are In My Fresh California Raisins"
# 3) Title-Case 1: Capitalize all but internal articles, prepositions,
#    and conjunctions:
#    "The Vitamins Are in My Fresh California Raisins"
# 4) Title-Case 2: Capitalize all but internal articles, prepositions,
#    conjunctions and forms of 'to be':
#    "The Vitamins are in My Fresh California Raisins"
# 5) Title-Case 3: Capitalize all but internal closed-class function words
#    (these are the word classes that are strongly conserved in a language,
#    and to which it is hard to add new members):
#    "The Vitamins are in my Fresh California Raisins"
# 6) Noun-Case: Just capitalize nouns
#    "The Vitamins are in my fresh California Raisins"
# 7) Sentence case: Just the first word and proper nouns (and a few
#    other exceptions for English Prose):
#    "The vitamins are in my fresh California raisins"
# 8) Proper-Noun Case: Only proper nouns are capitalized.
#    "the vitamins are in my fresh California raisins"
# 9) Lowercase
#    "the vitamins are in my fresh california raisins"


# autoformat shim. Takes a case conversion name, and optionally
# something to convert. If not passed anything to convert, it will
# work on $_. If called in void context, it will modify its input
# (including $_, when appropriate).

my $TC = new Lingua::EN::Titlecase;

sub afmt
  { my $case = shift;
    my $opt  = { case => $case };
    my @ret;

    return afmt($case,$_) unless @_;

    foreach my $in (@_)
      { my $out;

	if( !defined($in) )
	  { $out = undef; }
	elsif( $in eq '' )
	  { $out = ''; }
	elsif( $case eq 'highlight' )
	  { $out = $TC->title($in); }
	else
	  {
	    # autoformat gags on blanks and undef's
	    $out = autoformat($in, $opt);

	    chomp($out); chomp($out);
	  }
	if( VOID )
	  { modifiable($in,$_) = $out; }
	else
	  { push @ret, $out; }
      }

    if( SCALAR )
      { return $ret[0]; }
    else
      { return @ret; }
  }

1;
