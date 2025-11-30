use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Format - расширение Perl для форматирования чисел, раскрашивания вывода и т.п.
# 
# # VERSION
# 
# 0.0.10
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Format;

local ($::_g0 = do {trappout { print "123\n" }}, $::_e0 = "123\n"); ::ok $::_g0 eq $::_e0, 'trappout { print "123\n" } # => 123\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {coloring "#red ↬ #r\n"}, $::_e0 = "\e[31m ↬ \e[0m\n"); ::ok $::_g0 eq $::_e0, 'coloring "#red ↬ #r\n" # => \e[31m ↬ \e[0m\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {trappout { printcolor "#red ↬ #r\n" }}, $::_e0 = "\e[31m ↬ \e[0m\n"); ::ok $::_g0 eq $::_e0, 'trappout { printcolor "#red ↬ #r\n" } # => \e[31m ↬ \e[0m\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Утилиты для форматирования чисел, раскрашивания вывода и т.п.
# 
# # SUBROUTINES
# 
# ## coloring ($format, @params)
# 
# Раскрашивает текст с помощью escape-последовательностей, а затем заменяет формат на `sprintf`. Названия цветов используются из модуля `Term::ANSIColor`. Для **RESET** используйте `#r` или `#R`.
# 
::done_testing; }; subtest 'coloring ($format, @params)' => sub { 
local ($::_g0 = do {coloring "#{BOLD RED}###r %i", 6}, $::_e0 = "\e[1;31m##\e[0m 6"); ::ok $::_g0 eq $::_e0, 'coloring "#{BOLD RED}###r %i", 6 # => \e[1;31m##\e[0m 6' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## printcolor ($format, @params)
# 
# Как `coloring`, но печатает отформатированную строку на стандартный вывод.
# 
# ## warncolor ($format, @params)
# 
# Как `coloring`, но печатает отформатированную строку в `STDERR`.
# 
::done_testing; }; subtest 'warncolor ($format, @params)' => sub { 
local ($::_g0 = do {trapperr { warncolor "#{green}ACCESS#r %i\n", 6 }}, $::_e0 = "\e[32mACCESS\e[0m 6\n"); ::ok $::_g0 eq $::_e0, 'trapperr { warncolor "#{green}ACCESS#r %i\n", 6 }  # => \e[32mACCESS\e[0m 6\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## accesslog ($format, @params)
# 
# Пишет в STDOUT используя для форматирования функцию `coloring` и добавляет префикс с датой-временем.
# 
::done_testing; }; subtest 'accesslog ($format, @params)' => sub { 
::like scalar do {trappout { accesslog "#{green}ACCESS#r %i\n", 6 }}, qr{\[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[32mACCESS\e\[0m 6\n}, 'trappout { accesslog "#{green}ACCESS#r %i\n", 6 }  # ~> \[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[32mACCESS\e\[0m 6\n'; undef $::_g0; undef $::_e0;

# 
# ## errorlog ($format, @params)
# 
# Пишет в **STDERR** используя для форматирования функцию `coloring` и добавляет префикс с датой-временем.
# 
::done_testing; }; subtest 'errorlog ($format, @params)' => sub { 
::like scalar do {trapperr { errorlog "#{red}ERROR#r %i\n", 6 }}, qr{\[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[31mERROR\e\[0m 6\n}, 'trapperr { errorlog "#{red}ERROR#r %i\n", 6 }  # ~> \[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[31mERROR\e\[0m 6\n'; undef $::_g0; undef $::_e0;

# 
# ## p ($target; %properties)
# 
# `p` из Data::Printer с предустановленными настройками.
# 
# Вместо неудобного первого параметра используется просто скаляр.
# 
# Необязательный параметр `%properties` позволяет перекрывать настройки. 
# 
::done_testing; }; subtest 'p ($target; %properties)' => sub { 
::like scalar do {trapperr { p +{cat => 123} }}, qr{cat.+123}, 'trapperr { p +{cat => 123} } # ~> cat.+123'; undef $::_g0; undef $::_e0;

# 
# ## np ($target; %properties)
# 
# `np` из Data::Printer с предустановленными настройками.
# 
# Вместо неудобного первого параметра используется просто скаляр.
# 
# Необязательный параметр `%properties` позволяет перекрывать настройки. 
# 
::done_testing; }; subtest 'np ($target; %properties)' => sub { 
::like scalar do {np +{cat => 123}}, qr{cat.+123}, 'np +{cat => 123} # ~> cat.+123'; undef $::_g0; undef $::_e0;

# 
# ## flesch_index_human ($flesch_index)
# 
# Преобразует индекс Флеша в русскоязычную метку с помощью шага 10.
# 
::done_testing; }; subtest 'flesch_index_human ($flesch_index)' => sub { 
local ($::_g0 = do {flesch_index_human -10}, $::_e0 = "несвязный русский текст"); ::ok $::_g0 eq $::_e0, 'flesch_index_human -10   # => несвязный русский текст' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human -3}, $::_e0 = "для академиков"); ::ok $::_g0 eq $::_e0, 'flesch_index_human -3    # => для академиков' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human 0}, $::_e0 = "для академиков"); ::ok $::_g0 eq $::_e0, 'flesch_index_human 0     # => для академиков' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human 1}, $::_e0 = "для академиков"); ::ok $::_g0 eq $::_e0, 'flesch_index_human 1     # => для академиков' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human 15}, $::_e0 = "для профессионалов"); ::ok $::_g0 eq $::_e0, 'flesch_index_human 15    # => для профессионалов' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human 99}, $::_e0 = "для 11 лет (уровень 5-го класса)"); ::ok $::_g0 eq $::_e0, 'flesch_index_human 99    # => для 11 лет (уровень 5-го класса)' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human 100}, $::_e0 = "для младшеклассников"); ::ok $::_g0 eq $::_e0, 'flesch_index_human 100   # => для младшеклассников' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {flesch_index_human 110}, $::_e0 = "несвязный русский текст"); ::ok $::_g0 eq $::_e0, 'flesch_index_human 110   # => несвязный русский текст' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from_radix ($string, $radix)
# 
# Анализирует натуральное число в указанной системе счисления. По умолчанию используется 64-значная система.
# 
# Для цифр используются символы 0–9, A–Z, a–z, _ и –. Эти символы используются до и для 64 значной системы. Для цифр после 64 значной системы используются символы кодировки **CP1251**.
# 
::done_testing; }; subtest 'from_radix ($string, $radix)' => sub { 
local ($::_g0 = do {from_radix "A-C"}, $::_e0 = do {45004}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'from_radix "A-C" # -> 45004' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {from_radix "A-C", 64}, $::_e0 = do {45004}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'from_radix "A-C", 64 # -> 45004' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {from_radix "A-C", 255}, $::_e0 = do {666327}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'from_radix "A-C", 255 # -> 666327' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {eval { from_radix "A-C", 256 }; $@}, qr{The number system 256 is too large. Use NS before 256}, 'eval { from_radix "A-C", 256 }; $@ 	# ~> The number system 256 is too large. Use NS before 256'; undef $::_g0; undef $::_e0;

# 
# ## to_radix ($number, $radix)
# 
# Преобразует натуральное число в заданную систему счисления. По умолчанию используется 64-значная система.
# 
::done_testing; }; subtest 'to_radix ($number, $radix)' => sub { 
local ($::_g0 = do {to_radix 10_000}, $::_e0 = "2SG"); ::ok $::_g0 eq $::_e0, 'to_radix 10_000 				# => 2SG' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {to_radix 10_000, 64}, $::_e0 = "2SG"); ::ok $::_g0 eq $::_e0, 'to_radix 10_000, 64 			# => 2SG' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {to_radix 10_000, 255}, $::_e0 = "dt"); ::ok $::_g0 eq $::_e0, 'to_radix 10_000, 255 			# => dt' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
::like scalar do {eval { to_radix 0, 256 }; $@}, qr{The number system 256 is too large. Use NS before 256}, 'eval { to_radix 0, 256 }; $@ 	# ~> The number system 256 is too large. Use NS before 256'; undef $::_g0; undef $::_e0;

