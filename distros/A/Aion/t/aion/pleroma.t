use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Pleroma - контейнер эонов
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Pleroma;

my $pleroma = Aion::Pleroma->new;

local ($::_g0 = do {$pleroma->get('user')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$pleroma->get(\'user\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
eval {$pleroma->resolve('user')}; local ($::_g0 = $@, $::_e0 = 'user is\'nt eon!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$pleroma->resolve(\'user\') # @-> user is\'nt eon!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Реализует паттерн контейнера зависимостей.
# 
# Эон создаётся при запросе из контейнера через метод `get` или `resolve`, либо через аспект `eon` как ленивый `default`. Ленивость можно отменить через аспект `lazy`.
# 
# Контейнер можно получить с помощью `Aion->pleroma`.
# 
# Конфигурацию для создания эонов получает из конфига `PLEROMA` и файла аннотаций (создаётся пакетом `Aion::Annotation`). Файл аннотаций можно заменить через конфиг `INI`.
# 
# # CONFIG
# 
# Настройки модуля, которые можно установить в `.env`:
# 
# * AION_PLEROMA_INI – файл аннотаций. По умолчанию `etc/annotation/eon.ann`.
# * AION_PLEROMA_AUTOWARE – подгружать модули автоматически, даже если они не прописаны в конфигурации. По умолчанию `1`.
# 
# # EONS FROM CONFIG
# 
# В `etc/*.yml` можно добавить ключ `aion.eon` с описанием дополнительных эонов. Это позволяет собирать эоны декларативно: задавать аргументы конструктора (именованные или упорядоченные), вызывать методы после создания и передавать ссылки на другие эоны через `@`.
# 
# Опишем классы эонов.
# 
# Файл lib/Ex/Eon/Astronomer.pm:
#@> lib/Ex/Eon/Astronomer.pm
#>> package Ex::Eon::Astronomer;
#>> use strict; use warnings;
#>> 
#>> sub new { my ($class, $name, $telescope) = @_; bless { name => $name, telescope => $telescope, seen => [] }, $class }
#>> sub name      { $_[0]{name} }
#>> sub telescope { $_[0]{telescope} }
#>> sub seen      { $_[0]{seen} }
#>> sub observe   {
#>> 	my ($self, $body) = @_;
#>> 	die "body is'nt Planet!" unless $body && $body->isa('Ex::Eon::Planet');
#>> 	push @{ $self->{seen} }, $body;
#>> 	$body
#>> }
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/Ex/Eon/Planet.pm:
#@> lib/Ex/Eon/Planet.pm
#>> package Ex::Eon::Planet;
#>> use common::sense;
#>> use Aion;
#>> 
#>> has name       => (is => 'ro');
#>> has moons      => (is => 'ro', default => 0);
#>> has discoverer => (is => 'ro');
#>> 
#>> 1;
#@< EOF
# 
# Теперь конфигурация эонов. У эона-учёного `Ex::Eon::Galileo` аргументы заданы упорядоченно (`arguments` – массив), после создания вызывается метод `observe` со ссылкой на другой эон (`@Ex::Eon::Saturn`). У планет `arguments` – хеш, а аргумент `discoverer` ссылается (`@`) на эон учёного.
# 
# Файл etc/aion/include.yml:
#@> etc/aion/include.yml
#>> aion:
#>>   eon:
#>>     Ex::Eon::Jupiter:
#>>       class: 'Ex::Eon::Planet'
#>>       arguments:
#>>         name: 'Jupiter'
#>>         moons: 95
#>>         discoverer: '@Ex::Eon::Galileo'
#>>     Ex::Eon::Saturn:
#>>       class: 'Ex::Eon::Planet'
#>>       arguments:
#>>         name: 'Saturn'
#>>         moons: 146
#>>     Ex::Eon::Galileo:
#>>       class: 'Ex::Eon::Astronomer'
#>>       arguments: [ 'Galileo Galilei', 'refracting telescope' ]
#>>       calls:
#>>         - [observe, '@Ex::Eon::Saturn']
#@< EOF
# 
# В конфигурации эон `Ex::Eon::Jupiter` описан раньше, чем `Ex::Eon::Galileo` (на которого он ссылается через `@`). Порядок описания не важен: эоны порождаются лениво при запросе, поэтому `@`-ссылка разрешается уже на готовый эон.
# 
# Прочитаем конфигурацию из `etc/aion/include.yml` и передадим её контейнеру.
# 
::done_testing; }; subtest 'EONS FROM CONFIG' => sub { 
use Aion::Pleroma;
use Aion::Env::Etc ();

my $etc = Aion::Env::Etc::parse('etc/aion/include.yml');
my $pleroma = Aion::Pleroma->new(pleroma => $etc->{aion}{eon});

my $jupiter = $pleroma->resolve('Ex::Eon::Jupiter');
local ($::_g0 = do {$jupiter->name}, $::_e0 = "Jupiter"); ::ok $::_g0 eq $::_e0, '$jupiter->name    # => Jupiter' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$jupiter->moons}, $::_e0 = "95"); ::ok $::_g0 eq $::_e0, '$jupiter->moons   # => 95' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$jupiter->discoverer->name}, $::_e0 = "Galileo Galilei"); ::ok $::_g0 eq $::_e0, '$jupiter->discoverer->name # => Galileo Galilei' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ref($jupiter->discoverer)}, $::_e0 = "Ex::Eon::Astronomer"); ::ok $::_g0 eq $::_e0, 'ref($jupiter->discoverer)  # => Ex::Eon::Astronomer' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $galileo = $pleroma->resolve('Ex::Eon::Galileo');
local ($::_g0 = do {$galileo->name}, $::_e0 = "Galileo Galilei"); ::ok $::_g0 eq $::_e0, '$galileo->name  # => Galileo Galilei' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$galileo->telescope}, $::_e0 = "refracting telescope"); ::ok $::_g0 eq $::_e0, '$galileo->telescope  # => refracting telescope' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {ref($galileo->seen->[0])}, $::_e0 = "Ex::Eon::Planet"); ::ok $::_g0 eq $::_e0, 'ref($galileo->seen->[0])  # => Ex::Eon::Planet' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$galileo->seen->[0]->name}, $::_e0 = "Saturn"); ::ok $::_g0 eq $::_e0, '$galileo->seen->[0]->name # => Saturn' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Круговая зависимость
# 
# Если эоны ссылаются друг на друга, то контейнер не сможет их породить. Цикл вычисляется уже при добавлении эона (`autoware`) — на этапе сборки конфигурации — и выбрасывается исключение с цепочкой ссылок.
# 
::done_testing; }; subtest 'Круговая зависимость' => sub { 
my $cnt = Aion::Pleroma->new;
$cnt->autoware({ class => 'Ex::Eon::Galileo', arguments => [ 'Galileo Galilei', 'refracting telescope' ], calls => [[ 'observe', '@Ex::Eon::Jupiter' ]] }, 'Ex::Eon::Galileo');
eval {$cnt->autoware({ class => 'Ex::Eon::Planet', arguments => { name => 'Jupiter', moons => 95, discoverer => '@Ex::Eon::Galileo' } }, 'Ex::Eon::Jupiter')}; local ($::_g0 = $@, $::_e0 = qr{Circular eon dependency: .+Ex::Eon::Jupiter}); ok defined($::_g0) && $::_g0 =~ $::_e0, '$cnt->autoware({ class => \'Ex::Eon::Planet\', arguments => { name => \'Jupiter\', moons => 95, discoverer => \'@Ex::Eon::Galileo\' } }, \'Ex::Eon::Jupiter\') # @~> Circular eon dependency: .+Ex::Eon::Jupiter' or ::diag defined($::_g0)? "Got:$::_g0": 'Got is undef'; undef $::_g0; undef $::_e0;

# 
# ## Eon description keys
# 
# Каждый эон в `aion.eon` описывается строкой или хешем.
# 
# Строка задаёт конструктор `'класс#метод'` (или просто `'класс'`), метод по умолчанию – `new`. Так создаются самые простые эоны без аргументов.
# 
# Хеш может содержать ключи:
# 
# * `class` – класс (пакет) эона. Если не указан и ключ эона похож на имя класса (`/^[\w:]+$/`), используется сам ключ.
# * `method` – метод класса-конструктора. По умолчанию `new`.
# * `arguments` – аргументы конструктора:
#   * хеш – именованные аргументы (`new => %hash`);
#   * массив – упорядоченные аргументы (`new => @array`).
# * `calls` – список вызовов методов после создания эона. Каждый вызов – имя метода (без аргументов) или массив `[имя_метода, аргументы...]`.
# 
# Значение аргумента (или элемента вызова), начинающееся с `@`, воспринимается как ссылка на другой эон: `@ключ` заменяется порождённым эоном из контейнера.
# 
# # FEATURES
# 
# ## ini
# 
# Файл с аннотациями.
# 
::done_testing; }; subtest 'ini' => sub { 
local ($::_g0 = do {Aion::Pleroma->new->ini}, $::_e0 = "etc/annotation/eon.ann"); ::ok $::_g0 eq $::_e0, 'Aion::Pleroma->new->ini # => etc/annotation/eon.ann' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## pleroma
# 
# Конфигурация: ключ => 'класс#метод_класса'.
# 
# Файл lib/Ex/Eon/AnimalEon.pm:
#@> lib/Ex/Eon/AnimalEon.pm
#>> package Ex::Eon::AnimalEon;
#>> #@eon
#>> 
#>> use common::sense;
#>> 
#>> use Aion;
#>>  
#>> has role => (is => 'ro');
#>> 
#>> #@eon ex.cat
#>> sub cat { __PACKAGE__->new(role => 'cat') }
#>> 
#>> #@eon
#>> sub dog { __PACKAGE__->new(role => 'dog') }
#>> 
#>> 1;
#@< EOF
# 
# Файл etc/annotation/eon.ann:
#@> etc/annotation/eon.ann
#>> Ex::Eon::AnimalEon#,2=
#>> Ex::Eon::AnimalEon#cat,10=ex.cat
#>> Ex::Eon::AnimalEon#dog,13=Ex::Eon::AnimalEon#dog
#@< EOF
# 
::done_testing; }; subtest 'pleroma' => sub { 
local ($::_g0 = do {Aion::Pleroma->new->pleroma}, $::_e0 = do {{ "Ex::Eon::AnimalEon#dog" => { class => "Ex::Eon::AnimalEon", method => "dog" }, "Ex::Eon::AnimalEon" => { class => "Ex::Eon::AnimalEon", method => "new" }, "ex.cat" => { class => "Ex::Eon::AnimalEon", method => "cat" }, "Aion::Pleroma" => { class => "Aion::Pleroma", method => "new" } }}); ::is_deeply $::_g0, $::_e0, 'Aion::Pleroma->new->pleroma # --> { "Ex::Eon::AnimalEon#dog" => { class => "Ex::Eon::AnimalEon", method => "dog" }, "Ex::Eon::AnimalEon" => { class => "Ex::Eon::AnimalEon", method => "new" }, "ex.cat" => { class => "Ex::Eon::AnimalEon", method => "cat" }, "Aion::Pleroma" => { class => "Aion::Pleroma", method => "new" } }' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## eon
# 
# Совокупность порождённых эонов.
# 
::done_testing; }; subtest 'eon' => sub { 
my $pleroma = Aion::Pleroma->new;

local ($::_g0 = do {$pleroma->eon}, $::_e0 = do {{ "Aion::Pleroma" => $pleroma }}); ::is_deeply $::_g0, $::_e0, '$pleroma->eon # --> { "Aion::Pleroma" => $pleroma }' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
my $cat = $pleroma->resolve('ex.cat');
local ($::_g0 = do {$pleroma->eon}, $::_e0 = do {{ "ex.cat" => $cat, "Aion::Pleroma" => $pleroma }}); ::is_deeply $::_g0, $::_e0, '$pleroma->eon # --> { "ex.cat" => $cat, "Aion::Pleroma" => $pleroma }' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # SUBROUTINES
# 
# ## get ($key)
# 
# Получить эон из контейнера.
# 
::done_testing; }; subtest 'get ($key)' => sub { 
my $pleroma = Aion::Pleroma->new;
local ($::_g0 = do {$pleroma->get('')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$pleroma->get(\'\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$pleroma->get('Ex::Eon::AnimalEon#dog')->role}, $::_e0 = "dog"); ::ok $::_g0 eq $::_e0, '$pleroma->get(\'Ex::Eon::AnimalEon#dog\')->role # => dog' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## resolve ($key)
# 
# Получить эон из контейнера или исключение, если его там нет.
# 
::done_testing; }; subtest 'resolve ($key)' => sub { 
my $pleroma = Aion::Pleroma->new;
eval {$pleroma->resolve('e.ibex')}; local ($::_g0 = $@, $::_e0 = "e.ibex is'nt eon!"); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$pleroma->resolve(\'e.ibex\') # @=> e.ibex is\'nt eon!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$pleroma->resolve('Ex::Eon::AnimalEon#dog')->role}, $::_e0 = "dog"); ::ok $::_g0 eq $::_e0, '$pleroma->resolve(\'Ex::Eon::AnimalEon#dog\')->role # => dog' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## autoware ($config, [$key])
# 
# Добавить эон в плерому. `$config` – строка `'класс#метод'` (или просто `'класс'`) либо хеш с ключами `class`, `method`, а также опционально `arguments`/`calls` (см. выше). Если `$key` не задан, он выводится из конфигурации.
# 
# Файл lib/Ex/Eon/AstroEon.pm:
#@> lib/Ex/Eon/AstroEon.pm
#>> package Ex::Eon::AstroEon;
#>> use common::sense;
#>> use Aion;
#>> 
#>> has role => (is => 'ro', default => 'upiter');
#>> sub mars { __PACKAGE__->new(role => 'mars') }
#>> sub venus { __PACKAGE__->new(role => 'venus') }
#>> 
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'autoware ($config, [$key])' => sub { 
my $pleroma = Aion::Pleroma->new;
local ($::_g0 = do {$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role}, $::_e0 = "upiter"); ::ok $::_g0 eq $::_e0, '$pleroma->autoware(\'Ex::Eon::AstroEon\')->get(\'Ex::Eon::AstroEon\')->role # => upiter' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$pleroma->autoware('Ex::Eon::AstroEon#mars', 'ex.mars')->get('ex.mars')->role}, $::_e0 = "mars"); ::ok $::_g0 eq $::_e0, '$pleroma->autoware(\'Ex::Eon::AstroEon#mars\', \'ex.mars\')->get(\'ex.mars\')->role # => mars' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$pleroma->autoware('Ex::Eon::AstroEon#venus')->get('Ex::Eon::AstroEon#venus')->role}, $::_e0 = "venus"); ::ok $::_g0 eq $::_e0, '$pleroma->autoware(\'Ex::Eon::AstroEon#venus\')->get(\'Ex::Eon::AstroEon#venus\')->role # => venus' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$pleroma->autoware({class => 'Ex::Eon::AstroEon', method => 'venus'})->get('Ex::Eon::AstroEon#venus')->role}, $::_e0 = "venus"); ::ok $::_g0 eq $::_e0, '$pleroma->autoware({class => \'Ex::Eon::AstroEon\', method => \'venus\'})->get(\'Ex::Eon::AstroEon#venus\')->role # => venus' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role}, $::_e0 = "upiter"); ::ok $::_g0 eq $::_e0, '$pleroma->autoware(\'Ex::Eon::AstroEon\')->get(\'Ex::Eon::AstroEon\')->role # => upiter' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
eval {$pleroma->autoware('Ex::Eon::AstroEon#mars', 'Ex::Eon::AstroEon#venus')}; local ($::_g0 = $@, $::_e0 = 'Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$pleroma->autoware(\'Ex::Eon::AstroEon#mars\', \'Ex::Eon::AstroEon#venus\') # @-> Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

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
# The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
