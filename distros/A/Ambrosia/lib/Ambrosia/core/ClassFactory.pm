package Ambrosia::core::ClassFactory;
use strict;
use warnings;
use Carp;

use Ambrosia::core::Nil;
use Ambrosia::Assert;
use Ambrosia::error::Exceptions;
require Ambrosia::Meta;

our $VERSION = 0.010;

sub create
{
    my $package = shift;

    my $fields;
    my $type;
    if ( @_ == 1 )
    {
        $type = 'inheritable';
        $fields = shift;
    }
    else
    {
        $type = shift;
        $fields = shift;
    }

    eval
    {
        $fields->{package} = $package;
        Ambrosia::Meta::class($type, $fields);
        no strict 'refs';
        ${$package.'::VERSION'} = 0.001;
    };
    if ( $@ )
    {
        throw Ambrosia::error::Exception 'Error in ClassFactory: ' . $@;
    }
}

sub create_object
{
    my $package = shift;

    my $obj = undef;
    eval
    {
        my ($can_new, $is_load);
        if ($can_new = eval {$package->can('new')} )
        {
            $is_load = 1;
        }
        else
        {
            if ( !eval{$package->VERSION} && eval qq{require $package;} )
            {
                eval {$package->import; 1;} and $is_load = 1;
            }
            else
            {
                croak 'Cannot require ' . $package . ': ' . $@;
            }
        }
        $obj = $package->new( @_ ) if $can_new || ($is_load && eval {$package->can('new')});
    };
    if ( $@ )
    {
        throw Ambrosia::error::Exception 'Error in ClassFactory: ' . $@;
    }
    elsif( $obj )
    {
        return $obj;
    }
    croak 'Cannot create the object of ' . $package;
    return new Ambrosia::core::Nil;
}

sub load_class
{
    my $package = shift;

    assert {defined $package} 'Cannot load class without the package. Caller: ' . caller(0);

    eval
    {
        unless ( eval {$package->VERSION} )
        {
            if ( eval qq{require $package;} )
            {
                eval {$package->import};
            }
            else
            {
                croak 'Cannot require: ' . $package . '; err: ' . $@;
            }
        }
    };
    if ( $@ )
    {
        throw Ambrosia::error::Exception 'Error in ClassFactory: ' . $@;
    }
    return $package;
}

1;

__END__

=head1 NAME

Ambrosia::core::ClassFactory - a factory of classes.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    require Ambrosia::core::ClassFactory;

    #In memory (on fly)
    Ambrosia::core::ClassFactory::create('Employes::Person', {public => qw/FirstName LastName Age/});
    my $p = new Employes::Person(FirstName => 'John', LastName => 'Smith', Age => 33);

    #From module Employes/Person.pm (Employes::Person created by Ambrosia::Meta)
    my $p = Ambrosia::core::ClassFactory::create_object('Employes::Person', (FirstName => 'John', LastName => 'Smith', Age => 33));
    print $p->FirstName; #John

=head1 DESCRIPTION

C<Ambrosia::core::ClassFactory> is a factory of classes that allows to produce classes on the fly,
to create objects of certain type and just to load packages.

=head1 SUBROUTINES

=head2 create ($package, $fields)

    Produces class of represented type dynamically with represented fields.

    create($package, $fields);
    in params:
        $package - name of class ('Foo::Bar::Baz')
        $fields - hash. See L<Ambrosia::Meta>

=head2 create_object ($package, %params)

    Loads the package and creates the appropriate object and initializes it by the specified parameters.

    in params:
        $package - name of class ('Foo::Bar::Baz')
        %params - data hash.

=head2 load_class ($package)

    Imports some semantics into the current package from the named module,
    generally by aliasing certain subroutine or variable names into your package.
    It is exactly equivalent to B<use> but without B<BEGIN>

    in params:
        $package - name of class ('Foo::Bar::Baz')

    equivalent: require Foo::Bar::Baz; Foo::Bar::Baz->import;

=cut

=head1 DEPENDENCIES

L<Ambrosia::core::Exceptions>
L<Ambrosia::Meta>

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
