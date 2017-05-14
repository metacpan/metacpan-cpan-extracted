
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use strict;

package Data::Type::Collection::Std::Interface;

  our @ISA = qw(Data::Type::Object::Interface);

  our $VERSION = '0.01.25';

  sub prefix : method {'Std::'} 

  sub pkg_prefix : method {'std_'} 

package Data::Type::Collection::Std::Interface::Numeric;

   our @ISA = qw(Data::Type::Collection::Std::Interface);

   sub desc : method { 'Numeric' }

   sub doc : method { q{Number or related} }

package Data::Type::Collection::Std::Interface::Temporal;

   our @ISA = qw(Data::Type::Collection::Std::Interface);

   sub desc { 'Time or Date' }

   sub doc { 'Any time or date related object.' }

package Data::Type::Collection::Std::Interface::String;

   our @ISA = qw(Data::Type::Collection::Std::Interface);

   sub desc { 'String' }

   sub doc { q{Something that may be matched with a regex and doesnt belong to another category.} }

package Data::Type::Collection::Std::Interface::Logic;

   our @ISA = qw(Data::Type::Collection::Std::Interface);

   sub desc { 'Logic' }

   sub doc { 'Something that requires some more program logic.' }

package Data::Type::Collection::Std::Interface::Business;

   our @ISA = qw(Data::Type::Collection::Std::Interface);

   our $VERSION = '0.01.03';

   sub desc { 'Business' }

   sub doc { 'Something from the CPAN C<Business> namespace or simply business related.' }

package Data::Type::Collection::Std::Interface::Locale;

   our @ISA = qw(Data::Type::Collection::Std::Interface);

   our $VERSION = '0.01.05';

   sub desc { 'Locale' }

   sub doc { 'Language or Localization specific.' }

	#
	# Custom datatypes
	#

package Data::Type::Object::std_word;

   our @ISA = qw(Data::Type::Collection::Std::Interface::String);

   our $VERSION = '0.01.25';

   sub desc { 'word (without whitespaces)' }

   sub _test
   {
       my $this = shift;

       Data::Type::ok( 1, Data::Type::Facet::match( 'std/word' ) );
   }

package Data::Type::Object::std_bool;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Numeric);
	
	our $VERSION = '0.01.25';
	
	sub desc : method { 'boolean value' }
	  
        sub info
	{
	  my $this = shift;
	    
	  return sprintf '%s value', $this->[0] || 'true or false';
	}
	
	sub _test
	{
	  my $this = shift;

            Data::Type::ok( $this->[0] eq 'true' ? 1 : 0, Data::Type::Facet::bool( $this->[0] ) );
	}

package Data::Type::Object::std_int;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Numeric);

        our $VERSION = '0.01.27';

	sub _depends { qw(Regexp::Common) }

	sub desc : method { 'integer' }

	sub info { 'integer' }

	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::match( 'std/int' ) );
	}

package Data::Type::Object::std_num;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Numeric);

	our $VERSION = '0.01.25';

	sub desc : method { 'number' }

	sub info { 'number' }

	sub _test
	{
		my $this = shift;

				# Here we test the hierarchy feature -> nested types !

			Data::Type::Object::std_int->test( $Data::Type::value );
	}

package Data::Type::Object::std_real;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Numeric);

	our $VERSION = '0.01.25';

	sub _depends { qw(Regexp::Common) }

	sub desc : method { 'real' }

	sub info { 'real' }

	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::match( 'std/real' ) );
	}

package Data::Type::Object::std_quoted;

	our @ISA = qw(Data::Type::Collection::Std::Interface::String);

	our $VERSION = '0.01.25';

	sub _depends { qw(Regexp::Common) }

	sub desc : method { 'quoted string' }

	sub info { 'quoted string' }

	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::match( 'std/quoted' ) );
	}

package Data::Type::Object::std_gender;

	our @ISA = qw(Data::Type::Collection::Std::Interface::String);

	our $VERSION = '0.01.25';

	sub desc : method { 'human gender' }

	sub info : method
	{
		my $this = shift;

		return sprintf 'gender %s', join( ', ', $this->param );
	}

	sub param : method { qw(male female) }

	sub choice : method
	{
       		my $this = shift;

   	return $this->param;
   	}

	sub _test : method
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::exists( [ $this->param ] ) );
	}

