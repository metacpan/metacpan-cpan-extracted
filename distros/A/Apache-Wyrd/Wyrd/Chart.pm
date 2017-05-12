use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Chart;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use GD::Graph;
use GD::Graph::colour qw(:colours :convert :lists);
use Apache::Wyrd::Services::SAK qw(:tag :file token_parse token_hash);
use Digest::SHA qw(sha1_hex);
use Data::Dumper;

=pod

=head1 NAME

Apache::Wyrd::Chart - Embed Dynamically-redrawn charts in HTML

=head1 SYNOPSIS

  <BASENAME::Chart img="chart.png" type="bars" height="200" width="300">
    <BASENAME::Query>
      select month, price
      from monthly_prices
      order by month
    </BASENAME::Query>
  </BASENAME::Chart>

=head1 DESCRIPTION

Chart-graphic Wyrd wrapping the C<GD::Graph> Module.  Creates a graphic file
(PNG) and a meta-data file based on data handed it to by an
C<Apache::Wyrd::Query> Wyrd.

=head2 HTML ATTRIBUTES

The Chart Wyrd accepts nearly all the attributes of the GD::Graph module and the
E<lt>imgE<gt> tag, producing an E<lt>imgE<gt> tag which points to the
graphic file produced by GD::Graph, having most attributes (such as onClick,
border, but not src) given to the Chart Wyrd.

=over

=item Wyrd attributes:

=over

=item data_col

Which column of the query to plot.  Default: 2.

=item labels

A comma or whitespace-separated list of label names.  If not enough labels
are given, the remainder will be labeled "unknown"

=item label_col

Which column of the query to use for labels.  Default: 1.

=item other_limit

Items with values under this number will be lumped together under the item
name "Other".

=item label_filters, value_filters

A whitespace or comma delineated list of builtin filters to apply to the
labels or values respectively.  Current filters:

=over

=item zero

Replace undefined values with 0.

=item dollar_sign

Put a dollar sign to the left

=item percent_sign

Put a percent sign to the right

=item commify

Put numbers into (north american style) comma splits, i.e. 3,000,000 for 3E6

=back

=item Flags

=over

=item nochache

Always generate the graphic, instead of checking to see if it has changed

=item percent

Convert values to percentages of total

=item rotate

Pivot the table returned by the query to make X Y and vice-versa

=item value_labels

Add the value to the label, as in "Foobars (2), Widgets (23)"


=back

=back

=over

=item IMG-style attributes:

=over

=item height, width, vspace, border, hspace

In pixels, as per IMG tag

=item src

Required - Where (document-root-relative) the graphic is to appear. 
Currently must end with .png.

=back

=item GD::Graph-style attributes

See GD::Graph documentation for more details.  Files are always
document-root-relative.  Colors may be in GD::Graph name format or in  in
HTML "#XXXXXX" format.  Edge-positions are in the GD::Graph standard of UL
for Upper-Left, LL for Lower-Left, etc.  1 is the usual value for "yes" in
boolean attributes.  Lists are in a whitespace-separated or comma-separated
list of items (using Apache::Wyrd::Services::SAK::token_parse).  Angles are
in degrees.

=over

=item type

What type of graph, per the GD::Graph subclasses.  Valid types are: lines,
hbars, bars, points, linespoints, area, or pie

=item b_margin t_margin l_margin r_margin

edge-to-graphic margins

=item transparent interlaced

PNG options

=item bgclr fgclr boxclr textclr labelclr axislabelclr legendclr valuesclr
accentclr shadowclr

Colors for the respective chart elements

=item dclrs borderclrs

Data element and border colors, in list format.

=item show_values values_vertical values_space values_format

Whether (1=yes) to show values, whether vertically, what space (pixels)
around them and what (sprintf-style) format to display them in.

=item logo logo_position logo_resize

logo file, corner for logo, and resize factor

=item legend_placement legend_spacing legend_marker_width
legend_marker_height lg_cols

Legend attributes (axestype graphs only)

