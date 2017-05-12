use strict;
use Apache::ScoreboardGraph ();

use constant IS_MODPERL => exists $ENV{MOD_PERL};

my($image, $r, $gtop_host);
if (IS_MODPERL) {
    $r = shift;
    $r->send_http_header('image/gif');
    $image = Apache::Scoreboard->image;
    $gtop_host = $r->dir_config("GTopHost");
}
else {
    my $host = shift || "localhost";
    $image = Apache::Scoreboard->fetch("http://$host/scoreboard");
    $gtop_host = shift;
}

my $sbgraph = Apache::ScoreboardGraph->new({image => $image});
my($graph, $data) = $sbgraph->mem_usage({gtop_host => $gtop_host});

if (IS_MODPERL) {
    print $graph->plot($data);
}
else {
    $graph->plot_to_png("scoreboard-mem-usage.png", $data);
}


