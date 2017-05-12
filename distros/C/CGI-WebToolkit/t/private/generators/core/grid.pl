my ($data) = @args;

my $data_defaults = {
	'class' => '',
	'widths' => '[100%]',
	'columns' => [],
};
my $params = CGI::WebToolkit::__parse_params( $data, $data_defaults );

my $class = $params->{'class'};

my $widths = $params->{'widths'};
my @widths = map { s/[^\s\d\%]//g; $_ } split /\s+/, $widths;

my @columns = @{$params->{'columns'}};

my $content = ''; # each: [margin, width, margin]
#my $total_width = 0;
for (my $w = 0; $w < scalar @widths - 1; $w += 2) {
	my $margin_left = $widths[$w];
	my $margin_right = ($w == scalar @widths - 2 ? $widths[$w+2] : 0);
	my $width = $widths[$w + 1];
	$content .=
		'<div class="grid_column" '.
			'style="width:'.convert_to_css_length($width).'; float:left; '.
				'margin:0 '.convert_to_css_length($margin_right).' 0 '.
				convert_to_css_length($margin_left).';">'.
			shift(@columns).
		'</div>';
	#$total_width += 
	#	convert_to_int($width) + convert_to_int($margin_left) +
	#	convert_to_int($margin_right);
}

return
	#'<div class="grid" style="width:'.convert_to_css_length($total_width).';">'.
	'<div class="grid grid_'.$class.'" style="width:100%;">'.
		$content.
		'<div class="clear"></div>'.
	'</div>';
	
sub convert_to_css_length {
	my ($value) = @_;
	return ($value =~ /\%$/ ? $value : $value.'px');
}

sub convert_to_int {
	my ($value) = @_;
	$value =~ s/[^\d]//g;
	return $value;
}

