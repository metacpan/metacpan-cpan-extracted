my ($data) = @args;

my $data_defaults = {
	'content' => [],
	'headlines' => [],
	'transformers' => [],
};
my $params = CGI::WebToolkit::__parse_params( $data, $data_defaults );

my $content      = $params->{'content'};
my $headlines    = $params->{'headlines'};
my $transformers =
	(exists $params->{'transformers'} ? $params->{'transformers'} : []);

$transformers = [] unless defined $transformers;
return '<p><i>No entries found.</i></p>' unless scalar @{$content};
my $htm = '';

my $table_id = 'table_'.time().sprintf('%.0f', rand(10000));
$htm .= '<form><p class="filter">Filter: <input name="filter_'.$table_id.'" onkeyup="tablefilter(this, \''.$table_id.'\', 1);" type="text"></p></form>';
$htm .= '<div class="clear"></div>';
$htm .= '<table class="sortable" id="'.$table_id.'">';
$htm .= '<tr>';
foreach my $headline (@{$headlines}) {
	$htm .= '<th>'.$headline.'</th>';	
}
$htm .= '</tr>';
my $query;
$query = query($content) unless ref($content);
foreach my $r (0..(ref($content) ? scalar @{$content} : $query->rows()) - 1) {
	my $row = (ref($content) ? $content->[$r] : $query->fetchrow_arrayref());		
	$htm .= '<tr>';
	my $c = 0;
	foreach my $col (@{$row}) {
		$htm .= '<td>';
		my $content = (scalar @{$transformers} > $c && ref($transformers->[$c]) eq 'CODE' ?
					$transformers->[$c]->($col) : $col);
		$htm .= (defined $content && length $content ? $content : '-');
		$htm .= '</td>';
		$c ++;
	}
	$htm .= '</tr>';		
}
$htm .= '</table>';

return $htm;
