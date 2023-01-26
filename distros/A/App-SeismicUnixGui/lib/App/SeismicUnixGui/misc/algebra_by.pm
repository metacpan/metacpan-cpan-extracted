package App::SeismicUnixGui::misc::algebra_by;

# perform matrix math on arrays by  class
# Contains methods/subroutines/functions to operate on directories
# V 1. April 15  2008
# Juan M. Lorenzo

sub rotate2 {

    # rotate an X,Y pair by rot radians. +ve CCW.   -ve CW
    # rotate a vector by rot radians. +ve CCW.      -ve CW

    my ( $ref_X, $ref_Y, $num_elements, $rot ) = @_;

    #print("\nrotation value is: $rot \n");
    #print("Number of row(s) is: $num_elements \n");

    my $cost = cos($rot);
    my $sint = sin($rot);

    #print("\ncos value is: $cost \n");
    #print("sin value is: $sint \n");
    for ( $i = 1 ; $i <= $num_elements ; $i++ ) {

        $X[$i] = $$ref_X[$i] * $cost - $$ref_Y[$i] * $sint;
        $Y[$i] = $$ref_X[$i] * $sint + $$ref_Y[$i] * $cost;

    }

    # make sure arrays do not contaminate outside
    my @XX = @X;
    my @YY = @Y;

    return ( \@XX, \@YY );

}

1;
