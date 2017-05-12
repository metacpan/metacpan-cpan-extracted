package CGI::Graph;

use Data::Table;
use CGI::Graph::Plot::points::numerical;
use CGI::Graph::Plot::points::string;
use CGI::Graph::Plot::bars::numerical;
use CGI::Graph::Plot::bars::string;

$VERSION = "0.93";
my $directory = ".";

sub new {
	my $vars = pop(@_);		

	my $table = Data::Table::fromCSV($vars->{source});
	my @header = $table->header;

	if (!($vars->{X})) {
		$vars->{X} = $header[0];	
	}

	if ($vars->{graph_type} eq 'bar') {
	        if ($vars->{X} =~ /^[ir]_/) {	
			return new CGI::Graph::Plot::bars::numerical($vars);
		}
		return new CGI::Graph::Plot::bars::string($vars);
	}

	#elsif ($vars->{graph_type} eq 'points') {
	else {
	        if ($vars->{X} =~ /^[ir]_/) {
			return new CGI::Graph::Plot::points::numerical($vars);
		}
		return new CGI::Graph::Plot::points::string($vars);
	}
}

sub newGraph {
	my ($vars) = @_;
	return new($vars);
}

sub table {
	my ($source,$myFile,$X) = @_;
	
	my $table = Data::Table::fromCSV($source);
	open INPUT, "$directory/$myFile";
	my $select = <INPUT>;
	close INPUT;
	chomp $select;
	my @select = split ("",$select);

	$displayTable = $table->rowMask(\@select, 0);
	$displayTable->sort($X, !($X=~/^[ir]_/), 0);
	
	return $displayTable;
}

1;


=head1 NAME

CGI::Graph - Create interactive CGI-based graphs

=head1 DESCRIPTION

This module creates CGI graphs which allow the user to visualize spreadsheet 
data using scatter plots, bar plots, histograms, etc. It provides features for 
easy interactions such as panning, zooming, element selection, and axis 
selection.

An input file in CSV format is used. Any column names should be preceded by 
a character identifying the type of that column and an underscore. For example, 
a set of integers called "age" should be in a column named "i_age". Currently, 
the only prefixes that are used are "i_" for integers and "r_" for real numbers. 
If the column is prefixed by another character, it is assumed to be a 
non-numerical data set.

An output file is used for storing selection values. This file contains a 
binary string, with each position in the string corresponding to a row from 
the input file. 0 is used for unselected elements, 1 for selected elements. 

Within the package, there are 2 different types of modules: Plot and Layout. 
The Layout module only provides functions relating to the placement of form
elements and icons. Classes derived from the Plot module are used to create
the various point and bar graphs.

For Plot modules, the only required values are the name of the input and output 
files. Other values such as the zoom factor or axes values are obtained from
the form elements of the CGI. See the field summary section for more details.
To create a new Plot object, a reference to a hash containing certain values is 
needed. The Vars() function (for CGI objects) can be used to easily obtain a 
hash containing all of these values. 

Once an object is created, a string of parameters can be generated that can be
passed to a CGI in order to output an image. The string is in the form 
key1=value1&key2=value2... and can easily be appended to the URL in an <img src>
tag. Separate images can be generated for a main view and a global (grid) view.
The main image can be augmented with an image map that allows selection of
elements. The global view is divided into a grid, which shows the main view in
relation to a default view displaying all elements. A user can click on a 
section of the grid to move the center of the main view.

Form elements provided by the Layout module allow the user to zoom in and out,
change axes, change graph types, and more.

The CGI::Graph::Plot module acts as a parent class for all graph types. From
this, the points and bars modules are derived. Finally, from each of those
modules, numerical and string modules are derived. 
CGI::Graph::Layout provides functions relating to the placement of form
elements and icons. 


		 Plot                          Layout
	       /      \                           |
	 points         bars                      |
	/ \             / \                       |
numerical string numerical string                 |
	|      \ /          |                     |
        +-------+-----------+                     |
                |                                 |
             CGI::Graph ----------> Driver.cgi <--+
		|
                +-> Draw.cgi
		+-> selectTable.cgi

                                 
                                   Driver.cgi
                                /       |      \
        [graph & grid parameters] [image maps] [selection info]
	 |                                            |
         +-> Draw.cgi                                 +-> selectTable.cgi
              |                                            |
              +-> graph image                              +-> selected elements
              +-> grid image                                   in html table

=over 4

=item B<CGI::Graph::Plot::points::numerical>

a point graph using a numerical X axis.

=item B<CGI::Graph::Plot::points::string>

a point graph using a non-numerical X axis.

