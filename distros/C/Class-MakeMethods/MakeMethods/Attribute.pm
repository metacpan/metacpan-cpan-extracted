package Class::MakeMethods::Attribute;

require 5.006;
use strict;
use Carp;
use Attribute::Handlers;

use Class::MakeMethods;
use Class::MakeMethods::Utility::Inheritable 'get_vvalue';

our $VERSION = 1.005;

our %DefaultMaker;

sub import {
  my $class = shift;

  if ( scalar @_ and $_[0] =~ m/^\d/ ) {
    Class::MakeMethods::_import_version( $class, shift );
  }
  
  if ( scalar @_ == 1 ) {
    my $target_class = ( caller(0) )[0];
    $DefaultMaker{ $target_class } = shift;
  }
}

sub UNIVERSAL::MakeMethod :ATTR(CODE) {
  my ($package, $symbol, $referent, $attr, $data) = @_;
  if ( $symbol eq 'ANON' or $symbol eq 'LEXICAL' ) {
    croak "Can't apply MakeMethod attribute to $symbol declaration."
  }
  if ( ! $data ) {
    croak "No method type provided for MakeMethod attribute."
  }
  my $symname = *{$symbol}{NAME};
  if ( ref $data eq 'ARRAY' ) {
    local $_ = shift @$data;
    $symname = [ @$data, $symname ];
    $data = $_;
  }
  unless ( $DefaultMaker{$package} ) {
    local $_ = get_vvalue( \%DefaultMaker, $package );
    $DefaultMaker{$package} = $_ if ( $_ );
  }
  Class::MakeMethods->make( 
    -TargetClass => $package,
    -ForceInstall => 1, 
    ( $DefaultMaker{$package} ? ('-MakerClass'=>$DefaultMaker{$package}) : () ),
    $data => $symname
  );
}

1;

__END__

=head1 NAME

Class::MakeMethods::Attribute - Declare generated subs with attribute syntax

=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Attribute 'Standard::Hash';
  
  sub new    :MakeMethod('new');
  sub foo    :MakeMethod('scalar');
  sub bar    :MakeMethod('scalar', { hashkey => 'bar_data' });
  sub debug  :MakeMethod('Standard::Global:scalar');

=head1 DESCRIPTION

This package allows common types of methods to be generated via a subroutine attribute declaration. (Available in Perl 5.6 and later.)

Adding the :MakeMethod() attribute to a subroutine declaration causes Class::MakeMethods to create and install a subroutine based on the parameters given to the :MakeMethod attribute.

You can declare a default method-generation class by passing the name of a MakeMethods subclass in the use Class::MakeMethods::Attribute statement. This default method-generation class will also apply as the default to any subclasses declared at compile time. If no default method-generation class is selected, you will need to fully-qualify all method type declarations.

=head1 EXAMPLE

Here's a typical use of Class::MakeMethods::Attribute:

  package MyObject;
  use Class::MakeMethods::Attribute 'Standard::Hash';
  
  sub new    :MakeMethod('new');
  sub foo    :MakeMethod('scalar');
  sub bar    :MakeMethod('scalar', { hashkey => 'bar_data' });
  sub debug  :MakeMethod('Standard::Global:scalar');

  package MySubclass;
  use base 'MyObject';

  sub bazzle :MakeMethod('scalar');

This is equivalent to the following explicit Class::MakeMethods invocations:

  package MyObject;
  
  use Class::MakeMethods ( 
    -MakerClass => 'Standard::Hash',
    new => 'new',
    scalar => 'foo',
    scalar => [ 'ba', { hashkey => 'bar_data' } ],
    'Standard::Global:scalar' => 'debug',
  );
  
  package MySubclass;
  use base 'MyObject';
  
  use Class::MakeMethods ( 
    -MakerClass => 'Standard::Hash',
    scalar => 'bazzle',
  );

=head1 DIAGNOSTICS

The following warnings and errors may be produced when using
Class::MakeMethods::Attribute to generate methods. (Note that this
list does not include run-time messages produced by calling the
generated methods, or the standard messages produced by
Class::MakeMethods.)

=over

=item Can't apply MakeMethod attribute to %s declaration.

You can not use the C<:MakeMethod> attribute with lexical or anonymous subroutine declarations. 

=item No method type provided for MakeMethod attribute.

You called C<:MakeMethod()> without the required method-type argument.

=back

=head1 SEE ALSO

See L<Attribute::Handlers> by Damian Conway.

See L<Class::MakeMethods> for general information about this distribution. 

=cut
