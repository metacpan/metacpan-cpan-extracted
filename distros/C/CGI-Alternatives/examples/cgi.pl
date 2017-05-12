#!/usr/bin/env perl

# most CGI.pm scripts i encounter don't use strict or warnings.
# please don't omit these, you are asking for a world of pain
# somewhere down the line if you choose to develop sans strict
use strict;
use warnings;

use CGI qw/ -utf8 /; 

my $cgi  = CGI->new;
my $res  = $cgi->param( 'user_input' );
my $out  = $cgi->header(
    -type    => 'text/html',
    -charset => 'utf-8',
);

# html output functions. at best this is a lesson in obfuscation
# at worst it is an unmaintainable nightmare (and i'm using
# relatively clean perl code and a very very simple example here)
$out .= $cgi->start_html( "An Example Form" );

$out .= $cgi->start_form(
    -method  => "post",
    -action  => "/example_form",
);

$out .= $cgi->p(
    "Say something: ",
    $cgi->textfield( -name => 'user_input' ),
    $cgi->br,
    ( $res ? ( $cgi->br, "You wrote: $res" ) : () ),
    $cgi->br,
    $cgi->br,
    $cgi->submit,
);

$out .= $cgi->end_form;
$out .= $cgi->end_html;

print $out;
