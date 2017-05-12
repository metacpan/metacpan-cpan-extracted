
use warnings;
use strict;

package Data::Polymorph;

use Carp;
use Scalar::Util qw( blessed looks_like_number );
use UNIVERSAL qw( isa can );

=head1 NAME

Data::Polymorph - Yet another approach for polymorphism.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  my $poly = Data::Polymorph->new;
  
  ## defining external method 'freeze'
  
  $poly->define( 'FileHandle' => freeze => sub{
    "do{ require Symbol; bless Symbol::gensym(), '".ref($_[0])."'}"
  }  );
  
  $poly->define( "UNIVERSAL" => freeze => sub{
    use Data::Dumper;
    sprintf( 'do{ my %s }', Dumper $_[0]);
  });
  
  ## it returns `undef'
  FileHandle->can('freeze');
  UNIVERSAL->('freeze');
  
  ###
  ### applying defined method.
  ###
  
  ## returns "do{ requier Symbol; bless Symbol::gensym(), 'FileHandle'}"
  $poly->apply( FileHandle->new , 'freeze' );

=head1 DESCRIPTION

This module provides gentle way of polymorphic behaviors definition 
for special cases that aren't original concerns.

Applying this solution dissipates necessity for making an original
namespace dirty.

=head1 ATTRIBUTES

=over 4

=item C<runs_native>

  ##
  ##  If external method "foo" is not defined into the $poly...
  ##
  
  $poly->runs_native(1);
  $poly->apply($obj, foo => $bar ); # ... same as $obj->foo($bar)
  $poly->runs_native(0);
  $poly->apply($obj, foo => $bar ); # ... die

If this value is true and the object uses C<UNIVERSAL::can>
when the method is not defined.

=item C<class_methods>

The dictionary of class methods.

=item C<type_methods>

The dictionary of type methods.

=back

=head1 METHODS

=over 4

=item C<new>

  $poly = Data::Polymorph->new();
  $poly = Data::Polymorph->new( runs_native => 0 ); 
  $poly = Data::Polymorph->new( runs_native => 1 ); 

Constructs and returns a new instance of this class.

=cut



{
  my @Template =
    (
     [ class_methods => sub{{}} ],
     [ type_methods => sub{
         return
           [
            [Undef     => sub{ !defined( $_[1] );         },{},'Any'],
            [ScalarRef => sub{ isa( $_[1], 'SCALAR' )     },{},'Ref'],
            [CodeRef   => sub{ isa( $_[1], 'CODE' )       },{},'Ref'],
            [ArrayRef  => sub{ isa( $_[1], 'ARRAY' )      },{},'Ref'],
            [HashRef   => sub{ isa( $_[1], 'HASH' )       },{},'Ref'],
            [GlobRef   => sub{ isa( $_[1], 'GLOB' )       },{},'Ref'],
            [RefRef    => sub{ isa( $_[1], 'REF' )        },{},'Ref'],
            [Ref       => sub{ ref( $_[1] ) and 1         },{},'Defined'],
            [Num       => sub{ looks_like_number( $_[1] ) },{},'Value'],
            [Glob      => sub{ isa(\$_[1],'GLOB' )        },{},'Value'],
            [Str       => sub{ isa(\$_[1],'SCALAR');      },{},'Value'],
            [Value     => sub{ 1                          },{},'Defined'],
            [Defined   => sub{ 1                          },{},'Any'],
            [Any       => sub{ 1                          },{},undef],
           ]
         }],

     [ _dic => sub{
         my $self = shift;
         return {  map{ ($_->[0] ,  $_)} @{$self->type_methods}   };
       }],

     [ runs_native     => sub{0} ],
     );

  sub{
    my ( $caller ) = caller;
    foreach (@_){
      my $field = $_;
      my $glob = do{ no strict 'refs'; \*{"${caller}::$field"} };
      *{$glob} = sub  ($;$){
        my $self = shift;
        return $self->{$field} unless @_;
        $self->{$field} = shift;
      };
    }
  }->( map { $_->[0]} @Template );

  sub new {
    my ($self, %args) = @_;
    $self = bless {} , (blessed $self) || $self;
    foreach my $spec ( @Template ){
      $self->{$spec->[0]} = $spec->[1]->($self);
    }
    $self->runs_native(1) if $args{runs_native};
    $self;
  }
}



=item C<type>

  $type = $poly->type( 123  ); # returns 'Num'

