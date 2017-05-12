package Cellular::Automata::Wolfram;

use 5.006;
use strict;
use warnings;
use GD;
use Carp;
use Math::BaseCalc;
use Graphics::ColorNames 'hex2tuple';
use Class::MethodMaker
    new_with_init => 'new',
    get_set => [qw(rule rules colors radius width num_of_gens first_gen 
random gens window draw_file)];

use constant INSTANCE_DEFAULTS => (rule=>110,radius=>1,width=>80,num_of_gens=>100,random=>"",colors=>['white','black'],draw_file=>'wolfram.png');

require Exporter;
require DynaLoader;
require GD;
require Carp;
require Math::BaseCalc;
require Graphics::ColorNames;

use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Cellular::Automata::Wolfram ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.1';

bootstrap Cellular::Automata::Wolfram $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub init {
    my($self) = shift;
    my %values = (INSTANCE_DEFAULTS,@_);
    my $key;
    if(!exists($values{first_gen})) {
        $values{"first_gen"} = 
$self->set_first_gen($values{"colors"},$values{"width"},$values{"random"});
        $values{"width"} = (length($values{"first_gen"}));
    } # if
 
    if(!exists($values{rules})) {
        $values{rules} = 
$self->get_rules($values{rule},$values{colors},$values{radius});
    } # if 
    foreach my $key (keys %values) {
        $self->$key($values{$key});
    } # foreach
    my $temp = $self->first_gen();
    if(!defined($self->gens())) {
        $self->generate();
    } # if
    return $self;
} # sub new

