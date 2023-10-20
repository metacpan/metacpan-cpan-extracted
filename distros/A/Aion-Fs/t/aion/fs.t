use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-fs!aion!fs/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Fs - utilities for filesystem: read, write, find, replace files, etc
# 
# # VERSION
# 
# 0.0.3
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Fs;

lay mkpath "hello/world.txt", "hi!";
lay mkpath "hello/moon.txt", "noreplace";
lay mkpath "hello/big/world.txt", "hellow!";
lay mkpath "hello/small/world.txt", "noenter";

::like scalar do {mtime "hello"}, qr!^\d+(\.\d+)?$!, 'mtime "hello"  # ~> ^\d+(\.\d+)?$';

::is_deeply scalar do {[map cat, grep -f, find ["hello/big", "hello/small"]]}, scalar do {[qw/ hellow! noenter /]}, '[map cat, grep -f, find ["hello/big", "hello/small"]]  # --> [qw/ hellow! noenter /]';

my @noreplaced = replace { s/h/$a $b H/ }
    find "hello", "-f", "*.txt", qr/\.txt$/, sub { /\.txt$/ },
        noenter "*small*",
            errorenter { die "find $_: $!" };

::is_deeply scalar do {\@noreplaced}, scalar do {["hello/moon.txt"]}, '\@noreplaced # --> ["hello/moon.txt"]';

::is scalar do {cat "hello/world.txt"}, "hello/world.txt :utf8 Hi!", 'cat "hello/world.txt"       # => hello/world.txt :utf8 Hi!';
::is scalar do {cat "hello/moon.txt"}, "noreplace", 'cat "hello/moon.txt"        # => noreplace';
::is scalar do {cat "hello/big/world.txt"}, "hello/big/world.txt :utf8 Hellow!", 'cat "hello/big/world.txt"   # => hello/big/world.txt :utf8 Hellow!';
::is scalar do {cat "hello/small/world.txt"}, "noenter", 'cat "hello/small/world.txt" # => noenter';

::is_deeply scalar do {[find "hello", "*.txt"]}, scalar do {[qw!  hello/moon.txt  hello/world.txt  hello/big/world.txt  hello/small/world.txt  !]}, '[find "hello", "*.txt"]  # --> [qw!  hello/moon.txt  hello/world.txt  hello/big/world.txt  hello/small/world.txt  !]';
::is_deeply scalar do {[find "hello", "-d"]}, scalar do {[qw!  hello  hello/big hello/small  !]}, '[find "hello", "-d"]  # --> [qw!  hello  hello/big hello/small  !]';

erase reverse find "hello";

::is scalar do {-e "hello"}, scalar do{undef}, '-e "hello"  # -> undef';

