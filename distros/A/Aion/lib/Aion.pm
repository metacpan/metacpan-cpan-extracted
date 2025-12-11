package Aion;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "1.4";

use Aion::Types qw//;
use Aion::Meta::RequiresAnyFunction;
use Aion::Meta::Feature;
use Aion::Meta::RequiresFeature;
use Aion::Meta::Subroutine;

# Когда осуществлять проверки:
#   ro - только при выдаче
#   wo - только при установке
#   rw - при выдаче и уcтановке
#   no - никогда не проверять
use config ISA => 'rw';

sub export($@);

# Классы в которых подключён Aion с метаинформацией
our %META;

# Вызывается из другого пакета, для импорта данного
sub import {
	my (undef, $attr) = @_;
	my $pkg = caller;

	*{"$pkg\::DOES"} = \&does if \&does != $pkg->can('DOES');

	if($attr ne '-role') {  # Класс
		export $pkg, qw/extends/;
		*{"${pkg}::new"} = \&initialize;
	} else {	# Роль
		export $pkg, qw/requires req/;
	}

	export $pkg, qw/with has aspect does exactly/;

	# Метаинформация
	$META{$pkg} = {
		order => scalar keys %META,
		require => {},
		feature => {},
		subroutine => {},
		aspect => {
			is        => \&is_aspect,
			isa       => \&isa_aspect,
			coerce    => \&coerce_aspect,
			lazy      => \&lazy_aspect,
			default   => \&default_aspect,
			trigger   => \&trigger_aspect,
			release   => \&release_aspect,
			init_arg  => \&init_arg_aspect,
			accessor  => \&accessor_aspect,
			writer    => \&writer_aspect,
			reader    => \&reader_aspect,
			predicate => \&predicate_aspect,
			clearer   => \&clearer_aspect,
			cleaner   => \&cleaner_aspect,
			eon       => \&eon_aspect,
		}
	};

	eval "package $pkg; use Aion::Types; 1" or die;
}

# Удаляет добавленные символы
sub unimport {
	my $pkg = caller;
	
	undef &{"${pkg}::$_"} for qw/extends with aspect requires req/;
	
	eval "package $pkg; no Aion::Types; 1" or die;
}

# Экспортирует функции в пакет, если их там ещё нет
sub export($@) {
	my $pkg = shift;
	for my $sub (@_) {
		my $can = $pkg->can($sub);
		die "$pkg can $sub!" if $can && $can != \&$sub;
		*{"${pkg}::$sub"} = \&$sub unless $can;
	}
}

# Проверяет, что этот пакет инициализирован Aion
sub is_aion($) {
	my $pkg = shift;
	die "$pkg is'nt class of Aion!" if !exists $META{$pkg};
}

#@category Aspects

# ro, rw, + и -, *
sub is_aspect {
	my ($is, $feature) = @_;
	die "Use is => '{ro|rw|wo|no} {+|-} {*} {?} {!}'" if $is !~ /^(?<access>ro|rw|wo|no)?(?<require>[+-])?(?<weak>\*)?(?<has>\??)(?<clear>!?)\z/;

	my ($construct, $name) = @$feature{qw/construct name/};

	$construct->getter("die 'Feature $name cannot be get!';") if $+{access} ~~ [qw/wo no/];

	$construct->setter("die 'Feature $name cannot be set!';") if $+{access} ~~ [qw/ro no/];

	$construct->add_trigger("%(weaken)s") if $+{weak};

	$feature->{required} = 1, $construct->not_specified(' else { die "%(init_arg)s required!" }') if $+{require} eq '+';
	
	$feature->{excessive} = 1, $construct->initer('die "%(init_arg)s excessive!"') if $+{require} eq '-';

	$feature->{make_predicate} = 1 if $+{has};
	$feature->{make_clearer} = 1 if $+{clear};
}