=item B<CGI::Graph::Plot::bars::numerical>

a bar graph using a numerical X axis.

=item B<CGI::Graph::Plot::points::string>

a bar graph using a non-numerical X axis.

=back

=head1 SYNOPSIS

Sample Driver.cgi:

	use CGI::Graph;
	use CGI;

	$q = new CGI;
	$q->param('source','table.csv');   # assign specific parameters
	$q->param('myFile','select.dat');
	%hash = $q->Vars();		   # get hash from CGI object

	$plot = new CGI::Graph(\%hash);     # create new CGI::Graph object

	# specify dimensions for images and maps
	$graph_x_size = 500;
	$graph_y_size = 400;
	$grid_x_size = 250;
	$grid_y_size = 200;

	# obtain parameters to pass to cgi in order to generate graph image
        $graphParams = $plot->graphParams($graph_x_size,$graph_y_size);

	# print image source tag, appending graph parameters to URL
	print "<img src = Draw.cgi?$graphParams usemap=#imagemap width=$graph_x_size height=$graph_y_size border=0>\n";

	# output graph image map
	print $plot->graphMap($graph_x_size,$graph_y_size,$CGI_name);

	# obtain parameters to pass to cgi in order to generate grid image
        $gridParams = $plot->gridParams($grid_x_size,$grid_y_size);

	# print image source tag, appending grid parameters to URL
	print "<img src = Draw.cgi?$gridParams usemap=#gridmap width=$grid_x_size height=$grid_y_size border=1>\n";

	# output grid image map
	print $plot->gridMap($grid_x_size,$grid_y_size,$CGI_name);

Sample Draw.cgi

	use CGI::Graph;
	use CGI;
	use GD;

	$q = new CGI;

	%hash = $q->Vars;			# get hash from CGI object 
	my $plot = new CGI::Graph(\%hash);	# create new CGI::Graph object

	if ($q->param('grid')) {
	        $gd = $plot->drawGrid();	# create a gd object that represents the grid image
	}

	else {
	        $gd = $plot->drawGraph();	# create a gd object that represents the graph image
	}

	print $q->header('image/png');		# output image header
	binmode STDOUT;				# make sure that STDOUT is in binary mode
	print STDOUT $gd->png;			# output gd object in png format

=head1 REQUIRES

Perl 5.004 or greater, CGI, GD, GD::Graph, Data::Table

=head1 FIELD SUMMARY

=over 4

=item source I<string>

name of a CSV file used for input.

=item myFile I<string>

filename used for storing selection data.

=item X,Y I<string>

names of X and Y labels, which should correspond to columns of the table.

=item center I<int,int>

the current center value of the graph, in x,y format.

=item zoom I<int>

a value indicating the size of the current view window, 1 = full view, 
5 = maximum zoom.

=item divisions I<int>

the grid image is divided into divisions x divisions rectangles.

=item selected I<binary string>

each digit of the string corresponds to the selection value of the table row
at each index.

=item table I<Data::Table reference>

a reference to the Data::Table object read in from the source field.

=item width,height I<int>

width and height of main graph image and map

=item grid_width,grid_height I<int>

width and height of grid image and map

=item graph_type I<string>

indicates the type of graph. Currently, only "points" and "bar" are available.

=item zoom_type I<string>

indicates the type of zoom used for bar graphs. The default is "vertical lock",
where the vertical bounds are fixed regardless of zoom factor. Both "unlocked"
modes allow the user to change the upper bound, but the "unlocked int" mode
restricts the upper bound to an integer value.

=item histogram_type I<string>

indicates the type of histogram zoom, either "fixed" or "variable". Fixed zoom
functions similarly to the zoom style of other graph types. Variable zoom will
re-calculate the histogram of the smaller set of data which roughly corresponds
to the area in the view window.

=item dataColor,selectColor,lineColor,windowColor I<[red,green,blue], name, or hexadecimal>

indicates the color for data, selected values, grid lines, and the grid window. The value
is passed from the object as a hexadecimal value, but can be inputted as an array reference,
specific color name(see GD::Graph::colours), or hexadecimal value.

=item refresh_display I<on/undef>

the refresh_display value is stored so that it can be incoporated into the
mapInfo method.

=item x_min,x_max,y_min,y_max I<real>

minimum and maximum values for the current image or image map. Either indicates
a fractional value for elements to include or an actual mimimum or maximum.

=back

=head1 METHODS

=head2 Public Methods

=over 4

=item I<CGI::Graph::Plot::classname> CGI::Graph::Plot::classname::new($vars)

