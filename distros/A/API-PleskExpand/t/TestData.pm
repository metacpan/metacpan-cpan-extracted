package TestData;

use strict;
use warnings;

my $online_expand_url = 'https://your.true.host.ru:8442/webgate.php';

our %online_expand_valid_params = (
    api_version   => $ENV{'expand_api_version'}  || '2.2.4.1',
    username      => $ENV{'expand_username'}     || 'root',
    password      => $ENV{'expand_password'}     || 'qwerty',
    url           => $ENV{'expand_url'}          || $online_expand_url,
    debug         => '',
    request_debug => '',
);

