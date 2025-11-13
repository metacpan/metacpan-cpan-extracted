package Aion::Meta::FeatureConstruct;

use common::sense;

use Aion::Meta::Util qw//;

Aion::Meta::Util::create_getters(qw/
	pkg name
	write read
	getvar ret
/);
Aion::Meta::Util::create_accessors(qw/
    init_arg
	set get has clear weaken
	accessor_name reader_name writer_name predicate_name clearer_name
	initer not_specified
	getter setter selfret
/);

#  Конструктор
sub new {
	my ($cls, $pkg, $name) = @_;

	bless {
		pkg => $pkg,
		name => $name,
		initializer => <<'END',
		if (exists $value{%(init_arg)s}) {
			%(initer)s
		}%(not_specified)s
END
		destroyer => <<'END',
		if (%(has)s) {
			eval {
				%(cleaner)s
			};
			warn $@ if $@;
		}
END
		accessor => <<'END',
package %(pkg)s {
	sub %(accessor_name)s%(attr)s {
		if (@_>1) {
			my ($self, $val) = @_;
			%(setter)s
			%(selfret)s
		} else {
			my ($self) = @_;
			%(getter)s
		}
	}
}
END
		reader => <<'END',
package %(pkg)s {
	sub %(reader_name)s {
		my ($self) = @_;
		%(read)s
	}
}
END
		writer => <<'END',
package %(pkg)s {
	sub %(writer_name)s {
		my ($self, $val) = @_;
		%(write)s
		%(selfret)s
	}
}
END
		predicate => <<'END',
package %(pkg)s {
	sub %(predicate_name)s {
		my ($self) = @_;
		%(has)s
	}
}
END
		clearer => <<'END',
package %(pkg)s {
	sub %(clearer_name)s {
		my ($self) = @_;
		if (%(has)s) {
			%(cleaner)s%(clear)s
		}
		%(clearret)s
	}
}
END
		accessor_name  => '%(name)s',
		reader_name    => '_get_%(name)s',
		writer_name    => '_set_%(name)s',
		attr           => '',
		write          => '%(preset)s%(set)s%(trigger)s',
		read           => '%(access)s%(getvar)s%(release)s%(ret)s',
		setter         => '%(write)s',
		getter         => '%(read)s',
		initer         => "%(initvar)s%(write)s",
		init_arg       => '%(name)s',
		initvar        => 'my $val = delete $value{%(init_arg)s};',
		not_specified  => '',
		preset         => '',
		set            => '$self->{%(name)s} = $val;',
		trigger        => '',
		selfret        => '$self',
		access         => '',
		getvar         => '%(get)s',
		get            => '$self->{%(name)s}',
		release        => '',
		ret            => '',
		predicate_name => 'has_%(name)s',
		has            => 'exists $self->{%(name)s}',
		clearer_name   => 'clear_%(name)s',
		clear          => 'delete $self->{%(name)s}',
		clearret       => '$self',
		cleaner        => '',
		weaken         => 'Scalar::Util::weaken(%(get)s);',
	}, ref $cls || $cls;
}

sub add_attr	{ shift->_expand('attr',	@_) }
sub add_preset  { shift->_expand('preset',  @_) }
sub add_trigger { shift->_expand('trigger', @_) }
sub add_cleaner { shift->_expand('cleaner', @_) }
sub add_access  { shift->_expand('access',  @_) }
sub add_release {
	my $self = shift;
	@$self{qw/getvar ret/} = ('my $val = %(get)s;', '$val') if $self->{ret} eq '';
	$self->_expand('release', @_)
}

sub _expand(@) {
	my ($self, $key, $code, $shift) = @_;

	if(ref $self->{$key}) {
		if($shift) { unshift @{$self->{$key}}, $code }
		else { push @{$self->{$key}}, $code }
	}
	elsif ($self->{$key} eq '') {
		$self->{$key} = $code;
	}
	else {
		$self->{$key} = $shift? [$code, $self->{$key}]: [$self->{$key}, $code];
	}
	
	$self
}

for my $key (qw/initializer destroyer accessor writer reader predicate clearer/) {
	*$key = sub {
		my ($self) = @_;
		_idents($self->_resolv($self->{$key}))
	}
}

sub _resolv {
	my ($self, $s) = @_;
	$s = join '', @$s if ref $s;
	$s =~ s{%\((\w*)\)s}{
		die "has: not construct `$1`\!" unless exists $self->{$1};
		$self->_resolv($self->{$1})
	}ge;
	$s
}

