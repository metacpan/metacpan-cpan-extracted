use strict;
use warnings;

use Test::More tests => 8;
use Test::Deep;

use FindBin;
use App::ape::update;

is(App::ape::update->new(),1,"Bad exit code provided when insufficient test args are passed");
is(App::ape::update->new("zippy.test"),4,"Bad exit code provided when insufficient defect args are passed");

no warnings qw{redefine once};
local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return {} };
use warnings;
is(App::ape::update->new(qw{-d YOLO-666 zippy.test}),3,"Bad exit code provided when insufficient configuration passed");

my %args_parsed;
no warnings qw{redefine once};
local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return { 'server.host' => 'zippy.test', 'server.port' => 666} };
local *App::Prove::Elasticsearch::Utils::require_indexer = sub { return 'BogusIndexer' };
local *BogusIndexer::check_index = sub {};
use warnings;
my $obj = App::ape::update->new(qw{-p clownOS -p clownBrowser -v 666.666 -d YOLO-420 -d YOLO-666 zippy.test});
isa_ok($obj,'App::ape::update',"Good object provided when good args are passed to new");
my $args_expected = {
    platforms => ['clownOS', 'clownBrowser'],
    versions  => ['666.666'],
    defects   => ['YOLO-420', 'YOLO-666'],
    status => undef,
};
is_deeply($obj->{options},$args_expected,"Arg Parse seems to work");

no warnings qw{redefine once};

local *BogusIndexer::associate_case_with_result = sub { return 2 };
use warnings;
is($obj->run(),2,"Bad exit code provided when good args are passed, but failure occurs");

like(qx{$FindBin::Bin/../bin/ape update -h},qr/usage/i,"Usage printed when run -h, file is executable");
is($?,0,"Good exit code from binary in -h mode");
