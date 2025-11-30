!ru:en,badges
# NAME

Aion::Format - расширение Perl для форматирования чисел, раскрашивания вывода и т.п.

# VERSION

0.1.0

# SYNOPSIS

```perl
use Aion::Format;

trappout { print "123\n" } # => 123\n

coloring "#red ↬ #r\n" # => \e[31m ↬ \e[0m\n
trappout { printcolor "#red ↬ #r\n" } # => \e[31m ↬ \e[0m\n
```

# DESCRIPTION

Утилиты для форматирования чисел, раскрашивания вывода и т.п.

# SUBROUTINES

## coloring ($format, @params)

Раскрашивает текст с помощью escape-последовательностей, а затем заменяет формат на `sprintf`. Названия цветов используются из модуля `Term::ANSIColor`. Для **RESET** используйте `#r` или `#R`.

```perl
coloring "#{BOLD RED}###r %i", 6 # => \e[1;31m##\e[0m 6
```

## printcolor ($format, @params)

Как `coloring`, но печатает отформатированную строку на стандартный вывод.

## warncolor ($format, @params)

Как `coloring`, но печатает отформатированную строку в `STDERR`.

```perl
trapperr { warncolor "#{green}ACCESS#r %i\n", 6 }  # => \e[32mACCESS\e[0m 6\n
```

## accesslog ($format, @params)

Пишет в STDOUT используя для форматирования функцию `coloring` и добавляет префикс с датой-временем.

```perl
trappout { accesslog "#{green}ACCESS#r %i\n", 6 }  # ~> \[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[32mACCESS\e\[0m 6\n
```

## errorlog ($format, @params)

Пишет в **STDERR** используя для форматирования функцию `coloring` и добавляет префикс с датой-временем.

```perl
trapperr { errorlog "#{red}ERROR#r %i\n", 6 }  # ~> \[\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\] \e\[31mERROR\e\[0m 6\n
```

## p ($target; %properties)

`p` из Data::Printer с предустановленными настройками.

Вместо неудобного первого параметра используется просто скаляр.

Необязательный параметр `%properties` позволяет перекрывать настройки. 

```perl
trapperr { p +{cat => 123} } # ~> cat.+123
```

## np ($target; %properties)

`np` из Data::Printer с предустановленными настройками.

Вместо неудобного первого параметра используется просто скаляр.

Необязательный параметр `%properties` позволяет перекрывать настройки. 

```perl
np +{cat => 123} # ~> cat.+123
```

## flesch_index_human ($flesch_index)

Преобразует индекс Флеша в русскоязычную метку с помощью шага 10.

```perl
flesch_index_human -10   # => несвязный русский текст
flesch_index_human -3    # => для академиков
flesch_index_human 0     # => для академиков
flesch_index_human 1     # => для академиков
flesch_index_human 15    # => для профессионалов
flesch_index_human 99    # => для 11 лет (уровень 5-го класса)
flesch_index_human 100   # => для младшеклассников
flesch_index_human 110   # => несвязный русский текст
```

## from_radix ($string, $radix)

Анализирует натуральное число в указанной системе счисления. По умолчанию используется 64-значная система.

Для цифр используются символы 0–9, A–Z, a–z, _ и –. Эти символы используются до и для 64 значной системы. Для цифр после 64 значной системы используются символы кодировки **CP1251**.

```perl
from_radix "A-C" # -> 45004
from_radix "A-C", 64 # -> 45004
from_radix "A-C", 255 # -> 666327
eval { from_radix "A-C", 256 }; $@ 	# ~> The number system 256 is too large. Use NS before 256
```

## to_radix ($number, $radix)

Преобразует натуральное число в заданную систему счисления. По умолчанию используется 64-значная система.

```perl
to_radix 10_000 				# => 2SG
to_radix 10_000, 64 			# => 2SG
to_radix 10_000, 255 			# => dt
eval { to_radix 0, 256 }; $@ 	# ~> The number system 256 is too large. Use NS before 256
```

## kb_size ($number)

Добавляет числовые цифры и добавляет единицу измерения.

```perl
kb_size 102             # => 102b
kb_size 1024            # => 1k
kb_size 1023            # => 1\x{a0}023b
kb_size 1024*1024       # => 1M
kb_size 1000_002_000_001_000    # => 931\x{a0}324G
```

## replace ($subject, @rules)

Несколько преобразований текста за один проход.

```perl
my $s = replace "33*pi",
    qr/(?<num> \d+)/x   => sub { "($+{num})" },
    qr/\b pi \b/x       => sub { 3.14 },
    qr/(?<op> \*)/x     => sub { " $& " },
;

$s # => (33) * 3.14
```

## matches ($subject, @rules)

Синоним `replace`. **DEPRECATED**.

```perl
my $s = matches "33*pi",
    qr/(?<num> \d+)/x   => sub { "($+{num})" },
    qr/\b pi \b/x       => sub { 3.14 },
    qr/(?<op> \*)/x     => sub { " $& " },
;

$s # => (33) * 3.14
```

## nous ($templates)

Упрощенный язык регулярных выражений для распознавания текста в документах HTML.

1. Убирает все пробелы в начале и конце.
2. С начала каждой строки удаляются 4 пробела или 0-3 пробела и табуляция.
3. Пробелы в конце строки и строки пробелов заменяются на `\s*`. 
4. Все переменные в `{{ var }}` заменяются на `.*?`. Т.е. распознаётся всё.
4. Все переменные в `{{> var }}` заменяются на `[^<>]*?`. Т.е. не распознаются html-теги.
4. Все переменные в `{{: var }}` заменяются на `[^\n]*`. Т.е. должно быть на одной строке.
5. Выражения в двойных квадратных скобках (`[[ ... ]]`) могут не существовать.
5. В качестве круглых скобок используются двойные скобки (`(( ... ))`).
5. `||` - или.

