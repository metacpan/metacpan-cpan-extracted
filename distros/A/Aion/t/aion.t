use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-1]); 	my $project_name = $dirs[$#dirs-1]; 	my @test_dirs = @dirs[$#dirs-1+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion - постмодернистская объектная система для Perl 5, такая как «Mouse», «Moose», «Moo», «Mo» и «M», но с улучшениями
# 
# # VERSION
# 
# 1.3
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

local ($::_g0 = do {Calc->new(a => 1.1, b => 2)->result}, $::_e0 = "3.1"); ::ok $::_g0 eq $::_e0, 'Calc->new(a => 1.1, b => 2)->result   # => 3.1' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {$cat->type}, $::_e0 = "cat"); ::ok $::_g0 eq $::_e0, '$cat->type   # => cat' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$cat->name}, $::_e0 = "murka"); ::ok $::_g0 eq $::_e0, '$cat->name   # => murka' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

$cat->name("murzik");
local ($::_g0 = do {$cat->name}, $::_e0 = "murzik"); ::ok $::_g0 eq $::_e0, '$cat->name   # => murzik' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {$s->keysify}, $::_e0 = "key1, key2"); ::ok $::_g0 eq $::_e0, '$s->keysify	 # => key1, key2' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$s->valsify}, $::_e0 = "a, b"); ::ok $::_g0 eq $::_e0, '$s->valsify	 # => a, b' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## exactly ($package)
# 
# Проверяет, что `$package` — это суперкласс для данного или сам этот класс.
# 
# Реализацию метода `isa` Aion не меняет и она находит как суперклассы, так и роли (так как и те и другие добавляются в `@ISA` пакета).
# 
::done_testing; }; subtest 'exactly ($package)' => sub { 
package Ex::X { use Aion; }
package Ex::A { use Aion; extends q/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

local ($::_g0 = do {Ex::C->exactly("Ex::A")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::C->exactly("Ex::A") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::C->exactly("Ex::B")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::C->exactly("Ex::B") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::C->exactly("Ex::X")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::C->exactly("Ex::X") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::C->exactly("Ex::X1")}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::C->exactly("Ex::X1") # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::A->exactly("Ex::X")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::A->exactly("Ex::X") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::A->exactly("Ex::A")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::A->exactly("Ex::A") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::X->exactly("Ex::X")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::X->exactly("Ex::X") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {Ex::Z->does("Role::A")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::Z->does("Role::A") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::Z->does("Role::B")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::Z->does("Role::B") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::Z->does("Role::X")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::Z->does("Role::X") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Role::A->does("Role::X")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Role::A->does("Role::X") # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Role::A->does("Role::X1")}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Role::A->does("Role::X1") # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Ex::Z->does("Ex::Z")}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Ex::Z->does("Ex::Z") # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {$earth->moon}, $::_e0 = "Mars"); ::ok $::_g0 eq $::_e0, '$earth->moon # => Mars' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {$value}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '		$value # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$aspect_name}, $::_e0 = "lvalue"); ::ok $::_g0 eq $::_e0, '		$aspect_name # => lvalue' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {$class}, $::_e0 = "World"); ::ok $::_g0 eq $::_e0, '		$class   # => World' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$extends}, $::_e0 = "Hello"); ::ok $::_g0 eq $::_e0, '		$extends # => Hello' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
	}
}

package Hello { use Aion;
	extends q/World/;

local ($::_g0 = do {$World::extended_by_this}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	$World::extended_by_this # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

local ($::_g0 = do {Hello->isa("World")}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Hello->isa("World")	 # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

eval {NewExample->new(f => 5)}; local ($::_g0 = $@, $::_e0 = 'y required!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'NewExample->new(f => 5) # @-> y required!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {NewExample->new(f => 5, y => 10)}; local ($::_g0 = $@, $::_e0 = 'f is\'nt feature!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'NewExample->new(f => 5, y => 10) # @-> f is\'nt feature!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {NewExample->new(f => 5, p => 6, y => 10)}; local ($::_g0 = $@, $::_e0 = 'f, p is\'nt features!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'NewExample->new(f => 5, p => 6, y => 10) # @-> f, p is\'nt features!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {NewExample->new(z => 10, y => 10)}; local ($::_g0 = $@, $::_e0 = 'z excessive!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'NewExample->new(z => 10, y => 10) # @-> z excessive!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

my $ex = NewExample->new(y => 8);

eval {$ex->x}; local ($::_g0 = $@, $::_e0 = 'Get feature x must have the type Num. The it is undef!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$ex->x # @-> Get feature x must have the type Num. The it is undef!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

$ex = NewExample->new(x => 10.1, y => 8);

local ($::_g0 = do {$ex->x}, $::_e0 = do {10.1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->x # -> 10.1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

::like scalar do {eval { Omega1->new }; $@}, qr{Requires abc of Role::Alpha}, 'eval { Omega1->new }; $@ # ~> Requires abc of Role::Alpha'; undef $::_g0; undef $::_e0;

package Omega { use Aion;
	with Role::Alpha;

	sub abc { "abc" }
}

local ($::_g0 = do {Omega->new->abc}, $::_e0 = "abc"); ::ok $::_g0 eq $::_e0, 'Omega->new->abc  # => abc' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

::like scalar do {eval { Omega2->new }; $@}, qr{Requires req x => \(is => 'rw', isa => Num\) of Role::Beta}, 'eval { Omega2->new }; $@ # ~> Requires req x => \(is => \'rw\', isa => Num\) of Role::Beta'; undef $::_g0; undef $::_e0;

package Omega3 { use Aion;
	with Role::Beta;

	has x => (is => 'rw', isa => Num, default => 12);
}

local ($::_g0 = do {Omega3->new->x}, $::_e0 = do {12}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Omega3->new->x  # -> 12' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

eval {ExIs->new}; local ($::_g0 = $@, $::_e0 = 'ro required!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'ExIs->new # @-> ro required!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {ExIs->new(ro => 10, wo => -10)}; local ($::_g0 = $@, $::_e0 = 'wo excessive!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'ExIs->new(ro => 10, wo => -10) # @-> wo excessive!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

local ($::_g0 = do {ExIs->new(ro => 10)->has_rw}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIs->new(ro => 10)->has_rw # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ExIs->new(ro => 10, rw => 20)->has_rw}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIs->new(ro => 10, rw => 20)->has_rw # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ExIs->new(ro => 10, rw => 20)->clear_rw->has_rw}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIs->new(ro => 10, rw => 20)->clear_rw->has_rw # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {ExIs->new(ro => 10)->ro}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIs->new(ro => 10)->ro  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {ExIs->new(ro => 10)->wo(30)->has_wo}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIs->new(ro => 10)->wo(30)->has_wo # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
eval {ExIs->new(ro => 10)->wo}; local ($::_g0 = $@, $::_e0 = 'Feature wo cannot be get!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'ExIs->new(ro => 10)->wo # @-> Feature wo cannot be get!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ExIs->new(ro => 10)->rw(30)->rw}, $::_e0 = do {30}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIs->new(ro => 10)->rw(30)->rw  # -> 30' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Функция с `*` не удерживает значение:
# 

package Node { use Aion;
	has parent => (is => "rw*", isa => Maybe[Object["Node"]]);
}

my $root = Node->new;
my $node = Node->new(parent => $root);

local ($::_g0 = do {$node->parent->parent}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$node->parent->parent   # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
undef $root;
local ($::_g0 = do {$node->parent}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$node->parent   # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# And by setter:
$node->parent($root = Node->new);

local ($::_g0 = do {$node->parent->parent}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$node->parent->parent   # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
undef $root;
local ($::_g0 = do {$node->parent}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$node->parent   # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## isa => $type
# 
# Указывает тип, а точнее – валидатор, фичи.
# 
::done_testing; }; subtest 'isa => $type' => sub { 
package ExIsa { use Aion;
	has x => (is => 'ro', isa => Int);
}

eval {ExIsa->new(x => 'str')}; local ($::_g0 = $@, $::_e0 = 'Set feature x must have the type Int. The it is \'str\'!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'ExIsa->new(x => \'str\') # @-> Set feature x must have the type Int. The it is \'str\'!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {ExIsa->new->x}; local ($::_g0 = $@, $::_e0 = 'Get feature x must have the type Int. The it is undef!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'ExIsa->new->x # @-> Get feature x must have the type Int. The it is undef!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ExIsa->new(x => 10)->x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExIsa->new(x => 10)->x			  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {ExCoerce->new(x => 10.4)->x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExCoerce->new(x => 10.4)->x  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ExCoerce->new(x => 10.5)->x}, $::_e0 = do {11}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExCoerce->new(x => 10.5)->x  # -> 11' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## default => $value
# 
# Значение по умолчанию устанавливается в конструкторе, если параметр с именем фичи отсутствует.
# 
::done_testing; }; subtest 'default => $value' => sub { 
package ExDefault { use Aion;
	has x => (is => 'ro', default => 10);
}

local ($::_g0 = do {ExDefault->new->x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExDefault->new->x  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ExDefault->new(x => 20)->x}, $::_e0 = do {20}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ExDefault->new(x => 20)->x  # -> 20' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
local ($::_g0 = do {$count}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$count   # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->x}, $::_e0 = do {11}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->x   # -> 11' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$count}, $::_e0 = do {11}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$count   # -> 11' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->x}, $::_e0 = do {11}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->x   # -> 11' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$count}, $::_e0 = do {11}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$count   # -> 11' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## lazy => (1|0)
# 
# Аспект `lazy` включает или отключает ленивое вычисление значения по умолчанию (`default`).
# 
# По умолчанию он включен только если значение по умолчанию является подпрограммой.
# 
::done_testing; }; subtest 'lazy => (1|0)' => sub { 
package ExLazy0 { use Aion;
	has x => (is => 'ro?', lazy => 0, default => sub { 5 });
}

my $ex0 = ExLazy0->new;
local ($::_g0 = do {$ex0->has_x}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex0->has_x # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex0->x}, $::_e0 = do {5}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex0->x     # -> 5' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

package ExLazy1 { use Aion;
	has x => (is => 'ro?', lazy => 1, default => 6);
}

my $ex1 = ExLazy1->new;
local ($::_g0 = do {$ex1->has_x}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex1->has_x # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex1->x}, $::_e0 = do {6}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex1->x     # -> 6' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## eon => (1|2|$key)
# 
# С помощью аспекта `eon` реализуется паттерн **Dependency Injection**.
# 
# Он связывает свойство с сервисом из контейнера `$Aion::pleroma`.
# 
# Значением аспекта может быть ключ сервиса, 1 или 2.
# 
# * Если 1 – тогда ключём будет пакет в `isa => Object['Packet']`.
# * Если 2 – тогда ключём будет "пакет#свойство".
# 
# Файл lib/CounterEon.pm:
#@> lib/CounterEon.pm
#>> package CounterEon;
#>> #@eon ex.counter
#>> use Aion;
#>> 
#>> has accomulator => (isa => Object['AccomulatorEon'], eon => 1);
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/AccomulatorEon.pm:
#@> lib/AccomulatorEon.pm
#>> package AccomulatorEon;
#>> #@eon
#>> use Aion;
#>> 
#>> has power => (isa => Object['PowerEon'], eon => 2);
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/PowerEon.pm:
#@> lib/PowerEon.pm
#>> package PowerEon;
#>> use Aion;
#>> 
#>> has counter => (eon => 'ex.counter');
#>> 	
#>> #@eon
#>> sub power { shift->new }
#>> 
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'eon => (1|2|$key)' => sub { 
{
	use Aion::Pleroma;
	local $Aion::pleroma = Aion::Pleroma->new(ini => undef, pleroma => {
		'ex.counter' => 'CounterEon#new',
		AccomulatorEon => 'AccomulatorEon#new',
		'PowerEon#power' => 'PowerEon#power',
	});
	
	my $counter = $Aion::pleroma->get('ex.counter');

local ($::_g0 = do {$counter->accomulator->power->counter}, $::_e0 = do {$counter}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	$counter->accomulator->power->counter # -> $counter' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

# 
# См. [Aion::Pleroma](https://metacpan.org/pod/Aion::Pleroma).
# 
# ## trigger => $sub
# 
# `$sub` вызывается после установки свойства в конструкторе (`new`) или через сеттер.
# 
# Этимология `trigger` – впустить.
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
local ($::_g0 = do {$ex->y}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->y	  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
$ex->x(20);
local ($::_g0 = do {$ex->y}, $::_e0 = do {30}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->y	  # -> 30' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## release => $sub
# 
# `$sub` вызывается перед возвратом свойства из объекта через геттер.
# 
# Этимология `release` – выпустить.
# 
::done_testing; }; subtest 'release => $sub' => sub { 
package ExRelease { use Aion;
	has x => (release => sub {
		my ($self, $value) = @_;
		$_[1] = $value + 1;
	});
}

my $ex = ExRelease->new(x => 10);
local ($::_g0 = do {$ex->x}, $::_e0 = do {11}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->x	  # -> 11' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## init_arg => $name
# 
# Меняет имя свойства в конструкторе.
# 
::done_testing; }; subtest 'init_arg => $name' => sub { 
package ExInitArg { use Aion;
	has x => (is => 'ro+', init_arg => 'init_x');

local ($::_g0 = do {ExInitArg->new(init_x => 10)->x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	ExInitArg->new(init_x => 10)->x # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

# 
# ## accessor => $name
# 
# Меняет имя акцессора.
# 
::done_testing; }; subtest 'accessor => $name' => sub { 
package ExAccessor { use Aion;
	has x => (is => 'rw', accessor => '_x');

local ($::_g0 = do {ExAccessor->new->_x(10)->_x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	ExAccessor->new->_x(10)->_x # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

# 
# ## writer => $name
# 
# Создаёт сеттер с именем `$name` для свойства.
# 
::done_testing; }; subtest 'writer => $name' => sub { 
package ExWriter { use Aion;
	has x => (is => 'ro', writer => '_set_x');

local ($::_g0 = do {ExWriter->new->_set_x(10)->x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	ExWriter->new->_set_x(10)->x # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
}

# 
# ## reader => $name
# 
# Создаёт геттер с именем `$name` для свойства.
# 
::done_testing; }; subtest 'reader => $name' => sub { 
package ExReader { use Aion;
	has x => (is => 'wo', reader => '_get_x');

local ($::_g0 = do {ExReader->new(x => 10)->_get_x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	ExReader->new(x => 10)->_get_x # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$ex->_has_x}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	$ex->_has_x        # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ex->x(10)->_has_x}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '	$ex->x(10)->_has_x # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$ex->has_x}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->has_x	  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
$ex->clear_x_;
local ($::_g0 = do {$ex->has_x}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->has_x	  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
$ex->x(10);
local ($::_g0 = do {$ex->has_x}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->has_x	  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
$ex->clear_x_;
local ($::_g0 = do {$ex->has_x}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ex->has_x	  # -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {$ExCleaner::x}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ExCleaner::x		  # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
ExCleaner->new(x => 10);
local ($::_g0 = do {$ExCleaner::x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ExCleaner::x		  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $ex = ExCleaner->new(x => 12);

local ($::_g0 = do {$ExCleaner::x}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ExCleaner::x	  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
$ex->clear_x;
local ($::_g0 = do {$ExCleaner::x}, $::_e0 = do {12}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ExCleaner::x	  # -> 12' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

undef $ex;

local ($::_g0 = do {$ExCleaner::x}, $::_e0 = do {12}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ExCleaner::x	  # -> 12' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
local ($::_g0 = do {$anim->is_cat('cat')}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$anim->is_cat(\'cat\')	# -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$anim->is_cat('dog')}, $::_e0 = do {""}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$anim->is_cat(\'dog\')	# -> ""' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

eval {MaybeCat->is_cat("cat")}; local ($::_g0 = $@, $::_e0 = 'Arguments of method `is_cat` must have the type Tuple[Me, Str].'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'MaybeCat->is_cat("cat") # @-> Arguments of method `is_cat` must have the type Tuple[Me, Str].' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
eval {my @items = $anim->is_cat("cat")}; local ($::_g0 = $@, $::_e0 = 'Returns of method `is_cat` must have the type Tuple[Bool].'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'my @items = $anim->is_cat("cat") # @-> Returns of method `is_cat` must have the type Tuple[Bool].' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

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

local ($::_g0 = do {Cat->new->is_cat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Cat->new->is_cat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {Dog->new->is_cat}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'Dog->new->is_cat # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
eval {Mouse->new}; local ($::_g0 = $@, $::_e0 = 'Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'Mouse->new # @-> Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

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
