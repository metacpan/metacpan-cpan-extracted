package Apache::ScoreboardGraph;

use strict;
use Apache::Scoreboard ();
use Chart::PNGgraph::bars ();
use Chart::PNGgraph::pie ();
use Chart::PNGgraph::lines ();

use constant KB => 1024;

sub new {
    my($class, $opts) = @_;
    if ($opts and $opts->{host}) {
	$opts->{image} ||= 
	  Apache::Scoreboard->fetch("http://$opts->{host}/scoreboard");
    }
    else {
	$opts = {image => Apache::Scoreboard->image};
    }
    $opts->{host} ||= "";
    bless $opts, $class;
}

sub access {
    my($self, $args) = @_;
    my $image = $self->{image};
    my(@labels, @access, @bytes);
    my($total_access, $total_bytes);

    for (my $parent = $image->parent; $parent; $parent = $parent->next) {
	push @labels, $parent->pid;
	my $server = $parent->server;
	
	my $count = $server->access_count;
	push @access, $count;
	$total_access += $count;
	
	my $bytes = $server->bytes_served;
	push @bytes, $bytes / KB;
	$total_bytes += $bytes;
    }
    
    my $data = [\@labels, \@access, \@bytes];
    
    my $graph = Chart::PNGgraph::bars->new;
    
    $graph->set( 
		x_label => 'Child PID',
		y1_label => 'Access Count',
		y2_label => 'Bytes Served (KB)',
		title => "$self->{host} Server Access",
		long_ticks => 1,
		bar_spacing => 2,
		two_axes => 1,
		x_labels_vertical => 1,
		x_label_position => 1/2,
		dclrs => [qw(lred lblue)],
		%{ $args || {} },
	       );
    
    my $bytes_str = Apache::Scoreboard::size_string($total_bytes);
    
    $graph->set_legend("Access Count ($total_access total)", 
		       "Bytes Served (KB) ($bytes_str total)");

    ($graph, $data);
}

my %Status = 
  (
   '.' => "Open Slot",
   'S' => "Starting",
   '_' => "Waiting",
   'R' => "Reading",
   'W' => "Writing",
   'K' => "Keepalive",
   'L' => "Logging",
   'D' => "DNS Lookup",
   'G' => "Finishing",
  );

sub status {
    my($self, $args) = @_;
    my $image = $self->{image};
    my %data = ();
    my @labels = values %Status;
    
    for (my $parent = $image->parent; $parent; $parent = $parent->next) {
	my $server = $parent->server;
	$data{ $Status{ $server->status } }++;
    }
    
    my @nlabels = map { "$_ ($data{$_})" } keys %data;
    
    my $data = [\@nlabels, [@data{keys %data}]];
    
    my $graph = Chart::PNGgraph::pie->new(250, 250);
    
    $graph->set( 
		title => "$self->{host} Server Status",
		pie_height => 36,
		axislabelclr => 'black',
		'3d' => 0,
		start_angle => 90,
		%{ $args || {} },
	       );
    ($graph, $data);    
}

sub cpu {
    my($self, $args) = @_;
    my $image = $self->{image};
    my(@labels, @cpu, @req_time);
    my($total_cpu, $total_req_time);
    
    for (my $parent = $image->parent; $parent; $parent = $parent->next) {
	push @labels, $parent->pid;
	my $server = $parent->server;
	
	my $cpu = $server->times;
	push @cpu, $cpu;
	$total_cpu += $cpu;
	
	my $req_time = $server->req_time;
	push @req_time, $req_time;
	$total_req_time += $req_time;
    }
    
    my $data = [\@labels, \@cpu, \@req_time];
    
    my $graph = Chart::PNGgraph::bars->new;
    
    $graph->set( 
		x_label => 'Child PID',
		y1_label => 'CPU',
		y2_label => 'Request Time',
		title => "$self->{host} Server CPU Usage",
		long_ticks => 1,
		bar_spacing => 2,
		two_axes => 1,
		x_labels_vertical => 1,
		x_label_position => 1/2,
		dclrs => [qw(lred lblue)],
		%{ $args || {} },
	       );
    
    $graph->set_legend("CPU ($total_cpu total)", 
		       "Request Time (in milliseconds) ($total_req_time total)");
    ($graph, $data);
}

sub mem_usage {
    require GTop;
    my($self, $args) = @_;
    my $image = $self->{image};
    my $gtop_host = delete $args->{gtop_host};
    my $gtop = $gtop_host ? GTop->new($gtop_host) : GTop->new;
    
    my %data = ();
    my %total = ();
    my @mem = qw(size share vsize rss real);
    my $pids = $image->pids;
    
    for my $pid (@$pids) {
	push @{ $data{labels} }, $pid;
	
	my $mem = $gtop->proc_mem($pid);
	for (@mem) {
	    next unless $mem->can($_); #real
	    my $val = $mem->$_();
	    push @{ $data{$_} }, $val/KB;
	    $total{$_} += $val;
	}
	my $real = $data{size}->[-1] - $data{share}->[-1]; 
	push @{ $data{real} }, $real;
	$total{real} += $real * KB;
    }
    
    my $data = [@data{'labels', @mem}];
    
    my $graph = Chart::PNGgraph::lines->new;
    
    $graph->set( 
		x_label => 'Child PID',
		y_label => 'size',
		title => "$gtop_host Apache Memory Usage",
		y_tick_number => 8,
		y_label_skip => 2,
		line_width => 3,
		y_number_format => sub { 
		    sprintf "%s", GTop::size_string(KB * shift);
		},
		%{ $args || {} },
	       );
    
    $graph->set_legend(map { 
	my $str = GTop::size_string($total{$_});
	"$_ ($str total)";
    } @mem);

    ($graph, $data);
}

1;
__END__
