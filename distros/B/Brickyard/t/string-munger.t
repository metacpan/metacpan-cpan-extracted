#!/usr/bin/env perl
use warnings;
use strict;
use lib 't/lib';
use Brickyard;
use Test::Most;
my $brickyard = Brickyard->new(base_package => 'BrickyardTest::StringMunger');
my $root_config = bless {}, 'RootConfig';
$brickyard->init_from_config('t/config/string-munger.ini', $root_config);
my $text = 'hello';
$text = $_->run($text) for $brickyard->plugins_with(-StringMunger);
my $expect = <<'EOEXPECT';
HELLOHELLOHELLO
@Default/Uppercase
@Default/Repeat
@Default/Reporter
%Append
suffix1suffix2suffix3
EOEXPECT
eq_or_diff $text, $expect, 'munge string with string-munger.ini';

$brickyard->reset_plugins;
$brickyard->init_from_config('t/config/string-munger-filter.ini', $root_config);
$text = 'hello';
$text = $_->run($text) for $brickyard->plugins_with(-StringMunger);

$expect = <<'EOEXPECT';
hellohellohello
@Default/Repeat
@Default/Reporter
EOEXPECT
eq_or_diff $text, $expect, 'munge string with string-munger-filter.ini';
done_testing();
