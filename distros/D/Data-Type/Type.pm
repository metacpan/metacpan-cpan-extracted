# (c) 2002 by Murat Ünalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself


require 5.005_62; use strict; use warnings;

use Class::Maker;

use Error qw(:try);

use Locale::Language;	# required by langcode langname

package Type::Exception;

	our @ISA = qw(Error);

	sub new
	{
		my $class = shift;

		$class = ref( $class ) || $class;

	    local $Error::Depth = $Error::Depth + 1;

		my %args = @_;

		my %super_args;

		foreach my $key ( qw(text package file line object) )
		{
			if( exists $args{$key} )
			{
				$super_args{'-'.$key} = $args{$key};

				delete $args{$key};
			}
		}
		
		return $class->SUPER::new( %super_args );
	}

package Failure::Type;

	Class::Maker::class
	{
		isa => [qw(Type::Exception)],

		public =>
	    {
	    	bool => [qw( expected returned )],

			string => [qw( was_file )],

	    	int => [qw( was_line )],

	    	ref => [qw( type value )],
	    },
	};

package Failure::Facet;

	Class::Maker::class
	{
		isa => [qw(Type::Exception)],
		
		public =>
	    {
	    	bool => [qw( expected returned )],

	    	ref => [qw( type )],
	    },
	};

