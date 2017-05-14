
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Facet::Exception;

      	Class::Maker::class
       	{
       		isa => [qw( Data::Type::BaseException )],
       	};

package Data::Type::Facet::Interface;

	use Attribute::Util;

	sub test : Abstract method;

	sub info : Abstract method;

	sub desc : Abstract method;

	sub usage : Abstract method;

	sub _depends : method { () }

sub _load_dependency 
{
    my $this = shift;
    
    foreach ( $this->_depends )
    {
	unless( exists $Data::Type::_loaded->{$_} )
	{
	    eval "use $_;"; die $@ if $@;

	    $Data::Type::_loaded->{$_} = caller;
	}
	else
	{
	    warn sprintf "%s tried to load twice %s", $_, join( ', ', caller ) if $Data::Type::DEBUG;
	}
    }
}

package Data::Type::Facet;

	use vars qw($AUTOLOAD);

	sub AUTOLOAD
	{
		( my $func = $AUTOLOAD ) =~ s/.*:://;

	return bless [ @_ ], sprintf 'Data::Type::Facet::%s', $func;
	}

package Data::Type::Facet::__anon;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { $_[0]->info }

	sub info : method { 'anonymous facet i.e. generated from a sub reference' }

	sub test : method
	{
		my $this = shift;

		Data::Type::try 
		{
			$_[0]->();
		}
		catch Error Data::Type::with
		{
			my $e = shift;

			throw $e;
		};

		#throw Data::Type::Facet::Exception( text => 'not a reference' ) unless ref( $Data::Type::value );
	}

package Data::Type::Facet::ref;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'if its a reference' }

	sub info : method
	{
		my $this = shift;

		return sprintf $this->[0] ? 'reference' : 'reference to %s', $this->[0];
	}

	sub test : method
	{
		my $this = shift;

		if( $this->[0] )
		{
			throw Data::Type::Facet::Exception( text => 'not a reference' ) unless ref( $Data::Type::value );
		}
		else
		{
			throw Data::Type::Facet::Exception( text => sprintf 'not a reference to "%s"', $this->[0] ) unless $this->[0] eq ref( $Data::Type::value );
		}
	}

package Data::Type::Facet::range;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'if value is between a value x and y' }

	sub test : method
	{
		my $this = shift;

		throw Data::Type::Facet::Exception( text => "$Data::Type::value is not in range $this->[0] - $this->[1]" ) unless $Data::Type::value >= $this->[0] && $Data::Type::value <= $this->[1];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'between %s - %s characters long', $this->[0], $this->[1];
	}

package Data::Type::Facet::lines;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'whether enough lines (newlines)' }

	sub test : method
	{
		my $this = shift;

		throw Data::Type::Facet::Exception( text => "not enough (new)lines found" ) unless ( $Data::Type::value =~ s/(\n)//g) > $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf '%d lines', $this->[0];
	}

package Data::Type::Facet::less;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'length is less than x' }

	sub test : method
	{
	    my $this = shift;
    
	    throw Data::Type::Facet::Exception( text => "length isnt less than $this->[0]" ) unless length($Data::Type::value) < $this->[0];
	}

	sub info : method { return sprintf 'less than %d chars long', $_[0]->[0] }

package Data::Type::Facet::max;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'scalar is numerically not exceeding x' }

	sub test : method
	{
		my $this = shift;

    		throw Data::Type::Facet::Exception() if $Data::Type::value > $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'maximum of %d', $this->[0];
	}

package Data::Type::Facet::min;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'scalar is numerically more than x' }

	sub test : method
	{
		my $this = shift;

    		throw Data::Type::Facet::Exception() if $Data::Type::value < $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'minimum of %d', $this->[0];
	}

