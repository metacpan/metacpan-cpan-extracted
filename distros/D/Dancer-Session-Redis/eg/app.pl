#
# This example is a part of the Dancer-Session-Redis distribution
#

# 1) Start this application server
#       perl app.pl
# 2) Paste and go to the following link in your favourite browser
#       http://localhost:4100/
# 3) ...
# 4) PROFIT!

use strict;
use warnings;
use Dancer;

# some settings
set port          => 4100;
set logger        => 'console';

# set up session
set redis_session => {
    server   => 'localhost:6379',  # this option should be tuned to fit your needs
    database => 3,
    expire   => 3600,
    debug    => 0,
};
set session       => 'Redis';
set session_name  => 'eg_session_id'; # session's cookie name

# route
get '/' => sub {

    # fetch old value
    my $old = session->{counter};

    # prepare new value
    my $new = 1 + (defined $old ? $old : 0);

    # save new value
    session counter => $new;

    # display result
    join '' => 'Session ID: ', session->id, '<br/>', 'Counter: ', $new, '<br/><br/>Reload the page...';

};

dance;
