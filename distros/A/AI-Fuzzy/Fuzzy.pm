package AI::Fuzzy;

use strict;
use vars qw($VERSION);

use AI::Fuzzy::Set;
use AI::Fuzzy::Axis;
use AI::Fuzzy::Label;

$VERSION = '0.05';

1;
__END__

=head1 NAME

AI::Fuzzy - Perl extension for Fuzzy Logic

=head1 SYNOPSIS

  use AI::Fuzzy;

  my $f = new AI::Fuzzy::Axis;
  my $l = new AI::Fuzzy::Label("toddler",      1, 1.5, 3.5);

  $f->addlabel("baby",        -1,   1, 2.5);
  $f->addlabel($l);
  $f->addlabel("little kid",   2,   7,  12);
  $f->addlabel("kid",          6,  10,  14);
  $f->addlabel("teenager",    12,  16,  20);
  $f->addlabel("young adult", 18,  27,  35);
  $f->addlabel("adult",       25,  50,  75);
  $f->addlabel("senior",      60,  80, 110);
  $f->addlabel("relic",      100, 150, 200);


  for (my $x = 0; $x<50; $x+=4) {
      print "$x years old => " . $f->labelvalue($x) . "\n";
  }

  $a = new AI::Fuzzy::Set( x1 => .3, x2 => .5, x3 => .8, x4 => 0, x5 => 1);
  $b = new AI::Fuzzy::Set( x5 => .3, x6 => .5, x7 => .8, x8 => 0, x9 => 1);
  print "a is: " . $a->as_string . "\n"; 
  print "b is: " . $b->as_string . "\n"; 
  
  print "a is equal to b" if ($a->equal($b));
  
  my $c = $a->complement();
  print "complement of a is: " . $c->as_string . "\n"; 
  
  $c = $a->union($b);
  print "a union b is: " . $c->as_string . "\n"; 
  
  $c = $a->intersection($b);
  print "a intersection b is: " . $c->as_string . "\n"; 

__END__

=head1 DESCRIPTION

AI::Fuzzy really consists of three modules - AI::Fuzzy::Axis, AI::Fuzzy::Label, and
AI::Fuzzy::Set.  

A fuzzy set is simply a mathematical set to which members can
I<partially> belong. For example, a particular shade of gray may
partially belong to the set of dark colors, whereas black would have
full membership, and lemon yellow would have almost no membership.

A fuzzy axis holds fuzzy labels and can be used to classify values
by examining the degree to which they belong to several labels, and 
selecting the most appropriate.  For example, it can decide whether 
to call water at 60 degrees Farenheight "cold", "cool", or "warm". 

A fuzzy label classifies a particular range of the Axis. In the above example 
the label is one of "cold", "cool", or "warm". A fuzzy label defines how
much a crisp value belongs to the classifier such as "cold", "warm", or "cool". 



=head2 Fuzzy Sets

AI::Fuzzy:Set has these methods:

    $fs = B<new> AI::Fuzzy::Set;

    # here, "Bob" is unquestionably tall.. the others less so.
    $fs_tall_people = B<new> AI::Fuzzy::Set( Lester=>.34, Bob=>1.00, Max=>.86 );
   
    # $x will be .86
    $x = B<membership> $fs_tall_people, "Max";

    # get list of members, sorted from least membership to greatest:
    @shortest_first = B<members> $fs_tall_people;

    $fs = B<new> AI::Fuzzy::Set( x1 => .3, x2 => .5, x3 => .8, x4 => 0, x5 => 1);

    B<complement>, B<union>, B<intersection>
    Thesie are the fuzzy set version of the typical functions.
   
    B<equal>
    Returns true if the sets have the same elements and those elements
    are all equal.

   B<as_string>
   Prints the set as tuples:
	$b = new AI::Fuzzy::Set( x5 => .3, x6 => .5, x7 => .8, x8 => 0, x9 => 1);
	print "b is: " . $b->as_string . "\n"; 
    prints:
	b is: x8/0, x5/0.3, x6/0.5, x7/0.8, x9/1

=head2 Fuzzy Labels

A Fuzzy::Label label has four attributes: the text of the label (it
can be any scalar, really), and three numbers: low, mid, high if you
imagine a cartesian plane (remember graph paper in algebra?)  of all
possible values, the label applies to a particular range.  the graph
might look something like this:


	
	  |Y           * (mid, 1)
	  |           /  \
	  |          /     \
	  |         /       \
	  |        /          \
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

$fl = new AI::Fuzzy::Label ( "hot", 77, 80, 100 );
$fx = new AI::Fuzzy::Label ( "cold", 0, 10, 200 );
    # what I consider hot. :) (in Farenheit, of course!)

if ( $fl->lessthan($fx) ) {
    print "the laws of nature have changed\n";
}

# there is a lessthan, greaterthan, lessequal, greaterequal, and between 
#  that functions as above or using <,>,<=,>=

$a = $fl->applicability($value);
    # $a is now the degree to which this label applies to $value

=head2 Fuzzy Axis

A Fuzzy::Axis maintains a hash of labels.  Thus you can now look at how
values apply to the full range of labels.  The graph of an Axis might
look like this:


	
	  |Y             * (mid, 1)
	  |           /\/ \      /|
	  |  /- -\   / /\  \    / |  
	  | /     \-/ /  \   \ /  |  (some function on some range of x)
	  | |        /    \   /\  ---*-|
	 -|---------*-----------*------- X
	           (low,0)      (high,0)
         

the Y value is still the applicability of the label for a given X value,
but there are three labels on this Axis.  A different X value may
put your value into a new label.

$fl = new AI::Fuzzy::Axis;

$fl->addlabel($label);
    # add a label created as in AI::Fuzzy::Label docs

$a = $fl->applicability($label, $value);
    # $a is now the degree to which $label applies to $value

$l = $fl->label ("labelname");
    # returns the label object named "labelname"

$l = $fl->labelvalue ($value);
    # applies a label to $value

@l = $fl->labelvalue($value);
    # returns a list of labels and their applicability values

$s = new AI::Fuzzy::Set( $fl->label($value) );
    # same thing, but now it's an object

@range = $fl->range();
    # returns a list of labels, sorted by their midpoints
    # eg: ("cold", "cool", "lukewarm", "warm", "hot")
=head1 AUTHOR

Tom Scanlan <tscanlan@openreach.com>,
current maintainer 

Michal Wallace  (sabren@manifestation.com),
original author


=head1 SEE ALSO

Move along, nothing to "see also" here...

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@openreach.com>

=cut
