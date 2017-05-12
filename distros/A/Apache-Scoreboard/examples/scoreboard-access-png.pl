use strict;
use Apache::ScoreboardGraph ();

use constant IS_MODPERL => exists $ENV{MOD_PERL};

my($image, $r);
if (IS_MODPERL) {
    $r = shift;
    $r->send_http_header('image/gif');
    $image = Apache::Scoreboard->image;
}
else {
    my $host = shift || "localhost";
    $image = Apache::Scoreboard->fetch("http://$host/scoreboard");
}

my $sbgraph = Apache::ScoreboardGraph->new({image => $image});
my($graph, $data) = $sbgraph->access;

if (IS_MODPERL) {
    print $graph->plot($data);
}
else {
    $graph->plot_to_png("scoreboard-access.png", $data);
}


