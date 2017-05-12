package Ambrosia::Meta;
use strict;
no strict 'refs';
use warnings;
no warnings 'redefine';

use base qw/Exporter/;
our @EXPORT = qw/class abstract sealed inheritable/;

use Ambrosia::Assert;
use Ambrosia::error::Exceptions;
require Ambrosia::core::Object;

our $VERSION = 0.010;

#fields
sub __PRIVATE()   { 1 }
sub __PUBLIC()    { 2 }
sub __PROTECTED() { 3 }
sub __FRIENDS()   { 4 }

#classes
sub __ABSTRACT()    { 1 }
sub __SEALED()      { 2 }
sub __INHERITABLE() { 3 }

my %FIELDS_ACCESS = (
        private   => &__PRIVATE,
        protected => &__PROTECTED,
        public    => &__PUBLIC,
        friends   => &__FRIENDS,
    );

my %CLASS_TYPE = (
        abstract    => &__ABSTRACT,
        sealed      => &__SEALED,
        inheritable => &__INHERITABLE,
    );

sub import
{
    my $proto = shift;

    assert {$proto eq __PACKAGE__} "'$proto' cannot be inherited from sealed class '" . __PACKAGE__ . '\'.';
    #throw Ambrosia::error::Exception("'$proto' cannot be inherited from sealed class '" . __PACKAGE__ . '\'.') if $proto ne __PACKAGE__;

    my $INSTANCE_CLASS = caller(0);
    unless ( eval { $INSTANCE_CLASS->isa('Ambrosia::core::Object') } )
    {
        @{$INSTANCE_CLASS . '::ISA'} = ();
        my $ISA = \@{$INSTANCE_CLASS . '::ISA'};
        unshift @$ISA, 'Ambrosia::core::Object';
    }

    $proto->export_to_level(1, $proto, @EXPORT);
}

sub abstract(@)
{
    return abstract => @_;
}

sub sealed(@)
{
    return sealed => @_;
}

sub inheritable(@)
{
    return inheritable => @_;
}

