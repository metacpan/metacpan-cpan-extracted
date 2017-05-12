#!/usr/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Data::Table;
use CGI::Graph;
use CGI::Graph::Layout;

# Make sure that a data file exists. Try using "example.dat" as a test
# case. You will also need to specify a file where selection data can be
# stored, and may need to change the write permissions for this file.

$q = new CGI;

# explicitly set source, myFile, and graph_type parameters
$q->param('source','example.dat');
$q->param('myFile','selection.dat');
$q->param('graph_type','points') unless ($q->param('graph_type'));

# if save icon has been clicked on, then return selection table in csv format

if ($q->param('save') || $q->param('save.x')) {
	print "Content-type: application/octet-stream\n";
	print "Content-disposition: filename=project.csv\n\n";
        $displayTable = CGI::Graph::table($q->param('source'),$q->param('myFile'),
                $q->param('X'));
        print $displayTable->csv;
        exit;
}

print $q->header;
print $q->start_html(-title=>'CGI::Graph Sample');
print $q->startform("post", "Sample.cgi", "", "name='myform'");

# create a new Layout object using the CGI object
$page = new CGI::Graph::Layout($q);

# update selection values if necessary
CGI::Graph::Plot::all_values($page->{myFile},$page->{table}->nofRow(),0) if
($q->param(unselect_list) eq 'All' ); # all unselected - set values to 0
CGI::Graph::Plot::all_values($page->{myFile},$page->{table}->nofRow(),1) if
($q->param(select_list) eq 'All');    # all selected - set values to 1

# get hash containing all parameters from CGI object
%hash = $q->Vars;

# create a new Plot object by calling new function
# and passing in hash reference containing CGI parameters
$plot = new CGI::Graph(\%hash);
 
# obtain parameters for main image and global view
$graphParams = $plot->graphParams();
$gridParams = $plot->gridParams();

print "<TABLE border=1>\n";
print "<TR>\n";
print "<TD ALIGN=\"center\" ROWSPAN=\"4\">";

# html tag for main image, passing in parameters
print "<img src = Draw.cgi?$graphParams usemap=#imagemap width=500 height=400 border=0>\n";
print "</TD>\n";
print "<TD ALGIN=\"center\" COLSPAN=\"2\">";

# html tag for global view, passing in parameters
print "<img src = Draw.cgi?$gridParams usemap=#gridmap width=250 height=200 border=1>\n";
print "</TD></TR>\n";
print "<TR>\n";
print "<TD COLSPAN=\"2\">";

# output scrolling lists containing axis labels
print $page->header_bars();

# create submit button
print $q->submit(-name=>'act',-value=>'Submit');
print "<BR>";
print "<HR>";

# output scrolling list with zoom factor options
print $page->zoom_bar();

# output scatter plot, bar graph, and disk icons
print $page->icons()," ";

# create reset button
print $q->defaults('RESET');
print "</TD>";
print "</TR>\n";
print "<TR>\n";
print "<TD COLSPAN=\"2\">";

# output scrolling lists with select/unselect options
print $page->select_bars();
print "<HR>";

# output checkbox for refreshing selection window
print $page->refresh_selected," ";

# output button for viewing selection window
print $page->view_button("myWindow",850,650);
print "</TD>\n";
print "</TR>\n";
print "<TR>";

# for bar graphs, output zoom type options
if ($plot->{graph_type} eq 'bar') {
        print "<TD>";
        print $page->zoom_type();
        print "</TD>";

        # for numerical bar graphs, output histogram type options
        if ($plot->{X} =~ /^[ir]/) {
		print "<TD>";
                print $page->histogram_type();
                print "</TD>";
        }

}

print "</TR>";
print "<TR>\n";
print "<TD ALIGN=\"center\" COLSPAN=3>";

# output textbox for displaying element attributes
print $page->textbox();
print "</TD>\n";
print "</TR>\n";
print "</TABLE>\n";

# if the refresh_display box is checked, re-open selection window
if ($q->param('refresh_display')) {
        print CGI::Graph::Layout::select_window($plot);
}

# output image maps for main image and global view
print $plot->graphMap("Sample.cgi","imagemap");
print $plot->gridMap("Sample.cgi","gridmap");

# preserve attributes not determined by form elements
$q->delete('center');
print $q->hidden('center',$plot->{center});
print $q->hidden('graph_type',$q->param('graph_type'));
print $q->hidden('source',$q->param('source'));
print $q->hidden('myFile',$q->param('myFile'));
print $q->hidden('height',$q->param('height'));
print $q->hidden('width',$q->param('width'));
print $q->hidden('grid_height',$q->param('grid_height'));
print $q->hidden('grid_width',$q->param('grid_width'));
print $q->hidden('dataColor',$q->param('dataColor'));
print $q->hidden('selectColor',$q->param('selectColor'));
print $q->hidden('lineColor',$q->param('lineColor'));
print $q->hidden('windowColor',$q->param('windowColor'));

print $q->endform;
print $q->end_html;