# isa => Type
sub isa_aspect {
	my ($isa, $feature) = @_;
	my ($construct, $name) = @$feature{qw/construct name/};
	die "has: $name - isa maybe Aion::Type" unless UNIVERSAL::isa($isa, 'Aion::Type');

	$feature->{isa} = $isa;

	$construct->add_release("${\$feature->meta}\{isa}->validate(\$val, 'Get feature $name');") if ISA =~ /ro|rw/;

	$construct->add_preset("${\$feature->meta}\{isa}->validate(\$val, 'Set feature $name');") if ISA =~ /wo|rw/;
}

# coerce => 1
sub coerce_aspect {
	my ($coerce, $feature) = @_;

	return unless $coerce;

	die "coerce: isa not present!" unless $feature->{isa};

	$feature->{construct}->add_preset("\$val = ${\$feature->meta}\{isa}->coerce(\$val);", 1) if ISA =~ /wo|rw/;
}

our $pleroma;

# eon => $key
sub eon_aspect {
	my ($key, $feature) = @_;

	die "eon is not compatible with default!" if $feature->{opt}{default};

	require Aion::Pleroma, $pleroma = Aion::Pleroma->new unless $pleroma;

	if($key eq 1) {
		my $isa = $feature->{opt}{isa};
		$key = $isa && $isa->{name} eq "Object" && $isa->{args}[0]
			or die "use: has $feature->{name} => (isa => Object[...], eon => 1)";
	}
	elsif($key eq 2) {
		my $isa = $feature->{opt}{isa};
		$key = ($isa && $isa->{name} eq "Object" && $isa->{args}[0]
			or die "use: has $feature->{name} => (isa => Object[...], eon => 2)")
		. "#$feature->{name}";
		
	}

	default_aspect(sub { $pleroma->resolve($key) }, $feature);
}

# lazy => 1|0
sub lazy_aspect {
	my ($lazy, $feature) = @_;

	$feature->{lazy} = $lazy;
}

# default => value
sub default_aspect {
	my ($default, $feature) = @_;

	my $name = $feature->name;
	my $default_is_code = ref $default eq "CODE";

	if($default_is_code) {
		$feature->{builder} = $default;
	} else {
		$feature->{default} = $default;
		$feature->{opt}{isa}->validate($default, $name) if $feature->{opt}{isa};
	}

	if($feature->{opt}{lazy} // $default_is_code) {
		$feature->{lazy} = 1;

		if ($default_is_code) {
			$feature->construct->add_access("unless(%(has)s) {
				my \$val = ${\$feature->meta}\{builder}->(\$self);
				%(write)s
			}");
		} else {
			$feature->construct->add_access("unless(%(has)s) {
				my \$val = ${\$feature->meta}\{default};
				%(write)s
			}");
		}
	} else {
		if($default_is_code) {
			$feature->{construct}->not_specified(" else {
				my \$val = ${\$feature->meta}\{builder}->(\$self);
				%(write)s
			}");
		} else {
			$feature->{construct}->not_specified(" else {
				my \$val = ${\$feature->meta}\{default};
				%(write)s
			}");
		}
		
	}
}

# trigger => $sub
sub trigger_aspect {
	my ($trigger, $feature) = @_;

	$feature->{trigger} = $trigger;

	my $construct = $feature->{construct};

	$construct->add_preset("my \@old = %(has)s? %(get)s: ();");
	$construct->add_trigger("${\$feature->meta}\{trigger}->(\$self, \@old);");
}

# release => $sub
sub release_aspect {
	my ($release, $feature) = @_;

	$feature->{release} = $release;

	$feature->{construct}->add_release("${\$feature->meta}\{release}->(\$self, \$val);");
}

# init_arg => $name
sub init_arg_aspect {
	my ($init_arg, $feature) = @_;

	$feature->construct->init_arg($init_arg);
}

# accessor => $name
sub accessor_aspect {
	my ($accessor, $feature) = @_;

	$feature->construct->accessor_name($accessor);
}

# writer => $name
sub writer_aspect {
	my ($writer, $feature) = @_;

	$feature->{make_writer} = 1;
	$feature->construct->writer_name($writer);
}

# reader => $name
sub reader_aspect {
	my ($reader, $feature) = @_;

	$feature->{make_reader} = 1;
	$feature->construct->reader_name($reader);
}

