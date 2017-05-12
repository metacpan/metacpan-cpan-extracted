#! perl -w

#
# This is the decimal.c example rewritten in Perl with some enhancements.
#
# This sample program illustrates how to perform calculations
# using the dtF/SQL DTFDECIMAL data type.
#
# Author: Thomas Wegner 
# Date: 2001-Jan-10
#

use strict;
use Mac::DtfSQL qw(:all);

$| = 1; # no line buffering


print "\n",
        "dtF/SQL - Decimal Sample\n",
        "------------------------\n";


my @dec;
my @dec_input;
my ($scale, $sum, $dif, $prod, $quot, $ok, $index);

# create objects
$dec[0] = Mac::DtfSQL->new_decimal;
$dec[1] = Mac::DtfSQL->new_decimal;
$dec[2] = Mac::DtfSQL->new_decimal;
$sum = Mac::DtfSQL->new_decimal;
$dif = Mac::DtfSQL->new_decimal;
$prod = Mac::DtfSQL->new_decimal;
$quot = Mac::DtfSQL->new_decimal;


# There are three methods which allow you to set the value of a decimal object:
#
# $dec->from_string('5500.40'); # assign value from string
# $dec->from_long(150000); # assign value from long integer
# $dec->assign($dec2); # $dec = $dec2
#
# The scale (number of digits after the decimal point) of a decimal created using 
# the from_string method depends on the actual number of digits after the decimal 
# point in the string source.
#
# The scale of a decimal initialized by the from_long method is always zero.


