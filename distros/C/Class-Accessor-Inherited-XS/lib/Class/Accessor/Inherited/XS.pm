package Class::Accessor::Inherited::XS;
use 5.010001;
use strict;
use warnings;

use Class::Accessor::Inherited::XS::Compat qw/mk_type_accessors mk_inherited_accessors mk_class_accessors mk_varclass_accessors mk_object_accessors/;

our $PREFIX = '__cag_';

BEGIN {
    our $VERSION = '0.35';

    require XSLoader;
    XSLoader::load('Class::Accessor::Inherited::XS', $VERSION);
}

use Carp qw/confess/;
use Class::Accessor::Inherited::XS::Constants;

my $REGISTERED_TYPES = {};
register_types(
    inherited       => {installer => _curry(\&_mk_inherited_accessor, None),       clone_arg => 1},
    inherited_ro    => {installer => _curry(\&_mk_inherited_accessor, IsReadonly), clone_arg => 1},
    class           => {installer => _curry(\&_mk_class_accessor, 0, None),        clone_arg => undef},
    class_ro        => {installer => _curry(\&_mk_class_accessor, 0, IsReadonly),  clone_arg => undef},
    varclass        => {installer => _curry(\&_mk_class_accessor, 1, None),        clone_arg => undef},
    varclass_ro     => {installer => _curry(\&_mk_class_accessor, 1, IsReadonly),  clone_arg => undef},
    object          => {installer => _curry(\&_mk_object_accessor, None),          clone_arg => 1},
    accessors       => {installer => _curry(\&_mk_object_accessor, None),          clone_arg => 1}, # alias for object
    object_ro       => {installer => _curry(\&_mk_object_accessor, IsReadonly),    clone_arg => 1},
    getters         => {installer => _curry(\&_mk_object_accessor, IsReadonly),    clone_arg => 1}, # alias for object_ro
    constructor     => {installer => \&_mk_constructor,                            clone_arg => undef},
);

sub import {
    my $pkg = shift;
    return unless scalar @_;

    my %opts = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;
    my $class = delete $opts{package} // caller;

    for my $type (keys %opts) {
        my $accessors = $opts{$type};
        my ($installer, $clone_arg) = $pkg->_type_installer($type);

        if (ref($accessors) eq 'HASH') {
            $installer->($class, $_, $accessors->{$_}) for keys %$accessors;

        } elsif (ref($accessors) eq 'ARRAY') {
            $installer->($class, $_, $clone_arg && $_) for @$accessors;

        } elsif (!ref($accessors)) {
            $installer->($class, $accessors, $clone_arg && $accessors);

        } else {
            confess("Can't understand format for '$type' accessors initializer");
        }
    }
}

sub register_types {
    register_type(shift, shift) while scalar @_;
}

sub is_type_registered { exists $REGISTERED_TYPES->{$_[0]} }

sub register_type {
    my ($type, $args) = @_;

    if (exists $REGISTERED_TYPES->{$type}) {
        confess("Type '$type' has already been registered");
    }

    if (!exists $args->{installer}) {
        $args->{installer} = sub {
            my ($class, $name, $field) = @_;
            install_inherited_cb_accessor(
                "${class}::${name}", $field, $PREFIX.$field,
                $args->{read_cb} // $args->{on_read}, $args->{write_cb} // $args->{on_write},
                $args->{opts} // 0,
            );
        };
    }

    $args->{clone_arg} = 1 unless exists $args->{clone_arg}; # for cb-types
    $REGISTERED_TYPES->{$type} = $args;
}

#
#   Functions below are NOT part of the public API
#

sub _curry {
    my ($sub, @args) = @_;

    return sub {
        $sub->(@_, @args);
    };
}

sub _type_installer {
    my (undef, $type) = @_;

    my $type_info = $REGISTERED_TYPES->{$type} or confess("Don't know how to install '$type' accessors");
    return ($type_info->{installer}, $type_info->{clone_arg});
}

sub _mk_inherited_accessor {
    my ($class, $name, $field, $flags) = @_;

    install_inherited_accessor("${class}::${name}", $field, $PREFIX.$field, $flags);
}

sub _mk_class_accessor {
    my ($class, $name, $default, $is_varclass, $flags) = @_;

    install_class_accessor("${class}::${name}", $default, $is_varclass, $flags);
}

sub _mk_object_accessor {
    my ($class, $name, $field, $flags) = @_;

    install_object_accessor("${class}::${name}", $field, $flags);
}

sub _mk_constructor {
    my ($class, $name) = @_;

    install_constructor("${class}::${name}");
}