# predicate => $name
sub predicate_aspect {
	my ($predicate, $feature) = @_;

	$feature->{make_predicate} = 1;
	$feature->construct->predicate_name($predicate);
}

# clearer => $name
sub clearer_aspect {
	my ($clearer, $feature) = @_;

	$feature->{make_clearer} = 1;
	$feature->construct->clearer_name($clearer);
}

# cleaner => $sub
sub cleaner_aspect {
	my ($cleaner, $feature) = @_;

	my ($cls, $construct) = @$feature{qw/pkg construct/};
	
	$feature->{cleaner} = $cleaner;

	$construct->add_cleaner("${\$feature->meta}\{cleaner}->(\$self);");
}

# Расширяет класс или роль
sub inherits($$@) {
	my $pkg = shift; my $is_with = shift;

	is_aion $pkg;

	my $FEATURE = $Aion::META{$pkg}{feature};
	my $ASPECT = $Aion::META{$pkg}{aspect};
	my $REQUIRE = $Aion::META{$pkg}{require} //= {};

	# Добавляем наследуемые свойства и атрибуты
	for my $module (@_) {
		eval "require $module" or die unless $module->can('with') || $module->can('new');

		if(my $meta = $Aion::META{$module}) {
			%$FEATURE = (%$FEATURE, %{$meta->{feature}}) ;
			%$ASPECT = (%$ASPECT, %{$meta->{aspect}});
			%$REQUIRE = (%$REQUIRE, %{$meta->{require}});
		}
	}

	my $import_name = $is_with? 'import_with': 'import_extends';
	for my $module (@_) {
		my $import = $module->can($import_name);
		$import->($module, $pkg) if $import;
	}

	return;
}

# Наследование классов
sub extends(@) {
	my $pkg = caller;

	is_aion $pkg;

	push @{"${pkg}::ISA"}, @_;
	push @{$Aion::META{$pkg}{extends}}, @_;

	unshift @_, $pkg, 0;
	goto &inherits;
}

# Расширение ролями
sub with(@) {
	my $pkg = caller;

	is_aion $pkg;

	push @{"${pkg}::ISA"}, @_;
	push @{$Aion::META{$pkg}{with}}, @_;

	unshift @_, $pkg, 1;
	goto &inherits;
}

sub requires(@) {
	my $pkg = caller;

	is_aion $pkg;

	#TODO: добавить проверку на существование
	$Aion::META{$pkg}{require}{$_} = Aion::Meta::RequiresAnyFunction->new(pkg => $pkg, name => $_) for @_;
}

# Требуется свойство
sub req(@) {
	my ($name) = @_;
	my $pkg = caller;

	is_aion $pkg;

	my $meta = $Aion::META{$pkg};

	#TODO: добавить проверку на существование по модулю и сравнить, что не одинаковы, если модули не совпадают
	# die "Feature `$name` already required!" if exists $meta->{require}{$name};

	$meta->{require}{$name} = Aion::Meta::RequiresFeature->new($pkg, @_);
	return;
}

# Добавляется аспект
sub aspect($$) {
	my ($name, $sub) = @_;
	my $pkg = caller;

	is_aion $pkg;

	my $ASPECT = $Aion::META{$pkg}{aspect};
	die "Aspect `$name` exists!" if exists $ASPECT->{$name};
	$ASPECT->{$name} = $sub;
	return;
}

# Ищет именно классы, а не роли
sub exactly {
    my ($self, $class) = @_;
    return '' if Aion::Types::ClassName->exclude($class);
	goto &UNIVERSAL::isa;
}


# Определяет - подключена ли роль
sub does {
	my ($self, $role) = @_;
	return '' if Aion::Types::ClassName->include($role);
	goto &UNIVERSAL::isa;
}

