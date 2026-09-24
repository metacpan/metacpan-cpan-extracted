!ru:en
# NAME

Aion::Pleroma - контейнер эонов

# SYNOPSIS

```perl
use Aion::Pleroma;

my $pleroma = Aion::Pleroma->new;

$pleroma->get('user') # -> undef
$pleroma->resolve('user') # @-> user is'nt eon!
```

# DESCRIPTION

Реализует паттерн контейнера зависимостей.

Эон создаётся при запросе из контейнера через метод `get` или `resolve`, либо через аспект `eon` как ленивый `default`. Ленивость можно отменить через аспект `lazy`.

Контейнер можно получить с помощью `Aion->pleroma`.

Конфигурацию для создания эонов получает из конфига `PLEROMA` и файла аннотаций (создаётся пакетом `Aion::Annotation`). Файл аннотаций можно заменить через конфиг `INI`.

# CONFIG

Настройки модуля, которые можно установить в `.env`:

* AION_PLEROMA_INI – файл аннотаций. По умолчанию `etc/annotation/eon.ann`.
* AION_PLEROMA_AUTOWARE – подгружать модули автоматически, даже если они не прописаны в конфигурации. По умолчанию `1`.

# EONS FROM CONFIG

В `etc/*.yml` можно добавить ключ `aion.eon` с описанием дополнительных эонов. Это позволяет собирать эоны декларативно: задавать аргументы конструктора (именованные или упорядоченные), вызывать методы после создания и передавать ссылки на другие эоны через `@`.

Опишем классы эонов.

Файл lib/Ex/Eon/Astronomer.pm:
```perl
package Ex::Eon::Astronomer;
use strict; use warnings;

sub new { my ($class, $name, $telescope) = @_; bless { name => $name, telescope => $telescope, seen => [] }, $class }
sub name      { $_[0]{name} }
sub telescope { $_[0]{telescope} }
sub seen      { $_[0]{seen} }
sub observe   {
	my ($self, $body) = @_;
	die "body is'nt Planet!" unless $body && $body->isa('Ex::Eon::Planet');
	push @{ $self->{seen} }, $body;
	$body
}

1;
```

Файл lib/Ex/Eon/Planet.pm:
```perl
package Ex::Eon::Planet;
use common::sense;
use Aion;

has name       => (is => 'ro');
has moons      => (is => 'ro', default => 0);
has discoverer => (is => 'ro');

1;
```

Теперь конфигурация эонов. У эона-учёного `Ex::Eon::Galileo` аргументы заданы упорядоченно (`arguments` – массив), после создания вызывается метод `observe` со ссылкой на другой эон (`@Ex::Eon::Saturn`). У планет `arguments` – хеш, а аргумент `discoverer` ссылается (`@`) на эон учёного.

Файл etc/aion/include.yml:
```yaml
aion:
  eon:
    Ex::Eon::Jupiter:
      class: 'Ex::Eon::Planet'
      arguments:
        name: 'Jupiter'
        moons: 95
        discoverer: '@Ex::Eon::Galileo'
    Ex::Eon::Saturn:
      class: 'Ex::Eon::Planet'
      arguments:
        name: 'Saturn'
        moons: 146
    Ex::Eon::Galileo:
      class: 'Ex::Eon::Astronomer'
      arguments: [ 'Galileo Galilei', 'refracting telescope' ]
      calls:
        - [observe, '@Ex::Eon::Saturn']
```

В конфигурации эон `Ex::Eon::Jupiter` описан раньше, чем `Ex::Eon::Galileo` (на которого он ссылается через `@`). Порядок описания не важен: эоны порождаются лениво при запросе, поэтому `@`-ссылка разрешается уже на готовый эон.

Прочитаем конфигурацию из `etc/aion/include.yml` и передадим её контейнеру.

```perl
use Aion::Pleroma;
use Aion::Env::Etc ();

my $etc = Aion::Env::Etc::parse('etc/aion/include.yml');
my $pleroma = Aion::Pleroma->new(pleroma => $etc->{aion}{eon});

my $jupiter = $pleroma->resolve('Ex::Eon::Jupiter');
$jupiter->name    # => Jupiter
$jupiter->moons   # => 95
$jupiter->discoverer->name # => Galileo Galilei
ref($jupiter->discoverer)  # => Ex::Eon::Astronomer

my $galileo = $pleroma->resolve('Ex::Eon::Galileo');
$galileo->name  # => Galileo Galilei
$galileo->telescope  # => refracting telescope
ref($galileo->seen->[0])  # => Ex::Eon::Planet
$galileo->seen->[0]->name # => Saturn
```

## Круговая зависимость

Если эоны ссылаются друг на друга, то контейнер не сможет их породить. Цикл вычисляется уже при добавлении эона (`autoware`) — на этапе сборки конфигурации — и выбрасывается исключение с цепочкой ссылок.