sub _idents {
	local ($_) = @_;
	my $indent;
	s{(^\t*)|;[\t ]*(\S)}{
		if(defined $1) { $indent = $1 } else { ";\n$indent$2" }
	}gme;
	$_
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Meta::FeatureConstruct - accessor, predicate, initializer and clearer

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Designed for constructing getters/setters from pieces of code.

=head1 SUBROUTINES

=head2 new ($pkg, $name)

Constructor.

=head2 pkg

The package to which the attribute belongs. Getter.

	$::construct->pkg # -> "My::Package"

=head2 name

Attribute name. Getter.

	$::construct->name # -> "my_feature"

=head2 write

Code for writing the value. Getter.

	$::construct->write # \> %(preset)s%(set)s%(trigger)s

=head2 read

Code to read the value. Getter.

	$::construct->read # \> %(access)s%(getvar)s%(release)s%(ret)s

=head2 getvar

Variable to receive the value. Getter.

	$::construct->getvar # \> %(get)s

=head2 ret

Value return code. Getter.

	$::construct->ret # -> ''

=head2 init_arg

The key is in the initialization hash. Accessor.

	$::construct->init_arg # \> %(name)s

=head2 set

Code for setting the value to the object hash. Accessor.

	$::construct->set # \> $self->{%(name)s} = $val;

=head2 get

Code for getting a value from an object hash. Accessor.

	$::construct->get # \> $self->{%(name)s}

=head2 has

Code for checking the existence of a value. Accessor.

	$::construct->has # \> exists $self->{%(name)s}

=head2 clear

Code for deleting a value. Accessor.

	$::construct->clear # \> delete $self->{%(name)s}

=head2 weaken

Link weakening code. Accessor.

	$::construct->weaken # \> Scalar::Util::weaken(%(get)s);

=head2 accessor_name

The name of the accessor method. Accessor.

	$::construct->accessor_name # \> %(name)s

=head2 reader_name

Reader method name. Accessor.

	$::construct->reader_name # \> _get_%(name)s

=head2 writer_name

Writer method name. Accessor.

	$::construct->writer_name # \> _set_%(name)s

=head2 predicate_name

Predicate method name. Accessor.

	$::construct->predicate_name # \> has_%(name)s

=head2 clearer_name

The name of the cleanser method. Accessor.

	$::construct->clearer_name # \> clear_%(name)s

=head2 initer

Attribute initialization code. Accessor.

	$::construct->initer # \> %(initvar)s%(write)s

=head2 not_specified

Initialization code if no value is specified. Accessor.

	$::construct->not_specified # -> ''

=head2 getter

Getter code in the accessor. Accessor.

	$::construct->getter # \> %(read)s

=head2 setter

Setter code in the accessor. Default: '%(write)s'.

	$::construct->setter # \> %(write)s

=head2 selfret

Return code from setter. Accessor.

	$::construct->selfret # \> $self

=head2 add_attr($code, $unshift)

Adds an attribute to the accessor.

	$::construct->add_attr(':bvalue');
	$::construct->{attr} # --> [':lvalue', ':bvalue']
	$::construct->add_attr(':a_value', 1);
	$::construct->{attr} # --> [':a_value', ':lvalue', ':bvalue']

=head2 add_preset($code, $unshift)

Adds a preset code before recording.

	$::construct->add_preset('die if $val < 0;', 1);
	$::construct->{preset} # -> 'die if $val < 0;'

=head2 add_trigger($code, $unshift)

Adds a trigger after recording.

	$::construct->add_trigger('$self->on_change;');
	$::construct->{trigger} # -> '$self->on_change;'

=head2 add_cleaner($code, $unshift)

Adds cleanup code before deletion.

	$::construct->add_cleaner('$self->{old} = $self->{attr};');
	$::construct->{cleaner} # -> '$self->{old} = $self->{attr};'

=head2 add_access($code, $unshift)

Adds code to the getter before reading the attribute.

	$::construct->add_access('die unless $self->{attr};');
	$::construct->{access} # -> 'die unless $self->{attr};'

=head2 add_release($code, $unshift)

Adds code to the getter after reading.

	$::construct->add_release('$val = undef;');
	$::construct->{release} # -> '$val = undef;'

=head2 initializer

Generates code to initialize a feature in the constructor (C<new>).

	
	$::construct->initializer # -> << 'END'
			if (exists $value{my_feature}) {
				my $val = delete $value{my_feature};
				die if $val < 0;
				$self->{my_feature} = $val;
				$self->on_change;
			}
	END

=head2 destroyer

Generates code for the destructor.

	$::construct->destroyer # -> <<'END'
			if (exists $self->{my_feature}) {
				eval {
					$self->{old} = $self->{attr};
				};
				warn $@ if $@;
			}
	END

=head2 accessor

Generates an accessor code.

	
	
	
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

=head2 reader

Generates getter code.

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

=head2 writer

Generates setter code.

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

=head2 predicate

Generates a predicate code.

	$::construct->predicate # -> <<'END'
	package My::Package {
		sub has_my_feature {
			my ($self) = @_;
			exists $self->{my_feature}
		}
	}
	END

=head2 clearer

Generates a purifier code.

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

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Meta::FeatureConstruct module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