creates a new Plot. $vars is a hash reference that should contain the 
keys source and myFile. The source value is used as an input and should be a 
CSV file. The myFile value is used to store selection values. Optional keys are
the X and Y axes names, divisions, center, and zoom.

=item I<CGI::Graph::Plot::classname> CGI::Graph::new($vars)

creates a new Plot. Similar to the method above, but will automatically
choose an appropriate graph type.

=item I<void> Plot::all_values($filename,$size,$value)

$value is written $size number of times to the filename specified. (used to 
change all selection values to 0 or 1)

=item I<string> Plot->graphParams()

returns a string of the form key1=value1&key2=value2... used to pass values to
the CGI which draws the graph.

=item I<string> Plot->gridParams()

returns a string of the form key1=value1&key2=value2... used to pass values to
the CGI which draws the grid.

=item I<string> Plot->graphMap(width,height,name,mapname,info)

returns an image map which should correspond to the image generated by 
drawGraph. The dimensions width and height should be the same as those used by 
drawGraph. The name parameter should be the name of a textbox and will be used
to display the attributes of the element which the user moves the mouse over.
Mapname is the name of the image map, which should match the "usemap" parameter
in the <img src> tag. Info is an optional parameter which will select a data set
to pop up over an element (point graphs only).

=item I<string> Plot->gridMap()

return grid image map. Each area in the map contains the parameters used by the
current Plot, except that a different center is specified.

=item I<GD::Image> Plot->drawGraph()

Return graph image as a GD::Image object. 

=item I<GD::Image> Plot->drawGrid()

Return grid image as a GD::Image object. 

=back

=head2 Private Methods

=over 4

=item I<string> Plot::getValues($vars,@keys)

retrieves the values corresponding to @keys from the hash reference $vars. The
keys and values are returned in a string of the form key1=value1&key2=value2...

=item I<(int,int)> Plot::bounds(@numericalData)

given an array of numerical data, bounds will return a "nice" upper and lower
bound.

=item I<string> Plot->mapInfo()

mapInfo returns a string which represents the attributes of the Plot object.

=item I<void> Plot->write_selected()

writes the selection values of the Plot object to the file specified in the 
Plot object's myFile field.

=item I<(int,int,int)> Plot->resize()

returns the center and span of the current view, relative to the number of
divisions.

=item I<GD::Image> Plot->gridLines($image)

will add vertical and horizontal lines to an image, as well as a center marker
and a rectangle which acts as a view window.

=item I<varies> Plot->count(varies)

determines numerical X and Y data to be used in plotting the graph. Parameters
and return values differ for each of the different plot types. For example,
in a non-numerical bar graph, the occurences of each X value will be counted
and used as the Y value.

=item I<varies> Plot->valuesInRange(varies)

determines which X and Y elements should actually be plotted on the graph by
using the object's center and zoom values to calculate what should be in range.

=back

=head2 Layout Methods

=over 4

=item I<Layout object> Layout::new(CGI object)

creates a new Layout object. The CGI object must contain two parameters: source
and myFile. These two parameters should be the same as the ones contained in
the CGI::Graph::Plot object.

=item I<string> Layout->header_bars()

returns html to create two scrolling lists that contain the x and y column
names.

=item I<string> Layout->zoom_bar()

returns html to create a scrolling list with numbers 1-5.

=item I<string> Layout->select_bars()

returns html to create scrolling lists for select and unselect options.

=item I<string> Layout->zoom_type()

returns html for a radio group controlling zoom type for bar graphs.

=item I<string> Layout->histogram_type()

returns html for a radio group controlling the type of histogram for numerical
bar graphs.

=item I<string> Layout->textbox()

returns html for a textarea for displaying the attributes of elements.

=item I<string> Layout->icons($bar,$points)

returns html for image buttons used to determine graph type or saving data.
$bar and $points are optional filenames for alternate images.

=item I<string> Layout->view_button($windowName,$width,$height)

returns html for a javascript button that will open a window displaying
selected elements in an html table. $windowName is the name of the window
to be opened. $width and $height are its dimensions.

=item I<string> Layout->refresh_selected()

returns html for a checkbox which determines if the pop-up window displaying
selected elements is refreshed after each submission.

=item I<string> Layout->select_window($ref)

returns html containing javascript which opens a window displaying selected
elements in an html table. $ref must contain 

=back

=head1 AUTHORS

Max Chang E<lt>chang@gnf.orgE<gt> and Yingyao Zhou E<lt>zhou@gnf.orgE<gt>

=head1 SEE ALSO

CGI, GD, GD::Graph, Data::Table

=cut
