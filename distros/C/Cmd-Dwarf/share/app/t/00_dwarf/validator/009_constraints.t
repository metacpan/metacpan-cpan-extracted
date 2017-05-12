use strict;
use warnings;
use utf8;
use Test::Base::Less;
use Dwarf::Validator;
use Dwarf::Request;
use Hash::MultiValue;

filters {
	query    => [qw/eval/],
	rule     => [qw/eval/],
	expected => [qw/eval/],
};

for my $block (blocks) {
	my $q = Dwarf::Request->new({ env => {} });
	$q->env->{'dwarf.request.merged'} = Hash::MultiValue->from_mixed($block->query);

	my $v = Dwarf::Validator->new($q);
	$v->check(
		$block->rule
	);

	my @expected = $block->expected;
	while (my ($key, $val) = splice(@expected, 0, 2)) {
		is($v->is_error($key), $val, $block->name);
	}
}

done_testing;

__END__

=== NOT_NULL
--- query: { hoge => 1, zero => 0, blank => "", undef => undef, multi => 1, multi => undef, }
--- rule
(
	hoge      => [qw/NOT_NULL/],
	zero      => [qw/NOT_NULL/],
	blank     => [qw/NOT_NULL/],
	undef     => [qw/NOT_NULL/],
	missing   => [qw/NOT_NULL/],
	multi     => [qw/NOT_NULL/],
	'array[]' => [qw/NOT_NULL/],
);
--- expected
(
	hoge      => 0,
	zero      => 0,
	blank     => 0,
	undef     => 1,
	missing   => 1,
	multi     => 1,
	'array[]' => 1,
)

=== REQUIRED
--- query: { hoge => 1, zero => 0, blank => "", undef => undef }
--- rule
(
	hoge    => [qw/REQUIRED/],
	zero    => [qw/REQUIRED/],
	blank   => [qw/REQUIRED/],
	undef   => [qw/REQUIRED/],
	missing => [qw/REQUIRED/],
);
--- expected
(
	hoge    => 0,
	zero    => 0,
	blank   => 0,
	undef   => 1,
	missing => 1,
)

=== NOT_BLANK
--- query: { hoge => 1, zero => 0, blank => "", undef => undef }
--- rule
(
	hoge    => [qw/NOT_BLANK/],
	zero    => [qw/NOT_BLANK/],
	blank   => [qw/NOT_BLANK/],
	undef   => [qw/NOT_BLANK/],
	missing => [qw/NOT_BLANK/],
);
--- expected
(
	hoge    => 0,
	zero    => 0,
	blank   => 1,
	undef   => 1,
	missing => 1,
)

=== INT
--- query: { hoge => '1', fuga => '-1', hoga => 'ascii', foo => "1\n" }
--- rule
(
	hoge => [qw/INT/],
	fuga => [qw/INT/],
	hoga => [qw/INT/],
	foo  => [qw/INT/],
)
--- expected
(
	hoge => 0,
	fuga => 0,
	hoga => 1,
	foo  => 1,
)

=== UINT
--- query: { hoge => '1', fuga => '-1', hoga => 'ascii', foo => "1\n" }
--- rule
(
	hoge => [qw/UINT/],
	fuga => [qw/UINT/],
	hoga => [qw/UINT/],
	foo  => [qw/UINT/],
)
--- expected
(
	hoge => 0,
	fuga => 1,
	hoga => 1,
	foo  => 1,
)

=== NUMBER
--- query: { hoge => '1.0', fuga => '-1.1', hoga => 'ascii' }
--- rule
(
	hoge => [qw/NUMBER/],
	fuga => [qw/NUMBER/],
	hoga => [qw/NUMBER/],
	foo  => [qw/NUMBER/],
)
--- expected
(
	hoge => 0,
	fuga => 0,
	hoga => 1,
)

=== EQUAL
--- query: { 'z1' => 'foo', 'z2' => 'foo' }
--- rule
(
	'z1' => [[EQUAL => 'foo']],
	'z2' => [[EQUAL => 'bar']],
)
--- expected
(
	z1 => 0,
	z2 => 1,
)

=== BETWEEN
--- query: { num => 5 }
--- rule
(
	num => [
		[BETWEEN => 1, 10],
	],
)
--- expected
(
	num => 0,
)

=== BETWEEN
--- query: { num => 5 }
--- rule
(
	num => [
		[BETWEEN => 6, 10],
	],
)
--- expected
(
	num => 1,
)

=== BETWEEN
--- query: { num => 5 }
--- rule
(
	num => [
		[BETWEEN => 1, 4],
	],
)
--- expected
(
	num => 1,
)

=== LESS_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_THAN => 5],
	],
)
--- expected
(
	num => 1,
)

=== LESS_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_THAN => 6],
	],
)
--- expected
(
	num => 0,
)

