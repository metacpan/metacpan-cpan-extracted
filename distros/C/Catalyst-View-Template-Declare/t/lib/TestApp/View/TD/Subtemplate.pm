package TestApp::View::TD::Subtemplate;
use strict;
use warnings;
use Template::Declare::Tags;

template subtemplate => sub {
    p { "This is a subtemplate." };
};

1;
