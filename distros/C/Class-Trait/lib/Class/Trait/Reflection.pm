package Class::Trait::Reflection;

use strict;
use warnings;

our $VERSION = '0.31';

use Class::Trait ();

# constructor

sub new {
    my ( $_class, $_package_or_trait ) = @_;
    my $class = ref($_class) || $_class;
    no strict 'refs';

    # accept a package or an object
    my ( $_trait, $package );
    if ( ref($_package_or_trait)
        && $_package_or_trait->isa("Class::Trait::Config") )
    {
        $_trait  = $_package_or_trait;
        $package = $_trait->name();
    }
    else {
        $package = ref($_package_or_trait) || $_package_or_trait;
        $_trait = ${"${package}::TRAITS"}->clone();
    }

    # we are gonna do that symbol table thang
    my $trait = {
        package_name => $package,

        # we want to clone the trait so that
        # we can mess with it if we want
        trait => $_trait
    };
    bless $trait, $class;
    return $trait;
}

# methods

# accessors

sub getName {
    my ($self) = @_;
    return $self->{trait}->name();
}

sub getSubTraitList {
    my ($self) = @_;
    return wantarray
      ? @{ $self->{trait}->sub_traits() }
      : $self->{trait}->sub_traits();
}

sub getRequirements {
    my ($self) = @_;
    return wantarray
      ? keys %{ $self->{trait}->requirements() }
      : [ keys %{ $self->{trait}->requirements() } ];
}

sub getMethods {
    my ($self) = @_;
    return $self->{trait}->methods();
}

sub getMethodLabels {
    my ($self) = @_;
    return wantarray
      ? keys %{ $self->{trait}->methods }
      : [ keys %{ $self->{trait}->methods } ];
}

sub getConflicts {
    my ($self) = @_;
    return wantarray
      ? keys %{ $self->{trait}->conflicts() }
      : [ keys %{ $self->{trait}->conflicts() } ];
}

sub getOverloads {
    my ($self) = @_;
    return $self->{trait}->overloads();
}

sub getOperators {
    my ($self) = @_;
    return wantarray
      ? keys %{ $self->{trait}->overloads }
      : [ keys %{ $self->{trait}->overloads } ];
}

# other methods

sub loadSubTraitByName {
    my ( $self, $trait_name ) = @_;
    return $self->new( Class::Trait::load_trait($trait_name) );
}

sub getTraitDump {
    my ($self) = @_;
    require Data::Dumper;
    return Data::Dumper::Dumper( { %{ $self->{trait} } } );
}

sub traverse {
    my ( $trait, $function, $depth ) = @_;
    $depth ||= 0;
    $function->( $trait, $depth );
    foreach my $sub_trait_name ( $trait->getSubTraitList() ) {
        my $sub_trait = $trait->loadSubTraitByName($sub_trait_name);
        $sub_trait->traverse( $function, $depth + 1 );
    }
}

1;

__END__

=head1 NAME

Class::Trait::Reflection - Reflection class used to find information about
classes which use Traits.

=head1 SYNOPSIS

The Class::Trait::Reflection class used to find information about classes
which use Traits.

=head1 DESCRIPTION

This class is to be used by other applications as a foundation from which to
build various trait compostion tools. It attempts to decouple others from the
internal representation of traits (currently the Class::Trait::Config object)
and provide a more abstract view of them.

=head1 METHODS

=head2 constructor

=over 4

=item B<new>

If given either a I<Class::Trait::Config object>, I<a blessed perl object
which uses traits> or I<a valid perl package name which uses traits>. This
constructor will return a valid Class::Trait::Reflection object which can be
used to examine the specific properties of the traits utilized.

=back

=head2 accessors

=over 4

=item B<getName>

Returns the name string for the trait.

=item B<getSubTraitList>

Returns an array or an array ref in scalar context) of string names of all the
sub-traits the trait includes.

=item B<getRequirements>

Returns an array (or an array ref in scalar context) of method labels and
operators which represent the requirements for the given trait.

=item B<getMethods>

Returns an hash ref of method label strings to method subroutine references.

=item B<getMethodLabels>

Returns an array (or an array ref in scalar context) of method label strings.

=item B<getConflicts>

Returns an array (or an array ref in scalar context) of method labels and
operators which are in conflict for a given trait. This is only applicable for
COMPOSITE traits.

=item B<getOverloads>

Returns an hash ref of operators to method label strings.

=item B<getOperators>

Returns an array (or an array ref in scalar context) of all the operators for
a given trait.

=back

=head2 Utility methods

=over 4

=item B<loadSubTraitByName>

Given a trait name, this method attempts to load the trait using the
Class::Trait module, and then uses that trait to construct a new
Class::Trait::Reflection object to examine the trait with. This can function
both as a class method and an instance method. 

=item B<getTraitDump>

Returns a Data::Dumper string of the internals of a Class::Trait::Config
object. 

=item B<traverse>

Given a subroutine reference, this method can be used to traverse a trait
heirarchy. The subroutine reference needs to take two parameters, the first is
the current trait being examined, the second is the number representing the
depth within the trait heirarchy. 

Here is an example of printing out the trait heirarchy as tabbed in names:

    my $reflected_trait = Class::Trait::Reflection->new($object_or_package);
    
    $reflected_trait->traverse(sub {
        my ($trait, $depth) = @_;
        print(("   " x $depth), $trait->getName(), "\n");
    });

This should produce output similar to this:

    COMPOSITE
        TCircle
            TMagnitude
                TEquality
            TGeometry
        TColor
            TEquality

Note: COMPOSITE is the placeholder name for an unnamed composite trait such as
the one found in a class.

=back

=head1 SEE ALSO

B<Class::Trait>, B<Class::Trait::Config>

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