# Создаёт свойство
sub has(@) {
	my $property = shift;

	my $pkg = caller;
	is_aion $pkg;

	my %opt = @_;
	my $meta = $Aion::META{$pkg};

	# создаём фичи
	for my $name (ref $property? @$property: $property) {

		die "has: the method $name is already in the package $pkg"
			if $pkg->can($name) && !exists $meta->{feature}{$name};

		my $feature = Aion::Meta::Feature->new($pkg, $name, @_);

		my $require = delete $meta->{require}{$name};
		$require->compare($feature) if $require;

		my $overload = $meta->{feature}{$name};
		$overload->compare($feature) if $overload;
		
		$feature->mk_property;
		$meta->{feature}{$name} = $feature;
	}
	return;
}

# Инициализатор: закрывает класс и заменяется на конструктор
sub initialize {
	my ($cls) = @_;

	$cls = ref $cls || $cls;
	is_aion $cls;

	my $REQUIRE = $Aion::META{$cls}{require};
	my $FEATURE = $Aion::META{$cls}{feature};
	my $SUBROUTINE = $Aion::META{$cls}{subroutine};
	for my $key (keys %$REQUIRE) {
		my $require = $REQUIRE->{$key};
		
		if ($require->isa('Aion::Meta::RequiresAnyFunction')) {
			$require->compare($cls->can($key));
		} elsif ($require->isa('Aion::Meta::RequiresFeature')) {
			$require->compare($FEATURE->{$require->name});
		} else {
			$require->compare($SUBROUTINE->{$require->subname});
		}
	}

	%$REQUIRE = ();

	# TODO: очищать класс от вспомогательных функций
	#eval "package $cls; Aion->unimport; 1" or die;

	my $new = << 'END';
package %(cls)s {
	sub new {
		my ($cls, %value) = @_;
		$cls = ref $cls || $cls;
		my $self = bless {}, $cls;
		
%(initializers)s
		
		if(scalar keys %value) {
			my @fakekeys = sort keys %value;
			die "@fakekeys is'nt feature!" if @fakekeys == 1;
			local $" = ", ";
			die "@fakekeys is'nt features!"
		}

		return $self;
	}
}
END

    my @destroyers;
	my $initializers = join "", map {
		push @destroyers, $_->{construct}->destroyer if $_->{cleaner};
		$_->{construct}->initializer
	} sort { $a->{order} <=> $b->{order} } values %$FEATURE;
	
	my %var = (
		cls => $cls,
		initializers => $initializers,
	);
	
	$new =~ s/%\((\w+)\)s/$var{$1}/ge;

	eval $new;
	die if $@;

	if (@destroyers) {
		my $destroyer = << 'END';
package %(cls)s {
	sub DESTROY {
		my ($self) = @_;

		warn "${\ref $self}#${\Scalar::Util::id $self} destroy in global phase!" if ${^GLOBAL_PHASE} eq 'DESTRUCT';

%(destroyers)s
	}
}
END

		my %var = (
			cls => $cls,
			destroyers => join "", @destroyers,
		);
	
		$destroyer =~ s/%\((\w+)\)s/$var{$1}/ge;

		eval $destroyer;
		die $@ if $@;
	}
	
	goto &{"${cls}::new"};
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion - a postmodern object system for Perl 5, such as “Mouse”, “Moose”, “Moo”, “Mo” and “M”, but with improvements

=head1 VERSION

1.4

=head1 SYNOPSIS

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
	
	Calc->new(a => 1.1, b => 2)->result   # => 3.1

=head1 DESCRIPTION

Aion is OOP-framework for creating classes with B<features>, has B<aspects>, B<roles> and so on.

The properties declared through HAS are called B<features>.

And C<is>,C<isa>, C<default>, and so on inC<has> are called B<aspects>.

In addition to standard aspects, roles can add their own aspects using the B<aspect> subprogram.

The signature of the methods can be checked using the attribute C<:Isa(...)>.

=head1 SUBROUTINES IN CLASSES AND ROLES

C<Use Aion> imports types from the moduleC<Aion::Types> and the following subprograms:

=head2 has ($name, %aspects)

Creates a method for obtaining/setting the function (properties) of the class.

lib/Animal.pm file:

	package Animal;
	use Aion;
	
	has type => (is => 'ro+', isa => Str);
	has name => (is => 'rw-', isa => Str, default => 'murka');
	
	1;



	use lib "lib";
	use Animal;
	
	my $cat = Animal->new(type => 'cat');
	
	$cat->type   # => cat
	$cat->name   # => murka
	
	$cat->name("murzik");
	$cat->name   # => murzik

=head2 with

Adds to the module of the role. For each role, the C<import_with> method is called.

File lib/Role/Keys/Stringify.pm:

	package Role::Keys::Stringify;
	
	use Aion -role;
	
	sub keysify {
		my ($self) = @_;
		join ", ", sort keys %$self;
	}
	
	1;

File lib/Role/Values/Stringify.pm:

	package Role::Values::Stringify;
	
	use Aion -role;
	
	sub valsify {
		my ($self) = @_;
		join ", ", map $self->{$_}, sort keys %$self;
	}
	
	1;

File lib/Class/All/Stringify.pm:

	package Class::All::Stringify;
	
	use Aion;
	
	with q/Role::Keys::Stringify/;
	with q/Role::Values::Stringify/;
	
	has [qw/key1 key2/] => (is => 'rw', isa => Str);
	
	1;



	use lib "lib";
	use Class::All::Stringify;
	
	my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");
	
	$s->keysify	 # => key1, key2
	$s->valsify	 # => a, b

=head2 exactly ($package)

Checks that C<$package> is a super class for a given or this class itself.

Aion does not change the implementation of the C<isa> method and it finds both superclasses and roles (since both are added to the C<@ISA> package).

	package Ex::X { use Aion; }
	package Ex::A { use Aion; extends q/Ex::X/; }
	package Ex::B { use Aion; }
	package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }
	
	Ex::C->exactly("Ex::A") # -> 1
	Ex::C->exactly("Ex::B") # -> 1
	Ex::C->exactly("Ex::X") # -> 1
	Ex::C->exactly("Ex::X1") # -> ""
	Ex::A->exactly("Ex::X") # -> 1
	Ex::A->exactly("Ex::A") # -> 1
	Ex::X->exactly("Ex::X") # -> 1

