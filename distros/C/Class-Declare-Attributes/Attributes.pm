package Class::Declare::Attributes;

use 5.006;
use strict;
use warnings;
use attributes;

use Class::Declare  qw( :modifiers );
use File::Spec::Functions       qw();
use base qw( Class::Declare        );
use vars qw( $VERSION $REVISION    );

    $VERSION      = '0.12';
    $REVISION     = '$Revision: 1515 $';

# need to copy the export symbols from Class::Declare
# to permit Class::Declare::Attributes to provide attribute modifiers
    *EXPORT_OK    = *Class::Declare::EXPORT_OK;
    *EXPORT_TAGS  = *Class::Declare::EXPORT_TAGS;


# declare the 'attributes' helper routines
{
  # moving "my" declarations out of BEGIN for Perl v5.8.4
  #   - this avoids "Bizarre copy of HASH in leavesub" error
  #   - this is a bug fixed in v5.8.5
  #   - see http://perlmonks.org/index.pl?node_id=361620 for more details
  my  %__ATTR__;
  my  %__PKGS__;
  my  %__DONE__;

BEGIN {

  # define the attributes that are wrapped by this class
      %__ATTR__ = map { $_ => 1 } qw( abstract
                                      class
                                      restricted
                                      static
                                      public
                                      protected
                                      private    );

  # suppress the warnings surrounding the use of attributes that may be
  # reserved for future use
  #   - this is naughty ... oh, well ... can be changed if necessary
  #   - we want to suppress this warning without disabling all warnings
  #   - we previously set $^W to 0, but this is very heavy handed, so
  #     let's try the following
  $SIG{__WARN__}  = sub {
    # if we detect a violation caused by C::D::A, then suppress it,
    # otherwise let it through
    my  $pkg    = __PACKAGE__;
    ( $_[0] =~ /attribute may clash .+? reserved word: (\w+)/o ||
      $_[0] =~ /^Declaration of (\w+) .+? package $pkg .+? reserved word/o )
        # ensure the attribute belongs to C::D::A
        and ( $__ATTR__{ $1 } )
        and return 1; # do nothing

    # otherwise, return the standard warn() response
    warn $_[0];
  };  # $SIG{__WARN__}()


  # keep a log of calls made to set the attributes
      %__PKGS__ = ();
      %__DONE__ = ();


# MODIFY_CODE_ATTRIBUTES()
#
# Keep a reference of the and type of attribute for each method specified as
#
#     sub method : type { ... }
#
sub MODIFY_CODE_ATTRIBUTES
{
  my  ( $pkg , $ref , @attr )   = @_;

  # only consider the attributes that we know about
  my    @unknown;   undef @unknown;
  foreach my $attr ( @attr ) {
    # if this not an attribute we care about, then add it to the list of
    # attributes to return
    push @unknown , $attr
      and next                unless ( exists $__ATTR__{ $attr } );

    # have we already assigned one of our attributes to this target?
    #   - if we have, then we should raise an error
    if ( defined ( my $previous =  $__PKGS__{ $pkg }->{ $ref } ) ) {
      # if this reference has already been assigned one of our attributes,
      # then we have a problem if we are attempting to now assign a different
      # attribute
      #   - something declared with the same attribute twice is not a problem
      #     as we just ignore the subsequent assignment
      next              if ( $previous eq $attr );

      # two conflicting attribute assignments
      die "conflicting CODE attribute assignments of '$previous' "
        . "and '$attr' in $pkg";
    }

    # store this attribute assignment
    $__PKGS__{ $pkg }->{ $ref } = $attr;
    
    # assign the CORE 'method' attribute to this reference as well
    #   - each code reference assigned a Class::Declare::Attributes interface
    #     is also actually a method
            attributes::->import( CORE => $ref => 'method' );
  }

  # if we have any unknown attributes, then return them
  return @unknown         if ( @unknown );

  # otherwise, there's nothing more to do
  return;
} # MODIFY_CODE_ATTRIBUTES()


# FETCH_CODE_ATTRIBUTES()
#
# Return the type of attribute for the given package and reference
sub FETCH_CODE_ATTRIBUTES
{
  my  ( $pkg , $ref )   = @_;

  # if this is known package and reference, then return its attributes
  return $__PKGS__{ $pkg }->{ $ref };
} # FETCH_CODE_ATTRIBUTES()



# __init__()
#
# Initialise the code wrapping for Class::Declare-style methods
#   - this needs to be called either at INIT time or when declare() is called
#     to ensure dynamically loaded modules are handled correctly and the
#     strict() setting is obeyed
sub __init__
{
  my  $self   = __PACKAGE__->static( shift );
  my  @pkg    = ( defined $_[0] ) ? ( $_[0] ) : keys %__PKGS__;

  # iterate through the given package(s)
  foreach my $pkg ( @pkg ) {
    no strict 'refs';

    # do we have strict checking for this package on?
    my  $strict = $pkg->strict;

    # if we have strict checking off and we've seen this package before
    # then we should ensure we 'unnwrap' all wrapped routines
    unless ( $strict ) {
      if ( my $wrapped = delete $__DONE__{ $pkg } ) {
        while ( my ( $glob , $ref ) = each %{ $wrapped } ) {
          no warnings 'redefine';

          *{ $glob }  = $ref;
        }
      }

      # no point proceeding, since we don't have strict checking on
      return;
    }

    # iterate through the symbol tree of this package
    my  $pkg_   = $pkg . '::';
    my  @names  = keys %{ $pkg_ };
    foreach my $name ( @names ) {
      no warnings 'once';

      # if we don't have a normal symbol table entry, then skip
      #   - occasionally we will find a reference here not a GLOB
      my  $sym  = ${ $pkg_ }{ $name };
               ( ref $sym )                 and next;

      # if we don't have a CODE reference then we can't proceed
      my  $ref  = *{ $sym }{ CODE }           or next;
      my  @attr = grep { defined } attributes::get( $ref );

      # filter attributes that don't belong to the list fo C::D attributes
          @attr = grep { defined } grep { $__ATTR__{ $_ } } @attr;

      # if there are no attributes, then there's nothing to do
        ( @attr )                             or next;

      # extract the name of this subroutine
      my  $glob = $pkg_ . $name;

      # if we have strict access checking, then "wrap" this routine
      if ( $strict ) {
        no warnings 'redefine';

        my  $type   = $attr[0];
         *{ $glob } = sub { $pkg->$type( $_[0] , $glob ); goto $ref };

        # make note that this method has been wrapped
        #   - store the original CODE reference for this glob
        $__DONE__{ $pkg }->{ $glob }  = $ref;
      }
    }
  }
} # __init__()

} # BEGIN()

} # closure


