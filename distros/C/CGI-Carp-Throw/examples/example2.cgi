#!/usr/bin/perl -w

#####################################################################
# example2.cgi - Sample/Test program for CGI::Carp::Throw
# Demonstrates use of throw_format_sub to provide template formatted
# throw_browser output.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw qw/:carp_browser throw_format_sub/;
use HTML::Template;

my $t = HTML::Template->new(filehandle => *DATA);

#####################################################################
sub neaterThrowMsg {
    my $throw_msg = shift;
    $t->param(throw_msg => $throw_msg);
    return $t->output;
}
throw_format_sub(\&neaterThrowMsg);

#####################################################################
print header, start_html(-title => 'Throw test'),
    p('expecting parameter: "need_this".');

if (my $need_this = param('need_this')) {
    if ($need_this =~ /^[\s\w.]+$/ and -e $need_this) {
        print h1('Thank you for providing parameter "need_this"'), end_html;
    }
    else {
        croak 'Invalid or non-existent file name: ', $need_this;
    }
}
else {
    throw_browser '***  Please provide parameter: need_this!  ***';
}

__DATA__
<html>
<head><title>A Template</title></head>
<body>
<p style="color: red; font-style: italic"><TMPL_VAR NAME=THROW_MSG></p>
</body>
</html>

