use Test::More;

use App::MakeEPUB;

# Tests regarding the toc.ncf file
# ================================

my ($npa,$np_ref,$args,$nps);

$npa  = [
    [ 'file1.html', '', 'No Anchor' ],
    [ 'file1.html', 'anchor1', 'First Anchor' ],
    [ 'file1.html', 'anchor2', 'Second Anchor' ],
];
$np_ref = <<EONP;
<navPoint id="navpoint-2" playOrder="2">
  <navLabel><text>No Anchor</text></navLabel>
  <content src="file1.html" />
</navPoint>
<navPoint id="navpoint-3" playOrder="3">
  <navLabel><text>First Anchor</text></navLabel>
  <content src="file1.html#anchor1" />
</navPoint>
<navPoint id="navpoint-4" playOrder="4">
  <navLabel><text>Second Anchor</text></navLabel>
  <content src="file1.html#anchor2" />
</navPoint>
EONP
$args = { counter => 2, array => $npa, indent => '' };
$nps = App::MakeEPUB::_tocncf_navPoints_from_array($args);

is($args->{counter}, 5, "counter updated");
is($nps, $np_ref, "correct navPoint string");

$args->{array} = [
    [ 'file2.html', 'anchor1', 'First Anchor', "    <!-- extra -->\n"],
];
$np_ref = <<EONP;
  <navPoint id="navpoint-5" playOrder="5">
    <navLabel><text>First Anchor</text></navLabel>
    <content src="file2.html#anchor1" />
    <!-- extra -->
  </navPoint>
EONP
$args->{indent} = '  ';
$nps = App::MakeEPUB::_tocncf_navPoints_from_array($args);

is($args->{counter}, 6, "counter updated");
is($nps, $np_ref, "correct navPoint string");

done_testing();
