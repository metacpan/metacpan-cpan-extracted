# $Id$ 

package Class::Fields;

use strict;
no strict 'refs';

use vars qw(@ISA @EXPORT $VERSION);
require Exporter;
@ISA = qw(Exporter);

# is_* will push themselves onto @EXPORT
@EXPORT = qw( field_attrib_mask
              field_attribs
              dump_all_attribs
              show_fields
              is_public
              is_private
              is_protected
              is_inherited
              is_field
            );

$VERSION = '0.204';

use Class::Fields::Fuxor;
use Class::Fields::Attribs;

# Mapping of attribute names to their internal values.
use vars qw(%NAMED_ATTRIBS);
BEGIN {
    %NAMED_ATTRIBS = (
                      Public    =>  PUBLIC,
                      Private   =>  PRIVATE,
                      Inherited =>  INHERITED,
                      Protected =>  PROTECTED,
                     );
}

=pod

=head1 NAME

Class::Fields - Inspect the fields of a class.


=head1 SYNOPSIS

    use Class::Fields;

    is_field    ($class, $field);
    is_public   ($class, $field);
    is_private  ($class, $field);
    is_protected($class, $field);
    is_inherited($class, $field);

    @fields = show_fields($class, @attribs);

    $attrib     = field_attrib_mask($class, $field);
    @attribs    = field_attribs($class, $field);

    dump_all_attribs(@classes);


    # All functions also work as methods.
    package Foo;
    use base qw( Class::Fields );

    Foo->is_public($field);
    @fields = Foo->show_fields(@attribs);
    # ...etc...


=head1 DESCRIPTION

B<NOTE> This module, and the fields system, is largely obsolete.
Please consider using one of the many accessor generating modules, or
just skip directly to a complete object oriented system like L<Moose>
or L<Mouse>.

A collection of utility functions/methods for examining the data
members of a class.  It provides a nice, high-level interface that
should stand the test of time and Perl upgrades nicely.

The functions in this module also serve double-duty as methods and can
be used that way by having your module inherit from it.  For example:

    package Foo;
    use base qw( Class::Fields );
    use fields qw( this that _whatever );

    print "'_whatever' is a private data member of 'Foo'" if
        Foo->is_private('_whatever');

    # Let's assume we have a new() method defined for Foo, okay?
    $obj = Foo->new;
    print "'this' is a public data member of 'Foo'" if
        $obj->is_public('this');

=over 4

=item B<is_field>

  is_field($class, $field);
  $class->is_field($field);

Simply asks if a given $class has the given $field defined in it.

=cut

sub is_field {
    my($proto, $field) = @_;

    my($class) = ref $proto || $proto;
    return defined field_attrib_mask($class, $field) ? 1 : 0;
}

=pod

=item B<is_public>

=item B<is_private>

=item B<is_protected>

=item B<is_inherited>

  is_public($class, $field);
  is_private($class, $field);
  ...etc...
        or
  $obj->is_public($field);
        or
  Class->is_public($field);

A bunch of functions to quickly check if a given $field in a given $class
is of a given type.  For example...

  package Foo;
  use public  qw( Ford   );
  use private qw( _Nixon );

  package Bar;
  use base qw(Foo);

  # This will print only 'Ford is public' because Ford is a public
  # field of the class Bar.  _Nixon is a private field of the class
  # Foo, but it is not inherited.
  print 'Ford is public'        if is_public('Bar', 'Ford');
  print '_Nixon is inherited'   if is_inherited('Foo', '_Nixon');


=cut

# Generate is_public, etc... from %NAMED_ATTRIBS For each attribute we
# generate a simple named closure.  Seemed the laziest way to do it,
# lets us update %NAMED_ATTRIBS without having to make a new function.
while ( my($attrib, $attr_val) = each %NAMED_ATTRIBS ) {
    no strict 'refs';
    my $fname = 'is_'.lc $attrib;
    *{$fname} = sub {
        my($proto, $field) = @_;
        
        # So we can be called either as a function or a method from
        # a class name or an object.
        my($class) = ref $proto || $proto;
        my $fattrib = field_attrib_mask($class, $field);
        
        return unless defined $fattrib;
        
        return $fattrib & $attr_val;
    };
      
    push @EXPORT, $fname;
}