=item x_label y_label box_axis two_axes zero_axis zero_axis_only
x_plot_values y_plot_values y_max_value y_min_value x_tick_number
x_min_value x_tick_number x_min_value x_max_value y_number_format
x_label_skip y_label_skip x_tick_offset x_all_ticks x_label_position
y_label_position x_labels_vertical long_ticks tick_length x_ticks
y_tick_number axis_space text_space

Axis attributes (for applicable chart types)

=item overwrite bar_width bar_spacing shadow_depth borderclrs cycle_clrs
cumulate

Bar-chart attributes, foo_clrs are lists.  Cumulate is boolean, and means to
stack values within a bar

=item line_types line_type_scale line_width skip_undef

Line-chart attributes.  Line types are 1: solid, 2: dashed, 3: dotted, 4:
dot-dashed.  skip_undef leaves a gap for an undefined point

=item markers marker_size

Marker types (1: filled square, 2: open square, 3: horizontal cross, 4:
diagonal cross, 5: filled diamond, 6: open diamond, 7: filled circle, 8:
open circle, 9: horizontal line, 10: vertical line) and size (in pixels)

=item 3d pie_height start_angle suppress_angle

Pie chart attributes.  suppress_angle is a limit below which no line is
drawn

=item legend_font title_font x_label_font y_label_font x_axis_font
y_axis_font

Fonts.  Either a file (if your system supports TTF) or one of the builtin
fonts: gdTinyFont gdSmallFont gdMediumBoldFont gdLargeFont gdGiantFont

=back

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=cut

sub _file_problems {
	my ($self, $file) = @_;
	if (-f $file) {
		$self->_error("$file is not writable.  Updates will fail.") unless (-w _);
	} else {
		my $dir = $file;
		$dir =~ s/[^\/]+$//;
		$self->_raise_exception("$dir is not writable") unless (-w $dir);
	}
}

sub _ok_font {
	my ($self, $font) = @_;
	if ($font =~ /\//) {
		#font is a file
		unless ($self->{'_ttf_support'}) {
			$self->_error("Font requested: $font, but no TTF support");
			return;
		}
		#warn $font;
		my $root = $self->dbl->req->document_root;
		return "$root$font" if (-f "$root$font" and -r _);
		$self->_error("Font requested: $font, but the file doesn't exist or can't be read");
		return;
	}
	return $font if (grep {$font eq $_} @{$self->{'_valid_attributes'}->{'builtin_fonts'}});
	return;
}

sub _image_template {
	my ($self) = @_;
	my $template = attopts_template(@{$self->{'_valid_attributes'}->{'img'}});
	return '<img src="$:src"' . $template . '>';
}

