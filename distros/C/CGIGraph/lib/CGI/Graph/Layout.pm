package CGI::Graph::Layout;
use CGI;
use GD;
use Data::Table;

my %default = ( columns => 119,
		height => 650,
		width => 850);

sub new {
	my ($pkg,$q) = @_;
	my $class = ref($pkg) || $pkg;
	my $table = Data::Table::fromCSV($q->param('source'));

	my $self = {CGI    => $q,
		    source => $q->param('source'),
		    myFile => $q->param('myFile'),
		    table  => $table};

	bless $self,$class;
	return $self;
}

sub header_bars {
	my $self = shift;
	my @header = $self->{table}->header;
	my %header=();
	my @Yheader=();
	for ($i=0; $i<scalar @header; $i++) {
		$header{$header[$i]} = substr($header[$i], 2);
		push @Yheader, $header[$i] if ($header[$i] =~ /^[ir]_/);
	}

	my $final = $self->{CGI}->scrolling_list("X",\@header,undef,1,0,\%header);
	$final .= "vs".$self->{CGI}->scrolling_list("Y",\@Yheader,undef,1,0,\%header) if @Yheader;
	return $final;
}

sub info_bar {
	$self = shift;
	my @header = $self->{table}->header;
	my %header;	
	foreach $header (@header) {
		$header{$header} = substr($header, 2);
	}

	my $final = "Pop-up info: ";
	$final .= $self->{CGI}->scrolling_list("info",\@header,undef,1,0,\%header);
	return $final;
}

sub zoom_bar {
	my $self = shift;
	my $final = "zoom factor ";
	$final .= $self->{CGI}->popup_menu(-name => "zoom",
				 -values   => [1,2,3,4,5],
				 -onChange => "this.form.submit()");
	return $final;
}

sub select_bars {
	my $self = shift;
	my $final;
        $self->{CGI}->delete('select_list');
        $final.= $self->{CGI}->scrolling_list(-name=>'select_list',
                                -values=>['--Select--','Visible','All'],
                                -default=>['--Select--'],
                                -size=>1,
                                -onChange => 'this.form.submit()');

        $self->{CGI}->delete('unselect_list');
        $final.= $self->{CGI}->scrolling_list(-name=>'unselect_list',
                                -values=>['--Unselect--','Visible','All'],
                                -default=>['--Unselect--'],
                                -size=>1,
                                -onChange => 'this.form.submit()');
	return $final;
}

sub zoom_type {
	my $self = shift;
	my $final = "bar zoom type<BR>";
	$final.= $self->{CGI}->radio_group(-name=> 'zoom_type',
                                              -values=> ['vertical lock','unlocked int','unlocked'],
                                              -default=> 'vertical lock',
					      -linebreak => 'true',
                                              -onClick=> "this.form.submit()");
	return $final;
}

sub histogram_type {
	my $self = shift;
	my $final = "histogram type<BR>";
	$final.= $self->{CGI}->radio_group(-name=> 'histogram_type',
                                              -values=> ['variable','fixed'],
                                              -default=> 'variable',
					      -linebreak => 'true',
                                              -onClick=> "this.form.submit()");
	return $final;
}

sub textbox {
	my $self = shift;
	my $cols = $self->{table}->nofCol;

	my $final = $self->{CGI}->textarea(-name     => 'myarea',
		                 -default  => '',
		                 -rows     => $cols,
	        	         -columns  => $default{columns});
	return $final;
}

sub icons {
	my ($self,$points,$bar,$save) = @_;
	my $final;

	if ($points) {
		$final = $self->{CGI}->image_button( -name => 'points',
	                        -src => $points,
	                        -onClick => "graph_type.value='points'");
	}

	else {
		$final = $self->{CGI}->submit(-name=>'points',
			        -value=>'Point Graph',
	                        -onClick => "graph_type.value='points'");
	}

	$final.= ' ';

	if ($bar) {
		$final.= $self->{CGI}->image_button( -name => 'bar',
	                        -src => $bar,
	                        -onClick => "graph_type.value='bar'");
	}

	else {
		$final .= $self->{CGI}->submit(-name=>'bar',
			        -value=>'Bar Graph',
	                        -onClick => "graph_type.value='bar'");
	}

	$final.= ' ';

	if ($save) {
		$final.= $self->{CGI}->image_button( -name => 'save',
	                        -src => $save);
	}

	else {
		$final .= $self->{CGI}->submit(-name=>'save',
			        -value=>'Save');
	}
	
	return $final;
}

sub view_button {
	my $self = shift;
	my $windowName = shift || "myWindow";
	my $width = shift || $default{width};
	my $height = shift || $default{height};

	my $source = $self->{source};
	my $myFile = $self->{myFile};
	my $X = $self->{CGI}->param('X');

	my $final = $self->{CGI}->button( -name  => 'open_select',
				-value => 'View Selected',
				-onClick => "x=window.open('selectTable.cgi?source=$source&myFile=$myFile&X=$X',
					    '$windowName',config='height=$height,width=$width,scrollbars=1,left=0,top=0');
					     x.focus()");
	return $final;
}

sub refresh_selected {
	my $self = shift;

	my $final = $self->{CGI}->checkbox(-name=>'refresh_display',
		-checked => 'checked',
		-label=>'Refresh Selected Values',
		-onClick => "this.form.submit()");

	return $final;
}

sub select_window {
	my $plot = shift;
	my $source = $plot->{source};
	my $myFile = $plot->{myFile};
	my $X = $plot->{X};
	my $rand = rand(localtime);

	my $final = '<SCRIPT LANGUAGE ="javascript">';
	$final.= "x=window.open('selectTable.cgi?source=$source&myFile=$myFile&X=$X&rand=$rand','myWindow',config='height=$default{height},$default{width},scrollbars=1,left=0,top=0')";
	$final.= "</SCRIPT>";

	return $final;
}

1;
