# NAME

Aion::Fs::Cat - файловый дескриптор с автозакрытием

# SYNOPSIS

```perl
use Aion::Fs qw/lay/;
use Aion::Fs::Cat;
use Symbol;

my $file = "lay.test.txt";

lay $file, "xyz";

my $f = Symbol::gensym;
open $f, "<", $file;

$f = Aion::Fs::Cat->new(f => $f, path => $file);

-d $f # -> ""
-f $f # -> 1

read $f, my $buf, 1;
$buf # => x

<$f> # => yz

$f->path; # => lay.test.txt

undef $f;
```

# DESCRIPTION

Содержит файловый дескриптор, который закрывается в деструкторе. А благодаря перегрузке операторов `*{}`, `-X` и `<>` работает со всеми файловыми операциями `perl`.

Используется в [Aion::Fs::ilay](https://metacpan.org/pod/Aion::Fs#icat-\(%3B%24path\)).

# SUBROUTINES

## new (%args)

Конструктор.

## path ()

Путь к файлу.

## next ()

Следующая строка.

## DESTROY ()

Деструктор. Закрывает файловый дескриптор.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Fs::Cat module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
