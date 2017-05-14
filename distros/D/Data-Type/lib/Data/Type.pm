
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
# $Revision: 1.39 $
# $Header: /cygdrive/y/cvs/perl/modules/Data/Type/Type.pm.tmpl,v 1.39 2003/04/12 12:48:38 Murat Exp $

package Data::Type;

BEGIN
{
	use Regexp::Box;

	our $rebox = Regexp::Box->new( name => 'Data::Type custom datatypes' );
}

	our $VERSION = "0.02.02";

	our $DEBUG = 0;

	require 5.005_62; use strict; use warnings;

	use Carp;

	use Class::Maker;

	use Class::Maker::Exception qw(:try);
	
	use Locale::Language;	# required by langcode langname
	
	use IO::Extended qw(:all);
	
	use Data::Iter qw(:all);
	
	use Exporter;

	our @ISA = qw( Exporter );

	use subs qw(try with);
		
	our %EXPORT_TAGS = 
        ( 
	  'all' => [qw(is isnt valid dvalid catalog summary try with)],

	  'valid' => [qw(is isnt valid dvalid)],
 
	  # same as :valid

	  'is' => [qw(is isnt valid dvalid)],

	  'try' => [qw(try with)],
	);
	
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
	
	our @EXPORT = ();

         # modules loaded registry (used by _load_dependency method)

        our $_loaded = {};

        our @_requested;

	our $_master_prefix = '';	# prefix all datatypes with that string

	our $_callers_pkg = '';

	our $_used_import_opts = {};

	use Data::Type::Collection;

        sub import
        {
		# Fetch the callers pkg

	    $_callers_pkg = scalar caller;

	    warnfln "caller is %S", $_callers_pkg if $Data::Type::DEBUG;

		# Reset master_prefix each time this module is used
                # So there is no confusion if its double used and the old
		# master_prefix is active

            $Data::Type::_master_prefix = '';

	    @_requested = ();

	    push @_requested, 'Std';
	    	    
	    my @copy;

	    foreach my $id (@_) 
	    {      
		if( $id =~ /^\+/ )
		{
			# $id is an alias to @_ entry and therefore read-only

		    warnfln "Import Collection statement for: %S", $id if $Data::Type::DEBUG;

		    my $cp = $id;

		    $cp =~ s/^\+//;
		    
		    if( $cp eq 'ALL' )		    
		    {
			warnfln "Collections %S for import registered", join( ', ', keys %$Data::Type::Collection::_ids ) if $Data::Type::DEBUG;

			push @_requested, keys %$Data::Type::Collection::_ids;
		    }
		    else
		    {
			push @_requested, $cp;
		    }
		}	      
		elsif( $id =~ /^<(.+)>$/ )
		{
		  $_used_import_opts->{MASTER_PREFIX} = $Data::Type::_master_prefix = $1;
		}
		elsif( $id =~ /^_$/ )
		{
		  warnfln "Export option: UNDERSCORE activated." if $Data::Type::DEBUG;

		  $Data::Type::_reformat_name = sub { $_[0] =~ s/::/_/g; };

		  $_used_import_opts->{UNDERSCORE} = 1;
		}
		elsif( $id =~ /^debug\+\+$/i )
		{
		  $_used_import_opts->{DEBUG} = $Data::Type::DEBUG++;
		}
		elsif( $id =~ /^debug\-\-$/i )
		{
		  $_used_import_opts->{DEBUG} = $Data::Type::DEBUG--;
		}
		else
		{
		    push @copy, $id;
		}
	    }
	    
	    if( defined $_used_import_opts->{UNDERSCORE} )
	    {
		unless( defined $_used_import_opts->{MASTER_PREFIX} )
		{
		    $_used_import_opts->{MASTER_PREFIX} = $Data::Type::_master_prefix = $_callers_pkg.'::';
		}
	    }		
	    
	    my %requested;
	    
	    $requested{$_} = '' for @_requested;
	    
	    @_requested = grep { !/^STD$/i } keys %requested;
	    
	    warn sprintf "Following collection where requested to export: %s", join( ', ', @Data::Type::_requested) if $Data::Type::DEBUG;         

	    foreach ( 'STD', @_requested )
	    {
		my $pm = $Data::Type::Collection::_arg_to_pkg->{$_};

		$pm = $_ unless defined $pm;

		use Data::Dump qw(pp);

		die "pm var empty for $_ out of args".Data::Dump::pp( 'STD', @_requested ) unless defined $pm;

		eval "use Data::Type::Collection::$pm;"; 

		if( $@ )
		{
		    use Carp qw(cluck);

		    use Data::Dump qw(dump);

		    cluck "eval use Data::Type::Collection::$pm failed. Did you have a spelling mistake ? Requested where ".dump( @_requested, \%requested );


		    die $@;
		}
		
		codegen( $_.'::' );
	    }
	    
	    @_ = @copy;
	    
	    __PACKAGE__->export_to_level(1, @_);
	}

