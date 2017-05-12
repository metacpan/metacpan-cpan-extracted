
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C++ Language Mapping Specification, New Edition June 1999
#

package CORBA::Cplusplus::LengthVisitor;

use strict;
use warnings;

our $VERSION = '0.40';

use CORBA::C::LengthVisitor;
use base qw(CORBA::C::LengthVisitor);

# builds $node->{length}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{done_hash} = {};
    $self->{key} = 'cpp_name';
    return $self;
}

#   See 1.9     Mapping for Structured Types
#

sub _get_length {
    my $self = shift;
    my ($type) = @_;
    if (       $type->isa('AnyType')
            or $type->isa('SequenceType')
            or $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('ObjectType')
            or $type->isa('RegularValue')
            or $type->isa('BoxedValue')
            or $type->isa('AbstractValue') ) {
        return 'variable';
    }
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('TypeDeclarator') ) {
        return $type->{length};
    }
    return undef;
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{length});
    $node->{length} = 'variable';
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{length});
    $node->{length} = 'variable';
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $self->_get_defn($_->{type})->visit($self);
    }
}

1;