package Data::Type::Object::std_gender_de;

	our $VERSION = '0.01.12';

	our @ISA = qw(Data::Type::Object::std_gender);

	sub export { ('GENDER::DE') }

	sub param : method { ( 'weiblich', 'männlich' ) }

package Data::Type::Object::std_yesno;

	our @ISA = qw(Data::Type::Collection::Std::Interface::String);

	our $VERSION = '0.01.25';

	sub desc : method { 'primitiv answer' }

	sub info : method
	{
		my $this = shift;

		return sprintf q{a primitiv answer (%s)}, join( ', ', $this->param ) ;
	}

	sub param  : method { qw(yes no) }

   	sub choice : method
   	{
       		my $this = shift;

   	return $this->param;
   	}

	sub _filters : method { return ( [ 'chomp' ], [ 'lc' ] ) }

	sub _test : method
	{
		my $this = shift;

			# Data::Type->filter(  [ 'chomp' ], [ 'lc' ] );

			Data::Type::ok( 1, Data::Type::Facet::exists( [ $this->param ] ) );
	}

package Data::Type::Object::std_yesno_de;

	our @ISA = qw(Data::Type::Object::std_yesno);

        our $VERSION = '0.01.14';

	sub export { ('YESNO::DE') };

	sub param { qw(ja nein) }

package Data::Type::Object::std_ref;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.25';

	sub desc : method { 'perl reference' }

	sub info
	{
		my $this = shift;

		return qq{a reference to a variable};
	}
	
	sub _test
        {
	  my $this = shift;
		
		Data::Type::ok( 1, Data::Type::Facet::ref( $Data::Type::value ) );
		
			if( @$this )
			{
				$Data::Type::value = ref( $Data::Type::value );
				
				$this = [ @$this ] unless ref( $this ) eq 'ARRAY';
				
				Data::Type::ok( 1, Data::Type::Facet::exists( [ @$this ] ) );
			}
	}

package Data::Type::Object::std_creditcard;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Business);

	our $VERSION = '0.01.25';

	sub _depends { qw(Business::CreditCard) }

	sub desc : method { 'creditcard' }

	our $cardformats =
	{
		DINERS =>
		{
			name	=> 'Diners Club',

			prefix	=> { 3000 => 3059, 3600 => 3699, 3800 => 3889 },

			digits	=> [ 14 ],
		},

		AMEX =>
		{
			name	=> 'American Express',

			prefix	=> { 3400 => 3499, 3700 => 3799 },

			digits	=> [ 15 ],
		},

		JCB =>
		{
			name	=> 'JCB',

			prefix	=> { 3528 => 3589 },

			digits	=> [ 16 ],
		},

		BLACHE =>
		{
			name	=> 'Carte Blache',

			prefix	=> { 3890 => 3899 },

			digits	=> [ 14 ],
		},
	
		VISA =>
		{
			name	=> 'VISA',

			prefix=> [ 4 ],

			digits	=> [ 13, 16 ],
		},
	
		MASTERCARD =>
		{
			name	=> 'MasterCard',

			prefix	=> { 5100 => 5599 },

			digits	=> [ 16 ],
		},
	
		BANKCARD =>
		{
			name	=> 'Australian BankCard',
			
			prefix	=> [ 5610 ],

			digits	=> [ 16 ],
		},
	
		DISCOVER =>
		{
			name	=> 'Discover/Novus',
			
			prefix	=> [ 6011 ],

			digits	=> [ 16 ],
		}
	};

	sub info
	{
		my $this = shift;

		return sprintf 'is one of a set of creditcard type (%s)', join( ', ', keys %$cardformats );
	}

	sub usage
	{
		my $this = shift;

		return sprintf "CREDITCARD( Set of [%s], .. )", join( '|', keys %$cardformats );
	}

	our $default_cc = 'VISA';

	sub _filters : method { return ( [ 'strip', '\D' ] ) }

	sub _test
	{
		my $this = shift;

			printf "creditcard '%s' is about to be tested\n", $Data::Type::value if $Data::Type::debug;

			Data::Type::ok( 1, Data::Type::Facet::mod10check( $Data::Type::value ) );

			push @$this, $default_cc unless @$this;

			my $results = {};

			foreach ( @$this )
			{
				$results->{$_} = [];

				my $card = $cardformats->{$_};

				push @{ $results->{$_} }, 'digits' if map { length($Data::Type::value) eq $_ ? () : 'invalid' } @{ $card->{digits} };

				if( ref $card->{prefix} eq 'HASH' )
				{
					my $prefix;

					while( my( $min, $max ) = each %{ $card->{prefix} } )
					{
						$prefix = pack( 'a'.length($max), $Data::Type::value );

						push @{ $results->{$_} }, 'prefix' if $prefix+0 > $max;

						$prefix = pack( 'a'.length($min), $Data::Type::value );

						push @{ $results->{$_} }, 'prefix' if $prefix+0 < $min;
					}
				}
				elsif( ref $card->{prefix} eq 'ARRAY' )
				{
					for ( @{ $card->{prefix} } )
					{
						$_ .= '';

						push @{ $results->{$_} }, 'prefix' unless $Data::Type::value =~ /$_/;
					}
				}
			}

		throw Data::Type::Exception( text => 'creditcard not valid' ) unless map { @{ $results->{$_} } == 0 ? 1 : () } keys %$results;
	}

