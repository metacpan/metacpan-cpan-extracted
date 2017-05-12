package Class::MakeMethods::Basic;

use Class::MakeMethods '-isasubclass';

$VERSION = 1.000;

1;

__END__

########################################################################

=head1 NAME

Class::MakeMethods::Basic - Make really simple methods


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Basic::Hash (
    'new'     => [ 'new' ],
    'scalar'  => [ 'foo', 'bar' ]
  );

  package main;   
 
  my $obj = MyObject->new( foo => "Foozle", bar => "Bozzle" );
  print $obj->foo();
  $obj->bar("Barbados");


=head1 DESCRIPTION

This document describes the various subclasses of Class::MakeMethods
included under the Basic::* namespace, and the method types each
one provides.

The Basic subclasses provide stripped-down method-generation implementations. 

Subroutines are generated as closures bound to each method name.

=head2 Calling Conventions

When you C<use> a subclass of this package, the method declarations you provide
as arguments cause subroutines to be generated and installed in
your module. You can also omit the arguments to C<use> and instead make methods
at runtime by passing the declarations to a subsequent call to
C<make()>.

You may include any number of declarations in each call to C<use>
or C<make()>. If methods with the same name already exist, earlier
calls to C<use> or C<make()> win over later ones, but within each
call, later declarations superceed earlier ones.

You can install methods in a different package by passing C<-TargetClass =E<gt> I<package>> as your first arguments to C<use> or C<make>. 

See L<Class::MakeMethods/"USAGE"> for more details.

=head2 Declaration Syntax

The following types of declarations are supported:

=over 4

=item *

I<generator_type> => 'I<method_name>'

=item *

I<generator_type> => 'I<name_1> I<name_2>...'

=item *

I<generator_type> => [ 'I<name_1>', 'I<name_2>', ...]

=back

For a list of the supported values of I<generator_type>, see
L<Class::MakeMethods::Docs::Catalog/"BASIC CLASSES">, or the documentation
for each subclass.

For each method name you provide, a subroutine of the indicated
type will be generated and installed under that name in your module.

Method names should start with a letter, followed by zero or more
letters, numbers, or underscores.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

For distribution, installation, support, copyright and license 
information, see L<Class::MakeMethods::Docs::ReadMe>.

=cut
