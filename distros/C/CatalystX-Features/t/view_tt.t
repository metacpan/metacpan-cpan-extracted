use strict;
use warnings;
use Test::More;
use B::Deparse;

use FindBin;
use lib "$FindBin::Bin/lib/TestAppTT/lib";

plan skip_all => 'deactivated'; # XXX

eval { require Catalyst::View::TT };
plan skip_all => "View::TT not installed" if $@; 

plan tests => 4;

use_ok 'Catalyst::Test', 'TestApp';

{
    my $resp = request('/test/tt');
    is($resp->content, 'in feature tt', 'feature tt template');
}

{
    my $resp = request('/main');
    is($resp->content, 'in main tt', 'basic tt template' );
}

{
    my $resp = request('/main_to_test');
    is($resp->content, 'in feature tt', 'forward from main app to a feature template');
}

done_testing;


