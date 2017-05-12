use Graph::Easy;
use MIME::Base64 qw(encode_base64);
use Encode qw(encode);
#use Graph;
#use Graph::Layouter::Spring;

# create vertices and edges of graph
my $g = _get_graph();

# generate js that renders the graph
my $js = ''; #_get_js_code($g);
my $data = encode_base64(encode("utf8", _get_image($g)));

my $html = <<EOFHTM;
<img src="data:text/html;base64,$data"/>
<div id="myCanvas" style="position:relative;width:800px;height:600px;background:#eee;"></div>
<script type="text/javascript">
	Event.observe(window,'load',function(){
		var jg = new jsGraphics("myCanvas");
		jg.setColor("#ff0000");
		jg.setStroke(1);
		jg.setFont("Verdana,Arial,sans-serif", "9px", "normal");
		$js
		jg.paint();
	});
</script>
EOFHTM

return output(1, '', _page('network',$html));

# ----------------------------------------------------------------------

sub _get_image
{
	my $graphviz = $g->as_graphviz_file();
	
	my $tmpfile1 = '/tmp/'.time().'.txt'; 
	my $tmpfile2 = '/tmp/'.time().'.png'; 
}

sub _get_graph
{
	#my $g = Graph->new();
	my $g = Graph::Easy->new();

	#my $a = {'title' => 'a','color' => 'red',  'size' => 1.0};
	#my $b = {'title' => 'b','color' => 'green','size' => 0.5};
	#my $c = {'title' => 'c','color' => 'blue', 'size' => 0.3};
	#my $d = {'title' => 'd','color' => 'pink', 'size' => 0.4};
	
	#$g->add_edge($a,$b);
	#$g->add_edge($b,$c);
	#$g->add_edge($c,$a);
	#$g->add_edge($c,$d);

	$g->add_edge('a','b');
	$g->add_edge('b','c');
	$g->add_edge('c','a');
	$g->add_edge('c','d');
	
	return $g;
	
	# get switch IPs
	my @switches;
	my $query
		= find(
			-tables  => ['alist_pc'],
			-columns => ['switch'],
		);
	while (my $row = $query->fetchrow_hashref()) {
		push @switches,
			{
				'title' => $row->{'switch'},
				'color' => 'green',
				'type'  => 'switch',
				'size'  => 0.5,
			};
	}

	my $server
		= {
			'title' => 'Server',
			'color' => 'red',
			'type'  => 'server',
			'size'  => 0.7,
		};

	for (my $i = 0; $i < @switches; $i ++) {
		# connect switch to server
		$g->add_edge($server, $switches[$i]);
		
		# connect switches together
		$g->add_edge( $switches[$i], $switches[$i+1] )
			if $i < @switches -1;

		# get pcs connected to switch
		my $query2
			= find(
				-tables => ['alist_pc'],
				-where  => {'switch' => $switches[$i]->{'title'}},
			);
		my $x = 0;
		while (my $row = $query2->fetchrow_hashref()) {
			next if $row->{'name'} eq '';
			$g->add_edge(
				$switches[$i],
				{
					'title' => $row->{'name'},
					'color' => 'blue',
					'type'  => 'pc',
					'size'  => 0.3,
				});
			$x ++;
			last if $x == 10;
		}	
	}
	$g->add_edge( $switches[-1], $switches[0] );

	return $g;
}

sub _get_js_code
{
	my ($g) = @_;
	
	my $layouted = Graph::Layouter::Spring::layout($g);

	my $s = 100;  # scale
	my $o = 200; # offset

	my $vertices = '';
	my $edges = 'jg.setColor("black");';
	foreach my $e ($layouted->edges()) {
		my $v_from = $e->[0];
		my $v_to   = $e->[1];
		
		my $a_from = $g->get_vertex_attributes($v_from);
		my $a_to   = $g->get_vertex_attributes($v_to);
		
		my ($x1,$y1,$x2,$y2) =
			(int($a_from->{'layout_pos1'} * $s + $o),
			 int($a_from->{'layout_pos2'} * $s + $o),
			 int($a_to->{'layout_pos1'}   * $s + $o),
			 int($a_to->{'layout_pos2'}   * $s + $o));
		
		$edges .= 'jg.drawLine('.$x1.','.$y1.','.$x2.','.$y2.');';
		
		#$html .= CGI::WebToolkit::__dd($g->get_vertex_attributes($v));
	}
	foreach my $v ($layouted->vertices()) {
		my $a = $g->get_vertex_attributes($v);
				
		my $size = int($v->{'size'} * 30);
		my ($x,$y) =
			(int($a->{'layout_pos1'} * $s + ($o-($size/2))),
			 int($a->{'layout_pos2'} * $s + ($o-($size/2))));
		
		$vertices .=
			'jg.setColor("black");'.
			'jg.drawString("'.$v->{'title'}.'",'.($x+$size).','.($y+$size).');'.
			'jg.setColor("'.$v->{'color'}.'");'.
			'jg.fillEllipse('.$x.','.$y.','.$size.','.$size.');';
	}
	return $edges.$vertices;
}