sub _get_graph {
	my ($self) = @_;
	my $type = $self->{'type'};
	my $graph = undef;
	if ($type =~ /^(lines|hbars|bars|points|linespoints|area|pie)$/) {
		eval("use GD::Graph::$type");
		$self->_raise_exception($@) if ($@);
		my $height = ($self->{'height'} || 300);
		my $width = ($self->{'width'} || 400);
		eval("\$graph = GD::Graph::$type->new(\$width, \$height)");
		$self->_raise_exception($@) if ($@);
	} else {
		$self->_raise_exception("Chart type \"$type\" not supported.");
	}
	$self->{'_ttf_support'} = $graph->can_do_ttf;

	my @builtin_colors = GD::Graph::colour::colour_list;
	my @color_attribs = @{$self->{'_valid_attributes'}->{'color_attr'}};
	my @array_attribs = @{$self->{'_valid_attributes'}->{'array_attr'}};
	my @font_attribs = @{$self->{'_valid_attributes'}->{'font_attr'}};
	@font_attribs = @{$self->{'_valid_attributes'}->{'font_attr_pie'}} if ($self->{'type'} eq 'pie');

	#Parse colors, allowing only valid hex or builtin colors
	my %bad_colors = ();
	foreach my $attrib (@color_attribs) {
		my @colors = token_parse($self->{$attrib});
		my @dclrs = ();
		foreach my $color (@colors) {
			next if (grep {$_ eq $color} @builtin_colors);
			if ($color !~ /^#[0-9abcdefABCDEF]{6}$/) {
				$self->_error("color $color in attribute $attrib is invalid.  This color will be ignored.");
				$bad_colors{$color} = 1;
			} else {
				$graph->add_colour($color, [hex2rgb($color)]);
			}
		}
	}

	#remove bad colors from non-multiple attribs
	foreach my $attrib (@color_attribs) {
		next if (grep {$attrib eq $_} @array_attribs);
		delete $self->{$attrib} if ($bad_colors{$self->{$attrib}});
	}

	#parse multiples into arrayrefs, removing bad colors from multiples if required
	foreach my $attrib (@array_attribs) {
		next unless defined($self->{$attrib});
		my @values = token_parse($self->{$attrib});
		delete ($self->{$attrib});
		if (grep {$_ eq $attrib} @color_attribs) {
			@values = (grep {$bad_colors{$_} != 1} @values);
		}
		$self->{$attrib} = \@values if (@values);
	}

	#call those methods that are available to all types
	$self->{'text_clr'} && $graph->set_text_clr($self->{'text_clr'});
	$self->{'title_font'} && $self->_ok_font($self->{'title_font'}) && $graph->set_title_font(token_parse($self->{'title_font'}));

	$self->_add_chart_attributes($self->{'_valid_attributes'}->{'all'});
	#then those for axis types
	if ($type =~ /^(lines|hbars|bars|points|linespoints|area)$/) {
		$self->_add_chart_attributes($self->{'_valid_attributes'}->{'axes'});
		if ($type =~ /bars/) {
			$self->_add_chart_attributes($self->{'_valid_attributes'}->{'bars'});
		}
		if ($type =~ /points/) {
			$self->_add_chart_attributes($self->{'_valid_attributes'}->{'points'});
		}
		if ($type =~ /lines/) {
			$self->_add_chart_attributes($self->{'_valid_attributes'}->{'lines'});
		}
	#or those for pie types
	} elsif ($type eq 'pie') {
		$self->_add_chart_attributes($self->{'_valid_attributes'}->{'pie'});
	}

	#then parse function-based settings, such as fonts
	foreach my $attrib (@font_attribs) {
		next unless defined ($self->{$attrib});
		my ($font, $size) = token_parse($self->{$attrib});
		my $approved_font = $self->_ok_font($font);
		if ($approved_font) {
			eval "\$graph->set_$attrib('$approved_font', $size)";
			$self->_error("Could not use font $font in attribute $attrib: $@") if ($@);
		} else {
			$self->_error("Could not use font $font in attribute $attrib");
		}
	}
	$graph->set_legend(token_parse($self->{'legend'})) if $self->{'legend'};

	my %settings = ();
	foreach my $attribute (@{$self->{'_chart_attributes'}}) {
		$settings{$attribute} = $self->{$attribute} if defined($self->{$attribute});
	}

	#warn Dumper(\%settings);
	$graph->set(%settings);
	return $graph;
}


sub _plot {
	my ($self) = @_;
	my $graph = $self->_get_graph;
	$self->_process_chart($graph);
	my $gd = $graph->plot($self->{'_graph_data'});
	$self->_error($graph->error) if ($graph->error);
	$self->_alter_graphic($gd);
	$self->_error($graph->error) if ($graph->error);
	#256 Color limit due to bugs in GD library
	eval {$gd->trueColor(0)};
	my $file = $self->{'_graphic_file'};
	my $format = $self->{'_file_format'};
	local $| = 1;
	open OUT, "> $file" || $self->_raise_exception("Could not write file $file: $!");
	binmode(OUT);
	eval {
		if ($format eq 'gif') {
			print OUT $gd->gif();
		} else {
			print OUT $gd->png();
		}
		$self->_error($graph->error) if ($graph->error);
	};
	close OUT;
	select OUT;
	if ($@) {
		$self->_error($@);
	}
}

