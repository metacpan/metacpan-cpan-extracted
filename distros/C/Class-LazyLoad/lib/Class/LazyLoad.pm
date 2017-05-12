package Class::LazyLoad;

use strict 'vars';

use vars qw(
    $AUTOLOAD
    $VERSION
);

$VERSION = 0.04;

{
    my @todo;
    sub import
    {
        shift;
        return if (caller)[0] eq 'Class::LazyLoad::Functions';        
        
        unless ( @_ ) {
            push @todo, [ (caller)[0], 'new' ];
            return;
        }

        foreach ( @_ ) {
            if (ref($_) eq 'ARRAY') {
                push @todo, $_;
            } else {
                push @todo, [ $_, 'new' ];
            }
        }
    }

    sub init_lazyloads { lazyload( @$_ ) for @todo }
    INIT { init_lazyloads() }
}

use overload
    '${}' => sub { _build($_[0]); $_[0] },          
    '%{}' => sub { _build($_[0]); $_[0] },
    '&{}' => sub { _build($_[0]); $_[0] },
    '@{}' => sub { 
        # C::LL does array access, so make sure it's not us before building.
        return $_[0] if (caller)[0] eq __PACKAGE__;
        _build($_[0]); $_[0] 
    },
    nomethod => sub {
        my $realclass = $_[0][1];
        if ($_[3] eq '""') {
            if (my $func = overload::Method($realclass, $_[3])) {
                _build($_[0]);
                return $_[0]->$func();
            }
            else {
                return overload::StrVal($_[0]);
            }
        }
        die "LazyLoaded object '$realclass' is not overloaded, cannot perform '$_[3]'\n" 
            unless overload::Overloaded($realclass);
        my $func = overload::Method($realclass, $_[3]);
        die "LazyLoaded object '$realclass' does not overloaded '$_[3]'\n"	
            unless defined $func;
        _build($_[0]);
        $_[0]->$func($_[1], $_[2]);
    };

sub can
{
    _build( $_[0] );
    $_[0]->can($_[1]);
}

sub isa { $_[0][1]->isa($_[1]) }

sub AUTOLOAD
{
    my ($subname) = $AUTOLOAD =~ /([^:]+)$/;

    my $realclass = $_[0][1];
    _build( $_[0] );

    my $func = $_[0]->can( $subname );
    die "Cannot call '$subname' on an instance of '$realclass'\n"
        unless ref( $func ) eq 'CODE';

    goto &$func;
}

sub _compile
{ 
    my $pkg = shift;
    (my $filename = $pkg) =~ s!::!/!g;
#    print "$pkg => " . $INC{"$filename.pm"} . "\n";
    return if exists $INC{"$filename.pm"};

    eval "use $pkg;";
    die "Could not load '$pkg' because : $@" if $@;
}

{
    my %lazyloads;

    sub lazyload
    {
        my $pkg = shift;

        _compile( $pkg );

        my @functions = @_;
        @functions = qw( new ) unless @functions;

        foreach my $name (@functions)
        {
            my $subname = __PACKAGE__ . '::' . $pkg . '::' . $name;

            # Don't override a function we've already overridden;
            next if defined &{$subname};

            my $func = \&{ $pkg . '::' . $name };
            *$subname = sub { unshift @_, $func; bless \@_, __PACKAGE__ };

            local $^W = 0;
            *{ $pkg . '::' . $name }  = \&$subname;

            $lazyloads{ $pkg }{ $name } = $func;
        }

        return ~~1;
    }

    sub unlazyload
    {
        my $pkg = shift;

        foreach my $name ( keys %{ $lazyloads{ $pkg } } )
        {
            my $subname = __PACKAGE__ . '::' . $pkg . '::' . $name;

            local $^W = 0;
            *{ $pkg . '::' . $name } = delete $lazyloads{ $pkg }{ $name };
        }

        delete $lazyloads{ $pkg };

        return ~~1;
    }

    sub _build
    {
        my @x = @{$_[0]};

        my $func = shift @x;
        $_[0] = $func->(@x);

        die "INTERNAL ERROR: Cannot build instance of '$x[0]'\n"
            unless defined $_[0];

        # This can occur if the class wasn't loaded correctly.
        die "INTERNAL ERROR: _build() failed to build a new object\n"
            if ref($_[0]) eq __PACKAGE__;

        return ~~1;
    }

    sub lazyload_one
    {
        my ($pkg, $name, @args) = @_;

        die "Must pass in (CLASS, [ CONSTRUCTOR, [ARGS] ]) to lazyload_one().\n"
            unless defined $pkg;

        $name = 'new' unless defined $name && length $name;

        _compile( $pkg );

        my $func = \&{ $pkg . '::' . $name };
        bless [ $func, $pkg, @args ];
    }
}

sub DESTROY{ undef }

1;
__END__