package Data::Type::Entry;

	Class::Maker::class
    	{
	    public => 
	    {
		bool => [qw( expected )],
		
		ref  => [qw( object )],
	    },
	};

package Data::Type::L18N;

        use strict;

	use Locale::Maketext;

	our @ISA = qw( Locale::Maketext );

package Data::Type::L18N::de;

	our @ISA = qw(Data::Type::L18N);

	use strict;

	use vars qw(%Lexicon);

	our %Lexicon =
     	(
		__current_locale__ => 'deutsch',

		"Can't open file [_1]: [_2]\n" => "Problem beim öffnen der datei [_1]. Grund: [_2]\n",

		"You won!" => "Du hast gewonnen!",
	);

package Data::Type::L18N::en;

	our @ISA = qw(Data::Type::L18N);

	use strict;

	use vars qw(%Lexicon);

	our %Lexicon =
	(
		__current_locale__ => 'english',

		"Can't open file [_1]: [_2]\n" => "Can't open file [_1]: [_2]\n",

		"You won!" => "You won!",
	 );

package Data::Type::Proxy;

	use vars qw($AUTOLOAD);

	sub AUTOLOAD
	{
		( my $func = $AUTOLOAD ) =~ s/.*:://;

	return bless [ @_ ], Data::Type::_add_package_to_name( lc $func );
	}

  #
  # The universal "Data::Type::Object Interface"
  #

package Data::Type::Object::Interface;

use Attribute::Util;

sub desc : method
{
    warn "abstract method called" if $Data::Type::DEBUG;
    
    return 'Universal';
}

# static string

sub info : Abstract method;

# shell commando like usage

sub usage { '' } #: Abstract method;

sub _filters : method { () }

# holds the logic of type validation. Should use Data::Type::ok()
# to dispatch public and private facets

sub test
{
  my $this = shift;

  $this->_load_dependency;	

  Data::Type->filter( $this->_filters ) if scalar $this->_filters;
		
return $this->_test( @_ );
}

# return scalar/array/hash of alternativ choices when an inputfield
# is generated for this type

sub choice : Abstract method;

# returns a data structure used for the configuration/parameterization of
# the datatype

sub param : Abstract method;

# If some default value for C<param> exists, they should be returned
# by this function

sub default : Abstract method;

# returns an array of required modules for this type
# [note] used to build a dependency tree

sub basic_depends : method { qw() }

sub _depends { () }

sub depends : method 
{ 
	my $this = shift;
	
	my @d = ();

	@d = $this->_depends;
	
return ( @d, $this->basic_depends );  
}

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

# No idea ?

sub to_text : Abstract method;

# api for casting of types
# Usage: my $a_castedto_b = TYPE_A->cast( TYPE_B );
# [note] Ideally use C<Class::Multimethods> for dispatching

sub cast : Abstract method;

# return static text of some sort of "manpage" for this type

sub doc : Abstract method; # A descriptive information about the interface should be placed here.

# returns a scalar. This should be implemented by an Data::Type::Collection::*::Interface class
# which is then used when generating the final exportname with C<exported>

sub prefix : method
{
	Carp::croak "abstract method prefix called";
}


# return array of alias's for that type 

sub export : method
{	    
    my $this = shift;
    
    $this ||= ref($this);
    
    my $name = Data::Type::_cut_package_from_name( $this );

    my $pre = $this->pkg_prefix;

    $name =~ s/^${pre}//gi;

    return ( $name );
}

# return array of alias's for that type, including a prefix
# if this type is part of a collection

sub exported : method
{
    my $this = shift;
    
    my @result;
    
    foreach( $this->export )	
    { 
	my $n = $this->prefix().$_;
	
	$Data::Type::_reformat_name->( $n ) if defined $Data::Type::_reformat_name;
	
	push @result, Data::Type::_gen_name( $n );
    }
    
return @result;
}	

sub summary
{
    my $this = shift;

    if( wantarray )
    {
	return Data::Type::summary( scalar @_ ? @_ : '' , $this );
    }

    my $sum;

    foreach my $entry ( Data::Type::summary( scalar @_ ? @_ : '' , $this ) )
    {
	$sum .= Data::Type::sprintfln "expecting it %s %s ", $entry->expected ? 'is' : 'is NOT', Data::Type::strlimit( $entry->object->info() );
    }

return $sum;
}

use String::ExpandEscapes;

