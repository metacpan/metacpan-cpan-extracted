!ru:en,badges
# NAME

Aion::Annotation::Reader - считывает аннотации, комментарии и времена обновления модулей

# VERSION

0.1.0

# SYNOPSIS

Файл etc/annotation/todo.ann:
```perl
For::Test#abc,5=add1
For::Test#xyz,11=add2
```

Файл etc/annotation/remarks.ini:
```perl
For::Test#,4=The package for testing
For::Test#abc,9=Is property\n  readonly
```

Файл var/cache/modules.mtime.ini:
```perl
For::Test=2025-01-02 03:04:05
```

```perl
use Aion::Annotation::Reader;
use Time::Local qw/timelocal/;

my $reader = Aion::Annotation::Reader->new('todo');

my @ann; push @ann, $_ while <$reader>;

my $ann = [
	{pkg => 'For::Test', name => 'abc', line => '5',  annotation => 'add1'},
	{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'},
];

\@ann # --> $ann

my $reader_remarks = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_REMARKS);

my $remarks = [
	{pkg => 'For::Test', name => '',    line => '4', remark => 'The package for testing'},
	{pkg => 'For::Test', name => 'abc', line => '9', remark => "Is property\n  readonly"},
];

\@{$reader_remarks} # --> $remarks

my $reader_mtime = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_MTIME);

# Время хранится как unixtime, поэтому ожидаемое значение не зависит от часового пояса
my $mtime = [{pkg => 'For::Test', mtime => timelocal(5, 4, 3, 2, 0, 2025)}];

\@{$reader_mtime} # --> $mtime
```

# DESCRIPTION

