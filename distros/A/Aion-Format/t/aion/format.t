use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-format!aion!format/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Format - Perl extension for formatting numbers, colorizing output and so on
# 
# # VERSION
# 
# 0.0.3
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format;

::is scalar do {trappout { print "123\n" }}, "123\n", 'trappout { print "123\n" } # => 123\n';

::is scalar do {coloring "#red ~> #r\n"}, "\e[31m ~> \e[0m\n", 'coloring "#red ~> #r\n" # => \e[31m ~> \e[0m\n';
::is scalar do {trappout { printcolor "#red ~> #r\n" }}, "\e[31m ~> \e[0m\n", 'trappout { printcolor "#red ~> #r\n" } # => \e[31m ~> \e[0m\n';

# 
# # DESCRIPTION
# 
# A utilities for formatting numbers, colorizing output and so on.
# 
# # SUBROUTINES
# 
# ## coloring ($format, @params)
# 
# Colorizes the text with escape sequences, and then replaces the format with sprintf. Color names using from module `Term::ANSIColor`. For `RESET` use `#r` or `#R`.
# 
done_testing; }; subtest 'coloring ($format, @params)' => sub { 
::is scalar do {coloring "#{BOLD RED}###r %i", 6}, "\e[1;31m##\e[0m 6", 'coloring "#{BOLD RED}###r %i", 6 # => \e[1;31m##\e[0m 6';

# 
# ## printcolor ($format, @params)
# 
# As `coloring`, but it print formatted string.
# 
# ## warncolor ($format, @params)
# 
# As `coloring`, but print formatted string to `STDERR`.
# 
done_testing; }; subtest 'warncolor ($format, @params)' => sub { 
::is scalar do {trapperr { warncolor "#{green}ACCESS#r %i\n", 6 }}, "\e[32mACCESS\e[0m 6\n", 'trapperr { warncolor "#{green}ACCESS#r %i\n", 6 }  # => \e[32mACCESS\e[0m 6\n';

# 
# ## accesslog ($format, @params)
# 
# It write in STDOUT `coloring` returns with prefix datetime.
# 
done_testing; }; subtest 'accesslog ($format, @params)' => sub { 
::like scalar do {trappout { accesslog "#{green}ACCESS#r %i\n", 6 }}, qr!\[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[32mACCESS\e\[0m 6\n!, 'trappout { accesslog "#{green}ACCESS#r %i\n", 6 }  # ~> \[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[32mACCESS\e\[0m 6\n';

# 
# ## errorlog ($format, @params)
# 
# It write in STDERR `coloring` returns with prefix datetime.
# 
done_testing; }; subtest 'errorlog ($format, @params)' => sub { 
::like scalar do {trapperr { errorlog "#{red}ERROR#r %i\n", 6 }}, qr!\[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[31mERROR\e\[0m 6\n!, 'trapperr { errorlog "#{red}ERROR#r %i\n", 6 }  # ~> \[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[31mERROR\e\[0m 6\n';

# 
# ## flesch_index_human ($flesch_index)
# 
# Convert flesch index to russian label with step 10.
# 
done_testing; }; subtest 'flesch_index_human ($flesch_index)' => sub { 
::is scalar do {flesch_index_human -10}, "несвязный русский текст", 'flesch_index_human -10   # => несвязный русский текст';
::is scalar do {flesch_index_human -3}, "для академиков", 'flesch_index_human -3    # => для академиков';
::is scalar do {flesch_index_human 0}, "для академиков", 'flesch_index_human 0     # => для академиков';
::is scalar do {flesch_index_human 1}, "для академиков", 'flesch_index_human 1     # => для академиков';
::is scalar do {flesch_index_human 15}, "для профессионалов", 'flesch_index_human 15    # => для профессионалов';
::is scalar do {flesch_index_human 99}, "для 11 лет (уровень 5-го класса)", 'flesch_index_human 99    # => для 11 лет (уровень 5-го класса)';
::is scalar do {flesch_index_human 100}, "для младшеклассников", 'flesch_index_human 100   # => для младшеклассников';
::is scalar do {flesch_index_human 110}, "несвязный русский текст", 'flesch_index_human 110   # => несвязный русский текст';

# 
# ## from_radix ($string, $radix)
# 
# Parses a natural number in the specified number system. 64-number system used by default.
# 
# For digits using symbols 0-9, A-Z, a-z, _ and -. This symbols using before and for 64 NS. For digits after 64 using symbols from CP1251 encoding.
# 
done_testing; }; subtest 'from_radix ($string, $radix)' => sub { 
::is scalar do {from_radix "A-C"}, scalar do{45004}, 'from_radix "A-C" # -> 45004';
::is scalar do {from_radix "A-C", 64}, scalar do{45004}, 'from_radix "A-C", 64 # -> 45004';
::is scalar do {from_radix "A-C", 255}, scalar do{666327}, 'from_radix "A-C", 255 # -> 666327';
::like scalar do {eval { from_radix "A-C", 256 }; $@}, qr!The number system 256 is too large. Use NS before 256!, 'eval { from_radix "A-C", 256 }; $@ 	# ~> The number system 256 is too large. Use NS before 256';

# 
# ## to_radix ($number, $radix)
# 
# Converts a natural number to a given number system. 64-number system used by default.
# 
done_testing; }; subtest 'to_radix ($number, $radix)' => sub { 
::is scalar do {to_radix 10_000}, "2SG", 'to_radix 10_000 				# => 2SG';
::is scalar do {to_radix 10_000, 64}, "2SG", 'to_radix 10_000, 64 			# => 2SG';
::is scalar do {to_radix 10_000, 255}, "dt", 'to_radix 10_000, 255 			# => dt';
::like scalar do {eval { to_radix 0, 256 }; $@}, qr!The number system 256 is too large. Use NS before 256!, 'eval { to_radix 0, 256 }; $@ 	# ~> The number system 256 is too large. Use NS before 256';

# 
# ## kb_size ($number)
# 
# Adds number digits and adds a unit of measurement.
# 
done_testing; }; subtest 'kb_size ($number)' => sub { 
::is scalar do {kb_size 102}, "102b", 'kb_size 102             # => 102b';
::is scalar do {kb_size 1024}, "1k", 'kb_size 1024            # => 1k';
::is scalar do {kb_size 1023}, "1\x{a0}023b", 'kb_size 1023            # => 1\x{a0}023b';
::is scalar do {kb_size 1024*1024}, "1M", 'kb_size 1024*1024       # => 1M';
::is scalar do {kb_size 1000_002_000_001_000}, "931\x{a0}324G", 'kb_size 1000_002_000_001_000    # => 931\x{a0}324G';

# 
# ## matches ($subject, @rules)
# 
# Multiple text transformations in one pass.
# 
done_testing; }; subtest 'matches ($subject, @rules)' => sub { 
my $s = matches "33*pi",
    qr/(?<num> \d+)/x   => sub { "($+{num})" },
    qr/\b pi \b/x       => sub { 3.14 },
    qr/(?<op> \*)/x     => sub { " $& " },
;

::is scalar do {$s}, "(33) * 3.14", '$s # => (33) * 3.14';

# 
# ## nous ($templates)
# 
# A simplified regex language for text recognition in HTML documents.
# 
# 1. All spaces from the beginning and end are removed. 
# 2. From the beginning of each line, 4 spaces or 0-3 spaces and a tab are removed. 
# 3. Spaces at the end of the line and whitespace lines are replaced with `\s*`. 4. All variables in `{{ var }}` are replaced with `.*?`. Those. recognize everything. 
# 4. All variables in `{{> var }}` are replaced with `[^<>]*?`. Those. do not recognize html tags. 
# 4. All variables in `{{: var }}` are replaced with `[^\n]*`. Those. must be on the same line. 
# 5. Expressions in double square brackets (`[[ ... ]]`) may not exist. 
# 5. Double parentheses (`(( ... ))`) are used as parentheses. 5. `||` - or.
# 
done_testing; }; subtest 'nous ($templates)' => sub { 
my $re = nous [
q{
	<body>
	<center>
	<h2><a href={{> author_link }}>{{: author_name }}</a><br>
	{{ title }}</h2>
},
q{
    <li><A HREF="{{ comments_link }}">((Comments: {{ comments }}, last from {{ last_comment_posted }}.||Added comment))</A>
	<li><a href="{{ author_link }}">{{ author_name }}</a>
	[[ (translate: {{ interpreter_name }})]]
	 (<u>{{ author_email }}</u>) 
	<li>Year: {{ posted }}
},
q{
	<li><B><font color=#393939>Annotation:</font></b><br><i>{{ annotation_html }}</i></ul>
	</ul></font>
	</td></tr>
},
q{
	<!----------- The work itself --------------->
	{{ html }}
	<!------------------------------------------->
},
];

my $s = q{
<body>
<center>
<h2><a href=/to/book/link>A. Alis</a><br>
Grivus campf</h2>

Any others...

<!----------- The work itself --------------->
This book text!
<!------------------------------------------->
};

$s =~ $re;
my $result = {%+};
::is_deeply scalar do {$result}, scalar do {{author_link => "/to/book/link", author_name => "A. Alis", title => "Grivus campf"}}, '$result # --> {author_link => "/to/book/link", author_name => "A. Alis", title => "Grivus campf"}';

# 
# ## num ($number)
# 
# Adds separators between digits of a number.
# 
done_testing; }; subtest 'num ($number)' => sub { 
::is scalar do {num +0}, "0", 'num +0         # => 0';
::is scalar do {num -1000.3}, "-1 000.3", 'num -1000.3    # => -1 000.3';

# 
# Separator by default is no-break space. Set separator and decimal point same as:
# 

::is scalar do {num [1000, "#"]}, "1#000", 'num [1000, "#"]         		# => 1#000';
::is scalar do {num [-1000.3003003, "_", ","]}, "-1_000,3003003", 'num [-1000.3003003, "_", ","]   # => -1_000,3003003';

# 
# See also `Number::Format`.
# 
# ## rim ($number)
# 
# Translate positive integers to **roman numerals**.
# 
done_testing; }; subtest 'rim ($number)' => sub { 
::is scalar do {rim 0}, "N", 'rim 0       # => N';
::is scalar do {rim 4}, "IV", 'rim 4       # => IV';
::is scalar do {rim 6}, "VI", 'rim 6       # => VI';
::is scalar do {rim 50}, "L", 'rim 50      # => L';
::is scalar do {rim 49}, "XLIX", 'rim 49      # => XLIX';
::is scalar do {rim 505}, "DV", 'rim 505     # => DV';

# 
# **roman numerals** after 1000:
# 

::is scalar do {rim 49_000}, "XLIX M", 'rim 49_000      # => XLIX M';
::is scalar do {rim 49_000_000}, "XLIX M M", 'rim 49_000_000  # => XLIX M M';
::is scalar do {rim 49_009_555}, "XLIX IX DLV", 'rim 49_009_555  # => XLIX IX DLV';

# 
# See also:
# 
# * `Roman` is simple converter.
# * `Math::Roman` is another converter.
# * `Convert::Number::Roman` is OOP interface.
# * `Number::Convert::Roman` is another OOP interface.
# * `Text::Roman` convert standart and milhar roman numbers.
# * `Roman::Unicode` use digits ↁ (5 000), ↂ (1000), and so on.
# * `Acme::Roman` added support roman numerals in perl code (`I + II -> III`), but use `+`, `-` and `*` operations only.
# * `Date::Roman` is Perl OO extension for handling roman style dates, but with arabic numbers (id 3 702).
# * `DateTime::Format::Roman` is roman date formatter, but with arabic numbers (5 Kal Jun 2003).
# 
# ## round ($number, $decimal)
# 
# Rounds a number to the specified decimal place.
# 
done_testing; }; subtest 'round ($number, $decimal)' => sub { 
::is scalar do {round 1.234567, 2}, scalar do{1.23}, 'round 1.234567, 2  # -> 1.23';
::is scalar do {round 1.235567, 2}, scalar do{1.24}, 'round 1.235567, 2  # -> 1.24';

# 
# ## sinterval ($interval)
# 
# Generates human-readable spacing.
# 
# Width of result is 12 symbols.
# 
done_testing; }; subtest 'sinterval ($interval)' => sub { 
::is scalar do {sinterval  6666.6666}, "01:51:06.667", 'sinterval  6666.6666 	# => 01:51:06.667';
::is scalar do {sinterval  6.6666}, "00:00:06.667", 'sinterval  6.6666 		# => 00:00:06.667';
::is scalar do {sinterval  .333}, "0.33300000 s", 'sinterval  .333 		# => 0.33300000 s';
::is scalar do {sinterval  .000_33}, "0.3300000 ms", 'sinterval  .000_33 		# => 0.3300000 ms';
::is scalar do {sinterval  .000_000_33}, "0.330000 mks", 'sinterval  .000_000_33 	# => 0.330000 mks';

# 
# ## sround ($number, $digits)
# 
# Leaves `$digits` (0 does not count) wherever they are relative to the point.
# 
# Default `$digits` is 2.
# 
done_testing; }; subtest 'sround ($number, $digits)' => sub { 
::is scalar do {sround 10.11}, scalar do{10}, 'sround 10.11        # -> 10';
::is scalar do {sround 100.11}, scalar do{100}, 'sround 100.11       # -> 100';
::is scalar do {sround 0.00012}, scalar do{0.00012}, 'sround 0.00012      # -> 0.00012';
::is scalar do {sround 1.2345}, scalar do{1.2}, 'sround 1.2345       # -> 1.2';
::is scalar do {sround 1.2345, 3}, scalar do{1.23}, 'sround 1.2345, 3    # -> 1.23';

# 
# ## trans ($s)
# 
# Transliterates the russian text, leaving only Latin letters and dashes.
# 
done_testing; }; subtest 'trans ($s)' => sub { 
::is scalar do {trans "Мир во всём Мире!"}, "mir-vo-vsjom-mire", 'trans "Мир во всём Мире!"  # => mir-vo-vsjom-mire';

# 
# ## transliterate ($s)
# 
# Transliterates the russian text.
# 
done_testing; }; subtest 'transliterate ($s)' => sub { 
::is scalar do {transliterate "Мир во всём Мире!"}, "Mir vo vsjom Mire!", 'transliterate "Мир во всём Мире!"  # => Mir vo vsjom Mire!';

# 
# ## trapperr (&block)
# 
# Trap for STDERR.
# 
done_testing; }; subtest 'trapperr (&block)' => sub { 
::is scalar do {trapperr { print STDERR 123 }}, "123", 'trapperr { print STDERR 123 }  # => 123';

# 
# See also `IO::Capture::Stderr`.
# 
# ## trappout (&block)
# 
# Trap for STDOUT.
# 
done_testing; }; subtest 'trappout (&block)' => sub { 
::is scalar do {trappout { print 123 }}, "123", 'trappout { print 123 }  # => 123';

# 
# See also `IO::Capture::Stdout`.
# 
# ## TiB ()
# 
# The constant is one tebibyte.
# 
done_testing; }; subtest 'TiB ()' => sub { 
::is scalar do {TiB}, scalar do{2**40}, 'TiB  # -> 2**40';

# 
# ## GiB ()
# 
# The constant is one gibibyte.
# 
done_testing; }; subtest 'GiB ()' => sub { 
::is scalar do {GiB}, scalar do{2**30}, 'GiB  # -> 2**30';

# 
# ## MiB ()
# 
# The constant is one mebibyte.
# 
done_testing; }; subtest 'MiB ()' => sub { 
::is scalar do {MiB}, scalar do{2**20}, 'MiB  # -> 2**20';

# 
# ## KiB ()
# 
# The constant is one kibibyte.
# 
done_testing; }; subtest 'KiB ()' => sub { 
::is scalar do {KiB}, scalar do{2**10}, 'KiB  # -> 2**10';

# 
# ## xxL ()
# 
# Maximum length in data LongText mysql and mariadb.
# L - large.
# 
done_testing; }; subtest 'xxL ()' => sub { 
::is scalar do {xxL}, scalar do{4*GiB-1}, 'xxL  # -> 4*GiB-1';

# 
# ## xxM ()
# 
# Maximum length in data MediumText mysql and mariadb.
# M - medium.
# 
done_testing; }; subtest 'xxM ()' => sub { 
::is scalar do {xxM}, scalar do{16*MiB-1}, 'xxM  # -> 16*MiB-1';

# 
# ## xxR ()
# 
# Maximum length in data Text mysql and mariadb.
# R - regularity.
# 
done_testing; }; subtest 'xxR ()' => sub { 
::is scalar do {xxR}, scalar do{64*KiB-1}, 'xxR  # -> 64*KiB-1';

# 
# ## xxS ()
# 
# Maximum length in data TinyText mysql and mariadb.
# S - small.
# 
done_testing; }; subtest 'xxS ()' => sub { 
::is scalar do {xxS}, scalar do{255}, 'xxS  # -> 255';

# 
# ## to_str (;$scalar)
# 
# Converts to string perl without interpolation.
# 
done_testing; }; subtest 'to_str (;$scalar)' => sub { 
::is scalar do {to_str "a'\n"}, "'a\\'\n'", 'to_str "a\'\n" # => \'a\\\'\n\'';
::is_deeply scalar do {[map to_str, "a'\n"]}, scalar do {["'a\\'\n'"]}, '[map to_str, "a\'\n"] # --> ["\'a\\\'\n\'"]';

# 
# ## from_str (;$one_quote_str)
# 
# Converts from string perl without interpolation.
# 
done_testing; }; subtest 'from_str (;$one_quote_str)' => sub { 
::is scalar do {from_str "'a\\'\n'"}, "a'\n", 'from_str "\'a\\\'\n\'"  # => a\'\n';
::is_deeply scalar do {[map from_str, "'a\\'\n'"]}, scalar do {["a'\n"]}, '[map from_str, "\'a\\\'\n\'"]  # --> ["a\'\n"]';

# 
# # SUBROUTINES/METHODS
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# Aion::Format is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