package Data::Type;

	use IO::Extended qw(:all);
	
	use Iter qw(:all);

	our @types = type_list();

		# generate Type subs

	codegen();

	use Exporter;

	our @ISA = qw( Exporter );

	our %EXPORT_TAGS = ( 'all' => [ qw(typ untyp istyp verify overify catalog toc testplan), map { uc } @types ] );

	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

	our @EXPORT = ();

	our $VERSION = "0.01.04";

	our $DEBUG = 0;

	our @_history;

	our $tie_registry = {};
	
	no strict 'refs';

	sub strlimit
	{
		my $limit = $_[1] || 60;

		return length( $_[0] ) > $limit ? join('', (split(//, $_[0]))[0..$limit-1]).'..' : $_[0];
	}

	sub info
	{
		my $that = shift;

		my $value = shift;

		$value = '' unless defined( $value );

		printfln "\n\nType '%s' against '%s' (%s)", $value, ref $that, strlimit( $that->info ) if $DEBUG;
	}

	sub expect
	{
		my $expected = shift;

		foreach my $that ( @_ )
		{
			::try
			{
				$that->test( $Type::value );

				#info( $that ) if $DEBUG;
			}
			catch Failure::Facet ::with
			{
				my @back = caller(7);

				throw Failure::Type( value => $Type::value, type => $that, was_file => $back[1], was_line => $back[2] ) if $expected;
			};
		}
	}

	sub recording_expect
	{
		my $expected = shift;

		foreach my $that ( @_ )
		{
			push @Data::Type::_history, [ $that, $expected ];
		}
	}

	our $current_expect = 'expect';

	sub pass
	{
		$current_expect->( 1, @_ );
	}

	sub fail
	{
		$current_expect->( 0, @_ );
	}

	sub assert
	{
		println $_[0] ? '..ok' : '..failed';
	}

		# Tests Types

	sub verify
	{
		my $value = shift;

		foreach my $that ( @_ )
		{
			$Type::value = undef;

			info( $that, $value ) if $DEBUG;

			$that->test( $value );
		}
	}

		# Wrapper for dying instead of throwing exceptions

	sub dverify
	{
		my @args = @_;
		
		my $dead;
		
			try
			{
				verify( @_ );
			}
			catch Type::Exception ::with
			{
				my $e = shift;
				
				$dead = sprintf "Expected '%s' %s at %s line %s\n",
					$e->value, 
					$e->type->info, 
					$e->was_file, 
					$e->was_line;
			};
		
			return 1 unless $dead;

			$! = $dead;
			
	return undef;	
	}
	
		# verify a collection of types against an object
		
	sub overify 
	{
		my $rules = shift;
	
		my @objects = @_;

		my $m;
				
		::try
		{
			foreach my $obj ( @objects )
			{
				foreach ( iter $rules )
				{ 
					my ( $m, $t ) = ( key(), value() );
									
					if( ref( $t ) eq 'ARRAY' ) 
					{
						verify( $obj->$m ,  @{ $t } );
					}
					elsif( ref( $t ) eq 'CODE' )
					{
						throw Type::Exception( text => 'overify failed with '.$m.' for object via CODEREF' ) unless $t->( $obj->$m );
					}
					else
					{
						verify( $obj->$m , $t );
					}
				}
			}
		}
		catch Type::Exception ::with
		{			
			my $e = shift;
			
			throw $e; 
		};
	}

	sub testplan
	{
		@Data::Type::_history = ();

		$Data::Type::current_expect = 'recording_expect';

		foreach my $that ( @_ )
		{
			$Type::value = undef;

			$that->test( '' );
		}

		$Data::Type::current_expect = 'expect';

		return @Data::Type::_history;
	}

		# carefull: names beginning with _ are ignored !
		
	sub _grasp_sym_list
	{
        my $pk = shift or die;
        
		my @types = Data::Type::_search_pkg( $pk );

		my @result;

		foreach my $key ( @types )
		{
			( my $name ) = ( $key =~ /::(.+)::$/ );

			push @result, $name if $name =~ /^[a-z]/;
		}

		return @result;
	}
	
	sub type_list { _grasp_sym_list( 'Type::' ) };
	
	sub filter_list { _grasp_sym_list( 'Filter::' ) };

	sub catalog
	{
		my @types = sort { $a cmp $b } type_list();

		my $result;
		
		$result .= sprintf __PACKAGE__." $VERSION supports %d types:\n\n", scalar @types;
				
		foreach my $name ( @types )
		{						
			$result .= sprintf "%s%-15s %-8s - %s\n", " " x 2, 
				
				"Type::${name}"->can( 'export' ) ? join( ', ', "Type::${name}"->export ) : _translate( $name ), 

				"Type::${name}"->VERSION || '', 				
				
				strlimit( ( bless [], "Type::${name}" )->info(  ) );
		}

		@types = sort { $a cmp $b } filter_list();

		$result .= sprintf "\nAnd %d filters:\n\n", scalar @types;

		foreach my $name ( @types )
		{
			$result .= sprintf "  %-18s - %s\n", _translate( $name ), strlimit( ( bless [], "Filter::${name}" )->info(  ) );
		}
		
		return $result;
	}

	sub _show_list
	{
		my $hash = shift;
		
		my $ind = shift || 1;
		
		my $result;
		
		foreach my $key (keys %$hash)
		{
			my $val = $hash->{ $key };
			
				# headlines 
				
			unless( ref( $key ) )
			{
				$result .= sprintf "%s%s\n", " " x $ind, $key;
			}
			else
			{
				$result .= sprintf "%s%s\n", " " x $ind, $_ for @$key;
			}
						
				# contents
				
			if( ref( $val ) eq 'ARRAY' )
			{
				$result .= sprintf "%s%s\n\n", "  " x $ind, join( ', ', sort { $a cmp $b } @$val ); 
			}
			elsif( ref( $val ) eq 'HASH' )
			{			
				$result .= _show_list( $val, $ind + 2 );
			}
		}
	
	return $result;
	}

	sub _unique_ordered
	{
		my $prev = shift;
			
		my @result = ( $prev );
				
		for ( iter \@_ )
		{			
			push @result, VALUE() if VALUE() ne $prev;
			
			$prev = $_;
		}
		
	return @result;
	}
	
	sub toc
	{
		my @types = type_list();

		my $result;
				
		use Tie::ListKeyedHash;
		
		tie my %tied_hash, 'Tie::ListKeyedHash';
		
		foreach my $name ( @types )
		{						
			my @isa = _unique_ordered @{ Class::Maker::Reflection::inheritance_isa( @{ "Type::${name}::ISA" } ) };
										
			my $special_key = [ _unique_ordered map { $_->can( 'desc' ) ?  $_->desc : () } @isa ];
						
			$tied_hash{ $special_key } = [] unless defined $tied_hash{ $special_key };
										 
			push @{ $tied_hash{ $special_key } }, 
				
				sprintf( '%s', 
						
						"Type::${name}"->can( 'export' ) ? join( ', ', "Type::${name}"->export ) : _translate( $name )
						
				);
		}
		
		$result .= _show_list \%tied_hash;
		
	return $result;
	}

	sub depends
	{
		my %result;
				
		foreach my $name ( type_list() )
		{	
			if( "Type::${name}"->can( 'depends' ) )
			{				
				foreach my $mod ("Type::${name}"->depends )
				{
					eval "use $mod";
	
					die "$@ $!" if $@;
					
					$result{$mod}->{version} = $mod->VERSION unless exists $result{$mod}->{version};
					
					$result{$mod}->{types} = [] unless exists $result{$mod}->{types};
					
					push @{ $result{$mod}->{types} }, { name => _translate( $name ) };
				}
			}
		}
				
	return \%result;
	}

	sub typ
	{
		my $type = shift;

		foreach my $xref ( @_ )
		{
			ref($xref) or die sprintf "typ: %s reference detected, instead of a reference.", lc ref($xref) || 'no';

			$type->isa( 'IType::UNIVERSAL' ) or die sprintf "typed( ref, TYPE ) expects a TYPE as second arguemnt. You supplied '%s' which is not.", $type;

			tie $$xref, 'Data::Type::Typed', $type;
			
			$tie_registry->{$xref+0} = ref( $type );
		}
		
		return 1;
	}

	sub istyp
	{		
		no warnings;
		
		return $tie_registry->{ $_[0]+0 } if exists $tie_registry->{ $_[0]+0 };  
	}
	
	sub untyp
	{
		untie $$_ for @_;
		
		delete $tie_registry->{$_+0} for @_;
	}

	use subs qw(typ untyp);

	sub _search_pkg
	{
		my $path = '';

		my @found;

		no strict 'refs';

		foreach my $pkg ( @_ )
		{
			next unless $pkg =~ /::$/;

			$path .= $pkg;

			if( $path =~ /(.*)::$/ )
			{
				foreach my $symbol ( sort keys %{$path} )
				{
					if( $symbol =~ /::$/ && $symbol ne 'main::' )
					{
						push @found, "${path}${symbol}";
					}
				}
			}
		}

	return @found;
	}

			# Generate Type alias subs
			#
			# - Generate subs like 'VARCHAR' into this package
			# - These are then Exported
			#
			# Note that codegen is called above

	sub _translate
	{
		return uc shift;
	}
	
	sub _export
	{
		my $what = shift;

		foreach my $where ( @_ )
		{
			warn "exporting $what to $where" if $DEBUG;
			
			println sprintf "sub %s { Type::Proxy::%s( \@_ ); };", _translate( $where ), _translate( $what ) if $DEBUG;
	
			eval sprintf "sub %s { Type::Proxy::%s( \@_ ); };", _translate( $where ), _translate( $what );
	
			warn $@ if $@;
		}
	}
	
	sub codegen
	{
		my @aliases;
		
		foreach my $type ( Data::Type::type_list() )
		{
			println $type if $DEBUG;

			my $type_pkg = "Type::${type}";
			
			warn "$type_pkg can( 'export' ) ? ", $type_pkg->can( 'export' ) ? 'yes' : 'no' if $DEBUG;
			
			_export( $type, $type_pkg->can( 'export' ) ?  $type_pkg->export : _translate( $type ) );
			 
			push @aliases, $type_pkg->can( 'export' ) ?  $type_pkg->export : _translate( $type );
		}

		println sprintf "use subs qw(%s);", join ' ', @aliases if $DEBUG;

		eval sprintf "use subs qw(%s);", join ' ', @aliases;

		warn $@ if $@;
	}

package Data::Type::Locale;

	# add localization stuff here
	
package Type::Proxy;

	use vars qw($AUTOLOAD);

	sub AUTOLOAD
	{
		( my $func = $AUTOLOAD ) =~ s/.*:://;

	return bless [ @_ ], sprintf "Type::%s", lc $func;
	}

package Regex;

	use Regexp::Common;

	use Carp;
	
	sub exact
	{
		return '^'.$_[0].'$';
	}
		
	our $LIST =
	{
		word => qr/[^\s]+/,
		
		mysql_date => qr/\d{4}-[01]\d-[0-3]\d/,
		
		mysql_datetime => qr/\d{4}-[01]\d-[0-3]\d [0-2]\d:[0-6]\d:[0-6]\d/,
		
		mysql_timestamp => qr/[1-2][9|0][7-9,0-3][0-7]-[01]\d-[0-3]\d [0-2]\d:[0-6]\d:[0-6]\d/,
		
		mysql_time => qr/-?\d{3,3}:[0-6]\d:[0-6]\d/,
		
		mysql_year4 => qr/[0-2][9,0,1]\d\d/,
		
		mysql_year2 => qr/\d{2,2}/,
		
		binary => qr/[01]+/,
		
		hex => qr/[0-9a-fA-F]+/,
		
		email => qr/(?:[^\@]*)\@(?:\w+)(?:\.\w+)+/,	# not used 

		dna => qr/[ATGC]+/,
		
		rna => qr/[AUGC]+/,
		
		triplet => qr/[ATGC]{3,3}/,
		
		domain => qr/[a-z0-9\.-]+/,
	};
	
	sub list
	{
		return $LIST->{$_[0]} if exists $LIST->{$_[0]};
		
		carp "Unknown $_[0] Regex::list regex requested";
	}

package Type;

		# This value is important. It gets reset to undef in verify() before the test starts. During test
		# it hold the $value of the data to tested against.

	our $value;

package IType::UNIVERSAL;

	sub to_text : method
	{
		my $this = shift;

		die "abstract IType::UNIVERSAL::to_text() called.";
	}

	sub cast : method
	{
		die "abstract IType::UNIVERSAL::cast() called.";		
	}
	
package IType::Numeric;

	our @ISA = qw(IType::UNIVERSAL);

	sub desc { 'Numeric' }
	
package IType::Temporal;

	our @ISA = qw(IType::UNIVERSAL);

	sub desc { 'Time or Date related' }

package IType::String;

	our @ISA = qw(IType::UNIVERSAL);

	sub desc { 'String' }

package IType::Logic;

	our @ISA = qw(IType::UNIVERSAL);

	sub desc { 'Logic' }

package IType::DB::Mysql;

	our @ISA = qw(IType::UNIVERSAL);

	sub desc { 'Database' }

package IType::W3C;

	our @ISA = qw(IType::UNIVERSAL);

	sub desc { 'W3C' }

package IType::Business;

	our @ISA = qw(IType::UNIVERSAL);

	our $VERSION = '0.01.03';
	
	sub desc { 'Business' }

package Type::varchar;

	our @ISA = qw(IType::String);

	sub info
	{
		my $this = shift;

		return sprintf 'a string with limited length of %s', $this->[0] || 'choice (default 60)';
	}

	sub test
	{
		my $this = shift;

		$Type::value = length( shift );

			Data::Type::pass( Facet::Proxy::range( 0, $this->[0] || 60 ) );
	}

package Type::word;

	our @ISA = qw(IType::String);

	sub info
	{
		my $this = shift;

		return 'a word (without spaces)';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::list( 'word' ) ) );
	}

package Type::bool;

	our @ISA = qw(IType::Numeric);

	sub info
	{
		my $this = shift;

		return sprintf 'a %s value', $this->[0] || 'true or false';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			if( $this->[0] eq 'true' )
			{
				Data::Type::pass( Facet::Proxy::bool( $this->[0] ) );
			}
			else
			{
				Data::Type::fail( Facet::Proxy::bool( $this->[0] ) );
			}
	}

package Type::int;

	our @ISA = qw(IType::Numeric);

	sub depends { qw(Regexp::Common) }

	sub info
	{
		my $this = shift;

		return 'an integer';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( $Regex::RE{num}{int} ) ) );
	}

