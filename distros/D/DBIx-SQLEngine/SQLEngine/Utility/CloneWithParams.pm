=head1 NAME

DBIx::SQLEngine::Utility::CloneWithParams - Nifty Cloner

=head1 SYNOPSIS

  use DBIx::SQLEngine::Utility::CloneWithParams;
  
  $clone = clone_with_parameters( $string, @replacements );
  $clone = clone_with_parameters( \@array, @replacements );
  $clone = clone_with_parameters( \%hash, @replacements );

=head1 DESCRIPTION

This package provides a function named clone_with_parameters() that makes deep copies of nested data structures, while making replacements in key places.

=head2 clone_with_parameters

  $clone = clone_with_parameters( $reference, @replacements );

This function makes deep copies of nested data structures, with object
reblessing and loop detection to avoid endless cycles. (The internals are
based on clone() from L<Clone::PP>.)

It's one distinctive behavior is that if a data structure contains references
to the special numeric Perl variables $1, $2, $3, and so forth, when it is
cloned they are replaced with a set of provided parameter values. It also
replaces stringified versions of those references embedded in scalar values.

An exception is thrown if the number of parameters provided does not match
the number of special variables referred to.

B<Limitations:> 

=over 2

=item *

This will not properly copy tied data. 

=item *

Using this to clone objects will only work with simple objects that don't 
do much preprocessing of the values they contain.

=back

B<Examples:>

=over 2

=item *

Here's a simple copy of a string with embedded values to be provided by the caller:

  my $template = \$1 . '-' . \$2;
  my $clone = clone_with_parameters( $template, 'Foozle', 'Basil' );
  ok( $clone, 'Foozle-Basil' );

=item *

Here's a simple cloning of an array with values to be provided by the caller:

  my $template = [ \$1, '-', \$2 ];
  my $clone = clone_with_parameters( $template, 'Foozle', 'Basil' );
  is_deeply( $clone, [ 'Foozle', '-', 'Basil' ] );

=item *

Here's a simple cloning of a hash with key values to be provided by the caller:

  my $template = { foo => \$1, bar => \$2 }; 
  my $clone = clone_with_parameters( $template, 'Foozle', 'Basil' );
  is_deeply( $clone, { foo => 'Foozle', bar => 'Basil' } );

=item *

Templates to be copied can contain nested data structures, and can use paramters multiple times:

  my $template = { foo => \$1, bar => [ \$2, 'baz', \$2 ] }; 
  my $clone = clone_with_parameters( $template, 'Foozle', 'Basil' );
  is_deeply( $clone, { foo=>'Foozle', bar=>['Basil','baz','Basil'] } );

=item *

Although hash keys are automatically stringified, they still are substituted:

  my $template = { foo => 'bar', \$1 => \$2 }; 
  my $clone = clone_with_parameters( $template, 'Foozle', 'Basil' );
  is_deeply( $clone, { foo => 'bar', Foozle => 'Basil' } );

=item *

Objects can be copied to produce properly-blessed clones:

  package My::SimpleObject;

  sub new { my $class = shift; bless { @_ } $class }
  sub foo { ( @_ == 1 ) ? $_[0]->{foo} : ( $_[0]->{foo} = $_[1] ) }
  sub bar { ( @_ == 1 ) ? $_[0]->{bar} : ( $_[0]->{bar} = $_[1] ) }

  package main;
  use DBIx::SQLEngine::Utility::CloneWithParams;

  my $template = My::SimpleObject->new( foo => \$1, bar => \$2 ); 
  my $clone = clone_with_parameters( $template, 'Foozle', 'Basil' );
  isa_ok( $clone, 'My::SimpleObject' );
  ok( $clone->foo, 'Foozle' );
  ok( $clone->bar, 'Basil' );

