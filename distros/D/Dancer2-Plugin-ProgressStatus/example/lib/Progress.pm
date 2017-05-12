=head1 DESCRIPTION

A sample dancer app that demonstrates a simple progress bar.
Both a text update and a bootstrap based progress bar

=cut

package Progress;
use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::ProgressStatus;

# Landing demo page.
# Shows a link and some progress text
get '/' => sub {
    return <<'EOF';
<html>
<head>
<link href="//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" rel="stylesheet">
<script src="//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
<script src="/client_progress.js"></script>
<script type="text/javascript">
    $(function() {
        $('#longrunninglink').click(function() {
            // Issue the long running task in the background for demo purposes
            $.getJSON('/start_long_task/test');

            // wait a second to ensure the first call arrives
            // first, then start monitoring the progress
            setTimeout(function() {
                checkProgress('test', function(data) {
                var progress = Math.round((data.count / data.total ) * 100);
                    $('#progress').html(progress + '%');
                    $('.progress-bar').width(progress + '%');
                });
            }, 1000);
        });
    });
</script>
</head>
<body>
<h1>Demo for progress bar</h1>

<div>
<a id="longrunninglink" href="#">
Click here
</a> to start a long running server task in the background.
</div>

<!-- plain text % status -->
<div id="progress"></div>

<!-- this is a bootstrap progressbar, requires bootstrap css loaded  -->
<div id="progressbar" class="progress progress-striped active">
    <div class="progress-bar" style="width: 1%;"></div>
</div>

</body>
</html>
EOF
};

## This loads the long running query and takes about 30 seconds before
## it returns a single string "ok"
get '/start_long_task/:name' => sub {
    if ( is_progress_running(param('name')) ) {
        return 'Progress "test" is already running, please wait until it finishes';
    }

    my $prog = start_progress_status(param('name'));

    foreach my $i (1..30) {
        $prog++;
        $prog->add_message("finished $i");
        sleep 1;
    }
    $prog->count(100);

    content_type 'text/plain';
    return "ok";
};

1;
