!ru:en,badges
# NAME

Aion::Annotation - обрабатывает аннотации в модулях perl

# VERSION

0.0.3

# SYNOPSIS

Файл lib/For/Test.pm:
```perl
package For::Test;
# The package for testing
#@deprecated for_test

#@deprecated
#@todo add1
# Is property
#   readonly
has abc => (is => 'ro');

#@todo add2
#@param Int $a
#@param Int[] $r
sub xyz {}

1;
```

```perl
use Aion::Annotation;

Aion::Annotation->new->scan;

open my $f, '<', 'var/cache/modules.mtime.ini' or die $!; my @modules_mtime = <$f>; chop for @modules_mtime; close $f;
open my $f, '<', 'etc/annotation/remarks.ini' or die $!; my @remarks = <$f>; chop for @remarks; close $f;
open my $f, '<', 'etc/annotation/todo.ann' or die $!; my @todo = <$f>; chop for @todo; close $f;
open my $f, '<', 'etc/annotation/deprecated.ann' or die $!; my @deprecated = <$f>; chop for @deprecated; close $f;
open my $f, '<', 'etc/annotation/param.ann' or die $!; my @param = <$f>; chop for @param; close $f;

0+@modules_mtime  # -> 1
$modules_mtime[0] # ~> ^For::Test=\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$
\@remarks         # --> ['For::Test#,4=The package for testing', 'For::Test#abc,9=Is property\n  readonly']
\@todo            # --> ['For::Test#abc,6=add1', 'For::Test#xyz,11=add2']
\@deprecated      # --> ['For::Test#,3=for_test', 'For::Test#abc,5=']
\@param           # --> ['For::Test#xyz,12=Int $a', 'For::Test#xyz,13=Int[] $r']
```

# DESCRIPTION

`Aion::Annotation` сканирует модули perl в каталоге **lib** и распечатывает их в соответстующие файлы в каталоге **etc/annotation**.

Сменить **lib** можно через конфиг `LIB`, **etc/annotation** через конфиг `INI`, а **var/cache** через конфиг `CACHE`.

1. В **modules.mtime.ini** хранятся времена последнего обновления модулей.
2. В **remarks.ini** сохраняются комментарии к подпрограммам, свойствам и пакетам.
3. В файлах **имя.ann** сохраняются аннотации по своим именам.

# SUBROUTINES/METHODS

## scan ()

Сканирует кодовую базу задаваемую конфигом `LIB` (перечень каталогов, по умолчанию `["lib"]`). И достаёт все аннотации и комментарии и распечатывает их в соответстующие файлы в каталоге `INI` (по умолчанию "etc/annotation").

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Annotation module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