=== LESS_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_EQUAL => 5],
	],
)
--- expected
(
	num => 0,
)

=== LESS_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[LESS_EQUAL => 4],
	],
)
--- expected
(
	num => 1,
)

=== MORE_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_THAN => 5],
	],
)
--- expected
(
	num => 1,
)

=== MORE_THAN
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_THAN => 4],
	],
)
--- expected
(
	num => 0,
)

=== MORE_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_EQUAL => 5],
	],
)
--- expected
(
	num => 0,
)

=== MORE_EQUAL
--- query: { num => 5 }
--- rule
(
	num => [
		[MORE_THAN => 6],
	],
)
--- expected
(
	num => 1,
)

=== ASCII
--- query: { hoge => 'abcdefg', fuga => 'あbcdefg' }
--- rule
(
	hoge => [qw/ASCII/],
	fuga => [qw/ASCII/],
)
--- expected
(
	hoge => 0,
	fuga => 1,
)

=== LENGTH
--- query: { 'z1' => 'foo', 'z2' => 'foo', 'z3' => 'foo', 'x1' => 'foo', x2 => 'foo', x3 => 'foo' }
--- rule
(
	z1 => [['LENGTH', '2']],
	z2 => [['LENGTH', '3']],
	z3 => [['LENGTH', '4']],
	x1 => [['LENGTH', '2', '2']],
	x2 => [['LENGTH', '2', '3']],
	x3 => [['LENGTH', '2', '4']],
)
--- expected
(
	z1 => 1,
	z2 => 0,
	z3 => 1,
	x1 => 1,
	x2 => 0,
	x3 => 0,
)

=== DATE
--- query: { y => 2009, m => 2, d => 30 }
--- rule
(
	{date => [qw/y m d/]} => ['DATE'],
)
--- expected
(
	date => 1,
)

=== DATE
--- query: { y => 2009, m => 2, d => 28 }
--- rule
(
	{date => [qw/y m d/]} => ['DATE'],
)
--- expected
(
	date => 0,
)

=== DATE-NOT_NULL
--- query: {  }
--- rule
(
	{date => [qw/y m d/]} => ['DATE', 'NOT_NULL'],
)
--- expected
(
	date => 1,
)

=== DATE
--- query: { date => '2009-02-28' }
--- rule
(
	date => ['DATE'],
)
--- expected
(
	date => 0,
)

=== DATE with blank arg.
--- query: { y => '', m => '', d => ''}
--- rule
(
	{date => [qw/y m d/]} => ['DATE'],
)
--- expected
(
	date => 1,
)

=== TIME should success
--- query: { h => 12, m => 0, s => 30 }
--- rule
(
	{date => [qw/h m s/]} => ['TIME'],
)
--- expected
(
	date => 0,
)
 
=== TIME should fail
--- query: { h => 24, m => 0, s => 0 }
--- rule
(
	{date => [qw/h m s/]} => ['TIME'],
)
--- expected
(
	date => 1,
)

=== TIME-NOT_NULL
--- query: {  }
--- rule
(
	{date => [qw/h m s/]} => ['TIME', 'NOT_NULL'],
)
--- expected
(
	date => 1,
)

=== TIME
--- query: { time => '12:30:00' }
--- rule
(
	date => ['TIME'],
)
--- expected
(
	date => 0,
)

=== TIME should not warn with ''
--- query: { h => '', m => '', s => ''}
--- rule
(
	{date => [qw/h m s/]} => ['TIME'],
)
--- expected
(
	date => 1,
)

=== HTTP_URL
--- query: { p1 => 'http://example.com/', p2 => 'foobar', }
--- rule
(
	p1 => ['HTTP_URL'],
	p2 => ['HTTP_URL'],
);
--- expected
(
	p1 => 0,
	p2 => 1,
)

=== EMAIL
--- query: { p1 => 'http://example.com/', p2 => 'foobar@example.com', p3 => 'foo..bar.@example.com', p4 => '日本語@docomo.ne.jp' }
--- rule
(
	p1 => ['EMAIL'],
	p2 => ['EMAIL'],
	p3 => ['EMAIL'],
	p4 => ['EMAIL'],
);
--- expected
(
	p1 => 1,
	p2 => 0,
	p3 => 1,
	p4 => 1,
)

=== EMAIL_LOOSE
--- query: { p1 => 'http://example.com/', p2 => 'foobar@example.com', p3 => 'foo..bar.@example.com', p4 => '日本語@docomo.ne.jp' }
--- rule
(
	p1 => ['EMAIL_LOOSE'],
	p2 => ['EMAIL_LOOSE'],
	p3 => ['EMAIL_LOOSE'],
	p4 => ['EMAIL_LOOSE'],
);
--- expected
(
	p1 => 1,
	p2 => 0,
	p3 => 0,
	p4 => 1,
)