sub draw {
    my($self,$draw_file) = @_;
    if(defined($draw_file)) { 
        $self->draw_file($draw_file);
    } # if
    else {
        $draw_file = $self->draw_file();
    } # else
    my %COLORS;
    tie %COLORS, 'Graphics::ColorNames';
    my $width = $self->width();
    my $num_of_gens = $self->num_of_gens();
    my $outfile;
    my $i;
    my $j;
    my $im = new GD::Image($width,$num_of_gens);
    my $color;
    open($outfile,">". $draw_file) or croak "Cannot open $draw_file\n";
    my $colors = $self->colors();
    my %color2tuple;
    foreach $color (@{$colors}) {
        if(exists($COLORS{$color})) {
            $color2tuple{$color} = 
$im->colorAllocate(hex2tuple($COLORS{$color}));
        } # if 
        else {
            croak("Cannot find:" . $color . "in Graphics::ColorNames\n");
        } # else
    } # foreach
    $self->generate();
    my $gens = $self->gens();
    my $gen;
    my @lines;
    my $png_info;
    for($i=0;$i<@{$gens};$i++) {
        @lines = split(//,$gens->[$i]);
        for($j=0;$j<=$#lines;$j++) {
            $im->setPixel($j,$i,$color2tuple{$colors->[$lines[$j]]});
        } # for
    } # for
    binmode $outfile;
    $png_info = $im->png;
    print $outfile $png_info;
    close($outfile);
} # sub draw


sub next_gen {
    my($self,$curr_gen) = @_;
    my $next_gen;
    my $i;
    my $rules = $self->rules();
    my $window_size = $self->window();
    my $width = $self->width(length($self->first_gen()));
    my $radius = $self->radius();
    my $key;
    my $curr_window;
    my $state;
    my $left_cells;
    my $right_cells;
    for($i=0;$i<=($width-$window_size);$i++) {
        $curr_window = substr($curr_gen,$i,$window_size);
        if(exists($rules->{$curr_window})) {
            $next_gen .= $rules->{$curr_window};
        } # if
        else {
            croak("There is no rule for:" . $curr_window);
        } # else
    } # for
    my $temp1;
    my $temp2;
    for($i=1;$i<=$radius;$i++) {
        $curr_window = substr($curr_gen,-$i,$i) . 
substr($curr_gen,0,$window_size-$i);
        if(exists($rules->{$curr_window})) {
            $left_cells .= $rules->{$curr_window};
        } # if
        else {
            croak("There is no rule for:" . $curr_window);
        } # else
        $temp1 =  substr($curr_gen,-$window_size+$i);
        $temp2 = substr($curr_gen,0,$i);
        $curr_window = $temp1 . $temp2;
        if(exists($rules->{$curr_window})) {
            $right_cells .= $rules->{$curr_window};
        } # if
        else {
            croak("There is no rule for:" . $curr_window);
        } # else
    } # for
    $next_gen = $left_cells . $next_gen . $right_cells;
    return $next_gen;
} # sub next_gen

sub generate {
    my($self) = @_;
    my $num_of_gens = $self->num_of_gens();
    my $curr_gen;
    my $i;
    if($self->random()) {
        $curr_gen = 
$self->set_first_gen($self->colors(),$self->width(),$self->random());
    } # if
    else {
        $curr_gen = $self->first_gen();
    } # else
    my @gens;
    push(@gens,$curr_gen);
    for($i=0;$i<=$num_of_gens;$i++) {
        $curr_gen = $self->next_gen($curr_gen);
        push(@gens,$curr_gen);
    } # for
    $self->gens([@gens]);
} # sub generate

sub set_first_gen {
    my($self,$colors,$width,$random) = @_;
    my $i;
    my @first_gen;
    my $temp;
    my $num_o_colors = @{$colors};
    if($random) {
        srand($$);
        for($i=0;$i<$width;$i++) {
            push(@first_gen,int(rand($num_o_colors)));
        } # for
        $temp = join("",@first_gen);
    } # if
    else {
        $num_o_colors--;
        $temp = "0" x (int($width/2)-1) . "$num_o_colors" . "0" x 
int($width/2);
    } # else
    return $temp;
} # sub set_first_gen


sub get_rules {
    my($self,$rule,$colors,$radius) = @_;
    my $i;
    my @k_states = (0..9,'A'..'Z','a'..'z');
    my @subk_states = splice(@k_states,0,@{$colors});
    my $calc = new Math::BaseCalc(digits => \@subk_states); #up to base 36
    my $rule_base = $calc->to_base($rule); # Convert $rule to given base
    my $max_num = (@{$colors} ** (@{$colors}**($radius+2)))-1;
    my $max_num_base = $calc->to_base($max_num);
    my $max_num_base_len = length($max_num_base);
    my $rule_base_len = length($rule_base);
    my $zero_pad = "0" x ($max_num_base_len-$rule_base_len);
    $rule_base = $zero_pad . $rule_base;
    $rule_base = reverse($rule_base);
    my $rule_num;
    my $max_rule_num = (@{$colors}**($radius+2))-1;
    my $max_rule_num_len = length($calc->to_base($max_rule_num));
    $self->window($max_rule_num_len);
    my %rules;
    for($i=$max_rule_num;$i>=0;$i--) {
                                  $rule_num = $calc->to_base($i);
                                  $zero_pad = "0" x 
($max_rule_num_len-length($rule_num));
                                  $rule_num = $zero_pad . $rule_num;
                                  $rules{$rule_num} = chop($rule_base);
    } # for
    return \%rules;
} # get_rules

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Cellular::Automata::Wolfram, implements one-dimensional non-totalistic 
cellular automata as described in Dr. Steven Wolfram's, A New Kind of 
Science, ISBN:1-57955-008-8

=head1 VERSION

This document refers to to version 1.00 of Cellular::Automata::Wolfram, 
released November 17, 2002

=head1 SYNOPSIS

  use Cellular::Automata::Wolfram;
  my $png_file = shift;
  my $caw = 
  new Cellular::Automata::Wolfram(
  rule=>110,radius=>1,width=>80,num_of_gens=>100,random=>"",
  colors=>[white,black]);
  my $ar_gens = $caw->gens();
  foreach my $gen (@{$ar_gens)) {
     print "$gen\n"; # Prints the numeric values of each generation 
                     # in the Cellular Automata.
  } # foreach
  $caw->draw($png_file); # This writes a png file out, 
                         # $caw->draw() has a default name 
                         # of "wolfram.png".


=head1 DESCRIPTION

Dr. Steven Wolfram describes in his book, A New Kind of Science, 
ISBN:1-57955-008-8 his path-breaking experiment where he comprehensively 
explored a mathematical function which can be described (by me see the 
reference for a detailed explanation) as follows:

Given an 1d array of numbers A:

[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0]

Call this generation 1 (i.e. t).

Generation 2 (i.e. t+1) will be created by applying a rule to each number of the form A(i)(t+1) = rules(A(i-1)(t),A(i)(t),A(i+1)(t)), where A(i)(t) is the current value at position i for generation t in the array, and A(i)(t+1) is the next generations value of A(i).

For an array limited to 0 and 1 as possible values in each position
the complete rules function can be described as follows:

Given array rule_input:

[111,110,101,100,011,010,001,000]

This is all the possible values that can be given as inputs to the rule 
function for an 0,1 array of numbers.  The return for the rule function 
can be defined as follows:

[111,110,101,100,011,010,001,000]
  |   |   |   |   |   |   |   |
  0   1   1   0   1   1   1   0

This number 01101110 can be treated as a decimal number expressed as
110, as the result of the following standard binary to decimal formula.
0x128+1x64+1x32+0x16+1x8+1x4+1x2+0x1 = 110.

This number 110 can be used to define the entire rules function that is 
needed
to determine the next generation.

Since all the possbile rules can be described from a eight digit binary 
number 
they run from 0 to 255 decimal, each number describes a different rules 
function and every possible rules function for an array limited to 0 and 1 

and whose input is three values drawn from that array.  The three values 
are
chosen in the formula descibed above.

The choice of i-1, the left adjacent cell, and, i+1, the right adjacent 
cell, as the number of left and right ajacent cells to consider for the 
next 
generation can be defined as radius R.  The number of values each cell can 

take can be described as K (in drawing the number of colors).  The 
examples 
short description is therefore (rule 110, K=2,R=1).  This module allows 
you 
to explore every one dimensional cellular automata for any valid rule for 
a 
given K and R.  The array wraps by default.

The result of rule 110 with K=2 [0,1] R=1 for 80 generations in an array 
of K 
values width 80 where the values wrap:


00000000000000000000000000000000000000010000000000000000000000000000000000000000
00000000000000000000000000000000000000110000000000000000000000000000000000000000
00000000000000000000000000000000000001110000000000000000000000000000000000000000
00000000000000000000000000000000000011010000000000000000000000000000000000000000
00000000000000000000000000000000000111110000000000000000000000000000000000000000
00000000000000000000000000000000001100010000000000000000000000000000000000000000
00000000000000000000000000000000011100110000000000000000000000000000000000000000
00000000000000000000000000000000110101110000000000000000000000000000000000000000
00000000000000000000000000000001111111010000000000000000000000000000000000000000
00000000000000000000000000000011000001110000000000000000000000000000000000000000
00000000000000000000000000000111000011010000000000000000000000000000000000000000
00000000000000000000000000001101000111110000000000000000000000000000000000000000
00000000000000000000000000011111001100010000000000000000000000000000000000000000
00000000000000000000000000110001011100110000000000000000000000000000000000000000
00000000000000000000000001110011110101110000000000000000000000000000000000000000
00000000000000000000000011010110011111010000000000000000000000000000000000000000
00000000000000000000000111111110110001110000000000000000000000000000000000000000
00000000000000000000001100000011110011010000000000000000000000000000000000000000
00000000000000000000011100000110010111110000000000000000000000000000000000000000
00000000000000000000110100001110111100010000000000000000000000000000000000000000
00000000000000000001111100011011100100110000000000000000000000000000000000000000
00000000000000000011000100111110101101110000000000000000000000000000000000000000
00000000000000000111001101100011111111010000000000000000000000000000000000000000
00000000000000001101011111100110000001110000000000000000000000000000000000000000
00000000000000011111110000101110000011010000000000000000000000000000000000000000
00000000000000110000010001111010000111110000000000000000000000000000000000000000
00000000000001110000110011001110001100010000000000000000000000000000000000000000
00000000000011010001110111011010011100110000000000000000000000000000000000000000
00000000000111110011011101111110110101110000000000000000000000000000000000000000
00000000001100010111110111000011111111010000000000000000000000000000000000000000
00000000011100111100011101000110000001110000000000000000000000000000000000000000
00000000110101100100110111001110000011010000000000000000000000000000000000000000
00000001111111101101111101011010000111110000000000000000000000000000000000000000
00000011000000111111000111111110001100010000000000000000000000000000000000000000
00000111000001100001001100000010011100110000000000000000000000000000000000000000
00001101000011100011011100000110110101110000000000000000000000000000000000000000
00011111000110100111110100001111111111010000000000000000000000000000000000000000
00110001001111101100011100011000000001110000000000000000000000000000000000000000
01110011011000111100110100111000000011010000000000000000000000000000000000000000
11010111111001100101111101101000000111110000000000000000000000000000000000000000
11111100001011101111000111111000001100010000000000000000000000000000000000000001
00000100011110111001001100001000011100110000000000000000000000000000000000000011
00001100110011101011011100011000110101110000000000000000000000000000000000000111
00011101110110111111110100111001111111010000000000000000000000000000000000001101
00110111011111100000011101101011000001110000000000000000000000000000000000011111
01111101110000100000110111111111000011010000000000000000000000000000000000110001
11000111010001100001111100000001000111110000000000000000000000000000000001110011
01001101110011100011000100000011001100010000000000000000000000000000000011010110
11011111010110100111001100000111011100110000000000000000000000000000000111111110
11110001111111101101011100001101110101110000000000000000000000000000001100000011
00010011000000111111110100011111011111010000000000000000000000000000011100000110
00110111000001100000011100110001110001110000000000000000000000000000110100001110
01111101000011100000110101110011010011010000000000000000000000000001111100011010
11000111000110100001111111010111110111110000000000000000000000000011000100111110
11001101001111100011000001111100011100010000000000000000000000000111001101100011
01011111011000100111000011000100110100110000000000000000000000001101011111100110
11110001111001101101000111001101111101110000000000000000000000011111110000101110
10010011001011111111001101011111000111010000000000000000000000110000010001111011
10110111011110000001011111110001001101110000000000000000000001110000110011001110
11111101110010000011110000010011011111010000000000000000000011010001110111011011
00000111010110000110010000110111110001110000000000000000000111110011011101111110
00001101111110001110110001111100010011010000000000000000001100010111110111000010
00011111000010011011110011000100110111110000000000000000011100111100011101000110
00110001000110111110010111001101111100010000000000000000110101100100110111001110
01110011001111100010111101011111000100110000000000000001111111101101111101011010
11010111011000100111100111110001001101110000000000000011000000111111000111111110
11111101111001101100101100010011011111010000000000000111000001100001001100000011
00000111001011111101111100110111110001110000000000001101000011100011011100000110
00001101011110000111000101111100010011010000000000011111000110100111110100001110
00011111110010001101001111000100110111110000000000110001001111101100011100011010
00110000010110011111011001001101111100010000000001110011011000111100110100111110
01110000111110110001111011011111000100110000000011010111111001100101111101100010
11010001100011110011001111110001001101110000000111111100001011101111000111100110
11110011100110010111011000010011011111010000001100000100011110111001001100101111
00010110101110111101111000110111110001110000011100001100110011101011011101111000
00111111111011100111001001111100010011010000110100011101110110111111110111001000
01100000001110101101011011000100110111110001111100110111011111100000011101011000
11100000011011111111111111001101111100010011000101111101110000100000110111111000
10100000111110000000000001011111000100110111001111000111010001100001111100001001
11100001100010000000000011110001001101111101011001001101110011100011000100011011
00100011100110000000000110010011011111000111111011011111010110100111001100111110
01100110101110000000001110110111110001001100001111110001111111101101011101100010

=head2 Constructor and initalization

This program has the following hash as its default values:

{rule=>110,radius=>1,width=>80,num_of_gens=>100,random=>"",colors=>[white,black],draw_file=>'wolfram.png'}

This hash can be overidden in the constructor.

For example:

   use Cellular::Automata::Wolfram;
   my $caw = new Cellular::Automata::Wolfram(
      rule=>255,colors=>[red,blue]);

Any of the defaults can be overwitten.

The defaults are defined as follows:

B<rule>=The number which defines the rules for this automata.

B<radius>=The number of left and right adjacent cells to be passed to the 
rule function.

B<width>=The width of the inital array.

B<num_of_gens>=How many generations this automata will run.

B<random>=If a perl false value ("",0), then start with a single cell e.g. 
0001000, if a true valve then a random startup e.g. 1101010

B<colors>=An anonymous hash containing color names from the module 
Graphics::ColorNames, this is used for drawing and to set the number of 
states K of the cellular automata.

B<draw_file>=The file that will contain the png drawing which represents the 
cellular automata.

=head2 Class and Object Methods

This module uses Class::MethodMaker setup for the system.
This produces a method which sets and gets the value for a given variable.
e.g.

  use Cellular::Automata::Wolfram;
  my $caw = new Cellular::Automata::Wolfram();
  my $rule = $caw->rule();
  print "$rule\n";   # prints 110, the default.
  $rule = 90;
  $caw->rule($rule); # sets rule to 90
  $caw->generate();  # generates the result with the new rule.
  $caw->draw();      # Writes out to the wolfram.png 
                     # the image of the new automata.




Methods running under get_set calling conventions are:

B<Method rule>

  #This sets or gets the rule that the automata is running under.
  print "rule:", $caw->rule(),"\n"; # default prints 110
  $caw->rule(90); # sets internal rule value to 90
  print "rule:", $caw->rule(),"\n"; # prints 90

B<Method colors>

  print map "colors:$_\n",@{$caw->colors()};
  #default prints
  #colors:white
  #colors:black 

This sets or gets an array of color names that are legal values from
module: Graphics::ColorNames
The first color [0] is the lowest integer value in the rule set, see 
above.
The last color [$#colors] is the higest integer value in the rule set,

B<Method radius>
  print "radius:",$caw->radius(),"\n"; # default prints 1
  $caw->radius(2);                     # sets radius to 2.

This sets the number of cell on either side of the current cell to check 
to
determine the next state.
For example:
Given string 01010 checking position 2 zero based, radius 1 means the next
state is determined by looking at positions 1, and 3 to give you string 
101
to be used to determine position 2's next state.
If the radius is 2 then you check positions 0,1 and 3,4 to check the next 
state
to give you string 01010 to be used to determine position 2's next state.

B<Method width>

  print "width:",$caw->width(),"\n"; # default prints 80
  $caw->width(100); # sets the width to 100.

The width is the length of the one dimensional array of the cellular 
automata.
This implementation wraps on each end of the array.  Alternate behavior is 

to force a value on one or both ends of the array, this may be an option
in the next version of this code.

B<Method num_of_gens>

  print "num_of_gens:",$caw->num_of_gens(),"\n"; 
  # default prints 80
  $caw->num_of_gens(80); 
  # sets the num_of_gens to 80

The number of generations that the cellular automata can run is set here.
The default is 80 generations, and this can be set up to the limits of 
your
memory.

B<Method first_gen>

This allows you to set the first generation manually.

  print "first_gen:\n",$caw->first_gen(),"\n"; 
  # default prints:
  # first_gen:
  #00000000000000000000000000000000000000010000000000000000000000000000000000000000
  #If random is set at initialization then the default is something like:
  #first_gen:
  #10111010110011111101001111101000110111110101001100101110001001011010010101100101
  $caw->first_gen("0000000000001000000000000");
  #sets first_gen to "0000000000001000000000000"
  #
  #If this is a three color graph [0,1,2] then the default looks something 
  # like this:
  #first_gen:
  #00000000000000000000000000000000000000020000000000000000000000000000000000000000
  #If this is a three color graph and the random is true, then the default 
  #looks something like this:
  #first_gen:
  #0012101211020021201002120022120110010011002112102110120112221120222110020221010

This first generation is automatically generated if first_gens is not provided
at initialization.  It is by default filled with 0's with the highest number, 
in this case 1 in the middle position of the first generation.  If random is 
set on initalization then you get a random set of allowed digits [0,1] being 
the defaults.

B<Method random>

This sets the first generation to random values.  These random values are 
set
with equal probability, in the default it is, 0,1, if the number of states 
are
3 then it is 0,1,2, and so on.

B<Method gens>

This gets back an array reference the strings representing each generation
for the given rule, states, and colors.  The first_gen is position 0, and 
increases until num_of_gens.

  $caw->gens() # default returns undef until method draw, 
               # or generate is called.
  #So do this.
  my $caw = new Cellular::Automata::Wolfram;
  $caw->generate(); # using default values
  my $ar_gens = $caw->gens();
  foreach my $gen (@{$ar_gens)) {
    print "$gen\n"; # Prints the string values of each generation in the 
                    # Cellular Automata.
  } # foreach

Setting this will do no good :).

B<Method window>

$caw->window(); # default will print 3 or the size of the total window

This value is the size of the window or the 2*radius + 1.

This one should not be set either :).  Really...don't.

