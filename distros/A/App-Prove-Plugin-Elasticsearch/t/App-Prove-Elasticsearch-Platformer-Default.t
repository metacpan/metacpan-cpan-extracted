use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;
use App::Prove::Elasticsearch::Platformer::Default;

{
    no warnings qw{redefine once};
    local *System::Info::sysinfo_hash = sub { return { osname => 'lunix', 'distro' => 'Zippy OS 6' } };
    use warnings;
    local $] = 'v666';
    cmp_bag( App::Prove::Elasticsearch::Platformer::Default::get_platforms(),['lunix','Zippy OS 6','Perl v666'],"get_platforms returns expected information");
}