sub _add_chart_attributes {
	my ($self, $arrayref) = @_;
	my %uniq = ();
	#combine existing attributes, new attributes, and uniquify them before assigning them to
	#the _chart_attributes attribute
	$self->{'_chart_attributes'} = [grep {$uniq{$_}++ == 0} (@{$self->{'_chart_attributes'}}, @$arrayref)];
}

=pod

=item (void) C<_alter_graphic> (GD Object)

"Hook" method for putting final changes on the plotted GD graphic. Accepts
the graphic as a GD object.  Does nothing by default.

=cut

sub _alter_graphic {
	my ($self, $dg) = @_;
	return;
}

=pod

=item (undef) C<_process_chart> (GD::Graph Object)

"Hook" method for putting final changes on the GD::Graph object.  Accepts
the chart as a GD::Graph object.  Does nothing by default.

=cut

sub _process_chart {
	my ($self, $graph) = @_;
	return;
}

=pod

=item (void) C<_set_default_attribs> (void)

"Hook" method for setting default attributes.  Does nothing by default.

=cut

sub _set_default_attributes {
	return;
}

sub _get_data {
	my ($self) = @_;
	my $sh = $self->{'sh'};
	my @data = ();
	my $truncate = 0;
	my $file = 'Signature: ' . sha1_hex($self->_as_html) . "\n";
	while (my $line = $sh->fetchrow_arrayref) {
		push @data, [@$line];
		$file .= join("\t", @$line) . "\n";
	}
	$self->{'_graph_data'} = \@data;
	return $file;
}

sub _process_data {
	my ($self) = @_;
	my @data = @{$self->{'_graph_data'}};
	my $truncate = 0;
	#rotate table unless it's a series.
	unless ($self->_flags->series) {
		my @new = ();
		my $size = scalar(@{$data[0]});
		for (my $i = 0; $i < $size; $i++) {
			my @outline = ();
			foreach my $datum (@data) {
				push @outline, $datum->[$i];
			}
			push @new, [@outline];
		}
		@data = @new;
		if ($self->{'label_col'}) {
			if ($self->{'label_col'} != 1) {
				my @temp = splice(@data, $self->{'label_col'} - 1, 1);
				unshift @data, @temp;
			}
		}
		if ($self->{'data_col'}) {
			$data[1] = $data[$self->{'data_col'} - 1];
			$truncate ||= 1;
		}
		if ($self->_flags->by_value) {
			my @labels = ();
			my @values = ();
			my $count = 0;
			foreach my $datum (
				sort {lc($a->[1]) cmp lc($b->[1]) || $a->[1] <=> $b->[1]}
				map {[$data[0]->[$_], $data[1]->[$_]]}
				map {$count++}
				@{$data[0]}
			) {
				#warn Dumper($datum);
				push @labels, $datum->[0];
				push @values, $datum->[1];
			}
			@data = (\@labels, \@values);
			#warn Dumper(\@data);
			$truncate ||= 1;
		} elsif ($self->_flags->by_label) {
			my @labels = ();
			my @values = ();
			my $count = 0;
			foreach my $datum (
				sort {lc($a->[0]) cmp lc($b->[0]) || $_->[0] <=> $_->[0]}
				map {[$data[0]->[$_], $data[1]->[$_]]}
				map {$count++}
				@{$data[0]}
			) {
				#warn Dumper($datum);
				push @labels, $datum->[0];
				push @values, $datum->[1];
			}
			@data = (\@labels, \@values);
			$truncate ||= 1;
		}
		if ($self->{'other_limit'}) {
			my $other = 0;
			my $limit_reached = 0;
			my @labels = ();
			my @values = ();
			foreach my $value (@{$data[1]}) {
				my $label = shift @{$data[0]};
				if ($value < $self->{'other_limit'}) {
					$limit_reached = 1;
					$other += $value;
					#warn "name: $label, value: $value, total: $other";
				} else {
					push @labels, $label;
					push @values, $value
				}
			}
			if ($limit_reached) {
				$truncate = 1;
				push @labels, "Other";
				push @values, $other;
				@data = (\@labels, \@values);
			}
		}
		if ($self->_flags->percent) {
			foreach my $line (1 .. $#data) {
				my $sum = 0;
				map {$sum += $_} @{$data[$line]};
				my $count = 0;
				my $total = 0;
				foreach my $item (@{$data[0]}) {
					$data[$line][$count] = int((($data[1][$count]/$sum) * 100) + .5);
					$count++;
				}
			}
		}
		if ($self->_flags->value_labels) {
			$truncate ||= 1;
			my $count = 0;
			my $percent = '';
			$percent = '%' if ($self->_flags->percent);
			map {$data[0][$count] = $data[0][$count] . " ($_$percent)"; $count++} @{$data[1]};
		}
	} else {
		if ($self->_flags->rotate) {
			my @new = ();
			my $size = scalar(@{$data[0]});
			for (my $i = 0; $i < $size; $i++) {
				my @outline = ();
				foreach my $datum (@data) {
					push @outline, $datum->[$i];
				}
				push @new, [@outline];
			}
			@data = @new;
		}
		if ($self->{'labels'}) {
			my @label = ();
			my @given_label = token_parse($self->{'labels'});
			my $count = scalar(@{$data[0]});
			for (my $item = 0; $item < $count; $item++) {
				$label[$item] = ($given_label[$item] || 'unknown');
			}
			unshift @data, \@label;
		}
	}
	if ($truncate) {
		$self->_error("This chart cannot be represented as a series due to other parameters you have chosen.")
			if ($self->_flags->series);
		if ($truncate > 1) {
			$data[0] = [splice(@{$data[0]}, 0, $truncate + 1)];
			$data[1] = [splice(@{$data[1]}, 0, $truncate + 1)];
		}
		@data = ($data[0],$data[1]);
	}
	$self->{'_graph_data'} = \@data;
	$self->_filter_labels if ($self->{'label_filters'});
	$self->_filter_values if ($self->{'value_filters'});
}