B<Method draw_file>

This sets the name of the file that is written to when the draw method is
called.

  print "draw_file:",$caw->draw_file(),"\n"; # default prints wolfram.png.
  $caw->draw() # This will run the cellular automatata and write the file 
               # wolfram.png to the current directory.
  $caw->draw_file("/tmp/rule_110.png");
  $caw->draw() # This will run the cellular automatata and write the file 
               # rule_110.png to the tmp directory.

B<Method generate>

This will run the cellular automata from the first generation to the
num_of_gens.  This is called itself, or automatically if the draw method 
is called.

  my $caw = new Cellular::Automata::Wolfram();
  $caw->generate(); # This runs the automata.
  $caw->draw();     # This runs the automata again, n.b. 
                    # if you want to get an 
                    # image alone, call draw, don't call generate manually. 
                    # Generate is mainly available if you want to look at 
                    # and analyze the values for each without generating
                    # an image.

B<Method draw>

This makes makes a png image representing the complete run of the cellular automata.  The defaul name given to the image file is wolfram.png.

  my $caw = new Cellular::Automata::Wolfram();
  $caw->draw(); # This writes out the draw file, default is wolfram.png

=head1 ENVIORNMENT

This has been tested sucessfully under ActiveState Perl on Windows 2000.

This has been tested sucessfully under Perl 5.8 under Redhat Linux.