package Data::Type::Object::std_binary;

	our @ISA = qw(Data::Type::Collection::Std::Interface::String);

	our $VERSION = '0.01.25';

        sub desc : method { 'binary code' }

        sub info : method { q{binary code} }

        sub usage : method { 'Set of ( [0|1] )' }
	
	sub _test : method
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::match( 'std/binary' ) );
	}

package Data::Type::Object::std_hex;

	our @ISA = qw(Data::Type::Collection::Std::Interface::String);

	our $VERSION = '0.01.25';

	sub info : method { qq{hexadecimal code} }

	sub usage { 'Set of ( ([0-9a-fA-F]) )' }

	sub _filters : method { return ( [ 'strip', '\s' ] ) }
	
	sub _test
	{
		my $this = shift;

		        Data::Type::ok( 1, Data::Type::Facet::match( 'std/hex' ) );
	}

package Data::Type::Object::std_langcode;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Locale);

	our $VERSION = '0.01.03';

	sub _depends { qw(Locale::Language) }

	sub desc : method { 'language code' }

   	sub export { ('LANGCODE') }

	sub info
	{
		my $this = shift;

		return qq{a Locale::Language language code};
	}

	sub usage { '' }

	sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ], [ 'lc' ] ) }

	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::exists( [ Locale::Language::all_language_codes() ] ) );
	}

package Data::Type::Object::std_langname;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Locale);

	our $VERSION = '0.01.03';

	sub _depends { qw(Locale::Language) }

	sub desc : method { 'natural language' }

	sub info : method { qq{a language name} }

	sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ] ) }

	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::exists( [ Locale::Language::all_language_names() ] ) );
	}

package Data::Type::Object::std_issn;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Business);

	our $VERSION = '0.01.03';

	sub _depends { qw(Business::ISSN) }

	sub desc : method { 'ISSN' }

	sub info { qq{an International Standard Serial Number} }

	sub usage { 'example: 14565935' }

	sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ] ) }

	sub _test
	{
		my $this = shift;

			throw Data::Type::Facet::Exception() unless new Business::ISSN( $Data::Type::value )->is_valid;
	}

package Data::Type::Object::std_upc;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Business);

	our $VERSION = '0.01.03';

	sub _depends { qw(Business::UPC) }

	sub desc : method { 'UPC' }

	sub info { qq{standard (type-A) Universal Product Code}	}

	sub usage { 'i.e. 012345678905'	}

	sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ] ) }
       
	sub _test
	{
		my $this = shift;

			throw Data::Type::Facet::Exception() unless Business::UPC->new( $Data::Type::value )->is_valid;
	}

package Data::Type::Object::std_cins;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Business);

	our $VERSION = '0.01.03';

	sub _depends { qw(Business::CINS) }

	sub desc : method { 'CINS' }

	sub info { qq{a CUSIP International Numbering System Number} }

	sub usage { 'i.e. 035231AH2' }
	
	sub _filters : method { return ( [ 'strip', '\s' ], [ 'chomp' ] ) }

	sub _test
	{
		my $this = shift;

			my $result = Business::CINS->new( $Data::Type::value )->error;
			
			throw Data::Type::Facet::Exception( text => $result ) if defined $result;
	}