package Data::Type::Facet::match;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'matches regexp (registered within $Data::Type::rebox. Read Data::Type::Docs::RFC.)' }

	sub usage : method
	{
		return 'match( REGEXP_BOX_ID ) 	REGEXP_BOX_ID is a key from Data::Type::rebox'
	}
	
	sub test : method
	{
		my $this = shift;

		Data::Type::Facet::defined->test;
			
		if( $Data::Type::DEBUG )
		{
			warn sprintf "FACET match %s value '%s' with $this->[0] (regexp '%s')", 
			
				defined( $Data::Type::value ) ? 'defined' : 'undefined', 

				$Data::Type::value,

				$Data::Type::rebox->request( $this->[0], 'regexp', @$this );
		}
		
		unless( $Data::Type::value =~ $Data::Type::rebox->request( $this->[0], 'regexp', @$this ) )
		{
		    throw Data::Type::Facet::Exception( text => $Data::Type::rebox->request( $this->[0], 'desc', @$this ) ) ;
		}
	}

	sub info : method
	{
		my $this = shift;

	return sprintf 'matching a regular expression for %s', $Data::Type::rebox->request( $this->[0], 'desc', @$this );
	}

package Data::Type::Facet::is;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'is == x' }

	sub test : method
	{
		my $this = shift;

   		throw Data::Type::Facet::Exception( text => "is not exact $this->[0]" ) unless $Data::Type::value == $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'exact %s', $this->[0];
	}

package Data::Type::Facet::defined;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.04';

	sub desc : method { 'defined() returns true' }

	sub test : method
	{
		my $this = shift;

	    	throw Data::Type::Facet::Exception( text => 'not defined value' ) unless defined $Data::Type::value;
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'defined (not undef) value';
	}

package Data::Type::Facet::bool;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'true after boolean evaluation' }

	sub test : method
	{
		my $this = shift;

		my $p = 'true';

		$p = $this->[0];

		if( $p eq 'true' )
		{
		    throw Data::Type::Facet::Exception( text => "not boolean $p" ) unless $Data::Type::value;
		}
		elsif( $p eq 'false' )
		{
		    throw Data::Type::Facet::Exception( text => "boolean $p" ) if $Data::Type::value;
		}
		else
		{
	            die "Data::Type::Facet::bool argument is '$p'. But usage is bool( 'true' | 'false' ).";
		}
	}

	sub info : method
	{
		my $this = shift;

		return sprintf "boolean '%s' value", $this->[0] ? 'true' : 'false';
	}

package Data::Type::Facet::null;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'is literally "NULL" (after uppercase filter)' }

	sub test : method
	{
		my $this = shift;

   		throw Data::Type::Facet::Exception( text => "not literally NULL" ) unless uc( $Data::Type::value ) eq 'NULL';
	}

	sub info : method
	{
		my $this = shift;

		return "case-independant exact 'NULL'";
	}

package Data::Type::Facet::exists;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'exists in a hash or as an array member' }

	use Class::Multimethods;

	multimethod _exists => ( '$', 'HASH' ) => sub : method 
	{ 
		throw Data::Type::Facet::Exception( text => '$_[0] does not exist in HASH' ) unless exists $_[1]->{$_[0]};
	};

	multimethod _exists => ( '$', 'ARRAY' ) => sub : method 
	{ 
		for( @{$_[1]} )
		{
			return if $_[0] eq $_;
		}

		throw Data::Type::Facet::Exception( text => '$_[0] does not exist in array' );
	};

	multimethod _exists => ( 'ARRAY', 'HASH' ) => sub : method 
	{ 
	    _exists( $_, $_[1] ) for @{ $_[0] };
	};

	multimethod _exists => ( 'ARRAY', 'ARRAY' ) => sub : method 
	{ 
	    _exists( $_, $_[1] ) for @{ $_[0] };
	};

	sub test : method
	{
		my $this = shift;

			_exists( $Data::Type::value, @$this );
	}

	sub info : method
	{
		my $this = shift;

		if( ref( $this->[0] ) eq 'HASH' )
		{
			return sprintf 'element of hash keys (%s)', join( ', ', keys %{ $this->[0] } );
		}

		return sprintf 'element of array (%s)', join(  ', ', @{$this->[0]} );
	}

package Data::Type::Facet::mod10check;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'passes the mod10 LUHN algorithm check' }

	# could have used Algorithm::LUHN

	sub test : method
	{
		my $this = shift;


		eval "use Business::CreditCard;";

		die $@ if $@;

			# We use Business::CreditCard's mod10 luhn

	    	throw Data::Type::Facet::Exception( text => "mod10check failed" ) unless validate( $Data::Type::value );
	}

	sub info : method
	{
		my $this = shift;

		return 'LUHN formula (mod 10) for validation of creditcards';
	}

  # To be implemented and not yet really usefull yet.
  # 

