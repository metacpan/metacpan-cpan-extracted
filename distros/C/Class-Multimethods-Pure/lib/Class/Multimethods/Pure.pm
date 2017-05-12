package Class::Multimethods::Pure;

use 5.006001;
use strict;
use warnings;
no warnings 'uninitialized';

use Carp;

our $VERSION = '0.13';

our %MULTI;
our %MULTIPARAM;

our $REGISTRY;
$REGISTRY = {
    multi =>      \%MULTI,
    multiparam => \%MULTIPARAM,
    install_wrapper => sub {
        my ($pkg, $name) = @_;
        no strict 'refs';
        no warnings 'redefine';
        *{"$pkg\::$name"} = make_wrapper($name, $REGISTRY);
    },
};

our $DEFAULT_CORE = 'Class::Multimethods::Pure::Method::Slow';

{
    # This env check is mostly for testing.  No, correction, it's only for
    # testing.  Don't use it.
    if (my $core = $ENV{CMMP_DEFAULT_MULTI_CORE}) {
        $DEFAULT_CORE = $core;
    }
}

sub process_multi {
    my $registry = shift;    # multi, multiparam, and install_wrapper
    my $name = shift or return;
    
    if (@_) {
        my @params;
        until (!@_ || ref $_[0] eq 'CODE') {
            if ($_[0] =~ /^-/) {
                my ($k, $v) = splice @_, 0, 2;
                $k =~ s/^-//;

                $registry->{multiparam}{$name}{$k} = $v;
            }
            else {
                my $type = shift;
                unless (ref $type) {
                    if (Class::Multimethods::Pure::Type::Unblessed->is_unblessed($type)) {
                        $type = Class::Multimethods::Pure::Type::Unblessed->new($type);
                    }
                    else {
                        $type = Class::Multimethods::Pure::Type::Package->new($type);
                    }
                }
                push @params, $type;
            }
        }
        
        return () unless @_;
        
        my $code = shift;

        my $multi = $registry->{multi}{$name} ||= 
                Class::Multimethods::Pure::Method->new(
                    Core    => $registry->{multiparam}{$name}{Core},
                    Variant => $registry->{multiparam}{$name}{Variant},
                );
        
        $multi->add_variant(\@params, $code);
    }

    my $pkg = caller 1;
    $registry->{install_wrapper}->($pkg, $name);
    
    @_;
}

sub make_wrapper {
    my ($name, $registry) = @_;
    my $method = \$registry->{multi}{$name};
    sub {
        my $call = $$method->can('call');
        unshift @_, $$method;
        goto &$call;
    };
}

# exports a multimethod with a given name and arguments
sub multi {
    if (process_multi($REGISTRY, @_)) {
        croak "Usage: multi name => (Arg1, Arg2, ...) => sub { code };";
    }
}

our @exports = qw<multi all any none subtype Any>;

sub import {
    my $class = shift;
    my $cmd   = shift;
    
    my $pkg = caller;

    if ($cmd eq 'multi') {
        while (@_ = process_multi($REGISTRY, @_)) { }
    }
    elsif ($cmd eq 'import') {
        for my $export (@_) {
            unless (grep { $_ eq $export } @exports) {
                croak "$export is not exported from " . __PACKAGE__;
            }
            
            no strict 'refs';
            *{"$pkg\::$export"} = \&{__PACKAGE__ . "::$export"};
        }
    }
    elsif (!defined $cmd) {
        for my $export (@exports) {
            no strict 'refs';
            *{"$pkg\::$export"} = \&{__PACKAGE__ . "::$export"};
        }
    }
    else {
        croak "Unknown command: $cmd";
    }
}

sub all(@) {
    Class::Multimethods::Pure::Type::Conjunction->new(
        Class::Multimethods::Pure::Type->promote(@_)
    );
}

sub any(@) {
    Class::Multimethods::Pure::Type::Disjunction->new(
        Class::Multimethods::Pure::Type->promote(@_)
    );
}

sub none(@) {
    Class::Multimethods::Pure::Type::Injunction->new(
        Class::Multimethods::Pure::Type->promote(@_)
    );
}

sub Any() {
    Class::Multimethods::Pure::Type::Any->new;
}

sub subtype($$) {
    Class::Multimethods::Pure::Type::Subtype->new(
        Class::Multimethods::Pure::Type->promote($_[0]), $_[1]
    );
}

package Class::Multimethods::Pure::Type;

use Carp;
use Scalar::Util qw<blessed>;

# The promote multimethod is where the logic is to turn the string "Foo::Bar"
# into a Type::Package object.
our $PROMOTE = Class::Multimethods::Pure::Method->new;

sub promote {
    my ($class, @types) = @_;
    map { $PROMOTE->call($_) } @types;
}