=pod

=item B<show_fields>

  @all_fields   = show_fields($class);
  @fields       = show_fields($class, @attribs);
        or
  @all_fields   = $obj->show_fields;
  @fields       = $obj->show_fields(@attribs);
        or
  @all_fields   = Class->show_fields;
  @fields       = Class->show_fields(@attribs);

This will list all fields in a given $class that have the given set of
@attribs.  If @attribs is not given it will simply list all fields.

The currently available attributes are:
    Public, Private, Protected and Inherited

For example:

    package Foo;
    use fields qw(this that meme);

    package Bar;
    use Class::Fields;
    use base qw(Foo);
    use fields qw(salmon);

    # @fields contains 'this', 'that' and 'meme' since they are Public and
    # Inherited.  It doesn't contain 'salmon' since while it is
    # Public it is not Inherited.
    @fields = show_fields('Bar', qw(Public Inherited));

=cut

sub show_fields {
    my($proto, @attribs) = @_;

    # Allow its tri-nature.
    my($class) = ref $proto || $proto;

    return unless has_fields($class);

    my $fields  = get_fields($class);

    # Shortcut:  Return all fields if they don't specify a set of
    # attributes.
    return keys %$fields unless @attribs;
    
    # Figure out the bitmask for the attribute set they'd like.
    my $want_attr = 0;
    foreach my $attrib (@attribs) {
        unless( defined $NAMED_ATTRIBS{$attrib} ) {
            require Carp;
            Carp::croak("'$attrib' is not a valid field attribute");
        }
        $want_attr |= $NAMED_ATTRIBS{$attrib};
    }

    # Return all fields with the requested bitmask.
    my $fattr   = get_attr($class);
    return grep { ($fattr->[$fields->{$_}] & $want_attr) == $want_attr} 
                keys %$fields;
}

=pod

=item B<field_attrib_mask>

  $attrib = field_attrib_mask($class, $field);
        or
  $attrib = $obj->field_attrib_mask($field);
        or
  $attrib = Class->field_attrib_mask($field);

It will tell you the numeric attribute for the given $field in the
given $class.  $attrib is a bitmask which must be interpreted with
the PUBLIC, PRIVATE, etc... constants from Class::Fields::Attrib.

field_attribs() is probably easier to work with in general.

=cut

sub field_attrib_mask {
    my($proto, $field) = @_;
    my($class) = ref $proto || $proto;
    my $fields  = get_fields($class);
    my $fattr   = get_attr($class);
    return unless defined $fields->{$field};
    return $fattr->[$fields->{$field}];
}

=pod

=item B<field_attribs>

  @attribs = field_attribs($class, $field);
        or
  @attribs = $obj->field_attribs($field);
        or
  @attribs = Class->field_attribs($field);

Exactly the same as field_attrib_mask(), except that instead of
returning a bitmask it returns a somewhat friendlier list of
attributes which are applied to this field.  For example...

  package Foo;
  use fields qw( yarrow );

  package Bar;
  use base qw(Foo);

  # @attribs will contain 'Public' and 'Inherited'
  @attribs = field_attribs('Bar', 'yarrow');

The attributes returned are the same as those taken by show_fields().

=cut

sub field_attribs {
    my($proto, $field) = @_;
    my($class) = ref $proto || $proto;

    my @attribs = ();
    my $attr_mask = field_attrib_mask($class, $field);
    
    while( my($attr_name, $attr_val) = each %NAMED_ATTRIBS ) {
        push @attribs, $attr_name if $attr_mask & $attr_val;
    }

    return @attribs;
}

=pod

=item B<dump_all_attribs>

  dump_all_attribs;
  dump_all_attribs(@classes);
        or
  Class->dump_all_attribs;
        or
  $obj->dump_all_attribs;

