package TestApp::View::Xslate::SJIS;

use strict;
use base 'Catalyst::View::Xslate';

__PACKAGE__->config(
    content_charset => 'Shift_JIS',
);

1;
