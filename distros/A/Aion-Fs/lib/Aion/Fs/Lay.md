# NAME

Aion::Fs::Lay - файловый дескриптор с автозакрытием

# SYNOPSIS

```perl
use Aion::Fs::Lay;
use Symbol;

my $file = "lay.test.txt";

my $f = Symbol::gensym;
open $f, ">", $file or die $!;

$f = Aion::Fs::Lay->new(f => $f, path => $file);

printf $f "%s!\n", "hi";

-s $f; # -> 0
my $std = select $f; $| = 1; select $std;
-s $f; # -> 4

$f->path; # => lay.test.txt

undef $f;
```

# DESCRIPTION

Содержит файловый дескриптор, который закрывается в деструкторе. А благодаря перегрузке оператора `*{}` работает со всеми файловыми операциями **perl**.

Используется в [Aion::Fs::ilay](https://metacpan.org/pod/Aion::Fs#ilay-\(%3B%24path\)).

# SUBROUTINES

## new (%params)

Конструктор.

## path ()

Путь к файлу.

## DESTROY ()

Деструктор. Закрывает файловый дескриптор.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Fs::Lay module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
