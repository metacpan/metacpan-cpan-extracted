
=head1 NAME

Bio::Metabolic::Substrate - Perl extension for the description of biochemical substrates

=head1 SYNOPSIS

  use Bio::Metabolic::Substrate;

  my $sub1 = Bio::Metabolic::Substrate->new('Water');

  my $sub2 = Bio::Metabolic::Substrate->new('Oxygen', {o => 2});

=head1 DESCRIPTION

This class implements the object class representing Biochemical Compounds (Substrates) 
occurring in biochemical reactions.
Substrates must contain a name and arbitrary many attributes.

=head2 EXPORT

None

=head2 OVERLOADED OPERATORS

  String Conversion
    $string = "$substrate";
    print "\$substrate = '$substrate'\n";

  Equality
    if ($sub1 == $sub2)
    if ($sub1 != $sub2)

  Lexical comparison
    $cmp = $sub1 cmp $sub2;
    




=head1 AUTHOR

Oliver Ebenhöh, oliver.ebenhoeh@rz.hu-berlin.de

=head1 SEE ALSO

Bio::Metabolic.

=cut

package Bio::Metabolic::Substrate;

require 5.005_62;
use strict;
use warnings;

require Exporter;

#use AutoLoader qw(AUTOLOAD);

#use Math::Symbolic;
use Carp;

use overload
  "\"\"" => \&substrate_to_string,
  "=="   => \&equals,
  "!="   => \&not_equals,
  "cmp"  => \&compare_names;

our $VERSION = '0.06';

=head1 METHODS

=head2 Constructor new

First argument must specify the name. Second argument is a hash reference of 
key-value pairs defining the object attributes. Attributes are optional.

Upon creation, each substrate object gets associated with a variable 
(Math::Symbolic::Variable object) which is accessible by the accessor method
var(). The purpose for this is the automatic creation of ordinary differential
equation systems describing the dynamic behaviour of a metabolic system.

Returns a Bio::Metabolic::Substrate.

=cut

sub new {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);

    my $name = shift()
      || croak("no name has been provided for constructor new");

    my $attr = @_ ? shift() : {};

    my $self = {
        name => $name,

        #        var        => Math::Symbolic::Variable->new($name),
        attributes => $attr,
    };

    bless $self => $pkg;
}

=head2 Method copy

copy() returns a copy of the object. Attributes are cloned. The variable 
associated with the substrate (see var() below) is new defined and the value 
(if existing) is not copied.

=cut

sub copy {
    my $orig = shift;
    $orig = shift unless ref($orig);

    my %attr = %{ $orig->attributes };

    return $orig->new( $orig->name, \%attr );
}

=head2 Method name

Optional argument: sets the object's name. Returns the object's name.

=cut

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    return $self->{name};
}

=head2 Method attributes

Optional argument: sets the object's attributes. Returns the object's 
attributes.

=cut

sub attributes {
    my $self = shift;
    $self->{attributes} = shift if @_;
    return $self->{attributes};
}

=head2 Method var

Optional argument: sets the object's variable. Returns the object's 
variable (Math::Symbolic::Variable object).

=cut

#sub var {
#    my $self = shift;
#    $self->{var} = shift if @_;
#    return $self->{var};
#}

=head2 Method fix

Sets the value of the object's variable, thus fixing the substrate's 
concentration.

=cut

#sub fix {
#    my $self  = shift;
#    my $value = shift;

#    return $self->var->value($value);
#}

=head2 Method release

Sets the value of the object's variable to undef, thus releasing the substrate's
concentration.

=cut

#sub release {
#    shift->var->value(undef);
#}

=head2 Method get_attribute

Argument specifies the attribute name. Returns the attribute value or undef
if such an attribute does not exist.

=cut

sub get_attribute {
    my $self      = shift;
    my $attr_name = shift;

    return $self->attributes->{$attr_name};
}

=head2 Method substrate_to_string

Returns a readable string. The string consists of the object's attributes listed
in braces. If the object does not have any attributes, the string consists of
the object's name in square brackets.

=cut

sub substrate_to_string {
    my $substrate  = shift;
    my $attributes = $substrate->attributes;

    return "[" . $substrate->name . "]" unless keys(%$attributes);

    my $str = "{";
    foreach my $k ( keys(%$attributes) ) {
        $str .= "," if ( $str !~ /\{$/ );
        $str .= "'$k'=>$attributes->{$k}";
    }
    $str .= "}";
    return $str;
}

=head2 Method equals

Compares two substrates. If one of the substrates has attributes the set of 
attributes is compared. If both objects are without attributes, the names are
compared. Returns 1 upon equality, 0 otherwise.

=cut

sub equals {
    my ( $s1, $s2 ) = @_;
    my $sub1 = $s1->attributes;
    my $sub2 = $s2->attributes;

    my @sub1_keys = keys(%$sub1);
    my @sub2_keys = keys(%$sub2);

    return 0 if ( @sub1_keys != @sub2_keys );

    return ( $s1->name eq $s2->name ) unless @sub2_keys;

    my $k;
    foreach $k (@sub2_keys) {
        return 0 if ( !defined( $sub2->{$k} )
            || $sub2->{$k} ne $sub1->{$k} );
    }

    return 1;
}

=head2 Method not_equals

Compares two substrates. If one of the substrates has attributes the set of 
attributes is compared. If both objects are without attributes, the names are
compared. Returns 0 upon equality, 1 otherwise.

=cut

sub not_equals {
    return 1 - equals(@_);
}

=head2 Method is_empty

returns 1 if the object does not have any attributes

=cut

sub is_empty {
    my $substrate = shift->attributes;
    return keys(%$substrate) ? 0 : 1;
}

=head2 Method compare_names

Lexical comparison of the object names or optionally strings.

=cut

sub compare_names {
    my $s1 = shift;
    my $n1 = ref($s1) ? $s1->name : $s1;
    my $s2 = shift;
    my $n2 = ref($s2) ? $s2->name : $s2;
    return $n1 cmp $n2;
}

1;
__END__
