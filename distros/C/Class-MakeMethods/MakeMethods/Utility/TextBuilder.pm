package Class::MakeMethods::Utility::TextBuilder;

$VERSION = 1.008;

@EXPORT_OK = qw( text_builder );
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

use strict;
use Carp;

# $expanded_text = text_builder( $base_text, @exprs )
sub text_builder {
  my ( $text, @mod_exprs ) = @_;
  
  my @code_exprs;
  while ( scalar @mod_exprs ) {
    my $mod_expr = shift @mod_exprs;
    if ( ref $mod_expr eq 'HASH' ) {
      push @code_exprs, %$mod_expr;
    } elsif ( ref $mod_expr eq 'ARRAY' ) {
      unshift @mod_exprs, @$mod_expr;
    } elsif ( ref $mod_expr eq 'CODE' ) {
      $text = &$mod_expr( $text );
    } elsif ( ! ref $_ ) {
      $mod_expr =~ s{\*}{$text}g;
      $text = $mod_expr;
    } else {
      Carp::confess "Wierd contents of modifier array.";
    }
  }
  my %rules = @code_exprs;
  
  my @exprs;
  my @blocks;
  foreach ( sort { length($b) <=> length($a) } keys %rules ) {
    if ( s/\{\}\Z// ) {
      push @blocks, $_;
    } else {
      push @exprs, $_;
    }
  }
  push @blocks, 'UNUSED_CONSTANT' if ( ! scalar @blocks );
  push @exprs,  'UNUSED_CONSTANT' if ( ! scalar @exprs );
  
  # There has *got* to be a better way to regex matched brackets... Right?
  # Erm, well, no. It looks like Text::Balanced would do the trick, with the 
  # requirement that the below bit get re-written to not be regex-based.
  my $expr_expr = '\b(' . join('|', map "\Q$_\E", @exprs ) . ')\b';
  my $block_expr = '\b(' . join('|', map "\Q$_\E", @blocks ) . ') \{ 
      ( [^\{\}]* 
	(?: \{ 
	  [^\{\}]* 
	  (?:  \{   [^\{\}]*  \}  [^\{\}]*  )*? 
	\} [^\{\}]* )*?
      )
    \}';
  
  1 while ( 
    length $text and $text =~ s/ $expr_expr /
      my $substitute = $rules{ $1 };
      if ( ! ref $substitute ) { 
	$substitute;
      } elsif ( ref $substitute eq 'CODE' ) {
	&{ $substitute }();
      } else {
	croak "Unknown type of substitution rule: '$substitute'";
      }
    /gesx or $text =~ s/ $block_expr /
      my $substitute = $rules{ $1 . '{}' };
      my $contents = $2;
      if ( ! ref $substitute ) { 
	$substitute =~ s{\*}{$contents}g;
	$substitute;
      } elsif ( ref $substitute eq 'HASH' ) {
	$substitute->{$contents};
      } elsif ( ref $substitute eq 'CODE' ) {
	&{ $substitute }( $contents );
      } else {
	croak "Unknown type of substitution rule: '$substitute'";
      }
    /gesx
  );
  
  return $text;  
}

1;

__END__

=head1 NAME

Class::MakeMethods::Utility::TextBuilder - Basic text substitutions

=head1 SYNOPSIS

 print text_builder( $base_text, @exprs )

=head1 DESCRIPTION

This module provides a single function, which implements a simple "text macro" mechanism for assembling templated text strings.

  $expanded_text = text_builder( $base_text, @exprs )

Returns a modified copy of $base_text using rules from the @exprs list. 

The @exprs list may contain any of the following:

=over 4

=item *

A string, in which any '*' characters will be replaced by the base text. The interpolated string then replaces the base text.

=item *

A code-ref, which will be called with the base text as its only argument. The result of that call then replaces the base text.

=item *

A hash-ref, which will be added to the substitution hash used in the second pass, below.

=item *

An array-ref, containing additional expressions to be treated as above.

=back

After any initial string and code-ref rules have been applied, the hash of substitution rules are applied.

The text will be searched for occurances of the keys of the substitution hash, which will be modified based on the corresponding value in the hash. If the substitution key ends with '{}', the search will also match a balanced block of braces, and that value will also be used in the substitution.

The hash-ref may contain the following types of rules:

=over 4

=item *

'string' => 'string'

Occurances of the first string are to be replaced by the second.

=item *

'string' => I<code_ref>

Occurances of the string are to be replaced by the results of calling the subroutine with no arguments.

=item *

'string{}' => 'string'

Occurances of the first string and subsequent block of braces are replaced by a copy of the second string in which any '*' characters have first been replaced by the contents of the brace block. 

=item *

'string{}' => I<code_ref>

Occurances of the string and subsequent block of braces are replaced by the results of calling the subroutine with the contents of the brace block as its only argument. 

=item *

'string{}' => I<hash_ref>

Occurances of the string and subsequent block of braces are replaced by using the contents of the brace block as a key into the provided hash-ref.

=back

=head1 EXAMPLE

The following text and modification rules provides a skeleton for a collection letter:

  my $letter = "You owe us AMOUNT. Please pay up!\n\n" . 
		  "THREAT{SEVERITY}";
  
  my @exprs = (
    "Dear NAMEm\n\n*",
    "*\n\n-- The Management",
    
    { 'THREAT{}' => { 'good'=>'Please?', 'bad'=>'Or else!' } },
    
    "\t\t\t\tDATE\n*",
    { 'DATE' => 'Tuesday, April 1, 2001' },
  );

One might invoke this template by providing additional data for a given instance and calling the text_builder function:
  
  my $item = { 'NAME'=>'John', 'AMOUNT'=>'200 camels', 'SEVERITY'=>'bad' };
  
  print text_builder( $letter, @exprs, $item );

The resulting output is shown below:  

				  Tuesday, April 1, 2001
  Dear John,
  
  You owe us 200 camels. Please pay up!
  
  Or else!
  
  -- The Management

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

=cut