sub _filter_labels {
	my ($self) = @_;
	my @labels = ();
	my @filters = token_parse($self->{'label_filters'});
	foreach my $filter (@filters) {
		my @filtered = ();
		my @labels = @{$self->{'_graph_data'}->[0]};
		foreach my $label (@labels) {
			push @filtered, $self->_filter($filter, $label);
		}
		$self->{'_graph_data'}->[0] = \@filtered;
	}
}

sub _filter_values {
	my ($self) = @_;
	my @values = ();
	my @filters = token_parse($self->{'value_filters'});
	for (my $line = scalar(@{$self->{'_graph_data'}}); $line > 1; $line--) {
		foreach my $filter (@filters) {
			my @filtered = ();
			my @values = @{$self->{'_graph_data'}->[$line - 1]};
			foreach my $value (@values) {
				push @filtered, $self->_filter($filter, $value);
			}
			$self->{'_graph_data'}->[$line - 1] = \@filtered;
		}
	}
}

sub _filter {
	my ($self, $filter, $value) = @_;
	if ($filter eq 'zero') {
		return '0' unless $value;
	} elsif ($filter eq 'dollar_sign') {
		return '$' . $value;
	} elsif ($filter eq 'percent_sign') {
		return "$value%";
	} elsif ($filter eq 'commify') {
		1 while ($value =~ s/^([-+]?\d+)(\d{3})/$1,$2/);
		return $value;
	}else {
		return $self->_special_filter($filter, $value);
	}
}

=pod

=item (scalar) C<_special_filter> (scalar, scalar)

"Hook" for filtering data/labels.  Should accept a value for the filter and
the data to perform filters upon.

=cut

