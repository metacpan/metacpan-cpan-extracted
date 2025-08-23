package DBIx::QuickORM::Util::HashBase;
use strict;
use warnings;

our $VERSION = '0.000019';

#################################################################
#                                                               #
#  This is a generated file! Do not modify this file directly!  #
#  Use hashbase_inc.pl script to regenerate this file.          #
#  The script is part of the Object::HashBase distribution.     #
#  Note: You can modify the version number above this comment   #
#  if needed, that is fine.                                     #
#                                                               #
#################################################################

{
    no warnings 'once';
    $DBIx::QuickORM::Util::HashBase::HB_VERSION = '0.015';
    *DBIx::QuickORM::Util::HashBase::ATTR_SUBS = \%Object::HashBase::ATTR_SUBS;
    *DBIx::QuickORM::Util::HashBase::ATTR_LIST = \%Object::HashBase::ATTR_LIST;
    *DBIx::QuickORM::Util::HashBase::VERSION   = \%Object::HashBase::VERSION;
    *DBIx::QuickORM::Util::HashBase::CAN_CACHE = \%Object::HashBase::CAN_CACHE;
}


require Carp;
{
    no warnings 'once';
    $Carp::Internal{+__PACKAGE__} = 1;
}

BEGIN {
    {
        # Make sure none of these get messed up.
        local ($SIG{__DIE__}, $@, $?, $!, $^E);
        if (eval { require Class::XSAccessor; Class::XSAccessor->VERSION(1.19); 1 }) {
            *CLASS_XS_ACCESSOR = sub() { 1 }
        }
        else {
            *CLASS_XS_ACCESSOR = sub() { 0 }
        }
    }

    # these are not strictly equivalent, but for out use we don't care
    # about order
    *_isa = ($] >= 5.010 && require mro) ? \&mro::get_linear_isa : sub {
        no strict 'refs';
        my @packages = ($_[0]);
        my %seen;
        for my $package (@packages) {
            push @packages, grep !$seen{$_}++, @{"$package\::ISA"};
        }
        return \@packages;
    }
}

my %SPEC = (
    '^' => {reader => 1, writer => 0, dep_writer => 1, read_only => 0, strip => 1},
    '-' => {reader => 1, writer => 0, dep_writer => 0, read_only => 1, strip => 1},
    '>' => {reader => 0, writer => 1, dep_writer => 0, read_only => 0, strip => 1},
    '<' => {reader => 1, writer => 0, dep_writer => 0, read_only => 0, strip => 1},
    '+' => {reader => 0, writer => 0, dep_writer => 0, read_only => 0, strip => 1},
    '~' => {reader => 1, writer => 1, dep_writer => 0, read_only => 0, strip => 1, no_xs => 1},
);

sub spec { \%SPEC }

sub import {
    my $class = shift;
    my $into  = caller;
    $class->do_import($into, @_);
}

