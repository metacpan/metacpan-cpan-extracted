package Aion;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.4";

use Scalar::Util qw/blessed weaken/;
use Aion::Types qw//;

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
	my ($cls, $attr) = @_;
	my $pkg = caller;

	*{"${pkg}::isa"} = \&isa if \&isa != $pkg->can('isa');

    if($attr ne '-role') {  # Класс
		export $pkg, qw/new extends/;
    } else {    # Роль
		export $pkg, qw/requires/;
    }

	export $pkg, qw/with upgrade has aspect does clear/;

    # Метаинформация
	$META{$pkg} = {
		order => scalar keys %META,
		feature => {},
		aspect => {
			is => \&is_aspect,
			isa => \&isa_aspect,
			coerce => \&coerce_aspect,
			default => \&default_aspect,
			trigger => \&trigger_aspect,
			release => \&release_aspect,
			clearer => \&clearer_aspect,
		}
	};

    eval "package $pkg; use Aion::Types; 1" or die;
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

# Экспортирует функции в пакет, если их там ещё нет
sub is_aion($) {
	my $pkg = shift;
	die "$pkg is'nt class of Aion!" if !exists $META{$pkg};
}

#@category Aspects

sub _weaken_init {
	my ($self, $feature) = @_;
	weaken $self->{$feature->{name}};
}

# ro, rw, + и -, *
sub is_aspect {
    my ($cls, $name, $is, $construct, $feature) = @_;
    die "Use is => '(ro|rw|wo|no)[+-]?[*]?'" if $is !~ /^(ro|rw|wo|no)[+-]?[*]?\z/;

    $construct->{get} = "die 'has: $name is $is (not get)'" if $is =~ /^(wo|no)/;

	if($is =~ /^(ro|no)/) {
    	$construct->{set} = "die 'has: $name is $is (not set)'";
	}
	elsif($is =~ /\*\z/) {
		$construct->{ret} = "; Scalar::Util::weaken(\$self->{$name})$construct->{ret}";
	}

    $feature->{required} = 1 if $is =~ /\+/;
    $feature->{excessive} = 1 if $is =~ /-/;
    push @{$feature->{init}}, \&_weaken_init if $is =~ /\*\z/;
}

# isa => Type
sub isa_aspect {
    my ($cls, $name, $isa, $construct, $feature) = @_;
    die "has: $name - isa maybe Aion::Type"
        if !UNIVERSAL::isa($isa, 'Aion::Type');

    $feature->{isa} = $isa;

    $construct->{get} = "\$Aion::META{'$cls'}{feature}{$name}{isa}->validate(do{$construct->{get}}, 'Get feature `$name`')" if ISA =~ /ro|rw/;

    $construct->{set} = "\$Aion::META{'$cls'}{feature}{$name}{isa}->validate(\$val, 'Set feature `$name`'); $construct->{set}" if ISA =~ /wo|rw/;
}

# coerce => 1
sub coerce_aspect {
    my ($cls, $name, $coerce, $construct, $feature) = @_;

	return unless $coerce;

	die "coerce: isa not present!" unless $feature->{isa};

    $construct->{coerce} = "\$val = \$Aion::META{'$cls'}{feature}{$name}{isa}->coerce(\$val); ";
    $construct->{set} = "%(coerce)s$construct->{set}"
}

# default => value
sub default_aspect {
    my ($cls, $name, $default, $construct, $feature) = @_;

    if(ref $default eq "CODE") {
        $feature->{lazy} = 1;
        *{"${cls}::${name}__DEFAULT"} = $default;

		$construct->{lazy_trigger} //= "";
		$construct->{lazy} = "\$self->{$name} = \$self->${name}__DEFAULT%(lazy_trigger)s if !exists \$self->{$name}; ";
        $construct->{get} = "%(lazy)s$construct->{get}";
    } else {
        $feature->{opt}{isa}->validate($default, $name) if $feature->{opt}{isa};
        $feature->{default} = $default;
    }
}

sub _trigger_init {
	my ($self, $feature) = @_;
	my $name = "$feature->{name}__TRIGGER";
	$self->$name;
}