```perl
my $cnt = Aion::Pleroma->new;
$cnt->autoware({ class => 'Ex::Eon::Galileo', arguments => [ 'Galileo Galilei', 'refracting telescope' ], calls => [[ 'observe', '@Ex::Eon::Jupiter' ]] }, 'Ex::Eon::Galileo');
$cnt->autoware({ class => 'Ex::Eon::Planet', arguments => { name => 'Jupiter', moons => 95, discoverer => '@Ex::Eon::Galileo' } }, 'Ex::Eon::Jupiter') # @~> Circular eon dependency: .+Ex::Eon::Jupiter
```

## Eon description keys

Каждый эон в `aion.eon` описывается строкой или хешем.

Строка задаёт конструктор `'класс#метод'` (или просто `'класс'`), метод по умолчанию – `new`. Так создаются самые простые эоны без аргументов.

Хеш может содержать ключи:

* `class` – класс (пакет) эона. Если не указан и ключ эона похож на имя класса (`/^[\w:]+$/`), используется сам ключ.
* `method` – метод класса-конструктора. По умолчанию `new`.
* `arguments` – аргументы конструктора:
  * хеш – именованные аргументы (`new => %hash`);
  * массив – упорядоченные аргументы (`new => @array`).
* `calls` – список вызовов методов после создания эона. Каждый вызов – имя метода (без аргументов) или массив `[имя_метода, аргументы...]`.

Значение аргумента (или элемента вызова), начинающееся с `@`, воспринимается как ссылка на другой эон: `@ключ` заменяется порождённым эоном из контейнера.

# FEATURES

## ini

Файл с аннотациями.

```perl
Aion::Pleroma->new->ini # => etc/annotation/eon.ann
```

## pleroma

Конфигурация: ключ => 'класс#метод_класса'.

Файл lib/Ex/Eon/AnimalEon.pm:
```perl
package Ex::Eon::AnimalEon;
#@eon

use common::sense;

use Aion;
 
has role => (is => 'ro');

#@eon ex.cat
sub cat { __PACKAGE__->new(role => 'cat') }

#@eon
sub dog { __PACKAGE__->new(role => 'dog') }

1;
```

Файл etc/annotation/eon.ann:
```
Ex::Eon::AnimalEon#,2=
Ex::Eon::AnimalEon#cat,10=ex.cat
Ex::Eon::AnimalEon#dog,13=Ex::Eon::AnimalEon#dog
```

```perl
Aion::Pleroma->new->pleroma # --> { "Ex::Eon::AnimalEon#dog" => { class => "Ex::Eon::AnimalEon", method => "dog" }, "Ex::Eon::AnimalEon" => { class => "Ex::Eon::AnimalEon", method => "new" }, "ex.cat" => { class => "Ex::Eon::AnimalEon", method => "cat" }, "Aion::Pleroma" => { class => "Aion::Pleroma", method => "new" } }
```

## eon

Совокупность порождённых эонов.

```perl
my $pleroma = Aion::Pleroma->new;

$pleroma->eon # --> { "Aion::Pleroma" => $pleroma }
my $cat = $pleroma->resolve('ex.cat');
$pleroma->eon # --> { "ex.cat" => $cat, "Aion::Pleroma" => $pleroma }
```

# SUBROUTINES

## get ($key)

Получить эон из контейнера.

```perl
my $pleroma = Aion::Pleroma->new;
$pleroma->get('') # -> undef
$pleroma->get('Ex::Eon::AnimalEon#dog')->role # => dog
```

## resolve ($key)

Получить эон из контейнера или исключение, если его там нет.

```perl
my $pleroma = Aion::Pleroma->new;
$pleroma->resolve('e.ibex') # @=> e.ibex is'nt eon!
$pleroma->resolve('Ex::Eon::AnimalEon#dog')->role # => dog
```

## autoware ($config, [$key])

Добавить эон в плерому. `$config` – строка `'класс#метод'` (или просто `'класс'`) либо хеш с ключами `class`, `method`, а также опционально `arguments`/`calls` (см. выше). Если `$key` не задан, он выводится из конфигурации.

Файл lib/Ex/Eon/AstroEon.pm:
```perl
package Ex::Eon::AstroEon;
use common::sense;
use Aion;

has role => (is => 'ro', default => 'upiter');
sub mars { __PACKAGE__->new(role => 'mars') }
sub venus { __PACKAGE__->new(role => 'venus') }

1;
```

```perl
my $pleroma = Aion::Pleroma->new;
$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
$pleroma->autoware('Ex::Eon::AstroEon#mars', 'ex.mars')->get('ex.mars')->role # => mars
$pleroma->autoware('Ex::Eon::AstroEon#venus')->get('Ex::Eon::AstroEon#venus')->role # => venus

$pleroma->autoware({class => 'Ex::Eon::AstroEon', method => 'venus'})->get('Ex::Eon::AstroEon#venus')->role # => venus

$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
$pleroma->autoware('Ex::Eon::AstroEon#mars', 'Ex::Eon::AstroEon#venus') # @-> Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
