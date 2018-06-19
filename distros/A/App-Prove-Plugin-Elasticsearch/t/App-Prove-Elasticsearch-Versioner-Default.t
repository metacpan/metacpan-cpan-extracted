use strict;
use warnings;

use Test::More tests => 4;
use Test::Fatal;
use Capture::Tiny qw{capture_merged};
use App::Prove::Elasticsearch::Versioner::Default;

{
    my $t = 't/data/bogus/zippy.t';
    is(App::Prove::Elasticsearch::Versioner::Default::get_version($t),'0.111.1112.2.2.3',"get_version returns correct version in Changes");
    is(App::Prove::Elasticsearch::Versioner::Default::get_version($t),'0.111.1112.2.2.3',"get_version returns correct version when searching cache");
}

{
    my $t = '/bogus/someFileThatDoesNotExist.hokum';
    like(exception { capture_merged { App::Prove::Elasticsearch::Versioner::Default::get_version($t) } },qr/could not open/i,"get_version dies on no Changes");
}

{
    my $t = 't/data/bogus/morebogus/zippy.t';
    like(exception { App::Prove::Elasticsearch::Versioner::Default::get_version($t) },qr/could not determine/i,"get_version dies on no author in Changes");
}