# trigger => $sub
sub trigger_aspect {
	my ($cls, $name, $trigger, $construct, $feature) = @_;

	*{"${cls}::${name}__TRIGGER"} = $trigger;

	$construct->{set} = "my \$e = exists \$self->{$name}; my \$old = \$self->{$name}; $construct->{set}; \$self->${name}__TRIGGER(\$e? \$old: ())";
	$construct->{lazy_trigger} = ", \$self->${name}__TRIGGER";

	push @{$feature->{init}}, \&_trigger_init;
}

# release => $sub
sub release_aspect {
	my ($cls, $name, $release, $construct, $feature) = @_;

	*{"${cls}::${name}__RELEASE"} = $release;

	$construct->{get} = "my \$release = $construct->{get}; \$self->${name}__RELEASE(\$release); \$release";
}

# Если на фичах объекта есть clearer, то на него устанавливается этот деструктор
sub destroy {
	my ($self) = @_;

	my $feature_href = $Aion::META{ref $self}{feature};
	
	for my $feature (sort { $b->{order} <=> $a->{order} } values %$feature_href) {
		eval {
			my ($name, $clearer) = @$feature{qw/name clearer/};
			$clearer->($self) if defined $clearer and exists $self->{$name};
		};
		warn $@ if $@;
	}
}

# clearer => $sub
sub clearer_aspect {
	my ($cls, $name, $clearer, $construct, $feature) = @_;

	$feature->{clearer} = $clearer;
	*{"${cls}::DESTROY"} = \&destroy unless $cls->can('DESTROY');
	*{"${cls}::${name}__CLEARER"} = $clearer;
	
	die "Is DESTROY in Aion class ($cls): not set aion destroy!" if $cls->can('DESTROY') != \&destroy;
}