# 
# ## kb_size ($number)
# 
# Добавляет числовые цифры и добавляет единицу измерения.
# 
::done_testing; }; subtest 'kb_size ($number)' => sub { 
local ($::_g0 = do {kb_size 102}, $::_e0 = "102b"); ::ok $::_g0 eq $::_e0, 'kb_size 102             # => 102b' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {kb_size 1024}, $::_e0 = "1k"); ::ok $::_g0 eq $::_e0, 'kb_size 1024            # => 1k' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {kb_size 1023}, $::_e0 = "1\x{a0}023b"); ::ok $::_g0 eq $::_e0, 'kb_size 1023            # => 1\x{a0}023b' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {kb_size 1024*1024}, $::_e0 = "1M"); ::ok $::_g0 eq $::_e0, 'kb_size 1024*1024       # => 1M' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {kb_size 1000_002_000_001_000}, $::_e0 = "931\x{a0}324G"); ::ok $::_g0 eq $::_e0, 'kb_size 1000_002_000_001_000    # => 931\x{a0}324G' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## replace ($subject, @rules)
# 
# Несколько преобразований текста за один проход.
# 
::done_testing; }; subtest 'replace ($subject, @rules)' => sub { 
my $s = replace "33*pi",
    qr/(?<num> \d+)/x   => sub { "($+{num})" },
    qr/\b pi \b/x       => sub { 3.14 },
    qr/(?<op> \*)/x     => sub { " $& " },
;

local ($::_g0 = do {$s}, $::_e0 = "(33) * 3.14"); ::ok $::_g0 eq $::_e0, '$s # => (33) * 3.14' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## matches ($subject, @rules)
# 
# Синоним `replace`. **DEPRECATED**.
# 
::done_testing; }; subtest 'matches ($subject, @rules)' => sub { 
my $s = matches "33*pi",
    qr/(?<num> \d+)/x   => sub { "($+{num})" },
    qr/\b pi \b/x       => sub { 3.14 },
    qr/(?<op> \*)/x     => sub { " $& " },
;

local ($::_g0 = do {$s}, $::_e0 = "(33) * 3.14"); ::ok $::_g0 eq $::_e0, '$s # => (33) * 3.14' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## nous ($templates)
# 
# Упрощенный язык регулярных выражений для распознавания текста в документах HTML.
# 
# 1. Убирает все пробелы в начале и конце.
# 2. С начала каждой строки удаляются 4 пробела или 0-3 пробела и табуляция.
# 3. Пробелы в конце строки и строки пробелов заменяются на `\s*`. 
# 4. Все переменные в `{{ var }}` заменяются на `.*?`. Т.е. распознаётся всё.
# 4. Все переменные в `{{> var }}` заменяются на `[^<>]*?`. Т.е. не распознаются html-теги.
# 4. Все переменные в `{{: var }}` заменяются на `[^\n]*`. Т.е. должно быть на одной строке.
# 5. Выражения в двойных квадратных скобках (`[[ ... ]]`) могут не существовать.
# 5. В качестве круглых скобок используются двойные скобки (`(( ... ))`).
# 5. `||` - или.
# 
::done_testing; }; subtest 'nous ($templates)' => sub { 
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
local ($::_g0 = do {$result}, $::_e0 = do {{author_link => "/to/book/link", author_name => "A. Alis", title => "Grivus campf"}}); ::is_deeply $::_g0, $::_e0, '$result # --> {author_link => "/to/book/link", author_name => "A. Alis", title => "Grivus campf"}' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## num ($number)
# 
# Добавляет разделители между цифрами числа.
# 
::done_testing; }; subtest 'num ($number)' => sub { 
local ($::_g0 = do {num +0}, $::_e0 = "0"); ::ok $::_g0 eq $::_e0, 'num +0         # => 0' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {num -1000.3}, $::_e0 = "-1 000.3"); ::ok $::_g0 eq $::_e0, 'num -1000.3    # => -1 000.3' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Разделителем по умолчанию является неразрывный пробел. Установите разделитель и десятичную точку так же, как:
# 

