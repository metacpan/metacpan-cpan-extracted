package TestApp::Templates::NoAlias;

use strict;
use warnings;
use base 'Template::Declare::Catalyst';
use Template::Declare::Tags;
use TestApp::Templates::HTML::Util;

alias TestApp::Templates::HTML::Util under 'here';

template body => sub {
    show 'here/header';
    outs "body\n";
    show 'here/footer';
};

1;