package Data::Type::Object::std_defined;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.04';

	sub desc : method { 'defined value' }

        sub info { qq{a defined (not undef) value} }
	
	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::defined() );
	}

package Data::Type::Object::std_email;

{
    package Data::Type::Facet::__email;

    our @ISA = qw(Data::Type::Facet::Interface);

    our $VERSION = '0.01.25';

    sub _depends : method { qw(Email::Valid) }

    sub desc : method { 'valid email' }

    sub info : method { 'valid email' }

    sub test : method
    {
	my $this = shift;

	my $result = Email::Valid->address( -address => $Data::Type::value, -mxcheck => $this->[0] || 0 );

	throw Data::Type::Facet::Exception( text => 'not an email address' ) unless $result;
    }
}

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.25';

	sub _depends { qw(Email::Valid) }

	sub desc : method { 'email address' }

        sub usage : method 
        { 
          return <<'END_HERE';
[MXCHECK as STD::BOOL]
  MXCHECK results actually tests the mx host via internet (see Email::Valid)
END_HERE
        }

        sub info
	{
		my $this = shift;

		return sprintf "valid email address (%s mxcheck)", $this->[0] ? 'with' : 'without';
	}

	sub _test
	{
		my $this = shift;
		
		Data::Type::ok( 1, Data::Type::Facet::__email( $this->[0] ) );
	}

package Data::Type::Object::std_uri;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.25';

	sub _depends { qw(Regexp::Common) }

	sub desc : method { 'uri' }

	sub info
	{
		my $this = shift;

		my $scheme = $this->[0] || 'http';

		return sprintf '%s uri', $scheme;
	}

	sub _test
	{
		my $this = shift;

		        Data::Type::ok( 1, Data::Type::Facet::match( 'std/uri', $this->[0] || 'http'  ) );
	}

package Data::Type::Object::std_ip;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.04';
	
	sub _depends { qw(Regexp::Common Net::IPv6Addr) }
	
	sub desc : method { 'IP (v4 or v6) or MAC network address' }
	
	sub info { 'IP (V4, V6, MAC) network address' }

	sub default { 'v4' }

	sub _test
	{
		my $this = shift;

			my $format = lc( $this->[0] || $this->default );

			$format = 'IP'.$format if $format =~ /^[vV][46]$/;

			if( $format =~ /6/ )
			{				
				eval
				{
					new Net::IPv6Addr( $Data::Type::value );
				};

				throw Data::Type::Exception ( text => $@ ) if $@;
			}
			else
			{
				Data::Type::ok( 1, Data::Type::Facet::match( 'std/net', $format ) );
			}
	}

package Data::Type::Object::std_domain;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.04';

	sub desc : method { 'domain name' }

	sub info { qq{a network domain name} }

	sub _filters : method { return ( [ 'lc' ] ) }

	sub _test
	{
		my $this = shift;

			Data::Type::ok( 1, Data::Type::Facet::defined() );

			Data::Type::ok( 1, Data::Type::Facet::match( 'std/domain' ) );
	}

package Data::Type::Object::std_port;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.04';

	sub desc : method { 'tcp port number' }

	sub info { qq{a network port number} }

	sub _test
	{
		my $this = shift;

		Data::Type::Object::std_int->test( $Data::Type::value );

    		throw Data::Type::Exception->new( text => 'no port number' ) unless $Data::Type::value < 650;
	}

package Data::Type::Object::std_path;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.06';

	sub export { ( 'PATH' ) }

	sub desc : method { 'path' }

	sub info { qq{a path string} }

	sub _test
	{
		my $this = shift;

			#Data::Type::ok( 0, Data::Type::Facet::match( qr/.+/ ) );
	}

