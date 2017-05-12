package Contextual::Return::Wrapper;

use 5.008009;
use strict;
use warnings;

our $VERSION = '0.01';

use Class::ISA ;
use List::Util qw( first ) ;

my $function_code_ref ;
my $behavior_of ;

$behavior_of->{Listify}{CODE} = sub {
	my ( $ref, $symbol_name, @context ) = @_ ;

	return sub { @{ [ $ref->( @_ ) ] }[0..$#_] } ;
	} ;

$behavior_of->{ReturnContext}{CODE} = sub {
	my ( $ref, $symbol_name, @context ) = @_ ;

	my %behavior = map { $_->[1] => $_->[3] } @context ;
	$behavior{requires} ||= {} ;

	return sub {
		my $context = wantarray ?
				$behavior{requires}{void}
				  || $behavior{requires}{scalar}
				: defined wantarray 
				  ? $behavior{requires}{array}
				    || $behavior{requires}{void}
				    || $behavior{scalar}
				  : $behavior{requires}{array}
				    || $behavior{requires}{scalar}
				    || $behavior{void} ;

		return ( $context || sub { shift ; @_ }
				)->( $symbol_name, $ref->( @_ ) ) ;
		} ;
	} ;

$behavior_of->{ReturnContext}{requires}{array} = { array => sub {
	carp( "$_[0]() requires array context" ) ;
	shift ;	@_ ;
	} } ;
$behavior_of->{ReturnContext}{requires}{scalar} = { scalar => sub {
	carp( "$_[0]() requires scalar context" ) ;
	shift ;	@_ ;
	} } ;
$behavior_of->{ReturnContext}{requires}{void} = { void => sub {
	carp( "$_[0]() requires void context" ) ;
	shift ;	@_ ;
	} } ;

$behavior_of->{ReturnContext}{scalar}{first} = sub { shift ; $_[0] } ;
$behavior_of->{ReturnContext}{scalar}{last} = sub { shift ; $_[-1] } ;
$behavior_of->{ReturnContext}{scalar}{count} = sub { shift ; @_ } ;
$behavior_of->{ReturnContext}{scalar}{arrayref} = sub { shift ; [ @_ ] } ;
$behavior_of->{ReturnContext}{scalar}{array_ref} = sub { shift ; [ @_ ] } ;
$behavior_of->{ReturnContext}{scalar}{warn} = sub {
	carp( "$_[0]() called in scalar context" ) ;
	shift ;	@_ ;
	} ;

$behavior_of->{ReturnContext}{void}{warn} = sub {
	carp( "$_[0]() called in void context" ) ;
	shift ;	@_ ;
	} ;

sub carp {
	printf STDERR "Warning: %s at %s line %d.\n", 
			$_[0], @{ [ caller( 2 ) ] }[ 1, 2 ] ;
	}

sub usage {
	my ( $package, $symbol, $referent, $attr, $behave_how_arg,
			$phase, @debug ) = @_ ;
			$attr, @debug

	}

sub MODIFY_CODE_ATTRIBUTES {
	my( $package, $ref, $symbol_name, @args ) = @_ ;
	my $bad_argument = $symbol_name ;

	if ( $symbol_name =~ s{ ( \(.*?\) ) \Z }{}msx ) {
		@args = eval( $1 ) ;
		return $bad_argument unless defined $args[0] ;
		}
		
	my %behavior_args = @args == 0 
			? ('') x2
			: ( @args, ( @args %2 ? ('') : () ) ) ;

	return ( $symbol_name ) 
			unless exists $behavior_of->{$symbol_name}->{CODE} ;

	my @closure_inputs = map { [ @$_, _value_of( $behavior_of, @$_ ) ] }
			map { [ $symbol_name, 
			  ( $_ ? ( $_ => $behavior_args{$_} ) : () )
			  ] }
			keys %behavior_args ;

	my $bad = first { ! $_->[-1] } @closure_inputs ;
	return sprintf qq[%s( %s => '%s' )], @$bad if $bad ;

	$function_code_ref->{$ref} = [ @closure_inputs ] ;
	return () ;
	}

sub import {
	my ( $package ) = @_ ;

	no strict qw( refs ) ;
	no warnings qw( redefine ) ;

	do {
		my @context = @{ $function_code_ref->{ $_->[2] } } ;
		*{"$_->[0]"} = $behavior_of->{ $context[0][0] }->{CODE}->(
				$_->[2], $_->[1], @context ) ;
		} foreach 
		grep $_->[2] && $function_code_ref->{ $_->[2] },
		map { [ $_, *{"$_"}{NAME}, *{"$_"}{CODE} ] } 
		map {"${package}::$_"} 
		keys %{"${package}::"} ;

	goto &export ;
	}

sub export {
	my ( $package ) = @_ ;

	my ( $match, $super ) ;
	my @super = Class::ISA::super_path( $package ) ;
	my @siblings = @super ;

	while ( @siblings && ! ( $match = __PACKAGE__ eq shift @siblings ) 
			) {} ;
	## See perlmonks node 1047054
	first { $super = $_->can('import') } $match ? @siblings : @super ;
	goto &$super if $super ;
	return ;
	}

sub _value_of {
	my ( $ref, $key, @more ) = @_ ;
	return @more && exists $ref->{$key} 
			? _value_of( $ref->{$key}, @more )
			: $ref->{$key} ;
	}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Contextual::Return::Wrapper - Common functionality using wantarray

=head1 SYNOPSIS

  use parent qw( Contextual::Return::Wrapper Exporter ) ;

  __PACKAGE__->import ;

  sub formalize {
  	## baseline function without attribute

	return map { "Mr. $_" } @_ ;
	}

  sub uppercase : Listify {
	return map { uc } @_ ;
	}
  
  sub lowercase : ReturnContext( scalar => 'first' ) {
	return map { lc } @_ ;
	}

  my $sir = formalize( 'John' ) ;		## $sir =: 1
  my $john = uppercase( qw( John ) ) ;		## $john =: JOHN
  my $jim = lowercase( qw( Jim John ) ) ;	## $jim =: jim

B<ReturnContext> takes a variety of qualifiers which are listed below.

=head1 DESCRIPTION

The functions shown in the L</"SYNOPSIS"> can be generally referred to as list 
mutators.  When the return list is evaluated in a scalar context, as shown
in the I<formalize()> example above, the result is not what's usually
expected.

Contextual::Return::Wrapper automatically wraps these functions to change 
this behavior using attributes to specify pre-defined functionality.


=head2 Listify

Several users responded with the following recommendation when I posted my
original request:

  sub _listify {
	return @_[0..$#_] ;
	}

  sub calculate_distance {
	my ( $origin_zipcode, @remote_zipcodes ) = @_ ;
	## Latitude/Longitude lookups and calculations
	return _listify( @distances ) ;
	}

Contextual::Return::Wrapper delivers the same effect:

  sub calculate_distance : Listify {
	my ( $origin_zipcode, @remote_zipcodes ) = @_ ;
	## Latitude/Longitude lookups and calculations
	return @distances ;
	}

The primary advantage is a common, standardized solution with a somewhat
cleaner interface.

Note potential confusion with the identically named L<Scalar::Listify> module.  
The L</"Listify"> attribute is intended to convert a list to a scalar, while
the module converts a scalar to a list.


=head2 ReturnContext

A more general approach to this problem involves using the I<wantarray>
operator to determine the calling context of a function.  For example, the 
L<Contextual::Return> module provides an alternative to I<wantarray> that
provides more finely grained definitions.  Contextual::Return::Wrapper also
provides an alternative to explicit I<wantarray> calls by using a wrapper
to implement predefined functionality.

Obviously, no one would bother with anything so trivial, but the 
over-simplified I<lowercase()> function demonstrates where functionality is
added by the wrapper:

=head3 B<requires> qualifiers: I<array, scalar, void>

  sub lowercase : ReturnContext( requires => 'array' ) {
	return map { lc } $_ ;
	}
  ## $single= lowercase( qw( Jim John ) ) => generates warning
  ## lowercase( qw( Jim John ) ) => generates warning


  sub lowercase : ReturnContext( requires => 'scalar' ) {
	return map { lc } $_ ;
	}
  ## @list = lowercase( qw( Jim John ) ) => generates warning
  ## lowercase( qw( Jim John ) ) => generates warning


  sub lowercase : ReturnContext( requires => 'void' ) {
	return map { lc } $_ ;
	}
  ## @list = lowercase( qw( Jim John ) ) => generates warning
  ## $single= lowercase( qw( Jim John ) ) => generates warning

=head3 B<scalar> qualifiers: I<first, last, count, array_ref, warn>

  sub lowercase : ReturnContext( scalar => 'first' ) {
	return map { lc } $_ ;
	}
  ## scalar lowercase( qw( Jim John ) ) := 'jim'


  sub lowercase : ReturnContext( scalar => 'last' ) {
	return map { lc } $_ ;
	}
  ## scalar lowercase( qw( Jim John ) ) := 'john'


  sub lowercase : ReturnContext( scalar => 'count' ) {
	return map { lc } $_ ;
	}
  ## scalar lowercase( qw( Jim John ) ) := 2


  sub lowercase : ReturnContext( scalar => 'array_ref' ) {
	return map { lc } $_ ;
	}
  ## lowercase( qw( Jim John ) )->[0] := 'jim'


  sub lowercase : ReturnContext( scalar => 'warn' ) {
	return map { lc } $_ ;
	}
  ## scalar lowercase( qw( Jim John ) ) => generates warning

=head3 B<void> qualifiers: I<warn>

  sub lowercase : ReturnContext( void => 'warn' ) {
	return map { lc } $_ ;
	}
  ## lowercase( qw( Jim John ) ) => generates warning

=head3 combined qualifiers

Qualifiers can be combined as follows:

  sub lowercase : ReturnContext( void => 'warn', scalar => 'first' ) {
	return map { lc } $_ ;
	}


=head1 CAVEATS

=head2 evaluate.t

Some attribute definitions occur during compile time, which can cause 
problems for run-time evalution environments such as modperl.  Wrapping 
these compile-time definitions inside the I<import()> definition seems like
a successful work-around.  

In order to use these attributes inside a local package (eg I<main>), 
I<import()> needs to be explicitly invoked as shown in the L</"SYNOPSIS">.

  __PACKAGE__->import ;

=head2 exporter.t

The extended I<import()> function is going to conflict with 
C<Exporter::import()>, so the inheritance tree needs to be carefully defined.
The I<Exporter> class should be last, at the root, as follows:

  use parent qw( Contextual::Return::Wrapper Exporter ) ;

It seems that, like I<DESTROY()> destructors, some provision needs to chain 
I<import()> calls through an inheritance tree.  The I<export()> function 
may have potential as a general-purpose solution.  It can be used in any
package with the following invocation:

  goto &Contextual::Return::Wrapper::export


=head1 SEE ALSO

=over 8

=item * The module L<Attribute::Context> addresses the same problems.

=item * If this modules doesn't solve your problem, then 
L<Contextual::Return> probably does.

=item * L<Scalar::Listify> also addresses a similar problem domain.

=item * L<Attribute::Handler> is a good resource for designing attribute
based interfaces.  I adopted its style of defining attribute qualifiers
similar to function arguments.

=back

L<DBIx::Class> provides an example of the problem:

  @rows = $resultset->search( { id => { '<', 20 } } ) ;	
  $row = $resultset->search( { id => 20 } ) ;
  ## DBIx::Class automatically performs the list => scalar conversion

Please email me directly for questions, comments, suggestions, and other 
feedback.  The pre-defined functionality may be incomplete.

=head1 ACKNOWLEDGEMENTS

Admittedly, technically, I got in a little over my head.  My original 
intention was to publish a straightforward solution to standardize a 
variety of hacks and idioms.  The following individuals provided helpful 
instruction:

=over 8

=item * Curtis Ovid Poe

=item * Rolf Langsdorf

=item * Aristotle Pagaltzis

=item * Linda Walsh

=item * Chicago Perlmongers

=back

=head1 AUTHOR

Jim Schueler, E<lt>jim@tqis.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jim Schueler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