1;
__END__

=head1 NAME

Class::Accessor::Inherited::XS - Fast XS inherited, object and class accessors

=head1 SYNOPSIS

  # install accessors at compile time
  use Class::Accessor::Inherited::XS 
      package      => 'Pkg', # optionally install into another package
      constructor  => 'new', # object constructor name
      inherited    => 'foo', # inherited accessor for class/object
      object       => 'foo', # non-inherited simple object accessor
      varclass     => 'foo', # non-inherited accessor for __PACKAGE__,  aliased with '$__PACKAGE__::foo' variable
      class        => 'foo', # non-inherited anonymous accessor for __PACKAGE__
  ;
  
  use Class::Accessor::Inherited::XS {  # optional braces
      inherited => {foo => 'foo_key'},  # change package variable/hash key
      object    => {foo => 'foo_key'},  # change hash key
      class_ro  => {foo => $default},   # class_ro, varclass_ro, class, varclass set default values instead
      class     => {foo => $subref},    # lazy accessor initializer
      varclass  => ['foo', 'bar'],      # provide a list of accessor names
      accessors => ['foo'],             # alias for 'object'
      getters   => ['foo'],             # alias for 'object_ro'
  };

  # Or if you prefer a Class::Accessor::Grouped-like interface, you can do it
  # at run time. Note that this is not recommended and provides limited feature set.
  use parent 'Class::Accessor::Inherited::XS::Compat';

  __PACKAGE__->mk_inherited_accessors('foo', [bar => 'bar_key']);
  __PACKAGE__->mk_class_accessors('foo');
  __PACKAGE__->mk_varclass_accessors('foo');
  __PACKAGE__->mk_object_accessors('foo');

=head1 DESCRIPTION

This module provides a very fast implementation for a wide range of accessor types.

B<inherited> accessors have been introduced by L<Class::Accessor::Grouped>. They allow you to override
values set in a parent class with values set in childs or object instances. This module tries to be compatible
with L<Class::Accessor::Grouped> as much as possible.

Since this module focuses primary on speed, it provides no means to have your own per-class
getters/setters logic (like overriding L<Class::Accessor::Grouped/get_inherited> / L<Class::Accessor::Grouped/set_inherited>),
but it allows you to create new inherited accesor types with an attached callback.

B<class> and B<varclass> accessors are non-inherited package accessors - they return values from the class
they were defined in, even when called on objects or child classes. The difference between them is that
the B<varclass> internal storage is a package variable with the same name, while B<class> stores it's value
in an anonymous variable.

B<object> accessors provides plain simple hash key access.

B<class_ro>, B<varclass_ro>, B<inherited_ro>, B<object_ro> are readonly counterparts for correspoding accessors
without B<_ro> suffix. They behave exactly the same except that they will croak upon a call with arguments.
To set values for such accessors, you can write to either corresponding package variable or a hash key. B<ro_class>
accessor has no externally accessible storage, but you can provide a default value for it using hash
initializer syntax.

B<lazy> accessors do not have their own keyword but, instead, if you pass a subref as a default argument
to any one of the B<package> accessors' family, it's not stored as-is, but is called instead upon the first accessor
read and it's return value is stored. After that, B<lazy> accessor becomes a normal one of the same type. Calling
an accessor as a setter before first getter will loose it's defaultness (unless, of course, it's a readonly one).

B<constructor> can create objects either from a list or from a single hashref. Note that if you pass
a hash reference, it becomes blessed too. If that's not what you want, pass a dereferenced copy. As a
special case, passing a single B<undef> returns you an empty object.

    __PACKAGE__->new(foo => 1, bar => 2); # values are copied
    __PACKAGE__->new(\%args);             # values are not copied, much faster
    $obj->new(foo => 1, bar => 2);        # values are copied, but nothing is taken from $obj
    $obj->new(\%args);                    # values are not copied, and nothing is taken from $obj

=head1 UTF-8 AND BINARY SAFETY

Starting with the perl 5.16.0, this module provides full support for UTF-8 method names and hash keys.
But on older perls you can't distinguish UTF-8 strings from bytes string in method names, so accessors
with UTF-8 names can end up getting a wrong value. You have been warned.

Also, starting from 5.16.0 accessor installation is binary safe, except for the Windows platform.
This module croaks on attempts to install binary accessors on unsupported platforms.

=head1 THREADS

Though highly discouraged, perl threads are supported by L<Class::Accessor::Inherited::XS>. You can
have accessors with same names pointing to different keys in different threads, etc. There are
no known conceptual leaks.

