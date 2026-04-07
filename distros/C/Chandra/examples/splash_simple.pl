#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Chandra;
use Chandra::App;
use Chandra::Splash;

# Bootstrap NSApplication so windows render and focus properly.
my $app = Chandra::App->new(
    title  => 'My App',
    width  => 1,
    height => 1,
);
my $wv = $app->webview;
$wv->init;

sub pump { $wv->loop(0) for 1..5 }

sub pump_sleep {
    my ($secs) = @_;
    my $end = time + $secs;
    while (time < $end) {
        pump();
        select(undef, undef, undef, 0.02);
    }
}

# --- Show a splash with a progress bar that loads to 100% ---

my $splash = Chandra::Splash->new(
    title    => 'Loading Application',
    width    => 420,
    height   => 200,
    progress => 1,
);

$splash->show;
pump();

my @steps = (
    [ 10, 'Initialising...'       ],
    [ 30, 'Loading modules...'    ],
    [ 50, 'Connecting to DB...'   ],
    [ 70, 'Building interface...' ],
    [ 90, 'Almost ready...'       ],
    [100, 'Done!'                 ],
);

for my $step (@steps) {
    my ($pct, $msg) = @$step;
    $splash->update_progress($pct);
    $splash->update_status($msg);
    pump_sleep(0.6);
}

pump_sleep(0.4);
$splash->close;

# --- Now show the real application page ---

$wv->set_title('My App');
$wv->resize(800, 600);

my $page_html = <<'HTML';
<!DOCTYPE html>
<html>
<head>
<style>
  body {
    margin: 0; display: flex; align-items: center; justify-content: center;
    height: 100vh; background: #1a1a2e; color: #e0e0e0;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  }
  h1 { font-size: 2em; }
</style>
</head>
<body>
  <h1>Welcome to My App</h1>
</body>
</html>
HTML
$page_html =~ s/\\/\\\\/g;
$page_html =~ s/'/\\'/g;
$page_html =~ s/\n/\\n/g;
$wv->eval_js("document.open();document.write('$page_html');document.close();");

$app->run;
