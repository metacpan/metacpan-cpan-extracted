
package CORBA::XPIDL::NameVisitor;

use strict;
use warnings;

our $VERSION = '0.20';

# builds $node->{xp_name} for type

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{key} = 'xp_name';
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub _get_defn {
    my $self = shift;
    my ($defn) = @_;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self, 1);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self, 1);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    # empty
}

sub visitRegularInterface {
    my $self = shift;
    my ($node, $deep) = @_;
    return if (exists $node->{$self->{key}} and !defined $deep);
    $node->{$self->{key}} = $node->{idf} . ' *';
    return unless (defined $deep);
    foreach (@{$node->{list_export}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitForwardRegularInterface {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf} . ' *';
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{type})->visit($self);
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;

    $node->{$self->{key}} = $node->{idf};
    $self->_get_defn($node->{type})->visit($self);
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;

    if    (  $node->hasProperty('domstring')
            or $node->hasProperty('astring') ) {
        $node->{$self->{key}} = 'nsAString';
    }
    elsif ($node->hasProperty('utf8string')) {
        $node->{$self->{key}} = 'nsACString';
    }
    elsif ($node->hasProperty('cstring')) {
        $node->{$self->{key}} = 'nsACString';
    }
    else {
        $node->{$self->{key}} = $node->{native};
    }
    if    ($node->hasProperty('ptr')) {
        $node->{$self->{key}} .= ' *';
    }
    elsif ($node->hasProperty('ref')) {
        $node->{$self->{key}} .= ' &';
    }
}

#
#   3.11.1  Basic Types
#

sub visitBasicType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'unknown_type_' . ref $node;
}

sub visitFloatingPtType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'float') {
        $node->{$self->{key}} = 'float';
    }
    elsif ($node->{value} eq 'double') {
        $node->{$self->{key}} = 'double';
    }
    elsif ($node->{value} eq 'long double') {
        $node->{$self->{key}} = 'long double';
    }
    else {
        warn __PACKAGE__,"::visitFloatingPtType $node->{value}.\n";
    }
}

sub visitIntegerType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'short') {
        $node->{$self->{key}} = 'PRInt16';
    }
    elsif ($node->{value} eq 'unsigned short') {
        $node->{$self->{key}} = 'PRUint16';
    }
    elsif ($node->{value} eq 'long') {
        $node->{$self->{key}} = 'PRInt32';
    }
    elsif ($node->{value} eq 'unsigned long') {
        $node->{$self->{key}} = 'PRUint32';
    }
    elsif ($node->{value} eq 'long long') {
        $node->{$self->{key}} = 'PRInt64';
    }
    elsif ($node->{value} eq 'unsigned long long') {
        $node->{$self->{key}} = 'PRUint64';
    }
    else {
        warn __PACKAGE__,"::visitIntegerType $node->{value}.\n";
    }
}

sub visitCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'char';
}

sub visitWideCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'PRUnichar';
}

sub visitBooleanType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'PRBool';
}

sub visitOctetType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'PRUint8';
}

#
#   3.11.2  Constructed Types
#

sub visitStructType {
    # empty
}

sub visitUnionType {
    # empty
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    # empty
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    # empty
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'char *';
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'PRUnichar *';
}

sub visitFixedPtType {
    # empty
}

sub visitFixedPtConstType {
    # empty
}

#
#   3.12    Exception Declaration
#

sub visitException {
    # empty
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{type})->visit($self);
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = 'void';
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{type})->visit($self);
}

#
#   3.15    Repository Identity Related Declarations
#

sub visitTypeId {
    # empty
}

sub visitTypePrefix {
    # empty
}

1;