package Type::num;

	our @ISA = qw(IType::Numeric);

	sub info
	{
		my $this = shift;

		return 'a number';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

				# Here we test the hierarchy feature -> nested types !

			Type::int->test( $Type::value );
	}

package Type::real;

	our @ISA = qw(IType::Numeric);

	sub depends { qw(Regexp::Common) }

	sub info
	{
		my $this = shift;

		return 'a real';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( $Regex::RE{num}{real} ) ) );
	}

package Type::quoted;

	our @ISA = qw(IType::String);

	sub depends { qw(Regexp::Common) }

	sub info
	{
		my $this = shift;

		return 'a quoted string';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( $Regex::RE{quoted} ) ) );
	}

package Type::gender;

	our @ISA = qw(IType::String);

	sub info
	{
		my $this = shift;

		return sprintf 'a gender %s', join( ', ', $this->param );
	}
	
	sub param { qw(male female) }

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::exists( [ $this->param ] ) );
	}

package Type::yesno;

	our @ISA = qw(IType::String);

	sub info 
	{	
		my $this = shift;
				
		return sprintf q{a simple answer (%s)}, join( ', ', $this->param ) ;
	}

	sub param { qw(yes no) }
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;
		
			Filter::chomp->filter( \$Type::value );
			
			Filter::lc->filter( \$Type::value );

			Data::Type::pass( Facet::Proxy::exists( [ $this->param ] ) );
	}

package Type::dk_yesno;

	our @ISA = qw(Type::yesno);
	
	sub export { qw(DK::YESNO) };
		
	sub param { qw(ja nein) }

	# HERE START THE MYSQL TYPES
	
package Type::date;

	our @ISA = qw(IType::DB::Mysql IType::Temporal);

	our $VERSION = '0.01.01';
	
	sub depends { qw(Date::Parse) }
	
	sub info
	{
		my $this = shift;

			#The supported range is '1000-01-01' to '9999-12-31' (mysql)

		return 'a date (mysql or Date::Parse conform)';
	}

	sub usage 
	{
		my $this = shift;
		
		return <<ENDE;
DATE( [ 'MYSQL','DATEPARSE' ] ) MYSQL is mysql's builtin data type behaviour 
and DATAPARSE employs Data::Parse's str2time function. Filtered by: chomp.
ENDE
	}
	
	our $supported = { mysql => 1, dateparse => 1 };
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;
		
		my $format = 'mysql';
		
			$format = $this->[0] if @$this;

			$format = lc $format;

			my @back = caller(1);
						
			throw Failure::Type( 
				
				text => "unknown ".__PACKAGE__." argument '$format'",
				
				value => $Type::value, type => __PACKAGE__, was_file => $back[1], was_line => $back[2] 
				
				) unless exists $supported->{$format};

			Filter::chomp->filter( \$Type::value );
	
			if( $format eq 'mysql' )
			{
				Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'mysql_date' ) ) ) );
			}
			elsif( $format eq 'dateparse' )
			{
				use Date::Parse;
	
				#Date::Parse->language('German');
										
				throw Failure::Type( 
					
					text => 'is not a Date::Parse date',
					
					value => $Type::value, type => __PACKAGE__, was_file => $back[1], was_line => $back[2] 
					
					) unless str2time( $Type::value );
			}
	}

package Type::datetime;

	our @ISA = qw(IType::DB::Mysql IType::Temporal);

	sub info
	{
		my $this = shift;

			 #The supported range is '1000-01-01 00:00:00' to '9999-12-31 23:59:59' (mysql)

		return 'a date and time combination';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'mysql_datetime' ) ) ) );
	}

package Type::timestamp;

	our @ISA = qw(IType::DB::Mysql IType::Temporal);

	sub info
	{
		my $this = shift;

		return 'a timestamp (mysql)';
	}

	sub usage 
	{
		return q{The range is '1970-01-01 00:00:00' to sometime in the year 2037 (mysql)};
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'mysql_timestamp' ) ) ) );
	}

package Type::time;

	our @ISA = qw(IType::DB::Mysql IType::Temporal);

	sub info
	{
		my $this = shift;

		return 'a time (mysql)';
	}

	sub usage
	{
		return q{The range is '-838:59:59' to '838:59:59' (mysql)};
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'mysql_time' ) ) ) );
	}

