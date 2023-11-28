[![Actions Status](https://github.com/darviarush/perl-aion-fs/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion-fs/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Aion-Fs.svg)](https://metacpan.org/release/Aion-Fs)
# NAME

Aion::Fs - utilities for filesystem: read, write, find, replace files, etc

# VERSION

0.0.6

# SYNOPSIS

```perl
use Aion::Fs;

lay mkpath "hello/world.txt", "hi!";
lay mkpath "hello/moon.txt", "noreplace";
lay mkpath "hello/big/world.txt", "hellow!";
lay mkpath "hello/small/world.txt", "noenter";

mtime "hello"  # ~> ^\d+(\.\d+)?$

[map cat, grep -f, find ["hello/big", "hello/small"]]  # --> [qw/ hellow! noenter /]

my @noreplaced = replace { s/h/$a $b H/ }
    find "hello", "-f", "*.txt", qr/\.txt$/, sub { /\.txt$/ },
        noenter "*small*",
            errorenter { die "find $_: $!" };

\@noreplaced # --> ["hello/moon.txt"]

cat "hello/world.txt"       # => hello/world.txt :utf8 Hi!
cat "hello/moon.txt"        # => noreplace
cat "hello/big/world.txt"   # => hello/big/world.txt :utf8 Hellow!
cat "hello/small/world.txt" # => noenter

[find "hello", "*.txt"]  # --> [qw!  hello/moon.txt  hello/world.txt  hello/big/world.txt  hello/small/world.txt  !]
[find "hello", "-d"]  # --> [qw!  hello  hello/big hello/small  !]

erase reverse find "hello";

-e "hello"  # -> undef
```

# DESCRIPTION

This module provide light entering to filesystem.

Modules `File::Path`, `File::Slurper` and
`File::Find` are quite weighted with various features that are rarely used, but take time to get acquainted and, thereby, increases the entry threshold.

In `Aion::Fs` used the programming principle KISS - Keep It Simple, Stupid.

Supermodule `IO::All` provide OOP, and `Aion::Fs` provide FP.

* OOP - object oriented programming.
* FP - functional programming.

# SUBROUTINES/METHODS

## cat ($file)

Read file. If file not specified, then use `$_`.

```perl
cat "/etc/passwd"  # ~> root
```

`cat` read with layer `:utf8`. But you can set the level like this:

```perl
lay "unicode.txt", "↯";
length cat "unicode.txt"            # -> 1
length cat["unicode.txt", ":raw"]   # -> 3
```

`cat` raise exception by error on io operation:

```perl
eval { cat "A" }; $@  # ~> cat A: No such file or directory
```

**See also:**

* <File::Slurp> — `read_file('file.txt')`.
* <File::Slurper> — `read_text('file.txt')`, `read_binary('file.txt')`.
* <IO::All> — `io('file.txt') > $contents`.

## lay ($file, $content)

Write `$content` in `$file`.

* If one parameter specified, then use `$_` as `$file`.
* `lay` using layer `:utf8`. For set layer using two elements array for `$file`:

```perl
lay "unicode.txt", "↯"  # => unicode.txt
lay ["unicode.txt", ":raw"], "↯"  # => unicode.txt

eval { lay "/", "↯" }; $@ # ~> lay /: Is a directory
```

**See also:**

* <File::Slurp> — `write_file('file.txt', $contents)`.
* <File::Slurper> — `write_text('file.txt', $contents)`, `write_binary('file.txt', $contents)`.
* <IO::All> — `io('file.txt') < $contents`.

## find ($path, @filters)

Finded files and returns array paths from start path or paths if `$path` is array ref.

Filters may be:

* Subroutine - the each path fits to `$_` and test with subroutine.
* Regexp - test the each path on the regexp.
* String as "-Xxx", where `Xxx` - one or more symbols. Test on the perl file testers. Example "-fr" test the path on `-f` and `-r` file testers.
* Any string interpret function `wildcard` to regexp and the each path test on it.

The paths that have not passed testing by `@filters` are not returned.

If filter -X is unused, then throw exception:

```perl
eval { find "example", "-h" }; $@   # ~> Undefined subroutine &Aion::Fs::h called
```

If `find` is impossible to enter the subdirectory, then call errorenter with set variable `$_` and `$!`.

```perl
mkpath ["example/", 0];

[find "example"]    # --> ["example"]
[find "example", noenter "-d"]    # --> ["example"]

eval { find "example", errorenter { die "find $_: $!" } }; $@   # ~> find example: Permission denied
```

**See also:**

* <File::Find> — `find(sub { push @paths, $File::Find::name }, $dir)`.

## noenter (@filters)

No enter to catalogs. Using in `find`. `@filters` same as in `find`.

## errorenter (&block)

Call `&block` for each error on open catalog.

## erase (@paths)

Remove files and empty catalogs. Returns the `@paths`.

```perl
eval { erase "/" }; $@  # ~> erase dir /: Device or resource busy
eval { erase "/dev/null" }; $@  # ~> erase file /dev/null: Permission denied
```

**See also:**

* <unlink>.
* <File::Path> — `remove_tree("dir")`.

## mkpath ($path)

As **mkdir -p**, but consider last path-part (after last slash) as filename, and not create this catalog.

* If `$path` not specified, then use `PATH`.
* If `$path` is array ref, then use path as first and permission as second element.
* Default permission is `0755`.
* Returns `$path`.

```perl
local $_ = ["A", 0755];
mkpath   # => A

eval { mkpath "/A/" }; $@   # ~> mkpath /A: Permission denied

mkpath "A///./file";
-d "A"  # -> 1
```

**See also:**

* <File::Path> — `mkpath("dir1/dir2")`.

## mtime ($file)

Time modification the `$file` in unixtime in subsecond resolution (from Time::HiRes::stat).

Raise exeception if file not exists, or not permissions:

```perl
local $_ = "nofile";
eval { mtime }; $@  # ~> mtime nofile: No such file or directory

mtime ["/"]   # ~> ^\d+(\.\d+)?$
```

**See also:**

* <-M> — `-M "file.txt"`, `-M _` in days.
* <stat> — `(stat "file.txt")[9]` in seconds.
* <Time::HiRes> — `(Time::HiRes::stat "file.txt")[9]` in seconds with fractional part.

## replace (&sub, @files)

Replacing each the file if `&sub` replace `$_`. Returns files in which there were no replacements.

`@files` can contain arrays of two elements. The first one is treated as a path, and the second one is treated as a layer. Default layer is `:utf8`.

```perl
local $_ = "replace.ex";
lay "abc";
replace { $b = ":utf8"; y/a/¡/ } [$_, ":raw"];
cat  # => ¡bc
```

**See also:**

* <File::Edit>.
* <File::Edit::Portable>.

## include ($pkg)

Require `$pkg` and returns it.

File lib/A.pm:
```perl
package A;
sub new { bless {@_}, shift }
1;
```

File lib/N.pm:
```perl
package N;
sub ex { 123 }
1;
```

```perl
use lib "lib";
include("A")->new               # ~> A=HASH\(0x\w+\)
[map include, qw/A N/]          # --> [qw/A N/]
{ local $_="N"; include->ex }   # -> 123
```

## catonce ($file)

Read the file in first call with this file. Any call with this file return `undef`. Using for insert js and css modules in the resulting file.

```perl
local $_ = "catonce.txt";
lay "result";
catonce  # -> "result"
catonce  # -> undef

eval { catonce[] }; $@ # ~> catonce not use ref path!
```

## wildcard ($wildcard)

Translate the wildcard to regexp.

* `**` - `[^/]*`
* `*` - `.*`
* `?` - `.`
* `??` - `[^/]`
* `{` - `(`
* `}` - `)`
* `,` - `|`
* Any symbols translate by `quotemeta`.

```perl
wildcard "*.{pm,pl}"  # \> (?^usn:^.*?\.(pm|pl)$)
wildcard "?_??_**"  # \> (?^usn:^._[^/]_[^/]*?$)
```

Using in filters the function `find`.

**See also:**

* <File::Wildcard>.
* <String::Wildcard::Bash>.

## goto_editor ($path, $line)

Open the file in editor from config on the line.

File .config.pm:
```perl
package config;

config_module 'Aion::Fs' => {
    EDITOR => 'echo %p:%l > ed.txt',
};

1;
```

```perl
goto_editor "mypath", 10;
cat "ed.txt"  # => mypath:10\n

eval { goto_editor "`", 1 }; $@  # ~> `:1 --> 512
```

Default the editor is `vscodium`.

## from_pkg (;$pkg)

From package to file path.

```perl
from_pkg "Aion::Fs"  # => Aion/Fs.pm
[map from_pkg, "Aion::Fs", "A::B::C"]  # --> ["Aion/Fs.pm", "A/B/C.pm"]
```

## to_pkg (;$path)

From file path to package.

```perl
to_pkg "Aion/Fs.pm"  # => Aion::Fs
[map to_pkg, "Aion/Fs.md", "A/B/C.md"]  # --> ["Aion::Fs", "A::B::C"]
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Fs is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