```perl
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
$result # --> {author_link => "/to/book/link", author_name => "A. Alis", title => "Grivus campf"}
```

## num ($number)

Добавляет разделители между цифрами числа.

```perl
num +0         # => 0
num -1000.3    # => -1 000.3
```

Разделителем по умолчанию является неразрывный пробел. Установите разделитель и десятичную точку так же, как:

```perl
num [1000, "#"]         		# => 1#000
num [-1000.3003003, "_", ","]   # => -1_000,3003003
```

См. также `Number::Format`.

## rim ($number)

Переводит положительные целые числа в **римские цифры**.

```perl
rim 0       # => N
rim 4       # => IV
rim 6       # => VI
rim 50      # => L
rim 49      # => XLIX
rim 505     # => DV
```

**Римские цифры** после 1000:

```perl
rim 49_000      # => XLIX M
rim 49_000_000  # => XLIX M M
rim 49_009_555  # => XLIX IX DLV
```

См. также:

* [Roman](https://metacpan.org/pod/Roman) это простой конвертер.
* [Math::Roman](https://metacpan.org/pod/Math::Roman) это еще один конвертер.
* [Convert::Number::Roman](https://metacpan.org/pod/Convert::Number::Roman) имеет ООП-интерфейс.
* [Number::Convert::Roman](https://metacpan.org/pod/Number::Convert::Roman) – еще один интерфейс ООП.
* [Text::Roman](https://metacpan.org/pod/Text::Roman) конвертирует стандартные и милхарные римские числа.
* [Roman::Unicode](https://metacpan.org/pod/Roman::Unicode) использует цифры ↁ (5 000), ↂ (1000) и так далее.
* [Acme::Roman](https://metacpan.org/pod/Acme::Roman) добавляет поддержку римских цифр в коде Perl (`I + II -> III`), но использует только операции `+`, `-` и `*`.
* [Date::Roman](https://metacpan.org/pod/Date::Roman) — это объектно-ориентированное расширение Perl для обработки дат в римском стиле, но с арабскими цифрами (id 3 702).
* [DateTime::Format::Roman](https://metacpan.org/pod/DateTime::Format::Roman) – средство форматирования римских дат, но с арабскими цифрами (5 Kal Jun 2003).

## round ($number, $decimal)

Округляет число до указанного десятичного знака.

```perl
round 1.234567, 2  # -> 1.23
round 1.235567, 2  # -> 1.24
```

## sinterval ($interval)

Создает человекочитаемый интервал.

Ширина результата — 12 символов.

```perl
sinterval  6666.6666 	# => 01:51:06.667
sinterval  6.6666 		# => 00:00:06.667
sinterval  .333 		# => 0.33300000 s
sinterval  .000_33 		# => 0.3300000 ms
sinterval  .000_000_33 	# => 0.330000 mks
```

## sround ($number, $digits)

Оставляет `$digits` цифр после последнего нуля (сам 0 не учитывается).

По умолчанию `$digits` равен 2.

```perl
sround 10.11        # -> 10
sround 12.11        # -> 12
sround 100.11       # -> 100
sround 133.11       # -> 133
sround 0.00012      # -> 0.00012
sround 1.2345       # -> 1.2
sround 1.2345, 3    # -> 1.23
```

## trans ($s)

Транслитерирует русский текст, оставляя только латинские буквы и тире.

```perl
trans "Мир во всём Мире!"  # => mir-vo-vsjom-mire
```

## transliterate ($s)

Транслитерирует русский текст.

```perl
transliterate "Мир во всём Мире!"  # => Mir vo vsjom Mire!
```

## trapperr (&block)

Ловушка для **STDERR**.

```perl
trapperr { print STDERR "Stars: ✨" }  # => Stars: ✨
```

См. также `IO::Capture::Stderr`.

## trappout (&block)

Ловушка для **STDOUT**.

```perl
trappout { print "Stars: ✨" }  # => Stars: ✨
```

См. также `IO::Capture::Stdout`.

## TiB ()

Константа равна одному тебибайту.

```perl
TiB  # -> 2**40
```

## GiB ()

Константа равна одному гибибайту.

```perl
GiB  # -> 2**30
```

## MiB ()

Константа равна одному мебибайту.

```perl
MiB  # -> 2**20
```

## KiB ()

Константа равна одному кибибайту.

```perl
KiB  # -> 2**10
```

## xxL ()

Максимальная длина данных LongText mysql и mariadb.
L - large.

```perl
xxL  # -> 4*GiB-1
```

## xxM ()

Максимальная длина данных MediumText mysql и mariadb.
M - medium.

```perl
xxM  # -> 16*MiB-1
```

## xxR ()

Максимальная длина текста данных mysql и mariadb.
R - regularity.

```perl
xxR  # -> 64*KiB-1
```

## xxS ()

Максимальная длина данных TinyText mysql и mariadb.
S - small.

```perl
xxS  # -> 255
```

## to_str (;$scalar)

Преобразование в строку Perl без интерполяции.

```perl
to_str "a'\n" # => 'a\\'\n'
[map to_str, "a'\n"] # --> ["'a\\'\n'"]
```

## from_str (;$one_quote_str)

Преобразование из строки Perl без интерполяции.

```perl
from_str "'a\\'\n'"  # => a'\n
[map from_str, "'a\\'\n'"]  # --> ["a'\n"]
```

# SUBROUTINES/METHODS

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

Aion::Format is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