package Data::Type::Facet::file;

	our @ISA = qw(Data::Type::Facet::Interface);

	our $VERSION = '0.01.01';

	sub desc : method { 'whether file is existent' }

	sub usage : method { '( FILENAME )' }

	sub info : method { 'tests characteristics of file' }

	sub test : method
	{
		my $this = shift;

    			throw Data::Type::Facet::Exception( text => 'undefined value' ) unless defined $Data::Type::value;

			throw Data::Type::Facet::Exception(

			    text => 'supplied filename does not exist',

			    value => $Data::Type::value,

			    type => __PACKAGE__

			) unless -e $Data::Type::value;
	}

1;

__END__

=head1 NAME

Data::Type::Facet - a subelement of a type

=head1 SYNOPSIS

  package Data::Type::Object::std_real;

  ...

   sub _test
   {
     my $this = shift;

       Data::Type::ok( 1, Data::Type::Facet::match( 'std/real' ) );
   }

=head1 DESCRIPTION

Facets are bric's for L<Data::Type::Object>'s. They are partially almost trivial (more or less), but have some advantages. They are modularising the testing procedure of any datatype (and therefore giving the magic to the L<Data::Type/summary()> function.

=head1 EXCEPTIONS

L<Data::Type::Facet::Exception> is thrown by any facet to indicate L<Data::Type> that it failed to pass.

=head1 FACETS

=head2 Data::Type::Facet::ref( I<type> )

  Data::Type::Facet::ref();
  Data::Type::Facet::ref( 'ARRAY' );  # 'HASH' | 'CODE' | ..

Whether the value is a reference. If I<type> is given, this explicit reference is required. So if C<$Data::Type::value = [ 1, 2 ]> then

  ok( 1, Data::Type::Facet::ref( 'ARRAY' ) );

would pass. While

  ok( 1, Data::Type::Facet::ref( 'HASH' ) );

would of course not.

=head2 Data::Type::Facet::range( I<x>, I<y> )

  Data::Type::Facet::range( 1, 10 )

Value is numerically between the lower value I<x> and upper limit value I<y> (including them).

=head2 Data::Type::Facet::lines( I<min> ) 	

Counts the newlines C<\n> in a textblock. Expects more then I<min> lines (newlines).

=head2 Data::Type::Facet::less( I<min> )

Counts the C<length()> of a string and expects less than C<min>.

=head2 Data::Type::Facet::max( I<limit> )

Expects numbers under the I<limit> (E<lt> I<limit>).

=head2 Data::Type::Facet::min( I<limit> )

Expects numbers above I<limit> (E<gt> I<limit>).

=head2 Data::Type::Facet::match( I<boxid> )

  Data::Type::Facet::match( 'std/word' );

Please visit L<Data::Type::Docs::RFC/CONVENTIONS> and L<Regexp::Box> for details registering regexps. All regexps used by L<Data::Type> are stored within the central registry C<$Data::Type::rebox> (L<Regexp::Box>). The I<boxid> must be therefore e prior registered to C<$Data::Type::rebox>. The already stored one can be retrieven with L<Data::Type::Query>.

=head2 Data::Type::Facet::is()

Expects an exact match (C<==>).

=head2 Data::Type::Facet::defined()

Expects a defined value (as perl's C<defined()>).

=head2 Data::Type::Facet::null()

Expects not literally 'NULL'. Its test C<eq 'NULL'>.

=head2 Data::Type::Facet::bool( 'true' | 'false' )

  Data::Type::Facet::bool( 'true' );

Expects true or false boolean value.

=head2 Data::Type::Facet::exists( I<key | element> )

This function expects array elements with an array or a hash key within a hash, dependant on the given C<$Data::Type::value>.

=head2 Data::Type::Facet::mod10check()

Expects a number (mostly a credit-card number) to pass the I<mod10 LUHN algorithm> check.


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

