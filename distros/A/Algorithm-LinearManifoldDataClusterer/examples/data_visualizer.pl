#!/usr/bin/perl -w

# visualizer.pl

use strict;
use File::Basename;
use Graphics::GnuplotIF;

die "Needs one command-line arg for the name of the data source" unless @ARGV == 1;

my $data_source = shift @ARGV;

data_visualizer( $data_source );

sub data_visualizer {
#    my $self = shift;
    my $datafile = shift;
    my $filename = File::Basename::basename($datafile);
    my $temp_file = "__temp_" . $filename;
    $temp_file =~ s/\.\w+$/\.txt/;
    unlink $temp_file if -e $temp_file;
    open OUTPUT, ">$temp_file"
           or die "Unable to open a temp file in this directory: $!";
    open INPUT, "< $filename" or die "Unable to open $filename: $!";
    local $/ = undef;
    my @all_records = split /\s+/, <INPUT>;
    my %clusters;
    foreach my $record (@all_records) {    
        my @splits = split /,/, $record;
        my $record_name = shift @splits;
        $record_name =~ /(\w+?)_.*/;
        my $primary_cluster_label = $1;
        push @{$clusters{$primary_cluster_label}}, \@splits;
    }
    foreach my $key (sort {"\L$a" cmp "\L$b"} keys %clusters) {
        map {print OUTPUT "$_"} map {"@$_\n"} @{$clusters{$key}};
        print OUTPUT "\n\n";
    }
    my @sorted_cluster_keys = sort {"\L$a" cmp "\L$b"} keys %clusters;
    close OUTPUT;   
    my $plot = Graphics::GnuplotIF->new( persist => 1 );
    my $arg_string = "";
    $plot->gnuplot_cmd( "set noclip" );
    $plot->gnuplot_cmd( "set hidden3d" );

#    my attempt to make a sphere look like a sphere:
#    $plot->gnuplot_cmd( "set view 70, 20" );
#    $plot->gnuplot_cmd( "set size 0.75, 1.70" );

    $plot->gnuplot_cmd( "set pointsize 2" );
    $plot->gnuplot_cmd( "set parametric" );
    $plot->gnuplot_cmd( "set size ratio 1" );
    $plot->gnuplot_cmd( "set xlabel \"X\"" );
    $plot->gnuplot_cmd( "set ylabel \"Y\"" );
    $plot->gnuplot_cmd( "set zlabel \"Z\"" );
    # set the range for azimuth angles:
    $plot->gnuplot_cmd( "set urange [0:2*pi]" );
    # set the range for the elevation angles:
    $plot->gnuplot_cmd( "set vrange [-pi/2:pi/2]" );
    # Parametric functions for the sphere
    $plot->gnuplot_cmd( "r=1" );
    $plot->gnuplot_cmd( "fx(v,u) = r*cos(v)*cos(u)" );
    $plot->gnuplot_cmd( "fy(v,u) = r*cos(v)*sin(u)" );
    $plot->gnuplot_cmd( "fz(v)   = r*sin(v)" );
#    my $sphere_arg_str = "fx(v,u),fy(v,u),fz(v),";
    my $sphere_arg_str = "fx(v,u),fy(v,u),fz(v) notitle with lines lt 0,";
#    foreach my $i (0..$self->{_number_of_clusters_on_sphere}-1) {
    foreach my $i (0..scalar(keys %clusters)-1) {
        my $j = $i + 1;
        # The following statement puts the titles on the data points
        $arg_string .= "\"$temp_file\" index $i using 1:2:3 title \"$sorted_cluster_keys[$i] \" with points lt $j pt $j, ";
#        $arg_string .= "\"$temp_file\" index $i using 1:2:3 notitle with points lt $j pt $j, ";
    }
    $arg_string = $arg_string =~ /^(.*),[ ]+$/;
    $arg_string = $1;
#    $plot->gnuplot_cmd( "splot $arg_string" );
    $plot->gnuplot_cmd( "splot $sphere_arg_str $arg_string" );
}