=head2 does ($package)

Checks that C<$package> is a role that is used in a class or another role.

	package Role::X { use Aion -role; }
	package Role::A { use Aion -role; with qw/Role::X/; }
	package Role::B { use Aion -role; }
	package Ex::Z { use Aion; with qw/Role::A Role::B/; }
	
	Ex::Z->does("Role::A") # -> 1
	Ex::Z->does("Role::B") # -> 1
	Ex::Z->does("Role::X") # -> 1
	Role::A->does("Role::X") # -> 1
	Role::A->does("Role::X1") # -> ""
	Ex::Z->does("Ex::Z") # -> ""

=head2 aspect ($aspect => sub { ... })

Adds the aspect to C<has> in the current class and its classroom classes or the current role and applies its classes.

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
	
	$earth->moon # => Mars

The aspect is called every time it is indicated in C<has>.

The creator of the aspect has the parameters:

=over

=item * C<$value> — aspect value.

=item * C<$feature> - meta-object describing the feature (C<Aion::Meta::Feature>).

=item * C<$aspect_name> — aspect name.

=back

	package Example::Mars {
		use Aion;
	
		aspect lvalue => sub {
			my ($value, $feature, $aspect_name) = @_;
	
			$value # -> 1
			$aspect_name # => lvalue
	
			$feature->construct->add_attr(":lvalue");
		};
	
		has moon => (is => "rw", lvalue => 1);
	}

=head1 SUBROUTINES IN CLASSES

=head2 extends (@superclasses)

Expands the class with another class/classes. It causes from each inherited class the method of C<import_extends>, if it is in it.

	package World { use Aion;
	
		our $extended_by_this = 0;
	
		sub import_extends {
			my ($class, $extends) = @_;
			$extended_by_this ++;
	
			$class   # => World
			$extends # => Hello
		}
	}
	
	package Hello { use Aion;
		extends q/World/;
	
		$World::extended_by_this # -> 1
	}
	
	Hello->isa("World")	 # -> 1

