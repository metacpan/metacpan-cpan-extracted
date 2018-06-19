use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::Git;

{
    no warnings qw{redefine once};
    local *Git::command_oneline = sub { return "zippy\n" };
    use warnings;
    is(App::Prove::Elasticsearch::Blamer::Git::get_responsible_party(),'zippy',"get_responsible_party returns correct author from git config");
}
