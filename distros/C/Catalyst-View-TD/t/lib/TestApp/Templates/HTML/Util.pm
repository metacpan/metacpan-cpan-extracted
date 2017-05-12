package TestApp::Templates::HTML::Util;

use strict;
use warnings;
use Template::Declare::Tags;

template header => sub {
    outs "header\n";
};

template footer => sub {
    outs "footer\n";
};

1;
