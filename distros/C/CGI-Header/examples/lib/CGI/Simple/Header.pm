package CGI::Simple::Header;
use strict;
use warnings;
use parent 'CGI::Header';

sub _build_query {
    require CGI::Simple::Standard;
    CGI::Simple::Standard->loader('_cgi_object');
}

1;