Returns the type name of the given object. Types are below.

  Any
    Undef
    Defined
      Value
        Num
        Str
        Glob
      Ref
        ScalarRef
        HashRef
        ArrayRef
        CodeRef
        RefRef

They seem like L<Moose> Types.

Actually, I designed these types based on the man pages from 
L<Moose::Util::TypeConstraints>.
Because these were not designed for constraint, they never relate with 
L<Moose> types.

=item C<is_type>

  $poly->is_type('Any') ; # => 1
  $poly->is_type('Str') ; # => 1
  $poly->is_type('UNIVERSAL') ; # => 0

Returns true if given name is a defined type name. Otherwise,
returns false.

=item C<super_type>

  $type = $poly->super_type('Str');   # => Value
  $type = $poly->super_type('Undef'); # => Any

Returns name of the type which is the super type of the given type name.

=item C<class>

  $type = $poly->class( $obj );

Returns class name or type name of the given object.

=cut

sub type {
  my ( $self, $obj ) = @_;
  foreach my $slot ( @{$self->type_methods} ) {
    return $slot->[0] if $slot->[1]->($self, $obj) ;
  }
}

sub is_type {
  my ($self, $type) = @_;
  (exists $self->_dic->{$type}) ? 1 : 0;
}

sub super_type {
  my ($self, $type) = @_;
  confess "$type is not a type" unless $self->is_type( $type );
  ($self->_dic->{$type} || [])->[3];
}

sub class {
  my ( $self, $obj ) = @_;
  blessed( $obj ) or $self->type( $obj );
}

=item C<define_type_method>

  $poly->define_type_method('ArrayRef' => 'values' => sub{ @$_[0]});
  $poly->define_type_method('HashRef'  => 'values' => sub{ values %$_[0]});
  $poly->define_type_method('Any'      => 'values' => sub{ $_[0] });

Defines a method for the given type.

=item C<define_class_method>

  $poly->define_class_method( 'Class::Name' => 'method' => sub{
    #                    code reference
  }  );

Defines an external method for a given class which can be  appliabled
by the instance of this class.

=item C<define>

  $poly->define('Class::Name' => 'method' => sub{ ... } );
  $poly->define('Undef'       => 'method' => sub{ ... } );

Defines a method for a type or a class.

=cut

sub define_type_method {
  my ( $self, $class, $method , $code ) = @_;
  foreach my $slot ( @{$self->type_methods}) {
    next unless $slot->[0] eq $class;
    return $slot->[2]->{$method} = $code;
  }
  confess "unknown type: $class";
}

sub define_class_method {
  my ( $self, $class, $method , $code ) = @_;
  my $slot = ($self->class_methods->{$method} ||= []);
  my $i = 0;
  for(; $i < scalar @$slot ; $i++){
    my $klass = $slot->[$i]->[0];

    if( $klass eq $class ){
      $slot->[$i]->[1] = $code;
      return;
    }

    last if isa $class => $klass;
  }
  splice @$slot, $i, 0, [$class => $code];
}

sub define {
  my ( $self, $class, $method, $code ) = @_;
  goto ( $self->is_type( $class )
         ? \&define_type_method
         : \&define_class_method );
}


=item C<type_method>

  $meth = $poly->type_method( 'ArrayRef' => 'values' );

Returns a CODE reference which is invoked as the method of given type.

=item C<super_type_method>

  $meth = $poly->super_type_method( 'ArrayRef' => 'values' );

Returns a CODE reference which is invoked as the super method of given type.

=cut

sub type_method {
  my ( $self, $type, $method ) = @_;
  confess "$type is not a type" unless $self->is_type( $type );
  while ( $type ){
    my $slot = $self->_dic->{$type};
    my $code = $slot->[2]->{$method};
    return $code if $code;
    $type = $slot->[3];
  }
  undef;
}

sub super_type_method {
  my ($self, $type, $method ) = @_;
  confess "$type is not a type" unless $self->is_type( $type );
  my $count = 0;
  for (my $slot; $type ; $type = $slot->[3] ){
    $slot = $self->_dic->{$type};
    my $code = $slot->[2]->{$method};
    next unless $code;
    return $code if $count;
    $count++;
  }
  undef;
}

=item C<class_method>

  $meth = $poly->class_method( 'A::Class' => 'method' );
  ($poly->apply( 'A::Class' => $method ) or
   sub{ confess "method $method is not defined" } )->( $args .... );

