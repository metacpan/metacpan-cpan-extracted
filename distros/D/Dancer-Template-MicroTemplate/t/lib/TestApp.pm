package TestApp;

use strict;
use warnings;
use Dancer ':syntax';
use File::Spec::Functions qw(catdir);

set views   => catdir qw(t views);
set engines => {
    micro_template => {
        line_start => '%',
        tag_start  => '<%',
        tag_end    => '%>',
        extension  => 'mt',
    },
};
set template => 'micro_template';
set logger   => 'console';
set log      => 'warning';

get '/' => sub {
    return template '02-app', {
        var1 => 1,
        var2 => 2,
        foo  => 'one',
        bar  => 'two',
        baz  => 'three'
        }
};

true;
