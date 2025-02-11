package MyCatalystApp;
use utf8;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    -Log=fatal
    ConfigLoader
    Static::Simple
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    OIDC
/;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'MyCatalystApp',
    disable_component_resolution_regex_fallback => 1,
    'Plugin::ConfigLoader' => { file => catdir(dirname(__FILE__), '..', 'mycatalystapp.conf') },
);

__PACKAGE__->setup();

1;
