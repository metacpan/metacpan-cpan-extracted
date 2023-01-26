package App::SeismicUnixGui::misc::geometry_pack;

# geometry  package
# Contains functions to do math with text
# files for geometries
# V 1. Nov 30  2007
# Juan M. Lorenzo
#

sub test {
    my ( $aref, $bref ) = @_;
    print "\t", $aref, " ", $bref, " in test sub\n";

    #return($aref,$bref);
}

sub offset {
    my (
        $ref_X_SP,   $ref_Y_SP,   $ref_Z_SP,   $num_SP,   $ref_SP,
        $ref_X_GEOP, $ref_Y_GEOP, $ref_Z_GEOP, $num_GEOP, $ref_GEOP
    ) = @_;

    # for each shotpoint estimate geophone-shot offsets WITHIN a SP gather

    for ( $j = 1 ; $j <= $num_SP ; $j++ ) {

        for ( $i = 1 ; $i <= $num_GEOP ; $i++ ) {

            $dist[$j][$i] =
              sqrt( ( $$ref_X_SP[$j] - $$ref_X_GEOP[$i] ) *
                  ( $$ref_X_SP[$j] - $$ref_X_GEOP[$i] ) +
                  ( $$ref_Y_SP[$j] - $$ref_Y_GEOP[$i] ) *
                  ( $$ref_Y_SP[$j] - $$ref_Y_GEOP[$i] ) +
                  ( $$ref_Z_SP[$j] - $$ref_Z_GEOP[$i] ) *
                  ( $$ref_Z_SP[$j] - $$ref_Z_GEOP[$i] ) );

            print("\n X of SP [$j] is $$ref_X_SP[$j] \n");

            #print("\n Y of SP [$j] is $$ref_Y_SP[$j] \n");
            #print("\n Z of SP [$j] is $$ref_Z_SP[$j] \n");
            print("\n X of GEOPHONE $i is $$ref_X_GEOP[$i] \n");

            #print("\n Y of GEOPHONE $i is $$ref_Y_GEOP[$i] \n");
            #print("\n Z of GEOPHONE $i is $$ref_Z_GEOP[$i] \n");
            print("\n SOURCE-to-GEOPHONE offset is $dist[$j][$i] \n");
        }

    }

    return ( \@dist );
}

sub offset_1to1 {
    my ($ref_X_SP)   = shift @_;
    my ($ref_Y_SP)   = shift @_;
    my ($ref_Z_SP)   = shift @_;
    my ($ref_X_GEOP) = shift @_;
    my ($ref_Y_GEOP) = shift @_;
    my ($ref_Z_GEOP) = shift @_;
    my ($num_rows)   = shift @_;

    # for each shotpoint estimate geophone-shot offsets WITHIN a SP gather
    print("Number of rows is $num_rows\n");

    #		print("\n Z of GEOPHONE [1] is $$ref_Z_GEOP[1] \n");
    #		print("\n Z of SP [1] is $$ref_Z_SP[1] \n");

    #		print("\n Z of GEOPHONE [2] is $$ref_Z_GEOP[2] \n");
    #		print("\n Z of SP [2] is $$ref_Z_SP[2] \n");
    for ( $j = 1 ; $j <= $num_rows ; $j++ ) {

        #		print("\n Z of GEOPHONE [$j] is $$ref_Z_GEOP[$j] \n");
        #		print("\n Z of SP [$j] is $$ref_Z_SP[$j] \n");

        $dist[$j] =
          sqrt( ( $$ref_X_SP[$j] - $$ref_X_GEOP[$j] ) *
              ( $$ref_X_SP[$j] - $$ref_X_GEOP[$j] ) +
              ( $$ref_Y_SP[$j] - $$ref_Y_GEOP[$j] ) *
              ( $$ref_Y_SP[$j] - $$ref_Y_GEOP[$j] ) +
              ( $$ref_Z_SP[$j] - $$ref_Z_GEOP[$j] ) *
              ( $$ref_Z_SP[$j] - $$ref_Z_GEOP[$j] ) );

        #print("\n X of SP [$j] is $$ref_X_SP[$j] \n");
        #		print("\n X of GEOPHONE [$j] is $$ref_X_GEOP[$j] \n");
        #print("\n SOURCE-to-GEOPHONE offset is $dist[$j]\n");
        #print ("Number of rows is $j\n");
    }

    return ( \@dist );
}
1;
