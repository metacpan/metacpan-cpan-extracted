package
TestApp;

use strict;
use warnings;
use Dancer ':syntax';
use File::Spec::Functions qw(catdir);

set views    => catdir qw(t views);
set engines => {
    xslate => {
        cache     => 0,
        extension => 'tx',
    },
};
set template => 'xslate';
set logger   => 'console';
set log      => 'warning';

get '/' => sub { return template 'index', { loop => [1, 2] } };

true;
