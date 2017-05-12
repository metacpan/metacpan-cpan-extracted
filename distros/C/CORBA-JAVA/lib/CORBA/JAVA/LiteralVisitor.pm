
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           IDL to Java Language Mapping Specification, Version 1.2 August 2002
#

package CORBA::JAVA::LiteralVisitor;

use strict;
use warnings;

our $VERSION = '2.62';

# needs $node->{java_name} (JavaNameVisitor) for Enum
# builds $node->{java_literal}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{key} = 'java_literal';
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
    foreach (@{$node->{list_export}}) {
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
    shift->visitMember(@_);
}

sub visitInitializer {
    shift->visitOperation(@_);
}

sub visitBoxedValue {
    shift->visitTypeDeclarator(@_);
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    my $defn;
    my $pkg = $node->{full};
    $pkg =~ s/::[0-9A-Z_a-z]+$//;
    $defn = $self->{symbtab}->Lookup($pkg) if ($pkg);
    if ( defined $defn and $defn->isa('BaseInterface') ) {
        $node->{$self->{key}} = $node->{java_Name};
    }
    else {
        $node->{$self->{key}} = $node->{java_Name} . '.value';
    }
    $node->{value}->visit($self);       # expression
    $self->_get_defn($node->{type})->visit($self);
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
        return $elt->{java_Name};
    }
    elsif ( $elt->isa('Enum') ) {
        return $elt->{java_Name};
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
    my $type = $node->{type};
    my $str = $self->_Eval(\@list_expr, $type);
    my $cast = q{};
    if (ref $type) {
        while (     $type->isa('TypeDeclarator')
                and ! exists $type->{array_size} ) {
            $type = $self->_get_defn($type->{type});
        }
        if ($type->isa('EnumType')) {
            # empty
        }
        elsif ($type->{value} eq 'short') {
            $cast = '(short)';
        }
        elsif ($type->{value} eq 'unsigned short') {
            $cast = '(short)';
        }
        elsif ($type->{value} eq 'long') {
            # empty
        }
        elsif ($type->{value} eq 'unsigned long') {
            # empty
        }
        elsif ($type->{value} eq 'long long') {
            $cast = '(long)';
        }
        elsif ($type->{value} eq 'unsigned long long') {
            $cast = '(long)';
        }
        elsif ($type->{value} eq 'octet') {
            $cast = '(byte)';
        }
    }
    $node->{$self->{key}} = $cast . $str;
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
        if    ($_ == 10) {
            $str .= "\\n";
        }
        elsif ($_ == 13) {
            $str .= "\\r";
        }
        elsif ($_ == 34) {
            $str .= "\\\"";
        }
        elsif ($_ < 32 or $_ >= 128) {
            $str .= sprintf "\\u%04x",$_;
        }
        else {
            $str .= chr $_;
        }
    }
    $str .= q{"};
    $node->{$self->{key}} = $str;
}

sub visitWideStringLiteral {
    shift->visitStringLiteral(@_);
}

sub visitCharacterLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C', $node->{value};
    my $c = $list[0];
    my $str = q{'};
    if    ($c == 10) {
        $str .= "\\n";
    }
    elsif ($c == 13) {
        $str .= "\\r";
    }
    elsif ($c == 39) {
        $str .= "\\'";
    }
    elsif ($c < 32 or $c >= 128) {
        $str .= sprintf "\\u%04x",$c;
    }
    else {
        $str .= chr $c;
    }
    $str .= q{'};
    $node->{$self->{key}} = $str;
}

sub visitWideCharacterLiteral {
    shift->visitCharacterLiteral(@_);
}

sub visitFixedPtLiteral {
    my $self = shift;
    my ($node) = @_;
    my $str = q{"};
    $str .= $node->{value};
    $str .= q{"};
    $node->{$self->{key}} = $str;
}

sub visitFloatingPtLiteral {
    my $self = shift;
    my ($node, $type) = @_;
    my $str = $node->{value};
    if (    $type->{value} eq 'float' ) {
        $str .= 'f';
    }
    elsif ( $type->{value} eq 'double' ) {
        $str .= 'd';
    }
    elsif ( $type->{value} eq 'long double' ) {
        $str .= 'd';
    }
    $node->{$self->{key}} = $str;
}

sub visitBooleanLiteral {
    my $self = shift;
    my ($node) = @_;
    if ($node->{value} eq 'TRUE') {
        $node->{$self->{key}} = 'true';
    }
    else {
        $node->{$self->{key}} = 'false';
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
            my $str = $_->{value};
            $str =~ s/^\+//;
            $_->{$self->{key}} = $str;
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
            my $str = $_->{value};
            $str =~ s/^\+//;
            $_->{$self->{key}} = $str;
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
    my $type = $self->_get_defn($node->{type});
    while (     $type->isa('TypeDeclarator')
           and ! exists $type->{array_size} ) {
        $type = $self->_get_defn($type->{type});
    }
    $self->visitType($type);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $type);        # case
    }
}

sub visitCase {
    my $self = shift;
    my ($node, $type) = @_;
    foreach (@{$node->{list_label}}) {
        if      ($type->isa('EnumType') and $_->isa('Expression')) {
            $_->{$self->{key}} = $type->{java_Name} . '._' . $_->{value}->{java_name};
        }
        else {
            $_->visit($self);           # default or expression
        }
    }
    $node->{element}->visit($self);     # member
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
    my $type = $self->_get_defn($node->{type});
    $node->{$self->{key}} = $type->{java_Name} . '.' . $node->{java_name};
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
    shift->visitStringType(@_);
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
    shift->visitStructType(@_);
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $self->visitType($node->{type})     # param_type_spec or void
            if (exists $node->{type});      # initializer or factory or finder
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
    shift->visitOperation(@_);
}

sub visitFinder {
    shift->visitOperation(@_);
}

1;

