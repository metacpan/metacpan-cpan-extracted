
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Perl::LiteralVisitor;

use strict;
use warnings;

our $VERSION = '0.40';

# builds $node->{pl_literal}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{key} = 'pl_literal';
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub visitType {
    my $self = shift;
    my ($type) = @_;

    if (ref $type) {
        $type->visit($self);
    }
    else {
        $self->{symbtab}->Lookup($type)->visit($self);
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
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = 1;
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

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type});    # type_spec
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);           # expression
        }
    }
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
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

sub _Eval {
    my $self = shift;
    my ($list_expr, $type) = @_;
    my $elt = pop @{$list_expr};
    unless (ref $elt) {
        $elt = $self->{symbtab}->Lookup($elt);
    }
    if (    $elt->isa('BinaryOp') ) {
        my $right = $self->_Eval($list_expr, $type);
        my $left = $self->_Eval($list_expr, $type);
        return '(' . $left . q{ } . $elt->{op} . q{ } . $right . ')';
    }
    elsif ( $elt->isa('UnaryOp') ) {
        my $right = $self->_Eval($list_expr, $type);
        return $elt->{op} . $right;
    }
    elsif ( $elt->isa('Constant') ) {
        return $elt->{pl_package} . '::' . $elt->{pl_name} . '()';
    }
    elsif ( $elt->isa('Enum') ) {
        return $elt->{pl_name};
    }
    elsif ( $elt->isa('Literal') ) {
        $elt->visit($self, $type);
        return $elt->{$self->{key}};
    }
    else {
        warn __PACKAGE__,"::_Eval: INTERNAL ERROR ",ref $elt,".\n";
        return undef;
    }
}

sub visitExpression {
    my $self = shift;
    my ($node) = @_;
    my @list_expr = @{$node->{list_expr}};      # create a copy
    $node->{$self->{key}} = $self->_Eval(\@list_expr, $node->{type});
}

sub visitIntegerLiteral {
    my $self = shift;
    my ($node, $type) = @_;
    my $str = $node->{value};
    $str =~ s/^\+//;
    $node->{$self->{key}} = $str;
}

sub visitStringLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C*', $node->{value};
    my $str = q{"};
    foreach (@list) {
        if ($_ < 32 or $_ >= 128) {
            $str .= sprintf "\\x%02x", $_;
        }
        else {
            $str .= chr $_;
        }
    }
    $str .= q{"};
    $node->{$self->{key}} = $str;
}

sub visitWideStringLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C*', $node->{value};
    my $str = q{L"};
    foreach (@list) {
        if ($_ < 32 or ($_ >= 128 and $_ < 256)) {
            $str .= sprintf "\\x%02x", $_;
        }
        elsif ($_ >= 256) {
            $str .= sprintf "\\x{%04x}", $_;
        }
        else {
            $str .= chr $_;
        }
    }
    $str .= q{"};
    $node->{$self->{key}} = $str;
}

sub visitCharacterLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C', $node->{value};
    my $c = $list[0];
    my $str = q{"};
    if ($c < 32 or $c >= 128) {
        $str .= sprintf "\\x%02x", $c;
    }
    else {
        $str .= chr $c;
    }
    $str .= q{"};
    $node->{$self->{key}} = $str;
}

sub visitWideCharacterLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C', $node->{value};
    my $c = $list[0];
    my $str = q{L"};
    if ($c < 32 or ($c >= 128 and $c < 256)) {
        $str .= sprintf "\\x%02x", $c;
    }
    elsif ($c >= 256) {
        $str .= sprintf "\\x{%04x}", $c;
    }
    else {
        $str .= chr $c;
    }
    $str .= q{"};
    $node->{$self->{key}} = $str;
}

sub visitFixedPtLiteral {
    my $self = shift;
    my ($node) = @_;
    my $str = q{'};
    $str .= $node->{value};
    $str .= q{'};
    $node->{$self->{key}} = $str;
}

sub visitFloatingPtLiteral {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{value};
}

sub visitBooleanLiteral {
    my $self = shift;
    my ($node) = @_;
    if ($node->{value} eq 'TRUE') {
        $node->{$self->{key}} = '1';
    }
    else {
        $node->{$self->{key}} = q{""};
    }
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);           # expression
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

sub visitAnyType {
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
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = 1;
    foreach (@{$node->{list_member}}) {
        $self->visitType($_);           # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);               # expression
        }
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = 1;
    $self->visitType($node->{type});
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);               # case
    }
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_label}}) {
        $_->visit($self);               # default or expression
    }
    $node->{element}->visit($self);
}

sub visitDefault {
    # empty
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{value});   # member
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);               # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    $node->{$self->{key}} = $node->{idf};
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type});
    $node->{max}->visit($self) if (exists $node->{max});
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{max}->visit($self) if (exists $node->{max});
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{max}->visit($self) if (exists $node->{max});
}

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{d}->visit($self);
    $node->{s}->visit($self);
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
    foreach (@{$node->{list_member}}) {
        $self->visitType($_);           # member
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type});    # param_type_spec or void
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type});    # param_type_spec
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
    $self->visitType($node->{type});    # param_type_spec
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
#   3.16    Event Declaration
#

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
        $_->visit($self);               # parameter
    }
}

sub visitFinder {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
}

1;

