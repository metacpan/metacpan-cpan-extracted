

use strict;
use 5.005;
package Class::Constructor;
use Carp;
use File::Spec;

use vars qw($VERSION);

$VERSION = '1.1.4';

=head1 NAME

Class::Constructor - Simplify the creation of object constructors

=head1 SYNOPSIS

    package MyPackage;

    # Note if you don't have the CLASS package installed,
    # you can use the __PACKAGE__ keyword instead

    use CLASS;
    use base qw/ Class::Constructor Class::Accessor /;

    my @Accessors = qw(
        some_attribute
        another_attribute
        yet_another_attribute
    );

    CLASS->mk_accessors(@Accessors);
    CLASS->mk_constructor(
        Name           => 'new',
        Auto_Init      => \@Accessors,
    );

=head1 DESCRIPTION

Simplifies the creation of object constructors.

Instead of writing:

    sub new {
        my $proto = shift;
        my $class = ref $proto || $proto;
        my $self = {};
        bless $self, $class;

        my %args = @_;
        foreach my $attr ('first_attribute', 'second_attribute') {
            $self->$attr($args{$attr});
        }

        $self->_init();

        return $self;
    }

You can just write:

    CLASS->mk_constructor(
        Auto_Init      => [ 'first_attribute', 'second_attribute' ],
    );

There are other features as well:

=over 4

=item Automatically call other initialization methods.

Using the C<Init_Methods> method of C<mk_constructor>,
you can have your constructor method automatically call
one or more initialization methods.

=item Automatic Construction of objects of Subclasses

Your constructor can bless objects into one of
its subclasses.

For instance, the C<Fruit> class could bless objects
into the C<Fruit::Apple> or C<Fruit::Orange> classes
depending on a parameter passed to the constructor.

See L<Subclass_Param> for details.

=back

=head1 METHOD

=head2 mk_constructor

    CLASS->mk_constructor(
        Name           => 'new',
        Init_Methods   => [ '_init' ],
        Subclass_Param => 'Package_Type',
        Auto_Init      => [ 'first_attribute', 'second_attribute' ],
    );

The C<mk_constructor> method creates a constructor named C<Name> in
C<CLASS>'s namespace.

=over 4

=item Name

The name of the constructor method.  The default is C<new>.

=item Init_Methods

Cause the created constructor to call the listed methods
on all new objects that are created via the constructor.

    Foo->mk_constructor(
        Name           => 'new',
        Init_Methods   => '_init',
    );

    my $object = Foo->new; # This calls $object->_init();


    Foo->mk_constructor(
        Name           => 'new',
        Init_Methods   => [ '_init', '_startup' ],
    );

    my $object = Foo->new; # after construction, new()
                           # calls $object->_init(),
                           # then $object->_startup()


=item Auto_Init

A list of attributes that should be automatically initialized via the
parameters to the constructor.

For each name/value pair passed to the constructor, the constructor
will call the method named C<name> with the parameter of C<value>.

For instance, if you make your constructor with:

    Fruit->mk_constructor(
        Auto_Init      => [ 'size', 'colour' ],
    );

And you call the constructor with:

    use Fruit;
    my $fruit = Fruit->new(
        size   => 'big',
        colour => 'red',
    );

Then, internally, the C<new> constructor will automatically call the
following methods:

    $fruit->size('big');
    $fruit->colour('red');

Note that by default, C<Class::Constructor> converts names to lower
case. See C<CASE SENSITIVITY>, below.

=item Required_Params

A list of params that must be passed to the constructor when the object
is created.  If these items are not already listed as C<Auto_Init>
methods, they will be added to the C<Auto_Init> list.

    Fruit->mk_constructor(
        Required_Params      => [ 'size', 'price' ],
    );

    package main;

    use Fruit;
    my $fruit = Fruit->new;  # error, missing size, price

    my $fruit = Fruit->new(  # error: missing price
        size   => 'big'
    );

    my $fruit = Fruit->new(  # okay
        size   => 'big',
        price  => 0.25,
    );


=item Disable_Case_Mangling

Set this to a true value if you don't want Class::Constructor to force
attribute names to lower case.  See C<CASE SENSITIVITY>, below.

=item Disable_Name_Normalizing

Another name for C<Disable_Case_Mangling>, above.

=item Method_Name_Normalizer

Custom subroutine for converting a parameter passed to auto_init into a
attribute name.  See C<CASE SENSITIVITY>, below.

=item Class_Name_Normalizer

Custom subroutine for converting a subtype class into a Perl class name.
See C<CASE SENSITIVITY>, below.

