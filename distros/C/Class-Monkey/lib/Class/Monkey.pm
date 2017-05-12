package Class::Monkey;

use strict;
use warnings;
no warnings 'redefine';

our $VERSION = '0.007';
$Class::Monkey::Subs     = {};
$Class::Monkey::CanPatch = [];
$Class::Monkey::Classes  = [];
$Class::Monkey::Iter     = 0;

=head1 NAME

Class::Monkey - Monkey Patch a class/instance with modifiers and other sweet stuff

=head1 DESCRIPTION

Say we have a module installed on the system. It does some handy things, but you find a bug or a strange feature. We can easily fix it without subclassing by the following...

    # StupidClass.pm
    package SupidClass;
    
    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub name {
        my ($self, $name) = @_;
        print "Hello, ${name}\n";
    }

    sub no_args {
        print "No arguments were specified!\n";
    }

    1;

Above is our class. A stupid one at that. The C<name> method doesn't validate the arguments.. it just tries to print them in a 'hello' string. 
We can use an C<around> method to call the C<name> method if arguments are passed, or to call C<no_args> if not. We can happily do this from the program.

    # our_program.pl
    use Class::Monkey qw<StupidClass>;

    # The patch
    around 'name' => sub {
        my $method = shift;
        my $self   = shift;
        
        if (@_) {
            $self->$method(@_);
        }
        else {
            $self->no_args();
        }
    },
    qw<StupidClass>;
    # /The Patch
     
    $s->name();         # actually executes no_args
    $s->name("World"):  # runs name

=head1 SYNOPSIS

Simply import the classes you want to patch as an array when you C<use Class::Monkey>. Doing this means you won't even need to C<use> the module you want to patch - Class::Monkey takes care of that for you.

    use Class::Monkey qw<Some::Package Another::Module>;

    method 'needThisMethod' => sub {
        ...
    },
    qw<Some::Package>;

    my $p = Some::Package->new;
    $p->needThisMethod;

=head1 METHODS

=cut

sub import {
    my ($class, @args) = @_;
    my $pkg = scalar caller;
    my $tweak = 0;
    if (scalar @args > 0) {
        for my $m (@args) {
            if ($m eq '-tweak') {
                $tweak = 1;
                my ($index) = grep { $args[$_] eq '-tweak' } 0..$#args;
                splice @args, $index, 1;
                next;
            }
            push @{$Class::Monkey::CanPatch}, $m;
        }
        _extend_class(\@args, $pkg);
    }

    _import_def(
        $pkg,
        undef,
        qw/
            override
            method
            before
            after
            around
            unpatch
            instance
            original
            has
            extends
            exports
            canpatch
        /
    ) unless $tweak;

    _import_def($pkg, undef, qw<tweak haz>) if $tweak;
}

sub _extend_class {
    my ($mothers, $class) = @_;

    return if $class eq __PACKAGE__;
    foreach my $mother (@$mothers) {
        # if class is unknown to us, import it (FIXME)
        unless (grep { $_ eq $mother } @$Class::Monkey::Classes) {
            eval "use $mother";
            warn "Could not load $mother: $@"
                if $@;

            $mother->import;
        }
        push @$Class::Monkey::Classes, $mother;
    }

    {
        no strict 'refs';
        @{"${class}::ISA"} = @$mothers;
    }
}

=head2 haz

Please see C<tweak> for more information on how to get this method. C<haz> behaves the exact same way as C<extends>.

    use Class::Monkey '-tweak';

    haz 'FooClass';
    haz qw<FooClass Another::FooClass More::FooClass>;

=cut

sub haz {
    my (@args) = @_;
    my $pkg = getscope();
    if (scalar @args > 0) {
        for my $m (@args) {
            push @{$Class::Monkey::CanPatch}, $m;
        }
        _extend_class(\@args, $pkg);
    }
}

=head2 tweak

This method is only available when you C<use Class::Monkey '-tweak'>. This option may be preferred over the default modifier methods when you need to patch a class from a script using Moose/Mouse/Moo/Mo, etc. When you add -tweak, it will export only the C<tweak> and C<haz> methods.

    use Class::Monkey '-tweak';
    haz 'Foo';

    tweak 'mymethod' => (
        class => 'Foo',
        override => sub {
            print "mymethod has been overridden\n";
        },
    );

