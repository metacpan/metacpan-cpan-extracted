#!/usr/bin/perl
#
# We want to plot some thing like this on the input
#
# AU-CCSCRE001,10.9.1.246 => CORE1-MSM,10.9.1.248
# AU-CCSCRE001,10.9.1.246 => CORE2-MSM,10.9.1.249
#  CORE1-MSM,10.9.1.248 => 10.19.228.65,10.19.228.65
#   10.19.228.65,10.19.228.65 => SYDMGX2-RPMC1,unknown
#   10.19.228.65,10.19.228.65 => SYDMGX1-RPMC1,unknown
#    SYDMGX2-RPMC1,unknown => BURMGX2-RPMC1,unknown
#     BURMGX2-RPMC1,unknown => RN-48GE-01-MSFC-01,10.25.152.252
#      RN-48GE-01-MSFC-01,10.25.152.252 => TCNZA-AU-SYD-R1,10.25.159.254
#       TCNZA-AU-SYD-R1,10.25.159.254 => 10.25.159.44,10.25.159.44
#    SYDMGX1-RPMC1,unknown => BURMGX1-RPMC1,unknown
#     BURMGX1-RPMC1,unknown => RN-48GE-01-MSFC-01,10.25.152.252
#      RN-48GE-01-MSFC-01,10.25.152.252 => TCNZA-AU-SYD-R1,10.25.159.254
#       TCNZA-AU-SYD-R1,10.25.159.254 => 10.25.159.44,10.25.159.44
#  CORE2-MSM,10.9.1.249 => 10.19.228.65,10.19.228.65
#   10.19.228.65,10.19.228.65 => SYDMGX2-RPMC1,unknown
#   10.19.228.65,10.19.228.65 => SYDMGX1-RPMC1,unknown
#    SYDMGX2-RPMC1,unknown => BURMGX2-RPMC1,unknown
#     BURMGX2-RPMC1,unknown => RN-48GE-01-MSFC-01,10.25.152.252
#      RN-48GE-01-MSFC-01,10.25.152.252 => TCNZA-AU-SYD-R1,10.25.159.254
#       TCNZA-AU-SYD-R1,10.25.159.254 => 10.25.159.44,10.25.159.44
#    SYDMGX1-RPMC1,unknown => BURMGX1-RPMC1,unknown
#     BURMGX1-RPMC1,unknown => RN-48GE-01-MSFC-01,10.25.152.252
#      RN-48GE-01-MSFC-01,10.25.152.252 => TCNZA-AU-SYD-R1,10.25.159.254
#       TCNZA-AU-SYD-R1,10.25.159.254 => 10.25.159.44,10.25.159.44
# 

use Data::Dumper;
use GraphViz;

use vars qw/$name/;

$name = shift || 'plotfile';

$date = `date`;
chomp($date);
$Data::Dumper::Indent = 1;
%cache = ();
@cols = qw/black purple blue orange magenta /;
$indent = 0;
$debug = 0;

my $graph = GraphViz->new(sort => 1, 
				pageheight => 11.5,
				pagewidth  => 8.2,
				node   => {fontsize   =>'10pt', }
);

my ($from,$to) = buildgraph($graph);
$graph->as_ps("$name.ps");
$graph->as_png("$name.png");

printhtml($from,$to);

exit;


# We wan to plot some thing like this on the input
#
# AU-CCSCRE001,10.9.1.246 => CORE1-MSM,10.9.1.248
# AU-CCSCRE001,10.9.1.246 => CORE2-MSM,10.9.1.249
#  CORE1-MSM,10.9.1.248 => 10.19.228.65,10.19.228.65
#   10.19.228.65,10.19.228.65 => SYDMGX2-RPMC1,unknown
#   10.19.228.65,10.19.228.65 => SYDMGX1-RPMC1,unknown
#    SYDMGX2-RPMC1,unknown => BURMGX2-RPMC1,unknown
#     BURMGX2-RPMC1,unknown => RN-48GE-01-MSFC-01,10.25.152.252
#      RN-48GE-01-MSFC-01,10.25.152.252 => TCNZA-AU-SYD-R1,10.25.159.254
#       TCNZA-AU-SYD-R1,10.25.159.254 => 10.25.159.44,10.25.159.44
sub buildgraph
{
	my ($graph)   = @_;
	my @names     = ();
	my %addednode = ();
	my %addededge = ();
	my $src       = '';
	my $dest      = '';

	my $i = 0;
	my($h,$hip,$p,$pip);
	while(<>)
	{
		my $col = $cols[$i % $#cols];

		($h,$hip,$p,$pip) = /^\s*([^,]+),(\S+) => ([^,]+),(\S+)$/;		
		next unless $pip;

		$src = $h if $i == 0;

		unless( $addednode{$h} )
		{
			addnode($graph,$h,$hip);
			$addednode{$h}++;
		}
		unless( $addednode{$p} )
		{
			addnode($graph,$p,$pip);
			$addednode{$p}++;
		}
		unless( $addededge{"$h$hip->$p$pip"} )
		{
			$graph->add_edge({ from => $h, to => $p , color=>$col});
			$addededge{"$h$hip->$p$pip"}++;
		}
		$i++;
	}
	$dest = $p;
	return($src,$dest);
}

sub addnode 
{ 
	my $self = shift;
	my $name = shift;
	my $ip   = shift;

	my $l = '';
	if($name eq $ip)
	{
		$l = $name;
	}
	else
	{
		$l = "$name\n$ip";
	}
	$self->add_node({ name=> $name, label=>$l, color => 'red', 
					  URL => "http://www/place/$name-log.html" })
}

sub printhtml
{
	my $from = shift;
	my $to   = shift;

	open O, "> $name.html" || die;
	if($from && $to)
	{
	$to = 'ACCESS' if $to eq 'TCNZA2';
	print O <<EOT;
<h3>Note:</h3>

<h4>Created $date</h4>

<p>
This graph shows only the active routes from $from to $to
</p>

<p>
It does not include '<i>feasible succesors</i>' or '<i>inactive</i>'
backup links (eg BRI interface on branch routers).
</p>

<img src="http://www/customer/routegraphs/$name.png" border="1" vspace="1"
hspace="1" alt="active routes from $from to $to" align="left">

EOT

	}
	else
	{
	print O <<EOT;
<h3>No Graph Available</h3>

<h4>Created $date</h4>
EOT
	}

}