=item Param_Name_Normalizer

Custom subroutine to be applied to params passed to the constructor in
order to recognize special ones, such as those that are required by
C<Required_Params> and the special C<Subclass_Param>.  See C<CASE
SENSITIVITY>, below.

=item Subclass_Param

You can cause the constructor to make instances of a subclass,
based on the a special parameter passed to the constructor:

    # Fruit.pm:
    package Fruit;
    Fruit->mk_constructor(
        Name           => 'new',
        Subclass_Param => 'Type',
    );

    sub has_core { 0 };

    # Fruit/Apple.pm:
    package Fruit::Apple;
    use base 'Fruit';

    sub has_core { 1 };

    # main program:
    package main;

    my $apple = Fruit->new(
        Type => 'Apple',
    );

    if ($apple->has_core) {
        print "apples have cores!\n";
    }

=item Dont_Load_Subclasses_Param

The name of the parameter that will be checked by the constructor
to determine whether or not subclasses specified by C<Subclass_Param>
will be loaded or not.  This is mainly useful if you are writing
test scripts and you want to load in your packages manually.

For instance:

    # Fruit.pm:
    package Fruit;
    Fruit->mk_constructor(
        Name                     => 'new',
        Subclass_Param           => 'type',
        Dont_Load_Subclass_Param => 'Dont_Load_Subclass',
    );

    # main program:
    package main;

    my $apple = Fruit->new(
        Type               => 'Apple',
        Dont_Load_Subclass => 1,
    );

Now when the C<$apple> object is created, the constructor makes no
attempt to require the C<Fruit::Apple> module.

=back

=head1 CASE SENSITIVITY

By default, attribute names are forced to lower case and
the case of C<Auto_Init> parameter names passed to the constructor
doesn't matter.

So the following call to a constructor:

    my $fruit = Fruit->new(
        SiZE   => 'big',
        colOUR => 'red',
    );

Is actually equivalent to:

    my $fruit = Fruit->new();
    $fruit->size('big');
    $fruit->colour('red');

You can disable this behaviour by setting C<Disable_Case_Mangling>
to a true value:

    package Fruit;
    Fruit->mk_constructor(
        Disable_Case_Mangling => 1,
    );

Now the parameters are left unchanged:

    my $fruit = Fruit->new(
        SiZE   => 'big',
        colOUR => 'red',
    );

    # equivalent to:
    my $fruit = Fruit->new();
    $fruit->SiZE('big');
    $fruit->colOUR('red');


Similarly for class names as passed via C<Subclass_Param>, they are
converted to lower case and then the first letter is uppercased.

    # the following creates a Fruit::Apple
    my $apple = Fruit->new(
        Type => 'APPLE',
    );

This behaviour is also disabled via C<Disable_Case_Mangling>:

    package Fruit;
    Fruit->mk_constructor(
        Subclass_Param        => 'Type',
        Disable_Case_Mangling => 1,
    );

    # the following creates a Fruit::APPLE
    my $apple = Fruit->new(
        Type => 'APPLE',
    );

=head2 Advanced: Customizing Class, Method and Param normalization.

Note that this is an advanced feature with limited use, so you can
probably skip it.

If you want to customize the way C<Class::Constructor> changes method
names, you can pass subroutines to do the work:

    package Fruit;
    Fruit->mk_constructor(
        Subclass_Param         => 'Type',
        Method_Name_Normalizer => sub { '_' . lc $_[0] }, # precede lc methods with underscore
        Param_Name_Normalizer  => sub { uc $_[0] },       # params compared as upper case
        Class_Name_Normalizer  => sub { uc $_[0] },       # class names to uppercase
        Required_Params        => [ 'Size' ],
    );

    # the following creates a Fruit::APPLE
    my $apple = Fruit->new(
        Type            => 'apple',
        SiZE            => 'big',
        colOUR          => 'red',
    );

    # and the above is equivalent to:
    my $apple = Fruit->new(
        type   => 'apple',
    );

    $apple->_SiZE('big');
    $apple->_colOUR('red');

In the example above, the C<Method_Name_Normalizer> causes auto_init to
make convert parameter names into method names as follows:

    SiZE    => _size
    colOUR  => _colour

The C<Class_Name_Normalizer> converts the value of C<Type> (the
C<Subclass_Param>) into method names as follows:

    apple   => APPLE

The C<Param_Name_Normalizer> converts param names to upper case before
comparing them.  So C<Subclass_Param> is specified to be C<Type>, and is
eventually passed as C<type>.  But since both are normalized to C<TYPE>,
the match is found.

=cut