=head1 DIAGNOSTICS

=over 4

=item "Cannot open C<filename>"

If you don't have write permission for the draw file name given, then you
will see this message.  This name can include a path and make sure you can
write to the directory you specify.  The default path is the current 
directory.

=item "Cannot find C<colorname> in Graphics::ColorNames"

Graphics::Colornames covers most English color names, this has 650 names
in its default mode, see this modules documentation to see if what colors
are supported.

=item "There is no rule for: C<rule number>"

If for some reason you don't have a matching state for the current
substring in generation you are going through you get this error.
For example, given:

[111,110,101,100,011,undef,001,000]
  |   |   |   |   |   |     |   |
  0   1   1   0   1   u     1   0

If you are presented with 010 as a substring then you will get this error.

=back

=head1 BUGS

This does not handle n-dimensional cellular automata, and totalistic 
rules.
People might want to specify rgb values instead of color names.
Random values for the amount of a particular color could be user defined 
e.g. 70% white, 30% black.
This is very, very primitive, and there is quite a bit that could be added
both technically and in terms of more complex automata. 
These will be improvements in the next release.

Any bug reports please send to James M. Freeman II, jmfreeman@attbi.com

=head1 FILES

The modules that are prerequistes for this module are:

Lincoln Stein's GD.pm, version 2.05