sub do_import {
    my $class = shift;
    my $into  = shift;

    # Make sure we list the OLDEST version used to create this class.
    my $ver = $DBIx::QuickORM::Util::HashBase::HB_VERSION || $DBIx::QuickORM::Util::HashBase::VERSION;
    $DBIx::QuickORM::Util::HashBase::VERSION{$into} = $ver if !$DBIx::QuickORM::Util::HashBase::VERSION{$into} || $DBIx::QuickORM::Util::HashBase::VERSION{$into} > $ver;

    my $isa = _isa($into);
    my $attr_list = $DBIx::QuickORM::Util::HashBase::ATTR_LIST{$into} ||= [];
    my $attr_subs = $DBIx::QuickORM::Util::HashBase::ATTR_SUBS{$into} ||= {};

    my @pre_init;
    my @post_init;

    my $add_new = 1;

    if (my $have_new = $into->can('new')) {
        my $new_lookup = $DBIx::QuickORM::Util::HashBase::NEW_LOOKUP //= {};
        $add_new = 0 unless $new_lookup->{$have_new};
    }

    my %subs = (
        ($add_new ? ($class->_build_new($into, \@pre_init, \@post_init)) : ()),
        (map %{$DBIx::QuickORM::Util::HashBase::ATTR_SUBS{$_} || {}}, @{$isa}[1 .. $#$isa]),
        ($class->args_to_subs($attr_list, $attr_subs, \@_, $into)),
    );

    no strict 'refs';
    while (my ($k, $v) = each %subs) {
        if (ref($v) eq 'CODE') {
            *{"$into\::$k"} = $v;
        }
        else {
            my ($sub, @args) = @$v;
            $sub->(@args);
        }
    }
}

sub args_to_subs {
    my $class = shift;
    my ($attr_list, $attr_subs, $args, $into) = @_;

    my $use_gen = $class->can('gen_accessor') ;

    my %out;

    while (@$args) {
        my $x = shift @$args;
        my $p = substr($x, 0, 1);

        my $spec = $class->spec->{$p} || {reader => 1, writer => 1};
        substr($x, 0, 1) = '' if $spec->{strip};

        push @$attr_list => $x;
        my ($sub, $attr) = (uc $x, $x);

        $attr_subs->{$sub} = sub() { $attr };
        $out{$sub} = $attr_subs->{$sub};

        my $copy = "$attr";
        if ($spec->{reader}) {
            if ($use_gen) {
                $out{$attr} = $class->gen_accessor(reader => $copy, $spec, $args);
            }
            elsif (CLASS_XS_ACCESSOR && !$spec->{no_xs}) {
                $out{$attr} = [\&Class::XSAccessor::newxs_getter, "$into\::$attr", $copy];
            }
            else {
                $out{$attr} = sub { $_[0]->{$attr} };
            }
        }

        if ($spec->{writer}) {
            if ($use_gen) {
                $out{"set_$attr"} = $class->gen_accessor(writer => $copy, $spec, $args);
            }
            elsif(CLASS_XS_ACCESSOR && !$spec->{no_xs}) {
                $out{"set_$attr"} = [\&Class::XSAccessor::newxs_setter, "$into\::set_$attr", $copy, 0];
            }
            else {
                $out{"set_$attr"} = sub { $_[0]->{$attr} = $_[1] };
            }
        }
        elsif($spec->{read_only}) {
            $out{"set_$attr"} = $use_gen ? $class->gen_accessor(read_only => $copy, $spec, $args) : sub { Carp::croak("'$attr' is read-only") };
        }
        elsif($spec->{dep_writer}) {
            $out{"set_$attr"} = $use_gen ? $class->gen_accessor(dep_writer => $copy, $spec, $args) : sub { Carp::carp("set_$attr() is deprecated"); $_[0]->{$attr} = $_[1] };
        }

        if ($spec->{custom}) {
            my %add = $class->gen_accessor(custom => $copy, $spec, $args);
            $out{$_} = $add{$_} for keys %add;
        }
    }

    return %out;
}

sub attr_list {
    my $class = shift;

    my $isa = _isa($class);

    my %seen;
    my @list = grep { !$seen{$_}++ } map {
        my @out;

        if (0.004 > ($DBIx::QuickORM::Util::HashBase::VERSION{$_} || 0)) {
            Carp::carp("$_ uses an inlined version of DBIx::QuickORM::Util::HashBase too old to support attr_list()");
        }
        else {
            my $list = $DBIx::QuickORM::Util::HashBase::ATTR_LIST{$_};
            @out = $list ? @$list : ()
        }

        @out;
    } reverse @$isa;

    return @list;
}

sub _build_new {
    my $class = shift;
    my ($into, $pre_init, $post_init) = @_;

    my $add_pre_init  = sub(&) { push @$pre_init  => $_[-1] };
    my $add_post_init = sub(&) { push @$post_init => $_[-1] };

    my $__pre_init = $into->can('_pre_init');
    my $_pre_init  = $__pre_init ? sub { ($__pre_init->(), @$pre_init) } : sub { @$pre_init };

    my $__post_init = $into->can('_post_init');
    my $_post_init  = $__post_init ? sub { ($__post_init->(), @$post_init) } : sub {  @$post_init };

    my $new = sub {
        my $class = shift;

        my $self;

        if (@_ == 1) {
            my $arg  = shift;
            my $type = ref($arg);

            if ($type eq 'HASH') {
                $self = bless({%$arg}, $class);
            }
            else {
                Carp::croak("Not sure what to do with '$type' in $class constructor")
                    unless $type eq 'ARRAY';

                my %proto;
                my @attributes = attr_list($class);
                while (@$arg) {
                    my $val = shift @$arg;
                    my $key = shift @attributes or Carp::croak("Too many arguments for $class constructor");
                    $proto{$key} = $val;
                }

                $self = bless(\%proto, $class);
            }
        }
        else {
            $self = bless({@_}, $class);
        }

        $DBIx::QuickORM::Util::HashBase::CAN_CACHE{$class} = $self->can('init')
            unless exists $DBIx::QuickORM::Util::HashBase::CAN_CACHE{$class};

        $self->$_() for $_pre_init->();
        $self->init() if $DBIx::QuickORM::Util::HashBase::CAN_CACHE{$class};
        $self->$_() for reverse $_post_init->();

        $self;
    };

    my $new_lookup = $DBIx::QuickORM::Util::HashBase::NEW_LOOKUP //= {};
    $new_lookup->{$new} = 1;

    my %out;

    {
        no strict 'refs';
        $out{new}           = $new           unless defined(&{"${into}\::new"});
        $out{add_pre_init}  = $add_pre_init  unless defined(&{"${into}\::add_pre_init"});
        $out{add_post_init} = $add_post_init unless defined(&{"${into}\::add_post_init"});
        $out{_pre_init}     = $_pre_init     unless defined(&{"${into}\::_pre_init"});
        $out{_post_init}    = $_post_init    unless defined(&{"${into}\::_post_init"});
    }

    return %out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Util::HashBase - Build hash based classes.

=head1 SYNOPSIS

A class:

    package My::Class;
    use strict;
    use warnings;

    # Generate 3 accessors
    use DBIx::QuickORM::Util::HashBase qw/foo -bar ^baz <bat >ban +boo/;

    # Chance to initialize defaults
    sub init {
        my $self = shift;    # No other args
        $self->{+FOO} ||= "foo";
        $self->{+BAR} ||= "bar";
        $self->{+BAZ} ||= "baz";
        $self->{+BAT} ||= "bat";
        $self->{+BAN} ||= "ban";
        $self->{+BOO} ||= "boo";
    }

    sub print {
        my $self = shift;
        print join ", " => map { $self->{$_} } FOO, BAR, BAZ, BAT, BAN, BOO;
    }

Subclass it

    package My::Subclass;
    use strict;
    use warnings;

    # Note, you should subclass before loading HashBase.
    use base 'My::Class';
    use DBIx::QuickORM::Util::HashBase qw/bub/;

    sub init {
        my $self = shift;

        # We get the constants from the base class for free.
        $self->{+FOO} ||= 'SubFoo';
        $self->{+BUB} ||= 'bub';

        $self->SUPER::init();
    }

use it:

    package main;
    use strict;
    use warnings;
    use My::Class;

    # These are all functionally identical
    my $one   = My::Class->new(foo => 'MyFoo', bar => 'MyBar');
    my $two   = My::Class->new({foo => 'MyFoo', bar => 'MyBar'});
    my $three = My::Class->new(['MyFoo', 'MyBar']);

    # Readers!
    my $foo = $one->foo;    # 'MyFoo'
    my $bar = $one->bar;    # 'MyBar'
    my $baz = $one->baz;    # Defaulted to: 'baz'
    my $bat = $one->bat;    # Defaulted to: 'bat'
    # '>ban' means setter only, no reader
    # '+boo' means no setter or reader, just the BOO constant

    # Setters!
    $one->set_foo('A Foo');

    #'-bar' means read-only, so the setter will throw an exception (but is defined).
    $one->set_bar('A bar');

    # '^baz' means deprecated setter, this will warn about the setter being
    # deprecated.
    $one->set_baz('A Baz');

    # '<bat' means no setter defined at all
    # '+boo' means no setter or reader, just the BOO constant

    $one->{+FOO} = 'xxx';

Add pre_init and post-init:

B<Note:> These are not provided if you define your own new() method (via a stub
at the top).

B<Note:> Single inheritence should work with child classes doing the pre/post
init subs during construction, so long as all classes in the chain use a
generated new(). This will probably explode badly in multiple-inheritence.

    package My::Class;
    use strict;
    use warnings;

    # Generate 3 accessors
    use DBIx::QuickORM::Util::HashBase qw/foo -bar ^baz <bat >ban +boo/;

    # Do more stuff before init, add as many as you like by calling this
    # multiple times with a different code block each time
    add_pre_init {
        ...
    };

    # Chance to initialize defaults
    sub init { ... }

    # Do stuff after init, add as many as you want, they run in reverse order
    add_post_init {
        my $self = shift;
        ...
    };

    sub print {
        my $self = shift;
        print join ", " => map { $self->{$_} } FOO, BAR, BAZ, BAT, BAN, BOO;
    }

You can also call add_pre_init and add_post_init as class methods from anywhere
to add init and post-init to the class.

B<Please note:> This will apply to all future instances of the object created,
but not past ones. This is a form of meta-programming and it is easy to abuse.
It is also helpful for extending DBIx::QuickORM::Util::HashBase.

    My::Class->add_pre_init(sub { ... });
    My::Class->add_post_init(sub { ... });

=head1 DESCRIPTION

This package is used to generate classes based on hashrefs. Using this class
will give you a C<new()> method, as well as generating accessors you request.
Generated accessors will be getters, C<set_ACCESSOR> setters will also be
generated for you. You also get constants for each accessor (all caps) which
return the key into the hash for that accessor. Single inheritance is also
supported.

=head1 XS ACCESSORS

If L<Class::XSAccessor> is installed, it will be used to generate XS getters
and setters.

=head2 CAVEATS

The only caveat noticed so far is that if you take a reference to an objects
attribute element: C<< my $ref = \($obj->{foo}) >> then use
C<< $obj->set_foo(1) >>, setting C<< $$ref = 2 >> will not longer work, and
getting the value via C<< $val = $$ref >> will also not work. This is not a
problem when L<Class::XSAccessor> is not used.

In practice it will nbe VERY rare for this to be a problem, but it was noticed
because it broke a performance optimization in L<Test2::API>.

You can request an accessor NOT be xs with the '~' prefix:

    use DBIx::QuickORM::Util::HashBase '~foo';

The sample above generates C<foo()> and C<set_foo()> and they are NOT
implemented in XS.

=head1 THIS IS A BUNDLED COPY OF HASHBASE

This is a bundled copy of L<Object::HashBase>. This file was generated using
the
C</home/exodist/perl5/perlbrew/perls/main/bin/hashbase_inc.pl>
script.

=head1 METHODS

=head2 PROVIDED BY HASH BASE

=over 4

=item $it = $class->new(%PAIRS)

=item $it = $class->new(\%PAIRS)

=item $it = $class->new(\@ORDERED_VALUES)

Create a new instance.

HashBase will not export C<new()> if there is already a C<new()> method in your
packages inheritance chain.

B<If you do not want this method you can define your own> you just have to
declare it before loading L<DBIx::QuickORM::Util::HashBase>.

    package My::Package;

    # predeclare new() so that HashBase does not give us one.
    sub new;

    use DBIx::QuickORM::Util::HashBase qw/foo bar baz/;

    # Now we define our own new method.
    sub new { ... }

This makes it so that HashBase sees that you have your own C<new()> method.
Alternatively you can define the method before loading HashBase instead of just
declaring it, but that scatters your use statements.

The most common way to create an object is to pass in key/value pairs where
each key is an attribute and each value is what you want assigned to that
attribute. No checking is done to verify the attributes or values are valid,
you may do that in C<init()> if desired.

If you would like, you can pass in a hashref instead of pairs. When you do so
the hashref will be copied, and the copy will be returned blessed as an object.
There is no way to ask HashBase to bless a specific hashref.

In some cases an object may only have 1 or 2 attributes, in which case a
hashref may be too verbose for your liking. In these cases you can pass in an
arrayref with only values. The values will be assigned to attributes in the
order the attributes were listed. When there is inheritance involved the
attributes from parent classes will come before subclasses.

=back

=head2 HOOKS

=over 4

=item $self->init()

This gives you the chance to set some default values to your fields. The only
argument is C<$self> with its indexes already set from the constructor.

B<Note:> DBIx::QuickORM::Util::HashBase checks for an init using C<< $class->can('init') >>
during construction. It DOES NOT call C<can()> on the created object. Also note
that the result of the check is cached, it is only ever checked once, the first
time an instance of your class is created. This means that adding an C<init()>
method AFTER the first construction will result in it being ignored.

=back

=head1 ACCESSORS

=head2 READ/WRITE

To generate accessors you list them when using the module:

    use DBIx::QuickORM::Util::HashBase qw/foo/;

This will generate the following subs in your namespace:

=over 4

=item foo()

Getter, used to get the value of the C<foo> field.

=item set_foo()

Setter, used to set the value of the C<foo> field.

=item FOO()

Constant, returns the field C<foo>'s key into the class hashref. Subclasses will
also get this function as a constant, not simply a method, that means it is
copied into the subclass namespace.

The main reason for using these constants is to help avoid spelling mistakes
and similar typos. It will not help you if you forget to prefix the '+' though.

=back

=head2 READ ONLY

    use DBIx::QuickORM::Util::HashBase qw/-foo/;

=over 4

=item set_foo()

Throws an exception telling you the attribute is read-only. This is exported to
override any active setters for the attribute in a parent class.

=back

=head2 DEPRECATED SETTER

    use DBIx::QuickORM::Util::HashBase qw/^foo/;

=over 4

=item set_foo()

This will set the value, but it will also warn you that the method is
deprecated.

=back

=head2 NO SETTER

    use DBIx::QuickORM::Util::HashBase qw/<foo/;

Only gives you a reader, no C<set_foo> method is defined at all.

=head2 NO READER

    use DBIx::QuickORM::Util::HashBase qw/>foo/;

Only gives you a write (C<set_foo>), no C<foo> method is defined at all.

=head2 CONSTANT ONLY

    use DBIx::QuickORM::Util::HashBase qw/+foo/;

This does not create any methods for you, it just adds the C<FOO> constant.

=head2 NO XS

    use DBIx::QuickORM::Util::HashBase qw/~foo/;

This enforces that the getter and setter generated for C<foo> will NOT use
L<Class::XSAccessor> even if it is installed.

=head1 SUBCLASSING

You can subclass an existing HashBase class.

    use base 'Another::HashBase::Class';
    use DBIx::QuickORM::Util::HashBase qw/foo bar baz/;

The base class is added to C<@ISA> for you, and all constants from base classes
are added to subclasses automatically.

=head1 GETTING A LIST OF ATTRIBUTES FOR A CLASS

DBIx::QuickORM::Util::HashBase provides a function for retrieving a list of attributes for an
DBIx::QuickORM::Util::HashBase class.

=over 4

=item @list = DBIx::QuickORM::Util::HashBase::attr_list($class)

=item @list = $class->DBIx::QuickORM::Util::HashBase::attr_list()

Either form above will work. This will return a list of attributes defined on
the object. This list is returned in the attribute definition order, parent
class attributes are listed before subclass attributes. Duplicate attributes
will be removed before the list is returned.

B<Note:> This list is used in the C<< $class->new(\@ARRAY) >> constructor to
determine the attribute to which each value will be paired.

=back

=head1 SOURCE

The source code repository for HashBase can be found at
F<http://github.com/Test-More/HashBase/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