package Type::year;

	our @ISA = qw(IType::DB::Mysql IType::Temporal);

	sub info
	{
		my $this = shift;

		return 'a year in 2- or 4-digit format';
	}
	
	sub usage 
	{
		return 	'The allowable values are 1901 to 2155, 0000 in the 4-digit year format, and 1970-2069 if you use the 2-digit format (70-69) (default is 4-digit)';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			my $yformat = $this->[0] || 4;

			if( $yformat == 2 )
			{
					#1970-2069 if you use the 2-digit format (70-69);

				Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'mysql_year2' ) ) ) );
			}
			else
			{
					#The allowable values are 1901 to 2155, 0000 in the 4-digit

				Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'mysql_year4' ) ) ) );
			}
	}

package Type::tinytext;

	our @ISA = qw(IType::DB::Mysql IType::String);

	sub info
	{
		my $this = shift;

		return "text with a max length of 255 (2^8 - 1) characters (alias mysql tinyblob)";
	}

	sub test
	{
		my $this = shift;

		$Type::value = length( shift );

			Data::Type::pass( Facet::Proxy::max( 255 ) );
	}

package Type::text;

	our @ISA = qw(IType::DB::Mysql IType::String);

	sub info
	{
		my $this = shift;

		return "blob with a max length of 65535 (2^16 - 1) characters (alias mysql text)";
	}

	sub test
	{
		my $this = shift;

		$Type::value = length( shift );

			Data::Type::pass( Facet::Proxy::max( 65535 ) );
	}

package Type::mediumtext;

	our @ISA = qw(IType::DB::Mysql IType::String);

	sub info
	{
		my $this = shift;

		return "text with a max length of 16777215 (2^24 - 1) characters (alias mysql mediumblob)";
	}

	sub test
	{
		my $this = shift;

		$Type::value = length( shift );

			Data::Type::pass( Facet::Proxy::max( 16777215 ) );
	}

package Type::longtext;

	our @ISA = qw(IType::DB::Mysql IType::String);

	sub info
	{
		my $this = shift;

		return "text with a max length of 4294967295 (2^32 - 1) characters (alias mysql longblob)";
	}

	sub test
	{
		my $this = shift;

		$Type::value = length( shift );

			Data::Type::pass( Facet::Proxy::max( 4294967295 ) );
	}

package Type::enum;

	our @ISA = qw(IType::DB::Mysql IType::Logic);

	sub info
	{
		my $this = shift;

			#A string object that can have only one value, chosen from the list of values 'value1', 'value2', ..., NULL or the special "" error value. An ENUM can have a maximum of 65535 distinct values (mysql)

		return qq{a member of an enumeration};
	}

	sub param { { max => 65535 } }

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			throw Failure::Facet() if @$this > $this->param->{max};

			Data::Type::pass( Facet::Proxy::exists( [ @$this ] ) );
	}

package Type::set;

	our @ISA = qw(IType::DB::Mysql IType::Logic);

	sub info
	{
		my $this = shift;

			# A string object that can have zero or more values, each of which must be chosen from the list of values 'value1', 'value2', ... A SET can have a maximum of 64 members. (mysql)

		return qq{a set (can have a maximum of 64 members (mysql))};
	}

	sub param { { limit => 64, max => 65535 } }
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			throw Failure::Facet() if @$Type::value > $this->param->{limit};

			throw Failure::Facet() if @$this > $this->param->{max};

			Data::Type::pass( Facet::Proxy::exists( [ @$this ] ) );
	}

package Type::ref;

	our @ISA = qw(IType::Logic);

	sub info
	{
		my $this = shift;

		return qq{a reference to a variable};
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::ref( $Type::value ) );
						
			if( @$this )
			{
				$Type::value = ref( $Type::value );
				
				$this = [ @$this ] unless ref( $this ) eq 'ARRAY';
				
				Data::Type::pass( Facet::Proxy::exists( [ @$this ] ) );
			}
	}

package Type::creditcard;

	our @ISA = qw(IType::Business);

	sub depends { qw(Business::CreditCard) }

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
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\D' );

			printf "creditcard '%s' is about to be tested\n", $Type::value if $Data::Type::DEBUG;
			
			Data::Type::pass( Facet::Proxy::mod10check( $Type::value ) );

			push @$this, $default_cc unless @$this;
			
			my $results = {};
			
			foreach ( @$this )
			{
				$results->{$_} = [];
				
				my $card = $cardformats->{$_};
				
				push @{ $results->{$_} }, 'digits' if map { length($Type::value) eq $_ ? () : 'invalid' } @{ $card->{digits} };
				
				if( ref $card->{prefix} eq 'HASH' )
				{					
					my $prefix;
					
					while( my( $min, $max ) = each %{ $card->{prefix} } )
					{
						$prefix = pack( 'a'.length($max), $Type::value );

						push @{ $results->{$_} }, 'prefix' if $prefix+0 > $max;

						$prefix = pack( 'a'.length($min), $Type::value );

						push @{ $results->{$_} }, 'prefix' if $prefix+0 < $min;
					}
				}
				elsif( ref $card->{prefix} eq 'ARRAY' )
				{
					for ( @{ $card->{prefix} } )
					{
						$_ .= '';
						
						push @{ $results->{$_} }, 'prefix' unless $Type::value =~ /$_/;
					}
				}
			}
			
		throw Failure::Facet() unless map { @{ $results->{$_} } == 0 ? 1 : () } keys %$results;
	}

package Type::binary;

	our @ISA = qw(IType::W3C IType::String);

	sub info
	{
		my $this = shift;

		return qq{binary code};
	}

	sub usage 
	{
		
	return 'Set of ( [0|1] )';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'binary' ) ) ) );
	}

package Type::hex;

	our @ISA = qw(IType::W3C IType::String);

	sub info
	{
		my $this = shift;

		return qq{hexadecimal code};
	}

	sub usage 
	{
		
	return 'Set of ( ([0-9a-fA-F]) )';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'hex' ) ) ) );
	}

package Type::langcode;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.03';

	sub depends { qw(Locale::Language) }
	
	sub info
	{
		my $this = shift;

		return qq{a Locale::Language language code};
	}

	sub usage 
	{
		
	return '';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );
			Filter::lc->filter( \$Type::value );
						
			Data::Type::pass( Facet::Proxy::exists( [ Locale::Language::all_language_codes() ] ) );
	}

package Type::langname;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.03';

	sub depends { qw(Locale::Language) }
	
	sub info
	{
		my $this = shift;

		return qq{a language name};
	}

	sub usage 
	{
		
	return '';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );
						
			Data::Type::pass( Facet::Proxy::exists( [ Locale::Language::all_language_names() ] ) );
	}

