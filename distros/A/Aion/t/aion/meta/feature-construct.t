use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
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

local ($::_g0 = do {$construct->accessor}, $::_e0 = do {<< 'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$construct->accessor # -> << \'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$::construct->pkg}, $::_e0 = do {"My::Package"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->pkg # -> "My::Package"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# ## name
# 
# Имя атрибута. Геттер. 
# 
::done_testing; }; subtest 'name' => sub { 
local ($::_g0 = do {$::construct->name}, $::_e0 = do {"my_feature"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->name # -> "my_feature"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## write
# 
# Код для записи значения. Геттер.
# 
::done_testing; }; subtest 'write' => sub { 
local ($::_g0 = do {$::construct->write}, $::_e0 = '%(preset)s%(set)s%(trigger)s'); ::ok $::_g0 eq $::_e0, '$::construct->write # \> %(preset)s%(set)s%(trigger)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## read
# Код для чтения значения. Геттер.
# 
::done_testing; }; subtest 'read' => sub { 
local ($::_g0 = do {$::construct->read}, $::_e0 = '%(access)s%(getvar)s%(release)s%(ret)s'); ::ok $::_g0 eq $::_e0, '$::construct->read # \> %(access)s%(getvar)s%(release)s%(ret)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## getvar
# Переменная для получения значения. Геттер.
# 
::done_testing; }; subtest 'getvar' => sub { 
local ($::_g0 = do {$::construct->getvar}, $::_e0 = '%(get)s'); ::ok $::_g0 eq $::_e0, '$::construct->getvar # \> %(get)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ret
# Код возврата значения. Геттер.
# 
::done_testing; }; subtest 'ret' => sub { 
local ($::_g0 = do {$::construct->ret}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->ret # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## init_arg
# Ключ в хеше инициализации. Акцессор.
# 
::done_testing; }; subtest 'init_arg' => sub { 
local ($::_g0 = do {$::construct->init_arg}, $::_e0 = '%(name)s'); ::ok $::_g0 eq $::_e0, '$::construct->init_arg # \> %(name)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## set
# Код установки значения в хеш объекта. Акцессор.
# 
::done_testing; }; subtest 'set' => sub { 
local ($::_g0 = do {$::construct->set}, $::_e0 = '$self->{%(name)s} = $val;'); ::ok $::_g0 eq $::_e0, '$::construct->set # \> $self->{%(name)s} = $val;' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## get
# Код получения значения из хеша объекта. Акцессор.
# 
::done_testing; }; subtest 'get' => sub { 
local ($::_g0 = do {$::construct->get}, $::_e0 = '$self->{%(name)s}'); ::ok $::_g0 eq $::_e0, '$::construct->get # \> $self->{%(name)s}' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## has
# Код проверки существования значения. Акцессор.
# 
::done_testing; }; subtest 'has' => sub { 
local ($::_g0 = do {$::construct->has}, $::_e0 = 'exists $self->{%(name)s}'); ::ok $::_g0 eq $::_e0, '$::construct->has # \> exists $self->{%(name)s}' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## clear
# Код удаления значения. Акцессор.
# 
::done_testing; }; subtest 'clear' => sub { 
local ($::_g0 = do {$::construct->clear}, $::_e0 = 'delete $self->{%(name)s}'); ::ok $::_g0 eq $::_e0, '$::construct->clear # \> delete $self->{%(name)s}' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## weaken
# Код ослабления ссылки. Акцессор.
# 
::done_testing; }; subtest 'weaken' => sub { 
local ($::_g0 = do {$::construct->weaken}, $::_e0 = 'Scalar::Util::weaken(%(get)s);'); ::ok $::_g0 eq $::_e0, '$::construct->weaken # \> Scalar::Util::weaken(%(get)s);' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## accessor_name
# Имя метода-акцессора. Акцессор.
# 
::done_testing; }; subtest 'accessor_name' => sub { 
local ($::_g0 = do {$::construct->accessor_name}, $::_e0 = '%(name)s'); ::ok $::_g0 eq $::_e0, '$::construct->accessor_name # \> %(name)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## reader_name
# Имя метода-ридера. Акцессор.
# 
::done_testing; }; subtest 'reader_name' => sub { 
local ($::_g0 = do {$::construct->reader_name}, $::_e0 = '_get_%(name)s'); ::ok $::_g0 eq $::_e0, '$::construct->reader_name # \> _get_%(name)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## writer_name
# Имя метода-райтера. Акцессор.
# 
::done_testing; }; subtest 'writer_name' => sub { 
local ($::_g0 = do {$::construct->writer_name}, $::_e0 = '_set_%(name)s'); ::ok $::_g0 eq $::_e0, '$::construct->writer_name # \> _set_%(name)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## predicate_name
# Имя метода-предиката. Акцессор.
# 
::done_testing; }; subtest 'predicate_name' => sub { 
local ($::_g0 = do {$::construct->predicate_name}, $::_e0 = 'has_%(name)s'); ::ok $::_g0 eq $::_e0, '$::construct->predicate_name # \> has_%(name)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## clearer_name
# Имя метода-очистителя. Акцессор.
# 
::done_testing; }; subtest 'clearer_name' => sub { 
local ($::_g0 = do {$::construct->clearer_name}, $::_e0 = 'clear_%(name)s'); ::ok $::_g0 eq $::_e0, '$::construct->clearer_name # \> clear_%(name)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## initer
# Код инициализации атрибута. Акцессор.
# 
::done_testing; }; subtest 'initer' => sub { 
local ($::_g0 = do {$::construct->initer}, $::_e0 = '%(initvar)s%(write)s'); ::ok $::_g0 eq $::_e0, '$::construct->initer # \> %(initvar)s%(write)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## not_specified
# Код инициализации, если значение не указано. Акцессор.
# 
::done_testing; }; subtest 'not_specified' => sub { 
local ($::_g0 = do {$::construct->not_specified}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->not_specified # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## getter
# Код геттера в акцессоре. Акцессор.
# 
::done_testing; }; subtest 'getter' => sub { 
local ($::_g0 = do {$::construct->getter}, $::_e0 = '%(read)s'); ::ok $::_g0 eq $::_e0, '$::construct->getter # \> %(read)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## setter
# Код сеттера в акцессоре. По умолчанию: '%(write)s'.
# 
::done_testing; }; subtest 'setter' => sub { 
local ($::_g0 = do {$::construct->setter}, $::_e0 = '%(write)s'); ::ok $::_g0 eq $::_e0, '$::construct->setter # \> %(write)s' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## selfret
# Код возврата из сеттера. Акцессор.
# 
::done_testing; }; subtest 'selfret' => sub { 
local ($::_g0 = do {$::construct->selfret}, $::_e0 = '$self'); ::ok $::_g0 eq $::_e0, '$::construct->selfret # \> $self' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_attr($code, $unshift)
# Добавляет атрибут к акцессору.
# 
::done_testing; }; subtest 'add_attr($code, $unshift)' => sub { 
$::construct->add_attr(':bvalue');
local ($::_g0 = do {$::construct->{attr}}, $::_e0 = do {[':lvalue', ':bvalue']}); ::is_deeply $::_g0, $::_e0, '$::construct->{attr} # --> [\':lvalue\', \':bvalue\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
$::construct->add_attr(':a_value', 1);
local ($::_g0 = do {$::construct->{attr}}, $::_e0 = do {[':a_value', ':lvalue', ':bvalue']}); ::is_deeply $::_g0, $::_e0, '$::construct->{attr} # --> [\':a_value\', \':lvalue\', \':bvalue\']' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_preset($code, $unshift)
# Добавляет код предустановки перед записью.
# 
::done_testing; }; subtest 'add_preset($code, $unshift)' => sub { 
$::construct->add_preset('die if $val < 0;', 1);
local ($::_g0 = do {$::construct->{preset}}, $::_e0 = do {'die if $val < 0;'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->{preset} # -> \'die if $val < 0;\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_trigger($code, $unshift)
# Добавляет триггер после записи.
# 
::done_testing; }; subtest 'add_trigger($code, $unshift)' => sub { 
$::construct->add_trigger('$self->on_change;');
local ($::_g0 = do {$::construct->{trigger}}, $::_e0 = do {'$self->on_change;'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->{trigger} # -> \'$self->on_change;\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_cleaner($code, $unshift)
# Добавляет код очистки перед удалением.
# 
::done_testing; }; subtest 'add_cleaner($code, $unshift)' => sub { 
$::construct->add_cleaner('$self->{old} = $self->{attr};');
local ($::_g0 = do {$::construct->{cleaner}}, $::_e0 = do {'$self->{old} = $self->{attr};'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->{cleaner} # -> \'$self->{old} = $self->{attr};\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_access($code, $unshift)
# Добавляет код в геттер перед чтением атрибута.
# 
::done_testing; }; subtest 'add_access($code, $unshift)' => sub { 
$::construct->add_access('die unless $self->{attr};');
local ($::_g0 = do {$::construct->{access}}, $::_e0 = do {'die unless $self->{attr};'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->{access} # -> \'die unless $self->{attr};\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_release($code, $unshift)
# Добавляет код в геттер после чтения.
# 
::done_testing; }; subtest 'add_release($code, $unshift)' => sub { 
$::construct->add_release('$val = undef;');
local ($::_g0 = do {$::construct->{release}}, $::_e0 = do {'$val = undef;'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->{release} # -> \'$val = undef;\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## initializer
# Генерирует код для инициализации фичи в конструкторе (`new`).
# 
::done_testing; }; subtest 'initializer' => sub { 

local ($::_g0 = do {$::construct->initializer}, $::_e0 = do {<< 'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->initializer # -> << \'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$::construct->destroyer}, $::_e0 = do {<<'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->destroyer # -> <<\'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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



local ($::_g0 = do {$::construct->accessor}, $::_e0 = do {<<'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->accessor # -> <<\'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$::construct->reader}, $::_e0 = do {<<'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->reader # -> <<\'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$::construct->writer}, $::_e0 = do {<<'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->writer # -> <<\'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$::construct->predicate}, $::_e0 = do {<<'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->predicate # -> <<\'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
local ($::_g0 = do {$::construct->clearer}, $::_e0 = do {<<'END'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$::construct->clearer # -> <<\'END\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
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
