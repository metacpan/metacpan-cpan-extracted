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


$ENV{PATH_INFO} = '/bee';

stdout_like(
    sub { $app->process() },
    qr/foo_xxx/,
    'swtich to work fine'
);


stdout_like(
    sub {$app->process( 'foo_xxx_bar' ) },
    qr/foo_xxx_bar/,
    'set parameter foo_xx_bar'
);

package BOO ;

use strict;
use warnings;

use CGI::Builder qw/
    CGI::Builder::GetPageName
/;

sub PH_foo_xxx {
    shift->page_content =  'foo_xxx';
}

sub PH_foo_xxx_bar {
    shift->page_content =  'foo_xxx_bar';
    
}

sub PH_index {
    shift->page_content =  'index';
}

sub SH_bee {
    shift->switch_to( 'foo_xxx' );
}

1;
