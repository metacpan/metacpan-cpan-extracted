package Class::ObjectTemplate::DB;
use Class::ObjectTemplate 0.5;
use Carp;
use strict;
no strict 'refs';
require Exporter;

use vars qw(@ISA @EXPORT $VERSION $DEBUG);

@ISA = qw(Class::ObjectTemplate Exporter);
@EXPORT = qw(attributes);
$VERSION = 0.27;

$DEBUG = 0; # assign 1 to it to see code generated on the fly 

# JES -- Added to be able to turn automatic lookup on and off at
# method definition time. Set this to be true before calling
# attributes and the getter method will call undefined() if the
# current value is 'undef'.

# Create accessor functions, and new()
#
# attributes(lookup => ['foo', 'bar'], no_lookup => ['baz'])
# attributes('foo', 'bar', 'baz')
#
sub attributes {
    my ($pkg) = caller;

    croak "Error: attributes() invoked multiple times" 
      if scalar @{"${pkg}::_ATTRIBUTES_"};

    my %args;
    # figure out if we were called with a simple parameter list
    # or with a hash-style parameter list
    if (scalar @_) {
      if (scalar @_ % 2 == 0 &&
	  ($_[0] eq 'lookup' || $_[0] eq 'no_lookup') &&
	  ref($_[1]) eq 'ARRAY') {
	# we were called with hash style parameters
	%args = @_;
      } else {
	# we were called with a simple parameter list
	%args = ('no_lookup' => [@_]);
      }
    }
    my $lookup;

    #
    # We must define a constructor for the class, because we must
    # declare the variables used for the free list, $_max_id and
    # @_free. If we don't, we will get compile errors for any class
    # that declares itself a subclass of any Class::ObjectTemplate
    # class
    #
    print STDERR "defining constructor for $pkg\n" if $DEBUG;
    my $code .= Class::ObjectTemplate::_define_constructor($pkg);

    print STDERR "Creating methods for $pkg\n" if $DEBUG;
    foreach my $key (keys %args) {
      push(@{"${pkg}::_ATTRIBUTES_"},@{$args{$key}});

      # set up the $lookup boolean
      $lookup = ($key eq 'lookup');
      foreach my $attr (@{$args{$key}}) {
	print STDERR "  defining method $attr\n" if $DEBUG;

        # If a field name is "color", create a global list in the
        # calling package called @_color
        @{"${pkg}::_$attr"} = ();

        # If the accessor is already present, give a warning
        if (UNIVERSAL::can($pkg,"$attr")) {
	  carp "$pkg already has method: $attr";
	} else {
	  $code .= _define_accessor ($pkg, $attr, $lookup);
	}
      }
    }

    eval $code;
    if ($@) {
       die  "ERROR defining constructor and attributes for '$pkg':\n"
            . "\t$@\n"
            . "-----------------------------------------------------"
            . $code;
    }
}

sub _define_accessor {
    my ($pkg, $attr, $lookup) = @_;

    # This code creates an accessor method for a given
    # attribute name. This method  returns the attribute value
    # if given no args, and modifies it if given one arg.
    # Either way, it returns the latest value of that attribute

    # in ObjectTemplate::DB, if the getter is called and the current
    # value of the attribute is undef, then the classes undefined()
    # method will be invoked with the name of the attribute.

    my $code;
    if ($lookup) {
      # If we are to do automatic lookup when the current value
      # is undefined, we need to be complicated
      $code = <<"CODE";
package $pkg;
sub $attr {                                       # Accessor ...
    my \$name = ref(\$_[0]) . "::_$attr";
    return \$name->[\${\$_[0]}] = \$_[1] if \@_ > 1; # set
    return \$name->[\${\$_[0]}] 
         if defined \$name->[\${\$_[0]}];     # get
    # else call undefined(), and give it a change to define
    return \$name->[\${\$_[0]}] = \$_[0]->undefined('$attr');
}
CODE
    } else {
      # if we don't need to do lookup, it's short and sweet
      $code = <<"CODE";
package $pkg;
sub $attr {                                      # Accessor ...
    my \$name = ref(\$_[0]) . "::_$attr";
    \@_ > 1 ? \$name->[\${\$_[0]}] = \$_[1]  # set
            : \$name->[\${\$_[0]}];          # get
}
CODE
    }
  return $code;
}

# JES
# default function for lookup. Does the obvious
sub undefined {return undef;}
1;

__END__

=head1 NAME

Class::ObjectTemplate:DB - Perl extension for an optimized template
builder base class with lookup capability.

=head1 SYNOPSIS

  package Foo;
  use Class::ObjectTemplate::DB;
  require Exporter;
  @ISA = qw(Class::ObjectTemplate:DB Exporter);

  attributes(lookup => ['one', 'two'], no_lookup => ['three']);

  $foo = Foo->new();

  # these two invocations can trigger lookup
  $val = $foo->one();
  $val = $foo->two();

  # this invocation will not trigger lookup
  $val = $foo->three();

  # undefined() handles lookup
  sub Foo::undefined {
    my ($self,$attr) = @_;

    # we retrieve $attr from DB
    return DB_Lookup($self,$attr);
  }


=head1 DESCRIPTION

Class::ObjectTemplate::DB extends Class::ObjectTemplate in one simple
way: the C<undefined()> method.

When a class that inherits from Class::ObjectTemplate::DB defines a
method called undefined(), that method will be triggered when an
attribute\'s getter method is invoked and the attribute\'s current
value is C<undef>.

The author finds this useful when representing classes based on
objects stored in databases (hence the name of the module). That way
an object can be created, without triggering a DB lookup. Later if
data is accessed and it is not currently present in the object, it can
be retrieved on an as-need basis.

=head2 METHODS

=over

=item attributes('attr1', 'attr2')

=item attributes(lookup => ['attr1'], no_lookup => ['attr2'])

C<attributes()> still supports the standard Class::ObjectTemplate
syntax of a list of attribute names.

To use the new functionality, the new key-value syntax must be
used. Any method names specified in the C<lookup> array, will trigger
undefined. Those specified in the C<no_lookup> will not trigger
C<undefined()>.

=item undefined($self, $attr_name)

A class that inherits from Class::ObjectTemplate::DB must define a
method called C<undefined()> in order to utilize the lookup behavior. 

Whenever an attribute\'s getter method is invoked, and that
attribute\'s value is currently C<undef>, then C<undefined()> will be
invoked if that attribute was defined as in the C<lookup> array when
C<attributes()> was called.

A class\'s C<undefined()> method can include any specialized code
needed to lookup the value for that objects\'s attribute, such as
using DBI to connect to a local DB, and retrieve the value from a
table.

Class::ObjectTemplate::DB defines a default C<undefined()> which does
nothing.

=back

=head2 EXPORT

=item attributes()

=head1 AUTHOR

Jason E. Stewart (jason@openinformatics.com)

=head1 SEE ALSO

perl(1).

=cut
