# NAME

Aion - a postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements

# VERSION

0.1

# SYNOPSIS

```perl
package Calc {

    use Aion;

    has a => (is => 'ro+', isa => Num);
    has b => (is => 'ro+', isa => Num);
    has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');

    sub result {
        my ($self) = @_;
        eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
    }

}

Calc->new(a => 1.1, b => 2)->result   # => 3.1
```

# DESCRIPTION

Aion — OOP framework for create classes with **features**, has **aspects**, **roles** and so on.

Properties declared via `has` are called **features**.

And `is`, `isa`, `default` and so on in `has` are called **aspects**.

In addition to standard aspects, roles can add their own aspects using subroutine `aspect`.

# SUBROUTINES IN CLASSES AND ROLES

`use Aion` include in module types from `Aion::Types` and next subroutines:

## has ($name, %aspects)

Make method for get/set feature (property) of the class.

File lib/Animal.pm:
```perl
package Animal;
use Aion;

has type => (is => 'ro+', isa => Str);
has name => (is => 'rw-', isa => Str, default => 'murka');

1;
```

```perl
use lib "lib";
use Animal;

my $cat = Animal->new(type => 'cat');

$cat->type   # => cat
$cat->name   # => murka

$cat->name("murzik");
$cat->name   # => murzik
```

## with

Add to module roles. It call on each the role method `import_with`.

File lib/Role/Keys/Stringify.pm:
```perl
package Role::Keys::Stringify;

use Aion -role;

sub keysify {
    my ($self) = @_;
    join ", ", sort keys %$self;
}

1;
```

File lib/Role/Values/Stringify.pm:
```perl
package Role::Values::Stringify;

use Aion -role;

sub valsify {
    my ($self) = @_;
    join ", ", map $self->{$_}, sort keys %$self;
}

1;
```

File lib/Class/All/Stringify.pm:
```perl
package Class::All::Stringify;

use Aion;

with qw/Role::Keys::Stringify Role::Values::Stringify/;

has [qw/key1 key2/] => (is => 'rw', isa => Str);

1;
```

```perl
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

$s->keysify     # => key1, key2
$s->valsify     # => a, b
```

## isa ($package)

Check `$package` is the class what extended this class.

```perl
package Ex::X { use Aion; }
package Ex::A { use Aion; extends qw/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

Ex::C->isa("Ex::A") # -> 1
Ex::C->isa("Ex::B") # -> 1
Ex::C->isa("Ex::X") # -> 1
Ex::C->isa("Ex::X1") # -> ""
Ex::A->isa("Ex::X") # -> 1
Ex::A->isa("Ex::A") # -> 1
Ex::X->isa("Ex::X") # -> 1
```

## does ($package)

Check `$package` is the role what extended this class.

```perl
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
```

## aspect ($aspect => sub { ... })

It add aspect to `has` in this class or role, and to the classes, who use this role, if it role.

```perl
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
```

Aspect is called every time it is specified in `has`.

Aspect handler has parameters:

* `$cls` — the package with the `has`.
* `$name` — the feature name.
* `$value` — the aspect value.
* `$construct` — the hash with code fragments for join to the feature method.
* `$feature` — the hash present feature.

```perl
package Example::Mars {
    use Aion;

    aspect lvalue => sub {
        my ($cls, $name, $value, $construct, $feature) = @_;

        $construct->{attr} .= ":lvalue";

        $cls # => Example::Mars
        $name # => moon
        $value # -> 1
        [sort keys %$construct] # --> [qw/attr eval get name pkg ret set sub/]
        [sort keys %$feature] # --> [qw/construct has name opt/]

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
        };

        $feature # --> $_feature
    };

    has moon => (is => "rw", lvalue => 1);
}
```

# SUBROUTINES IN CLASSES

## extends (@superclasses)

Extends package other package. It call on each the package method `import_extends` if it exists.

```perl
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
    extends qw/World/;

    $World::extended_by_this # -> 1
}

Hello->isa("World")     # -> 1
```

## new (%param)

Constructor. 

* Set `%param` to features.
* Check if param not mapped to feature.
* Set default values.

```perl
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
```

# SUBROUTINES IN ROLES

## requires (@subroutine_names)

Check who in classes who use the role present the subroutines.

```perl
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
```

# METHODS

## has ($feature)

It check what property is set.

```perl
package ExHas { use Aion;
    has x => (is => 'rw');
}

my $ex = ExHas->new;

$ex->has("x")   # -> ""

$ex->x(10);

$ex->has("x")   # -> 1
```

## clear (@features)

Cleared the features.

```perl
package ExClear { use Aion;
    has x => (is => 'rw');
    has y => (is => 'rw');
}

my $c = ExClear->new(x => 10, y => 12);

$c->has("x")   # -> 1
$c->has("y")   # -> 1

$c->clear(qw/x y/);

$c->has("x")   # -> ""
$c->has("y")   # -> ""
```


# METHODS IN CLASSES

`use Aion` include in module next methods:

## new (%parameters)

The constructor.

# ASPECTS

`use Aion` include in module next aspects for use in `has`:

## is => $permissions

* `ro` — make getter only.
* `wo` — make setter only.
* `rw` — make getter and setter.

Default is `rw`.

Additional permissions:

* `+` — the feature is required. It is not used with `-`.
* `-` — the feature cannot be set in the constructor. It is not used with `+`.
* `*` — the value is reference and it maked weaken can be set.

```perl
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
```

Feature with `*` don't hold value:

```perl
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
```

## isa => $type

Set feature type. It validate feature value 

## default => $value

Default value set in constructor, if feature falue not present.

```perl
package ExDefault { use Aion;
    has x => (is => 'ro', default => 10);
}

ExDefault->new->x  # -> 10
ExDefault->new(x => 20)->x  # -> 20
```

If `$value` is subroutine, then the subroutine is considered a constructor for feature value. This subroutine lazy called where the value get.

```perl
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
```

## trigger => $sub

`$sub` called after the value of the feature is set (in `new` or in setter).

```perl
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
```

# ATTRIBUTES

Aion add universal attributes.

## Isa (@signature)

Attribute `Isa` check the signature the function where it called.

**WARNING**: use atribute `Isa` slows down the program.

**TIP**: use aspect `isa` on features is more than enough to check the correctness of the object data.

```perl
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
```

If use name of type in `@signature`, then call subroutine with this name from current package.

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