# require()
#
# Load the given class using Perl's require(), ensuring __init__() is called
# after the class has been successfully loaded. This is to ensure the correct
# subroutine wrappers are put in place.
#
# If the given class contains ';' then we assume that it's the string of the
# class rather than the filename, so we simply eval() that, rather than trying
# to load it from the filesystem.
sub require : class
{
  my  $self   = shift;
  # if there's no class then there's nothing to do
  my  $class  = shift                   or return undef;

  # do we have a file or the text of the class?
  if ( $class =~ m/;/o ) {
    # we assume we have the body of a class, so we just eval() it
    eval $class;

  # otherwise we have to load the file from disk
  } else {
    # convert the class into a file name
    my  $file   = File::Spec::Functions::catfile( split '::' , $class ) . '.pm';

    # attempt to load the file
    #   - return undef if there's a problem
    eval { require $file };
  }

  # if there were any problems, then we should fail
    ( $@ )                             and return undef;

  # if we've loaded this class, then ensure __init__() is called
      $self->__init__;

  1;  # everything is OK
} # require()


# for modules loaded by use(), ensure __init__() is called prior to code
# execution
INIT { __PACKAGE__->__init__ }


1;  # end of module
__END__
=pod

=head1 NAME

Class::Declare::Attributes - Class::Declare method types using Perl attributes.


=head1 SYNOPSIS

  package My::Class;

  use 5.006;
  use strict;
  use warnings;

  use base qw( Class::Declare::Attributes );

  # declare the class/instance attributes
  __PACKAGE__->declare( ... );

  #
  # declare class/static/restricted/etc methods of this package
  #

  sub my_abstract   : abstract   { ... }
  sub my_class      : class      { ... }
  sub my_static     : static     { ... }
  sub my_restricted : restricted { ... }
  sub my_public     : public     { ... }
  sub my_private    : private    { ... }
  sub my_protected  : protected  { ... }


=head1 DESCRIPTION

B<Class::Declare::Attributes> extends L<Class::Declare> by adding support
for Perl attributes for specifying class method types. This extension was
inspired by Damian Conway's L<Attribute::Handlers> module, and Tatsuhiko
Miyagawa's L<Attribute::Protected> module. The original implementation
used L<Attribute::Handlers>, but now simply refers to L<attributes>.

The addition of Perl attribute support (not to be confused with
object attributes, which are entirely different, and also supported
by B<Class::Declare>) greatly simplifies the specification of
B<Class::Declare>-derived class and instance methods. This should aid in
the porting of existing code (Perl, Java and C++) to a Class::Declare
framework, as well as simplify the development of new modules.

With the addition of Perl attributes, B<Class::Declare> methods can now be
written as

  sub method : public
  {
    my $self = shift;
    ...
  }

