package Benchmark::Harness::Graph;
use GD::Graph::lines;
use strict;
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

### ################################################################################################
sub new {
    my $cls = shift;

    my $self = {
         'axislist'	=> []
		# Defaults that will be overridden by parameters given to this new()
		,'x_legend'  => 'Time - mins', 'x_pixels' => 600, 'y_pixels' => 300
		,'y1_legend' => 'Memory | MB', 'y1_min_value' => 0, 'y1_color' => '#ff0000'
		,'y2_legend' => 'CPU | %',     'y2_max_value' => 0, 'y2_color' => '#00dd00'
    };

	my @positionalParameterNames = qw(source x_pixels y_pixels x_max_value y1_max_value y2_max_value);
	for ( @_ ) {
		if ( ref($_) eq 'HASH' ) {
			for my $k ( keys %$_ ) {
				$self->{$k} = $_->{$k};
			}
		} else {
			$self->{shift @positionalParameterNames} = $_;
		}
	}

	# If no schema was named, try to extract it from the XML file.
	unless ( $self->{schema} ) {
		open TMP, "<$self->{source}" or die "Can't open $self->{source}: $!";
		while ( <TMP> ) {
			if ( m{xsi\:noNamespaceSchemaLocation=(['"])(.*?)\1} ) {
				my $attr = $2;
				$attr =~ m{([\w\d]+)\.xsd};
				$self->{schema} = $1;
				close TMP;
				last;
			}
		}
	}
	
    eval "use Benchmark::Harness::Graph::$self->{schema}";    die $@ if $@;
    my $graph = eval "new Benchmark::Harness::Graph::$self->{schema}(\$self)";	die $@ if $@;

	return $graph->generate();
}

### ################################################################################################
sub generate {
    my ($self) = @_;
    my $axislist = $self->{axislist};

    # Plot the graph.
    my $my_graph = new GD::Graph::lines($self->{x_pixels}, $self->{y_pixels});
	my ($x_axis, $y1_axis, $y2_axis) = ($axislist->[0], $axislist->[1], $axislist->[2]);

    $my_graph->set(
        'two_axes' => 1, #'no_axes' => 1,
        'x_label_skip' => 1,
        'y1_label_skip' => 1,
        'y2_label_skip' => 1,
        'title' => undef,				# as for the functions entry/exit lines, below.
        'x_ticks'  => 'true', 'x_tick_number' => 12,
        'y1_ticks' => 'true', 'y1_tick_number' => 12,
        'y2_ticks' => 'true', 'y2_tick_number' => 10,
        'transparent' => 1, 'box_axis' => 0, 'line_width' => 3,
      	'x_max_value'  => $self->{x_max_value},  'x_min_value'  => $self->{x_min_value},
      	'y1_max_value' => $self->{y1_max_value}, 'y1_min_value' => $self->{y1_min_value},
        'y2_max_value' => $self->{y2_max_value}, 'y2_min_value' => $self->{y2_min_value},
    );

    $my_graph->plot([$x_axis->{data}, $y1_axis->{data}, $y2_axis->{data}]) or die $my_graph->error;

    # Plot the function entries / exits
    $my_graph->set(
        'two_axes' => 1, 'no_axes' => 0,
        'x_label_skip'  => 1,
        'y1_label_skip' => 1,
        'y2_label_skip' => 1,
        'title' => undef,
        'x_ticks'  => 'true', 'x_tick_number' => 12,
        'y1_ticks' => 'true', 'y1_tick_number' => 12,
        'y2_ticks' => 'true', 'y2_tick_number' => 10,
        'transparent' => 1, 'box_axis' => 0, 'line_width' => 2,
    );

    my @needsLegends = ( $x_axis, $y1_axis, $y2_axis ); # We'll build legends from this array later.
    my @funcDataColors = ($y1_axis->{color}); # $graph->plot() needs this, below.

    # Plot the function entries / exits
	my @nullAxis; map { push @nullAxis, undef } @{$x_axis->{data}};
	my $allAxis = [$x_axis->{data}, \@nullAxis];
    for (my $axisIdx = 3; $axisIdx < $#{$axislist}; $axisIdx += 1 ) {
		my $axis = $axislist->[$axisIdx];
		push @needsLegends, $axis;

        my $funcData = $axis->{data};
        push @funcDataColors, $axis->{color};
		$self->Normalize($y1_axis);
		push @$allAxis, $axis->{data};
	}
	$my_graph->set( dclrs => \@funcDataColors);
	$my_graph->plot($allAxis) or die $my_graph->error;

    my $ext = $my_graph->export_format;
    my $filnam = "$self->{source}";
    $filnam =~ s{\.[\w\d]+$}{};
    open(PNG, ">$filnam.$ext") or die "Cannot open '$filnam.$ext' for write: $!";
    binmode PNG;
    print PNG $my_graph->gd->$ext();
    close PNG;
	$self->{graphFilename} = "$filnam.$ext";

	# Here is our HTML output file
	$self->{outFilename} = "$filnam.htm";
    open HTM, ">$self->{outFilename}";
    
	print HTM '<html><head>';
	# Print any script (e.g., javascript) into the <head>
	print HTM $self->htmlScript();
	# Print any style (e.g., css) into the <head>
	print HTM $self->htmlStyle();
	print HTM '</head><body>';
	
	# print <img> of the graph and the legends surrounding it.
	print HTM $self->htmlGraph();
	print HTM '<tr><td align=center colspan=5><iframe id=detailview src=benchmarkHarnessGraphNullFrame.htm frameborder=0 height=80 width=500></iframe></td></tr>';

	print HTM <<EOT;
<tr><td colspan=5><table width=100% align=center>
<tr>
	<td width=60%>Subroutine</td>
	<td align=right width=10%>first</td>
	<td align=right width=10%>last</td>
	<td align=right width=10%>count</td>
	<td align=right width=10%>total tm</td>
</tr>
EOT

    for (my $axisIdx = 3; $axisIdx < $#{$axislist}; $axisIdx += 1 ) {
		my $axis = $axislist->[$axisIdx];
		my $color = $axis->{color} || 'black';
		my $countEntry = $axis->{count_entry};
		my $firstEntry = int($axis->{first_entry}+0.50);
		my $lastEntry = int($axis->{last_entry}+0.50);
		my $totalTime = int(($axis->{total_time}*100)+0.50)/100;
        print HTM <<EOT;
<tr>
<td><font color='$color'><b>$axis->{legend}</b></font></td>
<td align=right>$firstEntry</td>
<td align=right>$lastEntry</td>
<td align=right>$countEntry</td>
<td align=right>$totalTime</td>
</tr>
EOT
    }
    print HTM '</table></td></tr></table>';

	my $hotspotText = '';
	print HTM '<map NAME="clientsidemap" ID="clientsidemap">'."\n";
    for (my $axisIdx = 3; $axisIdx < $#{$axislist}; $axisIdx += 1 ) {
		my $axis = $axislist->[$axisIdx];
		map {
			print HTM <<EOT;
<area SHAPE="rect" COORDS="$_->[1],$_->[2],$_->[3],$_->[4]" HREF="javascript:ShowDetail($axisIdx)">
EOT
			$hotspotText .= $self->hotspotText($axislist, $axisIdx);
		} @{$self->collapseArea($my_graph->get_hotspot($axisIdx-1))};
	} 														 # ^^ $my_graph currently holds one less axis than axislist.
	print HTM "</map>\n$hotspotText";

	print HTM '</body></html>';
    close HTM;

	my $nullHtmName = $self->{outFilename};
	$nullHtmName =~ s{^(.*?)(?:(/)[^/]*)?$}{$1$2benchmarkHarnessGraphNullFrame.htm};
	unless ( -f $nullHtmName ) {
		open HTM, '>'.$nullHtmName;
		print HTM <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html><head></head>
<body marginWidth='2' marginHeight='2'>
	<b>Click on a horizontal subroutine line to display its details here.</b>
</body></html>
EOT
		close HTM;
	}

	return $self;
}

### ################################################################################################
### Normalize additional "Y" lines to fit the originally graphed Y1 line.
sub Normalize {
	my ($self, $axis) = @_;
	
	$axis->{max_value} = $axis->Max($axis) unless $axis->{max_value};
	$axis->{min_value} = $axis->Min($axis) unless $axis->{min_value};
	
	my $norm = ($self->{y1_max_value}-$self->{y1_min_value}) / ($axis->{max_value}-$axis->{min_value});
	return if $norm == 1;
    map { $_ *= $norm if defined($_) } @{$axis->{data}};
	$axis->{min_value} *= $norm;
	$axis->{max_value} *= $norm;
}

### ################################################################################################
### Return the <div> representing what gets displayed by hotspot click.
### Put this in a display:none element so it shows only via <script> control.
sub hotspotText {
	my ($self, $axislist, $idx) = @_;
	return <<EOT;
<div id=hs_$idx style='position:absolute;display:none;top:0;left:0;'>$axislist->[$idx]->{legend}</div>
EOT
}


### ################################################################################################
### Take GD::Graph's hotspot output and project it to the smallest array.
sub collapseArea {
	my $self = shift;
	my $answer = [];
	my $thisSpot = undef;
	for ( @_ ) {
		if ( defined $thisSpot ) {
			if ( defined($_) && ($thisSpot->[3] == $_->[1]) ) {
				$thisSpot->[3] = $_->[3];
			}
			else {
				push @$answer, $thisSpot;
				$thisSpot = undef;
			}
		}
		else {
			if ( defined $_ ) {
				$_->[2] -= 1;
				$_->[4] += 1;
				$thisSpot = $_;
			}
		}
	}
	push @$answer, $thisSpot if defined $thisSpot;
	return $answer;
}

### ################################################################################################
### Return the entire <script> element to insert in the html <head>
sub htmlScript {
	<<EOT;
<script language=javascript>
function ShowDetail (idx) {
	var detail = document.getElementById("hs_"+idx);
	if ( detail == null ) return;
	var iframe = document.getElementById("detailview");
	iframe.contentWindow.document.body.innerHTML = detail.innerHTML;
}
</script>
EOT
}

### ################################################################################################
### Return the entire <style> element to insert in the html <head>
sub htmlStyle {
	<<EOT;
<style>
<!--
.x_legend {
	font-weight: bold;
	text-align: center;
}
.y1_legend {
	font-weight: bold;
	font-size: 12;
	text-align: center;
	vertical-align: middle;
	text-color: green;
}
.y2_legend {
	font-weight: bold;
	font-size: 12;
	text-align: center;
	vertical-align: middle;
	text-color: red;
}
-->
</style>
EOT
}

### ################################################################################################
### Return the entire <table> element, up to end of graph area, to insert in the html <body>
sub htmlGraph {
	my $self = shift;

	my ($href) = ($self->{graphFilename} =~ m{([^/]*)$});
	
	my $x_legend = $self->{x_legend}   || 'Time';
	my $y1_legend = $self->{y1_legend} || 'Memory';
	$y1_legend =~ s{(.)}{$1<br>}g;
	my $y2_legend = $self->{y2_legend} || 'CPU';
	$y2_legend =~ s{(.)}{$1<br>}g;
	
	<<EOT;
<table width=700 align=center cellspacing=10>
<tr>
	<td width=6% class=y1_legend><font color='$self->{y1_color}'>$y1_legend</font></td>
	<td width=4%>&nbsp;</td>
	<td align=center><img src="$href" USEMAP="#clientsidemap" border=0></td>
	<td width=4%>&nbsp;</td>
	<td width=6% class=y2_legend><font color='$self->{y2_color}'>$y2_legend</font></td>
</tr>
<tr><td colspan=3 class=x_legend>$x_legend</td></tr>
EOT
}


### ################################################################################################
### ################################################################################################
### ################################################################################################
package Benchmark::Harness::GraphLineData;
use strict;

### ################################################################################################
# new($legend, $color)
sub new {
    return bless
    {
         'data'       => $_[1]
        ,'legend'     => $_[2]
        ,'color'      => $_[3]
        ,'line_width' => defined($_[4])?$_[4]:1
    }
}

### ################################################################################################
sub Max {
    my ($data, $max) = ($_[0]->{data}, -999999999);
    map { do {$max = ($max > $_)?$max:$_} if defined $_} @$data;
    return $max;
}
### ################################################################################################
sub Min {
    my ($data, $min) = ($_[0]->{data}, 999999999);
    map { do {$min = ($min < $_)?$min:$_} if defined $_} @$data;
    return $min;
}


### ################################################################################################
### ################################################################################################
### ################################################################################################
package Benchmark::Harness::SAX::Graph;
use Benchmark::Harness::SAX;
use base qw(Benchmark::Harness::SAX);
use strict;

## #################################################################################
sub new {
    my $self = bless shift->SUPER::new(	# Checks validity of global static
		{								# context and adds these attributes
             'capture' => []
            ,'data'    => []
            ,'subroutines' => []
        }
	);

    map {
        push @{$self->{capture}}, $_;	# Record the attributes we want to capture,
        push @{$self->{data}}, [];		# and instantiate an array for each one.
    } @_;

    return $self;
}

sub start_element {
    my ($self, $saxElm) = @_;

    if ( my $tagName = $self->SUPER::start_element($saxElm) ) { # Capture the standard elements (e.g., <ID>);
		if ( ($$tagName eq 'T') ) {	 # was not captured by SUPER, so maybe it's ours?
			my $capture = $self->{capture};
			my $data    = $self->{data};
			for (my $idx = 0; $idx < scalar @$capture; $idx++ ) {
				push @{$data->[$idx]}, $saxElm->{Attributes}->{'{}'.$capture->[$idx]}->{Value};
			};
		}
	}
}

1;