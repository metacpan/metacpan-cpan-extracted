
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::Collection::W3C::Interface;

use XML::Schema;

use Attribute::Util;

our @ISA = qw(Data::Type::Object::Interface);

our $VERSION = '0.01.25';

sub prefix : method { 'W3C::' }

sub pkg_prefix : method { 'w3c_' }

sub basic_depends : method { qw(XML::Schema) }

sub original : method
{
    my $this = shift;
    
    $this = ref($this) || $this;
    
    if( $this =~ /(\w+)\s+(.+)/ )
	    {
		return $1;
	    }
}

sub info : method { 'W3C XML Schema datatype '.$_[0]->desc }

sub desc { 'W3C' }

sub doc { 'W3C related types.' }

sub ordered : Abstract method; # One of {false, partial, total}

sub bounded : Abstract method; # A boolean

sub cardinality : Abstract method; # {finite, countably infinite}.

sub numeric : Abstract method; # A boolean

    # unit is a "factor" for the size of a single unit. Used when counting
    # length or other sizes.

sub unit : method { 1 }

	#
	# W3C Facets
	#

package Data::Type::Facet::Interface::W3C;

our @ISA = qw(Data::Type::Facet::Interface);

package Data::Type::Facet::Interface::Fundamental;

our @ISA = qw(Data::Type::Facet::Interface::W3C);

package Data::Type::Facet::Interface::Constraining;

our @ISA = qw(Data::Type::Facet::Interface::W3C);

=pod

=begin comment

http://www.w3.org/TR/xmlschema-2/#rf-fund-facets

4.2 Fundamental Facets

4.2.1 equal 
4.2.2 ordered 
4.2.3 bounded 
4.2.4 cardinality 
4.2.5 numeric

package Data::Type::Facet::equal;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Fundamental);

    sub desc { 'equal (4.2.1)' }

package Data::Type::Facet::ordered;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Fundamental);

    sub desc { 'ordered (4.2.2)' }

package Data::Type::Facet::bounded;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Fundamental);

    sub desc { 'bounded (4.2.3)' }


package Data::Type::Facet::cardinality;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Fundamental);

    sub desc { 'cardinality (4.2.4)' }


package Data::Type::Facet::numeric;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Fundamental);

    sub desc { 'numeric (4.2.5)' }

=end comment

=cut

=pod

=begin comment

4.3 Constraining Facets

4.3.1 length 
4.3.2 minLength 
4.3.3 maxLength 
4.3.4 pattern 
4.3.5 enumeration 
4.3.6 whiteSpace 
4.3.7 maxInclusive 
4.3.8 maxExclusive 
4.3.9 minExclusive 
4.3.10 minInclusive 
4.3.11 totalDigits 
4.3.12 fractionDigits 

=end comment

=cut

package Data::Type::Facet::length;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc : method { 'length (4.3.1)' }

sub doc : method
{ return <<ENDE;
[Definition:]   length is the number of units of length, where units of length varies depending on the type that is being ·derived· from. The value of length ·must· be a nonNegativeInteger. 
ENDE
}

sub usage : method
{ return <<ENDE;
value:NONNEGATIVEINTEGER, [fixed:BOOLEAN]

{value} The actual value of the value   [attribute]  
{fixed} The actual value of the fixed   [attribute], if present, otherwise false  

By fixing the value of the length facet we ensure that types derived from productCode can change or set the values of other facets, such as pattern, but cannot change the length. If {fixed} is true, then types for which the current type is the {base type definition} cannot specify a value for length other than {value}.
ENDE
}

=pod

=begin comment

4.3.1.3 length Validation Rules
Validation Rule: Length Valid 

A value in a ·value space· is facet-valid with respect to ·length·, determined as follows: 
1 if the {variety} is ·atomic· then 
1.1 if {primitive type definition} is string, then the length of the value, as measured in characters ·must· be equal to {value}; 
1.2 if {primitive type definition} is hexBinary or base64Binary, then the length of the value, as measured in octets of the binary data, ·must· be equal to {value}; 
2 if the {variety} is ·list·, then the length of the value, as measured in list items, ·must· be equal to {value} 

=end comment

=cut