sub pod : method
{ 
  my $this = shift;

  my $href = shift;

  my $escapes = {
		 e => join( ', ', $this->exported ),
		 d => $this->desc,
		 v => $this->VERSION || 'undefined',
		 u => $this->usage,
		 m => join(', ', map { "L<$_>" } $this->_depends),
		};
      
  my @fields;

  push @fields, '=head2 %e (since %v)', '%d';

  if( $this->usage || $this->_depends )
  {
#      $escapes->{i} = $this->info and push @fields, '%i' if $this->info;

#      $escapes->{s} = $this->summary and push @fields, '=item SUMMARY', '%s' if $this->summary;

      $escapes->{f} = join '; ', ( map { my $f = shift @$_; scalar @$_ ? "L<$f|Data::Type::Filter/$f> ".join( ', ', @$_ ) : () } $this->_filters ) and push @fields, '=head3 Filters', '%f' if $this->_filters;

      push @fields, '=head3 Usage', '%u' if $escapes->{u};
      
      push @fields, '=head3 Depends', '%m' if $escapes->{m};      
  }

  my $fmt = join ( "\n\n", @fields )."\n\n";

  my ($result, $error) = String::ExpandEscapes::expand( $fmt, $escapes );

  Carp::croak "Illegal escape sequence $error\n" if $error;

return $result;
}

package Data::Type::Context;

	Class::Maker::class
	{
    		public =>
    		{
    			int => [qw( failed passed )],
     
     			scalar => [qw( value )],
     
     			array => [qw( types )],
    		},
	};