local ($::_g0 = do {num [1000, "#"]}, $::_e0 = "1#000"); ::ok $::_g0 eq $::_e0, 'num [1000, "#"]         		# => 1#000' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {num [-1000.3003003, "_", ","]}, $::_e0 = "-1_000,3003003"); ::ok $::_g0 eq $::_e0, 'num [-1000.3003003, "_", ","]   # => -1_000,3003003' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# См. также `Number::Format`.
# 
# ## rim ($number)
# 
# Переводит положительные целые числа в **римские цифры**.
# 
::done_testing; }; subtest 'rim ($number)' => sub { 
local ($::_g0 = do {rim 0}, $::_e0 = "N"); ::ok $::_g0 eq $::_e0, 'rim 0       # => N' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 4}, $::_e0 = "IV"); ::ok $::_g0 eq $::_e0, 'rim 4       # => IV' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 6}, $::_e0 = "VI"); ::ok $::_g0 eq $::_e0, 'rim 6       # => VI' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 50}, $::_e0 = "L"); ::ok $::_g0 eq $::_e0, 'rim 50      # => L' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 49}, $::_e0 = "XLIX"); ::ok $::_g0 eq $::_e0, 'rim 49      # => XLIX' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 505}, $::_e0 = "DV"); ::ok $::_g0 eq $::_e0, 'rim 505     # => DV' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# **Римские цифры** после 1000:
# 

