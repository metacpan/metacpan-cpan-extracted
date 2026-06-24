[![Actions Status](https://github.com/darviarush/perl-aion-env/actions/workflows/test.yml/badge.svg)](https://github.com/darviarush/perl-aion-env/actions) [![GitHub Issues](https://img.shields.io/github/issues/darviarush/perl-aion-env?logo=perl)](https://github.com/darviarush/perl-aion-env/issues) [![MetaCPAN Release](https://badge.fury.io/pl/Aion-Env.svg)](https://metacpan.org/release/Aion-Env) [![Coverage](https://raw.githubusercontent.com/darviarush/perl-aion-env/master/doc/badges/total.svg)](https://fast2-matrix.cpantesters.org/?dist=Aion-Env+0.2)
# NAME

Aion::Env - создаёт константу связанную со значением из .env

# VERSION

0.2

# SYNOPSIS

Файл .env:
```text
BIN_TEST=10
OCT_TEST=${BIN_TEST}20
```

```perl
BEGIN {
	delete @ENV{qw/BIN_TEST OCT_TEST BB_TEST NN_TEST/};

	$ENV{UNI_TEST} = 30;
}

sub Int { sub { /^-?\d+$/ } }

use Aion::Env BIN_TEST => (isa => Int);
use Aion::Env OCT_TEST => (isa => Int);
use Aion::Env UNI_TEST => (isa => Int);
use Aion::Env BB_TEST => (isa => Int, default => 1);

BIN_TEST; # -> 10
OCT_TEST; # -> 1020
UNI_TEST; # -> 30
BB_TEST; # -> 1

eval 'use Aion::Env NN_TEST => ()'; $@; # ^-> NN_TEST is'nt defined!
eval 'use Aion::Env NN_TEST => (nouname => 1)'; $@; # ^-> Unknown aspect: nouname
eval 'use Aion::Env NN_TEST => (nouname1 => 1, nouname2 => 2)'; $@; # ^-> Unknown aspects: nouname1, nouname2
```

# DESCRIPTION

В проектах используется конфигурационный файл `.env` для конфигурации проекта, в `Makefile`, для `docker` и `docker compose`. Данный модуль позволяет оформить переменные окружения в виде констант модулей `perl`. 

Константы инициализируются из `%ENV`, если там нет значения или оно `undef`, то из файла `.env`, а если и там его не будет – из опции `default`.

При парсинге файла, ошибка синтаксиса приведёт к исключению.

Тип переменной окружения можно проверять с помощью опции `isa`. Она принимает подпрограмму или объект с перегруженным оператором `${}`. В этом случае значение будет передано в `$_`. Если объект имеет метод `validate`, как у `Aion::Type`, то будет вызван он с параметрами: значением и именем переменной окружения.

Рекомендуется называть переменные окружения используя название модуля в котором она объявлена. Например, пакет `Aion::Type`, тогда имена переменных окружения в нём – `AION_TYPE_*`.

# SUBROUTINES

## import ($cls, $name, %kw)

Создаёт константу с именем `$name` в пакете из которого вызван.
Опционально можно передать в `%kw` `isa` и `default`.

## parse ($file)

Парсит файл формата `.env` и возвращает хеш с переменными из него.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Env module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
