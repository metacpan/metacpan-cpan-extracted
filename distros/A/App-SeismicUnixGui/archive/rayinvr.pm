package rayinvr;

# rayinvr
# Contains methods/subroutines/functions to operate on rayinvr files
# V 1. Oct 14, 2008
# Juan M. Lorenzo

sub count_lines {

    # this function counts the numbers of lines in a text file
    my ($ref_origin) = shift @_;

    #print ("\nThe input file is called $$ref_origin\n");

    # open the file of interest
    open( FILE, $$ref_origin ) || print("Can't open $$ref_origin, $!\n");
    my @count = <FILE>;
    close(FILE);

    my $num_lines = @count;
    print("line number = $num_lines\n");

    return ($num_lines);
}

sub layers_vmodel {

    # this function extracts layers from a read v.in file

    ( $ref_line_array, $ref_length, $num_rows, $num_layers ) = @_;
    print("My file has $num_rows rows and $num_layers layers \n");

    # find continuation lines
    my $count_cont = 1;
    for ( $row = 1 ; $row <= $num_rows ; $row++ ) {
        $is = ( $row + 3 ) % 3;

#	print ("row is $row and is = $is iand line_array = $$ref_line_array[$row][1]\n");
        if ( $$ref_line_array[$row][1] == 1 && $is == 2 ) {
            $continuation_line[$count_cont] = $row;

#	print ("row is $row and is = $is iand line_array = $$ref_line_array[$row][1]\n");
            $count_cont++;
        }
    }
    $num_conts = $count_cont - 1;

    #	print("number of continuation lines = $num_conts\n");

    for ( $i = 1 ; $i <= $num_conts ; $i++ ) {
        $local_row      = $continuation_line[$i];
        $offset         = $$ref_length[$local_row] + 1;
        $num_new_values = $$ref_length[ $local_row + 3 ];
        print("row is $continuation_line[$i] and offset is $offset \n");

        for (
            $i = $offset, $j = 2 ;
            $i <= $offset + $num_new_values - 1 ;
            $i++, $j++
          )
        {

            $$ref_line_array[ $local_row - 1 ][$i] =
              $$ref_line_array[ $local_row + 2 ][$j];
            $$ref_line_array[$local_row][$i] =
              $$ref_line_array[ $local_row + 3 ][$j];
            $$ref_line_array[ $local_row + 1 ][$i] =
              $$ref_line_array[ $local_row + 1 ][$j];

            #		print("$$ref_line_array[$local_row-1][$i]\n");
            #		print("$$ref_line_array[$local_row][$i]\n");
            #		print("$$ref_line_array[$local_row+1][$i]\n");
        }
        $ref_length[ $local_row - 1 ] = $offset + $num_new_values - 1;
        $ref_length[$local_row]       = $offset + $num_new_values - 1;
        $ref_length[ $local_row + 1 ] = $offset + $num_new_values - 1;
    }

    for ( $i = 1 ; $i <= $offset + $num_new_values - 1 ; $i++ ) {
        print("$$ref_line_array[$local_row-1][$i]\n");
    }

    $local_row = $continuation_line[$j];

    for ( $j = 1 ; $j <= $num_conts ; $j++ ) {

        for ( $i = $local_row ; $i <= $num_rows - 3 ; $i = $i + 3 ) {

            for ( $k = 1 ; $k <= $$ref_length[ $local_row + 3 ] ; $k++ ) {
                $$ref_line_array[ $i + 1 ][$k] =
                  $$ref_line_array[ $local_row + 3 ][$k];
                $$ref_line_array[ $i + 2 ][$k] =
                  $$ref_line_array[ $local_row + 4 ][$k];
                $$ref_line_array[ $i + 3 ][$k] =
                  $$ref_line_array[ $local_row + 5 ][$k];

                $ref_length[ $i + 1 ] = $ref_length[ $i + 3 ];
                $ref_length[ $i + 2 ] = $ref_length[ $i + 4 ];
                $ref_length[ $i + 3 ] = $ref_length[ $i + 5 ];
            }

        }

        $local_row = $continuation_line[$j] - 3;
    }

    my $new_num_rows1 = $num_rows - ( $num_conts * 3 );
    return ();
}

sub read_vmodel {

    # this function reads v.in files

    my ($ref_origin) = shift @_;

    print("\n The input file is called $$ref_origin\n");

    # open the file of interest
    open( FILE, $$ref_origin ) || die("Can't open file_name, $!\n");

    # set the line counter
    my $row = 1;

    # read contents of file
    while ( $line = <FILE> ) {
        chomp($line);
        my (@line_array) = split( " ", $line );
        my $num_values = scalar @line_array;
        $num[$row] = $num_values;
		my $limit = $num_values;
		
        for ( $i = 0 ; $i <$limit; $i++ ) {
        	
            $A[$row][ $i + 1 ] = @line_array[$i];

            #print("$A[$row][$i]\n");
        }
        $row = $row + 1;
    }
    close(FILE);

    #	print("$A[1][1]\n");
    my $num_rows   = $row - 1;
    my @length     = @num;
    my $num_layers = ( $num_rows - 5 ) / 9;

    return ( \@A, \@length, $num_rows, $num_layers );
}

#sub write_vmodel_xgraph {
#
#    # this function writes v files for i/p to xgraph
#
#    # open and write to output file
#    my ( $ref_X, $ref_Y, $num_rows, $fmt, $ref_file_name ) = @_;
#
#    open(OUT,">$$ref_file_name") || die ("Can't open file_name, $!\n");
#
#    print("\nThe output file is called $$ref_file_name\n");
#
#    for ( $j = 0 ; $j < $num_rows ; $j++ ) {
#
#        printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j];
#        printf "$fmt\n", $$ref_X[$j], $$ref_Y[$j];
#    }
#
#    # open the file of interest
#
#    close(OUT);
#}

1;