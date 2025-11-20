!ru:en
# NAME

Aion::Fs::Find - итератор поиска файлов для Aion::Fs#find

# SYNOPSIS

```perl
use Aion::Fs::Find;

my $iter = Aion::Fs::Find->new(
	files => ["."],
	filters => [],
	errorenter => sub {},
	noenters => [],
);

my @files;
while (<$iter>) {
    push @files, $_;
}

\@files # --> ["."]
```

# DESCRIPTION

Итератор поиска файлов для функции-адаптера `find` из модуля `Aion::Fs`.

Отдельно использовать не предполагается.

Обладает перегруженными операторами  `<>`, `@{}` и `&{}`.

# SUBROUTINES

## new (%params)

Конструктор.

## next ()

Следующая итерация.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Fs::Find module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
