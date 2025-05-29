use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s =  '/tmp/.liveman/perl-aion/aion'    ;     File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $s), File::Path::rmtree($s) if -e $s;     File::Path::mkpath($s);     chdir $s or die "chdir $s: $!";      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     }  } # 
# # NAME
# 
# Aion - постмодернистская объектная система для Perl 5, такая как «Mouse», «Moose», «Moo», «Mo» и «M», но с улучшениями
# 
# # VERSION
# 
# 0.2
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Calc {

    use Aion;

    has a => (is => 'ro+', isa => Num);
    has b => (is => 'ro+', isa => Num);
    has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

    sub result : Isa(Object => Num) {
        my ($self) = @_;
        eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
    }

}

::is scalar do {Calc->new(a => 1.1, b => 2)->result}, "3.1", 'Calc->new(a => 1.1, b => 2)->result   # => 3.1';

# 
# # DESCRIPTION
# 
# Aion — ООП-фреймворк для создания классов с **фичами**, имеет **аспекты**, **роли** и так далее.
# 
# Свойства, объявленные через has, называются **фичами**.
# 
# А `is`, `isa`, `default` и так далее в `has` называются **аспектами**.
# 
# Помимо стандартных аспектов, роли могут добавлять свои собственные аспекты с помощью подпрограммы **aspect**.
# 
# Сигнатура методов может проверяться с помощью атрибута `:Isa(...)`.
# 
# # SUBROUTINES IN CLASSES AND ROLES
# 
# `use Aion` импортирует типы из модуля `Aion::Types` и следующие подпрограммы:
# 
# ## has ($name, %aspects)
# 
# Создаёт метод для получения/установки функции (свойства) класса.
# 
# Файл lib/Animal.pm:
#@> lib/Animal.pm
#>> package Animal;
#>> use Aion;
#>> 
#>> has type => (is => 'ro+', isa => Str);
#>> has name => (is => 'rw-', isa => Str, default => 'murka');
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'has ($name, %aspects)' => sub { 
use lib "lib";
use Animal;

my $cat = Animal->new(type => 'cat');

::is scalar do {$cat->type}, "cat", '$cat->type   # => cat';
::is scalar do {$cat->name}, "murka", '$cat->name   # => murka';

$cat->name("murzik");
::is scalar do {$cat->name}, "murzik", '$cat->name   # => murzik';

# 
# ## with
# 
# Добавляет в модуль роли. Для каждой роли вызывается метод `import_with`.
# 
# Файл lib/Role/Keys/Stringify.pm:
#@> lib/Role/Keys/Stringify.pm
#>> package Role::Keys::Stringify;
#>> 
#>> use Aion -role;
#>> 
#>> sub keysify {
#>>     my ($self) = @_;
#>>     join ", ", sort keys %$self;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/Role/Values/Stringify.pm:
#@> lib/Role/Values/Stringify.pm
#>> package Role::Values::Stringify;
#>> 
#>> use Aion -role;
#>> 
#>> sub valsify {
#>>     my ($self) = @_;
#>>     join ", ", map $self->{$_}, sort keys %$self;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/Class/All/Stringify.pm:
#@> lib/Class/All/Stringify.pm
#>> package Class::All::Stringify;
#>> 
#>> use Aion;
#>> 
#>> with q/Role::Keys::Stringify/;
#>> with q/Role::Values::Stringify/;
#>> 
#>> has [qw/key1 key2/] => (is => 'rw', isa => Str);
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'with' => sub { 
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

::is scalar do {$s->keysify}, "key1, key2", '$s->keysify     # => key1, key2';
::is scalar do {$s->valsify}, "a, b", '$s->valsify     # => a, b';

# 
# ## isa ($package)
# 
# Проверяет, что `$package` — это суперкласс для данного или сам этот класс.
# 
done_testing; }; subtest 'isa ($package)' => sub { 
package Ex::X { use Aion; }
package Ex::A { use Aion; extends q/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

::is scalar do {Ex::C->isa("Ex::A")}, scalar do{1}, 'Ex::C->isa("Ex::A") # -> 1';
::is scalar do {Ex::C->isa("Ex::B")}, scalar do{1}, 'Ex::C->isa("Ex::B") # -> 1';
::is scalar do {Ex::C->isa("Ex::X")}, scalar do{1}, 'Ex::C->isa("Ex::X") # -> 1';
::is scalar do {Ex::C->isa("Ex::X1")}, scalar do{""}, 'Ex::C->isa("Ex::X1") # -> ""';
::is scalar do {Ex::A->isa("Ex::X")}, scalar do{1}, 'Ex::A->isa("Ex::X") # -> 1';
::is scalar do {Ex::A->isa("Ex::A")}, scalar do{1}, 'Ex::A->isa("Ex::A") # -> 1';
::is scalar do {Ex::X->isa("Ex::X")}, scalar do{1}, 'Ex::X->isa("Ex::X") # -> 1';

# 
# ## does ($package)
# 
# Проверяет, что `$package` — это роль, которая используется в классе или другой роли.
# 
done_testing; }; subtest 'does ($package)' => sub { 
package Role::X { use Aion -role; }
package Role::A { use Aion; with qw/Role::X/; }
package Role::B { use Aion; }
package Ex::Z { use Aion; with qw/Role::A Role::B/ }

::is scalar do {Ex::Z->does("Role::A")}, scalar do{1}, 'Ex::Z->does("Role::A") # -> 1';
::is scalar do {Ex::Z->does("Role::B")}, scalar do{1}, 'Ex::Z->does("Role::B") # -> 1';
::is scalar do {Ex::Z->does("Role::X")}, scalar do{1}, 'Ex::Z->does("Role::X") # -> 1';
::is scalar do {Role::A->does("Role::X")}, scalar do{1}, 'Role::A->does("Role::X") # -> 1';
::is scalar do {Role::A->does("Role::X1")}, scalar do{""}, 'Role::A->does("Role::X1") # -> ""';
::is scalar do {Ex::Z->does("Ex::Z")}, scalar do{""}, 'Ex::Z->does("Ex::Z") # -> ""';

# 
# ## aspect ($aspect => sub { ... })
# 
# Добавляет аспект к `has` в текущем классе и его классам-наследникам или текущей роли и применяющим её классам.
# 
done_testing; }; subtest 'aspect ($aspect => sub { ... })' => sub { 
package Example::Earth {
    use Aion;

    aspect lvalue => sub {
        my ($cls, $name, $value, $construct, $feature) = @_;

        $construct->{attr} .= ":lvalue";
    };

    has moon => (is => "rw", lvalue => 1);
}

my $earth = Example::Earth->new;

$earth->moon = "Mars";

::is scalar do {$earth->moon}, "Mars", '$earth->moon # => Mars';

# 
# Аспект вызывается каждый раз, когда он указан в `has`.
# 
# Создатель аспекта имеет параметры:
# 
# * `$cls` — пакет с `has`.
# * `$name` — имя фичи.
# * `$value` — значение аспекта.
# * `$construct` — хэш с фрагментами кода для присоединения к методу объекта.
# * `$feature` — хеш описывающий фичу.
# 

package Example::Mars {
    use Aion;

    aspect lvalue => sub {
        my ($cls, $name, $value, $construct, $feature) = @_;

        $construct->{attr} .= ":lvalue";

::is scalar do {$cls}, "Example::Mars", '        $cls # => Example::Mars';
::is scalar do {$name}, "moon", '        $name # => moon';
::is scalar do {$value}, scalar do{1}, '        $value # -> 1';
::is_deeply scalar do {[sort keys %$construct]}, scalar do {[qw/attr eval get name pkg ret set sub/]}, '        [sort keys %$construct] # --> [qw/attr eval get name pkg ret set sub/]';
::is_deeply scalar do {[sort keys %$feature]}, scalar do {[qw/construct has name opt order/]}, '        [sort keys %$feature] # --> [qw/construct has name opt order/]';

        my $_construct = {
            pkg => $cls,
            name => $name,
			attr => ':lvalue',
			eval => 'package %(pkg)s {
	%(sub)s
}',
            sub => 'sub %(name)s%(attr)s {
		if(@_>1) {
			my ($self, $val) = @_;
			%(set)s%(ret)s
		} else {
			my ($self) = @_;
			%(get)s
		}
	}',
            get => '$self->{%(name)s}',
            set => '$self->{%(name)s} = $val',
            ret => '; $self',
        };

::is_deeply scalar do {$construct}, scalar do {$_construct}, '        $construct # --> $_construct';

        my $_feature = {
            has => [is => "rw", lvalue => 1],
            opt => {
                is => "rw",
                lvalue => 1,
            },
            name => $name,
            construct => $_construct,
            order => 0,
        };

::is_deeply scalar do {$feature}, scalar do {$_feature}, '        $feature # --> $_feature';
    };

    has moon => (is => "rw", lvalue => 1);
}

# 
# # SUBROUTINES IN CLASSES
# 
# ## extends (@superclasses)
# 
# Расширяет класс другим классом/классами. Он вызывает из каждого наследуемого класса метод `import_extends`, если он в нём есть.
# 
done_testing; }; subtest 'extends (@superclasses)' => sub { 
package World { use Aion;

    our $extended_by_this = 0;

    sub import_extends {
        my ($class, $extends) = @_;
        $extended_by_this ++;

::is scalar do {$class}, "World", '        $class      # => World';
::is scalar do {$extends}, "Hello", '        $extends    # => Hello';
    }
}

package Hello { use Aion;
    extends q/World/;

::is scalar do {$World::extended_by_this}, scalar do{1}, '    $World::extended_by_this # -> 1';
}

::is scalar do {Hello->isa("World")}, scalar do{1}, 'Hello->isa("World")     # -> 1';

# 
# ## new (%param)
# 
# Конструктор.
# 
# * Устанавливает `%param` для фич.
# * Проверяет, что параметры соответствуют фичам.
# * Устанавливает значения по умолчанию.
# 
done_testing; }; subtest 'new (%param)' => sub { 
package NewExample { use Aion;
    has x => (is => 'ro', isa => Num);
    has y => (is => 'ro+', isa => Num);
    has z => (is => 'ro-', isa => Num);
}

::like scalar do {eval { NewExample->new(f => 5) }; $@}, qr!f is not feature\!!, 'eval { NewExample->new(f => 5) }; $@            # ~> f is not feature!';
::like scalar do {eval { NewExample->new(n => 5, r => 6) }; $@}, qr!n, r is not features\!!, 'eval { NewExample->new(n => 5, r => 6) }; $@    # ~> n, r is not features!';
::like scalar do {eval { NewExample->new }; $@}, qr!Feature y is required\!!, 'eval { NewExample->new }; $@                    # ~> Feature y is required!';
::like scalar do {eval { NewExample->new(z => 10) }; $@}, qr!Feature z cannot set in new\!!, 'eval { NewExample->new(z => 10) }; $@           # ~> Feature z cannot set in new!';

my $ex = NewExample->new(y => 8);

::like scalar do {eval { $ex->x }; $@}, qr!Get feature `x` must have the type Num. The it is undef!, 'eval { $ex->x }; $@  # ~> Get feature `x` must have the type Num. The it is undef';

$ex = NewExample->new(x => 10.1, y => 8);

::is scalar do {$ex->x}, scalar do{10.1}, '$ex->x # -> 10.1';

# 
# # SUBROUTINES IN ROLES
# 
# ## requires (@subroutine_names)
# 
# Проверяет, что в классах использующих эту роль есть указанные подпрограммы или фичи.
# 
done_testing; }; subtest 'requires (@subroutine_names)' => sub { 
package Role::Alpha { use Aion -role;

    sub in {
        my ($self, $s) = @_;
        $s =~ /[${\ $self->abc }]/
    }

    requires qw/abc/;
}

::like scalar do {eval { package Omega1 { use Aion; with Role::Alpha; } }; $@}, qr!abc requires\!!, 'eval { package Omega1 { use Aion; with Role::Alpha; } }; $@ # ~> abc requires!';

package Omega { use Aion;
    with Role::Alpha;

    sub abc { "abc" }
}

::is scalar do {Omega->new->in("a")}, scalar do{1}, 'Omega->new->in("a")  # -> 1';

# 
# # METHODS
# 
# ## has ($feature)
# 
# Проверяет, что свойство установлено.
# 
# Фичи имеющие `default => sub { ... }` выполняют `sub` при первом вызове геттера, то есть: являются отложенными.
# 
# `$object->has('фича')` позволяет проверить, что `default` ещё не вызывался.
# 
done_testing; }; subtest 'has ($feature)' => sub { 
package ExHas { use Aion;
    has x => (is => 'rw');
}

my $ex = ExHas->new;

::is scalar do {$ex->has("x")}, scalar do{""}, '$ex->has("x")   # -> ""';

$ex->x(10);

::is scalar do {$ex->has("x")}, scalar do{1}, '$ex->has("x")   # -> 1';

# 
# ## clear (@features)
# 
# Удаляет ключи фич из объекта предварительно вызвав на них `clearer` (если есть).
# 
done_testing; }; subtest 'clear (@features)' => sub { 
package ExClearer { use Aion;
    has x => (is => 'rw');
    has y => (is => 'rw');
}

my $c = ExClearer->new(x => 10, y => 12);

::is scalar do {$c->has("x")}, scalar do{1}, '$c->has("x")   # -> 1';
::is scalar do {$c->has("y")}, scalar do{1}, '$c->has("y")   # -> 1';

$c->clear(qw/x y/);

::is scalar do {$c->has("x")}, scalar do{""}, '$c->has("x")   # -> ""';
::is scalar do {$c->has("y")}, scalar do{""}, '$c->has("y")   # -> ""';

# 
# 
# # METHODS IN CLASSES
# 
# `use Aion` включает в модуль следующие методы:
# 
# ## new (%parameters)
# 
# Конструктор.
# 
# # ASPECTS
# 
# `use Aion` включает в модуль следующие аспекты для использования в `has`:
# 
# ## is => $permissions
# 
# * `ro` — создать только геттер.
# * `wo` — создать только сеттер.
# * `rw` — создать геттер и сеттер.
# 
# По умолчанию — `rw`.
# 
# Дополнительные разрешения:
# 
# * `+` — фича обязательна в параметрах конструктора. `+` не используется с `-`.
# * `-` — фича не может быть установлена через конструктор. '-' не используется с `+`.
# * `*` — не инкрементировать счётчик ссылок на значение (применить `weaken` к значению после установки его в фичу).
# 
done_testing; }; subtest 'is => $permissions' => sub { 
package ExIs { use Aion;
    has rw => (is => 'rw');
    has ro => (is => 'ro+');
    has wo => (is => 'wo-');
}

::like scalar do {eval { ExIs->new }; $@}, qr!\* Feature ro is required\!!, 'eval { ExIs->new }; $@ # ~> \* Feature ro is required!';
::like scalar do {eval { ExIs->new(ro => 10, wo => -10) }; $@}, qr!\* Feature wo cannot set in new\!!, 'eval { ExIs->new(ro => 10, wo => -10) }; $@ # ~> \* Feature wo cannot set in new!';
ExIs->new(ro => 10);
ExIs->new(ro => 10, rw => 20);

::is scalar do {ExIs->new(ro => 10)->ro}, scalar do{10}, 'ExIs->new(ro => 10)->ro  # -> 10';

::is scalar do {ExIs->new(ro => 10)->wo(30)->has("wo")}, scalar do{1}, 'ExIs->new(ro => 10)->wo(30)->has("wo")  # -> 1';
::like scalar do {eval { ExIs->new(ro => 10)->wo }; $@}, qr!has: wo is wo- \(not get\)!, 'eval { ExIs->new(ro => 10)->wo }; $@ # ~> has: wo is wo- \(not get\)';
::is scalar do {ExIs->new(ro => 10)->rw(30)->rw}, scalar do{30}, 'ExIs->new(ro => 10)->rw(30)->rw  # -> 30';

# 
# Функция с `*` не удерживает значение:
# 

package Node { use Aion;
    has parent => (is => "rw*", isa => Maybe[Object["Node"]]);
}

my $root = Node->new;
my $node = Node->new(parent => $root);

::is scalar do {$node->parent->parent}, scalar do{undef}, '$node->parent->parent   # -> undef';
undef $root;
::is scalar do {$node->parent}, scalar do{undef}, '$node->parent   # -> undef';

# And by setter:
$node->parent($root = Node->new);

::is scalar do {$node->parent->parent}, scalar do{undef}, '$node->parent->parent   # -> undef';
undef $root;
::is scalar do {$node->parent}, scalar do{undef}, '$node->parent   # -> undef';

# 
# ## isa => $type
# 
# Указывает тип, а точнее – валидатор, фичи.
# 
done_testing; }; subtest 'isa => $type' => sub { 
package ExIsa { use Aion;
    has x => (is => 'ro', isa => Int);
}

::like scalar do {eval { ExIsa->new(x => 'str') }; $@}, qr!\* Feature x must have the type Int. The it is 'str'!, 'eval { ExIsa->new(x => \'str\') }; $@ # ~> \* Feature x must have the type Int. The it is \'str\'';
::like scalar do {eval { ExIsa->new->x          }; $@}, qr!Get feature `x` must have the type Int. The it is undef!, 'eval { ExIsa->new->x          }; $@ # ~> Get feature `x` must have the type Int. The it is undef';
::is scalar do {ExIsa->new(x => 10)->x}, scalar do{10}, 'ExIsa->new(x => 10)->x              # -> 10';

# 
# Список валидаторов см. в [Aion::Type](https://metacpan.org/pod/Aion::Type).
# 
# ## default => $value
# 
# Значение по умолчанию устанавливается в конструкторе, если параметр с именем фичи отсутствует.
# 
done_testing; }; subtest 'default => $value' => sub { 
package ExDefault { use Aion;
    has x => (is => 'ro', default => 10);
}

::is scalar do {ExDefault->new->x}, scalar do{10}, 'ExDefault->new->x  # -> 10';
::is scalar do {ExDefault->new(x => 20)->x}, scalar do{20}, 'ExDefault->new(x => 20)->x  # -> 20';

# 
# Если `$value` является подпрограммой, то подпрограмма считается конструктором значения фичи. Используется ленивое вычисление.
# 

my $count = 10;

package ExLazy { use Aion;
    has x => (default => sub {
        my ($self) = @_;
        ++$count
    });
}

my $ex = ExLazy->new;
::is scalar do {$count}, scalar do{10}, '$count   # -> 10';
::is scalar do {$ex->x}, scalar do{11}, '$ex->x   # -> 11';
::is scalar do {$count}, scalar do{11}, '$count   # -> 11';
::is scalar do {$ex->x}, scalar do{11}, '$ex->x   # -> 11';
::is scalar do {$count}, scalar do{11}, '$count   # -> 11';

# 
# ## trigger => $sub
# 
# `$sub` вызывается после установки свойства в конструкторе (`new`) или через сеттер.
# Этимология – впустить.
# 
done_testing; }; subtest 'trigger => $sub' => sub { 
package ExTrigger { use Aion;
    has x => (trigger => sub {
        my ($self, $old_value) = @_;
        $self->y($old_value + $self->x);
    });

    has y => ();
}

my $ex = ExTrigger->new(x => 10);
::is scalar do {$ex->y}, scalar do{10}, '$ex->y      # -> 10';
$ex->x(20);
::is scalar do {$ex->y}, scalar do{30}, '$ex->y      # -> 30';

# 
# ## release => $sub
# 
# `$sub` вызывается перед возвратом свойства из объекта через геттер.
# Этимология – выпустить.
# 
done_testing; }; subtest 'release => $sub' => sub { 
package ExRelease { use Aion;
    has x => (release => sub {
        my ($self, $value) = @_;
        $_[1] = $value + 1;
    });
}

my $ex = ExRelease->new(x => 10);
::is scalar do {$ex->x}, scalar do{11}, '$ex->x      # -> 11';

# 
# ## clearer => $sub
# 
# `$sub` вызывается при вызове декструктора или `$object->clear("feature")`, но только если свойство имеется (см. `$object->has("feature")`).
# 
done_testing; }; subtest 'clearer => $sub' => sub { 
package ExClearer { use Aion;
	
	our $x;

    has x => (clearer => sub {
        my ($self) = @_;
        $x = $self->x
    });
}

::is scalar do {$ExClearer::x}, scalar do{undef}, '$ExClearer::x      	# -> undef';
ExClearer->new(x => 10);
::is scalar do {$ExClearer::x}, scalar do{10}, '$ExClearer::x      	# -> 10';

my $ex = ExClearer->new(x => 12);

::is scalar do {$ExClearer::x}, scalar do{10}, '$ExClearer::x      # -> 10';
$ex->clear('x');
::is scalar do {$ExClearer::x}, scalar do{12}, '$ExClearer::x      # -> 12';

undef $ex;

::is scalar do {$ExClearer::x}, scalar do{12}, '$ExClearer::x      # -> 12';

# 
# # ATTRIBUTES
# 
# `Aion` добавляет в пакет универсальные атрибуты.
# 
# ## Isa (@signature)
# 
# Атрибут `Isa` проверяет сигнатуру функции.
# 
# **ВНИМАНИЕ**: использование атрибута «Isa» замедляет работу программы.
# 
# **СОВЕТ**: использования аспекта `isa` для объектов более чем достаточно, чтобы проверить правильность данных объекта.
# 
done_testing; }; subtest 'Isa (@signature)' => sub { 
package Anim { use Aion;

    sub is_cat : Isa(Object => Str => Bool) {
        my ($self, $anim) = @_;
        $anim =~ /(cat)/
    }
}

my $anim = Anim->new;

::is scalar do {$anim->is_cat('cat')}, scalar do{1}, '$anim->is_cat(\'cat\')    # -> 1';
::is scalar do {$anim->is_cat('dog')}, scalar do{""}, '$anim->is_cat(\'dog\')    # -> ""';


::like scalar do {eval { Anim->is_cat("cat") }; $@}, qr!Arguments of method `is_cat` must have the type Tuple\[Object, Str\].!, 'eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].';
::like scalar do {eval { my @items = $anim->is_cat("cat") }; $@}, qr!Returns of method `is_cat` must have the type Tuple\[Bool\].!, 'eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].';

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
# The Aion module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
