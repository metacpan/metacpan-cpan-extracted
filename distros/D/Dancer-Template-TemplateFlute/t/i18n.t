#! perl

use strict;
use warnings;

use Test::More;
use Dancer qw/:tests/;

use File::Spec;
use Data::Dumper;

use lib File::Spec->catdir( 't', 'lib' );

set template => 'template_flute';
set views => File::Spec->catdir('t', 'views');
set log => 'debug';
set logger => 'console';
set session => 'Simple';
# here this isn't picked up. Set in the module.
# set engines => { template_flute => { i18n => { class => 'MyTestApp::Lexicon' } } };

diag "Testing baby module";
use MyTestApp::Lexicon;
my $loc = MyTestApp::Lexicon->new;

var lang => 'it';
is $loc->localize('try'), 'Sono in italiano';
is $loc->localize('blabla'), 'blabla';

var lang => 'en';
is $loc->localize('try'), 'I am english now';
is $loc->localize('blabla'), 'blabla';

diag "Loading the app";

use MyTestApp2;
use Dancer::Test;

my $resp = dancer_response GET => '/en';

response_content_like $resp, qr/I am english now/;

$resp = dancer_response GET => '/it';

response_content_like $resp, qr/Sono in italiano/;


done_testing;