sub _special_filter {
	my ($self, $filter, $value) = @_;
	return $value;
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the register_filter, _setup and _format_output methods.  Also
reserves the methods _set_default_attributes, _get_data, _process_data,
_filter_labels, _filter_values, _filter.  Also reserves the standard
register_query method.

Produces, by default, a second file (E<lt>graphic_nameE<gt>.tdf) in the same
directory as the graphic which has the HTML fingerprint and the data stored
in tab-delineated-text format.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'_valid_attributes'} = {
		'img'			=>	[qw(align alt border height hspace ismap longdesc usemap vspace width src)],
		'all'			=>	[qw(b_margin t_margin l_margin r_margin transparent interlaced bgclr fgclr boxclr textclr labelclr axislabelclr legendclr valuesclr accentclr shadowclr dclrs show_values values_vertical values_space values_format logo logo_position logo_resize legend_placement legend_spacing legend_marker_width legend_marker_height lg_cols)],
		'axes'			=>	[qw(x_label y_label box_axis two_axes zero_axis zero_axis_only x_plot_values y_plot_values y_max_value y_min_value x_tick_number x_min_value x_tick_number x_min_value x_max_value y_number_format x_label_skip y_label_skip x_tick_offset x_all_ticks x_label_position y_label_position x_labels_vertical long_ticks tick_length x_ticks y_tick_number axis_space text_space)],
		'bars'			=>	[qw(overwrite bar_width bar_spacing shadow_depth borderclrs cycle_clrs cumulate)],
		'lines'			=>	[qw(line_types line_type_scale line_width skip_undef)],
		'points'		=>	[qw(markers marker_size)],
		'pie'			=>	[qw(3d pie_height start_angle suppress_angle)],
		'builtin_fonts'	=>	[qw(gdTinyFont gdSmallFont gdMediumBoldFont gdLargeFont gdGiantFont)],
		'font_attr'		=>	[qw(legend_font title_font x_label_font y_label_font x_axis_font y_axis_font)],
		'font_attr_pie'	=>	[qw(legend_font title_font label_font value_font)],
		'color_attr'	=>	[qw(bgclr fgclr boxclr textclr labelclr axislabelclr legendclr valuesclr accentclr shadowclr dclrs)],
		'array_attr'	=>	[qw(dclrs markers)],
		'boolean_attr'	=>	[qw(transparent interlaced show_values values_vertical box_axis two_axes zero_axis zero_axis_only x_plot_values y_plot_values x_all_ticks x_labels_vertical long_ticks x_ticks correct_width cycle_clrs cumulate skip_undef 3d)]
	};
	$self->{'_chart_attributes'} = [];
	$self->_set_default_attributes;
}

sub _format_output {
	my ($self) = @_;
	$self->_raise_exception('Chart Wyrds require Query Wyrds')
		unless ($self->{'sh'});
	my $file = $self->{'src'};
	my $root = $self->dbl->req->document_root;
	if ($file) {
		$file = "$root$file";
	} else {
		$self->_raise_exception("Chart Wyrds require a src attribute");
	}
	$self->_file_problems($file);
	my ($format) = $file =~ /\.(png|gif)$/i;
	unless ($format) {
		$self->_raise_exception('Only PNG or GIF file format is supported');
	}
	$self->{'_graphic_file'} = $file;
	$self->{'_file_format'} = lc($format);
	my $datafile = $file;
	$datafile =~ s/\.$format/\.tdf/;
	$self->_file_problems($datafile);
	$self->{'_data_file'} = $datafile;
	my $data = $self->_get_data;
	my $cache = '';
	$cache = $self->slurp_file($datafile) if (-f $datafile);
	if (($data ne $cache)) {
		$self->_info("(Re)building chart...");
		$self->_process_data;
		$self->_plot;
		#warn $datafile;
		spit_file($datafile, $data);
	}
	my %image_attributes = map {$_, $self->{$_}} @{$self->{'_valid_attributes'}->{'img'}};
	#warn $self->_image_template;
	$self->_data($self->_set(\%image_attributes, $self->_image_template));
	return;
}

sub register_query {
	my ($self, $query) = @_;
	$self->{'sh'} = $query->sh;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;