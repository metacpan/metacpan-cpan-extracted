#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 11;

use CSS::Janus;

my $self = CSS::Janus->new(
    'swap_ltr_rtl_in_url'    => 1,
    'swap_left_right_in_url' => 1
);
my $testcase;
my $shouldbe;

$testcase = 'background: url(/foo/bar-left.png)';
$shouldbe = 'background: url(/foo/bar-right.png)';
is($self->transform($testcase), $shouldbe);

$testcase = 'background: url(/foo/left-bar.png)';
$shouldbe = 'background: url(/foo/right-bar.png)';
is($self->transform($testcase), $shouldbe);

$testcase = 'url("http://www.blogger.com/img/triangle_ltr.gif")';
$shouldbe = 'url("http://www.blogger.com/img/triangle_rtl.gif")';
is($self->transform($testcase), $shouldbe);

$testcase = "url('http://www.blogger.com/img/triangle_ltr.gif')";
$shouldbe = "url('http://www.blogger.com/img/triangle_rtl.gif')";
is($self->transform($testcase), $shouldbe);

$testcase = "url('http://www.blogger.com/img/triangle_ltr.gif'  )";
$shouldbe = "url('http://www.blogger.com/img/triangle_rtl.gif'  )";
is($self->transform($testcase), $shouldbe);

$testcase = 'background: url(/foo/bar.left.png)';
$shouldbe = 'background: url(/foo/bar.right.png)';
is($self->transform($testcase), $shouldbe);

$testcase = 'background: url(/foo/bright.png)';
$shouldbe = 'background: url(/foo/bright.png)';
is($self->transform($testcase), $shouldbe);

$testcase = 'background: url(/foo/bar-rtl.png)';
$shouldbe = 'background: url(/foo/bar-ltr.png)';
is($self->transform($testcase), $shouldbe);

$testcase = 'background: url(/foo/bar-rtl.png); left: 10px';
$shouldbe = 'background: url(/foo/bar-ltr.png); right: 10px';
is($self->transform($testcase), $shouldbe);

$testcase = 'background: url(/foo/bar-right.png); direction: ltr';
$shouldbe = 'background: url(/foo/bar-left.png); direction: ltr';
is($self->transform($testcase), $shouldbe);

$testcase =
    'background: url(/foo/bar-rtl_right.png);' . 'left:10px; direction: ltr';
$shouldbe =
    'background: url(/foo/bar-ltr_left.png);' . 'right:10px; direction: ltr';
is($self->transform($testcase), $shouldbe);

