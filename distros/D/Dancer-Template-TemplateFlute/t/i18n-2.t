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
use MyTestApp::Lexicon2;
my $loc = MyTestApp::Lexicon2->new(prepend => 'X = ', append => ' = Z');

var lang => 'it';
is $loc->try_to_translate('try'), 'X = Sono in italiano = Z';
is $loc->try_to_translate('blabla'), 'blabla';

var lang => 'en';
is $loc->try_to_translate('try'), 'X = I am english now = Z';
is $loc->try_to_translate('blabla'), 'blabla';

diag "Loading the app";

use MyTestApp3;
use Dancer::Test;

my $resp = dancer_response GET => '/en';

response_content_like $resp, qr/X I am english now Z/;

$resp = dancer_response GET => '/it';

response_content_like $resp, qr/X Sono in italiano Z/;


done_testing;
