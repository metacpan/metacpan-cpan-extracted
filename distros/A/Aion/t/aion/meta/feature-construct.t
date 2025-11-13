use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} } # 
# # NAME
# 
# Aion::Meta::FeatureConstruct - конструктор акцессора, предиката, инициализатора и очистителя
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Meta::FeatureConstruct;

our $construct = Aion::Meta::FeatureConstruct->new('My::Package', 'my_feature');

$construct->add_attr(':lvalue');

::is scalar do {$construct->accessor}, scalar do{<< 'END'}, '$construct->accessor # -> << \'END\'';
package My::Package {
	sub my_feature:lvalue {
		if (@_>1) {
			my ($self, $val) = @_;
			$self->{my_feature} = $val;
			$self
		} else {
			my ($self) = @_;
			$self->{my_feature}
		}
	}
}
END

# 
# # DESCRIPTION
# 
# Предназначен для конструирования геттеров/сеттеров из кусочков кода.
# 
# # SUBROUTINES
# 
# ## new ($pkg, $name)
# 
# Конструктор.
# 
# ## pkg
# 
# Пакет, к которому относится атрибут. Геттер.
# 
::done_testing; }; subtest 'pkg' => sub { 
::is scalar do {$::construct->pkg}, scalar do{"My::Package"}, '$::construct->pkg # -> "My::Package"';

# ## name
# 
# Имя атрибута. Геттер. 
# 
::done_testing; }; subtest 'name' => sub { 
::is scalar do {$::construct->name}, scalar do{"my_feature"}, '$::construct->name # -> "my_feature"';

# 
# ## write
# 
# Код для записи значения. Геттер.
# 
::done_testing; }; subtest 'write' => sub { 
::is scalar do {$::construct->write}, '%(preset)s%(set)s%(trigger)s', '$::construct->write # \> %(preset)s%(set)s%(trigger)s';

# 
# ## read
# Код для чтения значения. Геттер.
# 
::done_testing; }; subtest 'read' => sub { 
::is scalar do {$::construct->read}, '%(access)s%(getvar)s%(release)s%(ret)s', '$::construct->read # \> %(access)s%(getvar)s%(release)s%(ret)s';

# 
# ## getvar
# Переменная для получения значения. Геттер.
# 
::done_testing; }; subtest 'getvar' => sub { 
::is scalar do {$::construct->getvar}, '%(get)s', '$::construct->getvar # \> %(get)s';

# 
# ## ret
# Код возврата значения. Геттер.
# 
::done_testing; }; subtest 'ret' => sub { 
::is scalar do {$::construct->ret}, scalar do{''}, '$::construct->ret # -> \'\'';

# 
# ## init_arg
# Ключ в хеше инициализации. Акцессор.
# 
::done_testing; }; subtest 'init_arg' => sub { 
::is scalar do {$::construct->init_arg}, '%(name)s', '$::construct->init_arg # \> %(name)s';

# 
# ## set
# Код установки значения в хеш объекта. Акцессор.
# 
::done_testing; }; subtest 'set' => sub { 
::is scalar do {$::construct->set}, '$self->{%(name)s} = $val;', '$::construct->set # \> $self->{%(name)s} = $val;';

# 
# ## get
# Код получения значения из хеша объекта. Акцессор.
# 
::done_testing; }; subtest 'get' => sub { 
::is scalar do {$::construct->get}, '$self->{%(name)s}', '$::construct->get # \> $self->{%(name)s}';

# 
# ## has
# Код проверки существования значения. Акцессор.
# 
::done_testing; }; subtest 'has' => sub { 
::is scalar do {$::construct->has}, 'exists $self->{%(name)s}', '$::construct->has # \> exists $self->{%(name)s}';

# 
# ## clear
# Код удаления значения. Акцессор.
# 
::done_testing; }; subtest 'clear' => sub { 
::is scalar do {$::construct->clear}, 'delete $self->{%(name)s}', '$::construct->clear # \> delete $self->{%(name)s}';

# 
# ## weaken
# Код ослабления ссылки. Акцессор.
# 
::done_testing; }; subtest 'weaken' => sub { 
::is scalar do {$::construct->weaken}, 'Scalar::Util::weaken(%(get)s);', '$::construct->weaken # \> Scalar::Util::weaken(%(get)s);';

# 
# ## accessor_name
# Имя метода-акцессора. Акцессор.
# 
::done_testing; }; subtest 'accessor_name' => sub { 
::is scalar do {$::construct->accessor_name}, '%(name)s', '$::construct->accessor_name # \> %(name)s';

# 
# ## reader_name
# Имя метода-ридера. Акцессор.
# 
::done_testing; }; subtest 'reader_name' => sub { 
::is scalar do {$::construct->reader_name}, '_get_%(name)s', '$::construct->reader_name # \> _get_%(name)s';

# 
# ## writer_name
# Имя метода-райтера. Акцессор.
# 
::done_testing; }; subtest 'writer_name' => sub { 
::is scalar do {$::construct->writer_name}, '_set_%(name)s', '$::construct->writer_name # \> _set_%(name)s';

# 
# ## predicate_name
# Имя метода-предиката. Акцессор.
# 
::done_testing; }; subtest 'predicate_name' => sub { 
::is scalar do {$::construct->predicate_name}, 'has_%(name)s', '$::construct->predicate_name # \> has_%(name)s';

# 
# ## clearer_name
# Имя метода-очистителя. Акцессор.
# 
::done_testing; }; subtest 'clearer_name' => sub { 
::is scalar do {$::construct->clearer_name}, 'clear_%(name)s', '$::construct->clearer_name # \> clear_%(name)s';

# 
# ## initer
# Код инициализации атрибута. Акцессор.
# 
::done_testing; }; subtest 'initer' => sub { 
::is scalar do {$::construct->initer}, '%(initvar)s%(write)s', '$::construct->initer # \> %(initvar)s%(write)s';

# 
# ## not_specified
# Код инициализации, если значение не указано. Акцессор.
# 
::done_testing; }; subtest 'not_specified' => sub { 
::is scalar do {$::construct->not_specified}, scalar do{''}, '$::construct->not_specified # -> \'\'';

# 
# ## getter
# Код геттера в акцессоре. Акцессор.
# 
::done_testing; }; subtest 'getter' => sub { 
::is scalar do {$::construct->getter}, '%(read)s', '$::construct->getter # \> %(read)s';

# 
# ## setter
# Код сеттера в акцессоре. По умолчанию: '%(write)s'.
# 
::done_testing; }; subtest 'setter' => sub { 
::is scalar do {$::construct->setter}, '%(write)s', '$::construct->setter # \> %(write)s';

# 
# ## selfret
# Код возврата из сеттера. Акцессор.
# 
::done_testing; }; subtest 'selfret' => sub { 
::is scalar do {$::construct->selfret}, '$self', '$::construct->selfret # \> $self';

# 
# ## add_attr($code, $unshift)
# Добавляет атрибут к акцессору.
# 
::done_testing; }; subtest 'add_attr($code, $unshift)' => sub { 
$::construct->add_attr(':bvalue');
::is_deeply scalar do {$::construct->{attr}}, scalar do {[':lvalue', ':bvalue']}, '$::construct->{attr} # --> [\':lvalue\', \':bvalue\']';
$::construct->add_attr(':a_value', 1);
::is_deeply scalar do {$::construct->{attr}}, scalar do {[':a_value', ':lvalue', ':bvalue']}, '$::construct->{attr} # --> [\':a_value\', \':lvalue\', \':bvalue\']';

# 
# ## add_preset($code, $unshift)
# Добавляет код предустановки перед записью.
# 
::done_testing; }; subtest 'add_preset($code, $unshift)' => sub { 
$::construct->add_preset('die if $val < 0;', 1);
::is scalar do {$::construct->{preset}}, scalar do{'die if $val < 0;'}, '$::construct->{preset} # -> \'die if $val < 0;\'';

# 
# ## add_trigger($code, $unshift)
# Добавляет триггер после записи.
# 
::done_testing; }; subtest 'add_trigger($code, $unshift)' => sub { 
$::construct->add_trigger('$self->on_change;');
::is scalar do {$::construct->{trigger}}, scalar do{'$self->on_change;'}, '$::construct->{trigger} # -> \'$self->on_change;\'';

# 
# ## add_cleaner($code, $unshift)
# Добавляет код очистки перед удалением.
# 
::done_testing; }; subtest 'add_cleaner($code, $unshift)' => sub { 
$::construct->add_cleaner('$self->{old} = $self->{attr};');
::is scalar do {$::construct->{cleaner}}, scalar do{'$self->{old} = $self->{attr};'}, '$::construct->{cleaner} # -> \'$self->{old} = $self->{attr};\'';

# 
# ## add_access($code, $unshift)
# Добавляет код в геттер перед чтением атрибута.
# 
::done_testing; }; subtest 'add_access($code, $unshift)' => sub { 
$::construct->add_access('die unless $self->{attr};');
::is scalar do {$::construct->{access}}, scalar do{'die unless $self->{attr};'}, '$::construct->{access} # -> \'die unless $self->{attr};\'';

# 
# ## add_release($code, $unshift)
# Добавляет код в геттер после чтения.
# 
::done_testing; }; subtest 'add_release($code, $unshift)' => sub { 
$::construct->add_release('$val = undef;');
::is scalar do {$::construct->{release}}, scalar do{'$val = undef;'}, '$::construct->{release} # -> \'$val = undef;\'';

# 
# ## initializer
# Генерирует код для инициализации фичи в конструкторе (`new`).
# 
::done_testing; }; subtest 'initializer' => sub { 

::is scalar do {$::construct->initializer}, scalar do{<< 'END'}, '$::construct->initializer # -> << \'END\'';
		if (exists $value{my_feature}) {
			my $val = delete $value{my_feature};
			die if $val < 0;
			$self->{my_feature} = $val;
			$self->on_change;
		}
END

# 
# ## destroyer
# Генерирует код для деструктора.
# 
::done_testing; }; subtest 'destroyer' => sub { 
::is scalar do {$::construct->destroyer}, scalar do{<<'END'}, '$::construct->destroyer # -> <<\'END\'';
		if (exists $self->{my_feature}) {
			eval {
				$self->{old} = $self->{attr};
			};
			warn $@ if $@;
		}
END

# 
# ## accessor
# Генерирует код акцессора.
# 
::done_testing; }; subtest 'accessor' => sub { 



::is scalar do {$::construct->accessor}, scalar do{<<'END'}, '$::construct->accessor # -> <<\'END\'';
package My::Package {
	sub my_feature:a_value:lvalue:bvalue {
		if (@_>1) {
			my ($self, $val) = @_;
			die if $val < 0;
			$self->{my_feature} = $val;
			$self->on_change;
			$self
		} else {
			my ($self) = @_;
			die unless $self->{attr};
			my $val = $self->{my_feature};
			$val = undef;
			$val
		}
	}
}
END

# 
# ## reader
# Генерирует код геттера.
# 
::done_testing; }; subtest 'reader' => sub { 
::is scalar do {$::construct->reader}, scalar do{<<'END'}, '$::construct->reader # -> <<\'END\'';
package My::Package {
	sub _get_my_feature {
		my ($self) = @_;
		die unless $self->{attr};
		my $val = $self->{my_feature};
		$val = undef;
		$val
	}
}
END

# 
# ## writer
# Генерирует код сеттера.
# 
::done_testing; }; subtest 'writer' => sub { 
::is scalar do {$::construct->writer}, scalar do{<<'END'}, '$::construct->writer # -> <<\'END\'';
package My::Package {
	sub _set_my_feature {
		my ($self, $val) = @_;
		die if $val < 0;
		$self->{my_feature} = $val;
		$self->on_change;
		$self
	}
}
END

# 
# ## predicate
# Генерирует код предиката.
# 
::done_testing; }; subtest 'predicate' => sub { 
::is scalar do {$::construct->predicate}, scalar do{<<'END'}, '$::construct->predicate # -> <<\'END\'';
package My::Package {
	sub has_my_feature {
		my ($self) = @_;
		exists $self->{my_feature}
	}
}
END

# 
# ## clearer
# Генерирует код очистителя.
# 
::done_testing; }; subtest 'clearer' => sub { 
::is scalar do {$::construct->clearer}, scalar do{<<'END'}, '$::construct->clearer # -> <<\'END\'';
package My::Package {
	sub clear_my_feature {
		my ($self) = @_;
		if (exists $self->{my_feature}) {
			$self->{old} = $self->{attr};
			delete $self->{my_feature}
		}
		$self
	}
}
END

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
# The Aion::Meta::FeatureConstruct module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