=== HIRAGANA
--- query: { hoge => 'ひらがなひらがな', fuga => 'カタカナ', haga => 'asciii', hoga => 'ひらがなと  すぺえす'}
--- rule
(
	hoge => [qw/HIRAGANA/],
	fuga => [qw/HIRAGANA/],
	hoga => [qw/HIRAGANA/],
	haga => [qw/HIRAGANA/],
);
--- expected
(
	hoge => 0,
	fuga => 1,
	hoga => 0,
	haga => 1,
)

=== KATAKANA
--- query: { 'p1' => 'ひらがなひらがな', 'p2' => 'カタカナ', 'p3' => 'カタカナ ト スペエス', p4 => 'ascii'}
--- rule
(
	p1 => [qw/KATAKANA/],
	p2 => [qw/KATAKANA/],
	p3 => [qw/KATAKANA/],
	p4 => [qw/KATAKANA/],
);
--- expected
(
	p1 => 1,
	p2 => 0,
	p3 => 0,
	p4 => 1,
)

=== JTEL
--- query: { 'p1' => '666-666-6666', 'p2' => '03-5555-5555'}
--- rule
(
	p1 => [qw/JTEL/],
	p2 => [qw/JTEL/],
);
--- expected
(
	p1 => 1,
	p2 => 0,
)

=== JZIP
--- query: { 'p1' => '155-0044', 'p2' => '03-5555-5555'}
--- rule
(
	p1 => [qw/JZIP/],
	p2 => [qw/JZIP/],
);
--- expected
(
	p1 => 0,
	p2 => 1,
)

=== DUPLICATION
--- query: { 'z1' => 'foo', 'z2' => 'foo', 'z3' => 'fob' }
--- rule
(
	{x1 => [qw/z1 z2/]} => ['DUPLICATION'],
	{x2 => [qw/z2 z3/]} => ['DUPLICATION'],
	{x3 => [qw/z1 z3/]} => ['DUPLICATION'],
)
--- expected
(
	x1 => 0,
	x2 => 1,
	x3 => 1,
)

=== REGEX
--- query: { 'z1' => 'ba3', 'z2' => 'bao' }
--- rule
(
	z1 => [['REGEX',  '^ba[0-9]$']],
	z2 => [['REGEXP', '^ba[0-9]$']],
)
--- expected
(
	z1 => 0,
	z2 => 1,
)

=== CHOICE
--- query: { 'z1' => 'foo', 'z2' => 'quux' }
--- rule
(
	z1 => [ ['CHOICE' => [qw/foo bar baz/]] ],
	z2 => [ ['IN'     => [qw/foo bar baz/]] ],
)
--- expected
(
	z1 => 0,
	z2 => 1,
)

=== NOT_IN
--- query: { 'z1' => 'foo', 'z2' => 'quux', z3 => 'hoge', z4 => 'eee' }
--- rule
(
	z1 => [ ['NOT_IN', [qw/foo bar baz/]] ],
	z2 => [ ['NOT_IN', [qw/foo bar baz/]] ],
	z3 => [ ['NOT_IN', []] ],
	z4 => [ ['NOT_IN'] ],
)
--- expected
(
	z1 => 1,
	z2 => 0,
	z3 => 0,
	z4 => 0,
)

=== MATCH
--- query: { 'z1' => 'ba3', 'z2' => 'bao' }
--- rule
(
	z1 => [[MATCH => sub { $_[0] eq 'ba3' } ]],
)
--- expected
(
	z1 => 0,
)

