use strict;
use warnings;
use utf8;
use CGI::Tiny ();
use Test::More;
use Time::Local 'timegm';

my $epoch_2digit = timegm(37, 49, 8, 6, 10, 94);

is CGI::Tiny::epoch_to_date(784111777), 'Sun, 06 Nov 1994 08:49:37 GMT', 'right date string';
is CGI::Tiny::date_to_epoch('Sun, 06 Nov 1994 08:49:37 GMT'), 784111777, 'right epoch';
is CGI::Tiny::date_to_epoch('Sunday, 06-Nov-94 08:49:37 GMT'), $epoch_2digit, 'right epoch';
is CGI::Tiny::date_to_epoch('Sun Nov  6 08:49:37 1994'), 784111777, 'right epoch';
is CGI::Tiny::date_to_epoch('arbitrary string'), undef, 'no epoch value';

my $time = time;
is CGI::Tiny::date_to_epoch(CGI::Tiny::epoch_to_date($time)), $time, 'round-trip epoch';

is CGI::Tiny::escape_html('&<>"\''), '&amp;&lt;&gt;&quot;&#39;', 'escaped unsafe HTML characters';
is CGI::Tiny::escape_html('&&&&&;'), '&amp;&amp;&amp;&amp;&amp;;', 'escaped many ampersands';
is CGI::Tiny::escape_html('☃'), '☃', 'nothing to escape';

done_testing;
