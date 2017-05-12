package TestApp::View::TD::IncludeOthers;
use strict;
use warnings;
use Template::Declare::Tags;

template includeother => sub {
    p { "This comes before the other template." };
    show('subtemplate');
};

1;