package Type::issn;

	our @ISA = qw(IType::Business);

	our $VERSION = '0.01.03';

	sub depends { qw(Business::ISSN) }

	sub info
	{
		my $this = shift;

		return qq{an International Standard Serial Number};
	}

	sub usage 
	{
		
	return 'example: 14565935';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );

			use Business::ISSN;
			
			throw Failure::Facet() unless new Business::ISSN( $Type::value )->is_valid;
	}

package Type::upc;

	our @ISA = qw(IType::Business);

	our $VERSION = '0.01.03';

	sub depends { qw(Business::UPC) }

	sub info
	{
		my $this = shift;

		return qq{standard (type-A) Universal Product Code};
	}

	sub usage 
	{
		return 'i.e. 012345678905';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );

			use Business::UPC;
			
			throw Failure::Facet() unless Business::UPC->new( $Type::value )->is_valid;
	}

package Type::cins;

	our @ISA = qw(IType::Business);

	our $VERSION = '0.01.03';

	sub depends { qw(Business::CINS) }

	sub info
	{
		my $this = shift;

		return qq{a CUSIP International Numbering System Number};
	}

	sub usage 
	{
		
	return 'i.e. 035231AH2';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );

			use Business::CINS;

			my $result = Business::CINS->new( $Type::value )->error;
			
			throw Failure::Facet( text => $result ) if defined $result;
	}

	# BIO stuff
	
	# Resources: http://users.rcn.com/jkimball.ma.ultranet/BiologyPages/C/Codons.html
	# CPAN: Bio::Tools::CodonTable 	
	
package Type::dna;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.03';

	sub export { qw(BIO::DNA) }

	sub info
	{
		my $this = shift;

		return q{a dna sequence};
	}

	sub usage 
	{
		
	return 'sequence of [ATGC]';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'dna' ) ) ) );
	}

package Type::rna;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.03';

	sub export { qw(BIO::RNA) }

	sub info
	{
		my $this = shift;

		return qq{a rna sequence};
	}

	sub usage 
	{
		
	return 'sequence of [ATUC]';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );

			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'rna' ) ) ) );
	}

package Type::codon;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.03';

	sub export { qw(BIO::CODON) }

	sub info
	{
		my $this = shift;

		return qq{a DNA (default) or RNA nucleoside triphosphates triplet};
	}

	sub usage 
	{
		
	return 'a triplet of DNA or RNA';
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Filter::strip->filter( \$Type::value, '\s' );
			Filter::chomp->filter( \$Type::value );
			Filter::uc->filter( \$Type::value );
			
			my $kind = $this->[0] || 'DNA';
			
			die sprintf "'%s' expects 'DNA' or 'RNA' as an argument and not '%s'",$this->export,$kind unless $kind eq 'DNA' || $kind eq 'RNA';
			
			#Data::Type::verify $Type::value, Type::Proxy::dna if $kind eq 'DNA';
			#Data::Type::verify $Type::value, Type::Proxy::rna if $kind eq 'RNA';
			
			Data::Type::pass( Facet::Proxy::match( Regex::exact( Regex::list( 'triplet' ) ) ) );
	}

package Type::defined;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.04';

	sub info
	{
		return qq{a defined (not undef) value};
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;
			
			Data::Type::pass( Facet::Proxy::defined() );
	}

package Type::email;

	our @ISA = qw(IType::Logic);

	sub depends { qw(Email::Valid) }

	sub info
	{
		my $this = shift;

		return 'an email address';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			Data::Type::pass( Facet::Proxy::email( $this->[0] ) );

			#Data::Type::pass( Facet::Proxy::match( Regex::list( 'email' ) ) );
	}

package Type::uri;

	our @ISA = qw(IType::Logic);

	sub depends { qw(Regexp::Common) }

	sub info
	{
		my $this = shift;

		my $scheme = $this->[0] || 'http';

		return sprintf 'an %s uri', $scheme;
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			my $scheme = $this->[0] || 'http';

			Data::Type::pass( Facet::Proxy::match( Regex::exact( $Regex::RE{URI}{HTTP}{'-scheme='.$scheme} ) ) );
	}

package Type::ip;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.04';
	
	sub depends { qw(Regexp::Common Net::IPv6Addr) }
	
	use Net::IPv6Addr;
	
	sub info
	{
		my $this = shift;

		return 'an IP (V4, V6, MAC) network address';
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;

			my $format = lc( $this->[0] || 'v4' );

			$format = 'IP'.$format if $format =~ /^[vV][46]$/;

			if( $format =~ /6/ )
			{				
				eval
				{
					new Net::IPv6Addr( $Type::value );
				};
				
				throw Failure::Type ( text => $@ ) if $@;
			}
			else
			{
				Data::Type::pass( Facet::Proxy::match( Regex::exact( $Regex::RE{net}{$format} ) ) );
			}
	}

		
package Type::domain;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.04';

	sub info
	{
		return qq{a network domain name};
	}

	sub test
	{
		my $this = shift;

		$Type::value = shift;
			
			Data::Type::pass( Facet::Proxy::defined() );

			Filter::lc->filter( \$Type::value );
			
			Data::Type::pass( Facet::Proxy::match( Regex::list( 'domain' ) ) );
					
			foreach my $segment ( split /\./, $Type::value ) 
			{
				Data::Type::pass( Facet::Proxy::match( qw/[^a-z]/ ) );	#must contain at least one alphabetical character
				Data::Type::fail( Facet::Proxy::match( qw/^-/ ) );		#cannot start with a dash
				Data::Type::fail( Facet::Proxy::match( qw/-$/ ) );		#cannot end with a dash
				Data::Type::fail( Facet::Proxy::match( qw/--/ ) );		#cannot have two dashes in a row
			}
	}

package Type::port;

	our @ISA = qw(IType::Logic);

	our $VERSION = '0.01.04';

	sub info
	{
		return qq{a network port number};
	}
	
	sub test
	{
		my $this = shift;

		$Type::value = shift;
			
			Type::int->test( $Type::value );
		
			Data::Type::fail( Facet::Proxy::match( qr/^0/ ) );
		
			Data::Type::pass( Facet::Proxy::max( 65535 ) );
	}

	#
	# Facets here
	#

package Facet::Proxy;

	use vars qw($AUTOLOAD);

	sub AUTOLOAD
	{
		( my $func = $AUTOLOAD ) =~ s/.*:://;

	return bless [ @_ ], sprintf 'Facet::%s', $func;
	}

package Facet::email;

	use Email::Valid;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		my $mxcheck = shift || 0;

		throw Failure::Facet() unless Email::Valid->address( -address => $val, -mxcheck => $mxcheck );
	}

	sub info : method
	{
		my $this = shift;

		my $mxcheck = shift || 0;

		return sprintf "a valid email address (%s mxcheck)", $mxcheck ? 'with' : 'without';
	}

