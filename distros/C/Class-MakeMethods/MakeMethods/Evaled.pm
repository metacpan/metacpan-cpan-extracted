=head1 NAME

Class::MakeMethods::Evaled - Make methods with simple string evals


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Evaled::Hash (
    new => 'new',
    scalar => [ 'foo', 'bar' ],
    array => 'my_list',
    hash => 'my_index',
  );


=head1 DESCRIPTION

This document describes the various subclasses of Class::MakeMethods
included under the Evaled::* namespace, and the method types each
one provides.

The Evaled subclasses generate methods using a simple string templating mechanism and basic string evals.


=head2 Calling Conventions

When you C<use> this package, the method names you provide
as arguments cause subroutines to be generated and installed in
your module.

See L<Class::MakeMethods::Standard/"Calling Conventions"> for more information.

=head2 Declaration Syntax

To declare methods, pass in pairs of a method-type name followed
by one or more method names. 

Valid method-type names for this package are listed in L<"METHOD
GENERATOR TYPES">.

See L<Class::MakeMethods::Standard/"Declaration Syntax"> and L<Class::MakeMethods::Standard/"Parameter Syntax"> for more information.

=cut

package Class::MakeMethods::Evaled;

$VERSION = 1.000;
use strict;
use Carp;

use Class::MakeMethods::Standard '-isasubclass';
use Class::MakeMethods::Utility::TextBuilder 'text_builder';

########################################################################

=head2 About Evaled Methods


=cut

sub evaled_methods {
  my $class = shift;
  my $template = shift;
  my $package = $Class::MakeMethods::CONTEXT{TargetClass};
  my @declarations = $class->_get_declarations( @_ );
  my @code_chunks;
  foreach my $method ( @declarations ) {
    my $code = $template;
    $code =~ s/__(\w+?)__/$method->{lc $1}/eg;

    # my $code = text_builder( $template, { 
    #   '__NAME__' => $method->{name}, 
    #   '__METHOD__{}' => $method, 
    #   '__CONTEXT__{}' => $Class::MakeMethods::CONTEXT,
    # } );

    push @code_chunks, $code;
  }
  my $code = join( "\n", "package $package;", @code_chunks, "1;" );
  eval $code; 
  $@ and Class::MakeMethods::_diagnostic('inst_eval_syntax', 'from eval', $@, $code);
  return;
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

For distribution, installation, support, copyright and license 
information, see L<Class::MakeMethods::Docs::ReadMe>.

=cut

1;
