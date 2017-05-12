package Class::Fields::Fuxor;

use strict;
no strict 'refs';
use vars qw(@ISA @EXPORT $VERSION);

use Carp::Assert;

$VERSION = '0.06';

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(add_fields 
             add_field_set
             has_fields 
             get_fields 
             get_attr 
             has_attr
            );


use constant TRUE       => (1==1);
use constant FALSE      => !TRUE;
use constant SUCCESS    => TRUE;
use constant FAILURE    => !SUCCESS;

use Class::Fields::Attribs;

=pod

=head1 NAME

  Class::Fields::Fuxor - Low level manipuation of object data members

=head1 SYNOPSIS

  # As functions.
  use Class::Fields::Fuxor;
  add_fields($class, $attrib, @fields);
  add_field_set($class, \@fields, \@attribs);
  has_fields($class);
  $fields = get_fields($class);
  $fattr  = get_attr($class);


  # As methods.
  package Foo;
  use base qw( Class::Fields::Fuxor );

  Foo->add_fields($attrib, @fields);
  Foo->has_fields;
  $fields   = Foo->get_fields;
  $fattr    = Foo->get_attr;
  

=head1 DESCRIPTION

This is a module for low level manipuation of the %FIELDS hash and its
accompying %fields::attr hash without actually touching them.  Modules
like fields.pm, base.pm and public.pm make use of this module.

%FIELDS and %fields::attr are currently used to store information
about the data members of classes.  Since the current data inheritance
system, built around pseudo-hashes, is considered a bit twitchy, it is
wise to encapsulate and rope it off in the expectation that it will be
replaced with something better.

Typically one does not want to mess with this stuff and instead uses
fields.pm and friends or perhaps Class::Fields.

=cut


# The %attr hash holds the attributes of the currently assigned fields
# per class.  The hash is indexed by class names and the hash value is
# an array reference.  The array is indexed with the field numbers
# (minus one) and the values are integer bit masks (or undef).  The
# size of the array also indicates the next field index to assign for
# additional fields in this class.
#
# BTW %attr is part of fields for legacy reasons.  We alias it here to make
# life easier.
use vars qw(%attr);
*attr = \%fields::attr;

=pod

=over 4

=item B<add_fields>

  add_fields($class, $attrib, @fields);

Adds a bunch of @fields to the given $class using the given $attrib.
For example:

    # Add the public fields 'this' and 'that' to the class Foo.
    use Class::Fields::Attribs;
    add_fields('Foo', PUBLIC, qw(this that));

$attrib is built from the constants in Class::Fields::Attribs

=cut

sub add_fields {
    my($proto, $attrib, @fields) = @_;
    add_field_set($proto, \@fields, [($attrib) x @fields]);
}

=pod

=item B<add_field_set>

  add_field_set($class, \@fields, \@attribs);

Functionally similar to add_fields(), excepting that it can add a
group of fields with different attributes all at once.  This is
necessary for the proper functioning of fields.pm.

Each element in @fields matches up with one in @attribs.  Obviously,
the two arrays must be the same size.

=cut

sub add_field_set {
    # Read the first two parameters.  The rest are field names.
    my($proto, $new_fields, $new_attribs) = @_;

    assert(@$new_fields == @$new_attribs) if DEBUG;

    # Quick bail out if nothing is to be added.
    return SUCCESS unless @$new_fields;

    my($class) = ref $proto || $proto;
        
    my $fields = get_fields($class);
    my $fattr  = get_attr($class);
    my $next_fno = @$fattr;


    # Check for existing fields not belonging to base classes.
    # Indicates a possible module reload.
    if ($next_fno > $fattr->[0]
	and ($fields->{$new_fields->[0]} || 0) >= $fattr->[0])
    {
        # Reset the next pointer to let the reload work.
	$next_fno = $fattr->[0];
    }

    # Go through the fields and attach attributes.
    foreach my $idx (0..$#{$new_fields}) {
        my $f      = $new_fields->[$idx];
        my $attrib = $new_attribs->[$idx];
        my $fno = $fields->{$f};

        # Allow the module to be reloaded so long as field positions
        # have not changed.
        if ($fno and $fno != $next_fno) {
            require Carp;
            if ($fno < $fattr->[0]) {
                Carp::carp("Hides field '$f' in base class") if $^W;
            } else {
                Carp::croak("Field name '$f' already in use");
            }
        }
        $fields->{$f} = $next_fno;
        $fattr->[$next_fno] = $attrib;
        $next_fno++;
    }
}


=item B<has_fields>

  has_fields($class);

A simple check to see if the given $class has a %FIELDS hash defined.
A simple test like (defined %{"$class\::FIELDS"}) will sometimes
produce typo warnings because it would create the hash if it was not
present before.

=cut

sub has_fields {
    my($proto) = shift;
    my($class) = ref $proto || $proto;
    my $fglob;
    return ($fglob = ${"$class\::"}{"FIELDS"} and *$fglob{HASH}) ? TRUE
                                                                 : FALSE;
}

=item B<has_attr>

  has_attr($class);

A simple check to see if the given $class has attributes.

=cut

sub has_attr {
    my($proto) = shift;
    my($class) = ref $proto || $proto;
    return exists $attr{$class};
}

=item B<get_attr>

  $fattr = get_attr($class);

Get's the field attribute array for the given $class.  This is roughly
equivalent to $fields::attr{$class} but we put a nice wrapper around
it for compatibility and readability.

$fattr is an array reference containing the attributes of the fields
in the given $class.  Each entry in $fattr corresponds to the position
indicated by the $class's %FIELDS has.  For example:

    package Foo;
    use fields qw(this _that);

    $fattr = get_attr('Foo');

    # Get the attributes for '_that' in the class 'Foo'.
    $that_attribs = print $fattr->[$Foo::FIELDS->{_that}];

When possible, one should avoid using this function since it exposes
more implementation detail than I'd like.  Class::Fields
should provide most of the functionality you'll need.

=cut

sub get_attr {
    my($proto) = shift;
    my($class) = ref $proto || $proto;
    unless ( defined $attr{$class} ) {
        $attr{$class} = [1];
    }
    return $attr{$class};
}

=pod

=item B<get_fields>

  $fields = get_fields($class);

Gets a reference to the %FIELDS hash for the given $class.  It will
autogenerate a %FIELDS hash if one doesn't already exist.  If you
don't want this behavior, be sure to check beforehand with
has_fields().

When possible, one should avoid using this function since it exposes
more implementation detail than I'd like.  Class::Fields
should provide most of the functionality you'll need.

=cut

sub get_fields {
    my($proto) = shift;
    my($class) = ref $proto || $proto;

    # Shut up a possible typo warning.
    () = \%{$class.'::FIELDS'};

    return \%{$class.'::FIELDS'};
}

=pod

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> based heavily on code liberated
from the original fields.pm and base.pm.


=head1 SEE ALSO

L<fields>, L<base>, L<public>, L<private>, L<protected>,
L<Class::Fields>, L<Class::Fields::Attribs>

=cut

return 'Maybe we should have stopped with Smalltalk.';
