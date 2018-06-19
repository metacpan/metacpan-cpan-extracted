use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal;
use App::Prove::Elasticsearch::Versioner::Git;

{
    no warnings qw{redefine once};
    local *Git::command_oneline = sub { return '666' };
    use warnings;
    is(App::Prove::Elasticsearch::Versioner::Git::get_version(),'666',"get_version returns correct SHA for repo HEAD");
}

{
    no warnings qw{redefine once};
    local *Git::command_oneline = sub { return "@_" };
    use warnings;
    like(App::Prove::Elasticsearch::Versioner::Git::get_file_version('whee'),qr/whee/,"get_file_version returns correct SHA");
}