sub test : method
{
    my $this = shift;

    my $fixed = shift || 0;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::minlength;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'minLength (4.3.2)' }

sub doc 
{ return <<ENDE;
[Definition:]   minLength is the minimum number of units of length, where units of length varies depending on the type that is being ·derived· from. The value of minLength  ·must· be a nonNegativeInteger. 
ENDE
}

sub test : method
{
    my $this = shift;

    my $fixed = shift || 0;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::maxlength;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'maxLength (4.3.3)' }

sub doc 
{ return <<ENDE;
[Definition:]   maxLength is the maximum number of units of length, where units of length varies depending on the type that is being ·derived· from. The value of maxLength  ·must· be a nonNegativeInteger. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::pattern;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'pattern (4.3.4)' }

sub doc : method
{ return <<ENDE;
[Definition:]   pattern is a constraint on the ·value space· of a datatype which is achieved by constraining the ·lexical space· to literals which match a specific pattern. The value of pattern  ·must· be a ·regular expression·. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::enumeration;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'enumeration (4.3.5)' }

sub doc : method
{ return <<ENDE;
[Definition:]   enumeration constrains the ·value space· to a specified set of values. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::whitespace;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'whiteSpace (4.3.6)' }

sub doc : method
{ return <<ENDE;
[Definition:]   whiteSpace constrains the ·value space· of types ·derived· from string such that the various behaviors specified in Attribute Value Normalization in [XML 1.0 (Second Edition)] are realized. The value of whiteSpace must be one of {preserve, replace, collapse}. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::maxinclusive;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'maxInclusive (4.3.7)' }

sub doc : method
{ return <<ENDE;
[Definition:]   maxInclusive is the ·inclusive upper bound· of the ·value space· for a datatype with the ·ordered· property. The value of maxInclusive ·must· be in the ·value space· of the ·base type·. 

·maxInclusive· provides for: 

Constraining a ·value space· to values with a specific ·inclusive upper bound·. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::maxexclusive;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'maxExclusive (4.3.8)' }

sub doc : method
{ return <<ENDE;
[Definition:]   maxExclusive is the ·exclusive upper bound· of the ·value space· for a datatype with the ·ordered· property. The value of maxExclusive  ·must· be in the ·value space· of the ·base type·. 

·maxExclusive· provides for: 

Constraining a ·value space· to values with a specific ·exclusive upper bound·.
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::minexclusive;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'minExclusive (4.3.9)' }

sub doc : method
{ return <<ENDE;
[Definition:]   minExclusive is the ·exclusive lower bound· of the ·value space· for a datatype with the ·ordered· property. The value of minExclusive ·must· be in the ·value space· of the ·base type·. 

·minExclusive· provides for: 

Constraining a ·value space· to values with a specific ·exclusive lower bound·. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::mininclusive;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'minInclusive (4.3.10)' }

sub doc : method
{ return <<ENDE;
[Definition:]   minInclusive is the ·inclusive lower bound· of the ·value space· for a datatype with the ·ordered· property. The value of minInclusive  ·must· be in the ·value space· of the ·base type·. 

·minInclusive· provides for: 

Constraining a ·value space· to values with a specific ·inclusive lower bound·. 
ENDE
}

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::totaldigits;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'totalDigits (4.3.11)' }

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

package Data::Type::Facet::fractiondigits;

    our $VERSION = '0.01.25';

    our @ISA = qw(Data::Type::Facet::Interface::Constraining);

    sub desc { 'fractionDigits (4.3.12)' }

sub test : method
{
    my $this = shift;

    #throw Data::Type::Facet::Exception() if ;
}

=pod

=begin comment

2.5 Datatype dichotomies
2.5.1 Atomic vs. list vs. union datatypes 
2.5.2 Primitive vs. derived datatypes 
2.5.3 Built-in vs. user-derived datatypes 

=end comment

=cut 

package Data::Type::Collection::W3C::Interface::Atomic;

our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

package Data::Type::Collection::W3C::Interface::List;

our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

package Data::Type::Collection::W3C::Interface::Union;

our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

package Data::Type::Collection::W3C::Interface::Primitive;

our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

package Data::Type::Collection::W3C::Interface::Derived;
	
our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

package Data::Type::Collection::W3C::Interface::Builtin;