package Facet::ref;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless ref( $val );
	}

	sub info : method
	{
		my $this = shift;

		return sprintf $this->[0] ? 'reference' : 'reference to %s', $this->[0];
	}

package Facet::range;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless defined( $val );

		throw Failure::Facet() unless $val >= $this->[0] && $val <= $this->[1];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'between %s - %s', $this->[0], $this->[1];
	}

package Facet::lines;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless defined($val);

		throw Failure::Facet() unless ($val =~ s/(\n)//g) > $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf '%d lines', $this->[0];
	}

package Facet::less;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless defined($val);

		throw Failure::Facet() unless length($val) < $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'less than %d chars long', $this->[0];
	}

package Facet::max;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless defined($val);

		throw Failure::Facet() if $val > $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'maximum of %d', $this->[0];
	}

package Facet::min;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless defined($val);

		throw Failure::Facet() if $val < $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'minimum of %d', $this->[0];
	}

package Facet::match;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless defined($val);

		throw Failure::Facet() unless $val =~ $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'matching the regular expression /%s/', $this->[0];
	}

package Facet::is;

	sub test : method
	{
		my $this = shift;

		throw Failure::Facet() unless $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'exact %s', $this->[0];
	}

package Facet::defined;

	our $VERSION = qw(0.01.04);
	
	sub test : method
	{
		my $this = shift;

		throw Failure::Facet() unless defined shift;
	}

	sub info : method
	{
		my $this = shift;

		return sprintf 'a defined (not undef) value';
	}

package Facet::bool;

	sub test : method
	{
		my $this = shift;

		throw Failure::Facet() unless $this->[0];
	}

	sub info : method
	{
		my $this = shift;

		return sprintf "boolean '%s' value", $this->[0] ? 'true' : 'false';
	}

package Facet::null;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

		throw Failure::Facet() unless uc( $val ) eq 'NULL';
	}

	sub info : method
	{
		my $this = shift;

		return "exactly 'NULL'";
	}

package Facet::exists;

	sub test : method
	{
		my $this = shift;
			        
		my $val = shift;
				
			if( ref( $val ) eq 'ARRAY' )
			{				
					# if we have to test against an array, just go through the
					# elements and look if they exist in the $val hash
					
				$this->test( $_ ) for @$val;

				return;
			}

				# convert an array to hash inplace
				
			if( ref( $this->[0] ) eq 'ARRAY' )
			{				
				my %hash;

				@hash{ @{ $this->[0] } } = 1;

				$this->[0] = \%hash;
			}

		throw Failure::Facet() unless exists $this->[0]->{$val};
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

package Facet::mod10check;

	# could have used Algorithm::LUHN
	
	use Business::CreditCard;

	sub test : method
	{
		my $this = shift;

		my $val = shift;

			# We use Business::CreditCard's mod10 luhn
			
		throw Failure::Facet() unless validate( $val );
	}

	sub info : method
	{
		my $this = shift;

		return 'LUHN formula (mod 10) for validation of creditcards';
	}
	
package Filter;

	sub filter : method
	{
		die "abstract method called";
	}

	sub info : method
	{
		die "abstract method called";
	}

package Filter::chomp;

	our @ISA = ( 'Filter' );
	
	sub filter : method
	{
		my $this = shift;

		my $sref_val = shift;
		
	return chomp $$sref_val;
	}

	sub info : method
	{
		my $this = shift;

		return "chomps";
	}

package Filter::lc;

	our @ISA = ( 'Filter' );
	
	sub filter : method
	{
		my $this = shift;

		my $sref_val = shift;
		
	return $$sref_val = lc $$sref_val;
	}

	sub info : method
	{
		my $this = shift;

		return "lower cases";
	}

package Filter::strip;

	our @ISA = ( 'Filter' );
	
	sub filter : method
	{
		my $this = shift;

		my $sref_val = shift;
		
		my $what = shift;
		
		$$sref_val =~ s/$what//go;
		
	return $$sref_val;
	}

	sub info : method
	{
		my $this = shift;

		return 'strip';
	}

package Filter::uc;

	our @ISA = ( 'Filter' );
	
	sub filter : method
	{
		my $this = shift;

		my $sref_val = shift;
		
	return $$sref_val = uc $$sref_val;
	}

	sub info : method
	{
		my $this = shift;

		return "upper cases";
	}

package Data::Type::Typed;

	use strict;

	require Tie::Scalar;

	our @ISA = qw(Tie::StdScalar);

	our $DEBUG = 0;

	our $BEHAVIOUR = { exceptions => 1, warnings => 1 };
	
	sub TIESCALAR
	{
		ref( $_[1] ) || die;

		$_[1]->isa( 'IType::UNIVERSAL' ) || die;

		Data::Type::printfln "TIESC '%s'", ref( $_[1] ) if $DEBUG;

	    return bless [ undef, $_[1] ], $_[0];
	}

	sub STORE
	{
		my $this = shift;

		my $value = shift || undef;

		Data::Type::printfln "STORE '%s' into %s typed against '%s'", $value, $this, ref( $this->[1] ) if $DEBUG;

		::try
		{
			Data::Type::verify( $value, $this->[1] );
		}
		catch Type::Exception ::with
		{
			my $e = shift;

			my @back = caller(4);

			warn sprintf "type conflict: '%s' is not %s at %s line %d\n", $value, $this->[1]->info, $back[1], $back[2] if $BEHAVIOUR->{warnings};

			$e->value = $value;
			$e->was_file = $back[1];
			$e->was_line = $back[2];
			
			throw $e if $BEHAVIOUR->{exceptions};
		};

		$this->[0] = $value;
	}

	sub FETCH
	{
		my $this = shift;

		Data::Type::printfln "FETCH $this '%s' ", $this->[0] if $DEBUG;

		return $this->[0];
	}

package Data::Type::Guard;

	use Carp;
	
	Class::Maker::class
	{
		public =>
		{
			array => [qw( allow )],
			
			hash => [qw( tests )],
		},
	};
	
	sub inspect : method
	{
		my $this = shift;
	
		my $object = shift;

		my $decision;

		if( @{ $this->allow } > 0 )
		{			
			my %t;
	
			@t{ $this->allow } = 1;

			unless( exists $t{ ref( $object ) } )
			{
				carp "Guard is selective and only accepts ", join ', ', $this->allow if $Data::Type::DEBUG;
				
				return 0;
			}    			
		}
			
		::try
		{
			Data::Type::overify( { $this->tests }, $object );
			
			$decision = 1;
		}
		catch Type::Exception ::with
		{
			$decision = 0;
		};
	
	return $decision; 
	}

1;

__END__

=head1 NAME

Data::Type - versatile data and value types

=head1 SYNOPSIS

	use Data::Type qw(:all);
	use Error qw(:try);
	
	try
	{
		verify $email		, EMAIL;
		verify $homepage	, URI('http');
		verify $cc			, CREDITCARD( 'MASTERCARD', 'VISA' );
		verify $answer_a	, YESNO;
		verify $gender		, GENDER;
		verify 'one'		, ENUM( qw(one two three) );
		verify [qw(two six)], SET( qw(one two three four five six) ) );
		verify $server_ip4	, IP('v4');
		verify $server_ip6	, IP('v6');

		verify 'A35231AH1'	, CINS;
		verify '14565935'	, ISSN;		
		verify 'DE'			, LANGCODE;		
		verify 'German'		, LANGNAME;
		
		verify '012345678905', UPC();
		verify '5276440065421319', CREDITCARD( 'MASTERCARD' ) );

		verify 'ATGCAAAT'	, BIO::DNA;				
		verify 'AUGGGAAAU'	, BIO::RNA;		

		verify '01001001110110101', BINARY;
		verify '0F 0C 0A', HEX;

		verify '0'			, DEFINED;
		verify '234'		, NUM( 20 );
		verify '1' 			, BOOL( 'true' );
		verify '100'		, INT;
		verify '1.1'		, REAL;

		my $foo = bless( \'123', 'SomeThing' );
			
		verify $foo 		, REF;
		verify $foo			, REF( qw(SomeThing Else) );
		verify [ 'bar' ]	, REF( 'ARRAY' );

		verify ' ' x 20		, VARCHAR( 20 );
		verify '2001-01-01'	, DATE( 'MYSQL' );
		verify '16 Nov 94 22:28:20 PST'	, DATE( 'DATEPARSE' );
		verify '9999-12-31 23:59:59', DATETIME;
		verify '1970-01-01 00:00:00', TIMESTAMP;
		verify '-838:59:59'	, TIME;
		verify '2155'		, YEAR;
		verify '69'			, YEAR(2);
		verify '0' x 20		, TINYTEXT;
		verify '0' x 20		, MEDIUMTEXT;
		verify '0' x 20		, LONGTEXT;
		verify '0' x 20		, TEXT;
		
		verify '80'         , PORT;
		verify 'www.cpan.org', DOMAIN;
	}
	catch Type::Exception with
	{	
		my $e = shift;
		
		printf "Expected '%s' %s at %s line %s\n",
			$e->value, 
			$e->type->info, 
			$e->was_file, 
			$e->was_line;

		foreach my $entry ( testplan( $e->type ) )
		{
			printf "\texpecting it %s %s ", $entry->[1] ? 'is' : 'is NOT', $entry->[0]->info();
		}
	};

		# believe it or not, this really works
		
	foreach ( EMAIL, WORD, CREDITCARD( 'MASTERCARD', 'VISA' ), BIO::DNA, HEX )
	{
		print $_->info;						
		print $_->usage;					
		print $_->export;					# does it have other names
		print $_->param;					# what are my choice i.e. [yes,no]
		print $_->isa( 'IType::Business' ); # is it a Business related type ?
		print $_->VERSION;					# first apperance in Data::Type release
	}
		
		# tied interface (alias 'typ')
		
	try
	{			
		typ ENUM( qw(DNA RNA) ), \( my $a, my $b );

		print "a is typ'ed" if istyp( $a );

		$a = 'DNA';		# $alias only accepts 'DNA' or 'RNA'
		$a = 'RNA';		
		$a = 'xNA';		# throws exception 
		
		untyp( $alias );
	}
	catch Type::Exception ::with
	{
		printf "Expected '%s' %s at %s line %s\n",
			$e->value, 
			$e->type->info, 
			$e->was_file, 
			$e->was_line;
	};
	   
    dverify( $email, EMAIL ) or die $!;

	my $g = Data::Type::Guard->new( 

		allow => [ 'Human', 'Others' ],		# blessed objects of that type
		
		tests =>
		{
			email		=> EMAIL( 1 ),		# mxcheck ON ! see Email::Valid
			firstname	=> WORD,
			social_id	=> [ NUM, VARCHAR( 10 ) ],
			contacts	=> sub { my %args = @_; exists $args{lucy} },				
		}
	);
	
	$g->inspect( $h );

		# compact version
		
	overify { email => EMAIL( 1 ), firstname => WORD }, $object_a, $object_b;
	
	print toc();
	
	print catalog();
	