=head1 PERFORMANCE

L<Class::Accessor::Inherited::XS> is at least 10x times faster than L<Class::Accessor::Grouped>, depending
on your usage pattern. Inherited accessors have constant speed even in large inheritance chains. Object accessors
are even faster than L<Class::XSAccessor> ones.

Accessors with just an empty sub callback are ~3x times slower then normal ones, so use them only when absolutely necessary.

Here are results from a benchmark run on perl 5.20.1 (see bench folder):

                       Rate pkg_gparent_cag pkg_cag obj_cag obj_caix_cb pkg_set_caix pkg_gparent_caix pkg_caix obj_cxa obj_caix obj_direct class_caix
pkg_gparent_cag    233829/s              --    -77%    -82%        -96%         -98%             -98%     -98%    -99%     -99%       -99%       -99%
pkg_cag           1022855/s            337%      --    -21%        -84%         -89%             -90%     -90%    -94%     -95%       -96%       -97%
obj_cag           1302727/s            457%     27%      --        -80%         -86%             -87%     -87%    -92%     -94%       -95%       -96%
obj_caix_cb       6377179/s           2627%    523%    390%          --         -33%             -36%     -37%    -62%     -69%       -76%       -80%
pkg_set_caix      9538400/s           3979%    833%    632%         50%           --              -4%      -6%    -43%     -54%       -64%       -70%
pkg_gparent_caix  9914704/s           4140%    869%    661%         55%           4%               --      -2%    -41%     -52%       -62%       -68%
pkg_caix         10138654/s           4236%    891%    678%         59%           6%               2%       --    -40%     -51%       -61%       -68%
obj_cxa          16858257/s           7110%   1548%   1194%        164%          77%              70%      66%      --     -19%       -36%       -46%
obj_caix         20811071/s           8800%   1935%   1498%        226%         118%             110%     105%     23%       --       -20%       -34%
obj_direct       26145035/s          11081%   2456%   1907%        310%         174%             164%     158%     55%      26%         --       -16%
class_caix       31300776/s          13286%   2960%   2303%        391%         228%             216%     209%     86%      50%        20%         --


=head1 EXTENDING

    package MyAccessor;
    # 'register_type' isn't exported
    Class::Accessor::Inherited::XS::register_type(
        inherited_cb => {on_read => sub {}, on_write => sub{}},
    );

    package MyClass;
    use MyAccessor;
    use Class::Accessor::Inherited::XS {
        inherited    => ['foo'],
        inherited_cb => ['bar'],
    };

You can register new inherited accessor types with associated read/write callbacks. Unlike
L<Class::Accessor::Grouped>, only a single callback can be set for a type, without per-class
B<get_$type>/B<set_$type> lookups. You can omit either B<on_read> or B<on_write> if you don't
need it to avoid performance losses from associated call.

B<on_read> callback receives a single argument - return value from the underlying B<inherited> accessor. It's result
is the new accessor's return value (and it isn't stored anywhere).

B<on_write> callback receives original accessor's arguments, and it's return value is stored as usual.
Exceptions thrown from this callback will cancel store and will leave old value unchanged.

=head1 PROFILING WITH Devel::NYTProf

To perform it's task, L<Devel::NYTProf> hooks into the perl interpreter by replacing default behaviour for subroutine calls
at the opcode level. To squeeze last bits of performance, L<Class::Accessor::Inherited::XS> does the same, but separately
on each call site of its accessors. It turns out into CAIX favor - L<Devel::NYTProf> sees only the first call to CAIX
accessor, but all subsequent ones become invisible to the subs profiler.

Note that the statement profiler still correctly accounts for the time spent on each line, you just don't see time spent in accessors'
calls separately. That's sometimes OK, sometimes not - you get profile with all possible optimizations on, but it's not easy to comprehend.

Since it's hard to detect L<Devel::NYTProf> (and any other module doing such magic) in a portable way (all hail Win32), there's
an %ENV switch available - you can set CAIXS_DISABLE_ENTERSUB to a true value to disable opcode optimizations and get a full subs profile.

=head1 CAVEATS

When using B<varclass> accessors, do not clear or alias C<*__PACKAGE__::accessor> glob - that will break aliasing between accessor storage
and $__PACKAGE__::accessor variable. While the stored value is still accessible through accessor, it effectively becomes a B<class> one.

=head1 SEE ALSO

=over

=item * L<Class::Accessor::Grouped>

=item * L<Class::XSAccessor>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Vladimir Timofeev

Copyright (C) 2014-2018 by Sergey Aleynikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