package Data::Type::Object::std_regionname;

     our @ISA = qw(Data::Type::Collection::Std::Interface::Locale);

     our $VERSION = '0.01.05';

     sub export { ('REGIONNAME') }

     sub _depends { qw(Locale::SubCountry) }

	sub desc : method { 'country region' }

	sub info : method { qq{region name} }

	sub _filters : method { return ( [ 'uc' ] ) }

	sub _test
	{
		my $this = shift;

		$this->[0] or Carp::croak( 'unallowed country name' );
		
		my $loc = Locale::SubCountry->new( $this->[0] );
		
		my %states =  $loc->full_name_code_hash;
		
		for ( keys %states )
		{
		    $states{ uc $_} = $states{ $_ };
		    
		    delete $states{ $_ };
		}
		
		#print $states{'Tasmania'} eq 'TAS';
		
		throw Data::Type::Exception->new( text => 'bad regionname' ) unless exists $states{ $Data::Type::value };
	}

package Data::Type::Object::std_regioncode;

  our @ISA = qw(Data::Type::Collection::Std::Interface::Locale);

  our $VERSION = '0.01.05';

  sub _depends { qw(Locale::SubCountry) }

  sub desc : method { 'country region code' }

  sub info : method { qq{region code} }

  sub _filters : method { return ( [ 'uc' ] ) }

  sub _test
  {
      my $this = shift;
      
      $this->[0] or Carp::croak( 'unallowed region code' );
      
      my %states;
      
      eval
      {
	  my $loc = Locale::SubCountry->new( $this->[0] );
	  
	  %states =  $loc->code_full_name_hash;
      };
      
      throw Data::Type::Exception->new( text => 'Local::SubCountry error: '.$@ ) if $@;
      
      #print $states{'SA'} eq 'South Australia' ? "ok 9\n" : "not ok 9\n";

      throw Data::Type::Exception->new( text => 'bad regioncode' ) unless exists $states{ $Data::Type::value };
  }

package Data::Type::Object::std_countrycode;

   our @ISA = qw(Data::Type::Collection::Std::Interface::Locale);

   our $VERSION = '0.01.05';

   sub _depends { qw(Locale::SubCountry) }

   use Locale::SubCountry;

	sub desc : method { 'country code' }

	sub info : method { q{country code} }

	sub _filters : method { return ( [ 'uc' ] ) }

	sub _test
	{
		my $this = shift;

         my %countries;

         eval
         {
            my $world = new Locale::SubCountry::World;

            %countries =  $world->code_full_name_hash;
         };

         throw Data::Type::Exception->new( text => 'Local::SubCountry error: '.$@ ) if $@;

               #print $countries{'GB'} eq 'UNITED KINGDOM' ? "ok 14\n" : "not ok 14\n";

         throw Data::Type::Exception->new( text => 'bad countrycode' ) unless exists $countries{ $Data::Type::value };
	}

package Data::Type::Object::std_countryname;

   our @ISA = qw(Data::Type::Collection::Std::Interface::Locale);

   our $VERSION = '0.01.05';

   sub _depends { qw(Locale::SubCountry) }

#   use Locale::SubCountry;

	sub desc : method { 'country name' }

	sub info : method { qq{country name} }

	sub _filters : method { return ( [ 'uc' ] ) }

	sub _test
	{
		my $this = shift;

         my %countries;

         eval
         {
            my $world = new Locale::SubCountry::World;

            %countries =  $world->full_name_code_hash;
         };

         throw Data::Type::Exception->new( text => 'Local::SubCountry error: '.$@ ) if $@;

         throw Data::Type::Exception->new( text => 'this is not a country name refering to ISO' ) unless exists $countries{ $Data::Type::value };
	}

package Data::Type::Object::std_zip;

   our @ISA = qw(Data::Type::Collection::Std::Interface::Business);

   our $VERSION = '0.01.14';

   sub export { ('ZIP') }

   sub _depends { qw(Regexp::Common) }

   our $countries = { NL => 'Netherlands', DE => 'Germany', FR => 'France', DK => 'Denmark', BE => 'Belgian', AU => 'Australia', US => 'US' };

   sub desc : method { 'zip code' }

   sub info : method { q{zip code} }

   sub usage : method
   {
	 my $this = shift;

    return sprintf "%s( %s )", $this->export, join( ' | ', map { qq|"$_"| } keys %$countries );
   }

   sub doc : method
   {
     return sprintf "See possible alternative for REGION from the Regexp::Common::zip perldoc. Regexp::Common 2.111 supports:\n%s.", join( ",\n", map { $countries->{$_}.qq| or "$_"| } keys %$countries ); 
   }

   sub _test : method
   {
     my $this = shift;

     # countrycode
 
     my $ccode = $countries->{ $this->[0] || 'US' } || $this->[0];
 
     Data::Type::ok( 1, Data::Type::Facet::match( 'std/zip', $ccode ) );
    }   

