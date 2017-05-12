package Class::LazyFactory;
use 5.006001;
use strict;
use warnings;
use Carp;
use Class::Inspector;
use UNIVERSAL;

our @ISA = qw();

our $VERSION = '0.02';

my $class_config = [
    { }, # element[0] is namespace
    { }, # element[1] is constructor
];

sub initialize_factory {
    my $class = shift;
    my %p = @_;

    (not ref($class))
        or croak "new() must be called as a class method";
    
    # namespace 
    if (exists $p{namespace}) {
        (defined $p{namespace})
            or croak "namespace must be defined";
        $class_config->[0]->{$class} = $p{namespace};
    }
    
    # constructor
    if (exists $p{constructor}) {
        (defined $p{constructor})
            or croak "namespace must be defined";
        $class_config->[1]->{$class} = $p{constructor};
    }
    
}

sub new {
    my $class = shift;
    my $concrete_class = shift;
    (not ref($class))
        or croak "new() must be called as a class method";
    ($concrete_class)
        or croak "Undefined concrete class name";
    if (exists $class_config->[0]->{$class}) {
        $concrete_class = join('::', $class_config->[0]->{$class}, $concrete_class);
    }
    # load if necessary
    my $loaded = Class::Inspector->loaded($concrete_class);
    (defined $loaded)
        or croak "Invalid concrete class name: $concrete_class";
    if (not $loaded) {
        eval "require $concrete_class;"
            or croak "Unable to require concrete class: $concrete_class";
    }
    # construct instance
    my $constructor = 'new';
    if (exists $class_config->[1]->{$class}) {
        $constructor = $class_config->[1]->{$class};
    }
    $concrete_class->can($constructor)
        or croak "Unable to instantiate $concrete_class with invalid constructor: $constructor";

    my $i = $concrete_class->$constructor(@_);
    return $i;
}


1;
__END__

=head1 NAME

Class::LazyFactory - Base class factory for lazy-loaded concrete classes

=head1 SYNOPSIS

    # factory class 
    package MyHello::Factory;
    use strict;
    use base qw/Class::LazyFactory/;

    __PACKAGE__->initialize_factory( 
        namespace   => 'MyHello::Impl',
        constructor => 'new',
    );


    # the base class
    package MyHello::Impl::Abstract;
    use strict;
    use Carp;

    sub new { my $class = shift; return bless({ },$class); }
    sub get_greeting { croak "Unimplemented" }


    # concrete class #1
    package MyHello::Impl::English;
    use strict;
    use base qw/MyHello::Impl::Abstract/;

    sub get_greeting { "hello world" }


    # main.pl
    my $greeting = MyHello::Factory->new( "English" );
    print $greeting->get_greeting();


=head1 DESCRIPTION

Class::LazyFactory is a base class for factory classes. Concrete classes
are lazy loaded, i.e. dynamically C<require()>d, and instances of the
concrete classes are constructed. 

By using a factory method design pattern, one can provide a consistent
interface for constructing a family of classes, without knowing the actual
concrete classes in advance.

=head1 USAGE

Class::LazyFactory should be used as the base class for your factory 
objects. For example:

    package MyHello::Factory;
    use strict;
    use base qw/Class::LazyFactory/;

    __PACKAGE__->initialize_factory( 
        namespace   => 'MyHello::Impl',
        constructor => 'new',
    );

MyHello::Factory becomes your factory for constructing objects under
the namespace of MyHello::Impl. Concrete classes B<need not> be
registered in advance in order to be instantiated. Concrete classes
will only be loaded upon first construction.

=head1 METHODS

=over 4

=item FACTORY_CLASS->initialize_factory( %params )

This should be called in the factory class inheriting from Class::LazyFactory.

Parameters are as follows:

    namespace       => optional, use of a namespace is strongly recommended.
                       This is the prefix used when resolving the 
                       fully-qualified namespace of the concrete class.
    constructor     => optional, defaults to 'new'.
                       This is the class method that is called when 
                       instantiating a concrete class.

=item FACTORY_CLASS->new( $concrete_class_name, @params )

Returns an instance of a concrete class. The fully-qualified class name of
the concrete class is resolved by concatenating the namespace prefix (see
C<initialize_factory>) and C<$concrete_class_name>.

C<@params> is passed to the concrete class constructor. 

=back

=head1 SEE ALSO

Factory Design Patterns - Abstract Factory, Factory Method

L<DBI>, L<DBI::DBD> - This module was heavily inspired by DBI; DBI reflects
the factory design pattern and that drivers are dynamically loaded from the
given DSN string.

L<Class::Factory>

=head1 AUTHOR

Dexter Tad-y, <dtady@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Dexter Tad-y

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