package Data::Type;

		# See head of file for $VERSION variable (moved because of bug in VERSION_FROM of Makefile.pl)

		# This value is important. It gets reset to undef in valid() before the test starts. During test
		# it hold the $value of the data to tested against.

	our $value;
	
	our @_history;
	
	our %_alias;       # holds alias names for type like $_alias{BIO::CODON} = 'codon';
	
	no strict 'refs';

        our @_locale_handles = ( 'en' );

	our $_lh = Data::Type::L18N->get_handle( @_locale_handles ) || die "What language?";

	sub lh { $_lh }

	use Data::Type::Exception;

        use Data::Type::Filter;

        use Data::Type::Facet;

		# generate Type subs
	
	sub current_locale
	{
    		my $this = shift;

    	return $_lh->maketext('__current_locale__');
	}

        sub set_locale : method
        {
	    my $this = shift;

            $Data::Type::_lh = Data::Type::L18N->get_handle( @_ ) || die "Locale not implented or found";
        }      

        sub esc ($) { my $cpy = $_[0] || '' ; $cpy =~ s/\n/\\n/; "'".$cpy."'" }
	
	sub strlimit
	{
		my $limit = $_[1] || 60;
	
	return length( $_[0] ) > $limit ? join('', (split(//, $_[0]))[0..$limit-1]).'..' : $_[0];
	}

	sub filter : method
	{
		my $this = shift;
		
		foreach ( @_ ) 
		{
		    my ( $name, @args ) = @{$_};

		    print " " x 2;
		    
		    my $before = $Data::Type::value;
		    
		    "Data::Type::Filter::${name}"->filter( @args );

		    print " " x 2;

		    printf '%-20s %20s(%s) %30s => %-30s', 'FILTER', $name, join(',',@args), esc( $before), esc( $Data::Type::value) if $Data::Type::DEBUG;
		    
		    print "\n";
		}
	}

			# Generate Type alias subs
			#
			# - Generate subs like 'VARCHAR' into this package
			# - These are then Exported
			#
			# Note that codegen is called above

	sub _gen_name
	{
		my $what = shift;

	return $Data::Type::_master_prefix.uc( $what );
	}

	sub _add_package_to_name
	{
	    my $name = shift || die "_add_package_to_name needs at least one parameter";

	return 'Data::Type::Object::'.$name;
	}

	sub _cut_package_from_name
	{
	    my $p = shift || die "_cut_package_from_name needs at least one parameter";

        return ( $p =~ /^Data::Type::Object::([^:]+)/ )[0] || die "'$p' not matchable by _cut_package_from_name";
	}

	sub _revert_alias
	{
	
	return exists $_alias{ shift } ? $_alias{ shift } : undef;
	}

	sub _translate
	{
		my $name = shift;

	return join ', ', $name->exported;
	}

	sub expect
	{
		my $recording = shift;

		my $expected = shift;

		foreach my $that ( @_ )
		{
		    $that = bless [ $that ], 'Data::Type::Facet::__anon' if ref($that) eq 'CODE';

		    if ( $recording ) 
		    {
			push @Data::Type::_history, Data::Type::Entry->new( object => $that, expected => $expected );
		    }
		    else
		    {
			Data::Type::try
			{
				$that->test;
			}
			catch Error Data::Type::with
			{
				throw Data::Type::Exception( value => $Data::Type::value, type => $that, catched => \@_ ) if $expected;
			};
		    }
		}
	}

	our $record = 0;

	sub ok { expect( $record, @_ ) }

	sub assert { println $_[0] ? '..ok' : '..nok'}

		# Tests Types

	sub valid
	{
	    $Data::Type::value = ( @_ > 1 ) ? shift : $_;
	    
	    my $type = shift;

	    printf "%-20s %30s %-60s\n", 'VALID', esc( $Data::Type::value ), $type if $Data::Type::DEBUG;
	    
	    die "usage: valid( VALUE, TYPE )" if @_;

	    printfln "\n\nTesting %s given '%s' (%s)", ( $type->exported )[0], $value, strlimit( $type->info ) if $Data::Type::DEBUG;

	    $type->test;
	}

		# Wrapper for dieing instead of throwing exceptions

	our @err;

	sub dvalid
	{
	    my @args = @_;
	    
	    @err = ();
	
	    Data::Type::try
	    {
	      $Data::Type::value = ( @args > 1 ) ? shift @args : $_;

	      my $type = shift @args;

	      printf "%-20s %30s %-60s\n", 'DVALID', $Data::Type::value, $type if $Data::Type::DEBUG;

	      die "usage: dvalid( $Data::Type::value, $type )" if @args;

	      printfln "\n\nTesting %s given '%s' (%s)", ( $type->exported )[0], $Data::Type::value, strlimit( $type->info ) if $Data::Type::DEBUG;

	      $type->test;
	    }
	    catch Error Data::Type::with
	    {
               @err = @_;
            };

	return @err ? 0 : 1;
	}

	sub is { &dvalid }

	sub isnt { not &is }

	sub summary
	{
		@Data::Type::_history = ();

		$Data::Type::record = 1;

		$Data::Type::value = shift;

		#print Data::Dumper->Dump( [ \@_ ] );
		
		$_->test for @_;
		    
		$Data::Type::record = 0;

		return @Data::Type::_history;
	}

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
					if( $symbol =~ /(.+)::$/ && $symbol ne 'main::' )
					{
						push @found, "${path}$1";
					}
				}
			}
		}

	return @found;
	}
                                                 
	sub type_list_as_packages { map { die if $_ =~ /Interface/; $_ } grep { $_ ne 'Data::Type::Object::Interface' and $_->isa( 'Data::Type::Object::Interface' ) } _search_pkg( 'Data::Type::Object::' ) }

	sub type_list { map { _cut_package_from_name($_) } type_list_as_packages() }

	sub filter_list_as_packages { grep { $_ ne 'Data::Type::Filter::Interface' and $_->isa( 'Data::Type::Filter::Interface' ) } _search_pkg( 'Data::Type::Filter::' ) }

	sub filter_list { filter_list_as_packages() }

	sub facet_list_as_packages { grep { $_ ne 'Data::Type::Facet::Interface' and $_->isa( 'Data::Type::Facet::Interface' ) } _search_pkg( 'Data::Type::Facet::' ) }

	sub facet_list { facet_list_as_packages() }

	sub l18n_list { map { /::([^:]+)$/; uc $1 } _search_pkg( 'Data::Type::L18N::' ) }

	sub _show_list
	{
		my $hash = shift;

		my $ind = shift || 2;

		my $result;

		foreach my $key (keys %$hash)
		{
			my $val = $hash->{ $key };

				# headlines

			unless( ref( $key ) )
			{
				$result .= sprintf qq|%s"%s"\n|, " " x $ind, $key;
			}
			else
			{
				$result .= sprintf qq|%s"%s"\n|, " " x $ind, $_ for @$key;
			}

				# contents

			if( ref( $val ) eq 'ARRAY' )
			{
				$result .= sprintf "\n%s  %s\n\n", " " x $ind, join( ', ', sort { $a cmp $b } @$val );
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
		return '<empty toc>';

		my $result;

		use Tie::ListKeyedHash;

		tie my %tied_hash, 'Tie::ListKeyedHash';

		foreach my $pkg_name ( type_list_as_packages() )
		{
		  warn "$pkg_name will be reflected" if $Data::Type::DEBUG;

		  my @isa = _unique_ordered @{ Class::Maker::Reflection::inheritance_isa( @{ $pkg_name.'::ISA' } ) };

		  # this is brute and could become a trouble origin

		  @isa = grep { $_ ne 'Data::Type::Object::Interface' and $_->isa( 'Data::Type::Object::Interface' ) } @isa;

		  Carp::croak "$pkg_name has invalid isa tree with @isa" unless @isa;

		  my $special_key = [ _unique_ordered map { $_->can( 'desc' ) ?  $_->desc : () } @isa ];
		  
		  print Data::Dumper->Dump( [ \@isa, $special_key ] ); # if $Data::Type::DEBUG;

		  $tied_hash{ $special_key } = [] unless defined $tied_hash{ $special_key };

		  push @{ $tied_hash{ $special_key } }, sprintf( '%s', _translate( $pkg_name ) );
		}

		$result .= _show_list \%tied_hash;

	return $result;
	}

		# look at sub _export below. Normally it is used to use ie. DB_VARCHAR instead of DB::VARCHAR (namespace pollution!).

	our $_reformat_name = undef; 

	sub _export
	{
		my $what = shift;

		foreach my $where ( @_ )
		{
			my $c = sprintf "sub %s { Data::Type::Proxy::%s( \@_ ); };", $where, $what;

			println "_export: $c" if $Data::Type::DEBUG;

			eval $c;

			die $@ if $@;
		}
	}

	sub codegen
	{
	    my $prefix = shift;

	    warn "codegen for prefix $prefix" if $Data::Type::DEBUG;

		my @aliases;

		foreach my $type ( Data::Type::type_list() )
		{
		  printfln "generating code for %s", $type if $Data::Type::DEBUG;
		  
		  my $p = _add_package_to_name($type)->prefix;

		  warnfln "codegen if $p eq $prefix" if $Data::Type::DEBUG > 1;

		  printfln "export if $p eq $prefix." if $Data::Type::DEBUG;

		  if( $p eq $prefix )
		  {
			printfln "exporting %S", $type if $Data::Type::DEBUG;

			_export( $type, _add_package_to_name($type)->exported );

			my @n = _add_package_to_name($type)->exported;

			push @aliases, @n;

			$_alias{$_} = $type for @n;
		  }
		}

	        if( @aliases )
		{
		    warnfln sprintf "eval: use subs qw(%s);", join ' ', @aliases if $Data::Type::DEBUG;

		    eval sprintf "use subs qw(%s);", join ' ', @aliases;

		    warn $@ if $@;
		}
	}

1;

__END__

=head1 NAME

Data::Type - robust and extensible data- and valuetype system

=head1 SYNOPSIS

  use Data::Type qw(:is +ALL);

  is STD::EMAIL or warn;

  warn if isnt STD::CREDITCARD( 'MASTERCARD', 'VISA' );

  try
  {
    valid( '9999-12-31 23:59:59', DB::DATETIME );
  }
  catch Data::Type::Exception with
  {
    print $e->to_string foreach @_;
  };


=head1 DESCRIPTION



A lot of CPAN modules have a common purpose: reporting if data has some "characteristics". L<Email::Valid> is an illustrous example: reporting if a string has characteristics of an email address. The C<address()> method reports this via returning C<'yes'> or C<'no'>. Another module, another behaviour: C<Business::ISSN> tests for the characteristics of an C<International Standard Serial Number> and does this via an C<is_valid> method returning C<true> or C<false>. And so on and so on.
L<Data::Type> was created with modularity, introspectability and usability in mind.

The resulting key concepts are:

=over 3

=item * 
a unified interface to type related CPAN modules (via L<Data::Type>)

=item * 
generic, fun to extend and simple API (see L<Data::Type::Docs::RFC>)

=item * 
paremeterized types ( eg. C<STD::VARCHAR(80)> )

=item * 
alternativly exception-based or functional problem reports (L<valid()> contra L<is()>)

=item * 
localization via L<Locale::Maketext> (L<Data::Type/Localization>)

=item *
syntactic sugar ( C<die unless is BIO::DNA> )

=item *
generic access through L<DBI> to catalog of data types and more (see L<Data::Type::Query>)

=back

This module relies, as much as its plausible, on CPAN modules doing the job in the backend. For instance L<Regexp::Common> is doing a 
lot of the regular expression testing. L<Email::Valid> takes care of the C<EMAIL> type. L<Data::Parse> can be exploited
for doing the backwork for the C<DATE> type.


=head1 DOCUMENTATION

You find a gentle introduction at L<Data::Type::Docs>. It also navigates you through the rest of the documentation. Advanced users should keep on reading here.

=head1 SUPPORTED TYPES


All types are grouped and though belong to a B<collection>. The collection is identified by a short id. All members are living in a namespace that is prefixed with it (uppercased).

=over 3

=item L<Standard Collection ('STD')|Data::Type::Collection::Std>

This is a heterogenous collection of datatypes which is loaded by default. It contains various issues from CPAN modules (i.e. business, creditcard, email, markup, regexps and etc.) and some everyday things. See L<Data::Type::Collection::Std>.

=item L<W3C/XML-Schema Collection ('W3C')|Data::Type::Collection::W3C>

A nearly 1-to-1 use of L<XML::Schema> datatypes. It is nearly complete and works off the shelf. Please visit the XMLSchema L<http://www.w3.org/TR/xmlschema-2/> homepage for sophisticated documentation. See L<Data::Type::Collection::W3C>.

=item L<Database Collection ('DB')|Data::Type::Collection::DB>

Common database table types (VARCHAR, TINYTEXT, TIMESTAMP, etc.). See L<Data::Type::Collection::DB>.

=item L<Biological Collection ('BIO')|Data::Type::Collection::Bio>

Everything that is related to biological matters (DNA, RNA, etc.). See L<Data::Type::Collection::Bio>.

=item L<Chemistry Collection ('CHEM')|Data::Type::Collection::Chem>

Everything that is related to chemical matters (Atoms, etc.). See L<Data::Type::Collection::Chem>.

=item L<Perl5 Collection ('PERL')|Data::Type::Collection::Perl>

Reserved and undecided. See L<Data::Type::Collection::Perl>.

=item L<Perl6 Apocalypse Collection ('PERL6')|Data::Type::Collection::Perl6>

Placeholder for the Apocalypse and Synopsis 6 suggested datatypes for perl6. See L<Data::Type::Collection::Perl6>.

=back

B<[Note]> L<C<ALL>|Data::Type/EXPORT> is a an alias for all available collections at once.



[NOTE]
Please consider the same constrains as for CPAN namespaces when using/suggesting a new ID. A short discussion on the L<http://sf.net/projects/datatype> mailinglist is rewarded with gratefullness and respect.

=head1 API

=head2 FUNCTIONS

=head3 valid( $value, @types )

This function throws a L<Data::Type::Exception> exception on failure.

Verifies a 'value' against (one ore more) types or facets.

  try
  {
    valid( 'muenalan<haaar..harr>cpan.org', STD::EMAIL );
  }
  catch Data::Type::Exception with
  {
    dump( $e ) foreach @_;
  };

=head3 is( $type )

  $scalar = is( $value, $type );
  $scalar = is( $type );            # $_ is used as $value

Returns true or false instead of throwing exceptions. This is for the exception haters. For reporting, the exceptions are stored in C<$Data::Type::err> aref.

  is( 'muenalan<haaar..harr>cpan.org', STD::EMAIL ) or die dump($Data::Type::err);

[Note] C<dump()> is part of L<Data::Dump>. You can use any dumping routine or format a string with printf, of course.

If first argument is a C<$dt> it uses C<$_> instead of C<$value>. This is for syntactic sugar like:

  foreach( @nucleotide_samples )
  {
    email_to( $SETI ) unless is BIO::DNA;      # Sends "Non terrestric genome found. Suspected sequence '$_'.
  }

[Note] Dont take that example to serious. It also could have been simple RNA. Better would have been C<unless is (BIO::DNA, BIO::RNA)>.

=head3 isnt( $type )

  $scalar = isnt( $value, $type );
  $scalar = isnt( $type );          # $_ is used as $value

A negation of L<is( $type )>, or better an idiom for "not is". These are all semantical identical constructs:

   die if isnt STD::EMAIL;

   die if not is STD::EMAIL;

   die unless is STD::EMAIL;

[Note] C<die if is not STD::EMAIL> would be wrong (even if it is the most natural form). STD::EMAIL is not a package, but the FUNCTION STD::EMAIL() function. So a less ambigous form would be 

 die unless is STD::EMAIL();

because it cautions one not to confuse package vs. function names.

=head3 summary( $value, @types )

  $scalar = summary( $value, @types );
  @entries = summary( $value, @types );    # list context

In scalar context returns the textual representation of the facet set. Gives you a clou how the type verification process is driven. You can use that to prompt the web user to correct invalid form fields.

 print summary( $cc , STD::CREDITCARD( 'VISA' ) );

[Note] A real C<$dt-E<gt>test> is employed to collect the required information. Therefore the C<$value> arguement is required, because it dictates the executed code.

In list context C<summary> returns an array of L<Data::Type::Entry> objects.

 print $_->expected for summary( $cc , STD::CREDITCARD( 'VISA' ) );

=head2 CLASS METHODS

The method interface is thoroughly described in L<Data::Type::Docs::RFC>.

=head3 C<Data::Type-E<gt>set_locale( 'id' )>

If there is an implemented locale package under B<Data::Type::L18N::<id>>, then you can switch to that language with this method. Only text that may be promted to an B<end user> are seriously exposed to localization. Developers must live with B<english>.

[Note] Visit the L</"LOCALIZATION"> section below for extensive information.

=head1 LOCALIZATION

All localization is done via L<Locale::Maketext>. The package B<Data::Type::L18N> is the base class, while B<Data::Type::L18N::<id>> is a concrete implementation.

=head2 LOCALES

=head3 C<$Data::Type::L18N::de>

German. Not very complete.

=head3 C<$Data::Type::L18N::eng>

Complete English dictionary.

And to set to your favorite locale during runtime use the C<set_locale> method of B<Data::Type> (Of course the locale must be implemented).

  use Data::Type qw(:all +DB);

    Data::Type->set_locale( 'de' );  # set to german texts

    ...

Visit the L<Data::Type::Docs::Howto/LOCALIZATION> section for more on adding your own language.

[Note] Localization is only used for texts which somehow will be prompted to the user vis the C<summary()> functions or an exception. This should help developing, for example, web applications with B<Data::Type> and you simply forward problems to the user in the correct language.

=head1 EXPORT

No Functions, but the L<STD collection|Data::Type::Collection::Std> is imported per default.

=head2 FUNCTIONS

C<is>, C<isnt>, C<valid>, C<dvalid>, C<catalog>, C<toc>, C<summary>, C<try> and C<with>.

Exporter sets are:

B<':all'>     
  [qw(is isnt valid dvalid catalog toc summary try with)]

B<':valid'> or B<':is'>
  [qw(is isnt valid dvalid)]

B<':try'>     
  [qw(try with)]

=head2 DATATYPES

You can control the datatypes to be exported with following parameter.

+B<E<lt>uppercased collection idE<gt>> (i.e. B<BIO>, B<DB>, ... )

The B<STD> is loaded everytime (And you cannot unload it currently). Currently following
collections are available B<DB>, B<BIO>, B<PERL>, B<PERL6> (see above). The special collection B<ALL> is a synonym for all available collections.

Example:

 use Data::Type qw(:all +BIO);	# ..export the BIO collection

 use Data::Type qw(:all +DB);	# ..the DB collection

 use Data::Type qw(:all +ALL);	# ..and all available collections

[Note] L<Data::Type> pollutes namespaces en mass, but mitigates this via subjecting only to UPPERCASED namespaces. These are generally reserved and therefore B<hopefully> not often used. If one has conflicts with legacy code use L<export options|/OPTIONS> below.

=head2 OPTIONS

=head3 MASTER PREFIX

With this option you change the default datatypes alias's. If you use this option all alias's are prefixed with that string. The option is identified by a starting C<"E<lt>"> and ending C<"E<gt>">. One should care not to produce invalid package/function name constructs (spaces etc.). So if you want stop namespace pollution and want that all datatypes are send to a single namespace (eg. C<E<lt>"any::"E<gt>>) invoke L<Data::Type> like this:

  use Data::Type qw(:all <dt::> +BIO +DB);

  die unless is dt::STD::EMAIL;

so all later code accessing datatypes should use this prefix. It doesnt need to be a namespace, and C<E<lt>"__"E<gt>> would be absolutely valid (because the alias's are created via a string fed to L<perlfunc/eval>. So thats valid:

  use Data::Type qw(:all <__>);

  die unless is __STD::EMAIL;

[Note] Generally all datatypes are dispatched via an L<perlfunc/AUTOLOAD> routine in the L<Data::Type::Proxy> namespace. Via runtime codegeneration an alias subroutine is created to hop the the original call.

  sub DB::ENUM { Data::Type::Proxy::db_enum( @_ ) };

In this example any use of DB::ENUM gets redirected to B<Data::Type::Object::db_enum> interface (dont call it directly!).

=head3 C<UNDERSCORE>

A single occurance of C<_> within the import parameters will activatve UNDERSCORE namespace resolution. That is, instead of using the COLLECTION::TYPE:: theme for the datatypes the 'C<::>' part is replaced with an 'C<_>' (underscore). In terms of namespace pollution a sterile solution.

So you want everything within C<Data::Type::>:

  use Data::Type qw(:all _ <Data::Type::> +ALL);

  die unless is Data::Type::STD_EMAIL();  # default was STD::ENUM

Unless a I<MASTER_PREFIX> is defined, I<UNDERSCORE> will export the types into the caller package:

  use Data::Type qw(:all _ +ALL);

  die unless is STD_EMAIL();  # default was STD::ENUM

If I<MASTER_PREFIX> is defined, I<UNDERSCORE> will export the types into C<Data::Type::>. This can be somewhat confusing. Use explicit package names within the I<MASTER_PREFIX> to circumvent this ambiguous style.

  package main;

    use Data::Type qw(:all _ <main::TYPE_> +ALL);

    die unless is TYPE_STD_EMAIL();  # default was STD::ENUM

If i handn't introduced C<main::> in the MASTER_PREFIX i have exported types into C<Data::Type::>, remembers:

  use Data::Type qw(:all _ <TYPE_> +ALL);

  die unless is Data::Type::TYPE_STD_EMAIL();  # default was STD::ENUM

=head3 C<DEBUG>

Will increase debuglevel one up. Place multiple times for increased verbosity.

  use Data::Type qw(:all DEBUG++ DEBUG++);

would yield to debuglevel 2. To decrease debuglevel one level:

  use Data::Type qw(:all DEBUG++ +BIO DEBUG--);

would turn debuglevel up during import process of the L<BIO collection|Data::Type::Collection::BIO> and then back to default.

=head1 PREREQUISITES

=head2 General




L<Class::Maker> (0.05.17), L<Regexp::Box> (0.01), L<Error> (0.15), L<IO::Extended> (0.06), L<Tie::ListKeyedHash> (0.41), L<Data::Iter> (0), L<Class::Multimethods> (1.70), L<Attribute::Util> (0.01), L<DBI> (1.30), L<Text::TabularDisplay> (1.18), L<String::ExpandEscapes> (0.01), L<XML::LibXSLT> (1.53)


=head2 Additionally required

The following modules are B<eval>'ed at runtime if required. L<Data::Type> delays the loading of them until a datatype is actually using it. This has some (more) pro and cons. May be somebody could realize a small "delay" first time using a datatype.

If you install this module via L<CPAN>, all modules below are also required and should be installed if you have setup CPAN correctly. Even if you never intend to use some of the datatypes they are strictly required. But this shouldnt hurt too much.



=over 1

=item Locale::Language (2.21)

=over 2

=item by STD::LANGCODE, STD::LANGNAME

=back

=item Business::CreditCard (0.27)

=over 2

=item by STD::CREDITCARD

=back

=item Email::Valid (0.15)

=over 2

=item by STD::EMAIL

=back

=item Business::UPC (0.04)

=over 2

=item by STD::UPC

=back

=item HTML::Lint (1.26)

=over 2

=item by STD::HTML

=back

=item Business::CINS (1.13)

=over 2

=item by STD::CINS

=back

=item Date::Parse (2.27)

=over 2

=item by DB::DATE, STD::DATE

=back

=item Net::IPv6Addr (0.2)

=over 2

=item by STD::IP

=back

=item Business::ISSN (0.90)

=over 2

=item by STD::ISSN

=back

=item Regexp::Common (2.113)

=over 2

=item by STD::INT, STD::IP, STD::QUOTED, STD::REAL, STD::URI, STD::ZIP

=back

=item X500::DN (0.28)

=over 2

=item by STD::X500::DN

=back

=item Locale::SubCountry (0)

=over 2

=item by STD::COUNTRYCODE, STD::COUNTRYNAME, STD::REGIONCODE, STD::REGIONNAME

=back

=item XML::Schema (0.07)

=over 2

=item by W3C::ANYURI, W3C::BASE64BINARY, W3C::BOOLEAN, W3C::BYTE, W3C::DATE, W3C::DATETIME, W3C::DECIMAL, W3C::DOUBLE, W3C::DURATION, W3C::ENTITIES, W3C::ENTITY, W3C::FLOAT, W3C::GDAY, W3C::GMONTH, W3C::GMONTHDAY, W3C::GYEAR, W3C::GYEARMONTH, W3C::HEXBINARY, W3C::ID, W3C::IDREF, W3C::IDREFS, W3C::INT, W3C::INTEGER, W3C::LANGUAGE, W3C::LONG, W3C::NAME, W3C::NCNAME, W3C::NEGATIVEINTEGER, W3C::NMTOKEN, W3C::NMTOKENS, W3C::NONNEGATIVEINTEGER, W3C::NONPOSITIVEINTEGER, W3C::NORMALIZEDSTRING, W3C::NOTATION, W3C::POSITIVEINTEGER, W3C::QNAME, W3C::SHORT, W3C::STRING, W3C::TIME, W3C::TOKEN, W3C::UNSIGNEDBYTE, W3C::UNSIGNEDINT, W3C::UNSIGNEDLONG, W3C::UNSIGNEDSHORT

=back

=item XML::Parser (2.34)

=over 2

=item by STD::XML

=back

=item Pod::Find (0.24)

=over 2

=item by STD::POD

=back


=back


=head1 EXAMPLES

You can find typical uses in L<Data::Type::Docs::Howto> and some scripts may reside in t/ and contrib/ of this distribution.


=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>


=head1 SEE ALSO

All the basic are described at L<Data::Type::Docs>. It also navigates you through the rest of the documentation.

L<Data::Type::Docs::FAQ>, L<Data::Type::Docs::FOP>, L<Data::Type::Docs::Howto>, L<Data::Type::Docs::RFC>, L<Data::Type::Facet>, L<Data::Type::Filter>, L<Data::Type::Query>, L<Data::Type::Collection::Std>

And these CPAN modules:

L<Data::Types>, L<String::Checker>, L<Regexp::Common>, L<Data::FormValidator>, L<HTML::FormValidator>, L<CGI::FormMagick::Validator>, L<CGI::Validate>, L<Email::Valid::Loose>, L<Embperl::Form::Validate>, L<Attribute::Types>, L<String::Pattern>, L<Class::Tangram>, L<WWW::Form> 

=head2 W3C XML Schema datatypes

http://www.w3.org/TR/xmlschema-2/

=head2 Synopsis 6 by Damian Conway, Allison Randal

http://www.perl.com/pub/a/2003/04/09/synopsis.html?page=3

=cut