package Data::Type::Object::std_date;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Temporal);

	our $VERSION = '0.01.01';

	sub _depends { qw(Date::Parse) }

        sub export : method { ('DATE') }

        sub desc : method { 'date' }

	sub info : method { 'date (see Date::Parse)' }

	sub usage  : method { q{DATE employs Date::Parse str2time function.} }

	sub _filters : method { return ( [ 'chomp' ] ) }

	sub _test
	{
		my $this = shift;

			#Date::Parse->language('German');

			throw Data::Type::Exception(

			    text => 'is not a Date::Parse date',

			    value => $Data::Type::value,

			    type => __PACKAGE__

			) unless Date::Parse::str2time( $Data::Type::value );
	}

package Data::Type::Object::std_pod;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.36';

# 
# Seems that Test::Pod is more confectioned for this work, but Pod::Find works either.
#

	sub _depends { qw(Pod::Find) }

        sub export : method { ('POD') }

        sub desc : method { 'file containing Pod instructions' }

	sub info : method { 'date (see Date::Parse)' }

	sub usage  : method { q{POD() requires a filename value} }

	sub _filters : method { return ( [ 'chomp' ] ) }

	sub _test
	{
		my $this = shift;

			throw Data::Type::Exception(

			    text => 'supplied filename does not exist',

			    value => $Data::Type::value,

			    type => __PACKAGE__

			) unless -e $Data::Type::value;

			throw Data::Type::Exception(

			    text => 'supplied filename (not POD module) contains no pod information',

			    value => $Data::Type::value,

			    type => __PACKAGE__

			) unless Pod::Find::contains_pod( $Data::Type::value, 0 );
	}

package Data::Type::Object::std_shebang;
	
	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);
	
	our $VERSION = '0.01.36';
	
        sub desc : method { 'file containing a she-bang (#!)' }
	  
	  sub info : method { 'if the file start with #! and a signature in that line' }
	  
	  sub usage  : method { '( SIGNATURE [, SIGNATURE] ) - SIGNATURE is a text fragment (default: perl)' }
	  
	  sub _filters : method { return ( [ 'chomp' ] ) }

	  sub _test
	  {
		my $this = shift;

		throw Data::Type::Exception(
					    
					    text => 'supplied filename does not exist',
					    
					    value => $Data::Type::value,
					    
					    type => __PACKAGE__
					    
					    ) unless -e $Data::Type::value;
		
		unless( open ( FILE, $Data::Type::value ) )
		{
		    throw Data::Type::Exception(
						
						text => $!,
						
						value => $Data::Type::value,
						
						type => __PACKAGE__
						
						);
  	        }
		
		chomp( my $first_line = <FILE> );

		my $sign_allowed = join( '|', ( @$this || qw(perl) ) );

		close FILE;
		
		throw Data::Type::Exception(
					    
					    text => sprintf( 'supplied filename doesnt start with #!(%s)', $sign_allowed ),
					    
					    value => $Data::Type::value,
					    
					    type => __PACKAGE__
					    
					    ) unless $first_line =~ /#!$sign_allowed/;
	    }

package Data::Type::Object::std_x500;

	our @ISA = qw(Data::Type::Collection::Std::Interface::Logic);

	our $VERSION = '0.01.37';

	sub _depends { qw(X500::DN) }

        sub export : method { ('X500::DN') }

        sub desc : method { 'X.500 DN (Distinguished Name)' }

	sub info : method { 'distinguished names (see X500::DN)' }

	sub usage  : method { q{()} }

	sub _filters : method { return ( [ 'chomp' ] ) }

	sub _test
	{
		my $this = shift;

			throw Data::Type::Exception(

			    text => sprintf "this is not a %s", $this->desc,

			    value => $Data::Type::value,

			    type => __PACKAGE__

			) unless X500::DN->ParseRFC2253( $Data::Type::value );
	}