while (1) { # loop forever
	print "\n\n";
	print  	"You may now enter some decimals and we perform some operations with it.\n",
       		"In order to quit, enter \"exit\" or \"quit\" on any prompt.\n",
       		"\n";


#  We retrieve some lines of user input from STDIN which should represent a decimal.
#  When the input was "exit" or "quit", we leave the input loop, ending the script.

	$index = 1;
	do {
		print "Enter decimal dec" . $index . ": ";

    	my $input = <STDIN>;
    	chomp $input;
    
		# under MPW, the whole line including the prompt is the input, so get 
		# rid of the prompt
		$input =~ s/^Enter decimal dec\d: //; 	
	
		if (  ($input =~ /QUIT/i) || ($input =~ /EXIT/i) ) { # exit script
	    	last;
 		}

		$ok = $dec[$index-1]->from_string($input);
		if ( ! $ok )
  		{
    		print "ERROR: This is not a valid decimal.\n";
  		} else {
			$index++;
			push @dec_input, $input;
		}
	} until ( ($ok) && ($index != 2) );


	do {
		print "Enter a long integer value (dec3): ";


    	my $input = <STDIN>;
    	chomp $input;
    
		# under MPW, the whole line including the prompt is the input, so get 
		# rid of the prompt
		$input =~ s/^Enter a long integer value \(dec3\): //; 	
	
		if (  ($input =~ /QUIT/i) || ($input =~ /EXIT/i) ) { # exit script
	    	last;
 		}

		if  ( $input =~ /^[+-]?\d+$/) {
			$ok = $dec[2]->from_long($input);
			push @dec_input, $input;
		} else {
			$ok = 0; # not a long value, from_long doesn't care !
		}
		
		if ( ! $ok ) {
    		print "ERROR: This is not a valid long integer.\n";
  		} 
	} until $ok;
	
	print "\n\n";
	
	my $ary_count = @dec;
	for (my $i=0; $i<$ary_count; $i++) {
		#  Using the is_valid method we check whether a DTFDECIMAL
		#  created is valid.
		if (! $dec[$i]->is_valid) {
			print "ERROR: $dec_input[$i] is not a valid decimal specification.\n";
		}#if
	}#for
	
	# determine the largest scale used:

  	$scale = $dec[0]->get_scale;

  	if ($dec[1]->get_scale > $scale)
  	{
    	$scale = $dec[1]->get_scale;
		$dec[0]->set_scale($scale);
		print 	"Since the largest scale specified is $scale, we use this value for the \n",
	      		"following calculations.\n";
		#  a DTFDECIMAL's scale can be changed using the set_scale method:
		if (! $dec[0]->set_scale($scale) ) {
			print "\nERROR: Can't set the scale of dec1 (\"normalize\" failed).\n";
		} else {
			print "\nScale of dec1 after normalizing = ", $dec[0]->get_scale, "\n";
		}
	} else {
		$dec[1]->set_scale($scale);
		print 	"Since the largest scale specified is $scale, we use this value for the \n",
	      		"following calculations.\n";
		#  a DTFDECIMAL's scale can be changed using the set_scale method:
		if (! $dec[1]->set_scale($scale) ) {
			print "\nERROR: Can't set the scale of dec2 (\"normalize\" failed).\n";
		} else {
			print "\nScale of dec2 after normalizing = ", $dec[1]->get_scale, "\n";
		}
	}
	

	
	#  a DTFDECIMAL's scale can be changed using the set_scale method:
	if (! $dec[2]->set_scale($scale) ) {
		print "\nERROR: Can't set the scale of dec3 (\"normalize\" failed).\n";
	} else {
		print "Scale of dec3 (long value) after normalizing = ", $dec[2]->get_scale, "\n";
	}
	
	print "\nWe are now using the following constants:\n";
	for (my $i=0; $i<$ary_count; $i++) {
		print "    dec" ,$i+1, " = " , $dec[$i]->as_string , "\n";
		
	}#for
	
	print "\nDoing some comparisons:\n";
	
	if ( $dec[0]->equal($dec[1]) ) {
    	print "    ", $dec[0]->as_string, " == ", $dec[1]->as_string, " (dec1 == dec2)\n";
  	}
	if ( $dec[0]->less_equal($dec[1]) ) {
    	print "    ", $dec[0]->as_string, " <= ", $dec[1]->as_string, " (dec1 <= dec2)\n";
  	}
	if ( $dec[0]->greater_equal($dec[1]) ) {
    	print "    ", $dec[0]->as_string, " >= ", $dec[1]->as_string, " (dec1 >= dec2)\n";
  	}
	if ( $dec[0]->less($dec[1]) ) {
    	print "    ", $dec[0]->as_string, " < ", $dec[1]->as_string, " (dec1 < dec2)\n";
  	}
	if ( $dec[0]->greater($dec[1]) ) {
    	print "    ", $dec[0]->as_string, " > ", $dec[1]->as_string, " (dec1 > dec2)\n";
  	}
	
	  
  	print"\nPerforming some mathematical operations:\n";
	
	# add
	
	# scale for arthmetical operations is determined by the object for which the method is called, here $sum	
	$sum->assign($dec[0]); # $sum = $dec[0]
	$sum->add($dec[1]);

	if (! $sum->is_valid) { # returns always true, forget this check
    	print "ERROR: scales of dec1 and dec2 are different.\n";
  	}	
	print "    ", $dec[0]->as_string, " + ", $dec[1]->as_string, " = ", $sum->as_string, " (sum = dec1 + dec2)\n";


	# sub
	
	# scale for arthmetical operations determined by the object for which the method is called, here $dif	
	$dif->assign($dec[0]); # $dif = $dec[0]
	$dif->sub($dec[1]);

	if (! $dif->is_valid) { # returns always true, forget this check
    	print "ERROR: scales of dec1 and dec2 are different.\n";
  	}	
	print "    ", $dec[0]->as_string, " - ", $dec[1]->as_string, " = ", $dif->as_string, " (dec1 - dec2)\n";

	# div
	
	# scale for arthmetical operations determined by the object for which the method is called, here $quot	
	$quot->assign($sum); # $dif = $sum
	$quot->div($dec[2]);

	if (! $quot->is_valid) { # returns always true, forget this check
    	print "ERROR: scales of sum and dec3 are different.\n";
  	}	
	print "    ", $sum->as_string, " / ", $dec[2]->as_string, " = ", $quot->as_string, " (sum / dec3)\n";


	# mul
	
	# scale for arthmetical operations determined by the object for which the method is called, here $prod	
	$prod->assign($sum); # $dif = $sum
	$prod->mul($dec[2]);

	if (! $prod->is_valid) { # returns always true, forget this check
    	print "ERROR: scales of sum and dec3 are different.\n";
  	}	
	print "    ", $sum->as_string, " * ", $dec[2]->as_string, " = ", $prod->as_string, " (sum * dec3)\n";
	
	
}#while


__END__