=head1 NAME

Class::LazyLoad - 

=head1 SYNOPSIS

  use Class::LazyLoad::Functions 'lazyload', 'unlazyload';
  
  # lazyload classes dynamically
  lazyload('My::Class'); 
  unlazyload('My::Class');
  
  # lazyload classes at compile time
  use Class::LazyLoad 'My::Class'; 

  # Same as above
  use Class::LazyLoad [ 'My::Class', 'new' ]; 

  # For different constructors
  use Class::LazyLoad [ 'My::Class', 'build', 'create' ]; 
  
  # or make your class into a lazyload
  package My::Class;
  
  # If you're using 'new' as the constructor
  use Class::LazyLoad;

  # Or, if you're using different constructor names
  use Class::LazyLoad [ __PACKAGE__, 'build', 'create' ];
  
  # ... rest of your class here

=head1 DESCRIPTION

This is a highly flexible and general purpose lazyloader class. With very minimal configuration, it will correctly intercept constructor calls and wait until first access before actually executing the constructor.

=head1 WHY ANOTHER LAZYLOADER?

We looked at all the lazyloaders out there and realized that they were more complicated and in-depth than we wanted to be. Each one we looked at required the developer of the class to figure out how to lazyload their class. Plus, there was no provision for a consumer to lazyload a class that wasn't initially designed for it.

We wanted to lazyload anything we felt like and, if desired, indicate that a given class should be lazyloadable in a very . . . well . . . Lazy fashion. Hence, this class.

=head1 METHODS

=head2 isa()

This will dispatch to your class's isa().

=head2 can()

This will inflate the object, then dispatch to your class's can(). This is because of the following snippet:

  my $ref = $object->can( 'method' );
  $ref->( $object, @args );

If the object is not inflated during can(), the wrong (or no!) subreference will be returned.

=head2 LazyLoaded Public Attribute Access

We correctly handle the lazyloading of public attribute access, so that the following will work (depending on the underlying implementation of your object)

  SCALAR: ${$proxied_object}
  ARRAY:  $proxied_object->[3]
  HASH:   $proxied_object->{foo}
  SUB:    $proxied_object->(foo)
  
This basically results in the inflation of the proxied object.

=head2 LazyLoaded Operator Overloading

We correctly lazyload overloaded operators so that their use will result in the inflation of the proxied object. The only restriction we have is that the dereference operators are not overloadable since we make use of them to allow for proxied attribute access.

=head1 ASSUMPTIONS

=over 4

=item * Overloaded operators

We assume that you do not overload ${}, @{}, %{}, and &{}. We use these to test if you are accessing the object internals directly. The effect is that we will not redispatch these overloads to your object. The workaround is to do something else first, then we're not in the way anymore.

=back

=head1 Exportable Functions

To export these functions, you have to use Class::LazyLoad::Functions instead.

=over 4

=item B<lazyload>

Use this if you want to mark a class for lazyloading at runtime. The first parameter is the class you want to lazyload. Any subsequent parameters are the constructor name(s). (If none are provided, 'new' is assumed.)

=item B<unlazyload>

Use this if you want to unmark a class for lazyloading. Once this is called, the class will no longer benefit from lazyloading.

=item B<init_lazyloads>

This is the actual function called by the INIT block to do lazyloading during compile-time. Use this if you are working in an environment that may not execute the INIT phase. (If you don't understand what that means, you probably don't have to worry about it.)

=item B<lazyload_one>

This works much like C<lazyload> but will only lazyload a single instance of a given package. It will force compilation of the package, but it will not alter the package itself. 

=back

=head1 CAVEATS

This code has not been tested extensively in persistent environments, such as mod_perl. As such, the mechanism used (INIT blocks) may not work in certain situations. We provide C<init_lazyloads()> in case you need to intialize by hand.

=head1 BUGS

None that we are aware of. Of course, if you find a bug, let us know, and we will be sure to fix it. 

=head1 CODE COVERAGE

We use B<Devel::Cover> to test the code coverage of our tests, below is the B<Devel::Cover> report on this module test suite.

  ----------------------------------- ------ ------ ------ ------ ------ ------
  File                                  stmt branch   cond    sub   time  total
  ----------------------------------- ------ ------ ------ ------ ------ ------
  blib/lib/Class/LazyLoad.pm           100.0  100.0  100.0  100.0   94.7  100.0
  .../lib/Class/LazyLoad/Functions.pm  100.0    n/a    n/a  100.0    5.3  100.0
  Total                                100.0  100.0  100.0  100.0  100.0  100.0
  ----------------------------------- ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over 4

=item L<Object::Realize::Later>

=item L<Class::LazyObject>

=back

=head1 AUTHORS

Rob Kinyon, E<lt>rob.kinyon@gmail.comE<gt>
Stevan Little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Rob Kinyon and Stevan Little

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

