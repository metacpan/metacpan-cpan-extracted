use strict;
use warnings;
use Test::More;
use B::Deparse;

use FindBin;
use lib "$FindBin::Bin/lib/TestAppI18N/lib";

eval { require Catalyst::Plugin::I18N };
plan skip_all => "Catalyst::Plugin::I18N not installed" if $@; 

plan tests => 3;

use_ok 'Catalyst::Test', 'TestApp';

{
    my $resp = request('/loc');
    is($resp->content, 'tontoculo', 'basic localization');
}

{
    my $resp = request('/test/loc');
    is($resp->content, 'chungo', 'feature localization');
}

done_testing;

