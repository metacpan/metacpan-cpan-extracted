use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Enum - перечисления в стиле ООП, когда каждое перечсление является объектом
# 
# # VERSION
# 
# 0.0.2
# 
# # SYNOPSIS
# 
# Файл lib/StatusEnum.pm:
#@> lib/StatusEnum.pm
#>> package StatusEnum;
#>> 
#>> use Aion::Enum;
#>> 
#>> # Active status
#>> case active => 1, 'Active';
#>> 
#>> # Passive status
#>> case passive => 2, 'Passive';
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use StatusEnum;

::is scalar do {&StatusEnum::active->does('Aion::Enum')}, "1", '&StatusEnum::active->does(\'Aion::Enum\') # => 1';

::is scalar do {StatusEnum->active->name}, "active", 'StatusEnum->active->name   # => active';
::is scalar do {StatusEnum->passive->value}, "2", 'StatusEnum->passive->value # => 2';
::is scalar do {StatusEnum->active->alias}, "Active status", 'StatusEnum->active->alias  # => Active status';
::is scalar do {StatusEnum->passive->stash}, "Passive", 'StatusEnum->passive->stash # => Passive';

::is_deeply scalar do {[ StatusEnum->cases   ]}, scalar do {[StatusEnum->active, StatusEnum->passive]}, '[ StatusEnum->cases   ] # --> [StatusEnum->active, StatusEnum->passive]';
::is_deeply scalar do {[ StatusEnum->names   ]}, scalar do {[qw/active passive/]}, '[ StatusEnum->names   ] # --> [qw/active passive/]';
::is_deeply scalar do {[ StatusEnum->values  ]}, scalar do {[qw/1 2/]}, '[ StatusEnum->values  ] # --> [qw/1 2/]';
::is_deeply scalar do {[ StatusEnum->aliases ]}, scalar do {['Active status', 'Passive status']}, '[ StatusEnum->aliases ] # --> [\'Active status\', \'Passive status\']';
::is_deeply scalar do {[ StatusEnum->stashes ]}, scalar do {[qw/Active Passive/]}, '[ StatusEnum->stashes ] # --> [qw/Active Passive/]';

