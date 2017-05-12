
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           Python Language Mapping Specification, Version 1.2 November 2002
#

package CORBA::Python::ImportVisitor;

use strict;
use warnings;

our $VERSION = '2.64';

use File::Basename;

# builds $node->{py_import}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $cpy_ext) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{module} = undef;
    $self->{cpy_ext} = $cpy_ext;
    my $basename = basename($parser->YYData->{srcname}, '.idl');
    $basename =~ s/\./_/g;
    $self->{root_module} = 'c_' . $basename;
    return $self;
}

sub _get_defn {
    my $self = shift;
    my $defn = shift;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

sub _import {
    my $self = shift;
    my ($node, $flag_c) = @_;
    my $full = $node->{full};
    while (!$node->isa('Modules')) {
        $full =~ s/::[0-9A-Z_a-z]+$//;
        last unless ($full);
        $node = $self->{symbtab}->Lookup($full);
    }
    if ($flag_c) {
        if ($full) {
            my @name = split /::/, $full;
            $name[-1] = 'c' . $name[-1];
            $full = join '::', @name;
        }
        else {
            $full = $self->{root_module};
        }
        $self->{module}->{py_import}->{$full} = 1;
        return;
    }
    unless ($full eq $self->{module}->{full}) {
        $self->{module}->{py_import}->{$full} = 1;
        if ($full =~ /^$self->{module}->{full}/) {
            warn "possible circular import ($full in $self->{module}->{full}).\n";
        }
    }
}

sub _import_type {
    my $self = shift;
    my ($type) = @_;
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType')
            or $type->isa('TypeDeclarator')
            or $type->isa('BaseInterface') ) {
        $self->_import($type);
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    $node->{py_import} = {};
    $self->{module} = $node;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.6     Import Declaration
#

sub visitImport {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    $node->{py_import} = {};
    my $save_module = $self->{module};
    $self->{module} = $node;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
    $self->{module} = $save_module;
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    if ($self->{cpy_ext}) {
        $self->_import($node, 1);
    }
    foreach ($node->getInheritance()) {
        my $base = $self->_get_defn($_);
        $self->_import($base);
    }
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.9     Value Declaration
#

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
}

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self, $node);            # expression
        }
    }
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{value}->visit($self);       # expression
}

sub visitExpression {
    my $self = shift;
    my ($node) = @_;
    foreach my $elt (@{$node->{list_expr}}) {
        unless (ref $elt) {
            $elt = $self->{symbtab}->Lookup($elt);
        }
        if ($elt->isa('Constant')) {
            $self->_import($elt);
        }
    }
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self, $node);            # expression
        }
    }
}

sub visitNativeType {
    # empty
}

#
#   3.11.1  Basic Types
#

sub visitBasicType {
    # empty
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self, $type);                # expression
        }
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # case
    }
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_label}}) {
        $_->visit($self);           # default or expression
    }
    $node->{element}->visit($self);
}

sub visitDefault {
    # empty
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{value})->visit($self);     # member
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
    # empty
}

sub visitWideStringType {
    # empty
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
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{list_member}) {
        foreach (@{$node->{list_member}}) {
            $self->_get_defn($_)->visit($self);     # member
        }
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $self->_import_type($type);
}

sub visitVoidType {
    # empty
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $node->{_get}->visit($self);
    $node->{_set}->visit($self) if (exists $node->{_set});
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

#
#   3.17    Component Declaration
#

sub visitProvides {
    # empty
}

sub visitUses {
    # empty
}

sub visitPublishes {
    # empty
}

sub visitEmits {
    # empty
}

sub visitConsumes {
    # empty
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitFinder {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

1;

