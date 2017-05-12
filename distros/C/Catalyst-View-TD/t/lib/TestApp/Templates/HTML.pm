package TestApp::Templates::HTML;

use strict;
use warnings;
use Template::Declare::Tags;

template body => sub {
    show 'util/header';
    outs "body\n";
    show 'util/footer';
};

1;