=head1 DESCRIPTION

This module supports versatile data and value types. Out of the ordinary it supports 
parameterised types (like databases have i.e. VARCHAR(80) ). When you try to feed a 
typed variable against some odd data, this module explains what he would have expected. 


=head1 KEYWORDS

data types, data manipulation, data patterns, form data, user input, tie

=head1 TYPES and FILTERS

perl -e "use Data::Type qw(:all); print catalog()" lists all supported types:

Data::Type 0.01.04 supports 39 types:

  BINARY                   - binary code
  BOOL                     - a true or false value
  CINS            0.01.03  - a CUSIP International Numbering System Number
  BIO::CODON      0.01.03  - a DNA (default) or RNA nucleoside triphosphates triplet
  CREDITCARD               - is one of a set of creditcard type (DINERS, BANKCARD, VISA, ..
  DATE            0.01.01  - a date (mysql or Date::Parse conform)
  DATETIME                 - a date and time combination
  DEFINED         0.01.04  - a defined (not undef) value
  DK::YESNO                - a simple answer (ja, nein)
  BIO::DNA        0.01.03  - a dna sequence
  DOMAIN          0.01.04  - a network domain name
  EMAIL                    - an email address
  ENUM                     - a member of an enumeration
  GENDER                   - a gender male, female
  HEX                      - hexadecimal code
  INT                      - an integer
  IP              0.01.04  - an IP (V4, V6, MAC) network address
  ISSN            0.01.03  - an International Standard Serial Number
  LANGCODE        0.01.03  - a Locale::Language language code
  LANGNAME        0.01.03  - a language name
  LONGTEXT                 - text with a max length of 4294967295 (2^32 - 1) characters (..
  MEDIUMTEXT               - text with a max length of 16777215 (2^24 - 1) characters (al..
  NUM                      - a number
  PORT            0.01.04  - a network port number
  QUOTED                   - a quoted string
  REAL                     - a real
  REF                      - a reference to a variable
  BIO::RNA        0.01.03  - a rna sequence
  SET                      - a set (can have a maximum of 64 members (mysql))
  TEXT                     - blob with a max length of 65535 (2^16 - 1) characters (alias..
  TIME                     - a time (mysql)
  TIMESTAMP                - a timestamp (mysql)
  TINYTEXT                 - text with a max length of 255 (2^8 - 1) characters (alias my..
  UPC             0.01.03  - standard (type-A) Universal Product Code
  URI                      - an http uri
  VARCHAR                  - a string with limited length of choice (default 60)
  WORD                     - a word (without spaces)
  YEAR                     - a year in 2- or 4-digit format
  YESNO                    - a simple answer (yes, no)

And 4 filters:

  CHOMP              - chomps
  LC                 - lower cases
  STRIP              - strip
  UC                 - upper cases


=head1 TYPES BY GROUP

 Logic
  BIO::CODON, BIO::DNA, BIO::RNA, DEFINED, DOMAIN, EMAIL, IP, LANGCODE, LANGNAME, PORT, REF, URI

 Database
   Logic
      ENUM, SET

   Time or Date related
      DATE, DATETIME, TIME, TIMESTAMP, YEAR

   String
      LONGTEXT, MEDIUMTEXT, TEXT, TINYTEXT

 Business
  CINS, CREDITCARD, ISSN, UPC

 W3C
   String
      BINARY, HEX

 Numeric
  BOOL, INT, NUM, REAL

 String
  DK::YESNO, GENDER, QUOTED, VARCHAR, WORD, YESNO


=head1 INTERFACE

=head2 FUNCTIONS

=head3 verify( $s, $type, [ .. ] )

Verifies a 'value' against (one ore more) types or facets. 

=head3 dverify( $s, EMAIL ) or die $!

Dies instead of throwing exceptions.

=head3 overify( { member => TYPE, .. }, $object, [ .. ] )

Verifys members of objects against multiple 'types' or CODEREFS.

=head2 Class Data::Type::Guard

This is something like a Bouncer. He inspect 'object' members for a specific type. The class has two attributes and one
member.
	
=head3 allow => $ref_array

If empty isn't selective for special references (  HASH, ARRAY, "CUSTOM", .. ). If is set then "inspect" will fail if the object
is not a reference of the listed type.

=head3 tests => $ref_hash

Keys are the members names (anything that can be called via the $o->member syntax) and the type(s) as value. When a member should
match multple types, they should be contained in an array reference ( i.e. 'fon' => [ qw(NUM TELEPHONE) ] ).

=head3 inspect( $blessed )

Accepts a blessed reference as a parameter. It returns 0 if a guard test or type constrain will fail, otherwise 1.  
In future it should return a more appropriate report what failed and what not.

=head2 TYPE BINDING

Tie was employed to create something strict on variables. When a variable is typ'ed, everytime it is accessed a
type-check (verify) is applied.

=head3 typ EMAIL( 1 ), \( my $typed_var, my $typed_etc, .. );

EMAIL is a placeholder for any type of this library. Once an invalid value was assigned to a var an exception
gets thrown, so place your code in a try+catch block to handle that correctly.

	$typed_var = 'faked&fake.de'; # throws exception

=head3 istyp( $typed_var )

Because tie'd variables are obscuring themself, istyp() helps here. It reveals $typed_var 's type.

	if( $what = istyp( $a ) )
	{
		print "a is typed to $what";
	}

=head3 untyp
		
Takes the typ constrains from a variable (like untie).

	untyp( $alias );

=head1 Exceptions

Exceptions are implemented via the 'Error' module. Type::Exception is the base class inheriting from 'Error'
and beeing the anchestor of any exception used within this module.

=head2 Failure::Type

This exception has following members:

=head3 was_file	

The filename where the exception was thrown.

=head3 was_line	

The line number.

=head3 type

The type 'object' used for verification.

=head3 value

Reference to the data subjected to verification.

=head2 Failure::Facet

This exception is thrown in the verification process if a facet (which is a subelement
of the verification process) fails. It is for no use, unless you are planning to create custom types.

=head1 Retrieving Type Information

=head2 catalog()

returns a static string containing a listing of all know types (and a short information). This
may be used to get an overview via:

	perl -MData::Type -e "print Data::Type::catalog()"

=head2 toc()

Returns a static string containing a grouped listing of all know types.

	perl -MData::Type -e "print Data::Type::toc()"

=head2 testplan( $type )

Returns the entry-objects how the type is verified. This may be used to create a textual description 
how the type verification process is driven. This could give clues to a web user, when he should get
an error report, how his form submission would accepted.
 
=head3 depends()

Type:: package supports a method C<sub depends {qw(CPAN::aModule)}>. It helps building a dependency tree
classified for types. This function an an array reference, like this example:

	[
		{
		'module' => 'Net::IPv6Addr',
		'version' => '0.2',
		'types' => [
						{
						'name' => 'IP'
						}
					]
		},
		{
		'module' => 'Locale::Language',
		'version' => '2.02',
		'types' => [
						{
						'name' => 'LANGCODE'
						},
						{
						'name' => 'LANGNAME'
						}
					],
		},
	];
	   
Note: This can be easily stuffed into HTML::Template's loops or in future helps implementing clever 
runtime module loading for only types really used.

=head2 EXPORT

all = (typ untyp istyp verify catalog testplan toc), map { uc } @types

None by default.

=head2 PREREQUISITES

=head3 Standard
   Class::Maker (0.05.10), 
   Error (0.15), 
   IO::Extended (0.05), 
   Tie::ListKeyedHash (0.41), 
   Iter (0)
   
=head3 And for types

   Business::ISSN 0.90 by ISSN
   Net::IPv6Addr 0.2 by IP
   Locale::Language 2.02 by LANGCODE, LANGNAME
   Business::CINS 1.13 by CINS
   Email::Valid 0.14 by EMAIL
   Date::Parse 2.23 by DATE
   Business::CreditCard 0.27 by CREDITCARD
   Regexp::Common 1.20 by INT, IP, QUOTED, REAL, URI
   Business::UPC 0.02 by UPC
   

=head2 LAST CHANGES 0.01.04

  * added dverify( ) which is die'ing instead of throwing exceptions to the people:
  
        dverify( $email, EMAIL ) or die $!;
	
  * renamed 'choice' method for Type:: types to 'param'.
  
  * Some minor changes
    - Type::* package now supports new method C< sub depends {qw(CPAN::aModule)} > for retrieval of
	a dependency tree, which type made Data::Type require what.
	- added Data::Verify::depends() which returns a dependency list for types requiring other modules.
	
  * New (or updated) types:

  DEFINED         0.01.04  - a defined (not undef) value
  DOMAIN          0.01.04  - a network domain name
  IP              0.01.04  - an IP (V4, V6, MAC) network address
  PORT            0.01.04  - a network port number
   

=head1 AUTHOR

Murat Ünalan, <murat.uenalan@cpan.org>

=head1 SEE ALSO

http://www.w3.org/TR/2001/REC-xmlschema-2-20010502/

Data::Types, String::Checker, Regexp::Common, Data::FormValidator, HTML::FormValidator, CGI::FormMagick::Validator, CGI::Validate,
Email::Valid::Loose, Embperl::Form::Validate, Attribute::Types, String::Pattern, Class::Tangram

