package TestApp::Templates::HTML::User;

use strict;
use warnings;
use Template::Declare::Tags;

template list => sub {
    show '/util/header';
    outs "user list\n";
    show '/util/footer';
};

1;
