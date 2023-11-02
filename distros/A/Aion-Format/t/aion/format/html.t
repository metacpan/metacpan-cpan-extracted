use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-format!aion!format!html/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Format::Html - Perl extension for formatting HTML
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format::Html;

::is scalar do {from_html "<b>&excl;</b>"}, "!", 'from_html "<b>&excl;</b>"  # => !';
::is scalar do {to_html "<a>"}, "&lt;a&gt;", 'to_html "<a>"       # => &lt;a&gt;';

# 
# # DESCRIPION
# 
# Perl extension for formatting HTML-documents.
# 
# # SUBROUTINES
# 
# ## from_html ($html)
# 
# Converts html to text.
# 
done_testing; }; subtest 'from_html ($html)' => sub { 
::is scalar do {from_html "Basic is <b>superlanguage</b>!<br>"}, "Basic is superlanguage!\n", 'from_html "Basic is <b>superlanguage</b>!<br>"  # => Basic is superlanguage!\n';

# 
# ## to_html ($html)
# 
# Escapes html characters.
# 
# ## safe_html ($html)
# 
# Cuts off dangerous and unknown tags from html, and unknown attributes from known tags.
# 
done_testing; }; subtest 'safe_html ($html)' => sub { 
::is scalar do {safe_html "-<em>-</em><br>-"}, "-<em>-</em><br>-", 'safe_html "-<em>-</em><br>-" # => -<em>-</em><br>-';
::is scalar do {safe_html "-<em onclick='  '>-</em><br onmouseout=1>-"}, "-<em>-</em><br>-", 'safe_html "-<em onclick=\'  \'>-</em><br onmouseout=1>-" # => -<em>-</em><br>-';
::is scalar do {safe_html "-<xx24>-</xx24>"}, "--", 'safe_html "-<xx24>-</xx24>" # => --';
::is scalar do {safe_html "-< applet >-</ applet >"}, "-< applet >-", 'safe_html "-< applet >-</ applet >" # => -< applet >-';

# 
# ## split_on_pages ($html, $symbols_on_page, $by)
# 
# Breaks text into pages taking into account html tags.
# 
done_testing; }; subtest 'split_on_pages ($html, $symbols_on_page, $by)' => sub { 
::is_deeply scalar do {[split_on_pages "Alice in wonderland. This is book", 17]}, scalar do {["Alice in wonderland. ", "This is book"]}, '[split_on_pages "Alice in wonderland. This is book", 17]  # --> ["Alice in wonderland. ", "This is book"]';

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
# The Aion::Format::Html module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
