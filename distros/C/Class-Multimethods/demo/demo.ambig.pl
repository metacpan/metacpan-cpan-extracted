#!/usr/bin/env perl -w

use 5.005;

use Class::Multimethods;


multimethod put => (RoundPeg,Hole) => sub
{
	print "a round peg in any old hole\n";
};


multimethod put => (Peg,SquareHole) => sub
{
	print "any old peg in a square hole\n";
};


multimethod put => (Peg,Hole) => sub
{
	print "any old peg in any old hole\n";
};


# resolve_ambiguous put
# 	=> sub
 # 	   {
 # 		print "can't put a ", ref($_[0]),
 # 		      " into a ", ref($_[1]), "\n";
 # 	   };
 
# resolve_no_match put
#  	=> sub
# 	   {
# 		print "huh????\n";
# 	   };
  
# OR ELSE:
#
# resolve_ambiguous "put" => (Peg,Hole);
#
# resolve_no_match "put" => ('*','*');	# Note this will still fail unless
					# this variant is actually defined
					# when &put is called.


@RoundPeg::ISA   = qw{ Peg };

$peg = bless {}, Peg;
$roundpeg = bless {}, RoundPeg;

@SquareHole::ISA = qw{ Hole };

$hole = bless {}, Hole;
$squarehole = bless {}, SquareHole;

eval { put($peg, $hole)            } or print "ERROR: $@\n";
eval { put($roundpeg, $hole)       } or print "ERROR: $@\n";
eval { put($peg, $squarehole)      } or print "ERROR: $@\n";
eval { put($roundpeg, $squarehole) } or print "ERROR: $@\n";
eval { put(2,3)                    } or print "ERROR: $@\n";

Class::Multimethods::analyse(put=>[RoundPeg,SquareHole]);