package Data::Type::Object::std_xml;

   our @ISA = qw(Data::Type::Collection::Std::Interface::String);

   our $VERSION = '0.01.06';

   sub export { ('XML') }

   sub _depends { qw(XML::Parser) }

   sub desc : method { 'xml markup' }

   sub info : method { qq{xml markup} }

	sub _test
	{
		my $this = shift;

         eval
         {
            my $p = new XML::Parser();

            $p->parse( $Data::Type::value ); #$p->parsefile('REC-xml-19980210.xml');
         };

         throw Data::Type::Exception->new( text => $@ ) if $@;
	}

package Data::Type::Object::std_html;

  our @ISA = qw(Data::Type::Collection::Std::Interface::String);

  our $VERSION = '0.01.37';

  sub export { qw(HTML) }

  sub _depends { qw(HTML::Lint) }

  sub desc : method { 'html markup' }

  sub info : method { <<'END_HERE' }
Tests whether HTML contains invalid constructs (see HTML::Lint).
Throws Data::Type::Exception and the 'catched' member contains the array of HTML::Lint::Error (see pod) objects.
END_HERE
  
  sub usage  : method { <<END_HERE }
( 'structure' (default) | 'fluff' | 'helper' ) They are derived from the HTML::Lint->new() parameters (see HTML::Lint::Error)
END_HERE

  sub _test
  {
      my $this = shift;

      
      my $_alias =
      {
	  structure => HTML::Lint::Error::STRUCTURE(),
	
	  fluff => HTML::Lint::Error::FLUFF(),

	  helper => HTML::Lint::Error::HELPER(),
      };
      
      my @error_sensitivity = HTML::Lint::Error::STRUCTURE();

      push @error_sensitivity, ( map { $_alias->{$_} } @$this );

      my $lint = HTML::Lint->new( only_types => \@error_sensitivity );
      
      $lint->parse( $Data::Type::value );  # $lint->parse_file( $filename );
      
      map { print "# $_\n" } split /\n/, $Data::Type::value;

      throw Data::Type::Exception->new( 
					catched => [ $lint->errors ],
					
					text => sprintf( 'this is not error free %s', $this->desc ),

					value => $Data::Type::value,

					type => __PACKAGE__,

					) if scalar $lint->errors;
   }

1;

=head1 NAME

Data::Type::Collection::Std - the standard set of data types

=head1 SYNOPSIS

 valid '0F 0C 0A', STD::HEX;

 valid '0', STD::DEFINED;
 valid '234', STD::NUM( 20 );
 valid '1', STD::BOOL( 'true' );
 valid '100', STD::INT;
 valid '1.01', STD::REAL;

 valid $email, STD::EMAIL;
 valid $homepage, STD::URI('http');
 valid $cc, STD::CREDITCARD( 'MASTERCARD', 'VISA' );
 valid $answer_a, STD::YESNO;
 valid $gender, STD::GENDER;
 valid 'one', STD::ENUM( qw(one two three) );
 valid [qw(two six)], STD::SET( qw(one two three four five six) ) );
 valid $server_ip4, STD::IP('v4');
 valid $server_ip6, STD::IP('v6');
 
 valid 'A35231AH1', STD::CINS;
 valid '14565935', STD::ISSN; 
 valid 'DE', STD::LANGCODE;
 valid 'German', STD::LANGNAME;
 valid '012345678905', STD::UPC();
 valid '5276440065421319', STD::CREDITCARD( 'MASTERCARD' ) );

 my $foo = bless( \'123', 'SomeThing' );
 valid $foo, STD::REF;
 valid $foo, STD::REF( qw(SomeThing Else) );
 valid [ 'bar' ], STD::REF( 'ARRAY' );

 valid '80', STD::PORT;
 valid 'www.cpan.org', STD::DOMAIN;

 valid '<pre>hello</pre><br>', STD::HTML;
 valid '<field>hello</field>', STD::XML;

=head1 TYPES


=head2 STD::BINARY (since 0.01.25)

binary code

=head3 Usage

Set of ( [0|1] )

=head2 STD::BOOL (since 0.01.25)

boolean value

=head2 STD::CINS (since 0.01.03)

CINS

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

i.e. 035231AH2

=head3 Depends

L<Business::CINS>

=head2 STD::COUNTRYCODE (since 0.01.05)

country code

=head3 Depends

L<Locale::SubCountry>

=head2 STD::COUNTRYNAME (since 0.01.05)

country name

=head3 Depends