http://search.cpan.org/author/LDS/GD-2.05/

GD.pm is needed to draw the cellular automata image files.

Ken Williams' Math::BaseCalc, version 1.011

http://search.cpan.org/author/KWILLIAMS/Math-BaseCalc-1.011/

Math::BaseCalc is used to change the rule number into the native base
determined by the number of states in the system.  K (number of states) = 
2
gives 0,1 or binary, rule 110 becomes, 01101110.  This is the same for 
octal
systems, decimal, hexidecimal, base 36, etc.

Robert Rothenberg's Graphics::ColorNames, version 0.31

http://search.cpan.org/author/RRWO/Graphics-ColorNames-0.31/

Graphics::ColorNames is used to allow users to call colors by name, rgb
values are indirectly set through this function.  Upon initalization a 
cellular automata is set with white and black by default, see this 
module's
documentation for the set of legal color names, X names are used in this 
module.

Martyn J. Pearce's Class::MethodMaker, version 1.08

http://search.cpan.org/author/FLUFFY/Class-MethodMaker-1.08/

Class::MethodMaker is used to set up get set methods for this module, as
recommended and demonstrated in Damian Conway's Object Oriented Perl book, ISBN 1884777791.

=head1 SEE ALSO

Dr. Wolfram's landmark paper:

S. Wolfram, "Statistical mechanics of cellular automata", Rev. Mod. Phys. 
55 (1983) 601.

Some selected later papers:

O. Martin, A. Odlyzko, and S. Wolfram, "Algebraic properties of cellular 
automata", Commun. Math. Phys. 93, (1984) 219.

S. Wolfram, "Universality and complexity in cellular automata", Physica 
10D (1984) 1.

Dr. Wolfram's book which chronicles the early papers about this field:

"Theory and Applications of Cellular Automata", Steven Wolfram, ISBN: 
9971-50-123-6 (hardcover), 9971-50-124-4 (paperback)

Dr. Wolfram's magnum opus:
"A New Kind of Science", Steven Wolfram, ISBN:1-57955-008-8

The website:http://www.wolframscience.com/

Dr. Wolfram's offical webpage:
http://www.stephenwolfram.com/

Dr. Wolfram has produced an excellent commerical program for his Cellular 
Automata that runs on both Mac's and Windows and can be found here:

http://www.wolframscience.com/nksx/index.html

=head1 AUTHORS

James M. Freeman II, jmfreeman@attbi.com,racecarradar@yahoo.com

=head1 COPYRIGHT

Copyright (c) 2002, James M. Freeman II, All Rights Reserved.  This module 
is free sofware.  It may be used, redistributed and/or modified under the 
same terms as Perl itself.

=cut