=head2 new (%param)

The constructor.

=over

=item * Installs C<%param> for features.

=item * Checks that the parameters correspond to the features.

=item * Sets default values.

=back

	package NewExample { use Aion;
		has x => (is => 'ro', isa => Num);
		has y => (is => 'ro+', isa => Num);
		has z => (is => 'ro-', isa => Num);
	}
	
	NewExample->new(f => 5) # @-> y required!
	NewExample->new(f => 5, y => 10) # @-> f is'nt feature!
	NewExample->new(f => 5, p => 6, y => 10) # @-> f, p is'nt features!
	NewExample->new(z => 10, y => 10) # @-> z excessive!
	
	my $ex = NewExample->new(y => 8);
	
	$ex->x # @-> Get feature x must have the type Num. The it is undef!
	
	$ex = NewExample->new(x => 10.1, y => 8);
	
	$ex->x # -> 10.1

=head1 SUBROUTINES IN ROLES

=head2 requires (@subroutine_names)

Checks that classes using this role have the specified routines or features.

	package Role::Alpha { use Aion -role;
	
		requires qw/abc/;
	}
	
	package Omega1 { use Aion; with Role::Alpha; }
	
	eval { Omega1->new }; $@ # ~> Requires abc of Role::Alpha
	
	package Omega { use Aion;
		with Role::Alpha;
	
		sub abc { "abc" }
	}
	
	Omega->new->abc  # => abc

=head2 req ($name => @aspects)

Checks that classes using this role have the specified features with the specified aspects.

	package Role::Beta { use Aion -role;
	
		req x => (is => 'rw', isa => Num);
	}
	
	package Omega2 { use Aion; with Role::Beta; }
	
	eval { Omega2->new }; $@ # ~> Requires req x => \(is => 'rw', isa => Num\) of Role::Beta
	
	package Omega3 { use Aion;
		with Role::Beta;
	
		has x => (is => 'rw', isa => Num, default => 12);
	}
	
	Omega3->new->x  # -> 12

=head1 ASPECTS

C<use Aion> includes the following aspects in the module for use in C<has>:

=head2 is => $permissions

=over

=item * C<ro> - create only a gutter.

=item * C<wo> - create only a setter.

=item * C<rw> - Create getter and setter.

=back

By default - C<rw>.

Additional permits:

=over

=item * C<+> - the feature is required in the constructor parameters. C<+> is not used with C<->.

=item * C<-> - the feature cannot be installed via the constructor. '-' is not used with C<+>.

=item * C<*> - do not increment the value's reference counter (apply C<weaken> to the value after installing it in the feature).

=item * C<?> – create a predicate.

=item * C<!> – create clearer.

=back

	package ExIs { use Aion;
		has rw => (is => 'rw?!');
		has ro => (is => 'ro+');
		has wo => (is => 'wo-?');
	}
	
	ExIs->new # @-> ro required!
	ExIs->new(ro => 10, wo => -10) # @-> wo excessive!
	
	ExIs->new(ro => 10)->has_rw # -> ""
	ExIs->new(ro => 10, rw => 20)->has_rw # -> 1
	ExIs->new(ro => 10, rw => 20)->clear_rw->has_rw # -> ""
	
	ExIs->new(ro => 10)->ro  # -> 10
	
	ExIs->new(ro => 10)->wo(30)->has_wo # -> 1
	ExIs->new(ro => 10)->wo # @-> Feature wo cannot be get!
	ExIs->new(ro => 10)->rw(30)->rw  # -> 30

The function with C<*> does not hold the meaning:

	package Node { use Aion;
		has parent => (is => "rw*", isa => Maybe[Object["Node"]]);
	}
	
	my $root = Node->new;
	my $node = Node->new(parent => $root);
	
	$node->parent->parent   # -> undef
	undef $root;
	$node->parent   # -> undef
	
	# And by setter:
	$node->parent($root = Node->new);
	
	$node->parent->parent   # -> undef
	undef $root;
	$node->parent   # -> undef

=head2 isa => $type