A debugging tool which simply prints to STDERR everything it can about
a given set of @classes in a relatively formated manner.

Alas, this function works slightly differently if used as a function
as opposed to a method:

When called as a function it will print out attribute information
about all @classes given.  If no @classes are given it will print out
the attributes of -every- class it can find that has attributes.

When uses as a method, it will print out attribute information for the
class or object which uses the method.  No arguments are accepted.

I'm not entirely happy about this split and I might change it in the
future.

=cut

# Backwards compatiblity.
*_dump = \&dump_all_attribs;

#'#
sub dump_all_attribs {
    my @classes = @_;

    # Everything goes to STDERR.
    my $old_fh = select(STDERR);

    # Disallow $obj->dump_all_attribs(@classes);  Too ambiguous to live.
    # Alas, I can't check for Class->dump_all_attribs(@classes).
    if ( @classes > 1 and ref $classes[0] ) {
        require Carp;
        Carp::croak('$obj->dump_all_attribs(@classes) is too ambiguous.'.
                    'Use only as $obj->dump_all_attribs()');
    }

    # Allow $obj->dump_all_attribs; to work.
    $classes[0] = ref $classes[0] || $classes[0] if @classes == 1;

    # Have to do a little encapsulation breaking here.  Oh well, at least
    # its keeping it in the family.
    @classes = sort keys %fields::attr unless @classes;

    for my $class (@classes) {
        print "\n$class";
        if (@{"$class\::ISA"}) {
            print " (", join(", ", @{"$class\::ISA"}), ")";
        }
        print "\n";
        my $fields = get_fields($class);
        for my $f (sort {$fields->{$a} <=> $fields->{$b}} keys %$fields) {
            my $no = $fields->{$f};
            print "   $no: $f";
            print "\t(", join(", ", field_attribs($class, $f)), ")";
            print "\n";
        }
    }
        
    select($old_fh);
}

=pod

=head1 EXAMPLES

Neat tricks that can be done with this module:

=over 4

=item An integrity check for your object.

Upon destruction, check to make sure no strange keys were added to
your object hash.  This is a nice check against typos and other
modules sticking their dirty little fingers where they shouldn't be
if you're not using a pseudo-hash.

    sub DESTROY {
        my($self) = @_;
        my($class) = ref $self;

        my %fields = map { ($_,1) } $self->show_fields;
        foreach my $key ( keys %$self ) {
            warn "Strange key '$key' found in object '$self' ".
                  "of class '$class'" unless
                exists $fields{$key};
        }
    }

=item Autoloaded accessors for public data members.

Proper OO dogma tells you to do all public data access through
accessors (methods who's sole purpose is to get and set data in your
object).  This can be a royal pain in the ass to write and can also
get rapidly unmaintainable since you wind up with a series of nearly
identical methods.

*Perfect* for an autoloader!

    package Test::Autoload::Example;
    use base qw(Class::Fields);
    use public qw(this that up down);
    use private qw(_left _right);

    sub AUTOLOAD {
        my $self = $_[0];
        my $class = ref $self;

        my($field) = $AUTOLOAD =~ /::([^:]+)$/;

        return if $field eq 'DESTROY';

        # If its a public field, set up a named closure as its
        # data accessor.
        if ( $self->is_public($field) ) {
            *{$class."::$field"} = sub {
                my($self) = shift;
                if (@_) {
                    $self->{$field} = shift;
                }
                return $self->{$field};
            };
            goto &{$class."::$field"};
        } else {
            die "'$field' is not a public data member of '$class'";
        }
    }

L<Class::Accessor/EXAMPLES> for a much simpler version of this same
technique.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2001-2011 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with much code liberated from the
original fields.pm.


=head1 THANKS

Thanks to Tels for his big feature request/bug report.


=head1 SEE ALSO

This module and the L<fields> system are obsolete.
L<Moose>, L<Mouse>, L<Class::Accessor> are better alternatives.

L<fields>, L<public>, L<private>, L<protected>

Modules with similar effects... L<Tie::SecureHash>

=cut

return q|I'll get you next time, Gadget!|;
