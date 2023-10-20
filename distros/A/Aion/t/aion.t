use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion!aion/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion - a postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements
# 
# # VERSION
# 
# 0.1
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
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

::is scalar do {Calc->new(a => 1.1, b => 2)->result}, "3.1", 'Calc->new(a => 1.1, b => 2)->result   # => 3.1';

# 
# # DESCRIPTION
# 
# Aion — OOP framework for create classes with **features**, has **aspects**, **roles** and so on.
# 
# Properties declared via `has` are called **features**.
# 
# And `is`, `isa`, `default` and so on in `has` are called **aspects**.
# 
# In addition to standard aspects, roles can add their own aspects using subroutine `aspect`.
# 
# # SUBROUTINES IN CLASSES AND ROLES
# 
# `use Aion` include in module types from `Aion::Types` and next subroutines:
# 
# ## has ($name, %aspects)
# 
# Make method for get/set feature (property) of the class.
# 
# File lib/Animal.pm:
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
done_testing; }; subtest 'has ($name, %aspects)' => sub { 
use lib "lib";
use Animal;

my $cat = Animal->new(type => 'cat');

::is scalar do {$cat->type}, "cat", '$cat->type   # => cat';
::is scalar do {$cat->name}, "murka", '$cat->name   # => murka';

$cat->name("murzik");
::is scalar do {$cat->name}, "murzik", '$cat->name   # => murzik';

# 
# ## with
# 
# Add to module roles. It call on each the role method `import_with`.
# 
# File lib/Role/Keys/Stringify.pm:
#@> lib/Role/Keys/Stringify.pm
#>> package Role::Keys::Stringify;
#>> 
#>> use Aion -role;
#>> 
#>> sub keysify {
#>>     my ($self) = @_;
#>>     join ", ", sort keys %$self;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# File lib/Role/Values/Stringify.pm:
#@> lib/Role/Values/Stringify.pm
#>> package Role::Values::Stringify;
#>> 
#>> use Aion -role;
#>> 
#>> sub valsify {
#>>     my ($self) = @_;
#>>     join ", ", map $self->{$_}, sort keys %$self;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# File lib/Class/All/Stringify.pm:
#@> lib/Class/All/Stringify.pm
#>> package Class::All::Stringify;
#>> 
#>> use Aion;
#>> 
#>> with qw/Role::Keys::Stringify Role::Values::Stringify/;
#>> 
#>> has [qw/key1 key2/] => (is => 'rw', isa => Str);
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'with' => sub { 
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

::is scalar do {$s->keysify}, "key1, key2", '$s->keysify     # => key1, key2';
::is scalar do {$s->valsify}, "a, b", '$s->valsify     # => a, b';

# 
# ## isa ($package)
# 
# Check `$package` is the class what extended this class.
# 
done_testing; }; subtest 'isa ($package)' => sub { 
package Ex::X { use Aion; }
package Ex::A { use Aion; extends qw/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

::is scalar do {Ex::C->isa("Ex::A")}, scalar do{1}, 'Ex::C->isa("Ex::A") # -> 1';
::is scalar do {Ex::C->isa("Ex::B")}, scalar do{1}, 'Ex::C->isa("Ex::B") # -> 1';
::is scalar do {Ex::C->isa("Ex::X")}, scalar do{1}, 'Ex::C->isa("Ex::X") # -> 1';
::is scalar do {Ex::C->isa("Ex::X1")}, scalar do{""}, 'Ex::C->isa("Ex::X1") # -> ""';
::is scalar do {Ex::A->isa("Ex::X")}, scalar do{1}, 'Ex::A->isa("Ex::X") # -> 1';
::is scalar do {Ex::A->isa("Ex::A")}, scalar do{1}, 'Ex::A->isa("Ex::A") # -> 1';
::is scalar do {Ex::X->isa("Ex::X")}, scalar do{1}, 'Ex::X->isa("Ex::X") # -> 1';

# 
# ## does ($package)
# 
# Check `$package` is the role what extended this class.
# 
done_testing; }; subtest 'does ($package)' => sub { 
package Role::X { use Aion -role; }
package Role::A { use Aion; with qw/Role::X/; }
package Role::B { use Aion; }
package Ex::Z { use Aion; with qw/Role::A Role::B/ }

::is scalar do {Ex::Z->does("Role::A")}, scalar do{1}, 'Ex::Z->does("Role::A") # -> 1';
::is scalar do {Ex::Z->does("Role::B")}, scalar do{1}, 'Ex::Z->does("Role::B") # -> 1';
::is scalar do {Ex::Z->does("Role::X")}, scalar do{1}, 'Ex::Z->does("Role::X") # -> 1';
::is scalar do {Role::A->does("Role::X")}, scalar do{1}, 'Role::A->does("Role::X") # -> 1';
::is scalar do {Role::A->does("Role::X1")}, scalar do{""}, 'Role::A->does("Role::X1") # -> ""';
::is scalar do {Ex::Z->does("Ex::Z")}, scalar do{""}, 'Ex::Z->does("Ex::Z") # -> ""';

# 
# ## aspect ($aspect => sub { ... })
# 
# It add aspect to `has` in this class or role, and to the classes, who use this role, if it role.
# 
done_testing; }; subtest 'aspect ($aspect => sub { ... })' => sub { 
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

::is scalar do {$earth->moon}, "Mars", '$earth->moon # => Mars';

# 
# Aspect is called every time it is specified in `has`.
# 
# Aspect handler has parameters:
# 
# * `$cls` — the package with the `has`.
# * `$name` — the feature name.
# * `$value` — the aspect value.
# * `$construct` — the hash with code fragments for join to the feature method.
# * `$feature` — the hash present feature.
# 

package Example::Mars {
    use Aion;

    aspect lvalue => sub {
        my ($cls, $name, $value, $construct, $feature) = @_;

        $construct->{attr} .= ":lvalue";

::is scalar do {$cls}, "Example::Mars", '        $cls # => Example::Mars';
::is scalar do {$name}, "moon", '        $name # => moon';
::is scalar do {$value}, scalar do{1}, '        $value # -> 1';
::is_deeply scalar do {[sort keys %$construct]}, scalar do {[qw/attr eval get name pkg ret set sub/]}, '        [sort keys %$construct] # --> [qw/attr eval get name pkg ret set sub/]';
::is_deeply scalar do {[sort keys %$feature]}, scalar do {[qw/construct has name opt/]}, '        [sort keys %$feature] # --> [qw/construct has name opt/]';

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

::is_deeply scalar do {$construct}, scalar do {$_construct}, '        $construct # --> $_construct';

        my $_feature = {
            has => [is => "rw", lvalue => 1],
            opt => {
                is => "rw",
                lvalue => 1,
            },
            name => $name,
            construct => $_construct,
        };

::is_deeply scalar do {$feature}, scalar do {$_feature}, '        $feature # --> $_feature';
    };

    has moon => (is => "rw", lvalue => 1);
}

# 
# # SUBROUTINES IN CLASSES
# 
# ## extends (@superclasses)
# 
# Extends package other package. It call on each the package method `import_extends` if it exists.
# 
done_testing; }; subtest 'extends (@superclasses)' => sub { 
package World { use Aion;

    our $extended_by_this = 0;

    sub import_extends {
        my ($class, $extends) = @_;
        $extended_by_this ++;

::is scalar do {$class}, "World", '        $class      # => World';
::is scalar do {$extends}, "Hello", '        $extends    # => Hello';
    }
}

package Hello { use Aion;
    extends qw/World/;

::is scalar do {$World::extended_by_this}, scalar do{1}, '    $World::extended_by_this # -> 1';
}

::is scalar do {Hello->isa("World")}, scalar do{1}, 'Hello->isa("World")     # -> 1';

# 
# ## new (%param)
# 
# Constructor. 
# 
# * Set `%param` to features.
# * Check if param not mapped to feature.
# * Set default values.
# 
done_testing; }; subtest 'new (%param)' => sub { 
package NewExample { use Aion;
    has x => (is => 'ro', isa => Num);
    has y => (is => 'ro+', isa => Num);
    has z => (is => 'ro-', isa => Num);
}

::like scalar do {eval { NewExample->new(f => 5) }; $@}, qr!f is not feature\!!, 'eval { NewExample->new(f => 5) }; $@            # ~> f is not feature!';
::like scalar do {eval { NewExample->new(n => 5, r => 6) }; $@}, qr!n, r is not features\!!, 'eval { NewExample->new(n => 5, r => 6) }; $@    # ~> n, r is not features!';
::like scalar do {eval { NewExample->new }; $@}, qr!Feature y is required\!!, 'eval { NewExample->new }; $@                    # ~> Feature y is required!';
::like scalar do {eval { NewExample->new(z => 10) }; $@}, qr!Feature z cannot set in new\!!, 'eval { NewExample->new(z => 10) }; $@           # ~> Feature z cannot set in new!';

my $ex = NewExample->new(y => 8);

::like scalar do {eval { $ex->x }; $@}, qr!Get feature `x` must have the type Num. The it is undef!, 'eval { $ex->x }; $@  # ~> Get feature `x` must have the type Num. The it is undef';

$ex = NewExample->new(x => 10.1, y => 8);

::is scalar do {$ex->x}, scalar do{10.1}, '$ex->x # -> 10.1';

# 
# # SUBROUTINES IN ROLES
# 
# ## requires (@subroutine_names)
# 
# Check who in classes who use the role present the subroutines.
# 
done_testing; }; subtest 'requires (@subroutine_names)' => sub { 
package Role::Alpha { use Aion -role;

    sub in {
        my ($self, $s) = @_;
        $s =~ /[${\ $self->abc }]/
    }

    requires qw/abc/;
}

::like scalar do {eval { package Omega1 { use Aion; with Role::Alpha; } }; $@}, qr!abc requires\!!, 'eval { package Omega1 { use Aion; with Role::Alpha; } }; $@ # ~> abc requires!';

package Omega { use Aion;
    with Role::Alpha;

    sub abc { "abc" }
}

::is scalar do {Omega->new->in("a")}, scalar do{1}, 'Omega->new->in("a")  # -> 1';

# 
# # METHODS
# 
# ## has ($feature)
# 
# It check what property is set.
# 
done_testing; }; subtest 'has ($feature)' => sub { 
package ExHas { use Aion;
    has x => (is => 'rw');
}

my $ex = ExHas->new;

::is scalar do {$ex->has("x")}, scalar do{""}, '$ex->has("x")   # -> ""';

$ex->x(10);

::is scalar do {$ex->has("x")}, scalar do{1}, '$ex->has("x")   # -> 1';

# 
# ## clear (@features)
# 
# Cleared the features.
# 
done_testing; }; subtest 'clear (@features)' => sub { 
package ExClear { use Aion;
    has x => (is => 'rw');
    has y => (is => 'rw');
}

my $c = ExClear->new(x => 10, y => 12);

::is scalar do {$c->has("x")}, scalar do{1}, '$c->has("x")   # -> 1';
::is scalar do {$c->has("y")}, scalar do{1}, '$c->has("y")   # -> 1';

$c->clear(qw/x y/);

::is scalar do {$c->has("x")}, scalar do{""}, '$c->has("x")   # -> ""';
::is scalar do {$c->has("y")}, scalar do{""}, '$c->has("y")   # -> ""';

# 
# 
# # METHODS IN CLASSES
# 
# `use Aion` include in module next methods:
# 
# ## new (%parameters)
# 
# The constructor.
# 
# # ASPECTS
# 
# `use Aion` include in module next aspects for use in `has`:
# 
# ## is => $permissions
# 
# * `ro` — make getter only.
# * `wo` — make setter only.
# * `rw` — make getter and setter.
# 
# Default is `rw`.
# 
# Additional permissions:
# 
# * `+` — the feature is required. It is not used with `-`.
# * `-` — the feature cannot be set in the constructor. It is not used with `+`.
# * `*` — the value is reference and it maked weaken can be set.
# 
done_testing; }; subtest 'is => $permissions' => sub { 
package ExIs { use Aion;
    has rw => (is => 'rw');
    has ro => (is => 'ro+');
    has wo => (is => 'wo-');
}

::like scalar do {eval { ExIs->new }; $@}, qr!\* Feature ro is required\!!, 'eval { ExIs->new }; $@ # ~> \* Feature ro is required!';
::like scalar do {eval { ExIs->new(ro => 10, wo => -10) }; $@}, qr!\* Feature wo cannot set in new\!!, 'eval { ExIs->new(ro => 10, wo => -10) }; $@ # ~> \* Feature wo cannot set in new!';
ExIs->new(ro => 10);
ExIs->new(ro => 10, rw => 20);

::is scalar do {ExIs->new(ro => 10)->ro}, scalar do{10}, 'ExIs->new(ro => 10)->ro  # -> 10';

::is scalar do {ExIs->new(ro => 10)->wo(30)->has("wo")}, scalar do{1}, 'ExIs->new(ro => 10)->wo(30)->has("wo")  # -> 1';
::like scalar do {eval { ExIs->new(ro => 10)->wo }; $@}, qr!has: wo is wo- \(not get\)!, 'eval { ExIs->new(ro => 10)->wo }; $@ # ~> has: wo is wo- \(not get\)';
::is scalar do {ExIs->new(ro => 10)->rw(30)->rw}, scalar do{30}, 'ExIs->new(ro => 10)->rw(30)->rw  # -> 30';

# 
# Feature with `*` don't hold value:
# 

package Node { use Aion;
    has parent => (is => "rw*", isa => Maybe[Object["Node"]]);
}

my $root = Node->new;
my $node = Node->new(parent => $root);

::is scalar do {$node->parent->parent}, scalar do{undef}, '$node->parent->parent   # -> undef';
undef $root;
::is scalar do {$node->parent}, scalar do{undef}, '$node->parent   # -> undef';

# And by setter:
$node->parent($root = Node->new);

::is scalar do {$node->parent->parent}, scalar do{undef}, '$node->parent->parent   # -> undef';
undef $root;
::is scalar do {$node->parent}, scalar do{undef}, '$node->parent   # -> undef';

# 
# ## isa => $type
# 
# Set feature type. It validate feature value 
# 
# ## default => $value
# 
# Default value set in constructor, if feature falue not present.
# 
done_testing; }; subtest 'default => $value' => sub { 
package ExDefault { use Aion;
    has x => (is => 'ro', default => 10);
}

::is scalar do {ExDefault->new->x}, scalar do{10}, 'ExDefault->new->x  # -> 10';
::is scalar do {ExDefault->new(x => 20)->x}, scalar do{20}, 'ExDefault->new(x => 20)->x  # -> 20';

# 
# If `$value` is subroutine, then the subroutine is considered a constructor for feature value. This subroutine lazy called where the value get.
# 

my $count = 10;

package ExLazy { use Aion;
    has x => (default => sub {
        my ($self) = @_;
        ++$count
    });
}

my $ex = ExLazy->new;
::is scalar do {$count}, scalar do{10}, '$count   # -> 10';
::is scalar do {$ex->x}, scalar do{11}, '$ex->x   # -> 11';
::is scalar do {$count}, scalar do{11}, '$count   # -> 11';
::is scalar do {$ex->x}, scalar do{11}, '$ex->x   # -> 11';
::is scalar do {$count}, scalar do{11}, '$count   # -> 11';

# 
# ## trigger => $sub
# 
# `$sub` called after the value of the feature is set (in `new` or in setter).
# 
done_testing; }; subtest 'trigger => $sub' => sub { 
package ExTrigger { use Aion;
    has x => (trigger => sub {
        my ($self, $old_value) = @_;
        $self->y($old_value + $self->x);
    });

    has y => ();
}

my $ex = ExTrigger->new(x => 10);
::is scalar do {$ex->y}, scalar do{10}, '$ex->y      # -> 10';
$ex->x(20);
::is scalar do {$ex->y}, scalar do{30}, '$ex->y      # -> 30';

# 
# # ATTRIBUTES
# 
# Aion add universal attributes.
# 
# ## Isa (@signature)
# 
# Attribute `Isa` check the signature the function where it called.
# 
# **WARNING**: use atribute `Isa` slows down the program.
# 
# **TIP**: use aspect `isa` on features is more than enough to check the correctness of the object data.
# 
done_testing; }; subtest 'Isa (@signature)' => sub { 
package Anim { use Aion;

    sub is_cat : Isa(Object => Str => Bool) {
        my ($self, $anim) = @_;
        $anim =~ /(cat)/
    }
}

my $anim = Anim->new;

::is scalar do {$anim->is_cat('cat')}, scalar do{1}, '$anim->is_cat(\'cat\')    # -> 1';
::is scalar do {$anim->is_cat('dog')}, scalar do{""}, '$anim->is_cat(\'dog\')    # -> ""';


::like scalar do {eval { Anim->is_cat("cat") }; $@}, qr!Arguments of method `is_cat` must have the type Tuple\[Object, Str\].!, 'eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].';
::like scalar do {eval { my @items = $anim->is_cat("cat") }; $@}, qr!Returns of method `is_cat` must have the type Tuple\[Bool\].!, 'eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].';

# 
# If use name of type in `@signature`, then call subroutine with this name from current package.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
