package App::SeismicUnixGui::misc::plot;

# Contains methods/subroutines/functions to  plot data
# V 1. Dec 10  2010
# Juan M. Lorenzo

sub Gnuplot_Geo_enz_file {

    my ($ref_file_name) = shift @_;

    open( GNUPLOT, "| /usr/bin/gnuplot -persist; unset term" );
    print( GNUPLOT "						\\
        set mouse verbose;					\\
        set term X11;						\\
	set autoscale;						\\
      	unset log ;						\\
      	unset label ;						\\
      	set xtic auto ;						\\
      	set ytic auto ;						\\
      	set key 0.01,100;					\\
      	set title \"Plot Source Geometry for $$ref_file_name\";	\\
      	set xlabel \"Easting UTM Z=15 (centimeters)\";		\\
      	set ylabel \"Northing (centimeters)\";			\\
	plot \"$$ref_file_name\" using 2:3 with points;		\\
        pause mouse;						\\
	\n"
    );
    close(GNUPLOT);
    print("\nGnu Plot of $$ref_file_name \n");

}

#set xr [709700:400];					\\
#set yr [0:400];						\\
sub Gnuplot_Sp_enz_file {

    my ($ref_file_name) = shift @_;

    #set term X11;						\\
    open( GNUPLOT, "| /usr/bin/gnuplot -persist; unset term" );
    print( GNUPLOT "						\\
        set mouse verbose;					\\
	set autoscale;						\\
      	unset log ;						\\
      	unset label ;						\\
      	set xtic auto ;						\\
      	set ytic auto ;						\\
      	set key 0.01,100;					\\
      	set title \"Plot Shotpoint Geometry for $$ref_file_name\";	\\
      	set xlabel \"Easting UTM Z=15 (centimeters)\";		\\
      	set ylabel \"Northing (centimeters)\";			\\
	plot \"$$ref_file_name\" using 2:3 with points;		\\
        pause mouse;						\\
	\n"
    );
    close(GNUPLOT);
    print("\nGnu Plot of $$ref_file_name \n");
}

sub Gnuplot_1col {

    my ($ref_file_name) = shift @_;

    #set term X11;						\\
    open( GNUPLOT, "| /usr/bin/gnuplot -persist; unset term" );
    print( GNUPLOT "						\\
        set mouse verbose;					\\
	set autoscale;						\\
      	unset log ;						\\
      	unset label ;						\\
      	set xtic auto ;						\\
      	set ytic auto ;						\\
      	set title \" $$ref_file_name\";				\\
      	set xlabel \"Xlabel\";					\\
      	set ylabel \"Ylabel\";				\\
	plot \"$$ref_file_name\" using 1 with points;		\\
        pause mouse;						\\
	\n"
    );
    close(GNUPLOT);
    print("\nGnu Plot of $$ref_file_name \n");

}

sub Gnuplot_2cols {

    my ( $ref_file_name, $xlabel, $ylabel ) = @_;

    #set logscale y ;					\\
    open( GNUPLOT, "| /usr/bin/gnuplot -persist; unset term" );
    print( GNUPLOT "						\\
        set mouse verbose;					\\
	set autoscale;						\\
      	unset label ;						\\
      	set xtic auto ;						\\
      	set ytic auto ;						\\
      	set title \"$$ref_file_name\";	\\
      	set xlabel \"$xlabel\";					\\
      	set ylabel \"$ylabel\";					\\
	plot \"$$ref_file_name\" using 1:2 with points;		\\
        pause mouse;						\\
	\n"
    );

    #set key 0.01,100;					\\
    close(GNUPLOT);
    print("\nGnu Plot of $$ref_file_name \n");

}

sub Gnuplot_3cols {

    my ( $ref_file_name, $xlabel, $ylabel, $zlabel ) = @_;

    #set logscale y ;					\\
    open( GNUPLOT, "| /usr/bin/gnuplot -persist; unset term" );
    print( GNUPLOT "						\\
        set mouse verbose;					\\
	set autoscale;						\\
      	unset label ;						\\
      	set xtic auto ;						\\
      	set ytic auto ;						\\
      	set key 0.01,100;					\\
      	set title \"$$ref_file_name\";	\\
      	set xlabel \"$xlabel\";					\\
      	set ylabel \"$ylabel\";					\\
      	set zlabel \"$zlabel\";					\\
	splot \"$$ref_file_name\" u 1:2:3 with linespoints;		\\
        pause mouse;						\\
	\n"
    );
    close(GNUPLOT);
    print("\nGnu Plot of $$ref_file_name \n");

}
1;