Returns a CODE reference which is invoked as the method of given class.

=item C<super_class_method>

  $super = $poly->super_class_method( 'A::Class' => 'method' );
  ($poly->apply( 'A::Class' => $method ) or
   sub{ confess "method $method is not defined" } )->( $args .... );

Returns a CODE reference which is invoked as the super method of given class.

=cut

sub class_method {
  my ( $self, $class, $method ) = @_;
  my $slot = ($self->class_methods->{$method} ||= []);
  foreach my $meth ( @$slot ){
    next unless isa( $class, $meth->[0] );
    return $meth->[1];
  }
}

sub super_class_method {
  my ( $self, $class, $method ) = @_;
  my $slot  = ($self->class_methods->{$method} ||= []);
  my $count = 0;
  foreach my $meth ( @$slot ){
    next unless isa( $class, $meth->[0] );
    return $meth->[1] if $count;
    $count++;
  }
}

=item C<method>

  $code = $poly->method( []              => 'values' );
  $code = $poly->method( qr{foo}         => 'values' );
  $code = $poly->method( FileHandle->new => 'values' );

Returns a CODE reference which is invoked as the method of given object.

=item C<super_method>

  $code = $poly->super_method( []              => 'values' );
  $code = $poly->super_method( qr{foo}         => 'values' );
  $code = $poly->super_method( FileHandle->new => 'values' );
  $code = $poly->super_method( 'Any' => 'values' ); # always undef

Returns a CODE reference which is invoked as the super method of given object.

=cut

sub method {
  my ( $self, $obj, $method ) = @_;
  my $class = blessed( $obj );
  my $type  = $self->type( $obj );
  ($class
   ? ( $self->class_method( $class, $method ) or
       $self->type_method( $type, $method ) or
       ( $self->runs_native and UNIVERSAL::can( $obj , $method ) ))
   :  $self->type_method( $type, $method ));
}

sub _native_super {

  my ( $class, $method ) = @_;
  my $glob = do{ no strict 'refs'; \*{"$class::$method"} };
  my @isa  = do{ no strict 'refs'; @{"${class}::ISA"} };

  if( *{$glob}{CODE} ){
    foreach my $parent ( @isa ){
      my $code = UNIVERSAL::can( $parent, $method );
      return $code if $code;
    }
  }
  else {
    foreach my $parent ( @isa ){
      my $code = _native_super( $parent, $method );
      return $code if $code;
    }
  }
}

sub super_method {
  my ( $self, $obj, $method ) = @_;
  my $class  = blessed( $obj );
  my $type   = $self->type( $obj );

  if ( $class ){
    my $uni = $self->class_method( UNIVERSAL => $method );
    if( $class eq 'UNIVERSAL' ) {

      return $self->type_method( $type => $method ) if $uni;

    }
    else {

      my $code = $self->super_class_method( $class, $method );
      return $code if $code;

      if( $self->runs_native ) {
        $code = _native_super( $class, $method );
        return $code if $code;
      }

      return $self->type_method( $type => $method ) if $uni;
    }
  }

  $self->super_type_method( $type => $method );
}


=item C<apply>

  $poly->apply( $obj => 'method' => $arg1, $arg1 , $arg3 .... );

Invokes a method which was defined.

=item C<super>

  $poly->super( $obj => 'method' => $arg1, $arg1 , $arg3 .... );

Invokes a super method which was defined..

=back

=cut


sub apply {
  my $self   = shift;
  my $obj    = $_[0];
  my $method = splice @_, 1, 1;
  goto (  $self->method( $obj => $method ) or
          sub{ confess sprintf( 'method "%s" is not defined in %s',
                                $method,
                                $self->class($obj)) });
}

sub super {
  my $self   = shift;
  my $obj    = $_[0];
  my $method = splice @_, 1, 1;
  goto (  $self->super_method( $obj => $method ) or
          sub{ confess sprintf( 'method "SUPER::%s" is not defined in %s',
                                $method,
                                $self->class($obj)) });
}

1; # End of Data::Polymorph

__END__

=head1 AUTHOR

lieutar, C<< <lieutar at 1dk.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-class-external-method at
rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Polymorph>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

and...

Even if I am writing strange English because I am not good at English, 
I'll not often notice the matter. (Unfortunately, these cases aren't
testable automatically.)

If you find strange things, please tell me the matter.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Polymorph


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Polymorph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Polymorph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Polymorph>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Polymorph>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 lieutar, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
