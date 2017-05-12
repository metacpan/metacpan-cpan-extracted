package AI::Fuzzy;

use strict;
use vars qw($VERSION);

use AI::Fuzzy::Set;
use AI::Fuzzy::Label;

$VERSION = '0.01';

1;
__END__

=head1 NAME

AI::Fuzzy - Perl extension for Fuzzy Logic

=head1 SYNOPSIS

  use AI::Fuzzy;

  my $f = new AI::Fuzzy::Label;

  $f->addlabel("baby",        -1,   1, 2.5);
  $f->addlabel("toddler",      1, 1.5, 3.5);
  $f->addlabel("little kid",   2,   7,  12);
  $f->addlabel("kid",          6,  10,  14);
  $f->addlabel("teenager",    12,  16,  20);
  $f->addlabel("young adult", 18,  27,  35);
  $f->addlabel("adult",       25,  50,  75);
  $f->addlabel("senior",      60,  80, 110);
  $f->addlabel("relic",      100, 150, 200);


  for (my $x = 0; $x<50; $x+=4) {
      print "$x years old => " . $f->label($x) . "\n";
  }

__END__

=head1 DESCRIPTION

AI::Fuzzy really consists of two modules - AI::Fuzzy::Label and
AI::Fuzzy::Set.  

A fuzzy set is simply a mathematical set to which members can
I<partially> belong. For example, a particular shade of gray may
partially belong to the set of dark colors, whereas black would have
full membership, and lemon yellow would have almost no membership.

A fuzzy labeler classifies a particular crisp value by examining the
degree to which it belongs to several sets, and selecting the most
appropriate. For example, it can decide whether to call water at 60
degrees Farenheight "cold", "cool", or "warm". A fuzzy label might
be one of these labels, or a fuzzy set describing to what degree 
each of the labels describes the particular value in question.


=head2 Fuzzy Sets

AI::Fuzzy:Set has these methods:

    $fs = B<new> AI::Fuzzy::Set;

    # here, "Bob" is unquestionably tall.. the others less so.
    $fs_tall_people = B<new> AI::Fuzzy::Set( Lester=>34, Bob=>100, Max=>86 );
   
    # $x will be 86
    $x = B<membership> $fs_tall_people, "Max";

    # get list of members, sorted from least membership to greatest:
    @shortest_first = B<members> $fs_tall_people;

=head2 Fuzzy Labels

A Fuzzy::Label label has four attributes: the text of the label (it
can be any scalar, really), and three numbers: low, mid, high if you
imagine a cartesian plane (remember graph paper in algebra?)  of all
possible values, the label applies to a particular range.  the graph
might look something like this:


	
	  |Y               * (mid, 1)
	  |               /  \
	  |             /    \
	  |           /       \
	  |         /          \
	 -|-------*-------------*------- X
	           (low,0)      (high,0)
         

the Y value is applicability of the label for a given X value

the mid number is the "pure" value. eg, orange is at 0 or 360
degrees on the color wheel. the label applies 100% at the mid
point.

the low and high numbers are the two points at which
the label ceases to apply.

note that labels can overlap, and that the
mid number isn't always in the exact center, so the slope
of the two sides may vary...

$fl = new AI::FuzzyLabel;

$fl->addlabel( "hot", 77, 80, 100 );
    # what I consider hot. :) (in Farenheit, of course!)

$a = $fl->applicability($label, $value);
    # $a is now the degree to which $label applies to $value

$l = $fl->label ($value);
    # applies a label to $value

@l = $fl->label($value);
    # returns a list of labels and their applicability values

@l = new AI::Fuzzy::Set( $fl->label($value) );
    # same thing, but now it's an object

@range = $fl->range();
    # returns a list of labels, sorted by their midpoints
    # eg: ("cold", "cool", "lukewarm", "warm", "hot")


=head1 AUTHOR

Michal Wallace  (sabren@manifestation.com)

=head1 SEE ALSO

Move along, nothing to "see also" here...

=cut