{
    # I put each subtype into a variable so that you can extend the subtypes easily.
    
    my $pkg = sub { "Class::Multimethods::Pure::Type::$_[0]"->new(@_[1..$#_]) };

    # Anything that is blessed is probably already a Type object
    our $PROMOTE_BLESSED = $pkg->('Subtype', $pkg->('Any'), sub { blessed $_[0] });
    $PROMOTE->add_variant([ $PROMOTE_BLESSED ] => sub { $_[0] });
    
    # ARRAY, HASH, etc. get an Unblessed type for unblessed references.
    our $PROMOTE_UNBLESSED = $pkg->('Subtype', $pkg->('Any'),
                                sub { Class::Multimethods::Pure::Type::Unblessed->is_unblessed($_[0]) });
    $PROMOTE->add_variant(
        [ $PROMOTE_UNBLESSED ] => sub { 
            Class::Multimethods::Pure::Type::Unblessed->new($_[0])
    });

    # Anything else gets turned into a package.
    $PROMOTE->add_variant(
        [ $pkg->('Any') ] => sub {
            Class::Multimethods::Pure::Type::Package->new($_[0])
    });
}

# The subset multimethod is the most important multi used in the core.  It
# determines whether the left class is a subset of the right class.
our $SUBSET = Class::Multimethods::Pure::Method::DumbCache->new;

sub subset {
    my ($self, $other) = @_;
    $SUBSET->call($self, $other);
}

sub equal {
    my ($self, $other) = @_;
    subset($self, $other) && subset($other, $self);
}

sub matches;
sub string;

# returns whether this type depends on anything other than the package
sub ref_cacheable { 0 }
# returns whether this type *could possibly* match an object in this package
# (keep in mind that you could implement this even if ref_cacheable is false)
sub ref_match     { 1 }

{   
    my $pkg = sub { Class::Multimethods::Pure::Type::Package->new(
                            'Class::Multimethods::Pure::' . $_[0]) };

    $SUBSET->add_variant(
        [ $pkg->('Type'), $pkg->('Type') ] => sub {
             my ($a, $b) = @_;
             $a == $b;
    });
    
    # If you change this, remember to change Type::Package::subset
    # which is used in the bootstrap.
    $SUBSET->add_variant( 
        [ $pkg->('Type::Package'), $pkg->('Type::Package') ] => sub {
             my ($a, $b) = @_;
             $a->name->isa($b->name);
     });
    
    $SUBSET->add_variant(
        [ $pkg->('Type::Unblessed'), $pkg->('Type::Unblessed') ] => sub {
             my ($a, $b) = @_;
             $a->name eq $b->name;
    });

    $SUBSET->add_variant(
        [ $pkg->('Type::Any'), $pkg->('Type::Normal') ] => sub { 0 });

    $SUBSET->add_variant(
        [ $pkg->('Type::Normal'), $pkg->('Type::Any') ] => sub { 1 });

    $SUBSET->add_variant(
        [ $pkg->('Type::Any'), $pkg->('Type::Any') ] => sub { 1 });

    $SUBSET->add_variant(
        [ $pkg->('Type::Subtype'), $pkg->('Type::Subtypable') ] => sub {
            my ($a, $b) = @_;
            $a->base->subset($b);
        });

    $SUBSET->add_variant(
        [ $pkg->('Type::Subtypable'), $pkg->('Type::Subtype') ] => sub { 0 });

    $SUBSET->add_variant(
        [ $pkg->('Type::Subtype'), $pkg->('Type::Subtype') ] => sub {
            my ($a, $b) = @_;
            $a->base->subset($b) || 
                $a->base->subset($b->base) && $a->condition == $b->condition;
        });
    
    $SUBSET->add_variant(
        [ $pkg->('Type::Junction'), $pkg->('Type') ] => sub {
             my ($a, $b) = @_;
             $a->logic(map { $_->subset($b) } $a->values);
    });

    $SUBSET->add_variant(
        [ $pkg->('Type'), $pkg->('Type::Junction') ] => sub {
             my ($a, $b) = @_;
             $b->logic(map { $a->subset($_) } $b->values);
    });

    $SUBSET->add_variant(
        [ $pkg->('Type::Junction'), $pkg->('Type::Junction') ] => sub {
             my ($a, $b) = @_;
             # just like (Junction, Type)
             $a->logic(map { $_->subset($b) } $a->values);
     });
}

package Class::Multimethods::Pure::Type::Normal;

# Non-junctive thingies
use base 'Class::Multimethods::Pure::Type';

package Class::Multimethods::Pure::Type::Subtypable;

use base 'Class::Multimethods::Pure::Type::Normal';

package Class::Multimethods::Pure::Type::Package;

# A regular package type
use base 'Class::Multimethods::Pure::Type::Subtypable';

use Scalar::Util qw<blessed>;

sub new {
    my ($class, $package) = @_;
    bless {
        name => $package,
    } => ref $class || $class;
}

# This is overridden for bootstrapping purposes.  If you change
# logic here, you should change it in the multimethod above
# too.
sub subset {
    my ($self, $other) = @_;
    
    if (ref $self eq __PACKAGE__ && ref $other eq __PACKAGE__) {
        $self->name->isa($other->name);
    }
    else {
        $self->SUPER::subset($other);
    }
}

sub name {
    my ($self) = @_;
    $self->{name};
}

sub matches {
    my ($self, $obj) = @_;
    blessed($obj) ? $obj->isa($self->name) : 0;
}

sub string {
    my ($self) = @_;
    $self->name;
}

sub ref_cacheable { 1 }

sub ref_match {
    my ($self, $package) = @_;
    $package->isa($self->name);
}

package Class::Multimethods::Pure::Type::Unblessed;

# SCALAR, ARRAY, etc.
use base 'Class::Multimethods::Pure::Type::Subtypable';
use Carp;

our %SPECIAL = (
    SCALAR => 1,
    ARRAY  => 1,
    HASH   => 1,
    CODE   => 1,
    REF    => 1,
    GLOB   => 1,
    LVALUE => 1,
    IO     => 1,
    FORMAT => 1,
    Regexp => 1,
);

sub is_unblessed {
    my ($class, $name) = @_;
    $SPECIAL{$name};
}

sub new {
    my ($class, $name) = @_;
    croak "$name is not a valid unblessed type" 
        unless $SPECIAL{$name};
    bless {
        name => $name,
    } => ref $class || $class;
}

sub name {
    my ($self) = @_;
    $self->{name};
}

sub matches {
    my ($self, $obj) = @_;
    $self->name eq ref $obj;
}

sub string {
    my ($self) = @_;
    $self->name;
}

sub ref_cacheable { 1 }

sub ref_match {
    my ($self, $package) = @_;
    $self->name eq $package;
}

package Class::Multimethods::Pure::Type::Any;

# Anything whatever

use base 'Class::Multimethods::Pure::Type::Normal';

sub new {
    my ($class) = @_;
    bless { } => ref $class || $class;
}

sub matches {
    my ($self, $obj) = @_;
    1;
}

sub string {
    my ($self) = @_;
    "Any";
}

sub ref_cacheable { 1 }

sub ref_match { 1 }

package Class::Multimethods::Pure::Type::Subtype;

# A restricted type

use base 'Class::Multimethods::Pure::Type::Subtypable';

sub new {
    my ($class, $base, $condition) = @_;
    bless {
        base => $base,
        condition => $condition,
    } => ref $class || $class;
}

sub base {
    my ($self) = @_;
    $self->{base};
}

sub condition {
    my ($self) = @_;
    $self->{condition};
}

sub matches {
    my ($self, $obj) = @_;
    $self->base->matches($obj) && $self->condition->($obj);
}

sub string {
    my ($self) = @_;
    "where(" . $self->base->string . ", {@{[$self->condition]}})";
}

sub ref_cacheable { 0 }

sub ref_match {
    my ($self, $package) = @_;
    $self->base->ref_match($package);
}

package Class::Multimethods::Pure::Type::Junction;

# Any junction type

use base 'Class::Multimethods::Pure::Type';

sub new {
    my ($class, @types) = @_;
    bless {
        values => \@types,
    } => ref $class || $class;
}

sub values {
    my ($self) = @_;
    @{$self->{values}};
}

sub matches {
    my ($self, $obj) = @_;
    $self->logic(map { $_->matches($obj) } $self->values);
}

sub ref_cacheable {
    my ($self) = @_;
    for ($_->values) {
        return 0 unless $_->ref_cacheable;
    }
    return 1;
}

sub ref_match {
    my ($self, $package) = @_;
    $self->logic(map { $_->ref_match($package) } $self->values);
}

sub logic;  # takes a list of true/false values and returns
            # the boolean evaluation of them

package Class::Multimethods::Pure::Type::Disjunction;

# An any type
use base 'Class::Multimethods::Pure::Type::Junction';

sub logic {
    my ($self, @values) = @_;
    for (@values) {
        return 1 if $_;
    }
    return 0;
}

sub string {
    my ($self) = @_;
    'any(' . join(', ', map { $_->string } $self->values) . ')';
}

package Class::Multimethods::Pure::Type::Conjunction;

# An all type
use base 'Class::Multimethods::Pure::Type::Junction';

sub logic {
    my ($self, @values) = @_;
    for (@values) {
        return 0 unless $_;
    }
    return 1;
}

sub string {
    my ($self) = @_;
    'all(' . join(', ', map { $_->string } $self->values) . ')';
}

package Class::Multimethods::Pure::Type::Injunction;
# The none() type has some very, very strange behavior when you think
# about it.  In particular, note that none() (with no arguments) is
# at both the top and bottom of the type lattice.  Perhaps none()
# should not be allowed, or should require arguments.

# A none type
use base 'Class::Multimethods::Pure::Type::Junction';

sub logic {
    my ($self, @values) = @_;
    for (@values) {
        return 0 if $_;
    }
    return 1;
}

sub string {
    my ($self) = @_;
    'none(' . join(', ', map { $_->string } $self->values) . ')';
}

package Class::Multimethods::Pure::Variant;

use Carp;

sub new {
    my ($class, %o) = @_;
    bless {
        params => $o{params} || croak("Multi needs a list of 'params' types"),
        code => $o{code} || croak("Multi needs a 'code'ref"),
    } => ref $class || $class;
}

sub params {
    my ($self) = @_;
    @{$self->{params}};
}

sub param {
    my ($self, $param) = @_;
    $self->{params}[$param];
}

sub code {
    my ($self) = @_;
    $self->{code};
}

sub less {
    my ($a, $b) = @_;

    my @args = $a->params;
    my @brgs = $b->params;
    return 1 if @brgs < @args;
    return 0 if @args < @brgs;
    
    my $proper = 0;
    for my $i (0..$#args) {
        my $cmp = $args[$i]->subset($brgs[$i]);
        return 0 unless $cmp;
        if ($cmp && !$proper) {
            $proper = !$brgs[$i]->subset($args[$i]);
        }
    }

    return $proper;
}

sub matches {
    my ($self, $args) = @_;
    
    my @params = $self->params;
    return 0 if @$args < @params;
    
    for my $i (0..$#params) {
        unless ($params[$i]->matches($args->[$i])) {
            return 0;
        }
    }
    return 1;
}

sub param_ref_match {
    my ($self, $param, $package) = @_;
    $self->param($param)->ref_match($package);
}

sub string {
    my ($self) = @_;
    "(" . join(', ', map { $_->string } $self->params) . ")";
}

package Class::Multimethods::Pure::Method;

use Carp;

sub new {   # this needs to be overridden by subclasses
    my ($class, %opt) = @_;
    my $core = $opt{Core} || $Class::Multimethods::Pure::DEFAULT_CORE;
    
    if ($core->can('new')) {
        return $core->new(%opt);
    }
    
    $core = "Class::Multimethods::Pure::Method::$core";
    if ($core->can('new')) {
        return $core->new(%opt);
    }

    croak "Multimethod core $opt{Core} doesn't exist!";
}

sub call {
    my $self = shift;

    my $code = $self->find_variant(\@_)->code;
    goto &$code;
}

package Class::Multimethods::Pure::Method::Slow;

use base 'Class::Multimethods::Pure::Method';
use Carp;

sub new {
    my ($class, %o) = @_;
    bless {
        variants => [],
        Variant => $o{Variant} || 'Class::Multimethods::Pure::Variant',
    } => ref $class || $class;
}

sub add_variant {
    my ($self, $params, $code) = @_;
    
    push @{$self->{variants}}, 
        $self->{Variant}->new(params => $params,
                              code => $code);
}

sub variants {
    my ($self) = @_;
    @{$self->{variants}};
}

sub find_variant {
    my ($self, $args) = @_;
    
    my @cand;
    VARIANT:
    for my $variant (@{$self->{variants}}) {
        if ($variant->matches($args)) {
            for (@cand) {
                if ($_->less($variant)) {
                    # we're dominated: don't enter the list
                    next VARIANT;
                }
            }
            # okay, we're in
            for (my $i = 0; $i < @cand; $i++) {
                if ($variant->less($cand[$i])) {
                    # we dominate this variant: take it out of the list
                    splice @cand, $i, 1;
                    $i--;
                }
            }
            push @cand, $variant;
        }
    }

    if (@cand == 1) {
        return $cand[0];
    }
    elsif (@cand == 0) {
        croak "No method found for args (@$args)";
    }
    else {
        croak "Ambiguous method call for args (@$args):\n" .
            join '', map { "    " . $_->string . "\n" } @cand;
    }
}

package Class::Multimethods::Pure::Method::DumbCache;
# This dispatcher is the most presumptuous dispatcher there is.  It can
# optimize the simplest cases.  It will be faster for methods which:
#   * Don't use subtypes
#   * Have a fixed arity
# It will be slower otherwise.  Also it is a memory guzzler.  The more
# different kinds of objects you call it with, the more memory it guzzles.  So
# if you're subclassing a lot, avoid this dispatcher.

use base 'Class::Multimethods::Pure::Method::Slow';
use Carp;

sub new {
    my ($class, %o) = @_;
    my $self = $class->SUPER::new(%o);
    $self->{cache} = {};
    $self->{can_cache} = 1;
    $self->{arity} = undef;
    $self;
}

sub add_variant {
    my ($self, $params, $code) = @_;
    $self->SUPER::add_variant($params, $code);
    $self->{cache} = {};
    $self->{can_cache} = 1;
    $self->{arity} = undef;
    
    # Find out if we should even try caching
    VARIANT:
    for my $var ($self->variants) {
        my @params = $var->params;
        unless (defined $self->{arity}) {
            $self->{arity} = @params;
        }
        else {
            unless ($self->{arity} == @params) {
                $self->{can_cache} = 0;
                last VARIANT;
            }
        }

        for ($var->params) {
            unless ($_->ref_cacheable) {
                $self->{can_cache} = 0;
                last VARIANT;
            }
        }
    }
}

sub find_variant {
    my ($self, $args) = @_;
    if ($self->{can_cache}) {
        if (@$args < $self->{arity}) {
            croak "Not enough arguments to multimethod";
        }
        
        my $idx = join $;, map { ref } @$args[0..$self->{arity}-1];
        if (my $var = $self->{cache}{$idx}) {
            return $var;
        }
        else {
            return $self->{cache}{$idx} = $self->SUPER::find_variant($args);
        }
    }
    else {
        return $self->SUPER::find_variant($args);
    }
}

package Class::Multimethods::Pure::Method::DecisionTree;

use base 'Class::Multimethods::Pure::Method';
use Carp;

sub new {
    my ($class, %opt) = @_;
    bless {
        variants => [],
        find_variant => undef,
        Variant  => $opt{Variant} || 'Class::Multimethods::Pure::Variant',
    } => ref $class || $class;
}

sub add_variant {
    my ($self, $params, $code) = @_;

    push @{$self->{variants}},
        $self->{Variant}->new(params => $params,
                              code   => $code);

    undef $self->{find_variant};
}

sub variants {
    my ($self) = @_;
    @{$self->{variants}};
}

sub find_variant {
    my ($self, $args) = @_;
    $self->_compile->($args);
}

sub _compile {
    my ($self) = @_;
    return $self->{find_variant} if defined $self->{find_variant};
    
    my $tree = $self->_make_tree([$self->_all_conditions], [$self->_make_condmap]);
    my $code = $self->_compile_tree($tree, 0);
    
    $self->{find_variant} = $code;
}

sub _compile_tree {
    my ($self, $tree) = @_;
    
    if ($tree->{node_type} eq 'unique') {
        my $variant = $self->{variants}[$tree->{variantno}];
        return sub {
            $variant;
        };
    }
    if ($tree->{node_type} eq 'none_found') {
        return sub {
            my ($args) = @_; 
            croak "No method found for args (@$args)";
        };
    }
    if ($tree->{node_type} eq 'ambiguous') {
        return sub {
            my ($args) = @_;
            my @variants = @{$self->{variants}}[@{$tree->{variants}}];
            croak "Ambiguous method call for args (@$args):\n" .
                join '', map { "    " . $_->string . "\n" } @variants;
        }
    }
    if ($tree->{node_type} eq 'branch') {
        my $position  = $tree->{cond}{position};
        my $type      = $tree->{cond}{type};
        my $good  = $self->_compile_tree($tree->{good});
        my $bad   = $self->_compile_tree($tree->{bad});
        return sub {
            if (exists $_[0][$position] && $type->matches($_[0][$position])) {
                goto &$good;
            }
            else {
                goto &$bad;
            }
        };
    }

    die "Unknown node type $tree->{node_type}";
}

sub _reduce_condmap {
    my ($self, $condmap) = @_;
    
    my @ret = @$condmap;
    for (my $i = 0; $i < @ret; $i++) {
        for (my $j = 0; $j < @ret; $j++) {
            if ($self->{variants}[$ret[$j]{variantno}]
                ->less($self->{variants}[$ret[$i]{variantno}])) {

                splice @ret, $i, 1;
                $i--;
                last;
            }
        }
    }

    \@ret;
}

sub _make_tree {
    my ($self, $conds, $condmap) = @_;

    {
        my $rcmap = $self->_reduce_condmap($condmap);
        
        if (@$rcmap == 0) {
            return {
                node_type => 'none_found',
            };
        }

        if (@$conds == 0) {
            if (@$rcmap == 1) {
                return {
                    node_type => 'unique',
                    variantno => $rcmap->[0]{variantno},
                };
            }
            if (@$rcmap > 1) {
                return {
                    node_type => 'ambiguous',
                    variants => [ map { $_->{variantno} } @$rcmap ],
                };
            }
        }
    }
    
    my $bestbalance = 1e999;
    my $bestcond;
    for my $cond (0..$#$conds) {
        my (@good, @bad);
        for (@$condmap) {
            my $bits = $_->{cond}->($conds->[$cond]);
            if ($bits & 0b01) {
                push @good, $_;
            }
            if ($bits & 0b10) {
                push @bad, $_;
            }
        }

        my $balance = abs(@good - @$conds/2) + abs(@bad - @$conds/2);
        if ($balance < $bestbalance) {
            $bestbalance = $balance;
            $bestcond = [ $cond, \@good, \@bad ];
        }
    }

    die "Couldn't find best condition for some reason" unless defined $bestcond;

    my $newconds = [ @$conds ];
    splice @$newconds, $bestcond->[0], 1;

    return {
        node_type => 'branch',
        cond => $conds->[$bestcond->[0]],
        good => $self->_make_tree($newconds, $bestcond->[1]),
        bad  => $self->_make_tree($newconds, $bestcond->[2]),
    };
}

sub _make_condmap {
    my ($self) = @_;

    map { 
        { variantno => $_, cond => $self->_make_condition($self->{variants}[$_]) } 
    } 0..@{$self->{variants}}-1;
}

sub _make_condition {
    my ($self, $variant, $childrenq) = @_;

    my @params = $variant->params;
    my @conds;

    # we return a bitfield:
    #   bit 0 = consistent with cond
    #   bit 1 = consistent with not cond
    
    for my $i (0..$#params) {
        push @conds, sub { 
            my ($cond) = @_;
            return 0b11 if $cond->{position} != $i;
            return 0b01 if $params[$i]->subset($cond->{type});
            return 0b11;
        }
    }

    # 'and' all of @conds together
    return sub {
        my ($cond) = @_;
        my $ret = 0b11;
        for (@conds) {
            $ret &= $_->($cond);
        }
        return $ret;
    };
}

sub _all_conditions {
    my ($self) = @_;

    my @conds;
    for (@{$self->{variants}}) {
        my @params = $_->params;
        push @conds, map { { position => $_, type => $params[$_] } } 0..$#params;
    }

    for (my $i = 0; $i < @conds; $i++) {
        for (my $j = $i+1; $j < @conds; $j++) {
            if ($conds[$i]->{position} == $conds[$j]->{position}
                && $conds[$i]->{type}->subset($conds[$j]->{type}) 
                && $conds[$j]->{type}->subset($conds[$i]->{type})) {
                splice @conds, $j, 1;
                $j--;
            }
        }
    }

    return @conds;
}

1;

=head1 NAME

Class::Multimethods::Pure - Method-ordered multimethod dispatch

=head1 SYNOPSIS

    use Class::Multimethods::Pure;

    package A;
        sub magic { rand() > 0.5 }
    package B;
        use base 'A';
    package C;
        use base 'A';
    
    BEGIN {
        multi foo => ('A', 'A') => sub {
            "Generic catch-all";
        };

        multi foo => ('A', 'B') => sub {
            "More specific";
        };
        
        multi foo => (subtype('A', sub { $_[0]->magic }), 'A') => sub { 
            "This gets called half the time instead of catch-all";
        };

        multi foo => (any('B', 'C'), 'A') => sub {
            "Accepts B or C as the first argument, but not A"
        };
    }

=head1 DESCRIPTION

=head2 Introduciton to Multimethods

When you see the perl expression:

    $animal->speak;

You're asking for C<speak> to be performed on C<$animal>, based on
C<$animal>'s current type.  For instance, if C<$animal> were a Tiger, it
would say "Roar", whereas if C<$animal> were a Dog, it would say "Woof".
The information of the current type of C<$animal> need not be known by
the caller, which is what makes this mechanism powerful.

Now consider a space-shooter game.  You want to create a routine
C<collide> that does something based on the types of I<two> arguments.
For instance, if a Bullet hits a Ship, you want to deliver some damage,
but if a Ship hits an Asteroid, you want it to bounce off.  You could
write it like this:

    sub collide {
        my ($a, $b) = @_;
        if ($a->isa('Bullet') && $b->isa('Ship')) {...}
        elsif ($a->isa('Ship') && $b->isa('Asteroid')) {...}
        ...
    }

Just as you could have written C<speak> that way.  But, above being
ugly, this prohibits the easy addition of new types.  You first have to
create the type in one file, and then remember to add it to this list.

However, there is an analog to methods for multiple arguments, called
I<multimethods>.  This allows the logic for a routine that dispatches on
multiple arguments to be spread out, so that you can include the
relevant logic for the routine in the file for the type you just added.

=head2 Usage

You can define multimethods with the "multi" declarator:

    use Class::Multimethods::Pure;

    multi collide => ('Bullet', 'Ship') => sub {
        my ($a, $b) = @_;  ...
    };

    multi collide => ('Ship', 'Asteroid') => sub {
        my ($a, $b) = @_;  ...
    };

It is usually wise to put such declarations within a BEGIN block, so
they behave more like Perl treats subs (you can call them without
parentheses and you can use them before you define them).

If you think BEGIN looks ugly, then you can define them inline as you
use the module:

    use Class::Multimethods::Pure
        multi => collide => ('Bullet', 'Ship') => sub {...};

But you miss out on a couple of perks if you do that.  See 
L</Special Types> below.

After these are declared, you can call C<collide> like a regular
subroutine:

    collide($ship, $asteroid);

If you defined any variant of a multimethod within a package, then the
multi can also be called as a method on any object of that package (and
any package derived from it). It will be passed as the first argument.

    $ship->collide($asteroid);  # same as above

If you want to allow a multi to be called as a method on some package
without defining any variants in that package, use the null declaration:

    multi 'collide';
    # or
    use Class::Multimethods::Pure multi => collide;

This is also used to import a particular multi into your scope without
defining any variants there.

All multis are global; that is, C<collide> always refers to the same
multi, no matter where/how it is defined.  Allowing scoped multis is on
the TODO list.  But you still have to import it (as shown above) to use
it.

=head2 Non-package Types

In addition to any package name, there are a few special names that
represent unblessed references.  These are the strings returned by
C<ref> when given an unblessed reference.   For the record:

    SCALAR
    ARRAY
    HASH
    CODE
    REF
    GLOB
    LVALUE
    IO
    FORMAT
    Regexp

For example:

    multi pretty => (Any) => sub { $_[0] };
    multi pretty => ('ARRAY') => sub {
        "[ " . join(', ', map { pretty($_) } @{$_[0]}) . " ]";
    };
    multi pretty => ('HASH')  => sub {
        my $hash = shift;
        "{ " . join(', ', 
                map { "$_ => " . pretty($hash->{$_}) } keys %$hash)
        . " }";
    };

=head2 Special Types

There are several types which don't refer to any package.  These are
Junctive types, Any, and Subtypes.

Junctive types represent combinations of types.  C<any('Ship',
'Asteroid')> represents an object that is of either (or both) of the
classes C<Ship> and C<Asteroid>.  C<all('Horse', 'Bird')> represents an
object that is of both types C<Horse> and C<Bird> (probably some sort of
pegasus).  Finally, C<none('Dog')> represents an object that is I<not> a
C<Dog> (or anything derived from C<Dog>).

For example:

    multi fly => ('Horse') => sub { die "Horses don't fly!" };
    multi fly => ('Bird')  => sub { "Flap flap chirp" };
    multi fly => (all('Horse', 'Bird')) => sub { "Flap flap whinee" };

The C<Any> type represents anything at all, object or not.  Use it like
so:

    multi fly => (Any) => sub { die "Most things can't fly." };

Note that it is not a string.  If you give it the string "Any", it will
refer to the C<Any> package, which generally doesn't exist.  C<Any> is a
function that takes no arguments and returns an C<Any> type object.

Finally, there is a C<subtype> function which allows you to specify
constrained types.  It takes two arguments: another type and a code
reference.  The code reference is called on the argument that is being
tested for that type (after checking that the first argument---the base
type---is satisfied), and if it returns true, then the argument is of
that type.  For example:

    my $ZeroOne = subtype(Any, sub { $_[0] < 2 });

We have just defined a type object that is only true when its argument
is less than two and placed it in the type variable C<$ZeroOne>.  Now we
can define the Fibonacci sequence function:

    multi fibo => (Any) => sub { fibo($_[0]-1) + fibo($_[0]-2) };
    multi fibo => ($ZeroOne) => sub { 1 };

Of course, we didn't have to use a type variable; we could have just put
the C<subtype> call right where C<$ZeroOne> appears in the definition.

Consider the follwing declarations:

    multi describe => (subtype(Any, sub { $_[0] > 10 })) => sub {
        "Big";
    };
    multi describe => (subtype(Any, sub { $_[0] == 42 })) => sub {
        "Forty-two";
    };

Calling C<describe(42)> causes an ambiguity error, stating that both
variants of C<describe> match.  We can clearly see that the latter is
more specific than the former (see L</Semantics> for a precise
definition of how this relates to dispatch), but getting the computer to
see that involves solving the halting problem.

So we have to make explicit the relationships between the two subtypes,
using type variables:

    my $Big      = subtype(Any,  sub { $_[0] > 10 });
    my $FortyTwo = subtype($Big, sub { $_[0] == 42 });
    multi describe => ($Big) => sub {
        "Big";
    };
    multi describe => ($FortyTwo) => sub {
        "Forty-two";
    };

Here we have specified that C<$FortyTwo> is more specific than C<$Big>,
since it is a subtype of C<$Big>.  Now calling C<describe(42)> results
in "Forty-two".

In order to get the definitions of C<all>, C<any>, C<none>, C<Any>, and
C<subtype>, you need to import them from the module.  This happens by
default if you use the module with no arguments.  If you only want to
export some of these, use the C<import> command:

    use Class::Multimethods::Pure import => [qw<Any subtype>];

This will accept a null list for you folks who don't like to import
anything.

=head2 Semantics

I've put off explaining the method for determing which method to call
until now.  That's mostly because it will either do exactly what you
want, or yell at you for being ambiguous[1].  I'll take a moment to
define it precisely and mathematically, and then explain what that means
for Mere Mortals.

First, think of a class simply as the set of all of its possible
instances.  When you say C<Foo> is derived from  C<Bar>, you're saying
that "anything that is a C<Foo> is also a C<Bar>", and therefore that
C<Foo> is a subset of C<Bar>.  

Now define a partial order C<< < >> on the variants of a multimethod.
This will represent the relationship "is more specific than".  This is
defined as follows:

Variant A < variant B if and only if

=over

=item * 

Every parameter type in A is a subset of the corresponding parameter in
B.

=item *

At least one of them is a proper subset (that is, a subset but not
equal).

=back

A particular argument list matches a variant A if:

=over

=item *

Each argument is an element of the corresponding parameter type.

=item *

For every variant B, if B matches then A <= B.

=back

In other words, we define "is more specific than" in the most
conservative possible terms.  One method is more specific than the other
only when I<all> of its parameters are either equal or more specific.

A couple of notes:

=over

=item * 

Both A and B are more specific than any(A, B), unless one is a subset of
the other, in which case the junction is equivalent the more general
one.

=item *

all(A, B) is more specific than both A and B, unless one is a subset of
the other, in which case the junction is equivalent to the more specific
one.

=item *

A subtype with base type X is always more specific than X.  This is true
even if the constraint is C<sub { 1 }>, unfortunately.  That's one of
those halting problem thingamajiggers.

=item *

Everything is more specific than C<Any>, except C<Any> itself.

=back

[1] Unlike Manhattan Distance as implemented by L<Class::Multimethods>,
which does what you want more often, but does what you don't want
sometimes without saying a word.

=head2 Dispatch Straegties (and speed)

Class::Multimethods::Pure currently has three different strategies
it can use for dispatch, named I<Cores>.  If you're having issues
with speed, you might want to play around with the different cores
(or write a new one and send it to me C<:-)>.  The three cores are:

=over

=item Class::Multimethods::Pure::Method::Slow

This is the default core.  It implements the algorithm described above in an
obvious and straightforward way: it loops through all the defined variants and
sees which ones are compatible with your argument list, eliminates dominated
methods, and returns.  The performance of this core can be miserable,
especially if you have many variants.  However, if you only have two or three
variants, it might the best one for your job.

=item Class::Multimethods::Pure::Method::DumbCache

This core implements the semantics above by asking the slow core what it would
do, then caching the result based on the ref type of the arguments.  It can
guzzle memory if you pass many different types into the multi.  For example,
even if you only have one variant (A,A), but you subclass A I<n> times and pass
instances of the subclass into the multi instead, the DumbCache core will use
memory proportional to I<n> squared.  If all your variants have the same arity,
they don't use junctions or subtypes, and you're sure that the number of
subclasses of the classes defined in the variants is bounded (and small), then
this will be the fastest core.

=item Class::Multimethods::Pure::Method::DecisionTree

This core implements the semantics above by building a decision tree of
type membership checks.   That is, it does all its logic (like the Slow core)
by asking whether arguments are of type X, without any magic caching or ref
checking or anything.  It also minimizes the numbers of such checks necessary
in the worst case.  It takes some time to compile the multimethod the first
time you dispatch to it after a change.  If you don't meet the conditions for
DumbCache to be efficient, and you are not making frequent changes to the
dispatch table (almost nobody does), then this is going to be the fastest
core.

=back

To enable a different core for all multimethods, set
C<$Class::Multimethods::Pure::DEFAULT_CORE> to the desired core.  For example:

    use Class::Multimethods::Pure;
    $Class::Multimethods::Pure::DEFAULT_CORE = 'DecisionTree';

(If the name given to core is not already a class, then the module will try
prepending Class::Multimethods::Pure::Method.  I suppose you could get in
trouble if you happened to have a package named Slow, DumbCache, 
DecisionTree in your program.  When in doubt, fully qualify.)

A more courteous and versatile approach is to specify the core as an
option to the method definition; i.e.:

    use Class::Multimethods::Pure foo => ('A', 'B'),
                                 -Core => 'DecisionTree',
                                  sub {...}

or:

    multi foo => ('A', 'B'), -Core => 'DecisionTree', sub {
        ...
    };

You may also set options separately from definiton, like:

    use Class::Multimethods::Pure 'foo', -Core => 'DecisionTree';

or:
 
    multi 'foo', -Core => 'DecisionTree';

which sets the core but defines no variant.

=head2 Combinator Factoring

One of the things that I find myself wanting to do most when working
with multimethods is to have combinator types.  These are types that
simply call the multimethod again for some list of aggregated objects
and perform some operation on them (like a Junction). They're easy
to make if they're by themselves.

    multi foo => ('Junction', 'Object') => sub {...}
    multi foo => ('Object', 'Junction') => sub {...}
    multi foo => ('Junction', 'Junction') => sub {...}

However, you find yourself in a major pickle if you want to have more of
them.  For instance:

    multi foo => ('Kunction', 'Object') => sub {...}
    multi foo => ('Object', 'Kunction') => sub {...}
    multi foo => ('Kunction', 'Kunction') => sub {...}

Now they're both combinators, but the module yells at you if you pass
(Kunction, Junction), because there are two methods that would satisfy
that.

The way to define precedence with these combinators is similar to the
way you define precedence in a recursive descent grammar.  You create a
cascade of empty classes at the top of your heirarchy, and derive each
of your generics from a different one of those:

    package AnyObject;
    package JunctionObject;
        use base 'AnyObject';
    package KunctionObject;
        use base 'JunctionObject';
    package Object;
        use base 'KunctionObject';
        # derive all other classes from Object
    
    package Junction;
        use base 'JunctionObject';
        ...
    package Kunction;
        use base 'KunctionObject';
        ...

Now define your multis using these:

    multi foo => ('Junction', 'JunctionObject') => {...}
    multi foo => ('JunctionObject', 'Junction') => {...}
    multi foo => ('Junction', 'Junction') => {...}
    multi foo => ('Kunction', 'KunctionObject') => {...}
    multi foo => ('KunctionObject', 'Kunction') => {...}
    multi foo => ('Kunction', 'Kunction') => {...}

Then the upper one (Junction in this case) will get threaded first,
because a Junction is not a KunctionObject, so it doesn't fit in the
latter three methods.

=head2 Extending

Class::Multimethods::Pure was written to be extended in many ways, but
with a focus on adding new types of, er, types.  Let's say you want to
add Perl 6-ish roles to the Class::Multimethods::Pure dispatcher.  You
need to do four things:

=over

=item * 

Create a class, say My::Role derived from
Class::Multimethods::Pure::Type.  

=item * 

Define the method My::Role::matches, which takes a scalar and returns
whether it is a member of that class (including subclasses, etc.).

=item *

Define the method My::Role::string, which returns a reasonable string
representation of the type, for the user's sake.

=item *

Define as many multimethod variants of "subset" as necessary, which
return whether an object which is a member of the left type implies that
it is a member of the right type.  Construct a
Class::Multimethods::Pure::Type::Package type for your type for the
multimethod.  For a role, you'd need to define:

    $Class::Multimethods::Pure::Type::SUBSET->add_variant(
        [ Class::Multimethods::Pure::Type::Package->new('My::Role'),
          Class::Multimethods::Pure::Type::Package->new('My::Role') ] =>
        sub {...});

And:

    $Class::Multimethods::Pure::Type::SUBSET->add_variant(
        [ Class::Multimethods::Pure::Type::Package->new(
              'Class::Multimethods::Pure::Type::Package'),
          Class::Multimethods::Pure::Type::Package->new('My::Role') ] =>
        sub {...});

(Ugh, I wish my module name weren't so long).

=back

After you have defined these, you have fulfilled the
Class::Multimethods::Pure::Type interface, and now you can pass an
object of type My::Role to multi() and it will be dispatched using the
pure-ordered scheme.  It is nice to give the user a concise constructor
for your object type.

You can also automatically promote strings into objects by defining
variants on the (unary) multimethod
$Class::Multimethods::Pure::Type::PROMOTE.  So to promote strings that
happen to be the names of roles, do:

    $Class::Multimethods::Pure::Type::PROMOTE->add_variant(
        [ Class::Multimethods::Pure::Type::Subtype->new(
            Class::Multimethods::Pure::Type::Any->new,
            sub { is_a_role_name($_[0]) }) 
        ] => 
            sub { My::Role->new($_[0]) });

Now when you pass strings to "multi", if is_a_role_name returns true on
them, they will be promoted to a My::Role object.

=head1 AUTHOR

Luke Palmer <lrpalmer@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2005 by Luke Palmer (lrpalmer@gmail.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.
