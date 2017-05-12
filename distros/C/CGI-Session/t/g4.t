# $Id$

use strict;


use File::Spec;
use CGI::Session::Test::Default;
use Test::More;

my $t = CGI::Session::Test::Default->new(
    args=>{Directory=>File::Spec->catdir('t', 'sessiondata')});

plan tests => $t->number_of_tests;
$t->run();