instead of

  sub method
  {
    my $self = __PACKAGE__->public( shift );
    ...
  }


=head2 Attributes

B<Class::Declare::Attributes> defines six method or subroutine attributes
that correspond to the six method and object- and class-attribute types
of B<Class::Declare>:

=over 4

=item B<:abstract>

B<abstract> methods are merely placeholders and must be defined in
subclasses. If called, an B<abstract> method will throw an error through
I<die()>.

=item B<:class>

B<class> methods are accessible from anywhere, and may be called through
the class, a derived class, or any instance derived from the defining class.
This is the class equivalent of B<public> methods.

=item B<:static>

B<static> methods may only be accessed within the defining class and instances
of that class. This is the class equivalent of B<private> methods.

=item B<:restricted>

B<restricted> methods may only be accessed from within the defining class and
all classes and objects that inherit from it. This is the class equivalent
of B<protected> methods.

=item B<:public>

B<public> methods are accessible from anywhere, but only through object
instances derived from the defining class.

=item B<:private>

B<private> methods are only accessible from within the defining class and
instances of that class, and only through instances of the defining class.

=item B<:protected>

B<protected> methods are only accessible from within the defining class
and all classes and objects derived from the defining class. As an instance
method it may only be accessed via an object instance.

=back

The attributes defined by B<Class::Declare::Attributes> are not
to be confused with the object and class attributes defined by
B<Class::Declare::declare()>. The clash in terminology is unfortunate,
but as long as you remember the context of your attributes, i.e. are they
Perl-attributes, or class-/object-attributes, the distinction should be clear.


=head2 Attribute Modifiers

B<Class::Declare::Attributes> supports the use of the class and instance
attribute modifiers defined by B<Class::Declare>. These modifiers may be
imported into the current namespace by either explicitly listing the modifier
(B<rw> and B<ro>) or using one of the predefined tags: C<:read-write>,
C<:read-only> and C<:modifiers>. For example:

  use Class::Declare::Attributes qw( :read-only );

B<Note:> The "magic" of B<Class::Declare::Attributes> that defines the method
attributes is performed during the compilation of the module it is C<use>d
in. To access the attribute modifiers, the C<use base> approach should be
replaced with the more traditional:

  use Class::Declare::Attributes qw( :modifiers );
  use vars qw( @ISA );
  @ISA = qw( Class::Declare::Attributes );

However, because B<Class::Declare::Attributes> (or more precisely
L<Attribute::Handlers>) operates before the execution phase, the assignment to
C<@ISA> will occur too late to take effect (resulting in an invalid attribute
error). To prevent this error, and to bring the assignment to C<@ISA> forward
in the module compilation/execution phase, the assignment should be wrapped
in a C<BEGIN {}> block.

  BEGIN { @ISA = qw( Class::Declare::Attributes ); }

For more information on class and instance attribute modifiers, please refer
to L<Class::Declare>.


=head2 Methods

=over 4

=item B<require(> I<class> B<)>

In the event that a B<Class::Declare::Attributes>-derived class needs to be
loaded dynamically, the B<require()> method should be used to ensure correct
handling of the B<Class::Declare::Attributes>-style attributes. B<require()>
is a class method of B<Class::Declare::Attributes> and should therefore be
called along the lines of the following:

  package My::Class;

  use strict;
  use warnings;

  use bae qw( Class::Declare::Attributes );

  ...

      my $class   = 'My::Class::To::Load';
         __PACKAGE__->require( $class )    or die;

I<$class> can be either a class name (as above) or a string containing the
definition of the class. B<require()> will return true on success and
undefined on failure, with C<$@> containing the error.

=back


=head1 CAVEATS

B<Class::Declare::Attributes> is distributed as a separate module to
B<Class::Declare> as it requires Perl versions 5.6.0 and greater, while
B<Class::Declare> supports all object-aware versions of Perl (i.e. version
5.0 and above).

The interface B<Class::Declare::Attributes> provides is not ideal. In fact,
some might suggest that it's 'illegal'. In some ways, yes, it is illegal,
because it has hijacked some lowercase attribute names that Perl has marked
down for possible future use. However, as of Perl 5.8.0, these attributes
are not in use (C<:shared> is, which is why B<Class::Declare> changed this
class of attributes and methods to C<restricted>), and so we may as well
take advantage of them.

This is an example of what can be done with Perl (especially if you're
willing to bend the rules), and who knows, maybe it's a glimpse of the sort
of capabilities we'll see in Perl 6.


=head1 SEE ALSO

L<Class::Declare>, L<attributes>, L<Attribute::Protected>,
L<Attribute::Handlers>.


=head1 AUTHOR

Ian Brayshaw, E<lt>ibb@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2003-2016 by Ian Brayshaw. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


=cut
