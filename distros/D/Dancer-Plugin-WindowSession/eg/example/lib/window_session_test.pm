package window_session_test;
use Dancer ':syntax';
use Dancer::Plugin::WindowSession ;
use strict;
use warnings;
use Cwd;
use Carp;
use GD::Graph;
use GD::Graph::bars;
use GD::Graph::pie;
use GD::Graph::lines;
use GD::Graph::points;
use GD::Graph::area;


my @plot_data = (
	[ "2004","2005","2006","2007","2008","2009","2010","2011","2012" ],
	[ 38,     58,   1,      16,   260,   6,     28,     25,   87 ]
);

get '/' => sub {
	my $username = (session 'username') || "New User";
	session 'username' => $username;

	template 'index' ;
};

get '/image.png' => sub {
	my $img_width  = window_session('plot_width') || 400 ;
	my $img_height = window_session('plot_height') || 300 ;
	my $plot_type  = window_session('plot_type') || "bars";
	my $plot_color = window_session( 'plot_color') || "blue" ;

	my $g;
	if ($plot_type eq "bars") {
		$g = GD::Graph::bars->new($img_width,$img_height);
	} elsif ( $plot_type eq "lines" ) {
		$g = GD::Graph::lines->new($img_width,$img_height);
	} elsif ( $plot_type eq "area" ) {
		$g = GD::Graph::area->new($img_width,$img_height);
	} elsif ( $plot_type eq "points" ) {
		$g = GD::Graph::points->new($img_width,$img_height);
	} elsif ( $plot_type eq "pie" ) {
		$g = GD::Graph::pie->new($img_width,$img_height);
	} else {
		die "Error: unknown plot type '$plot_type'";
	}

	$g->set(
			title => "Thingamjigs per Year",
			x_label => "Years",
			y_label => "Thingamjigs")
		or die $g->error;

	$g->set ( dclrs => [ $plot_color ] )
		or die $g->error;

	header('Content-Type' => 'image/png' );
	return $g->plot(\@plot_data)->png();
};

## The user wants to change settings, show the <form>
get '/settings' => sub {
	template 'settings' ;
};

## The user submitted changes,
## Save the variables to session & window_session hashes,
## and redirect back to the main page.
post '/settings' => sub {

	## Get the variables, as submitted by the user
	## NOTE: This is just a demo, so no input validation is performed.
	my $username   = param('username') || "Unknown User";
	my $plot_type  = param('plot_type') || "bars" ;
	my $plot_color = param('plot_color') || "blue";
	my $plot_width = param('plot_width') || 400 ;
	my $plot_height= param('plot_height') || 300 ;

	# Save the username as a session variable
	session 'username' => $username;

	# Save the plot settings as a window-setting variables.
	window_session 'plot_type' => $plot_type;
	window_session 'plot_color' => $plot_color;
	window_session 'plot_width' => $plot_width;
	window_session 'plot_height' => $plot_height;

	## NOTE:
	## We must pass-on the 'winsid' CGI variable
	## in every URL we use.
	my $winsid = window_session_id;
	redirect "/?winsid=$winsid";
};

true;