You can replace 'override' in the above example with any of the available Class::Monkey modifiers (ie: before, method, after, around). Also C<class> can be the full name of the class as above, or an instance.

=cut
    
sub tweak {
    my ($sub, %args) = @_;
    
    my $class = delete $args{class};
    {
        no strict 'refs';
        foreach my $action (keys %args) {
            $action->($sub, $args{$action}, $class);
        }
    }
}

sub _import_def {
    my ($pkg, $from, @subs) = @_;
    no strict 'refs';
    if ($from) {
        for (@subs) {
            *{$pkg . "::$_"} = \&{"$from\::$_"};
        }
    }
    else {
        for (@subs) {
            *{$pkg . "::$_"} = \&$_;
        }
    }
}

sub _doh {
    my $err = shift;
    die $err . "\n";
}

sub _check_init {
    my $class = shift;

    $class = ref($class) if ref($class);
    _doh "No class was specified" if ! $class;

    _doh "Not allowed to patch $class"
        if ! grep { $_ eq $class } @{$Class::Monkey::CanPatch};
}

=head2 canpatch

Tells Class::Monkey you want to be able to patch the specified modules, but not to 'use' them.

    use Class::Monkey;
    use MyFoo;

    canpatch qw<MyFoo AndThis AndThat>;

    # then do stuff with MyFoo as normal

=cut

sub canpatch {
    my (@modules) = @_;
    
    push @{$Class::Monkey::CanPatch}, @modules;
}

sub _add_to_subs {
    my $sub = shift;
    if (! exists $Class::Monkey::Subs->{$sub}) {
        $Class::Monkey::Subs->{$sub} = {};
        $Class::Monkey::Subs->{$sub} = \&{$sub};
        no strict 'refs';
        *{__PACKAGE__ . "::$sub"} = \&{$sub};
    }
}

sub getscope {
    my $self = shift;
    my $pkg = $self||scalar caller(1);
    return $pkg;
}

=head2 exports

Have a subroutine in your file you want to explort to your patched class? Use C<exports> to do so.

    package Foo;

    sub new { return bless {}, __PACKAGE__ }    

    1;

    # test.pl
    package MyPatcher;

    use Class::Monkey qw<Foo>;
    
    sub foo { print "Hiya\n"; }

    exports 'foo', qw<Foo>;
    my $foo = Foo->new;
    $foo->foo(); # prints Hiya
    
    exports 'foo', $foo;        # works with instances too

=cut

sub exports {
    my ($method, $class) = @_;
    my $pkg = caller;
    no strict 'refs';
    if (ref($class)) {
        $Class::Monkey::Iter++;
        my $package = ref($class) . '::Class::Monkey::' . $Class::Monkey::Iter;
        @{$package . '::ISA'} = (ref($class));
        *{"${package}::${method}"} = *{"${pkg}::${method}"};
        bless $_[1], $package;
    }
    else {
        *{"${class}::${method}"} = *{"${pkg}::${method}"};
    }
}

    
=head2 extends

Sometimes you might not want to include the module you want to patch when you C<use Class::Monkey>. No problem. You can use C<extends> to do it later on.

  use Class::Monkey;
  extends 'SomeClass';
  extends qw<SomeClass FooClass>;

=cut

sub extends {
    my (@args) = @_;
    my $pkg = getscope; 
    if (scalar @args > 0) {
        for my $m (@args) {
            push @{$Class::Monkey::CanPatch}, $m;
        }
        _extend_class(\@args, $pkg);
    }
}

=head2 has