# Расширяет класс или роль
sub inherits($$@) {
    my $pkg = shift; my $with = shift;

	is_aion $pkg;

    my $FEATURE = $Aion::META{$pkg}{feature};
    my $ASPECT = $Aion::META{$pkg}{aspect};

    # Добавляем наследуемые свойства и атрибуты
	for my $module (@_) {
        eval "require $module" or die unless $module->can('with') || $module->can('new');

		if(my $meta = $Aion::META{$module}) {
			%$FEATURE = (%$FEATURE, %{$meta->{feature}}) ;
			%$ASPECT = (%$ASPECT, %{$meta->{aspect}});
		}
	}

    my $import_name = $with? 'import_with': 'import_extends';
    for my $module (@_) {
        my $import = $module->can($import_name);
        $import->($module, $pkg) if $import;

		if($with && exists $Aion::META{$module} && (my $requires = $Aion::META{$module}{requires})) {
			my @not_requires = grep { !$pkg->can($_) } @$requires;

			do { local $, = ", "; die "@not_requires requires!" } if @not_requires;
		}
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

# Требуются подпрограммы
sub requires(@) {
    my $pkg = caller;

	is_aion $pkg;

    push @{$Aion::META{$pkg}{requires}}, @_;
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

# Определяет - расширен ли класс
sub isa {
    my ($self, $class) = @_;

    my $pkg = ref $self || $self;

	return 1 if $class eq $pkg;

	my $meta = $Aion::META{$pkg};
    my $extends = $meta->{extends} // return "";

    return 1 if $class ~~ $extends;
    for my $extender (@$extends) {
        return 1 if $extender->isa($class);
    }

    return "";
}

# Определяет - подключена ли роль
sub does {
    my ($self, $role) = @_;

    my $pkg = ref $self || $self;
	my $meta = $Aion::META{$pkg};
	my $does = $meta->{with} // return "";

    return 1 if $role ~~ $does;
    for my $doeser (@$does) {
        return 1 if $doeser->can("does") && $doeser->does($role);
    }

    return "";
}

# Очищает переменные в объекте, возвращает себя
sub clear {
    my $self = shift;
	my $meta = $Aion::META{ref $self};
	for my $name (@_) {
		my $feature = $meta->{feature}{$name};
		$feature->{clearer}->($self) if $feature and $feature->{clearer} and exists $self->{$name};
	}
    delete @$self{@_};
    $self
}

# Создаёт свойство
sub has(@) {
	my $property = shift;

    return exists $property->{$_[0]} if blessed $property;

	my $pkg = caller;
	is_aion $pkg;

    my %opt = @_;
	my $meta = $Aion::META{$pkg};

	# атрибуты
	for my $name (ref $property? @$property: $property) {

		die "has: the method $name is already in the package $pkg"
            if $pkg->can($name) && !exists $meta->{feature}{$name};

        my %construct = (
            pkg => $pkg,
            name => $name,
			attr => '',
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
        );

        my $feature = {
            has => [@_],
            opt => \%opt,
            name => $name,
            construct => \%construct,
			order => scalar keys %{$meta->{feature}},
        };

        my $ASPECT = $meta->{aspect};
        for(my $i=0; $i<@_; $i+=2) {
            my ($aspect, $value) = @_[$i, $i+1];
            my $aspect_sub = $ASPECT->{$aspect};
            die "has: not exists aspect `$aspect`!" if !$aspect_sub;
            $aspect_sub->($pkg, $name, $value, \%construct, $feature);
        }

        my $sub = _resolv($construct{eval}, \%construct);
		eval $sub;
		die if $@;

        $feature->{sub} = $sub;
		$meta->{feature}{$name} = $feature;
	}
	return;
}

sub _resolv {
    my ($s, $construct) = @_;
    $s =~ s{%\((\w*)\)s}{
        die "has: not construct `$1`\!" unless exists $construct->{$1};
        _resolv($construct->{$1}, $construct);
    }ge;
    $s
}

# конструктор
sub new {
	my ($self, @errors) = create_from_params(@_);

	die join "", "has:\n\n", map "* $_\n", @errors if @errors;

	$self
}

# Устанавливает свойства и выдаёт объект и ошибки
sub create_from_params {
	my ($cls, %value) = @_;

	$cls = ref $cls || $cls;
	is_aion $cls;

	my $self = bless {}, $cls;

	my @init;
	my @required;
	my @errors;
    my $FEATURE = $Aion::META{$cls}{feature};

	while(my ($name, $feature) = each %$FEATURE) {

		if(exists $value{$name}) {
			my $val = delete $value{$name};

			if(!$feature->{excessive}) {
				$val = $feature->{coerce}->coerce($val) if $feature->{coerce};

				push @errors, $feature->{isa}->detail($val, "Feature $name")
                    if ISA =~ /w/ && $feature->{isa} && !$feature->{isa}->include($val);
				$self->{$name} = $val;
				push @init, $feature if $feature->{init};
			}
			else {
				push @errors, "Feature $name cannot set in new!";
			}
		} elsif($feature->{required}) {
            push @required, $name;
        } elsif(exists $feature->{default}) {
			$self->{$name} = $feature->{default};
			push @init, $feature if $feature->{init};
		}

	}

	for my $feature (@init) {
		for my $init (@{$feature->{init}}) {
			$init->($self, $feature);
		}
	}

	do {local $" = ", "; unshift @errors, "Features @required is required!"} if @required > 1;
	unshift @errors, "Feature @required is required!" if @required == 1;

	my @fakekeys = sort keys %value;
	unshift @errors, "@fakekeys is not feature!" if @fakekeys == 1;
	do {local $" = ", "; unshift @errors, "@fakekeys is not features!"} if @fakekeys > 1;

	return $self, @errors;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion - a postmodern object system for Perl 5, such as “Mouse”, “Moose”, “Moo”, “Mo” and “M”, but with improvements

=head1 VERSION

0.4

=head1 SYNOPSIS

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
	
	$s->keysify     # => key1, key2
	$s->valsify     # => a, b

=head2 isa ($package)

Checks that C<$package> is a super class for a given or this class itself.

	package Ex::X { use Aion; }
	package Ex::A { use Aion; extends q/Ex::X/; }
	package Ex::B { use Aion; }
	package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }
	
	Ex::C->isa("Ex::A") # -> 1
	Ex::C->isa("Ex::B") # -> 1
	Ex::C->isa("Ex::X") # -> 1
	Ex::C->isa("Ex::X1") # -> ""
	Ex::A->isa("Ex::X") # -> 1
	Ex::A->isa("Ex::A") # -> 1
	Ex::X->isa("Ex::X") # -> 1

=head2 does ($package)

Checks that C<$package> is a role that is used in a class or another role.

	package Role::X { use Aion -role; }
	package Role::A { use Aion; with qw/Role::X/; }
	package Role::B { use Aion; }
	package Ex::Z { use Aion; with qw/Role::A Role::B/ }
	
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
	        my ($cls, $name, $value, $construct, $feature) = @_;
	
	        $construct->{attr} .= ":lvalue";
	    };
	
	    has moon => (is => "rw", lvalue => 1);
	}
	
	my $earth = Example::Earth->new;
	
	$earth->moon = "Mars";
	
	$earth->moon # => Mars

The aspect is called every time it is indicated in C<has>.

The creator of the aspect has the parameters:

=over

=item * C<$cls> - a bag with C<has>.

=item * C<$name> is the name of feature.

=item * C<$value> is the meaning of the aspect.

=item * C<$construct> - a hash with fragments of the code for joining the object method.

=item * C<$feature> - a hash describing a feature.

=back

	package Example::Mars {
	    use Aion;
	
	    aspect lvalue => sub {
	        my ($cls, $name, $value, $construct, $feature) = @_;
	
	        $construct->{attr} .= ":lvalue";
	
	        $cls # => Example::Mars
	        $name # => moon
	        $value # -> 1
	        [sort keys %$construct] # --> [qw/attr eval get name pkg ret set sub/]
	        [sort keys %$feature] # --> [qw/construct has name opt order/]
	
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
	
	        $construct # --> $_construct
	
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
	
	        $feature # --> $_feature
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
	
	        $class      # => World
	        $extends    # => Hello
	    }
	}
	
	package Hello { use Aion;
	    extends q/World/;
	
	    $World::extended_by_this # -> 1
	}
	
	Hello->isa("World")     # -> 1

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
	
	eval { NewExample->new(f => 5) }; $@            # ~> f is not feature!
	eval { NewExample->new(n => 5, r => 6) }; $@    # ~> n, r is not features!
	eval { NewExample->new }; $@                    # ~> Feature y is required!
	eval { NewExample->new(z => 10) }; $@           # ~> Feature z cannot set in new!
	
	my $ex = NewExample->new(y => 8);
	
	eval { $ex->x }; $@  # ~> Get feature `x` must have the type Num. The it is undef
	
	$ex = NewExample->new(x => 10.1, y => 8);
	
	$ex->x # -> 10.1

=head1 SUBROUTINES IN ROLES

=head2 requires (@subroutine_names)

Checks that in classes using this role there are these subprograms or features.

	package Role::Alpha { use Aion -role;
	
	    sub in {
	        my ($self, $s) = @_;
	        $s =~ /[${\ $self->abc }]/
	    }
	
	    requires qw/abc/;
	}
	
	eval { package Omega1 { use Aion; with Role::Alpha; } }; $@ # ~> abc requires!
	
	package Omega { use Aion;
	    with Role::Alpha;
	
	    sub abc { "abc" }
	}
	
	Omega->new->in("a")  # -> 1

=head1 METHODS

=head2 has ($feature)

Checks that the property is established.

Features having C<< default =E<gt> sub {...} >> perform C<sub> during the first call of the Getter, that is: are delayed.

C<< $object-E<gt>has('feature') >> allows you to check that C<default> has not yet been called.

	package ExHas { use Aion;
	    has x => (is => 'rw');
	}
	
	my $ex = ExHas->new;
	
	$ex->has("x")   # -> ""
	
	$ex->x(10);
	
	$ex->has("x")   # -> 1

=head2 clear (@features)

He removes the keys of the feature from the object by previously calling them C<clearer> (if exists).

	package ExClearer { use Aion;
	    has x => (is => 'rw');
	    has y => (is => 'rw');
	}
	
	my $c = ExClearer->new(x => 10, y => 12);
	
	$c->has("x")   # -> 1
	$c->has("y")   # -> 1
	
	$c->clear(qw/x y/);
	
	$c->has("x")   # -> ""
	$c->has("y")   # -> ""

=head1 METHODS IN CLASSES

C<Use Aion> includes the following methods in the module:

=head2 new (%parameters)

The constructor.

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

=item * C<+> - feature is required in the parameters of the designer. C<+> is not used with C<->.

=item * C<-> - a feature cannot be installed through the constructor. '-' is not used with C<+>.

=item * C<*> - do not increase the counter of links to the value (apply C<weaken> to the value after installing it in a feature).

=back

	package ExIs { use Aion;
	    has rw => (is => 'rw');
	    has ro => (is => 'ro+');
	    has wo => (is => 'wo-');
	}
	
	eval { ExIs->new }; $@ # ~> \* Feature ro is required!
	eval { ExIs->new(ro => 10, wo => -10) }; $@ # ~> \* Feature wo cannot set in new!
	ExIs->new(ro => 10);
	ExIs->new(ro => 10, rw => 20);
	
	ExIs->new(ro => 10)->ro  # -> 10
	
	ExIs->new(ro => 10)->wo(30)->has("wo")  # -> 1
	eval { ExIs->new(ro => 10)->wo }; $@ # ~> has: wo is wo- \(not get\)
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
	
	eval { ExIsa->new(x => 'str') }; $@ # ~> \* Feature x must have the type Int. The it is 'str'
	eval { ExIsa->new->x          }; $@ # ~> Get feature `x` must have the type Int. The it is undef
	ExIsa->new(x => 10)->x              # -> 10

For a list of validators, see L<Aion:::Type>.

=head2 default => $value

The default value is set in the designer if there is no parameter with the name of the feature.

	package ExDefault { use Aion;
	    has x => (is => 'ro', default => 10);
	}
	
	ExDefault->new->x  # -> 10
	ExDefault->new(x => 20)->x  # -> 20

If C<$ Value> is a subprogram, then the subprogram is considered a designer of the meaning of the feature. Lazy calculation is used.

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

=head2 trigger => $sub

C<$sub> is called after installing the property in the constructor (C<new>) or through the setter.
Etymology - let in.

	package ExTrigger { use Aion;
	    has x => (trigger => sub {
	        my ($self, $old_value) = @_;
	        $self->y($old_value + $self->x);
	    });
	
	    has y => ();
	}
	
	my $ex = ExTrigger->new(x => 10);
	$ex->y      # -> 10
	$ex->x(20);
	$ex->y      # -> 30

=head2 release => $sub

C<$sub> is called before returning the property from the object through the gutter.
Etymology - release.

	package ExRelease { use Aion;
	    has x => (release => sub {
	        my ($self, $value) = @_;
	        $_[1] = $value + 1;
	    });
	}
	
	my $ex = ExRelease->new(x => 10);
	$ex->x      # -> 11

=head2 clearer => $sub

C<$sub> is called when the deructor is called orC<< $object-E<gt>clear("feature") ``, but only if there is a property (see >>$object->has(" feature ")`).

	package ExClearer { use Aion;
		
		our $x;
	
	    has x => (clearer => sub {
	        my ($self) = @_;
	        $x = $self->x
	    });
	}
	
	$ExClearer::x      	# -> undef
	ExClearer->new(x => 10);
	$ExClearer::x      	# -> 10
	
	my $ex = ExClearer->new(x => 12);
	
	$ExClearer::x      # -> 10
	$ex->clear('x');
	$ExClearer::x      # -> 12
	
	undef $ex;
	
	$ExClearer::x      # -> 12

=head1 ATTRIBUTES

C<Aion> adds universal attributes to the package.

=head2 Isa (@signature)

The attribute C<Isa> checks the signature of the function.

B<Attention>: Using the C<Isa> attribute slows down the program.

B<COUNCIL>: The use of the C<Isa> aspect for objects is more than enough to check the correctness of the object data.

	package Anim { use Aion;
	
	    sub is_cat : Isa(Object => Str => Bool) {
	        my ($self, $anim) = @_;
	        $anim =~ /(cat)/
	    }
	}
	
	my $anim = Anim->new;
	
	$anim->is_cat('cat')    # -> 1
	$anim->is_cat('dog')    # -> ""
	
	
	eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].
	eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion Module Is Copyright © 2023 Yaroslav O. Kosmina. Rusland. All Rights Reserved.
