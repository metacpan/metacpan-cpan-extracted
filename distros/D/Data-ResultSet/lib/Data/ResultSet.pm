package Data::ResultSet;
use warnings;
use strict;

our $VERSION = '1.001';

sub new
{
	my ($class) = @_;
	return bless [], $class;
}

sub make_wrappers
{
	my ($class, @methods ) = @_;

	$class->make_wrappers_for_all(@methods);
	$class->make_wrappers_for_has(@methods);
	$class->make_wrappers_for_get(@methods);
	$class->make_wrappers_for_get_not(@methods);

	return;
}

sub make_wrappers_for_get
{
	my ($class, @methods) = @_;

	my $generator = sub {
		my ($methodname) = @_;
		return sub {
			return grep { $_->$methodname() } @{$_[0]};
		};
	};

	return $class->_generate_methods( 'get', $generator, @methods );
}

sub make_wrappers_for_get_not
{
	my ($class, @methods) = @_;

	my $generator = sub {
		my ($methodname) = @_;
		return sub {
			return grep { ! $_->$methodname() } @{$_[0]};
		};
	};

	return $class->_generate_methods( 'get_not', $generator, @methods );
}

sub make_wrappers_for_has
{
	my ($class, @methods) = @_;

	my $generator = sub {
		my ($methodname) = @_;
		return sub {
			for( @{$_[0]} ) {
				if( $_->$methodname() ) {
					return 1;
				}
			}
			return 0;
		};
	};

	return $class->_generate_methods( 'has', $generator, @methods );
}

sub make_wrappers_for_all
{
	my ($class, @methods) = @_;

	my $generator = sub {
		my ($methodname) = @_;
		return sub {
			for( @{$_[0]} ) {
				if( ! $_->$methodname() ) {
					return 0;
				}
			}
			return 1;
		};
	};

	return $class->_generate_methods( 'all', $generator, @methods );
}

sub _generate_methods
{
	my ($class, $prefix, $generator, @methods) = @_; 

	no strict 'refs';  ## no critic (ProhibitNoStrict)
	foreach my $name (@methods) {
		my $wrappername = $name;
		$wrappername =~ s/is_//;
		$wrappername = "${class}::${prefix}_${wrappername}";
		if( ! defined &{$wrappername} ) {
			*{$wrappername} = $generator->($name);

		}
	}

	return;
}

sub add
{
	my ($self, $obj) = @_;
	push @{$self}, $obj;
	return $self;
}

sub clear
{
	my ($self) = @_;
	@{$self} = ();
	return 1;
}

sub count
{
	my ($self) = @_; 
	return scalar @{$self};
}

sub contents
{
	my ($self) = @_;
	return @{$self};
}

1;
__END__

=head1 NAME
 
Data::ResultSet - Container for aggregating and examining multiple results
 
=head1 SYNOPSIS

    # Subclass the module
    package MyApp::ResultSet;
    use base qw( Data::ResultSet );

    # Generate methods to wrap 'is_success' and 'is_error'
    __PACKAGE__->make_wrappers( qw( is_success is_error ) );

    # And elsewhere...
    package MyApp;
    use MyApp::ResultSet;
    sub something
    {
        # Create a resultset object
        my $result = MyApp::ResultSet->new();

        foreach my $thing ( @_ ) {
                # Add results of calling do_something() to the result
                # set
                $result->add(
                         $thing->do_something();
                );
        }

        # Return the results
        return $result;
    }

    # And, check your results
    my $r = something( @some_data );

    if( $r->all_success ) {
        # Only true if each result's ->is_success method returns true
        print "happiness and puppies!\n";
    } elsif ( $r->all_error ) {
        # Only true if each result's ->is_error method returns true
        die 'Oh noes! Everything errored out!';
    } else {
        foreach my $failed ( $r->list_not_success() ) {
                # Do something with each failed result
        }
    }
  
=head1 DESCRIPTION

Data::ResultSet is a container object for aggregating and examining
multiple results.  It allows multiple result objects matching the same
method signature to be returned as a single object that can then be
queried for success or failure in a number of ways.

This is accomplished by generating wrappers to methods in the
underlying list of result objects.  For example, if you have a result
object that has an is_ok() method, you can create a Data::ResultSet
subclass to handle it with:

    package MyApp::ResultSet;
    use base qw( Data::ResultSet );
    __PACKAGE__->make_wrappers( 'is_ok' );
    1;

This will generate C<all_ok>, C<has_ok>, C<get_ok>, and C<get_not_ok>
methods in MyApp::ResultSet that use the C<is_ok> accessor on your
result object.

=head1 CLASS METHODS

=head2 new ( )

Creates a new Data::ResultSet object.  Generally you will want to do
this on a subclass, not on Data::ResultSet.

=head2 make_wrappers ( @method_names )

Generates all wrapper methods ( all_, has_, get_, get_not ) for the
provided method names.  The resulting wrapper will consist of the
provided name and the appropriate prefix, with the exception that
provided names beginning with is_ will have the is_ stripped first.

The wrappers can be generated individually using other methods (see below).

=head2 make_wrappers_for_all ( @method_names )

Generates the C<all_> wrapper method for each provided name.

=head2 make_wrappers_for_has

Generates the C<has_> wrapper method for each provided name.

=head2 make_wrappers_for_get

Generates the C<get_> wrapper method for each provided name.

=head2 make_wrappers_for_get_not

Generates the C<get_not_> wrapper method for each provided name.

=head1 INSTANCE METHODS

=head2 add ( $object ) 

Adds an object to the result set.  Returns $self.

=head2 count ( ) 

Returns number of objects in the set.

=head2 contents ( )

Returns contents of set.

=head2 clear ( ) 

Clears contents of set.  Returns true.

=head2 all_METHOD ( )

Generated method that returns true if the METHOD called on every object
within the set returns true.

=head2 has_METHOD ( ) 

Generated method that returns true if one object within the set returns
true for METHOD.

=head2 get_METHOD ( ) 

Generated method that returns all objects for which METHOD returns true.

=head2 get_not_METHOD ( ) 

Generated method that returns all objects for which METHOD returns false.
 
=head1 INCOMPATIBILITIES

There are no known incompatibilities with this module.
 
=head1 BUGS AND LIMITATIONS

=over 4

=item *

The methods being wrapped shouldn't be anything more than simple
accessors.  They will get called an arbitrary number of times, so doing
any real work, particularly anything that changes state or has
side-effects, is a bad idea.

=back
 
Please report any new problems to the author.  Patches are welcome.

=head1 SEE ALSO

There are quite a few other packages on the CPAN for implementing
polymorphic return values.  You may wish to use one of these instead:

=over 4

=item * L<Class::ReturnValue>

=item * L<Return::Value>

=item * L<Contextual::Return>

=back
 
=head1 AUTHOR
 
Dave O'Neill (dmo@roaringpenguin.com)
 
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