our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

package Data::Type::Collection::W3C::Interface::UserDerived;

our @ISA = qw(Data::Type::Collection::W3C::Interface);

our $VERSION = '0.01.25';

	#
	# W3C datatypes
	#

=pod

=begin comment

Primitive datatypes
3.2.1 string 
3.2.2 boolean 
3.2.3 decimal 
3.2.4 float 
3.2.5 double 
3.2.6 duration 
3.2.7 dateTime 
3.2.8 time 
3.2.9 date 
3.2.10 gYearMonth 
3.2.11 gYear 
3.2.12 gMonthDay 
3.2.13 gDay 
3.2.14 gMonth 
3.2.15 hexBinary 
3.2.16 base64Binary 
3.2.17 anyURI 
3.2.18 QName 
3.2.19 NOTATION 

=end comment

=cut

package Data::Type::Object::w3c_string;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';
	
    sub export : method { ("STRING") }

    sub desc { 'string (3.2.1)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::string';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;

			$args->{ qw(length minLength maxLength pattern enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength pattern enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, pattern, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="string" id="string">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#string"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="preserve" id="string.preserve"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_boolean;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("BOOLEAN") }

    sub desc { 'boolean (3.2.2)' }

sub _test : method
{
    my $this = shift;

    my $pkg = 'XML::Schema::Type::boolean';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub _test__ : method
{
    my $this = shift;
 
    
    my $pkg = 'XML::Schema::Type::boolean';

    my $type = $pkg->new();

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );

    #match( $type->{ name }, 'string' );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(pattern whiteSpace) }

	sub doc { 'facets: pattern, whiteSpace' }
	
sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'finite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="boolean" id="boolean">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="finite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#boolean"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="boolean.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_decimal;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("DECIMAL") }

    sub desc { 'decimal (3.2.3)' }

sub _test : method
{
    my $this = shift;

    my $pkg = 'XML::Schema::Type::decimal';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::totaldigits( $args->{totaldigits} ) );
			Data::Type::ok( 1, Data::Type::Facet::fractiondigits( $args->{fractiondigits} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(totalDigits fractionDigits pattern whiteSpace enumeration maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: totalDigits, fractionDigits, pattern, whiteSpace, enumeration, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'total' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'true' }

sub def { return << 'ENDE';
	<xs:simpleType name="decimal" id="decimal">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="totalDigits"/>
				<hfp:hasFacet name="fractionDigits"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="total"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="true"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#decimal"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="decimal.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_float;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("FLOAT") }

    sub desc { 'float (3.2.4)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::float';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'total' }

sub bounded : method { 'true' }

sub cardinality : method { 'finite' }

sub numeric : method { 'true' }

sub def { return << 'ENDE';
	<xs:simpleType name="float" id="float">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="total"/>
				<hfp:hasProperty name="bounded" value="true"/>
				<hfp:hasProperty name="cardinality" value="finite"/>
				<hfp:hasProperty name="numeric" value="true"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#float"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="float.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_double;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("DOUBLE") }

    sub desc { 'double (3.2.5)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::double';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'total' }

sub bounded : method { 'true' }

sub cardinality : method { 'finite' }

sub numeric : method { 'true' }

sub def { return << 'ENDE';
	<xs:simpleType name="double" id="double">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="total"/>
				<hfp:hasProperty name="bounded" value="true"/>
				<hfp:hasProperty name="cardinality" value="finite"/>
				<hfp:hasProperty name="numeric" value="true"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#double"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="double.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_duration;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("DURATION") }

    sub desc { 'duration (3.2.6)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::duration';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="duration" id="duration">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#duration"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="duration.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_datetime;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("DATETIME") }

    sub desc { 'dateTime (3.2.7)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::dateTime';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="dateTime" id="dateTime">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#dateTime"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="dateTime.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_time;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("TIME") }

    sub desc { 'time (3.2.8)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::time';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="time" id="time">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#time"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="time.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_date_w3c;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("DATE") }

    sub desc { 'date (3.2.9)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::date';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="date" id="date">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#date"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="date.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_gyearmonth;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("GYEARMONTH") }

    sub desc { 'gYearMonth (3.2.10)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::gYearMonth';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="gYearMonth" id="gYearMonth">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#gYearMonth"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="gYearMonth.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_gyear;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("GYEAR") }

    sub desc { 'gYear (3.2.11)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::gYear';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="gYear" id="gYear">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#gYear"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="gYear.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_gmonthday;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("GMONTHDAY") }

    sub desc { 'gMonthDay (3.2.12)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::gMonthDay';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="gMonthDay" id="gMonthDay">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#gMonthDay"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="gMonthDay.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_gday;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("GDAY") }

    sub desc { 'gDay (3.2.13)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::gDay';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="gDay" id="gDay">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#gDay"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="gDay.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_gmonth;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("GMONTH") }

    sub desc { 'gMonth (3.2.14)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::gMonth';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxinclusive( $args->{maxinclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxexclusive( $args->{maxexclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::mininclusive( $args->{mininclusive} ) );
			Data::Type::ok( 1, Data::Type::Facet::minexclusive( $args->{minexclusive} ) );
	}
		
	sub facets { qw(pattern enumeration whiteSpace maxInclusive maxExclusive minInclusive minExclusive) }

	sub doc { 'facets: pattern, enumeration, whiteSpace, maxInclusive, maxExclusive, minInclusive, minExclusive' }

sub ordered : method { 'partial' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="gMonth" id="gMonth">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasFacet name="maxInclusive"/>
				<hfp:hasFacet name="maxExclusive"/>
				<hfp:hasFacet name="minInclusive"/>
				<hfp:hasFacet name="minExclusive"/>
				<hfp:hasProperty name="ordered" value="partial"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#gMonth"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="gMonth.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_hexbinary;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("HEXBINARY") }

    sub desc { 'hexBinary (3.2.15)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::hexBinary';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength pattern enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength pattern enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, pattern, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="hexBinary" id="hexBinary">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#binary"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="hexBinary.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>

ENDE
}

package Data::Type::Object::w3c_base64binary;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("BASE64BINARY") }

    sub desc { 'base64Binary (3.2.16)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::base64Binary';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength pattern enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength pattern enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, pattern, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="base64Binary" id="base64Binary">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#base64Binary"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="base64Binary.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_anyuri;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("ANYURI") }

    sub desc { 'anyURI (3.2.17)' }

sub _test : method
{
    my $this = shift;
  

    my $pkg = 'XML::Schema::Type::anyURI';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength pattern enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength pattern enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, pattern, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="anyURI" id="anyURI">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#anyURI"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="anyURI.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_qname;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("QNAME") }

    sub desc { 'QName (3.2.18)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::QName';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength pattern enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength pattern enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, pattern, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="QName" id="QName">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#QName"/>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="QName.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_notation;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Primitive);

    our $VERSION = '0.01.25';

    sub export : method { ("NOTATION") }

    sub desc { 'NOTATION (3.2.19)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::NOTATION';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength pattern enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::pattern( $args->{pattern} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength pattern enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, pattern, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return << 'ENDE';
	<xs:simpleType name="NOTATION" id="NOTATION">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="pattern"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#NOTATION"/>
			<xs:documentation>
        NOTATION cannot be used directly in a schema; rather a type
        must be derived from it by specifying at least one enumeration
        facet whose value is the name of a NOTATION declared in the
        schema.
      </xs:documentation>
		</xs:annotation>
		<xs:restriction base="xs:anySimpleType">
			<xs:whiteSpace value="collapse" fixed="true" id="NOTATION.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

=pod

=begin comment

3.3 Derived datatypes
3.3.1 normalizedString 
3.3.2 token 
3.3.3 language 
3.3.4 NMTOKEN 
3.3.5 NMTOKENS 
3.3.6 Name 
3.3.7 NCName 
3.3.8 ID 
3.3.9 IDREF 
3.3.10 IDREFS 
3.3.11 ENTITY 
3.3.12 ENTITIES 
3.3.13 integer 
3.3.14 nonPositiveInteger 
3.3.15 negativeInteger 
3.3.16 long 
3.3.17 int 
3.3.18 short 
3.3.19 byte 
3.3.20 nonNegativeInteger 
3.3.21 unsignedLong 
3.3.22 unsignedInt 
3.3.23 unsignedShort 
3.3.24 unsignedByte 
3.3.25 positiveInteger 	

=end comment

=cut

package Data::Type::Object::w3c_normalizedstring;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NORMALIZEDSTRING") }

    sub desc { 'normalizedString (3.3.1)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::normalizedString';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def {  return <<'ENDE';
	<xs:simpleType name="normalizedString" id="normalizedString">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#normalizedString"/>
		</xs:annotation>
		<xs:restriction base="xs:string">
			<xs:whiteSpace value="replace" id="normalizedString.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_token;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("TOKEN") }

    sub desc { 'token (3.3.2)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::token';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="token" id="token">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#token"/>
		</xs:annotation>
		<xs:restriction base="xs:normalizedString">
			<xs:whiteSpace value="collapse" id="token.whiteSpace"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_language;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("LANGUAGE") }

    sub desc { 'language (3.3.3)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::language';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="language" id="language">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#language"/>
		</xs:annotation>
		<xs:restriction base="xs:token">
			<xs:pattern value="(([a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*" id="language.pattern">
				<xs:annotation>
					<xs:documentation source="http://www.w3.org/TR/REC-xml#NT-LanguageID">
            pattern specifies the content of section 2.12 of XML 1.0e2
            and RFC 3066 (Revised version of RFC 1766).
          </xs:documentation>
				</xs:annotation>
			</xs:pattern>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_nmtoken;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NMTOKEN") }

    sub desc { 'NMTOKEN (3.3.4)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::NMTOKEN';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="NMTOKEN" id="NMTOKEN">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#NMTOKEN"/>
		</xs:annotation>
		<xs:restriction base="xs:token">
			<xs:pattern value="\c+" id="NMTOKEN.pattern">
				<xs:annotation>
					<xs:documentation source="http://www.w3.org/TR/REC-xml#NT-Nmtoken">
            pattern matches production 7 from the XML spec
          </xs:documentation>
				</xs:annotation>
			</xs:pattern>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_nmtokens;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NMTOKENS") }

    sub desc { 'NMTOKENS (3.3.5)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::NMTOKENS';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return <<'ENDE';

	<xs:simpleType name="NMTOKENS" id="NMTOKENS">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#NMTOKENS"/>
		</xs:annotation>
		<xs:restriction>
			<xs:simpleType>
				<xs:list itemType="xs:NMTOKEN"/>
			</xs:simpleType>
			<xs:minLength value="1" id="NMTOKENS.minLength"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_name;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NAME") }

    sub desc { 'Name (3.3.6)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::Name';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="Name" id="Name">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#Name"/>
		</xs:annotation>
		<xs:restriction base="xs:token">
			<xs:pattern value="\i\c*" id="Name.pattern">
				<xs:annotation>
					<xs:documentation source="http://www.w3.org/TR/REC-xml#NT-Name">
            pattern matches production 5 from the XML spec
          </xs:documentation>
				</xs:annotation>
			</xs:pattern>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_ncname;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NCNAME") }

    sub desc { 'NCName (3.3.7)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::NCName';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="NCName" id="NCName">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#NCName"/>
		</xs:annotation>
		<xs:restriction base="xs:Name">
			<xs:pattern value="[\i-[:]][\c-[:]]*" id="NCName.pattern">
				<xs:annotation>
					<xs:documentation source="http://www.w3.org/TR/REC-xml-names/#NT-NCName">
            pattern matches production 4 from the Namespaces in XML spec
          </xs:documentation>
				</xs:annotation>
			</xs:pattern>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_id;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("ID") }

    sub desc { 'ID (3.3.8)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::ID';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="ID" id="ID">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#ID"/>
		</xs:annotation>
		<xs:restriction base="xs:NCName"/>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_idref;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("IDREF") }

    sub desc { 'IDREF (3.3.9)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::IDREF';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="IDREF" id="IDREF">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#IDREF"/>
		</xs:annotation>
		<xs:restriction base="xs:NCName"/>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_idrefs;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("IDREFS") }

    sub desc { 'IDREFS (3.3.10)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::IDREFS';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return <<'ENDE';
	<xs:simpleType name="IDREFS" id="IDREFS">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#IDREFS"/>
		</xs:annotation>
		<xs:restriction>
			<xs:simpleType>
				<xs:list itemType="xs:IDREF"/>
			</xs:simpleType>
			<xs:minLength value="1" id="IDREFS.minLength"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_entity;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("ENTITY") }

    sub desc { 'ENTITY (3.3.11)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::ENTITY';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="ENTITY" id="ENTITY">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#ENTITY"/>
		</xs:annotation>
		<xs:restriction base="xs:NCName"/>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_entities;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("ENTITIES") }

    sub desc { 'ENTITIES (3.3.12)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::ENTITIES';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

	sub _test_ : method
	{
		my $this = shift;

		

		my $args;


			$args->{ qw(length minLength maxLength enumeration whiteSpace) } = @$this;
			
			Data::Type::ok( 1, Data::Type::Facet::length( $args->{length} ) );
			Data::Type::ok( 1, Data::Type::Facet::minlength( $args->{minlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::maxlength( $args->{maxlength} ) );
			Data::Type::ok( 1, Data::Type::Facet::enumeration( $args->{enumeration} ) );
			Data::Type::ok( 1, Data::Type::Facet::whitespace( $args->{whitespace} ) );
	}
		
	sub facets { qw(length minLength maxLength enumeration whiteSpace) }

	sub doc { 'facets: length, minLength, maxLength, enumeration, whiteSpace' }

sub ordered : method { 'false' }

sub bounded : method { 'false' }

sub cardinality : method { 'countably infinite' }

sub numeric : method { 'false' }

sub def { return <<'ENDE';
	<xs:simpleType name="ENTITIES" id="ENTITIES">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasFacet name="length"/>
				<hfp:hasFacet name="minLength"/>
				<hfp:hasFacet name="maxLength"/>
				<hfp:hasFacet name="enumeration"/>
				<hfp:hasFacet name="whiteSpace"/>
				<hfp:hasProperty name="ordered" value="false"/>
				<hfp:hasProperty name="bounded" value="false"/>
				<hfp:hasProperty name="cardinality" value="countably infinite"/>
				<hfp:hasProperty name="numeric" value="false"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#ENTITIES"/>
		</xs:annotation>
		<xs:restriction>
			<xs:simpleType>
				<xs:list itemType="xs:ENTITY"/>
			</xs:simpleType>
			<xs:minLength value="1" id="ENTITIES.minLength"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_integer;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("INTEGER") }

    sub desc { 'integer (3.3.13)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::integer';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="integer" id="integer">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#integer"/>
		</xs:annotation>
		<xs:restriction base="xs:decimal">
			<xs:fractionDigits value="0" fixed="true" id="integer.fractionDigits"/>
			<xs:pattern value="[-+]?[0-9]+"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_nonpositiveinteger;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NONPOSITIVEINTEGER") }

    sub desc { 'nonPositiveInteger (3.3.14)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::nonPositiveInteger';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="nonPositiveInteger" id="nonPositiveInteger">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#nonPositiveInteger"/>
		</xs:annotation>
		<xs:restriction base="xs:integer">
			<xs:maxInclusive value="0" id="nonPositiveInteger.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_negativeinteger;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NEGATIVEINTEGER") }

    sub desc { 'negativeInteger (3.3.15)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::negativeInteger';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="negativeInteger" id="negativeInteger">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#negativeInteger"/>
		</xs:annotation>
		<xs:restriction base="xs:nonPositiveInteger">
			<xs:maxInclusive value="-1" id="negativeInteger.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_long;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("LONG") }

    sub desc { 'long (3.3.16)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::long';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub bounded : method { 'true' }

sub cardinality : method { 'finite' }

sub def { return <<'ENDE';
	<xs:simpleType name="long" id="long">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasProperty name="bounded" value="true"/>
				<hfp:hasProperty name="cardinality" value="finite"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#long"/>
		</xs:annotation>
		<xs:restriction base="xs:integer">
			<xs:minInclusive value="-9223372036854775808" id="long.minInclusive"/>
			<xs:maxInclusive value="9223372036854775807" id="long.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_int;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("INT") }

    sub desc { 'int (3.3.17)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::int';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="int" id="int">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#int"/>
		</xs:annotation>
		<xs:restriction base="xs:long">
			<xs:minInclusive value="-2147483648" id="int.minInclusive"/>
			<xs:maxInclusive value="2147483647" id="int.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_short;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("SHORT") }

    sub desc { 'short (3.3.18)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::short';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="short" id="short">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#short"/>
		</xs:annotation>
		<xs:restriction base="xs:int">
			<xs:minInclusive value="-32768" id="short.minInclusive"/>
			<xs:maxInclusive value="32767" id="short.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_byte;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("BYTE") }

    sub desc { 'byte (3.3.19)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::byte';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="byte" id="byte">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#byte"/>
		</xs:annotation>
		<xs:restriction base="xs:short">
			<xs:minInclusive value="-128" id="byte.minInclusive"/>
			<xs:maxInclusive value="127" id="byte.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_nonnegativeinteger;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("NONNEGATIVEINTEGER") }

    sub desc { 'nonNegativeInteger (3.3.20)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::nonNegativeInteger';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="nonNegativeInteger" id="nonNegativeInteger">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#nonNegativeInteger"/>
		</xs:annotation>
		<xs:restriction base="xs:integer">
			<xs:minInclusive value="0" id="nonNegativeInteger.minInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_unsignedlong;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("UNSIGNEDLONG") }

    sub desc { 'unsignedLong (3.3.21)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::unsignedLong';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub bounded : method { 'true' }

sub cardinality : method { 'finite' }

sub def { return <<'ENDE';
	<xs:simpleType name="unsignedLong" id="unsignedLong">
		<xs:annotation>
			<xs:appinfo>
				<hfp:hasProperty name="bounded" value="true"/>
				<hfp:hasProperty name="cardinality" value="finite"/>
			</xs:appinfo>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#unsignedLong"/>
		</xs:annotation>
		<xs:restriction base="xs:nonNegativeInteger">
			<xs:maxInclusive value="18446744073709551615" id="unsignedLong.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_unsignedint;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("UNSIGNEDINT") }

    sub desc { 'unsignedInt (3.3.22)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::unsignedInt';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="unsignedInt" id="unsignedInt">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#unsignedInt"/>
		</xs:annotation>
		<xs:restriction base="xs:unsignedLong">
			<xs:maxInclusive value="4294967295" id="unsignedInt.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_unsignedshort;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("UNSIGNEDSHORT") }

    sub desc { 'unsignedShort (3.3.23)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::unsignedShort';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="unsignedShort" id="unsignedShort">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#unsignedShort"/>
		</xs:annotation>
		<xs:restriction base="xs:unsignedInt">
			<xs:maxInclusive value="65535" id="unsignedShort.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_unsignedbyte;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("UNSIGNEDBYTE") }

    sub desc { 'unsignedByte (3.3.24)' }

sub _test : method
{
    my $this = shift;

    

    my $pkg = 'XML::Schema::Type::unsignedByte';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="unsignedByte" id="unsignedByte">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#unsignedByte"/>
		</xs:annotation>
		<xs:restriction base="xs:unsignedShort">
			<xs:maxInclusive value="255" id="unsignedByte.maxInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

package Data::Type::Object::w3c_positiveinteger;

    our @ISA = qw(Data::Type::Collection::W3C::Interface::Derived);

    our $VERSION = '0.01.25';

    sub export : method { ("POSITIVEINTEGER") }

    sub desc { 'positiveInteger (3.3.25)' }

sub _test : method
{
    my $this = shift;

    my $pkg = 'XML::Schema::Type::positiveInteger';

    my $type = $pkg->new();

    #$type->constrain( maxInclusive => 32 );

    $type->constrain( @$this ) if @$this;

    throw Data::Type::Exception( text => $pkg->error() ) unless $type->instance( $Data::Type::value );
}

sub def { return <<'ENDE';
	<xs:simpleType name="positiveInteger" id="positiveInteger">
		<xs:annotation>
			<xs:documentation source="http://www.w3.org/TR/xmlschema-2/#positiveInteger"/>
		</xs:annotation>
		<xs:restriction base="xs:nonNegativeInteger">
			<xs:minInclusive value="1" id="positiveInteger.minInclusive"/>
		</xs:restriction>
	</xs:simpleType>
ENDE
}

1;

=head1 NAME

Data::Type::Collection::W3C - set of data types from the W3C XML Schema spec

=head1 TYPES


=head2 W3C::ANYURI (since 0.01.25)

anyURI (3.2.17)

=head2 W3C::BASE64BINARY (since 0.01.25)

base64Binary (3.2.16)

=head2 W3C::BOOLEAN (since 0.01.25)

boolean (3.2.2)

=head2 W3C::BYTE (since 0.01.25)

byte (3.3.19)

=head2 W3C::DATE (since 0.01.25)

date (3.2.9)

=head2 W3C::DATETIME (since 0.01.25)

dateTime (3.2.7)

=head2 W3C::DECIMAL (since 0.01.25)

decimal (3.2.3)

=head2 W3C::DOUBLE (since 0.01.25)

double (3.2.5)

=head2 W3C::DURATION (since 0.01.25)

duration (3.2.6)

=head2 W3C::ENTITIES (since 0.01.25)

ENTITIES (3.3.12)

=head2 W3C::ENTITY (since 0.01.25)

ENTITY (3.3.11)

=head2 W3C::FLOAT (since 0.01.25)

float (3.2.4)

=head2 W3C::GDAY (since 0.01.25)

gDay (3.2.13)

=head2 W3C::GMONTH (since 0.01.25)

gMonth (3.2.14)

=head2 W3C::GMONTHDAY (since 0.01.25)

gMonthDay (3.2.12)

=head2 W3C::GYEAR (since 0.01.25)

gYear (3.2.11)

=head2 W3C::GYEARMONTH (since 0.01.25)

gYearMonth (3.2.10)

=head2 W3C::HEXBINARY (since 0.01.25)

hexBinary (3.2.15)

=head2 W3C::ID (since 0.01.25)

ID (3.3.8)

=head2 W3C::IDREF (since 0.01.25)

IDREF (3.3.9)

=head2 W3C::IDREFS (since 0.01.25)

IDREFS (3.3.10)

=head2 W3C::INT (since 0.01.25)

int (3.3.17)

=head2 W3C::INTEGER (since 0.01.25)

integer (3.3.13)

=head2 W3C::LANGUAGE (since 0.01.25)

language (3.3.3)

=head2 W3C::LONG (since 0.01.25)

long (3.3.16)

=head2 W3C::NAME (since 0.01.25)

Name (3.3.6)

=head2 W3C::NCNAME (since 0.01.25)

NCName (3.3.7)

=head2 W3C::NEGATIVEINTEGER (since 0.01.25)

negativeInteger (3.3.15)

=head2 W3C::NMTOKEN (since 0.01.25)

NMTOKEN (3.3.4)

=head2 W3C::NMTOKENS (since 0.01.25)

NMTOKENS (3.3.5)

=head2 W3C::NONNEGATIVEINTEGER (since 0.01.25)

nonNegativeInteger (3.3.20)

=head2 W3C::NONPOSITIVEINTEGER (since 0.01.25)

nonPositiveInteger (3.3.14)

=head2 W3C::NORMALIZEDSTRING (since 0.01.25)

normalizedString (3.3.1)

=head2 W3C::NOTATION (since 0.01.25)

NOTATION (3.2.19)

=head2 W3C::POSITIVEINTEGER (since 0.01.25)

positiveInteger (3.3.25)

=head2 W3C::QNAME (since 0.01.25)

QName (3.2.18)

=head2 W3C::SHORT (since 0.01.25)

short (3.3.18)

=head2 W3C::STRING (since 0.01.25)

string (3.2.1)

=head2 W3C::TIME (since 0.01.25)

time (3.2.8)

=head2 W3C::TOKEN (since 0.01.25)

token (3.3.2)

=head2 W3C::UNSIGNEDBYTE (since 0.01.25)

unsignedByte (3.3.24)

=head2 W3C::UNSIGNEDINT (since 0.01.25)

unsignedInt (3.3.22)

=head2 W3C::UNSIGNEDLONG (since 0.01.25)

unsignedLong (3.3.21)

=head2 W3C::UNSIGNEDSHORT (since 0.01.25)

unsignedShort (3.3.23)



=head1 INTERFACE


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