local ($::_g0 = do {rim 49_000}, $::_e0 = "XLIX M"); ::ok $::_g0 eq $::_e0, 'rim 49_000      # => XLIX M' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 49_000_000}, $::_e0 = "XLIX M M"); ::ok $::_g0 eq $::_e0, 'rim 49_000_000  # => XLIX M M' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {rim 49_009_555}, $::_e0 = "XLIX IX DLV"); ::ok $::_g0 eq $::_e0, 'rim 49_009_555  # => XLIX IX DLV' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# См. также:
# 
# * [Roman](https://metacpan.org/pod/Roman) это простой конвертер.
# * [Math::Roman](https://metacpan.org/pod/Math::Roman) это еще один конвертер.
# * [Convert::Number::Roman](https://metacpan.org/pod/Convert::Number::Roman) имеет ООП-интерфейс.
# * [Number::Convert::Roman](https://metacpan.org/pod/Number::Convert::Roman) – еще один интерфейс ООП.
# * [Text::Roman](https://metacpan.org/pod/Text::Roman) конвертирует стандартные и милхарные римские числа.
# * [Roman::Unicode](https://metacpan.org/pod/Roman::Unicode) использует цифры ↁ (5 000), ↂ (1000) и так далее.
# * [Acme::Roman](https://metacpan.org/pod/Acme::Roman) добавляет поддержку римских цифр в коде Perl (`I + II -> III`), но использует только операции `+`, `-` и `*`.
# * [Date::Roman](https://metacpan.org/pod/Date::Roman) — это объектно-ориентированное расширение Perl для обработки дат в римском стиле, но с арабскими цифрами (id 3 702).
# * [DateTime::Format::Roman](https://metacpan.org/pod/DateTime::Format::Roman) – средство форматирования римских дат, но с арабскими цифрами (5 Kal Jun 2003).
# 
# ## round ($number, $decimal)
# 
# Округляет число до указанного десятичного знака.
# 
::done_testing; }; subtest 'round ($number, $decimal)' => sub { 
local ($::_g0 = do {round 1.234567, 2}, $::_e0 = do {1.23}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'round 1.234567, 2  # -> 1.23' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {round 1.235567, 2}, $::_e0 = do {1.24}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'round 1.235567, 2  # -> 1.24' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## sinterval ($interval)
# 
# Создает человекочитаемый интервал.
# 
# Ширина результата — 12 символов.
# 
::done_testing; }; subtest 'sinterval ($interval)' => sub { 
local ($::_g0 = do {sinterval  6666.6666}, $::_e0 = "01:51:06.667"); ::ok $::_g0 eq $::_e0, 'sinterval  6666.6666 	# => 01:51:06.667' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sinterval  6.6666}, $::_e0 = "00:00:06.667"); ::ok $::_g0 eq $::_e0, 'sinterval  6.6666 		# => 00:00:06.667' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sinterval  .333}, $::_e0 = "0.33300000 s"); ::ok $::_g0 eq $::_e0, 'sinterval  .333 		# => 0.33300000 s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sinterval  .000_33}, $::_e0 = "0.3300000 ms"); ::ok $::_g0 eq $::_e0, 'sinterval  .000_33 		# => 0.3300000 ms' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sinterval  .000_000_33}, $::_e0 = "0.330000 mks"); ::ok $::_g0 eq $::_e0, 'sinterval  .000_000_33 	# => 0.330000 mks' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## sround ($number, $digits)
# 
# Оставляет `$digits` цифр после последнего нуля (сам 0 не учитывается).
# 
# По умолчанию `$digits` равен 2.
# 
::done_testing; }; subtest 'sround ($number, $digits)' => sub { 
local ($::_g0 = do {sround 10.11}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 10.11        # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sround 12.11}, $::_e0 = do {12}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 12.11        # -> 12' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sround 100.11}, $::_e0 = do {100}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 100.11       # -> 100' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sround 133.11}, $::_e0 = do {133}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 133.11       # -> 133' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sround 0.00012}, $::_e0 = do {0.00012}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 0.00012      # -> 0.00012' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sround 1.2345}, $::_e0 = do {1.2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 1.2345       # -> 1.2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {sround 1.2345, 3}, $::_e0 = do {1.23}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'sround 1.2345, 3    # -> 1.23' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## trans ($s)
# 
# Транслитерирует русский текст, оставляя только латинские буквы и тире.
# 
::done_testing; }; subtest 'trans ($s)' => sub { 
local ($::_g0 = do {trans "Мир во всём Мире!"}, $::_e0 = "mir-vo-vsjom-mire"); ::ok $::_g0 eq $::_e0, 'trans "Мир во всём Мире!"  # => mir-vo-vsjom-mire' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## transliterate ($s)
# 
# Транслитерирует русский текст.
# 
::done_testing; }; subtest 'transliterate ($s)' => sub { 
local ($::_g0 = do {transliterate "Мир во всём Мире!"}, $::_e0 = "Mir vo vsjom Mire!"); ::ok $::_g0 eq $::_e0, 'transliterate "Мир во всём Мире!"  # => Mir vo vsjom Mire!' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## trapperr (&block)
# 
# Ловушка для **STDERR**.
# 
::done_testing; }; subtest 'trapperr (&block)' => sub { 
local ($::_g0 = do {trapperr { print STDERR "Stars: ✨" }}, $::_e0 = "Stars: ✨"); ::ok $::_g0 eq $::_e0, 'trapperr { print STDERR "Stars: ✨" }  # => Stars: ✨' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# См. также `IO::Capture::Stderr`.
# 
# ## trappout (&block)
# 
# Ловушка для **STDOUT**.
# 
::done_testing; }; subtest 'trappout (&block)' => sub { 
local ($::_g0 = do {trappout { print "Stars: ✨" }}, $::_e0 = "Stars: ✨"); ::ok $::_g0 eq $::_e0, 'trappout { print "Stars: ✨" }  # => Stars: ✨' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# См. также `IO::Capture::Stdout`.
# 
# ## TiB ()
# 
# Константа равна одному тебибайту.
# 
::done_testing; }; subtest 'TiB ()' => sub { 
local ($::_g0 = do {TiB}, $::_e0 = do {2**40}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'TiB  # -> 2**40' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## GiB ()
# 
# Константа равна одному гибибайту.
# 
::done_testing; }; subtest 'GiB ()' => sub { 
local ($::_g0 = do {GiB}, $::_e0 = do {2**30}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'GiB  # -> 2**30' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MiB ()
# 
# Константа равна одному мебибайту.
# 
::done_testing; }; subtest 'MiB ()' => sub { 
local ($::_g0 = do {MiB}, $::_e0 = do {2**20}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'MiB  # -> 2**20' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## KiB ()
# 
# Константа равна одному кибибайту.
# 
::done_testing; }; subtest 'KiB ()' => sub { 
local ($::_g0 = do {KiB}, $::_e0 = do {2**10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'KiB  # -> 2**10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## xxL ()
# 
# Максимальная длина данных LongText mysql и mariadb.
# L - large.
# 
::done_testing; }; subtest 'xxL ()' => sub { 
local ($::_g0 = do {xxL}, $::_e0 = do {4*GiB-1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'xxL  # -> 4*GiB-1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## xxM ()
# 
# Максимальная длина данных MediumText mysql и mariadb.
# M - medium.
# 
::done_testing; }; subtest 'xxM ()' => sub { 
local ($::_g0 = do {xxM}, $::_e0 = do {16*MiB-1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'xxM  # -> 16*MiB-1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## xxR ()
# 
# Максимальная длина текста данных mysql и mariadb.
# R - regularity.
# 
::done_testing; }; subtest 'xxR ()' => sub { 
local ($::_g0 = do {xxR}, $::_e0 = do {64*KiB-1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'xxR  # -> 64*KiB-1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## xxS ()
# 
# Максимальная длина данных TinyText mysql и mariadb.
# S - small.
# 
::done_testing; }; subtest 'xxS ()' => sub { 
local ($::_g0 = do {xxS}, $::_e0 = do {255}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'xxS  # -> 255' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## to_str (;$scalar)
# 
# Преобразование в строку Perl без интерполяции.
# 
::done_testing; }; subtest 'to_str (;$scalar)' => sub { 
local ($::_g0 = do {to_str "a'\n"}, $::_e0 = "'a\\'\n'"); ::ok $::_g0 eq $::_e0, 'to_str "a\'\n" # => \'a\\\'\n\'' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map to_str, "a'\n"]}, $::_e0 = do {["'a\\'\n'"]}); ::is_deeply $::_g0, $::_e0, '[map to_str, "a\'\n"] # --> ["\'a\\\'\n\'"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## from_str (;$one_quote_str)
# 
# Преобразование из строки Perl без интерполяции.
# 
::done_testing; }; subtest 'from_str (;$one_quote_str)' => sub { 
local ($::_g0 = do {from_str "'a\\'\n'"}, $::_e0 = "a'\n"); ::ok $::_g0 eq $::_e0, 'from_str "\'a\\\'\n\'"  # => a\'\n' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {[map from_str, "'a\\'\n'"]}, $::_e0 = do {["a'\n"]}); ::is_deeply $::_g0, $::_e0, '[map from_str, "\'a\\\'\n\'"]  # --> ["a\'\n"]' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

	::done_testing;
};

::done_testing;
