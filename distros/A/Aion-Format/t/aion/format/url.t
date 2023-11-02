use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-format!aion!format!url/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Format::Url - the utitlities for encode and decode the urls
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format::Url;

::is scalar do {to_url_params {a => 1, b => [[1,2],3,{x=>10}]}}, "a&b[][]&b[][]=2&b[]=3&b[][x]=10", 'to_url_params {a => 1, b => [[1,2],3,{x=>10}]} # => a&b[][]&b[][]=2&b[]=3&b[][x]=10';

::is scalar do {normalize_url "?x", "http://load.er/fix/mix?y=6"}, "http://load.er/fix/mix?x", 'normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x';

# 
# # DESCRIPTION
# 
# The utitlities for encode and decode the urls.
# 
# # SUBROUTINES
# 
# ## to_url_param (;$scalar)
# 
# Escape scalar to part of url search.
# 
done_testing; }; subtest 'to_url_param (;$scalar)' => sub { 
::is scalar do {to_url_param "a b"}, "a+b", 'to_url_param "a b" # => a+b';

::is_deeply scalar do {[map to_url_param, "a b", "🦁"]}, scalar do {[qw/a+b %1F981/]}, '[map to_url_param, "a b", "🦁"] # --> [qw/a+b %1F981/]';

# 
# ## to_url_params (;$hash_ref)
# 
# Generates the search part of the url.
# 
done_testing; }; subtest 'to_url_params (;$hash_ref)' => sub { 
local $_ = {a => 1, b => [[1,2],3,{x=>10}]};
::is scalar do {to_url_params}, "a&b[][]&b[][]=2&b[]=3&b[][x]=10", 'to_url_params  # => a&b[][]&b[][]=2&b[]=3&b[][x]=10';

# 
# 1. Keys with undef values not stringify.
# 1. Empty value is empty.
# 1. `1` value stringify key only.
# 1. Keys stringify in alfabet order.
# 

::is scalar do {to_url_params {k => "", n => undef, f => 1}}, "f&k=", 'to_url_params {k => "", n => undef, f => 1}  # => f&k=';

# 
# ## parse_url ($url, $onpage, $dir)
# 
# Parses and normalizes url.
# 
# * `$url` — url, or it part for parsing.
# * `$onpage` — url page with `$url`. If `$url` not complete, then extended it. Optional. By default use config ONPAGE = "off://off".
# * `$dir` (bool): 1 — normalize url path with "/" on end, if it is catalog. 0 — without "/".
# 
done_testing; }; subtest 'parse_url ($url, $onpage, $dir)' => sub { 
my $res = {
    proto  => "off",
    dom    => "off",
    domain => "off",
    link   => "off://off",
    orig   => "",
    onpage => "off://off",
};

::is_deeply scalar do {parse_url ""}, scalar do {$res}, 'parse_url ""    # --> $res';

$res = {
    proto  => "https",
    dom    => "main.com",
    domain => "www.main.com",
    path   => "/page",
    dir    => "/page/",
    link   => "https://main.com/page",
    orig   => "/page",
    onpage => "https://www.main.com/pager/mix",
};

::is_deeply scalar do {parse_url "/page", "https://www.main.com/pager/mix"}, scalar do {$res}, 'parse_url "/page", "https://www.main.com/pager/mix"   # --> $res';

$res = {
    proto  => "https",
    user   => "user",
    pass   => "pass",
    dom    => "x.test",
    domain => "www.x.test",
    path   => "/path",
    dir    => "/path/",
    query  => "x=10&y=20",
    hash   => "hash",
    link   => 'https://user:pass@x.test/path?x=10&y=20#hash',
    orig   => 'https://user:pass@www.x.test/path?x=10&y=20#hash',
    onpage => "off://off",
};
::is_deeply scalar do {parse_url 'https://user:pass@www.x.test/path?x=10&y=20#hash'}, scalar do {$res}, 'parse_url \'https://user:pass@www.x.test/path?x=10&y=20#hash\'  # --> $res';

# 
# See also `URL::XS`.
# 
# ## normalize_url ($url, $onpage, $dir)
# 
# Normalizes url.
# 
# It use `parse_url`, and it returns link.
# 
done_testing; }; subtest 'normalize_url ($url, $onpage, $dir)' => sub { 
::is scalar do {normalize_url ""}, "off://off", 'normalize_url ""   # => off://off';
::is scalar do {normalize_url "www.fix.com"}, "off://off/www.fix.com", 'normalize_url "www.fix.com"  # => off://off/www.fix.com';
::is scalar do {normalize_url ":"}, "off://off/:", 'normalize_url ":"  # => off://off/:';
::is scalar do {normalize_url '@'}, "off://off/@", 'normalize_url \'@\'  # => off://off/@';
::is scalar do {normalize_url "/"}, "off://off", 'normalize_url "/"  # => off://off';
::is scalar do {normalize_url "//"}, "off://", 'normalize_url "//" # => off://';
::is scalar do {normalize_url "?"}, "off://off", 'normalize_url "?"  # => off://off';
::is scalar do {normalize_url "#"}, "off://off", 'normalize_url "#"  # => off://off';

::is scalar do {normalize_url "/dir/file", "http://www.load.er/fix/mix"}, "http://load.er/dir/file", 'normalize_url "/dir/file", "http://www.load.er/fix/mix"  # => http://load.er/dir/file';
::is scalar do {normalize_url "dir/file", "http://www.load.er/fix/mix"}, "http://load.er/fix/mix/dir/file", 'normalize_url "dir/file", "http://www.load.er/fix/mix"  # => http://load.er/fix/mix/dir/file';
::is scalar do {normalize_url "?x", "http://load.er/fix/mix?y=6"}, "http://load.er/fix/mix?x", 'normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x';

# 
# # SEE ALSO
# 
# * `URI::URL`.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [darviarush@mail.ru](mailto:darviarush@mail.ru)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Format::Url module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