# 
# # DESCRIPTION
# 
# `Aion::Enum` позволяет создавать перечисления-объекты. Данные перечисления могут содержать дополнительные методы и свойства. В них можно добавлять роли (с помощью `with`) или использовать их самих как роли.
# 
# Важной особенностью является сохранение порядка перечисления.
# 
# `Aion::Enum` подобен перечислениям из php8, но имеет дополнительные свойства `alias` и `stash`.
# 
# # SUBROUTINES
# 
# ## case ($name, [$value, [$stash]])
# 
# Создаёт перечисление: его константу.
# 
::done_testing; }; subtest 'case ($name, [$value, [$stash]])' => sub { 
package OrderEnum {
    use Aion::Enum;

    case 'first';
    case second => 2;
    case other  => 3, {data => 123};
}

::is scalar do {&OrderEnum::first->name}, "first", '&OrderEnum::first->name  # => first';
::is scalar do {&OrderEnum::first->value}, scalar do{undef}, '&OrderEnum::first->value # -> undef';
::is scalar do {&OrderEnum::first->stash}, scalar do{undef}, '&OrderEnum::first->stash # -> undef';

::is scalar do {&OrderEnum::second->name}, "second", '&OrderEnum::second->name  # => second';
::is scalar do {&OrderEnum::second->value}, scalar do{2}, '&OrderEnum::second->value # -> 2';
::is scalar do {&OrderEnum::second->stash}, scalar do{undef}, '&OrderEnum::second->stash # -> undef';

::is scalar do {&OrderEnum::other->name}, "other", '&OrderEnum::other->name  # => other';
::is scalar do {&OrderEnum::other->value}, scalar do{3}, '&OrderEnum::other->value # -> 3';
::is_deeply scalar do {&OrderEnum::other->stash}, scalar do {{data => 123}}, '&OrderEnum::other->stash # --> {data => 123}';

# 
# ## issa ($nameisa, [$valueisa], [$stashisa], [$aliasisa])
# 
# Указывает тип (isa) значений и дополнений.
# 
# Её название – отсылка к богине Иссе из повести «Под лунами Марса» Берроуза.
# 
::done_testing; }; subtest 'issa ($nameisa, [$valueisa], [$stashisa], [$aliasisa])' => sub { 
eval {
package StringEnum;
    use Aion::Enum;

    issa Str => Int => Undef => Undef;

    case active => "Active";
};
::like scalar do {$@}, qr{active value must have the type Int. The it is 'Active'}, '$@ # ~> active value must have the type Int. The it is \'Active\'';

eval {
package StringEnum;
    use Aion::Enum;

    issa Str => Str => Int;

    case active => "Active", "Passive";
};
::like scalar do {$@}, qr{active stash must have the type Int. The it is 'Passive'}, '$@ # ~> active stash must have the type Int. The it is \'Passive\'';

# 
# Файл lib/StringEnum.pm:
#@> lib/StringEnum.pm
#>> package StringEnum;
#>> use Aion::Enum;
#>> 
#>> issa Str => Undef => Undef => StrMatch[qr/^[A-Z]/];
#>> 
#>> # pushkin
#>> case active => ;
#>> 
#>> 1;
#@< EOF
# 

::cmp_ok do { eval {require StringEnum}; $@ }, '=~', '^' . quotemeta 'active alias must have the type StrMatch[qr/^[A-Z]/]. The it is \'pushkin\'!', 'require StringEnum # @-> active alias must have the type StrMatch[qr/^[A-Z]/]. The it is \'pushkin\'!';

# 
# # CLASS METHODS
# 
# ## cases ($cls)
# 
# Список перечислений.
# 
::done_testing; }; subtest 'cases ($cls)' => sub { 
::is_deeply scalar do {[ OrderEnum->cases ]}, scalar do {[OrderEnum->first, OrderEnum->second, OrderEnum->other]}, '[ OrderEnum->cases ] # --> [OrderEnum->first, OrderEnum->second, OrderEnum->other]';

# 
# ## names ($cls)
# 
# Имена перечислений.
# 
::done_testing; }; subtest 'names ($cls)' => sub { 
::is_deeply scalar do {[ OrderEnum->names ]}, scalar do {[qw/first second other/]}, '[ OrderEnum->names ] # --> [qw/first second other/]';

# 
# ## values ($cls)
# 
# Значения перечислений.
# 
::done_testing; }; subtest 'values ($cls)' => sub { 
::is_deeply scalar do {[ OrderEnum->values ]}, scalar do {[undef, 2, 3]}, '[ OrderEnum->values ] # --> [undef, 2, 3]';

# 
# ## stashes ($cls)
# 
# Дополнения перечислений.
# 
::done_testing; }; subtest 'stashes ($cls)' => sub { 
::is_deeply scalar do {[ OrderEnum->stashes ]}, scalar do {[undef, undef, {data => 123}]}, '[ OrderEnum->stashes ] # --> [undef, undef, {data => 123}]';

# 
# ## aliases ($cls)
# 
# Псевдонимы перечислений.
# 
# Файл lib/AuthorEnum.pm:
#@> lib/AuthorEnum.pm
#>> package AuthorEnum;
#>> 
#>> use Aion::Enum;
#>> 
#>> # Pushkin Aleksandr Sergeevich
#>> case pushkin =>;
#>> 
#>> # Yacheykin Uriy
#>> case yacheykin =>;
#>> 
#>> case nouname =>;
#>> 
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'aliases ($cls)' => sub { 
require AuthorEnum;
::is_deeply scalar do {[ AuthorEnum->aliases ]}, scalar do {['Pushkin Aleksandr Sergeevich', 'Yacheykin Uriy', undef]}, '[ AuthorEnum->aliases ] # --> [\'Pushkin Aleksandr Sergeevich\', \'Yacheykin Uriy\', undef]';

# 
# ## fromName ($cls, $name)
# 
# Получить case по имени c исключением.
# 
::done_testing; }; subtest 'fromName ($cls, $name)' => sub { 
::is scalar do {OrderEnum->fromName('first')}, scalar do{OrderEnum->first}, 'OrderEnum->fromName(\'first\') # -> OrderEnum->first';
::like scalar do {eval { OrderEnum->fromName('not_exists') }; $@}, qr{Did not case with name `not_exists`\!}, 'eval { OrderEnum->fromName(\'not_exists\') }; $@ # ~> Did not case with name `not_exists`!';

# 
# ## tryFromName ($cls, $name)
# 
# Получить case по имени.
# 
::done_testing; }; subtest 'tryFromName ($cls, $name)' => sub { 
::is scalar do {OrderEnum->tryFromName('first')}, scalar do{OrderEnum->first}, 'OrderEnum->tryFromName(\'first\')      # -> OrderEnum->first';
::is scalar do {OrderEnum->tryFromName('not_exists')}, scalar do{undef}, 'OrderEnum->tryFromName(\'not_exists\') # -> undef';

# 
# ## fromValue ($cls, $value)
# 
# Получить case по значению c исключением.
# 
::done_testing; }; subtest 'fromValue ($cls, $value)' => sub { 
::is scalar do {OrderEnum->fromValue(undef)}, scalar do{OrderEnum->first}, 'OrderEnum->fromValue(undef) # -> OrderEnum->first';
::like scalar do {eval { OrderEnum->fromValue('not-exists') }; $@}, qr{Did not case with value `not-exists`\!}, 'eval { OrderEnum->fromValue(\'not-exists\') }; $@ # ~> Did not case with value `not-exists`!';

# 
# ## tryFromValue ($cls, $value)
# 
# Получить case по значению.
# 
::done_testing; }; subtest 'tryFromValue ($cls, $value)' => sub { 
::is scalar do {OrderEnum->tryFromValue(undef)}, scalar do{OrderEnum->first}, 'OrderEnum->tryFromValue(undef)        # -> OrderEnum->first';
::is scalar do {OrderEnum->tryFromValue('not-exists')}, scalar do{undef}, 'OrderEnum->tryFromValue(\'not-exists\') # -> undef';

# 
# ## fromStash ($cls, $stash)
# 
# Получить case по дополнению c исключением.
# 
::done_testing; }; subtest 'fromStash ($cls, $stash)' => sub { 
::is scalar do {OrderEnum->fromStash(undef)}, scalar do{OrderEnum->first}, 'OrderEnum->fromStash(undef) # -> OrderEnum->first';
::like scalar do {eval { OrderEnum->fromStash('not-exists') }; $@}, qr{Did not case with stash `not-exists`\!}, 'eval { OrderEnum->fromStash(\'not-exists\') }; $@ # ~> Did not case with stash `not-exists`!';

# 
# ## tryFromStash ($cls, $value)
# 
# Получить case по дополнению.
# 
::done_testing; }; subtest 'tryFromStash ($cls, $value)' => sub { 
::is scalar do {OrderEnum->tryFromStash({data => 123})}, scalar do{OrderEnum->other}, 'OrderEnum->tryFromStash({data => 123}) # -> OrderEnum->other';
::is scalar do {OrderEnum->tryFromStash('not-exists')}, scalar do{undef}, 'OrderEnum->tryFromStash(\'not-exists\')  # -> undef';

# 
# ## fromAlias ($cls, $alias)
# 
# Получить case по псевдониму c исключением.
# 
::done_testing; }; subtest 'fromAlias ($cls, $alias)' => sub { 
::is scalar do {AuthorEnum->fromAlias('Yacheykin Uriy')}, scalar do{AuthorEnum->yacheykin}, 'AuthorEnum->fromAlias(\'Yacheykin Uriy\') # -> AuthorEnum->yacheykin';
::like scalar do {eval { AuthorEnum->fromAlias('not-exists') }; $@}, qr{Did not case with alias `not-exists`\!}, 'eval { AuthorEnum->fromAlias(\'not-exists\') }; $@ # ~> Did not case with alias `not-exists`!';

# 
# ## tryFromAlias ($cls, $alias)
# 
# Получить case по псевдониму.
# 
::done_testing; }; subtest 'tryFromAlias ($cls, $alias)' => sub { 
::is scalar do {AuthorEnum->tryFromAlias('Yacheykin Uriy')}, scalar do{AuthorEnum->yacheykin}, 'AuthorEnum->tryFromAlias(\'Yacheykin Uriy\') # -> AuthorEnum->yacheykin';
::is scalar do {AuthorEnum->tryFromAlias('not-exists')}, scalar do{undef}, 'AuthorEnum->tryFromAlias(\'not-exists\')     # -> undef';

# 
# # FEATURES
# 
# ## name
# 
# Свойство только для чтения.
# 
::done_testing; }; subtest 'name' => sub { 
package NameEnum {
    use Aion::Enum;

    case piter =>;
}

::is scalar do {NameEnum->piter->name}, "piter", 'NameEnum->piter->name # => piter';

# 
# ## value
# 
# Свойство только для чтения.
# 
::done_testing; }; subtest 'value' => sub { 
package ValueEnum {
    use Aion::Enum;

    case piter => 'Pan';
}

::is scalar do {ValueEnum->piter->value}, "Pan", 'ValueEnum->piter->value # => Pan';

# 
# ## stash
# 
# Свойство только для чтения.
# 
::done_testing; }; subtest 'stash' => sub { 
package StashEnum {
    use Aion::Enum;

    case piter => 'Pan', 123;
}

::is scalar do {StashEnum->piter->stash}, "123", 'StashEnum->piter->stash # => 123';

# 
# ## alias
# 
# Свойство только для чтения.
# 
# Алиасы работают только если пакет находится в модуле, так как считывают комментарий перед кейсом за счёт рефлексии.
# 
# Файл lib/AliasEnum.pm:
#@> lib/AliasEnum.pm
#>> package AliasEnum;
#>> 
#>> use Aion::Enum;
#>> 
#>> # Piter Pan
#>> case piter => ;
#>> 
#>> 1;
#@< EOF
# 
::done_testing; }; subtest 'alias' => sub { 
require AliasEnum;
::is scalar do {AliasEnum->piter->alias}, "Piter Pan", 'AliasEnum->piter->alias # => Piter Pan';

# 
# # SEE ALSO
# 
# 1. [enum](https://metacpan.org/pod/enum).
# 2. [Class::Enum](https://metacpan.org/pod/Class::Enum).
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)
# 
# # LICENSE
# 
# This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Enum module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
