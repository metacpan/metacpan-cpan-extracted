#!/usr/bin/env perl

# most CGI.pm scripts i encounter don't use strict or warnings.
# please don't omit these, you are asking for a world of pain
# somewhere down the line if you choose to develop sans strict
use strict;
use warnings;

use FindBin qw/ $Script $Bin /;
use Template;
use CGI qw/ -utf8 /; 

# necessary objects
my $cgi = CGI->new;
my $tt  = Template->new({
    INCLUDE_PATH => "$Bin/templates",
});

# the user input
my $res = $cgi->param( 'user_input' );

# we're using TT but we *still* need to print the Content-Type header
# we can't put that in the template because we need it to be reusable
# by the various other frameworks
my $out = $cgi->header(
    -type    => 'text/html',
    -charset => 'utf-8',
);

# TT will append the output to the passed referenced SCALAR
$tt->process(
    "example_form.html.tt",
    {
        result => $res,
    },
    \$out,
) or die $tt->error;

print $out;
