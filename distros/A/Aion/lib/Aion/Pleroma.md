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

Контейнер находится в переменной `$Aion::pleroma` и его можно заменить с помощью `local`.

Конфигурацию для создания эонов получает из конфига `PLEROMA` и файла аннотаций (создаётся пакетом `Aion::Annotation`). Файл аннотаций можно заменить через конфиг `INI`.

# CONFIG

Настройки модуля, которые можно установить в `.config.pm`:

* INI => 'etc/annotation/eon.ann' – файл аннотаций.
* PLEROMA => {} – дополнительный набор эонов.
* AUTOWARE => 1 – подгружать модули автоматически, даже если они не прописаны в конфигурации.

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
Aion::Pleroma->new->pleroma # --> {"Ex::Eon::AnimalEon" => "Ex::Eon::AnimalEon#new", "Ex::Eon::AnimalEon#dog" => "Ex::Eon::AnimalEon#dog", "ex.cat" => "Ex::Eon::AnimalEon#cat", "Aion::Pleroma" => "Aion::Pleroma#new"}
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

## autoware ($action, [$key])

Добавить ключ в плерому.

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

$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
$pleroma->autoware('Ex::Eon::AstroEon#mars', 'Ex::Eon::AstroEon#venus') # @-> Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
