
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET_STR );
use FindBin;

use lib "$FindBin::Bin/lib";
use Apache2::Controller::Test::Funk qw( diag );
use YAML::Syck;

plan tests => 5;

my $url = "/render";

diag("GET_BODY $url");
my $data = GET_BODY $url;

ok t_cmp($data, "Top level handler.\n", "render test: top level handler");

$data = GET_BODY "$url/foo/bar/biz/baz";
my $dumpstring = "bar:\n".Dump([qw( biz baz )])."\n";
ok t_cmp($data, $dumpstring, "foobar test 2");

my $lame = GET_STR "$url/foo/bar/biz/baz";
diag("LAME:\n".$lame);

#diag("DATA:\n".join(", ", map ord, split '', $data));
#diag("DUMPSTRING:\n".join(", ", map ord, split '', $dumpstring));

$dumpstring = "default:\n".Dump([qw( bismuth cobalt cadmium )])."\n";
$data = GET_BODY "$url/foo/bismuth/cobalt/cadmium";
ok t_cmp($data, $dumpstring, "foobar test 3");

$lame = GET_STR "$url/foo/bismuth/cobalt/cadmium";
diag("LAME:\n".$lame);

$data = GET_BODY "$url/process";
diag($data);
ok t_cmp(
    $data, 
    "This is a test of processing a relative file from TT.\n\n", 
    "relative processing test"
);

$url = "/render/multipath/test";
$data = GET_BODY $url;
ok t_cmp($data, "Render multiple path.\n\n", "render with multiple INCLUDE_PATH");




__END__