Indicates the type, or rather - a validator, feature.

	package ExIsa { use Aion;
		has x => (is => 'ro', isa => Int);
	}
	
	ExIsa->new(x => 'str') # @-> Set feature x must have the type Int. The it is 'str'!
	ExIsa->new->x # @-> Get feature x must have the type Int. The it is undef!
	ExIsa->new(x => 10)->x			  # -> 10

For a list of validators, see L<Aion::Types>.

=head2 coerce => (1|0)

Includes type conversions.

	package ExCoerce { use Aion;
		has x => (is => 'ro', isa => Int, coerce => 1);
	}
	
	ExCoerce->new(x => 10.4)->x  # -> 10
	ExCoerce->new(x => 10.5)->x  # -> 11

=head2 default => $value

The default value is set in the designer if there is no parameter with the name of the feature.

	package ExDefault { use Aion;
		has x => (is => 'ro', default => 10);
	}
	
	ExDefault->new->x  # -> 10
	ExDefault->new(x => 20)->x  # -> 20

If C<$value> is a subroutine, then the subroutine is considered the feature's value constructor. Lazy evaluation is used if there is no C<lazy> attribute.

	my $count = 10;
	
	package ExLazy { use Aion;
		has x => (default => sub {
			my ($self) = @_;
			++$count
		});
	}
	
	my $ex = ExLazy->new;
	$count   # -> 10
	$ex->x   # -> 11
	$count   # -> 11
	$ex->x   # -> 11
	$count   # -> 11

=head2 lazy => (1|0)

The C<lazy> aspect enables or disables lazy evaluation of the default value (C<default>).

By default it is only enabled if the default is a subroutine.

	package ExLazy0 { use Aion;
		has x => (is => 'ro?', lazy => 0, default => sub { 5 });
	}
	
	my $ex0 = ExLazy0->new;
	$ex0->has_x # -> 1
	$ex0->x     # -> 5
	
	package ExLazy1 { use Aion;
		has x => (is => 'ro?', lazy => 1, default => 6);
	}
	
	my $ex1 = ExLazy1->new;
	$ex1->has_x # -> ""
	$ex1->x     # -> 6

=head2 eon => (1|2|$key)

The C<eon> aspect implements the B<Dependency Injection> pattern.

It associates a property with a service from the C<$Aion::pleroma> container.

The aspect value can be a service key, 1 or 2.

=over

=item * If 1 – then the key will be the package in C<< isa =E<gt> Object['Packet'] >>.

=item * If 2 – then the key will be “package#property”.

=back

File lib/CounterEon.pm:

	package CounterEon;
	#@eon ex.counter
	use Aion;
	
	has accomulator => (isa => Object['AccomulatorEon'], eon => 1);
	
	1;

File lib/AccomulatorEon.pm:

	package AccomulatorEon;
	#@eon
	use Aion;
	
	has power => (isa => Object['PowerEon'], eon => 2);
	
	1;

lib/PowerEon.pm file:

	package PowerEon;
	use Aion;
	
	has counter => (eon => 'ex.counter');
		
	#@eon
	sub power { shift->new }
	
	1;



	{
		use Aion::Pleroma;
		local $Aion::pleroma = Aion::Pleroma->new(ini => undef, pleroma => {
			'ex.counter' => 'CounterEon#new',
			AccomulatorEon => 'AccomulatorEon#new',
			'PowerEon#power' => 'PowerEon#power',
		});
		
		my $counter = $Aion::pleroma->get('ex.counter');
	
		$counter->accomulator->power->counter # -> $counter
	}

See L<Aion::Pleroma>.

=head2 trigger => $sub

C<$sub> is called after setting the property in the constructor (C<new>) or via a setter.

The etymology of C<trigger> is to let in.

	package ExTrigger { use Aion;
		has x => (trigger => sub {
			my ($self, $old_value) = @_;
			$self->y($old_value + $self->x);
		});
	
		has y => ();
	}
	
	my $ex = ExTrigger->new(x => 10);
	$ex->y	  # -> 10
	$ex->x(20);
	$ex->y	  # -> 30