L<Locale::SubCountry>

=head2 STD::CREDITCARD (since 0.01.25)

creditcard

=head3 Filters

L<strip|Data::Type::Filter/strip> \D

=head3 Usage

CREDITCARD( Set of [MASTERCARD|AMEX|DISCOVER|BANKCARD|BLACHE|VISA|JCB|DINERS], .. )

=head3 Depends

L<Business::CreditCard>

=head2 STD::DATE (since 0.01.01)

date

=head3 Usage

DATE employs Date::Parse str2time function.

=head3 Depends

L<Date::Parse>

=head2 STD::DEFINED (since 0.01.04)

defined value

=head2 STD::DOMAIN (since 0.01.04)

domain name

=head2 STD::EMAIL (since 0.01.25)

email address

=head3 Usage

[MXCHECK as STD::BOOL]
  MXCHECK results actually tests the mx host via internet (see Email::Valid)


=head3 Depends

L<Email::Valid>

=head2 STD::GENDER (since 0.01.25)

human gender

=head2 STD::GENDER::DE (since 0.01.12)

human gender

=head2 STD::HEX (since 0.01.25)

String

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

Set of ( ([0-9a-fA-F]) )

=head2 STD::HTML (since 0.01.37)

html markup

=head3 Usage

( 'structure' (default) | 'fluff' | 'helper' ) They are derived from the HTML::Lint->new() parameters (see HTML::Lint::Error)


=head3 Depends

L<HTML::Lint>

=head2 STD::INT (since 0.01.27)

integer

=head3 Depends

L<Regexp::Common>

=head2 STD::IP (since 0.01.04)

IP (v4 or v6) or MAC network address

=head3 Depends

L<Regexp::Common>, L<Net::IPv6Addr>

=head2 STD::ISSN (since 0.01.03)

ISSN

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

example: 14565935

=head3 Depends

L<Business::ISSN>

=head2 STD::LANGCODE (since 0.01.03)

language code

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Depends

L<Locale::Language>

=head2 STD::LANGNAME (since 0.01.03)

natural language

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Depends

L<Locale::Language>

=head2 STD::NUM (since 0.01.25)

number

=head2 STD::PATH (since 0.01.06)

path

=head2 STD::POD (since 0.01.36)

file containing Pod instructions

=head3 Usage

POD() requires a filename value

=head3 Depends

L<Pod::Find>

=head2 STD::PORT (since 0.01.04)

tcp port number

=head2 STD::QUOTED (since 0.01.25)

quoted string

=head3 Depends

L<Regexp::Common>

=head2 STD::REAL (since 0.01.25)

real

=head3 Depends

L<Regexp::Common>

=head2 STD::REF (since 0.01.25)

perl reference

=head2 STD::REGIONCODE (since 0.01.05)

country region code

=head3 Depends

L<Locale::SubCountry>

=head2 STD::REGIONNAME (since 0.01.05)

country region

=head3 Depends

L<Locale::SubCountry>

=head2 STD::SHEBANG (since 0.01.36)

file containing a she-bang (#!)

=head3 Usage

( SIGNATURE [, SIGNATURE] ) - SIGNATURE is a text fragment (default: perl)

=head2 STD::UPC (since 0.01.03)

UPC

=head3 Filters

L<strip|Data::Type::Filter/strip> \s

=head3 Usage

i.e. 012345678905

=head3 Depends

L<Business::UPC>

=head2 STD::URI (since 0.01.25)

uri

=head3 Depends

L<Regexp::Common>

=head2 STD::WORD (since 0.01.25)

word (without whitespaces)

=head2 STD::X500::DN (since 0.01.37)

X.500 DN (Distinguished Name)

=head3 Usage

()

=head3 Depends

L<X500::DN>

=head2 STD::XML (since 0.01.06)

xml markup

=head3 Depends

L<XML::Parser>

=head2 STD::YESNO (since 0.01.25)

primitiv answer

=head2 STD::YESNO::DE (since 0.01.14)

primitiv answer

=head2 STD::ZIP (since 0.01.14)

zip code

=head3 Usage

ZIP( "DE" | "AU" | "DK" | "NL" | "US" | "BE" | "FR" )

=head3 Depends

L<Regexp::Common>



=head1 INTERFACE


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

