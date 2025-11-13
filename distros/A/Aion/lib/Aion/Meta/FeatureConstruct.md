!ru:en
# NAME

Aion::Meta::FeatureConstruct - конструктор акцессора, предиката, инициализатора и очистителя

# SYNOPSIS

```perl
use Aion::Meta::FeatureConstruct;

our $construct = Aion::Meta::FeatureConstruct->new('My::Package', 'my_feature');

$construct->add_attr(':lvalue');

$construct->accessor # -> << 'END'
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
```

# DESCRIPTION

Предназначен для конструирования геттеров/сеттеров из кусочков кода.

# SUBROUTINES

## new ($pkg, $name)

Конструктор.

## pkg

Пакет, к которому относится атрибут. Геттер.

```perl
$::construct->pkg # -> "My::Package"
```
## name

Имя атрибута. Геттер. 

```perl
$::construct->name # -> "my_feature"
```

## write

Код для записи значения. Геттер.

```perl
$::construct->write # \> %(preset)s%(set)s%(trigger)s
```

## read
Код для чтения значения. Геттер.

```perl
$::construct->read # \> %(access)s%(getvar)s%(release)s%(ret)s
```

## getvar
Переменная для получения значения. Геттер.

```perl
$::construct->getvar # \> %(get)s
```

## ret
Код возврата значения. Геттер.

```perl
$::construct->ret # -> ''
```

## init_arg
Ключ в хеше инициализации. Акцессор.

```perl
$::construct->init_arg # \> %(name)s
```

## set
Код установки значения в хеш объекта. Акцессор.

```perl
$::construct->set # \> $self->{%(name)s} = $val;
```

## get
Код получения значения из хеша объекта. Акцессор.

```perl
$::construct->get # \> $self->{%(name)s}
```

## has
Код проверки существования значения. Акцессор.

```perl
$::construct->has # \> exists $self->{%(name)s}
```

## clear
Код удаления значения. Акцессор.

```perl
$::construct->clear # \> delete $self->{%(name)s}
```

## weaken
Код ослабления ссылки. Акцессор.

```perl
$::construct->weaken # \> Scalar::Util::weaken(%(get)s);
```

## accessor_name
Имя метода-акцессора. Акцессор.

```perl
$::construct->accessor_name # \> %(name)s
```

## reader_name
Имя метода-ридера. Акцессор.

```perl
$::construct->reader_name # \> _get_%(name)s
```

## writer_name
Имя метода-райтера. Акцессор.

```perl
$::construct->writer_name # \> _set_%(name)s
```

## predicate_name
Имя метода-предиката. Акцессор.

```perl
$::construct->predicate_name # \> has_%(name)s
```

## clearer_name
Имя метода-очистителя. Акцессор.

```perl
$::construct->clearer_name # \> clear_%(name)s
```

## initer
Код инициализации атрибута. Акцессор.

```perl
$::construct->initer # \> %(initvar)s%(write)s
```

## not_specified
Код инициализации, если значение не указано. Акцессор.

```perl
$::construct->not_specified # -> ''
```

## getter
Код геттера в акцессоре. Акцессор.

```perl
$::construct->getter # \> %(read)s
```

## setter
Код сеттера в акцессоре. По умолчанию: '%(write)s'.

```perl
$::construct->setter # \> %(write)s
```

## selfret
Код возврата из сеттера. Акцессор.

```perl
$::construct->selfret # \> $self
```

## add_attr($code, $unshift)
Добавляет атрибут к акцессору.

```perl
$::construct->add_attr(':bvalue');
$::construct->{attr} # --> [':lvalue', ':bvalue']
$::construct->add_attr(':a_value', 1);
$::construct->{attr} # --> [':a_value', ':lvalue', ':bvalue']
```

## add_preset($code, $unshift)
Добавляет код предустановки перед записью.

```perl
$::construct->add_preset('die if $val < 0;', 1);
$::construct->{preset} # -> 'die if $val < 0;'
```

## add_trigger($code, $unshift)
Добавляет триггер после записи.

```perl
$::construct->add_trigger('$self->on_change;');
$::construct->{trigger} # -> '$self->on_change;'
```

## add_cleaner($code, $unshift)
Добавляет код очистки перед удалением.

```perl
$::construct->add_cleaner('$self->{old} = $self->{attr};');
$::construct->{cleaner} # -> '$self->{old} = $self->{attr};'
```

## add_access($code, $unshift)
Добавляет код в геттер перед чтением атрибута.

```perl
$::construct->add_access('die unless $self->{attr};');
$::construct->{access} # -> 'die unless $self->{attr};'
```

## add_release($code, $unshift)
Добавляет код в геттер после чтения.

```perl
$::construct->add_release('$val = undef;');
$::construct->{release} # -> '$val = undef;'
```

## initializer
Генерирует код для инициализации фичи в конструкторе (`new`).

```perl

$::construct->initializer # -> << 'END'
		if (exists $value{my_feature}) {
			my $val = delete $value{my_feature};
			die if $val < 0;
			$self->{my_feature} = $val;
			$self->on_change;
		}
END
```

## destroyer
Генерирует код для деструктора.

```perl
$::construct->destroyer # -> <<'END'
		if (exists $self->{my_feature}) {
			eval {
				$self->{old} = $self->{attr};
			};
			warn $@ if $@;
		}
END
```

## accessor
Генерирует код акцессора.

```perl



$::construct->accessor # -> <<'END'
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
```

## reader
Генерирует код геттера.

```perl
$::construct->reader # -> <<'END'
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
```

## writer
Генерирует код сеттера.

```perl
$::construct->writer # -> <<'END'
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
```

## predicate
Генерирует код предиката.

```perl
$::construct->predicate # -> <<'END'
package My::Package {
	sub has_my_feature {
		my ($self) = @_;
		exists $self->{my_feature}
	}
}
END
```

## clearer
Генерирует код очистителя.

```perl
$::construct->clearer # -> <<'END'
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
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Meta::FeatureConstruct module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