Gives the wanted class an accessor. You can assign it a read-only or read-writable type (Similar to Moose). 
Because it works on remote packages you need to give it the full name of the method including the class.

    use Class::Monkey qw<Foo::Class>;
    
    has 'Foo::Class::greet' => ( is => 'ro', default => 'Hello' ); # read-only
    has 'Foo::Class::name'  => ( is => 'rw', default => 'World' ); # read-writable
    
    my $foo = Foo::Class->new;
    say "Hello, " . $foo->name;
    
    $foo->name('Monkey); # updates the name accessor to return a new value

If you leave out the C<is> parameter when you define an accessor it will always default to read-writable.

=cut

sub has {
    my ($name, %args) = @_;
    my $rtype   = delete $args{is}||"";
    my $default = delete $args{default}||"";
    no strict 'refs';
    if ($rtype eq 'ro') {
        if (! $default) {
            warn "Redundant null static accessor '$name'";
        }
        *{$name} = sub {
            my ($self, $val) = @_;
            if (@_ == 2) {
                warn "Cannot alter a Read-Only accessor";
                return ;
            }
            return $default;
        };
    }
    else {
        *{$name} = sub {
            my ($self, $val) = @_;
            if ($default && ! $self->{_used}->{$name}) {
                $self->{$name} = $default;
                $self->{_used}->{$name} = 1;
            }
            if (@_ == 2) {
                $self->{$name} = $val;
            }
            else {
                return $self->{$name}||"";
            }
        };
    }
}
# modifiers

=head2 instance

B<Note> This method should be deprecated as all modifiers now support constants OR an instance. Class::Monkey will determine which method should be used, so calling C<instance> is no longer required.

Patch an instance method instead of an entire class

    # Pig.pm
    package Pig;
    sub new { return bless {}, shift; }
    sub says { print "Oink!\n"; }

    # test.pl
    package main;
    use Class::Monkey qw<Pig>;

    my $pig  = Pig->new;
    my $pig2 = Pig->new;
    instance 'says' => sub {
        print "Meow\n";
    },
    $pig2;

    # only $pig2 will have its says method overridden

As of 0.002 you can now do it like this

    override 'says' => sub {
        print "Meow\n";
    }, $pig2;

    before 'says' => sub {
        print "Going to speak\n";
    }, $pig;

etc..

=cut

sub instance {
    my($method, $code, $instance) = @_;
    $Class::Monkey::Iter++;
    my $package = ref($instance) . '::Class::Monkey::' . $Class::Monkey::Iter;
    no strict 'refs';
    @{$package . '::ISA'} = (ref($instance));
    *{$package . '::' . $method} = $code;
    bless $_[2], $package;
}

=head2 original

If you want to run the original version of a patched method, but not unpatch it right away 
you can use C<original> to do so. It will run the old method before it was patched with any arguments you specify, but the actual method will still remain patched.

    after 'someMethod' => sub {
        print "Blah\n"
    },
    qw<Foo>;

    original('Foo', 'someMethod', qw<these are my args>);

OR if you prefer, you can just call C<Class::Monkey::PatchedClassName::method->(@args)>

    Class::Monkey::Foo->someMethod('these', 'are', 'my', 'args);

=cut

sub original {
    my ($class, $method, @args) = @_;
    if (exists $Class::Monkey::Subs->{"$class\::$method"}) {
        $Class::Monkey::Subs->{"$class\::$method"}->(@args);
    }
    else {
        warn "Could not run original method '$method' in class $class. Not found";
        return 0;
    }
}

=head2 override 

Overrides an already existing method. If the target method doesn't exist then Class::Monkey will throw an error.

    override 'foo' => sub {
        return "foo bar";
    },
    qw<Some::Module>;

=cut

sub override {
    my ($method, $code, $class) = @_;

    _check_init($class);

    _doh "You need to specify a class to which your overridden method exists"
        if ! $class;

    _doh "Method $method does not exist in $class. Perhaps you meant 'method' instead of 'override'?"
        if ! $class->can($method);

    _add_to_subs("$class\::$method");
    no strict 'refs';
    *$method = sub { $code->(@_) };
    if (ref($class)) {
        $Class::Monkey::Iter++;
        my $package = ref($class) . '::Class::Monkey::' . $Class::Monkey::Iter;
        @{$package . '::ISA'} = (ref($class));
        *{"${package}::${method}"} = \*$method;
        bless $_[2], $package;
    }
    else {
        *{$class . "::$method"} = \*$method;
    }
}

=head2 method

Creates a brand new method in the target module. It will NOT allow you to override an existing one using this, and will throw an error.

    method 'active_customers' => sub {
        my $self = shift;
        return $self->search({ status => 'active' });
    },
    qw<Schema::ResultSet::Customer>;

=cut

sub method {
    my ($method, $code, $class) = @_;
    
    _check_init($class);
    _doh "You need to specify a class to which your created method will be initialised"
        if ! $class;
    
    _doh "The method '$method' already exists in $class. Did you want to 'override' it instead?"
        if $class->can($method);

    _add_to_subs("$class\::$method");
    no strict 'refs';
    *$method = sub { $code->(@_); };

    *{$class . "::$method"} = \*$method;
}

=head2 before

Simply adds code to the target method before the original code is ran

    # Foo.pm
    package Foo;
    
    sub new { return bless {}, __PACKAGE__; }
    sub hello { print "Hello, $self->{name}; }
    1;

    # test.pl
    use Class::Monkey qw<Foo>;
   
    my $foo = Foo->new; 
    before 'hello' => {
        my $self = shift;
        $self->{name} = 'World';
    },
    qw<Foo>;

    print $foo->hello . "\n";

=cut

sub before {
    my ($method, $code, $class) = @_;
    my $full; 
    _check_init($class);
    $full = ref($class) ? ref($class) . "::${method}" : "${class}::${method}";
    my $new_code;
    my $old_code;
    die "Could not find $method in the hierarchy for $class\n"
        if ! $class->can($method);
    
    no strict 'refs';

    _add_to_subs($full);
    $old_code = \&{$full};
    if (ref($class)) {
        $Class::Monkey::Iter++;
        my $package = ref($class) . '::Class::Monkey::' . $Class::Monkey::Iter;
        @{$package . '::ISA'} = (ref($class));
        $full = "${package}::${method}";

        *$method = sub {
            $code->(@_);
            $old_code->(@_);
        };
        
        *{$full} = \*$method;
        bless $_[2], $package;
    }
    else {
        *$method = sub {
            $code->(@_);
            $old_code->(@_);
        }; 
        *{$full} = \*$method;
    }
    
    
}

=head2 after

Basically the same as C<before>, but appends the code specified to the END of the original

=cut

sub after {
    my ($method, $code, $class) = @_;

    _check_init($class);
    my $full = ref($class) ? ref($class) . "::${method}" : "${class}::${method}"; 
    my $new_code;
    my $old_code;
    die "Could not find $method in the hierarchy for $class\n"
        if ! $class->can($method);

    $old_code = \&{$full};
    no strict 'refs';
     _add_to_subs($full);
    if (ref($class)) {
        $Class::Monkey::Iter++;
        my $package = ref($class) . '::Class::Monkey::' . $Class::Monkey::Iter;
        @{$package . '::ISA'} = (ref($class));
        $full = "${package}::${method}";

        *$method = sub {
            $old_code->(@_);
            $code->(@_);
        };

        *{$full} = \*$method;
        bless $_[2], $package;
    }
    else {
        *$method = sub {
            $old_code->(@_);
            $code->(@_);
        };

        *{$full} = \*$method;
    }
}

=head2 around

Around gives the user a bit more control over the subroutine. When you create an around method the first argument will be the original method, the second is C<$self> and the third is any arguments passed to the original subroutine. In a away this allows you to control the flow of the entire subroutine.

    package MyFoo;

    sub greet {
        my ($self, $name) = @_;

        print "Hello, $name!\n";
    }

    1;

    # test.pl

    use Class::Monkey qw<MyFoo>;

    # only call greet if any arguments were passed to MyFoo->greet()
    around 'greet' => sub {
        my $method = shift;
        my $self = shift;

        $self->$method(@_)
            if @_;
    },
    qw<MyFoo>;

=cut

sub around {
    my ($method, $code, $class) = @_;

    my $full = "$class\::$method";
    die "Could not find $method in the hierarchy for $class\n"
        if ! $class->can($method);

    my $old_code = \&{$full};
    no strict 'refs';
    *$method = sub {
        $code->($old_code, @_);
    };

    _add_to_subs($full);
    if (ref($class)) {
        $Class::Monkey::Iter++;
        my $package = ref($class) . '::Class::Monkey::' . $Class::Monkey::Iter;
        @{$package . '::ISA'} = (ref($class));
        *{"${package}::${method}"} = \*$method;
        bless $_[2], $package;
    }
    else {
        *{$full} = \*$method;
    }
}

=head2 unpatch

Undoes any modifications made to patched methods, restoring it to its original state.

    override 'this' => sub {
        print "Blah\n";
    }, qw<FooClass>;
  
    unpatch 'this', 'FooClass';

=cut

sub unpatch {
    my ($method, $class) = @_;

    my $sub = "$class\::$method";

    if (! exists $Class::Monkey::Subs->{$sub}) {
        warn "Could not restore $method in $class because I have no recollection of it";
        return 0;
    }

    no strict 'refs';
    *{$sub} = $Class::Monkey::Subs->{$sub};
}

=head1 AUTHOR

Brad Haywood <brad@geeksware.net>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
