use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;
use App::Prove::Elasticsearch::Blamer::Default;
use Capture::Tiny qw{capture_merged};

{
    my $f = 't/data/bogus/lessbogus/subdir/zippy.t';
    is(App::Prove::Elasticsearch::Blamer::Default::get_responsible_party($f),'TEODESIAN',"get_responsible_party returns correct author in Changes");
    is(App::Prove::Elasticsearch::Blamer::Default::get_responsible_party($f),'TEODESIAN',"get_responsible_party returns correct author when searching cache");
}

{
    my $f = '/bogus/someFileThatDoesNotExist.hokum';
    like(exception { capture_merged { App::Prove::Elasticsearch::Blamer::Default::get_responsible_party($f) } },qr/could not open/i,"get_responsible_party dies on no Changes");
}

{
    my $f = 't/data/bogus/zippy.t';
    like(exception { App::Prove::Elasticsearch::Blamer::Default::get_responsible_party($f) },qr/could not determine/i,"get_responsible_party dies on no author in Changes");
}
