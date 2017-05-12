
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           Python Language Mapping Specification, Version 1.2 November 2002
#

package CORBA::Python::NameVisitor;

use strict;
use warnings;

our $VERSION = '2.64';

# builds $node->{py_name}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{python_keywords} = {        # Python 2.5
        'and'               => 1,
        'as'                => 1,
        'assert'            => 1,
        'break'             => 1,
        'class'             => 1,
        'continue'          => 1,
        'def'               => 1,
        'del'               => 1,
        'elif'              => 1,
        'else'              => 1,
        'except'            => 1,
        'exec'              => 1,
        'finally'           => 1,
        'for'               => 1,
        'from'              => 1,
        'global'            => 1,
        'if'                => 1,
        'import'            => 1,
        'in'                => 1,
        'is'                => 1,
        'lambda'            => 1,
        'not'               => 1,
        'or'                => 1,
        'pass'              => 1,
        'print'             => 1,
        'raise'             => 1,
        'return'            => 1,
        'try'               => 1,
        'while'             => 1,
        'with'              => 1,
        'yield'             => 1,
    };
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

sub _get_name {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{idf};
    if (exists $self->{python_keywords}->{$name}) {
        return '_' . $name;
    }
    else {
        return $name;
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self);
        }
    }
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
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{py_name});
    $node->{py_name} = $self->_get_name($node);
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{py_name});
    $node->{py_name} = $self->_get_name($node);
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
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
    $node->{py_name} = $self->_get_name($node);
}

sub visitExpression {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

#
#   3.11.1  Basic Types
#

sub visitBasicType {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{value};
    $name =~ s/ /_/g;
    $node->{py_name} = $name;
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{py_name});
    $node->{py_name} = $self->_get_name($node);
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{py_name});
    $node->{py_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
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
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = 'string';
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = 'wstring';
}

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    my $name = 'fixed';
    $node->{py_name} = $name;
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node) = @_;
    my $name = 'fixed';
    $node->{py_name} = $name;
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
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
    $node->{py_name} = $self->_get_name($node);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = q{};
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
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
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

sub visitUses {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

sub visitPublishes {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

sub visitEmits {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

sub visitConsumes {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitFinder {
    my $self = shift;
    my ($node) = @_;
    $node->{py_name} = $self->_get_name($node);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

1;

