# NAME

Aion::Format::Url - the utitlities for encode and decode the urls

# SYNOPSIS

```perl
use Aion::Format::Url;

to_url_params {a => 1, b => [[1,2],3,{x=>10}]} # => a&b[][]&b[][]=2&b[]=3&b[][x]=10

normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x
```

# DESCRIPTION

The utitlities for encode and decode the urls.

# SUBROUTINES

## to_url_param (;$scalar)

Escape scalar to part of url search.

```perl
to_url_param "a b" # => a+b

[map to_url_param, "a b", "🦁"] # --> [qw/a+b %1F981/]
```

## to_url_params (;$hash_ref)

Generates the search part of the url.

```perl
local $_ = {a => 1, b => [[1,2],3,{x=>10}]};
to_url_params  # => a&b[][]&b[][]=2&b[]=3&b[][x]=10
```

1. Keys with undef values not stringify.
1. Empty value is empty.
1. `1` value stringify key only.
1. Keys stringify in alfabet order.

```perl
to_url_params {k => "", n => undef, f => 1}  # => f&k=
```

## parse_url ($url, $onpage, $dir)

Parses and normalizes url.

* `$url` — url, or it part for parsing.
* `$onpage` — url page with `$url`. If `$url` not complete, then extended it. Optional. By default use config ONPAGE = "off://off".
* `$dir` (bool): 1 — normalize url path with "/" on end, if it is catalog. 0 — without "/".

```perl
my $res = {
    proto  => "off",
    dom    => "off",
    domain => "off",
    link   => "off://off",
    orig   => "",
    onpage => "off://off",
};

parse_url ""    # --> $res

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

parse_url "/page", "https://www.main.com/pager/mix"   # --> $res

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
parse_url 'https://user:pass@www.x.test/path?x=10&y=20#hash'  # --> $res
```

See also `URL::XS`.

## normalize_url ($url, $onpage, $dir)

Normalizes url.

It use `parse_url`, and it returns link.

```perl
normalize_url ""   # => off://off
normalize_url "www.fix.com"  # => off://off/www.fix.com
normalize_url ":"  # => off://off/:
normalize_url '@'  # => off://off/@
normalize_url "/"  # => off://off
normalize_url "//" # => off://
normalize_url "?"  # => off://off
normalize_url "#"  # => off://off

normalize_url "/dir/file", "http://www.load.er/fix/mix"  # => http://load.er/dir/file
normalize_url "dir/file", "http://www.load.er/fix/mix"  # => http://load.er/fix/mix/dir/file
normalize_url "?x", "http://load.er/fix/mix?y=6"  # => http://load.er/fix/mix?x
```

# SEE ALSO

* `URI::URL`.

# AUTHOR

Yaroslav O. Kosmina [darviarush@mail.ru](mailto:darviarush@mail.ru)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Format::Url module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