=== BASE64_TYPE
--- query: { 'image' => 'iVBORw0KGgoAAAANSUhEUgAABLAAAAMgCAMAAAAEPmswAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyRpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1NzowMSAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNS4xIE1hY2ludG9zaCIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpEQTcwNDRFRjkzRDcxMUU0ODZENkExQkRFRjY2MEM5OCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpEQTcwNDRGMDkzRDcxMUU0ODZENkExQkRFRjY2MEM5OCI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOkRBNzA0NEVEOTNENzExRTQ4NkQ2QTFCREVGNjYwQzk4IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOkRBNzA0NEVFOTNENzExRTQ4NkQ2QTFCREVGNjYwQzk4Ii8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+eVsU6wAAADNQTFRFv7+/f39/Pz8/Dw8P7+/vn5+fX19f39/fz8/PLy8vHx8fT09Pj4+Pr6+vb29vAAAA/////mb22AAAH6BJREFUeNrs3duCoza6gFHOmIPtfv+n3ZV0JruP6RIIIcFal3MxKVs/X4OMcfUFoBCVtwAQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAMECECwAwQIEC0CwcjBacEy4YJWxluv0NtGYcMEqYy0/GGpMuGBlruub91fmGhMuWHmv5fL+l9HGhAtWGWspWJhwwcrXD2spWJhwwcrUc2jfb8HChAtWmWspWJhwwSpmLQULEy5YeXm8fruWgoUJF6ys1nJ+/yfjjgkXrDLWUrAw4YKVhfETaylYmHDBymAtv36NynJy1VqZ8MsE6/NrKViYcME6V8BaChYmXLDO9bacXJoJFyww4YJlOcGEC5blRLBMuGCBCRcsywkmXLAsJ4IlWJYTTLhgWU4w4YJlOREswbKcYMIFy3KCCRcsy4lgCZblBBMuWJYTTLhgWU4ES7AsJ5hwwbKcYMIFS7AQLMGynGDCBctyggkXLMFCsATLcoIJFyzLCSZcsAQLEy5YlhNMuGBZTjDhgiVYmHDBspxgwgXLciJYJlywwIQLluUEEy5YlhPBMuGCBSZcsCwnmHDBspwIlmBZTjDhgmU5wYQLluVEsATLcoIJFyzLCSZcsCwngiVYlhNMuGBZTjDhgmU5ESzBspxgwgXLcoIJFyzBQrAEy3KWtrZVX9dN00w/vgsf/9tS1331uN3BX1XrL9+Sj/+pqeu1qjoTLliWM7HHs16a9jPvR9sMdTXe5S351IhMzSuvt8SEC9aF13Mdpnew5tVft1qPjW/JWplwwbKch+mer+a9Xbus17tErOo9b8lHtZ6jCRcsyxl/HV/Te7926LvLvCXjukR4S97zcPLZpwkXrIudWvVL+45mWq9wdfiIEvB/35NXZcIF69dHXxUmbDmruPKo1Tu20ps1vubo70k7PDsTLlg//0HvglyxVl8tfbnnm9M76zfFhAvWPZfzMbQHvra2LvE069j35OM8qzLhgmU5szqR+NdQ2g5n3xy/5vPekJtwwbrdco6vNskLbEpKVj8nWvalMuGCZTkDrnvSvcS5l6u474oJF6xbLWfVpH2RRZxlJc3V1y2+zoQLluXMLVd/Jyv3W+Cr+YTF35osEy5Yt1nOsTnnhQ453wB/1puyMVkmXLBuspzjcNorbddcc9XVJw7AlrfFhAvWPZazbs98rZleF55yNfjt9vvThAuW5fzZcz771dYZnl69zh+CZjThgmU5f7gaXDJ4uVNuJ1mPOYsxeJhwwbKc31rbPF5wXjtZdR5vSmvCBcty5vAx2M+WfD4u7HJ5VwYTLliWM7/Tq6+bzLlcFmZyORh8RWjCBevSy9k1mb3oPL6r02dT8cmEC5bl/PfDwTa7Vz1kMCZ1Pm/HasIFy3L+45Xjy25O38gaMno3OhMuWJbz6277lOfrns59tl9WV8mLCRcsy/n1vWhzfeHtmVvvXVYZd6e7YFnOr58OZvzKTyxWXr1qTbhgWc7c9ml+caBWevWXlwkXLMuZ4d0MP+n16sNowgXLcma73X52sXLr1WTCBctyfnm0Jbz8E4ZnKD/aJlywrracZfTqhJ337Pb1OhMuWLdfzr4t5PWnLlaf2xswmHDBuv1y9uW8Ae1479moTLhg3X05Y/Zqapr6W0sT+cPHKeG3dMbsTjxnEy5Yd1/OOL1qm7qvfhOT6lkP0T5sa9KNRoy/eW5edVV9dyX7qKq1fjVb/t9rEy5YN1/OCL2ah/4TV2rVukQ5Y0n27Ia93wNvl7r6z/PBsaqXsGyNJlyw7r2cu3u19AFH0aOOcNbSlzAYU/3Zzwc+qvXZkDcmXLDuvZw772dY+uAtpXHd3awkHxV2O96ZeQ08FXqsy3GpFizBuspy7urVvG7cAB9f+zLZpth43/6rQcO2GX8Of3oGc2vCBevWy7nnY7Bl10r2u06zEmy8PzfnaseNF4/XfMDunWAJ1jWWc8f35Ibd90NVe+53OPwnVrdeEO5+X6qhjX0pLFiXCtZYhwk8suLK5GP7Icrtm3uSdfQYbfuEsImxu9b97uxzNuGCFa7wfzC+sfV7ck20u837zb+cNR+7jfXYtLUW7VdfH79cmtWEC9aNl3Pj80XnmCvYbf4xmuXQ92bLuV/U58539c9Xhp0JF6z7LufGXeXY5+yPrdeFzyOHdMPf84r8N3Q/nn4uJlyw7ruc225omA64BWrjSdaR9zaEX6m2R9zN+n2yniZcsG67nNs+IDxmS3Tjb8Afd8YRfvf/UY+9+ea5P60JF6z7Ludw9u7Vd/XcdpPmYaM059Krb/eyXiZcsG67nFu+QXjkzy9v+gDgqE8K+3x69Vey/vm3ZTThgnXX5dyygXXsHTKbnnl60J8059Srvw6Zvy7fJxMuWHddzg0bWG2fYUOPOeuosrk0/f8T0DblLwYJlmDlJfw27gTPUt9SrEO+Uxi6oZbifs5u6Ey4YN10OcPvwJpTPNBlS7EOmKYx9GtKlztEBUuwsrogDA5DoueobyjWHP+vCDz9nDvBEizLeaAl015tKlb8rZ05tw0sEy5Yd17OZ7a92lKs6Pe7B749ry+CJViWM6MLwpS/q7XhS3yxb20Yzu2lCRcsy7n9gEy+R9OffYoV1vP1i2AJluXM5xQm9W/Dh39nKO4pVtgV4fxFsATLch5ozrxX4Y9BjXuKFdbLXrAEy3IeKPRRLicckcE/jBH1FKu9/Q6WYAlWNkJjcMoTtp8nnmJV+b89JlywbrOcgbdgLef8laHfHIq48x12BjoKlmBZzgPf+4xvaPhGF7jRFnHrO+h5zc0XwRIsy3mcsP3sEzbct4U14k6bLXfBEqxc9O9SjsfAexumc0o5CpZgWc5crrSWM//UwA8HYg1VfUomTbhgWc6dR+PJTyEIPBmM9YiXoA8lXoIlWJYzl7OWk9cp8PbRSHUNOgd9CpZgWc5MTrDOPn0I3HdfT1jbTrAEy3LmcYJ1/mPpwn4Qek5fyfmLYAmW5czjBOv8y53HCdvuQTtnjWAJluXM4wRryeAvDru1Icq2e1DUa8ESLMuZxQlWm8MdRoE/BhHjGnYRLMESrPJOsPI4FsN2sfrU/8VKsATLch4k6KfgM/khmLAPCmNsKbWCJViClYM59clK+lOsMfHSCpZgWc6DlPnxV9jt7qtgCZZgXWM5pzKPxKBLtP1f7ascqIIlWKXtBmV0f1Hix+kJlmAJVg6GQi91xrTXhGHBegiWYFnO04/7rG7gTvsA0MoelmAJVmFXVlmtT9i2eydYgiVY5S/nXOoJVuD9rr1gCZZgFb+cQT+bldlDnoJ234akwVoFS7As5wFCviGX2zNTgmLbJg2W7xIKluU8wJjyqiq6oGvCR8pgLYIlWJYzvpCvEeb32+spH6AQFqxJsATLcsYXsuWe3+8qpPxSUeVIFSzBOlnQkzvz+6W9LuGNDYHBqgRLsCxnbK/Cn/ob9DXIfZ9xBj6VeRUswbKcZ14R5vjb60F3vb5SLu0iWIJlOSMLuS+gzXJeEm6Ehy3tZX/nS7AE6zQhd14O5b/fCS8/8zwhFSzBKno5Q+5jyvP5AwkftN64JhQswSrlgirTXwZN+Ntbr8BrwlGwBMtyxhRyCL4yHZh0Jz1rYLBqwRIsyxnTXP75QtCdWG26Nmb5xQDBEqySl/NR/hVh4Fb4mKyN1z3FEizBOsla/hVh4CNm9t06OjvFEizBKuPkJNtnlCfcdV9CT7EGwRIsy3nG9s+c78Sk+/5z6K77Nb9QKFiCdY7+EucKCXfdH8HBmjvBEizLmX7355nvOx70EL8u3X/qqheFgiVY55ivMXcJ73UfgoN1wS/oCJZgneKRbO/nWEE3oO/bde/Dg3W9X1QVLME6xZrsOD9Wne4SrdsQrPYhWIJlOfdbLnKakPBjwvAbGy54N5ZgCdYpAnaQ2y9XCdbOV7LlmvA9dYIlWJbTFtaWtzxd5b8p1kOwBMtypjtZqK/zlu8csGFLsK61jyVYgnWGId1RfrCEP0Sx4d7Rr8WqBEuwLOce82WmLuhGrDrlf+wbq2AJluXcLuQT+sx/xTjoo7u9T53oNwbrPXSCJViWc/MbfZ3vlwTdiLX784N5a7GusvUuWIKV+VG+XihYu88WN59ivdtVsATLch6/F1NdKFj73/LNp1gfp3ejYAmW5dyivc7QVWnf8u2nWNc4yRIswUpvvM6ee2Cw9k/YjlOsK5xkCZZg5X2QL4K147/3840VnQkXLMt53L5PfalgRXgUYbOvWHNvwgXLcgZZ0h7iGQUrQn7H905NZcIFy3IGmJJeROWzHxfnfLHeW6z3MJpwwbKch/yZ13rPo1zgTu/7JkuwBCu5kO/wttd6z5vU799v39dCd98FS7CSe17mYVjnBCvCRWGxyRIswUou5HhbBOuYi8JCkyVYgpXckHrT53LBGtt3nGQVt5clWIKVXPO+rVhbcs9of1FhyRIswUquvW+wor3ndbw/aalMuGBZzlh/pWD90hLxj2p6Ey5YlvN377JgRdBNMf+see1MuGBZTsE67D0f415Zt6/RhAuW5Tx0++XOwfryiL0XWMJmlmAJlmCVGawod7z/cGXYdyZcsCzndxrBiqSP//flfmeWYAmWYJUarCOK9X43TxMuWJbzX7Ng5V2snK8MBUuw8v4jBeuEYr3bejThgmU5BSu251HfG8hzM0uwBCv1myxYUT0O+6bTUJlwwRIswSqlWBk+/l2wBEuwyg5W5G/p5J0swRKsxGrBil6s5X2XZAmWYAlW6cE6+E3N6feiBUuwBKv8YB33YWFmnxgKlmAlNgjWER7ToX93Lo9/FyzBSqwRrGM2so79l6BdTbhgCdbNHPqrZf2xz56eKhMuWIIlWKVcFr6X0YQLlmAJVimfaJx/XShYgpVYK1hHjvDBz8KYHiZcsG61nG/BOlL3Ovgl1CZcsATrJl4J3uCjd7JOPckSLMESrHTSnJ7U7WVPsgRLsATrasH6Mi4Hn2SNJlywBEuwStl8b3sTLliCdXkJf9/h4OvCoTPhgiVYF5dywg7+rs45e++CJViCdc1gffkyHnqTbvs04YIlWJeW+qykOjRZtQkXLMG6shNm+sjd9/QbWYIlWDn/jVNzLWe84f2ByZo6Ey5YgnXSns9VHZis1FvvgiVYOf+Nq9pkvpfVPky4YAnW+V8CkawciyVYgiVY9zAOFyiWYAmWYN0mWcfc/Z6yWIIlWIJ1I/1UdrEES7AE616bWUPJxRIswRKsm+nq6Lc5tKMJFyzBEqyDPGM/MCvVHaSCJViJBe37NtpykNgb8JMJF6xLLmcjWJmIuwE/mHDBEixZOXTgY27AryZcsASLY68Mh3hXhg8TLlg3D9ZbUo7WRdvMajsTLliXW86XkcsuWZFuc1hMuGBdbjlrI5efSA+gWU24YN07WA8xSZSsGBeGx98/KliClfrI8AS/6+5lNSZcsC62nFXQ3/hUknTJeuV/UShYgpV1sHw3J6X9P3F/9CeFgiVYqf8dF6ycD4G9u++DCResay1nXpsi/GDvVlZlwgXrUsvp28+ZXxc2Ge+7C5ZgpeZW99ytbbanWIIlWIJFzJOsSbAE60rLWWe0JcLvTrJ2FOspWIJ122C5EescjznLXSzBEqzk77L7GkrQNTnuYgmWYOUdrEU6zrL5xvdFsATrQsuZ47PC+YV+a7FGwRKs6yxna+hKOSA23t/wEizBus5yhm2OeMDMiR7bitUKlmBdZznD9kZ62SivWE/BEqzLLOeayeUFhxVrECzBusxyhn1M6NuEJxdr0ylWJ1iCdZXl7ExdSTZ9VtgLlmBdZjlbu+4lqTO6JhQswUov7GPCVTJOtuE5pK1gCdZllrPOYwOXz17Db/heYSVYgnWV5XwG/ZmzYpx+YIQHqxYswbrKcgZ+8DQqxtnCv1bYCJZgXWY5w3bd3Tpa4kWhYAnWZZazsYlVmD6TTSzBEqwT1DaxShP8dKxVsATrKssZtuvuTqwcjo087sQSLME6Y0skh3+sOfQUaxIswbrMck6+TliaZxa77oIlWGcI/Ji804vzhX5Q+BAswbrKcgb+c+3GhgyE/vLXU7AE6yrLGbiJ5ZcoMjDmcK+7YAlWAZtYrglzEPgd6EGwBOsyy/lyTXj1a8JGsATrMsv5dE149WvCSbAE6zrLGbgh4gvQGZjPny/BEqwiNkTcO5qBQbAE667LGbgh4vuEGejP/6REsASriA2Rd6UXp3ucv2SCJVgnCbyxwTNmipsvwRKsqMt57kMQQh9i6Vas802FBeshWP4FPOn64qiHhBNgKSxYlWAJVjSBH5K3enG6WrAE67bLGXpN6G53wRIswSrmmtCdDecfIIIlWPddztkplmAJlmCVEoDVKZZgXXrCBSvqcp79uVvovaNOsQTLJ8uXCtZc1nI2TrHK8jg9WLNgXSlYYQV4nf3n9k6xrnwKX5lwwYq5nOf/GE0beorldnfB8nNLgnWWIfQUy+3uN78kFKwbB+v8e8eDt91bD/I79QA5/avHpU24YMU8YymtsJ6VfPtgFTfhgvVfwr46kcFzh4O33T0X697BKm7CBSvicmbwekPvdrfvfqb19A2k2j9vNw7WWtxfbN+9nNVqTLhgRT1lz+HY79rgYj2E4yxBz8MaTLhgxV3OHD71Db6z4T25KDxLc3osCpxwwfq9wCe25PBVl+A7G65//3K+gpbpacIFK+pE5fGc9PBTrGMOBSLXojLhghV5OXN4wRtOsdw+eo6wm1BMuGD90VTgnuSGU6xJPLJfqcmEC9YfNQXuSW44xfIrhacI+kR3MeGCFftspS3xj/agmSK2sGoTLlh/FHofZhb3NG05xfIVnfReOSxQkRMuWL/zDFzOPO4E3nKK1bp/NLU5gz33QidcsH73Ct4lXuJvuN39o1juH835inAy4YL1CaGHfR5Hfb3lotAd7zmfB79MuGB9Qlvk5nU3K1buukxu7m19PHOlYIU+ES+TB+L1b8XKXJ3JiU2hEy5Yv/Yq9Iy5UazMT7DaTLaOXq4JrxSs0F9TzuVTlMdbsa50grWacMH61EsIfoJnqaeGipXSGLh1NJpwwfqUUh99sG3f3f1YiQTeKjeZcMH6nCl0OXO5UeX53lgsD5vJ78R9NeGCdcg/hRl9yWXZWKyrP7i7xNPf0YQL1ueE3yCQyz9Am+53//rsBhtZef0r2JhwwfqkDR+35fKyt14Uvt/TPTay1pPCHJyI3oQL1meFn6dk8zHK5ovCd3uHx8083/MpLzO4EK0JF6wjj/pcHsu49ZPCv29ovv5l4V8XZk36GR2DA/Ey4YL1+euGDUd7LldU1fZgXf/Twn/2+JrED7Tvgj+VO/oH4kuecMGKcYmfz+2X9Y5i5XOSVR3y/bV/d5KGMe9eDSZcsAJsua7K5hnpzZ5itTnc4NCt8zH/oH9zJZQuWRt6dfwWd9ETLli/2uoo9l6m7fc2fP2H9OwlfC5H7Zl8/yDpRMl6bOhVY8IFK+iY2XSo5/IxW/XeZznxNwvH13zcQfvjzs2QYFofW/75qEy4YAVpi17PdWex0m7xfHNu2E+HPtH853Od5pnjUjQmXLA2b3aUuJ7Du7xkdf1y8Bduf/nTQvORt5J22+ZoNOGCFabfepxnso01vfcnqzqzVkfcivSbx++0w1Ef2FdzvkNU+IQLVpQz5vd7GvMoVru/WO8m0T+nY78keb7K7/Mx9QecZnUbz3MT/ZZR4RMuWJEuqto8Pkp5xCjWu30dPp2Pekr0YN7//CyijX5CWW9dgdqEC1bc6f7DicmG9+CR0wv4/h/U9bhmfZxaten2S/50hM6viKvQb/6K1GTCBSvq9UP0BX285gM+EuvfsTRHNGvshzntdkmbrs79jumpTLhgbTmj33de8tlNkcc/Jxlfci7Wx+t5RVzYrqqXz1wvxX1AwCfvPNp/njW+9lyOv0y4YG06qvYe48v6h8l/POumPWi/5m+vd0ztsu5f3PGjVZ//lz3qid3nP8dvh+178F3f7OtAZ8IFK+2m5DeT39R91f10zFZ9/WrmBBcCwzu25tVvPAGpnvUQeiyv5x2e0+vZbajVsvcNfphwwdrmEfGCqvlqSr1zEb9Yf7+cpX5WnzycP4a3rpdm20VSzCc2bLhAnob18/3onq8IN7+tJlywtmreCR30vg0H/slTs9R1Xf3lf9duj+qrj//9o1LN3iM45mM3t/4t01BX45/25NZhivKWLiZcsLa/lJTLedTNN8O7ZPEukMa9cX59XPt8X66u+nr2GO/lzp0JF6wy/gE6bDmLLla8d2Ut4NWm/0HbRrCuFKzqEsvZFxyseI8tmAt4tU8TLlil/AN04O5FycXKcH/5MKsJF6xTNz7OOZf42bMtNlixTjpe+b/UwYQLVjlzfuhyPootVqz7vlu9uvSEC9Y/HwQlG/Rjf6eymwoNVqRvAj/16uITLlipJ/3guSz1w8I4H/QPenX1CResr5arLOdaZrCiPGKma/Xq+hMuWEln/fAn5VVFbmRFOZR7vbrDhAtWylPm49+4rikwWFF2Pha9usWEC1bC/Y8Ub1xdYLEi/Ls85v0KVxMuWOV9wpbkNudqLi5YEQ7nrLfv2t6EC1ZUY5KL/DTfXOhepQUrwg3SOd/TMT9MuGDFfk1XWs7Sbnvf/4iZnK8Im86EC1Z0/ZWWs7STrN2nIBm/3tqEC9YREuyCJPzmQlk7WbvnPNuPGubKhAtWqR+kJF3OuqDrwv1vzJjn/RxLZ8IFq9j1TLucYzFf1WliTFSV3757+zThgnWgo3dC2tQLVcRtpEOsD9H6zC6Dh86EC1bR+5LJX9Az962sto75bY6ckjVVJlywDl/P9mrL2eecrKm/6sttVxMuWAk8Dh34U74bmmuy2uGQGyr7HK6D686EC1YS3ZHfoj3pncsxWctxX1epzv60YRhNuGAls15wOZ95bb9P67GH9HjmPR155+qqE37jYH15HPYB+Ykfcz+yuclhqlMc0SddGbb55+qqE37fYB130+Wp31zo1vn651bfnWYlf71zxntXN5jw+wbry7hccjmr4dTb35d+vPLrbXoTLlinvcgjLilep7+srj/p0ZzT65yrhWeiZs31aMJzmPC7BuuQBc3imwvpmzUP/ZlH8/N19LVhO1QmPJ8Jv2mwPl7octFLhq5Pdq00nRur/+0yr82BtXqa8Kwvim8TrJgbt9ldMlSvo78t3Db1M59N6O55xAue6ocJz/2i+EbBirQJMq1ZjvUxx/D/WjVe/QV/XOl2JjzrCb9jsP5e0R3/Ck2vZ85j3VX1EvXysBnqKuvjuFqX/ScVTd6rasJvHay/N0E2HNbTUpfxXo0f1dp96tEsdV+VchRX66tpN548vvqHCS9pwu8YrL8P62fdzJ8c6qV+Fvc2Par61QR3q/k4pVqrImeiq/p6+XS32qKKbMIF69/D+mPKfzHmc9M0r/pjGUv/97f6OI7/eom/OZSn5usLravqIofvWH2sad384hW3f/2Pf7/U0YQXO+H3DtYPx3ZVPa7/MsfOUpvwcl+DZQQEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECxAsAAEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsAMECBAtAsAAECxAsAMECECxAsAAEC0CwAMECECxAsAAEC0CwAMECECwAwQIEC0CwAAQLECwAwQIQLECwAAQLQLAAwQIQLADBAgQLQLAABAsQLADBAhAsQLAABAtAsADBAhAsQLAABAtAsADBAhAsgJ3+T4ABAAJlKeV2ckohAAAAAElFTkSuQmCC', 'invalid_image' => 'aaa' }
--- rule
(
	image         => [[BASE64_TYPE => '(jpeg|png|gif)' ]],
	invalid_image => [[BASE64_TYPE => '(jpeg|png|gif)' ]],
)
--- expected
(
	image         => 0,
	invalid_image => 1,
)