# 
# # DESCRIPTION
# 
# This module provide light entering to filesystem.
# 
# Modules `File::Path`, `File::Slurper` and
# `File::Find` are quite weighted with various features that are rarely used, but take time to get acquainted and, thereby, increases the entry threshold.
# 
# In `Aion::Fs` used the programming principle KISS - Keep It Simple, Stupid.
# 
# Supermodule `IO::All` provide OOP, and `Aion::Fs` provide FP.
# 
# * OOP - object oriented programming.
# * FP - functional programming.
# 
# # SUBROUTINES/METHODS
# 
# ## cat ($file)
# 
# Read file. If file not specified, then use `$_`.
# 
done_testing; }; subtest 'cat ($file)' => sub { 
::like scalar do {cat "/etc/passwd"}, qr!root!, 'cat "/etc/passwd"  # ~> root';

# 
# `cat` read with layer `:utf8`. But you can set the level like this:
# 

lay "unicode.txt", "↯";
::is scalar do {length cat "unicode.txt"}, scalar do{1}, 'length cat "unicode.txt"            # -> 1';
::is scalar do {length cat["unicode.txt", ":raw"]}, scalar do{3}, 'length cat["unicode.txt", ":raw"]   # -> 3';

# 
# `cat` raise exception by error on io operation:
# 

::like scalar do {eval { cat "A" }; $@}, qr!cat A: No such file or directory!, 'eval { cat "A" }; $@  # ~> cat A: No such file or directory';

# 
# ## lay ($file, $content)
# 
# Write `$content` in `$file`.
# 
# * If one parameter specified, then use `$_` as `$file`.
# * `lay` using layer `:utf8`. For set layer using two elements array for `$file`:
# 
done_testing; }; subtest 'lay ($file, $content)' => sub { 
::is scalar do {lay "unicode.txt", "↯"}, "unicode.txt", 'lay "unicode.txt", "↯"  # => unicode.txt';
::is scalar do {lay ["unicode.txt", ":raw"], "↯"}, "unicode.txt", 'lay ["unicode.txt", ":raw"], "↯"  # => unicode.txt';

::like scalar do {eval { lay "/", "↯" }; $@}, qr!lay /: Is a directory!, 'eval { lay "/", "↯" }; $@ # ~> lay /: Is a directory';

# 
# ## find ($path, @filters)
# 
# Finded files and returns array paths from start path or paths if `$path` is array ref.
# 
# Filters may be:
# 
# * Subroutine - the each path fits to `$_` and test with subroutine.
# * Regexp - test the each path on the regexp.
# * String as "-Xxx", where `Xxx` - one or more symbols. Test on the perl file testers. Example "-fr" test the path on `-f` and `-r` file testers.
# * Any string interpret function `wildcard` to regexp and the each path test on it.
# 
# The paths that have not passed testing by `@filters` are not returned.
# 
# If filter -X is unused, then throw exception:
# 
done_testing; }; subtest 'find ($path, @filters)' => sub { 
::like scalar do {eval { find "example", "-h" }; $@}, qr!Undefined subroutine &Aion::Fs::h called!, 'eval { find "example", "-h" }; $@   # ~> Undefined subroutine &Aion::Fs::h called';

# 
# If `find` is impossible to enter the subdirectory, then call errorenter with set variable `$_` and `$!`.
# 

mkpath ["example/", 0];

::is_deeply scalar do {[find "example"]}, scalar do {["example"]}, '[find "example"]    # --> ["example"]';
::is_deeply scalar do {[find "example", noenter "-d"]}, scalar do {["example"]}, '[find "example", noenter "-d"]    # --> ["example"]';

::like scalar do {eval { find "example", errorenter { die "find $_: $!" } }; $@}, qr!find example: Permission denied!, 'eval { find "example", errorenter { die "find $_: $!" } }; $@   # ~> find example: Permission denied';

# 
# ## noenter (@filters)
# 
# No enter to catalogs. Using in `find`. `@filters` same as in `find`.
# 
# ## errorenter (&block)
# 
# Call `&block` for each error on open catalog.
# 
# ## erase (@paths)
# 
# Remove files and empty catalogs. Returns the `@paths`.
# 
done_testing; }; subtest 'erase (@paths)' => sub { 
::like scalar do {eval { erase "/" }; $@}, qr!erase dir /: Device or resource busy!, 'eval { erase "/" }; $@  # ~> erase dir /: Device or resource busy';
::like scalar do {eval { erase "/dev/null" }; $@}, qr!erase file /dev/null: Permission denied!, 'eval { erase "/dev/null" }; $@  # ~> erase file /dev/null: Permission denied';

# 
# ## mkpath ($path)
# 
# As **mkdir -p**, but consider last path-part (after last slash) as filename, and not create this catalog.
# 
# * If `$path` not specified, then use `PATH`.
# * If `$path` is array ref, then use path as first and permission as second element.
# * Default permission is `0755`.
# * Returns `$path`.
# cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
done_testing; }; subtest 'mkpath ($path)' => sub { 
local $_ = ["A", 0755];
::is scalar do {mkpath}, "A", 'mkpath   # => A';

::like scalar do {eval { mkpath "/A/" }; $@}, qr!mkpath : No such file or directory!, 'eval { mkpath "/A/" }; $@   # ~> mkpath : No such file or directory';

# 
# ## mtime ($file)
# 
# Time modification the `$file` in unixtime in subsecond resolution (from Time::HiRes::stat).
# 
# Raise exeception if file not exists, or not permissions:
# 
done_testing; }; subtest 'mtime ($file)' => sub { 
local $_ = "nofile";
::like scalar do {eval { mtime }; $@}, qr!mtime nofile: No such file or directory!, 'eval { mtime }; $@  # ~> mtime nofile: No such file or directory';

::like scalar do {mtime ["/"]}, qr!^\d+(\.\d+)?$!, 'mtime ["/"]   # ~> ^\d+(\.\d+)?$';

# 
# ## replace (&sub, @files)
# 
# Replacing each the file if `&sub` replace `$_`. Returns files in which there were no replacements.
# 
# `@files` can contain arrays of two elements. The first one is treated as a path, and the second one is treated as a layer. Default layer is `:utf8`.
# 
done_testing; }; subtest 'replace (&sub, @files)' => sub { 
local $_ = "replace.ex";
lay "abc";
replace { $b = ":utf8"; y/a/¡/ } [$_, ":raw"];
::is scalar do {cat}, "¡bc", 'cat  # => ¡bc';

# 
# ## include ($pkg)
# 
# Require `$pkg` and returns it.
# 
# File lib/A.pm:
#@> lib/A.pm
#>> package A;
#>> sub new { bless {@_}, shift }
#>> 1;
#@< EOF
# 
# File lib/N.pm:
#@> lib/N.pm
#>> package N;
#>> sub ex { 123 }
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'include ($pkg)' => sub { 
use lib "lib";
::like scalar do {include("A")->new}, qr!A=HASH\(0x\w+\)!, 'include("A")->new               # ~> A=HASH\(0x\w+\)';
::is_deeply scalar do {[map include, qw/A N/]}, scalar do {[qw/A N/]}, '[map include, qw/A N/]          # --> [qw/A N/]';
::is scalar do {{ local $_="N"; include->ex }}, scalar do{123}, '{ local $_="N"; include->ex }   # -> 123';

# 
# ## catonce ($file)
# 
# Read the file in first call with this file. Any call with this file return `undef`. Using for insert js and css modules in the resulting file.
# 
done_testing; }; subtest 'catonce ($file)' => sub { 
local $_ = "catonce.txt";
lay "result";
::is scalar do {catonce}, scalar do{"result"}, 'catonce  # -> "result"';
::is scalar do {catonce}, scalar do{undef}, 'catonce  # -> undef';

::like scalar do {eval { catonce[] }; $@}, qr!catonce not use ref path\!!, 'eval { catonce[] }; $@ # ~> catonce not use ref path!';

# 
# ## wildcard ($wildcard)
# 
# Translate the wildcard to regexp.
# 
# * `**` - `[^/]*`
# * `*` - `.*`
# * `?` - `.`
# * `??` - `[^/]`
# * `{` - `(`
# * `}` - `)`
# * `,` - `|`
# * Any symbols translate by `quotemeta`.
# 
done_testing; }; subtest 'wildcard ($wildcard)' => sub { 
::is scalar do {wildcard "*.{pm,pl}"}, '(?^usn:^.*?\.(pm|pl)$)', 'wildcard "*.{pm,pl}"  # \> (?^usn:^.*?\.(pm|pl)$)';
::is scalar do {wildcard "?_??_**"}, '(?^usn:^._[^/]_[^/]*?$)', 'wildcard "?_??_**"  # \> (?^usn:^._[^/]_[^/]*?$)';

# 
# Using in filters the function `find`.
# 
# ## goto_editor ($path, $line)
# 
# Open the file in editor from config on the line.
# 
# File .config.pm:
#@> .config.pm
#>> package config;
#>> 
#>> config_module 'Aion::Fs' => {
#>>     EDITOR => 'echo %p:%l > ed.txt',
#>> };
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'goto_editor ($path, $line)' => sub { 
goto_editor "mypath", 10;
::is scalar do {cat "ed.txt"}, "mypath:10\n", 'cat "ed.txt"  # => mypath:10\n';

::like scalar do {eval { goto_editor "`", 1 }; $@}, qr!`:1 --> 512!, 'eval { goto_editor "`", 1 }; $@  # ~> `:1 --> 512';

# 
# Default the editor is `vscodium`.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Fs is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
