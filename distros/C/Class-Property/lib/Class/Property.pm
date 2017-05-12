package Class::Property;
use strict; use warnings FATAL => 'all'; 
use parent 'Exporter';
use 5.016;
use Carp;

our $VERSION = '1.002'; # change in POD

our @EXPORT;

my $LAZY_INITS = {};

my $GEN = {
    'default' => sub
    {
        my( $prop_name ) = @_;
        
        return sub: lvalue
        {
            return shift->{$prop_name};
        };
    },
    'default_lazy' => sub
    {
        my( $prop_name, $lazy_init ) = @_;
        require Class::Property::RW::Lazy;
        my $dummy;
        my $inits = $LAZY_INITS->{$prop_name} //= {};
        my $wrapper = tie $dummy, 'Class::Property::RW::Lazy', $prop_name, $lazy_init, $inits;
        
        return sub: lvalue
        {
            my $self = shift;
            
            if( defined $inits->{$self} )
            {
                return $self->{$prop_name};
            }
            else
            {
                $wrapper->set_object($self);
                return $dummy;
            }
        };
    },
    'lazy_get_default_set' => sub
    {
        my( $prop_name, $lazy_init, $setter ) = @_;
        require Class::Property::RW::Lazy::CustomSet;
        my $dummy;
        my $inits = $LAZY_INITS->{$prop_name} //= {};
        my $wrapper = tie $dummy, 'Class::Property::RW::Lazy::CustomSet', $prop_name, $lazy_init, $setter, $inits;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'custom' => sub
    {
        my( $getter, $setter ) = @_;
        require Class::Property::RW::Custom;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::RW::Custom', $getter, $setter;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'default_get_custom_set' => sub
    {
        my( $prop_name, $setter ) = @_;
        require Class::Property::RW::CustomSet;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::RW::CustomSet', $prop_name, $setter;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'custom_get_default_set' => sub
    {
        my( $prop_name, $getter ) = @_;
        require Class::Property::RW::CustomGet;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::RW::CustomGet', $prop_name, $getter;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'default_ro' => sub
    {
        my( $prop_name ) = @_;
        require Class::Property::RO;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::RO', $prop_name;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'custom_ro' => sub
    {
        my( $prop_name, $getter ) = @_;
        require Class::Property::RO::CustomGet;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::RO::CustomGet', $prop_name, $getter;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'lazy_ro' => sub
    {
        my( $prop_name, $lazy_init ) = @_;
        require Class::Property::RO::Lazy;
        my $dummy;
        my $inits = $LAZY_INITS->{$prop_name} //= {};
        my $wrapper = tie $dummy, 'Class::Property::RO::Lazy', $prop_name, $lazy_init, $inits;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'default_wo' => sub: lvalue
    {
        my( $prop_name ) = @_;
        require Class::Property::WO;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::WO', $prop_name;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
    'custom_wo' => sub: lvalue
    {
        my( $prop_name, $setter ) = @_;
        require Class::Property::WO::CustomSet;
        my $dummy;
        my $wrapper = tie $dummy, 'Class::Property::WO::CustomSet', $prop_name, $setter;
        
        return sub: lvalue
        {
            $wrapper->set_object(shift);
            return $dummy;
        };
    },
};

# creating new property by names
# input is a hash of
# property_name => hashref
# and hashref is:
#
#   get => CODEREF | anything   # creates getter custom or default
#   get_lazy => CODEREF         # creates default getter with lazy init method from CODEREF
#   set => CODREF | anything    # creates custom or default setter 
#
my $make_property = sub
{
    my( $package, %kwargs ) = @_;

    #use Data::Dumper;    warn "Invoked $package with ".Dumper(\%kwargs);
    
    foreach my $prop_name (keys(%kwargs))
    {
        my $prop_settings = $kwargs{$prop_name};
        my $prop_methodname = "${package}::$prop_name";
        my $prop_method;
        
        if( # regular property
            exists $prop_settings->{'get'}
            and exists $prop_settings->{'set'}
        )
        {
            my( $get_type, $set_type ) = ( ref $prop_settings->{'get'}, ref $prop_settings->{'set'} );
            
            if( $get_type eq 'CODE' and $set_type eq 'CODE' ) # custom setter and gettter
            {
                $prop_method = $GEN->{'custom'}->(@{$prop_settings}{'get', 'set'});
            }
            elsif( $get_type eq 'CODE' )    # custom getter and default setter
            {
                $prop_method = $GEN->{'custom_get_default_set'}->($prop_name, @{$prop_settings}{'get'});
            }
            elsif( $set_type eq 'CODE' )    # default getter and custom setter
            {
                $prop_method = $GEN->{'default_get_custom_set'}->($prop_name, @{$prop_settings}{'set'});
            }
            else    # default getter and setter
            {
                $prop_method = $GEN->{'default'}->($prop_name);
            }
        }
        elsif( # regular property with lazy init
            exists $prop_settings->{'get_lazy'}
            and exists $prop_settings->{'set'}
        )
        {
            croak 'get_lazy parameter should be a coderef' if ref $prop_settings->{'get_lazy'} ne 'CODE';
            my $set_type = ref $prop_settings->{'set'};
            if( $set_type eq 'CODE' )
            {
                $prop_method = $GEN->{'lazy_get_default_set'}->($prop_name, $prop_settings->{'get_lazy'}, $prop_settings->{'set'});
            }
            else
            {
                $prop_method = $GEN->{'default_lazy'}->($prop_name, $prop_settings->{'get_lazy'});
            }
        }
        elsif( exists $prop_settings->{'get'} ) # ro property
        {
            if( ref $prop_settings->{'get'} eq 'CODE' ) # RO custom getter
            {
                $prop_method = $GEN->{'custom_ro'}->($prop_name, $prop_settings->{'get'});
            }
            else
            {
                $prop_method = $GEN->{'default_ro'}->($prop_name);
            }
        }
        elsif( exists $prop_settings->{'get_lazy'} ) # ro property with lazy init
        {
            croak 'get_lazy parameter should be a coderef' if ref $prop_settings->{'get_lazy'} ne 'CODE';
            $prop_method = $GEN->{'lazy_ro'}->($prop_name, $prop_settings->{'get_lazy'});
        }
        elsif( exists $prop_settings->{'set'} ) # wo property
        {
            if( ref $prop_settings->{'set'} eq 'CODE' ) # WO custom setter
            {
                $prop_method = $GEN->{'custom_wo'}->($prop_name, $prop_settings->{'set'});
            }
            else
            {
                $prop_method = $GEN->{'default_wo'}->($prop_name);
            }
        }        
        
        if(defined $prop_method)
        {
            no strict 'refs';
            *{$prop_methodname} = $prop_method;
        }
    }
    
    return $package;
};

push @EXPORT, 'property';
sub property{ return $make_property->( (caller)[0], @_);}
push @EXPORT, 'rw_property';
sub rw_property{ return $make_property->( (caller)[0], map{$_ => {'set' => undef, 'get' => undef }} @_);}
push @EXPORT, 'ro_property';
sub ro_property{ return $make_property->( (caller)[0], map{$_ => {'get' => undef }} @_);}
push @EXPORT, 'wo_property';
sub wo_property{ return $make_property->( (caller)[0], map{$_ => {'set' => undef }} @_);}

__END__
=head1 NAME

Class::Property - Perl implementation of class properties.

=head1 VERSION

Version 1.002

=head1 SYNOPSIS

This module allows you to easily create properties for your class. It supports default, custom and lazy properties. Basically, properties are just a fancy way to access object's keys, generally means C<$foo-E<gt>some_property> is equal to C<$foo-E<gt>{'some_property'}>.

General syntax: 

    package Foo;
    use Class::Property;

    property(
        'name' => { 'get' => undef, 'set' => undef },               # creates default RW property, fastests
        'age' => { 'get' => undef },                                # creates default RO property
        'salary' => { 'set' => undef },                             # creates default WO property
        'weight' => { 'get' => \&weight_getter, 'set' => undef },   # creates RW property with custom getter and default setter
        'family' => { 'get_lazy' => \&read_family },                # creates RO property with lazy init method 
    );

After you've created properties for your class, you may use them as lvalues:

    use Foo;
    
    my $foo = Foo->new();
    
    $foo->name = 'Yourname';
    printf 'The age of %s is %s', $foo->name, $foo->age;    
    
Usually you'll need to use general syntax when you want to use custom getters/setters and/or lazy properties. To make your code cleaner, there are few helper methods:

    rw_property( 'street', 'house', 'flat' );   # creates 3 RW properties 
    ro_property( 'sex', 'height' );             # creates 2 RO properties 
    wo_property( 'relation' );                  # creates WO property
    
=head1 API

=head2 Default properties

Default properties are the fastest way to make your code cleaner. They just mapping object's hash keys to class methods and returns them as L<lvalues|perlsub/"Lvalue subroutines">. Just use:

    rw_property( ... property names ... );

=head2 Read-only and write-only properties

Default RO and WO properties works slower, because they are using wrapper class, but they control access to the object properties. Both croaks on attempt to write to RO property or read WO one. Currently, perl doesn't allow to restrict access to the object hash keys, but you will use only properties in your code, you'll have additional control. You may create such properties with helper methods:

    ro_property( ... property names ... );

    # or
    
    wo_property( ... property names ... );


=head2 Custom getters/accessors

Sometimes you need to do something special on reading property, count reads, for example. This may be done via custom getter:

    property( 'phone_number' => {'get' => \&my_getter, 'set' => undef} );
    
    sub my_getter
    {
        my($self) = @_;
        
        $self->{'somecounter'}++;
        
        return $self->{'phone_number'};
    }

The property above will use default way to set data and call your own method to get it. Custom getter being invoked as object method (with C<$self> passed) and it must return requested value.

=head2 Custom setters/mutators

Sometimes you need to do something special on writing property, validate, for example. This may be done via custom setter:

    property( 'phone_number' => {'get' => undef, 'set' => \&my_setter} );
    
    sub my_setter
    {
        my($self, $value) = @_;
        
        ... validation or exception is here...
        
        $self->{'phone_number'} = $value;
        
        return;
    }

The property above will use default way to get data and call your own method to set it. Custom setter being invoked with two arguments - reference to an object and value to set. Setter responsible to store data in proper place.

=head2 Lazy properties

Lazy properties may be useful in situations, when reading data is resourseful or slow and it may be never used in current piece of code. For example, you may have database with persons and their relations:

    package Person;
    use Class::Property;
    
    property(
        'family' => { 'get_lazy' => \&read_family, 'set' => undef },
    );
    
    sub read_family
    {
        my($self) = @_;
        
        ... reading family members from database... 
        
        return $family;
    }
    
    ...
    
    my $me = Person->new(...);
    
    my $family = $me->family;       # first occurance, invokes read_family in background (resourceful)

    print_family( $me->family );    # other occurances, takes family from default place (fast)
    
Such class will have a lazy property: C<family>. If some code will try to access this object's property a first time, your method C<read_family> will be invoked and it's result will be stored in default place. Further accesses won't invoke init function, property will behave as non-lazy.
    
=head1 BENCHMARKING

Here is a comparision of different properties and alternatives as L<C<Class::Accessor>> and L<C<Class::Accessor::Fast>>

     1. Direct hash read           :  1 wallclock secs ( 0.78 usr +  0.00 sys =  0.78 CPU) @ 12820512.82/s (n=10000000)
     2. Direct hash write          :  0 wallclock secs ( 0.80 usr +  0.00 sys =  0.80 CPU) @ 12562814.07/s (n=10000000)
     3. Class::Property rw read    :  3 wallclock secs ( 2.54 usr +  0.00 sys =  2.54 CPU) @ 3930817.61/s (n=10000000)
     4. Class::Property rw write   :  2 wallclock secs ( 2.26 usr +  0.00 sys =  2.26 CPU) @ 4420866.49/s (n=10000000)
     5. Class::Accessor::Fast read :  4 wallclock secs ( 3.28 usr +  0.00 sys =  3.28 CPU) @ 3052503.05/s (n=10000000)
     6. Class::Accessor::Fast write:  4 wallclock secs ( 4.06 usr +  0.00 sys =  4.06 CPU) @ 2465483.23/s (n=10000000)
     7. Class::Property lrw read   :  6 wallclock secs ( 5.82 usr +  0.00 sys =  5.82 CPU) @ 1718508.33/s (n=10000000)
     8. Class::Property lrw write  :  4 wallclock secs ( 5.60 usr +  0.00 sys =  5.60 CPU) @ 1785395.47/s (n=10000000)
     9. Class::Accessor read       :  6 wallclock secs ( 6.83 usr +  0.00 sys =  6.83 CPU) @ 1463486.02/s (n=10000000)
    10. Class::Accessor write      :  8 wallclock secs ( 8.03 usr +  0.00 sys =  8.03 CPU) @ 1244709.98/s (n=10000000)
    11. Class::Property ro read    : 16 wallclock secs (15.26 usr +  0.00 sys = 15.26 CPU) @ 655436.85/s (n=10000000)
    12. Class::Property wo write   : 14 wallclock secs (14.18 usr +  0.00 sys = 14.18 CPU) @ 705168.89/s (n=10000000)
    13. Class::Property crw read   : 18 wallclock secs (17.19 usr +  0.00 sys = 17.19 CPU) @ 581699.73/s (n=10000000)
    14. Class::Property crw write  : 20 wallclock secs (19.58 usr +  0.00 sys = 19.58 CPU) @ 510777.40/s (n=10000000)    

Results shows that:

=over

=item * Default properties works 3 times slower than direct access, but still faster than L<Class::Accessor::Fast> accessors.

=item * Lazy properties works 7.2 times slower than direct access, but still faster than L<Class::Accessor> accessors.

=item * RO and WO properties works 18.6 times slower than direct access.

=item * Custom properties works 23.2 times slower than direct access.

=back

=head1 LICENSE

This module is published under the terms of the MIT license, which basically means "Do with it whatever you want". For more information, see the LICENSE file that should be enclosed with this distributions. A copy of the license is (at the time of writing) also available at L<http://www.opensource.org/licenses/mit-license.php>.

=head1 SEE ALSO

=over

=item * Main project repository and bugtracker: L<https://github.com/hurricup/Class-Property>

=item * Testing results: L<http://www.cpantesters.org/distro/C/Class-Property.html>
        
=item * AnnoCPAN, Annotated CPAN documentation: L<http://annocpan.org/dist/Class-Property>

=item * CPAN Ratings: L<http://cpanratings.perl.org/d/Class-Property>

=item * See also: L<Class::Variable>, L<Class::Accessor::Lazy>. 

=back

=head1 AUTHOR

Copyright (C) 2015 by Alexandr Evstigneev (L<hurricup@evstigneev.com|mailto:hurricup@evstigneev.com>)


=cut

1;