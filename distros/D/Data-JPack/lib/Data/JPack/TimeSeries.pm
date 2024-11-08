package  Data::JPack::TimeSeries;
use strict;
use warnings;

use Data::JPack;
#basic container to display time series data in one or more graphs
#graphs are grouped by files, and can represent unrelated data from each other
#
#Data is converted into JPack/FastPack for webtech compatible local file loading

use strict;
use warnings;

use parent 'Data::JPack::Container';

use constant KEY_OFFSET=>Data::JPack::Container::KEY_OFFSET+Data::JPack::Container::KEY_COUNT;

use enum ();

use constant  KEY_COUNT=>0;

sub new {
	#need to include the modules to for loading and rendering FastPack data
	my $pack=shift;
	$pack->SUPER::new(@_);

	#TODO:
	#	options for splitting files
}

sub bootstrap {
	my $self=shift;
	$self->SUPER::bootstrap;
	$self->add_to_app("client/components/fastpack/fastpack.css");
	$self->add_to_app("client/components/fastpack/sprintf.min.js");
	$self->add_to_app("client/components/fastpack/channelmanager.js");
	$self->add_to_app("client/components/fastpack/typemap.js");
	#$self->add_to_app("typemap.js");
	my @scripts=qw<
		uPlot.iife.min.js
		uPlot.min.css
		stripplot.js
		otv.js
	       dataset.js
	>;
	#manifest.js
	#	otv.js
	#	typemap.js
	$self->add_to_app(map "client/components/fastpack/$_", @scripts);

	#1. Take a input jpack file,
	#split into smaller ones and store into output dir
	#Also need to add a typemap
}
sub body {
	my $self=shift;
	$self->[Data::JPack::Container::buffer_].=<<~EOF;
  <video id="frontvideo" src="front.mp4" style="display:none;"></video>
<video id="sidevideo" src="side.mp4" style="display:none;"></video>
<video id="otvvideo" src="otv.mp4" style="display:none;"></video>

<div id="top">
	<div id="leftvsp"></div>
	<div id="rightvsp"> </div>
</div>
<div id="bottom"></div>
EOF
}

sub add_from_csv {
	
}


#takes an input file,
#	-splits according to rules
#	-writes files to destination
#	-
sub add_from_fastpack {
	my $self=shift;
	my %options=@_;
	

}

1;

