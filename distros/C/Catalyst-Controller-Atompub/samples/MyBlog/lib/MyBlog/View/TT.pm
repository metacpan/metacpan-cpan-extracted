package # hide from PAUSE
    MyBlog::View::TT;

use strict;
use base qw(Catalyst::View::TT);

__PACKAGE__->config({
    CATALYST_VAR => 'Catalyst',
    INCLUDE_PATH => [
        MyBlog->path_to('root', 'src'),
        MyBlog->path_to('root', 'lib')
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt2',
});

1;