=head2 release => $sub

C<$sub> is called before returning a property from an object via a getter.

The etymology of C<release> is to release.

	package ExRelease { use Aion;
		has x => (release => sub {
			my ($self, $value) = @_;
			$_[1] = $value + 1;
		});
	}
	
	my $ex = ExRelease->new(x => 10);
	$ex->x	  # -> 11

=head2 init_arg => $name

Changes the property name in the constructor.

	package ExInitArg { use Aion;
		has x => (is => 'ro+', init_arg => 'init_x');
	
		ExInitArg->new(init_x => 10)->x # -> 10
	}

=head2 accessor => $name

Changes the accessor name.

	package ExAccessor { use Aion;
		has x => (is => 'rw', accessor => '_x');
	
		ExAccessor->new->_x(10)->_x # -> 10
	}

=head2 writer => $name

Creates a setter named C<$name> for a property.

	package ExWriter { use Aion;
		has x => (is => 'ro', writer => '_set_x');
	
		ExWriter->new->_set_x(10)->x # -> 10
	}

=head2 reader => $name

Creates a getter named C<$name> for a property.

	package ExReader { use Aion;
		has x => (is => 'wo', reader => '_get_x');
	
		ExReader->new(x => 10)->_get_x # -> 10
	}

=head2 predicate => $name

Creates a predicate named C<$name> for a property. You can also create a predicate with a standard name using C<< is =E<gt> '?' >>.

	package ExPredicate { use Aion;
		has x => (predicate => '_has_x');
		
		my $ex = ExPredicate->new;
		$ex->_has_x        # -> ""
		$ex->x(10)->_has_x # -> 1
	}

=head2 clearer => $name

Creates a cleaner named C<$name> for a property. You can also create a cleaner with a standard name using C<< is =E<gt> '!' >>.

	package ExClearer { use Aion;
		has x => (is => '?', clearer => 'clear_x_');
	}
	
	my $ex = ExClearer->new;
	$ex->has_x	  # -> ""
	$ex->clear_x_;
	$ex->has_x	  # -> ""
	$ex->x(10);
	$ex->has_x	  # -> 1
	$ex->clear_x_;
	$ex->has_x	  # -> ""

=head2 cleaner => $sub

C<$sub> is called when the destructor or C<< $object-E<gt>clear_feature >> is called, but only if the feature is present (see C<< $object-E<gt>has_feature >>).

This aspect forces the creation of a predicate and a clearer.

	package ExCleaner { use Aion;
	
		our $x;
	
		has x => (is => '!', cleaner => sub {
			my ($self) = @_;
			$x = $self->x
		});
	}
	
	$ExCleaner::x		  # -> undef
	ExCleaner->new(x => 10);
	$ExCleaner::x		  # -> 10
	
	my $ex = ExCleaner->new(x => 12);
	
	$ExCleaner::x	  # -> 10
	$ex->clear_x;
	$ExCleaner::x	  # -> 12
	
	undef $ex;
	
	$ExCleaner::x	  # -> 12

=head1 ATTRIBUTES

C<Aion> adds universal attributes to the package.

=head2 :Isa (@signature)

The attribute C<Isa> checks the signature of the function.

	package MaybeCat { use Aion;
	
		sub is_cat : Isa(Me => Str => Bool) {
			my ($self, $anim) = @_;
			$anim =~ /(cat)/
		}
	}
	
	my $anim = MaybeCat->new;
	$anim->is_cat('cat')	# -> 1
	$anim->is_cat('dog')	# -> ""
	
	MaybeCat->is_cat("cat") # @-> Arguments of method `is_cat` must have the type Tuple[Me, Str].
	my @items = $anim->is_cat("cat") # @-> Returns of method `is_cat` must have the type Tuple[Bool].

The Isa attribute allows you to declare the required functions:

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
	
	Cat->new->is_cat # -> 1
	Dog->new->is_cat # -> 0
	Mouse->new # @-> Signature mismatch: is_cat(Me => Bool) of Anim <=> is_cat(Me => Int) of Mouse

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All Rights Reserved.
