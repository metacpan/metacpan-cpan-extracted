use Test::More tests=>5;
use strict;

BEGIN { 
  use_ok(qw(App::SimpleScan));
}

my $app = new App::SimpleScan;
$app->queue_lines("line 1", "line 4");
is $app->next_line, "line 1", "Initial stack right";
$app->queue_lines("line 2", "line 3");
is $app->next_line, "line 2", "restack works";
is $app->next_line, "line 3", "both lines stacked";
is $app->next_line, "line 4", "back to old input";
