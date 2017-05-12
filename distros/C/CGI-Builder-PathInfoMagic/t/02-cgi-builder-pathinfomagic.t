use strict;
use warnings;

use Test::More qw/no_plan/;
use Test::Output;

my $app = BOO->new();

$ENV{PATH_INFO} = '/foo/xxx';

stdout_like( 
    sub {$app->process() },
    qr/foo_xxx/,
    '/foo/xxx map to PH_foo_xxx'
);

$ENV{PATH_INFO} = '/foo/xxx/bar';

stdout_like(
    sub {$app->process() },
    qr/foo_xxx_bar/,
    '/foo/xxx/bar map to PH_fff_xxx_bar'
);


$ENV{PATH_INFO} = '/';


stdout_like(
    sub {$app->process() },
    qr/index/,
    '/ map to PH_index'
);


package BOO ;

use strict;
use warnings;

use CGI::Builder::PathInfoMagic;

sub PH_foo_xxx {
    shift->page_content =  'foo_xxx';
}

sub PH_foo_xxx_bar {
    shift->page_content =  'foo_xxx_bar';
    
}

sub PH_index {
    shift->page_content =  'index';
}
1;