=== FILTER
--- query: { 'foo' => ' 123 ', bar => 'one' }
--- rule
(
	foo => [[FILTER => 'TRIM'], 'INT'],
	bar => [[FILTER => sub { my $v = shift; $v =~ s/one/1/; $v } ], 'INT'],
)
--- expected
(
	foo => 0,
	bar => 0,
)

=== FILTER (TRIM/DEFAULT)
--- query: { 'foo' => ' 123 ' }
--- rule
(
	foo => ['TRIM', 'INT'],
	bar => [[DEFAULT => 1], 'INT'],
)
--- expected
(
	foo => 0,
	bar => 0,
)

=== FILTER (BLANK_TO_NULL)
--- query: { 'foo' => '', bar => '', baz => '' }
--- rule
(
	foo => ['BLANK_TO_NULL'],
	bar => ['BLANK_TO_NULL', 'NOT_NULL'],
	baz => ['NOT_NULL'],
)
--- expected
(
	foo => 0,
	bar => 1,
	baz => 0,
)

=== FILTER (with multiple values)
--- query: { 'foo' => [' 0 ', ' 123 ', ' 234 '], 'bar' => [qw(one one)] }
--- rule
(
	foo => [[FILTER => 'trim'], 'INT'],
	bar => [[FILTER => sub { my $v = shift; $v =~ s/one/1/; $v } ], 'INT'],
)
--- expected
(
	foo => 0,
	bar => 0,
)