sub class(@)
{
    my $INSTANCE_CLASS;

# You can create your class
# 1. so: class {} or equalent class inheritable {}
# 2. or so: class abstract {}
# 3. and so: class sealed {}
#
    my ( $clsType, $params ) = @_ == 1 ? (&__INHERITABLE, shift) : ( @_ == 2 ? ($CLASS_TYPE{lc(+shift)}, shift) : (&__INHERITABLE, {}) );

    if ( defined $params->{package} )
    {
        $INSTANCE_CLASS = $params->{package};
        delete $params->{package};
        unless ( eval { $INSTANCE_CLASS->isa('Ambrosia::core::Object') } )
        {
            @{$INSTANCE_CLASS . '::ISA'} = ();
            my $ISA = \@{$INSTANCE_CLASS . '::ISA'};
            unshift @$ISA, 'Ambrosia::core::Object';
        }
    }
    else
    {
        $INSTANCE_CLASS = caller(0);
    }

    my $alias = {};
    if ( defined $params->{alias} )
    {
        $alias = $params->{alias};
        delete $params->{alias};
    }

    return if ${"$INSTANCE_CLASS\::__AMBROSIA_INSTANCE__"};
    ${"$INSTANCE_CLASS\::__AMBROSIA_INSTANCE__"} = $clsType;

    *{$INSTANCE_CLASS.'::__AMBROSIA_IS_ABSTRACT__'} = sub() {${"$INSTANCE_CLASS\::__AMBROSIA_INSTANCE__"} == &__ABSTRACT};

    *{"$INSTANCE_CLASS\::__AMBROSIA_ALIAS_FIELDS__"} = sub() { $alias };
    %{"$INSTANCE_CLASS\::__AMBROSIA_INTERNAL_FLDS__"} = ();
    my $__FIELDS__ = \%{"$INSTANCE_CLASS\::__AMBROSIA_INTERNAL_FLDS__"};

    my %__PARENT__ = ();

################################################################################
#   Обрабатываем базовые классы
#   Заполняю $__FIELDS__ списком полей
################################################################################
    my $ISA = \@{$INSTANCE_CLASS . '::ISA' || []};
    my @PUB_FLDS = ();

    foreach my $inheritable (qw<extends implements>)
    {
        next unless exists $params->{$inheritable};

        foreach my $package ( @{$params->{$inheritable}} )
        {
            unless ( eval {$package->VERSION} )
            {
                if ( eval qq{require $package;} )
                {
                    eval {$package->import; 1;}
                    or throw Ambrosia::error::Exception 'Cannot import ' . $package . ': ', $@;
                    if ( (${"$package\::__AMBROSIA_INSTANCE__"} || -42) == &__SEALED )
                    {
                        throw Ambrosia::error::Exception $INSTANCE_CLASS . ' cannot be inherited from sealed class ' . $package;
                    }
                }
                else
                {
                    throw Ambrosia::error::Exception 'Cannot require ' . $package . ': ', $@;
                }
            }
            unshift @$ISA, $package;

            foreach my $f ( keys %{"$package\::__AMBROSIA_INTERNAL_FLDS__"} )
            {
                $__PARENT__{$f} = !exists $__PARENT__{$f} ? $package : throw Ambrosia::error::Exception "Duplicate field $f for $package that exists one of a base class.";
            }
            push @PUB_FLDS, $package->fields if eval { $package->can('fields') };
        }
        delete $params->{$inheritable};
    }

    ############################################################################
    #create property for class
    my @__FRIENDS__;
    if (exists $params->{friends})
    {
        @__FRIENDS__ = @{$params->{friends}};
        delete $params->{friends};
    }

    my $pos = 0;
    foreach ( keys %$params )
    {
        my $access = $FIELDS_ACCESS{$_} or throw Ambrosia::error::Exception "Unknown keyword: $_.";
        foreach my $fn ( @{$params->{$_}} )
        {
            throw Ambrosia::error::Exception "Duplicate field $fn for $INSTANCE_CLASS that exists in one of a base class."
                if exists $__PARENT__{$fn};

            my $f = defined $alias->{$fn} ? $alias->{$fn} : $fn;

            if ( __PUBLIC == $access )
            {
                if ( $clsType == &__SEALED )
                {
                    my $p = $pos;
                    *{"${INSTANCE_CLASS}::$f"} = sub() : lvalue {
                            $_[0]->[0]->[$p];
                        };
                }
                else
                {
                    *{"${INSTANCE_CLASS}::$f"} = sub() : lvalue {
                            $_[0]->[1]->{$fn}
                        };
                }
                push @PUB_FLDS, $fn;
                $__FIELDS__->{$fn} = __PUBLIC;
            }
            elsif ( __PROTECTED == $access )
            {
                *{"${INSTANCE_CLASS}::$f"} = sub() : lvalue {
#may be used assert????
                    my $_caller = caller;
                    unless ( $INSTANCE_CLASS eq $_caller || $_caller eq 'Ambrosia::core::Object' || eval{$_[0]->isa($_caller)} )
                    {
                        throw Ambrosia::error::Exception::AccessDenied "Access denied for $_caller. ${INSTANCE_CLASS}::$f() is a protected field of $INSTANCE_CLASS!"
                            unless ( grep { $_caller eq $_ }  @__FRIENDS__ );
                            #unless ( $_caller ~~ @__FRIENDS__ );
                    }
                    $_[0]->[1]->{$fn};
                };
                $__FIELDS__->{$fn} = __PROTECTED;
            }
            elsif ( __PRIVATE == $access )
            {
                if ( $clsType == &__SEALED )
                {
                    my $p = $pos;
                    *{"${INSTANCE_CLASS}::$f"} = sub() : lvalue {
                        my $_caller = caller;
                        unless ( $_caller eq $INSTANCE_CLASS || $_caller eq 'Ambrosia::core::Object' )
                        {
                            throw Ambrosia::error::Exception::AccessDenied "Access denied for $_caller. ${INSTANCE_CLASS}::$f() is a private field of $INSTANCE_CLASS!"
                                unless ( grep { $_caller eq $_ }  @__FRIENDS__ );
                                #unless ( $_caller ~~ @__FRIENDS__ );
                        }
                        $_[0]->[0]->[$p];
                    };
                }
                else
                {
                    *{"${INSTANCE_CLASS}::$f"} = sub() : lvalue {
                        my $_caller = caller;
                        unless ( $_caller eq $INSTANCE_CLASS || $_caller eq 'Ambrosia::core::Object' )
                        {
                            throw Ambrosia::error::Exception::AccessDenied "Access denied for $_caller. ${INSTANCE_CLASS}::$f() is a private field of $INSTANCE_CLASS!"
                                unless ( grep { $_caller eq $_ }  @__FRIENDS__ );
                                #unless ( $_caller ~~ @__FRIENDS__ );
                        }
                        $_[0]->[1]->{$fn};
                    };
                }
                $__FIELDS__->{$fn} = __PRIVATE;
            }
            $pos++;
        }
    }

    *{"${INSTANCE_CLASS}::fields"} = sub() { return @PUB_FLDS };
    *{"${INSTANCE_CLASS}::parent_fields"} = sub() { return keys %__PARENT__ };

    if ( eval {$INSTANCE_CLASS->can('__AMBROSIA_ATTR_ACTION__')} )
    {
        my $h = $INSTANCE_CLASS->__AMBROSIA_ATTR_ACTION__;
        foreach my $ref ( keys %$h )
        {
            my $sym = findsym($h->{$ref}->[0], $h->{$ref}->[1]);
            if ( $sym )
            {
                foreach (@{$h->{$ref}->[2]})
                {
                    s/^(\w+)\(?.*/$1/;
                    $_->($INSTANCE_CLASS, $h->{$ref}->[0], $sym, $h->{$ref}->[1]);
                }
                delete $h->{$ref};
                *{$INSTANCE_CLASS . '::__AMBROSIA_ATTR_ACTION__'} = sub { return $h };
            }
        }
    }
    return 1;
}

################################################################################

sub Private
{
    my($class, $package, $symbol, $referent) = @_;
    no warnings 'redefine';
    *{$symbol} = sub {
            if (caller eq $package)
            {
                goto &$referent;
            }
            else
            {
                throw Ambrosia::error::Exception $package . '::' . *{$symbol}{NAME} . ': access denied for ' . ref $_[0];
            }
        };
}

sub Override
{
    my($class, $package, $symbol, $referent) = @_;
    no warnings 'redefine';
    *{$symbol} = sub {
            goto &$referent;
        };
}

sub Abstract
{
    my($class, $package, $symbol, $referent) = @_;
    no warnings 'redefine';
    ${$class.'::__AMBROSIA_INSTANCE__'} = &__ABSTRACT;
    *{$symbol} = sub {
            throw Ambrosia::error::Exception *{$symbol}{NAME} . ' is abstract method.';
        };
}

sub Protected
{
    my($class, $package, $symbol, $referent) = @_;
    no warnings 'redefine';
    *{$symbol} = sub {
            my $caller = caller;
            if (eval{$caller->isa($package)})
            {
                goto &$referent;
            }
            else
            {
                throw Ambrosia::error::Exception $package . '::' . *{$symbol}{NAME} . ': access denied for ' . $caller;
            }
        };
}

sub Public
{
}

sub Static
{
}

my %symcache;
sub findsym
{
    my ($pkg, $ref, $type) = @_;
    return $symcache{$pkg,$ref} if $symcache{$pkg,$ref};
    $type ||= ref($ref);

    no strict 'refs';
    foreach my $sym ( values %{$pkg."::"} )
    {
        use strict;
        next unless ref ( \$sym ) eq 'GLOB';
        return $symcache{$pkg,$ref} = \$sym
            if *{$sym}{$type} && *{$sym}{$type} == $ref;
    }
    return undef;
}

1;

__END__

=head1 NAME

Ambrosia::Meta - another tool to build classes for Perl 5.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    package MyClass;

    use Ambrosia::Meta;

    class
    {
        extends   => [qw/base_class1 base_class2/],
        public    => [qw/public_field1 public_field2/],
        protected => [qw/protected_field1 protected_field2/],
        private   => [qw/private_field1 private_field2/],
    };

    sub next
    {
        my $self = shift;
        return $self->private1++;
    }

    1;

=cut

=head1 DESCRIPTION

Ambrosia::Meta used to create classes with the definition of access rights to the fields.
I<Ambrosia::Meta is a sealed class>, you cannot use it as base class for your classes.

You can mark the created class one of qualifiers, such as I<inheritable> (the default), I<abstract> and I<sealed>:

    class inheritable
    {
    };

or equivalent

    class
    {
    };

    class abstract
    {
    };

    class sealed
    {
    };

=over 4

=item class inheritable

The usual definition of the class.

=item class abstract

If you mark your class as I<abstract> it means that you cannot create an object with type of this class.

=item class sealed

This means that you cannot derive a class from it.

=back

=head2 KEYWORDS

=over 4

=item extends

This is the reference to the list of base classes.

=item public

This is the reference to the list of public fields.

=item protected

This is the reference to the list of protected fields.

=item private

This is the reference to the list of private fields.

=back

=head2 ATTRIBUTES

In your class created with the help of L<Ambrosia::Meta> you can use several predefined attributes for methods of class.

=over 4

=item Public

Does nothing. Just marked that this method is public.

=item Protected

Marks method as protected method.

=item Private

Marks method as private method.

=item Abstract

Marks method as abstract method. If at least one method in class have this attribute this class marks as I<abstract>.

=back

=head1 METHODS

All classes created with the help of L<Ambrosia::Meta> have L<Ambrosia::core::Object> as a base class.

B<WARNING!> Method names in the generated class can not start with "__AMBROSIA". Also, it concerns the package variables.

=head1 DEPENDENCIES

L<Exporter>
L<Ambrosia::error::Exceptions>
L<Ambrosia::core::Object>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 SEE ALSO

L<Ambrosia>
L<Ambrosia::core::Object>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
