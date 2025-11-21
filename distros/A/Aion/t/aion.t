use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-1]); 	my $project_name = $dirs[$#dirs-1]; 	my @test_dirs = @dirs[$#dirs-1+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion - постмодернистская объектная система для Perl 5, такая как «Mouse», «Moose», «Moo», «Mo» и «M», но с улучшениями
# 
# # VERSION
# 
# 1.1
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Calc {

	use Aion;

	has a => (is => 'ro+', isa => Num);
	has b => (is => 'ro+', isa => Num);
	has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

	sub result : Isa(Me => Num) {
		my ($self) = @_;
		eval "${\ $self->a} ${\ $self->op} ${\ $self->b}";
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
::done_testing; }; subtest 'has ($name, %aspects)' => sub { 
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
#>> 	my ($self) = @_;
#>> 	join ", ", sort keys %$self;
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
#>> 	my ($self) = @_;
#>> 	join ", ", map $self->{$_}, sort keys %$self;
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
::done_testing; }; subtest 'with' => sub { 
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

::is scalar do {$s->keysify}, "key1, key2", '$s->keysify	 # => key1, key2';
::is scalar do {$s->valsify}, "a, b", '$s->valsify	 # => a, b';

# 
# ## isa ($package)
# 
# Проверяет, что `$package` — это суперкласс для данного или сам этот класс.
# 
::done_testing; }; subtest 'isa ($package)' => sub { 
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
::done_testing; }; subtest 'does ($package)' => sub { 
package Role::X { use Aion -role; }
package Role::A { use Aion -role; with qw/Role::X/; }
package Role::B { use Aion -role; }
package Ex::Z { use Aion; with qw/Role::A Role::B/; }

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
::done_testing; }; subtest 'aspect ($aspect => sub { ... })' => sub { 
package Example::Earth {
	use Aion;

	aspect lvalue => sub {
		my ($lvalue, $feature) = @_;

		return unless $lvalue;

		$feature->construct->add_attr(":lvalue");
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
# * `$value` — значение аспекта.
# * `$feature` — метаобъект описывающий фичу (`Aion::Meta::Feature`).
# * `$aspect_name` — наименование аспекта.
# 

package Example::Mars {
	use Aion;

	aspect lvalue => sub {
		my ($value, $feature, $aspect_name) = @_;

::is scalar do {$value}, scalar do{1}, '		$value # -> 1';
::is scalar do {$aspect_name}, "lvalue", '		$aspect_name # => lvalue';

		$feature->construct->add_attr(":lvalue");
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
::done_testing; }; subtest 'extends (@superclasses)' => sub { 
package World { use Aion;

	our $extended_by_this = 0;

	sub import_extends {
		my ($class, $extends) = @_;
		$extended_by_this ++;

::is scalar do {$class}, "World", '		$class   # => World';
::is scalar do {$extends}, "Hello", '		$extends # => Hello';
	}
}

package Hello { use Aion;
	extends q/World/;

::is scalar do {$World::extended_by_this}, scalar do{1}, '	$World::extended_by_this # -> 1';
}

::is scalar do {Hello->isa("World")}, scalar do{1}, 'Hello->isa("World")	 # -> 1';

# 
# ## new (%param)
# 
# Конструктор.
# 
# * Устанавливает `%param` для фич.
# * Проверяет, что параметры соответствуют фичам.
# * Устанавливает значения по умолчанию.
# 
::done_testing; }; subtest 'new (%param)' => sub { 
package NewExample { use Aion;
	has x => (is => 'ro', isa => Num);
	has y => (is => 'ro+', isa => Num);
	has z => (is => 'ro-', isa => Num);
}

eval {NewExample->new(f => 5)}; ok defined($@), 'NewExample->new(f => 5) # @-> y required!'; ::cmp_ok $@, '=~', '^' . quotemeta 'y required!', 'NewExample->new(f => 5) # @-> y required!';
eval {NewExample->new(f => 5, y => 10)}; ok defined($@), 'NewExample->new(f => 5, y => 10) # @-> f is\'nt feature!'; ::cmp_ok $@, '=~', '^' . quotemeta 'f is\'nt feature!', 'NewExample->new(f => 5, y => 10) # @-> f is\'nt feature!';
eval {NewExample->new(f => 5, p => 6, y => 10)}; ok defined($@), 'NewExample->new(f => 5, p => 6, y => 10) # @-> f, p is\'nt features!'; ::cmp_ok $@, '=~', '^' . quotemeta 'f, p is\'nt features!', 'NewExample->new(f => 5, p => 6, y => 10) # @-> f, p is\'nt features!';
eval {NewExample->new(z => 10, y => 10)}; ok defined($@), 'NewExample->new(z => 10, y => 10) # @-> z excessive!'; ::cmp_ok $@, '=~', '^' . quotemeta 'z excessive!', 'NewExample->new(z => 10, y => 10) # @-> z excessive!';

my $ex = NewExample->new(y => 8);

eval {$ex->x}; ok defined($@), '$ex->x # @-> Get feature x must have the type Num. The it is undef!'; ::cmp_ok $@, '=~', '^' . quotemeta 'Get feature x must have the type Num. The it is undef!', '$ex->x # @-> Get feature x must have the type Num. The it is undef!';

$ex = NewExample->new(x => 10.1, y => 8);

::is scalar do {$ex->x}, scalar do{10.1}, '$ex->x # -> 10.1';

# 
# # SUBROUTINES IN ROLES
# 
# ## requires (@subroutine_names)
# 
# Проверяет, что в классах, использующих эту роль, есть указанные подпрограммы или фичи.
# 
::done_testing; }; subtest 'requires (@subroutine_names)' => sub { 
package Role::Alpha { use Aion -role;

	requires qw/abc/;
}

package Omega1 { use Aion; with Role::Alpha; }

::like scalar do {eval { Omega1->new }; $@}, qr{Requires abc of Role::Alpha}, 'eval { Omega1->new }; $@ # ~> Requires abc of Role::Alpha';

package Omega { use Aion;
	with Role::Alpha;

	sub abc { "abc" }
}

::is scalar do {Omega->new->abc}, "abc", 'Omega->new->abc  # => abc';

# 
# ## req ($name => @aspects)
# 
# Проверяет, что в классах, использующих эту роль, есть указанные фичи с указанными аспектами.
# 
::done_testing; }; subtest 'req ($name => @aspects)' => sub { 
package Role::Beta { use Aion -role;

	req x => (is => 'rw', isa => Num);
}

package Omega2 { use Aion; with Role::Beta; }

::like scalar do {eval { Omega2->new }; $@}, qr{Requires req x => \(is => 'rw', isa => Num\) of Role::Beta}, 'eval { Omega2->new }; $@ # ~> Requires req x => \(is => \'rw\', isa => Num\) of Role::Beta';

package Omega3 { use Aion;
	with Role::Beta;

	has x => (is => 'rw', isa => Num, default => 12);
}

::is scalar do {Omega3->new->x}, scalar do{12}, 'Omega3->new->x  # -> 12';

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
# * `?` – создать предикат.
# * `!` – создать clearer.
# 
::done_testing; }; subtest 'is => $permissions' => sub { 
package ExIs { use Aion;
	has rw => (is => 'rw?!');
	has ro => (is => 'ro+');
	has wo => (is => 'wo-?');
}

eval {ExIs->new}; ok defined($@), 'ExIs->new # @-> ro required!'; ::cmp_ok $@, '=~', '^' . quotemeta 'ro required!', 'ExIs->new # @-> ro required!';
eval {ExIs->new(ro => 10, wo => -10)}; ok defined($@), 'ExIs->new(ro => 10, wo => -10) # @-> wo excessive!'; ::cmp_ok $@, '=~', '^' . quotemeta 'wo excessive!', 'ExIs->new(ro => 10, wo => -10) # @-> wo excessive!';

::is scalar do {ExIs->new(ro => 10)->has_rw}, scalar do{""}, 'ExIs->new(ro => 10)->has_rw # -> ""';
::is scalar do {ExIs->new(ro => 10, rw => 20)->has_rw}, scalar do{1}, 'ExIs->new(ro => 10, rw => 20)->has_rw # -> 1';
::is scalar do {ExIs->new(ro => 10, rw => 20)->clear_rw->has_rw}, scalar do{""}, 'ExIs->new(ro => 10, rw => 20)->clear_rw->has_rw # -> ""';

::is scalar do {ExIs->new(ro => 10)->ro}, scalar do{10}, 'ExIs->new(ro => 10)->ro  # -> 10';

::is scalar do {ExIs->new(ro => 10)->wo(30)->has_wo}, scalar do{1}, 'ExIs->new(ro => 10)->wo(30)->has_wo # -> 1';
eval {ExIs->new(ro => 10)->wo}; ok defined($@), 'ExIs->new(ro => 10)->wo # @-> Feature wo cannot be get!'; ::cmp_ok $@, '=~', '^' . quotemeta 'Feature wo cannot be get!', 'ExIs->new(ro => 10)->wo # @-> Feature wo cannot be get!';
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
::done_testing; }; subtest 'isa => $type' => sub { 
package ExIsa { use Aion;
	has x => (is => 'ro', isa => Int);
}

eval {ExIsa->new(x => 'str')}; ok defined($@), 'ExIsa->new(x => \'str\') # @-> Set feature x must have the type Int. The it is \'str\'!'; ::cmp_ok $@, '=~', '^' . quotemeta 'Set feature x must have the type Int. The it is \'str\'!', 'ExIsa->new(x => \'str\') # @-> Set feature x must have the type Int. The it is \'str\'!';
eval {ExIsa->new->x}; ok defined($@), 'ExIsa->new->x # @-> Get feature x must have the type Int. The it is undef!'; ::cmp_ok $@, '=~', '^' . quotemeta 'Get feature x must have the type Int. The it is undef!', 'ExIsa->new->x # @-> Get feature x must have the type Int. The it is undef!';
::is scalar do {ExIsa->new(x => 10)->x}, scalar do{10}, 'ExIsa->new(x => 10)->x			  # -> 10';

# 
# Список валидаторов см. в [Aion::Types](https://metacpan.org/pod/Aion::Types).
# 
# ## coerce => (1|0)
# 
# Включает преобразования типов.
# 
::done_testing; }; subtest 'coerce => (1|0)' => sub { 
package ExCoerce { use Aion;
	has x => (is => 'ro', isa => Int, coerce => 1);
}

::is scalar do {ExCoerce->new(x => 10.4)->x}, scalar do{10}, 'ExCoerce->new(x => 10.4)->x  # -> 10';
::is scalar do {ExCoerce->new(x => 10.5)->x}, scalar do{11}, 'ExCoerce->new(x => 10.5)->x  # -> 11';

# 
# ## default => $value
# 
# Значение по умолчанию устанавливается в конструкторе, если параметр с именем фичи отсутствует.
# 
::done_testing; }; subtest 'default => $value' => sub { 
package ExDefault { use Aion;
	has x => (is => 'ro', default => 10);
}

::is scalar do {ExDefault->new->x}, scalar do{10}, 'ExDefault->new->x  # -> 10';
::is scalar do {ExDefault->new(x => 20)->x}, scalar do{20}, 'ExDefault->new(x => 20)->x  # -> 20';

# 
# Если `$value` является подпрограммой, то подпрограмма считается конструктором значения фичи. Используется ленивое вычисление, если нет атрибута `lazy`.
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
# ## lazy => (1|0)
# 
# Атрибут `lazy` включает или отключает ленивое вычисление значения по умолчанию (`default`).
# 
# По умолчанию он включен только если значение по умолчанию является подпрограммой.
# 
::done_testing; }; subtest 'lazy => (1|0)' => sub { 
package ExLazy0 { use Aion;
	has x => (is => 'ro?', lazy => 0, default => sub { 5 });
}

my $ex0 = ExLazy0->new;
::is scalar do {$ex0->has_x}, scalar do{1}, '$ex0->has_x # -> 1';
::is scalar do {$ex0->x}, scalar do{5}, '$ex0->x     # -> 5';

package ExLazy1 { use Aion;
	has x => (is => 'ro?', lazy => 1, default => 6);
}

my $ex1 = ExLazy1->new;
::is scalar do {$ex1->has_x}, scalar do{""}, '$ex1->has_x # -> ""';
::is scalar do {$ex1->x}, scalar do{6}, '$ex1->x     # -> 6';

# 
# ## trigger => $sub
# 
# `$sub` вызывается после установки свойства в конструкторе (`new`) или через сеттер.
# Этимология – впустить.
# 
::done_testing; }; subtest 'trigger => $sub' => sub { 
package ExTrigger { use Aion;
	has x => (trigger => sub {
		my ($self, $old_value) = @_;
		$self->y($old_value + $self->x);
	});

	has y => ();
}

my $ex = ExTrigger->new(x => 10);
::is scalar do {$ex->y}, scalar do{10}, '$ex->y	  # -> 10';
$ex->x(20);
::is scalar do {$ex->y}, scalar do{30}, '$ex->y	  # -> 30';

# 
# ## release => $sub
# 
# `$sub` вызывается перед возвратом свойства из объекта через геттер.
# Этимология – выпустить.
# 
::done_testing; }; subtest 'release => $sub' => sub { 
package ExRelease { use Aion;
	has x => (release => sub {
		my ($self, $value) = @_;
		$_[1] = $value + 1;
	});
}

my $ex = ExRelease->new(x => 10);
::is scalar do {$ex->x}, scalar do{11}, '$ex->x	  # -> 11';

# 
# ## init_arg => $name
# 
# Меняет имя свойства в конструкторе.
# 
::done_testing; }; subtest 'init_arg => $name' => sub { 
package ExInitArg { use Aion;
	has x => (is => 'ro+', init_arg => 'init_x');

::is scalar do {ExInitArg->new(init_x => 10)->x}, scalar do{10}, '	ExInitArg->new(init_x => 10)->x # -> 10';
}

# 
# ## accessor => $name
# 
# Меняет имя акцессора.
# 
::done_testing; }; subtest 'accessor => $name' => sub { 
package ExAccessor { use Aion;
	has x => (is => 'rw', accessor => '_x');

::is scalar do {ExAccessor->new->_x(10)->_x}, scalar do{10}, '	ExAccessor->new->_x(10)->_x # -> 10';
}

# 
# ## writer => $name
# 
# Создаёт сеттер с именем `$name` для свойства.
# 
::done_testing; }; subtest 'writer => $name' => sub { 
package ExWriter { use Aion;
	has x => (is => 'ro', writer => '_set_x');

::is scalar do {ExWriter->new->_set_x(10)->x}, scalar do{10}, '	ExWriter->new->_set_x(10)->x # -> 10';
}

# 
# ## reader => $name
# 
# Создаёт геттер с именем `$name` для свойства.
# 
::done_testing; }; subtest 'reader => $name' => sub { 
package ExReader { use Aion;
	has x => (is => 'wo', reader => '_get_x');

::is scalar do {ExReader->new(x => 10)->_get_x}, scalar do{10}, '	ExReader->new(x => 10)->_get_x # -> 10';
}

# 
# ## predicate => $name
# 
# Создаёт предикат с именем `$name` для свойства. Создать предикат со стандартным именем можно так же через  `is => '?'`.
# 
::done_testing; }; subtest 'predicate => $name' => sub { 
package ExPredicate { use Aion;
	has x => (predicate => '_has_x');
	
	my $ex = ExPredicate->new;
::is scalar do {$ex->_has_x}, scalar do{""}, '	$ex->_has_x        # -> ""';
::is scalar do {$ex->x(10)->_has_x}, scalar do{1}, '	$ex->x(10)->_has_x # -> 1';
}

# 
# ## clearer => $name
# 
# Создаёт очиститель с именем `$name` для свойства. Создать очиститель со стандартным именем можно так же через  `is => '!'`.
# 
::done_testing; }; subtest 'clearer => $name' => sub { 
package ExClearer { use Aion;
	has x => (is => '?', clearer => 'clear_x_');
}

my $ex = ExClearer->new;
::is scalar do {$ex->has_x}, scalar do{""}, '$ex->has_x	  # -> ""';
$ex->clear_x_;
::is scalar do {$ex->has_x}, scalar do{""}, '$ex->has_x	  # -> ""';
$ex->x(10);
::is scalar do {$ex->has_x}, scalar do{1}, '$ex->has_x	  # -> 1';
$ex->clear_x_;
::is scalar do {$ex->has_x}, scalar do{""}, '$ex->has_x	  # -> ""';

# 
# ## cleaner => $sub
# 
# `$sub` вызывается при вызове декструктора или `$object->clear_feature`, но только если свойство имеется (см. `$object->has_feature`).
# 
# Данный аспект принудительно создаёт предикат и clearer.
# 
::done_testing; }; subtest 'cleaner => $sub' => sub { 
package ExCleaner { use Aion;

	our $x;

	has x => (is => '!', cleaner => sub {
		my ($self) = @_;
		$x = $self->x
	});
}

::is scalar do {$ExCleaner::x}, scalar do{undef}, '$ExCleaner::x		  # -> undef';
ExCleaner->new(x => 10);
::is scalar do {$ExCleaner::x}, scalar do{10}, '$ExCleaner::x		  # -> 10';

my $ex = ExCleaner->new(x => 12);

::is scalar do {$ExCleaner::x}, scalar do{10}, '$ExCleaner::x	  # -> 10';
$ex->clear_x;
::is scalar do {$ExCleaner::x}, scalar do{12}, '$ExCleaner::x	  # -> 12';

undef $ex;

::is scalar do {$ExCleaner::x}, scalar do{12}, '$ExCleaner::x	  # -> 12';

# 
# # ATTRIBUTES
# 
# `Aion` добавляет в пакет универсальные атрибуты.
# 
# ## :Isa (@signature)
# 
# Атрибут `Isa` проверяет сигнатуру функции.
# 
::done_testing; }; subtest ':Isa (@signature)' => sub { 
package MaybeCat { use Aion;

	sub is_cat : Isa(Me => Str => Bool) {
		my ($self, $anim) = @_;
		$anim =~ /(cat)/
	}
}

my $anim = MaybeCat->new;
::is scalar do {$anim->is_cat('cat')}, scalar do{1}, '$anim->is_cat(\'cat\')	# -> 1';
::is scalar do {$anim->is_cat('dog')}, scalar do{""}, '$anim->is_cat(\'dog\')	# -> ""';

eval {MaybeCat->is_cat("cat")}; ok defined($@), 'MaybeCat->is_cat("cat") # @-> Arguments of method `is_cat` must have the type Tuple[Me, Str].'; ::cmp_ok $@, '=~', '^' . quotemeta 'Arguments of method `is_cat` must have the type Tuple[Me, Str].', 'MaybeCat->is_cat("cat") # @-> Arguments of method `is_cat` must have the type Tuple[Me, Str].';
eval {my @items = $anim->is_cat("cat")}; ok defined($@), 'my @items = $anim->is_cat("cat") # @-> Returns of method `is_cat` must have the type Tuple[Bool].'; ::cmp_ok $@, '=~', '^' . quotemeta 'Returns of method `is_cat` must have the type Tuple[Bool].', 'my @items = $anim->is_cat("cat") # @-> Returns of method `is_cat` must have the type Tuple[Bool].';

# 
# Атрибут Isa позволяет объявить требуемые функции:
# 

package Anim { use Aion -role;

	sub is_cat : Isa(Me => Bool);
}

package Cat { use Aion; with qw/Anim/;

	sub is_cat : Isa(Me => Bool) { 1 }
}

package Dog { use Aion; with qw/Anim/;

	sub is_cat : Isa(Me => Bool) { 0 }
}

package Mouse { use Aion; with qw/Anim/;
	
	sub is_cat : Isa(Me => Int) { 0 }
}

::is scalar do {Cat->new->is_cat}, scalar do{1}, 'Cat->new->is_cat # -> 1';
::is scalar do {Dog->new->is_cat}, scalar do{0}, 'Dog->new->is_cat # -> 0';
eval {Mouse->new}; ok defined($@), 'Mouse->new # @-> Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse'; ::cmp_ok $@, '=~', '^' . quotemeta 'Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse', 'Mouse->new # @-> Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse';

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

	::done_testing;
};

::done_testing;
