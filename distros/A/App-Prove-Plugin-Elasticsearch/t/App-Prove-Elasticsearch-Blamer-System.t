use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::System;

{
    sub mockeroo {
        return 'zippy';
    }

    no warnings qw{redefine once};
    local *System::Info::sysinfo_hash = sub { return { hostname => 'zippy.test' } };
    local *App::Prove::Elasticsearch::Blamer::System::_get_uname = sub { return 'zippy' };
    use strict;
    is(App::Prove::Elasticsearch::Blamer::System::get_responsible_party(),'zippy@zippy.test',"get_responsible_party returns expected results");
}