If the class itself imports clone_with_parameters(), it can be called as a method instead of a function:

  package My::SimpleObject;
  use DBIx::SQLEngine::Utility::CloneWithParams;
  ...
  
  package main;

  my $template = My::SimpleObject->new( foo => \$1, bar => \$2 ); 
  my $clone = $template->clone_with_parameters( 'Foozle', 'Basil' );
  ...

=back

=cut

########################################################################

package DBIx::SQLEngine::Utility::CloneWithParams;

use Exporter;
sub import { goto &Exporter::import } 
@EXPORT = @EXPORT_OK = qw( clone_with_parameters safe_eval_with_parameters );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use strict;
use Carp;

########################################################################

my @num_refs = map { \$_ } ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
my $num_refs = join "|", map { "\Q$_" } @num_refs;
my %num_refs = map { $num_refs[ $_ -1 ] => $_ } ( 1 .. 9 );

########################################################################

use vars qw( %CopiedItems @Parameters @ParametersUsed );

# $deep_copy = clone_with_parameters( $value_or_ref );
sub clone_with_parameters {
  my $item = shift;
  local @Parameters = @_;
  local %CopiedItems = ();
  local @ParametersUsed = ();
  my $clone = __clone_with_parameters( $item );
  if ( scalar @ParametersUsed < scalar @Parameters ) { 
    confess( "Too many arguments:  " . scalar(@Parameters) . 
		    " instead of " . scalar(@ParametersUsed));
  }
  return $clone;
}

sub __get_parameter {
  my $placeholder = shift;
  
  if ( $placeholder > scalar @Parameters ) {
    confess( "Too few arguments:  " . scalar(@Parameters) . 
		    " instead of $placeholder");
  }
  $ParametersUsed[ $placeholder -1 ] ++;
  return $Parameters[ $placeholder -1 ];
}

# $copy = __clone_with_parameters( $value_or_ref );
sub __clone_with_parameters {
  my $source = shift;
  
  return $CopiedItems{ $source } if ( exists $CopiedItems{ $source } );

  if ( my $placeholder = $num_refs{ $source } ) {
    return __get_parameter( $placeholder );
  }
  
  my $ref_type = ref $source;
  if (! $ref_type) {
    $source =~ s/($num_refs)/ __get_parameter( $num_refs{ $1 } ) /geo;
    return $source;
  }
  
  my $class_name;
  if ( "$source" =~ /^\Q$ref_type\E\=([A-Z]+)\(0x[0-9a-f]+\)$/ ) {
    $class_name = $ref_type;
    $ref_type = $1;
  }
  
  my $copy;
  if ($ref_type eq 'SCALAR') {
    $CopiedItems{ $source } = $copy = \( my $var = "" );;
    $$copy = __clone_with_parameters($$source);
  } elsif ($ref_type eq 'REF') {
    $CopiedItems{ $source } = $copy = \( my $var = "" );;
    $$copy = __clone_with_parameters($$source);
  } elsif ($ref_type eq 'HASH') {
    $CopiedItems{ $source } = $copy = {};
    %$copy = map { __clone_with_parameters($_) } %$source;
  } elsif ($ref_type eq 'ARRAY') {
    $CopiedItems{ $source } = $copy = [];
    @$copy = map { __clone_with_parameters($_) } @$source;
  } else {
    $copy = $source;
  }
  
  bless $copy, $class_name if $class_name;
  
  return $copy;
}

########################################################################

=head2 safe_eval_with_parameters

  @results = safe_eval_with_parameters( $perl_code_string );

Uses the Safe package to eval the provided code string. Uses a compartment which shares the same numeric variables, so that values evaluated this way can then be cloned with clone_with_parameters.

=cut

my $safe_compartment;
sub safe_eval_with_parameters {
  $safe_compartment or $safe_compartment = do {
    require Safe;
    my $compartment = Safe->new();
    $compartment->share_from( 'main', [ map { '$' . $_ } ( 1 .. 9 ) ] );
    $compartment;
  };

  $safe_compartment->reval( shift );
}

########################################################################

=head1 SEE ALSO

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;