sub mk_constructor {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %params = @_;

    my $constructor_name = $params{Name} || 'new';

    {
        no strict 'refs';
        return if defined &{"$class\:\:$constructor_name"};
    }

    my $normalization    = 1;
    undef $normalization if $params{Disable_Name_Normalization};
    undef $normalization if $params{Disable_Case_Mangling};

    my $method_name_normalize = $params{Method_Name_Normalizer} || sub { lc $_[0] };
    my $param_name_normalize  = $params{Param_Name_Normalizer}  || sub { lc $_[0] };
    my $class_name_normalize  = $params{Class_Name_Normalizer}  || sub { ucfirst lc $_[0] };

    my $subclass_param_name      = $normalization ? &$param_name_normalize($params{Subclass_Param})
                                                  : $params{Subclass_Param};


    my $dont_load_subclass_param = $params{Dont_Load_Subclass_Param};

    foreach my $param (qw/Auto_Init Init_Method Init_Methods/) {
        next unless exists $params{$param};
        $params{$param} = [ $params{$param} ] unless ref $params{$param} eq 'ARRAY';
    }

    my @init_methods;
    push @init_methods, @{ $params{'Init_Method'} }  if exists $params{'Init_Method'};
    push @init_methods, @{ $params{'Init_Methods'} } if exists $params{'Init_Methods'};

    my @auto_init;
    push @auto_init, @{ $params{'Auto_Init'} } if exists $params{'Auto_Init'};


    my @required_params;
    if (exists $params{'Required_Params'}) {
        if ($normalization) {
            push @required_params, map { &$param_name_normalize($_) } @{ $params{'Required_Params'} };
        }
        else {
            push @required_params, @{ $params{'Required_Params'} };
        }
    }

    my %auto_init;

    foreach my $param (@required_params) {
        unless ($auto_init{$param}) {
            push @auto_init, $param;
            $auto_init{$param} = 1;
        }
    }


    if ($normalization) {
        %auto_init = map { &$method_name_normalize($_) => 1 } @auto_init;
    }
    else {
        %auto_init = map { $_ => 1 } @auto_init;
    }

    my $constructor = sub {
        my $proto = shift;
        my $class = ref $proto || $proto;

        my %params = @_;
        my $self = {};

        my %normalized_params;

        if ($normalization) {
            %normalized_params = map { &$param_name_normalize($_) => $params{$_}} keys %params;
        }
        else {
            %normalized_params = map { $_ => $params{$_} } keys %params;
        }

        my $load_subclasses = 1;

        if (defined $dont_load_subclass_param) {
            if (exists $params{$dont_load_subclass_param} and $params{$dont_load_subclass_param}) {
                delete $params{$dont_load_subclass_param};
                $load_subclasses = 0;
            }
        }


        # Check for parameters flagged as required.  Throw an exception if
        # there is one missing.

        my @missing_required;
        foreach my $required_param (@required_params) {
            if ($normalization) {
                next if exists $normalized_params{ &$param_name_normalize($required_param) };
            }
            else {
                next if exists $params{ $required_param };
            }
            push @missing_required, $required_param;
        }
        if (@missing_required) {
            die "$class: Missing required parameter(s): ". (join ', ', @missing_required). "\n";
        }

        if ($subclass_param_name) {

            my $subclass;

            if ($normalization) {

                if (exists $normalized_params{$subclass_param_name}) {
                    $subclass       = &$class_name_normalize($normalized_params{$subclass_param_name});
                }
            }
            else {
                # subclass param is fixed
                if (exists $params{$subclass_param_name}) {
                    $subclass       = $params{$subclass_param_name};
                }
            }

            if ($subclass) {
                $class .= "::$subclass";

                if ($load_subclasses) {
                    my @class_fn = split /::/, $class;
                    my $class_fn = File::Spec->join(split /::/, $class);
                    $class_fn   .= '.pm';

                    require $class_fn;
                }
            }
        }

        bless $self, $class;

        foreach my $attr (keys %params) {
            my $method = $normalization ? &$method_name_normalize($attr) : $attr;
            if ($auto_init{$method}) {
                $self->$method($params{$attr});
            }
            else {
                unless (@init_methods) {
                    croak "Can't autoinitialize method $method from $attr\n";
                }
            }
        }

        foreach my $init_method (@init_methods) {
            $self->$init_method(@_);
        }

        return $self;
    };

    {
        no strict 'refs';
        *{"$class\:\:$constructor_name"} = $constructor;
    }
    return 1;
}

1;

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2001 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

=over 4

=item Class::Accessor

=item CLASS

=back

=cut
