#! perl -w
 
 use Mac::DtfSQL qw(:all);
 
 # create objects
   $dec1 = Mac::DtfSQL->new_decimal; 
   $dec2 = Mac::DtfSQL->new_decimal; 

 # equal
   $dec1->from_string('4000');
   $dec2->from_string('4000.0');
   if ($dec1->equal($dec2)) { # 4000 != 4000.0, because the scales don't match (autsch) 
        print "4000 == 4000.0 \n";
   } else {
        print "4000 != 4000.0 \n";
   }

 # multiplication 
 
 # Note: The scale for an arithmetical operation is determined by the object for which 
 #       the method is called, 0 in the following example
 
   $dec1->from_long(660000);   # 660,000, scale = 0
   $dec2->from_string('0.75'); # 0.75, scale = 2
  
   # wrong
   $dec1->mul($dec2) || die "Error multiplicating decimal"; 
   # == 660,000 and should be 495,000 (autsch) 
   # internally, 0.75 seems to be rounded to 1 (scale 0), 
   # *BUT* no error is returned (and this is the crux)
   
   print $dec1->as_string, " (and should be 495,000)\n";
 
   $dec1->from_long(660000);   # 660,000, scale = 0
   $dec2->from_string('0.75'); # 0.75, scale = 2
  
   # right
   $scale1 = $dec1->get_scale;
   $scale2 = $dec2->get_scale;
   if ( $scale1 > $scale2 ) {
       $dec2->set_scale( $scale1 );
   } else {
       $dec1->set_scale( $scale2 );
   }
   $dec1->mul($dec2); # == 495,000.00 (ok)
   print $dec1->as_string, " (ok)\n";
  
 # addition scale overflow 
 
 # Note: The scale for an arithmetical operation is determined by the object for which 
 #       the method is called, 15 in the following example
 
   $dec1->from_string('0.000000000000001') || die "Error creating decimal"; # decimal (16,15)
   $dec2->from_string('100.50') || die "Error creating decimal";; # decimal (5,2)
 
   $dec1->add($dec2) || die "Error adding decimal"; 
                     
   # result == 0.500000000000001 and should be 100.500000000000001
   # precision/scale overflow, because a decimal (18,15) would be needed,
   # *BUT* no error is returned (and this is the crux);
   # indeed, if you convert the decimal to a double value, you will
   # get 100.5 as a result, i.e. there is no value overflow internally
 
   print $dec1->as_string, " and should be 100.500000000000001\n";   
   $doubleVal = $dec1->to_double;
   print "converted to a double Value =  $doubleVal \n"; 


# No error is returned if you set the scale to a value out of the 0 .. 15 range   
   
   $dec1->set_scale(16) || die "Scale out of range"; # doesn't die
   print "scale = ", $dec1->get_scale, "\n";
   $dec1->is_valid ? print "Decimal is valid\n" : print "Decimal is not valid\n";   
   print $dec1->as_string, " \n";
   