`Aion::Annotation::Reader` читает файлы, которые создаёт [Aion::Annotation](https://metacpan.org/pod/Aion::Annotation), и отдаёт их содержимое построчно в виде хешей.

Доступны три вида данных:

1. Аннотации из файлов **имя.ann** (имя передаётся в конструктор).
2. Комментарии из **remarks.ini**.
3. Времена обновления модулей из **modules.mtime.ini**.

Читатель спроектирован как итератор поверх файла: конструктор открывает файл, а метод `next` возвращает очередной распознанный элемент. Объект перегружает ряд операций, чтобы читателя можно было использовать как файл или функцию прямо в выражениях.

Распознанные строки представляются хешами:

1. Аннотация (файл **etc/annotation/*.ann**) – ключи `pkg`, `name`, `line`, `annotation`.
2. Комментарий (файл **etc/annotation/remarks.ini**) – ключи `pkg`, `name`, `line`, `remark`.
3. Время (файл **var/cache/modules.mtime.ini**) – ключи `pkg`, `mtime`.

Каталоги настраиваются переменными окружения `AION_ANNOTATION_INI` (по умолчанию `etc/annotation`) и `AION_ANNOTATION_CACHE` (по умолчанию `var/cache`).

# OVERLOAD

`Aion::Annotation::Reader` перегружает операции:

## <>

Вызов читателя.

```perl
my $reader = Aion::Annotation::Reader->new('todo');

my @ann; push @ann, $_ while <$reader>;
0+@ann  # -> 2
```

## @{}

Список всех элементов.

```perl
my $reader = Aion::Annotation::Reader->new('todo');

my $ann = [
	{pkg => 'For::Test', name => 'abc', line => '5',  annotation => 'add1'},
	{pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'},
];

\@{$reader} # --> $ann
```

## &{}

Вызов как функции.

Каждое обращение возвращает следующий элемент или `undef` в конце:

```perl
my $reader = Aion::Annotation::Reader->new('todo');

&$reader # --> {pkg => 'For::Test', name => 'abc', line => '5', annotation => 'add1'}
&$reader # --> {pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'}
&$reader # -> undef
```

## *{}

Файловый дескриптор.

```perl
my $reader = Aion::Annotation::Reader->new('todo');
my $fh = *$reader;
readline $fh  # ~> ^For::Test#abc,5=add1$
```

## -X

Файловые операции.

Операции вида `-e`, `-s`, `-f` выполняются над файлом читателя. Результат операции кешируется:

```perl
my $reader = Aion::Annotation::Reader->new('todo');
-e $reader # -> 1
-s $reader # -> 43
-f $reader # -> 1
```

## ""

Строковое представление.

```perl
my $reader = Aion::Annotation::Reader->new('todo');
"$reader" # => Aion::Annotation::Reader<ann,etc/annotation/todo.ann>
```

# CONSTANTS

## READ_REMARKS

Специальное имя, при котором читается файл комментариев:

```perl
Aion::Annotation::Reader::READ_REMARKS  # -> "-remarks"
```

## READ_MTIME

Специальное имя, при котором читается файл времён обновления:

```perl
Aion::Annotation::Reader::READ_MTIME  # -> "-mtime"
```

## MODULES_MTIME_FILE

Имя файла времён обновления:

```perl
Aion::Annotation::Reader::MODULES_MTIME_FILE  # -> "modules.mtime.ini"
```

## REMARKS_FILE

Имя файла комментариев:

```perl
Aion::Annotation::Reader::REMARKS_FILE  # -> "remarks.ini"
```

## LINE_REGEX

Регулярное выражение строки аннотации или комментария:

```perl
my $line = 'For::Test#abc,5=add1';
my ($pkg, $name, $lineno, $text) = $line =~ Aion::Annotation::Reader::LINE_REGEX;
"$pkg|$name|$lineno|$text"  # -> "For::Test|abc|5|add1"
```

## MTIME_REGEX

Регулярное выражение строки времени обновления:

```perl
my $line = 'For::Test=2025-01-02 03:04:05';
$line =~ Aion::Annotation::Reader::MTIME_REGEX;
"$+{module}|$+{year}-$+{mon}-$+{mday} $+{hour}:$+{min}:$+{sec}"  # -> "For::Test|2025-01-02 03:04:05"
```

# SUBROUTINES

## new ($cls, $ann)

Конструктор. В `$ann` передаётся имя аннотации (тогда читается `etc/annotation/$ann.ann`), либо константы `READ_REMARKS` или `READ_MTIME`. Файл открывается сразу в конструкторе:

```perl
my $reader = Aion::Annotation::Reader->new('todo');
ref $reader       # -> "Aion::Annotation::Reader"
$reader->{type}   # -> "ann"
$reader->path     # -> "etc/annotation/todo.ann"
```

Вызов допустим и у экземпляра:

```perl
my $reader = Aion::Annotation::Reader->new('todo');
$reader->new('todo')->path  # -> "etc/annotation/todo.ann"
```

Если файла нет – бросается исключение:

```perl
eval { Aion::Annotation::Reader->new('no_such_annotation') };
$@ # ~> ^etc/annotation/no_such_annotation\.ann: 
```

## path ()

Путь к открытому файлу:

```perl
my $reader = Aion::Annotation::Reader->new(Aion::Annotation::Reader::READ_REMARKS);
$reader->path  # -> "etc/annotation/remarks.ini"
```

## next ()

Возвращает следующий распознанный элемент. В скалярном контексте – один элемент или `undef`, в списочном – все оставшиеся элементы:

```perl
my $reader = Aion::Annotation::Reader->new('todo');

scalar $reader->next # --> {pkg => 'For::Test', name => 'abc', line => '5', annotation => 'add1'}
scalar $reader->next # --> {pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'}
scalar $reader->next # -> undef
```

## DESTROY ()

Закрывает файл при уничтожении объекта. Обычно вызывается автоматически:

```perl
my $f;
{
	my $reader = Aion::Annotation::Reader->new('todo');
	$f = $reader->{f};
	defined fileno $f # -> 1
} # $reader->DESTROY closes the file

fileno $f  # -> undef
```

## detect_annotation ($self, $line)

Распознаёт строку аннотации. Возвращает хеш с ключами `pkg`, `name`, `line`, `annotation`:

```perl
my $test = {
	pkg => 'For::Test', name => 'xyz', line => '11', annotation => 'add2'
};

my $reader = Aion::Annotation::Reader->new('todo');
Aion::Annotation::Reader::detect_annotation($reader, "For::Test#xyz,11=add2\n") # --> $test
```

## detect_remark ($self, $line)

Распознаёт строку комментария. Экранированные последовательности `\n` превращаются в переводы строк, а `\<символ>` – в сам символ:

```perl
my $test = {
	pkg => 'For::Test', name => 'abc', line => '9', remark => "Is property\n  readonly"
};

my $reader = Aion::Annotation::Reader->new('todo');
Aion::Annotation::Reader::detect_remark($reader, "For::Test#abc,9=Is property\\n  readonly\n") # --> $test
```

## detect_mtime ($self, $line)

Распознаёт строку времени обновления. Поле `mtime` — это unixtime (в локальном часовом поясе):

```perl
use Time::Local qw/timelocal/;

my $test = {
	pkg => 'For::Test', mtime => timelocal(5, 4, 3, 2, 0, 2025)
};

my $reader = Aion::Annotation::Reader->new('todo');
Aion::Annotation::Reader::detect_mtime($reader, "For::Test=2025-01-02 03:04:05\n") # --> $test
```

# CORRUPT LINES

Если строка не соответствует формату, выдаётся предупреждение (`warn`), а элемент всё равно возвращается – с неопределёнными полями. Это позволяет не прерывать чтение на повреждённом файле:

```perl
use Aion::Annotation::Reader;

my @warn;
local $SIG{__WARN__} = sub { push @warn, @_ };

my $reader = Aion::Annotation::Reader->new('todo');

Aion::Annotation::Reader::detect_annotation($reader, "corrupt line\n") # --> {pkg => undef, name => undef, line => undef, annotation => undef}
Aion::Annotation::Reader::detect_remark($reader, "corrupt line\n") # --> {pkg => undef, name => undef, line => undef, remark => ''}
Aion::Annotation::Reader::detect_mtime($reader, "corrupt line\n") # --> {pkg => undef, mtime => undef}

0+@warn  # -> 3
$warn[0] # ~> ^etc/annotation/todo\.ann corrupt on line 
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Annotation::Reader module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
