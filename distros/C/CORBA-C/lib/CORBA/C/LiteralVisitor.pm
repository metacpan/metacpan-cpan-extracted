
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::LiteralVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

# needs $node->{c_name} (CnameVisitor) for Enum
# builds $node->{c_literal}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{key} = 'c_literal';
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
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self);
        }
    }
    foreach (@{$node->{list_export}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.6     Import Declaration
#

sub visitImport {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_export}}) {
        $self->_get_defn($_)->visit($self);
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
        $self->_get_defn($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $_->visit($self);           # expression
        }
    }
}

sub visitInitializer {
    # C mapping is aligned with CORBA 2.1
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
    my $elt = $self->_get_defn(pop @{$list_expr});
    if (    $elt->isa('BinaryOp') ) {
        my $right = $self->_Eval($list_expr, $type);
        if (       $elt->{op} eq '>>'
                or $elt->{op} eq '<<' ) {
            $right =~ s/[LU]+$//;
        }
        my $left = $self->_Eval($list_expr, $type);
        return '(' . $left . q{ } . $elt->{op} . q{ } . $right . ')';
    }
    elsif ( $elt->isa('UnaryOp') ) {
        my $right = $self->_Eval($list_expr, $type);
        return $elt->{op} . $right;
    }
    elsif ( $elt->isa('Constant') ) {
        return $elt->{c_name};
    }
    elsif ( $elt->isa('Enum') ) {
        return $elt->{c_name};
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
    my $type = $self->_get_defn($node->{type});
    while ($type->isa('TypeDeclarator')) {
        $type = $self->_get_defn($type->{type});
    }
    $node->{$self->{key}} = $self->_Eval(\@list_expr, $type);
}

sub visitIntegerLiteral {
    my $self = shift;
    my ($node, $type) = @_;
    my $str = $node->{value};
    $str =~ s/^\+//;
    unless (exists $type->{auto}) {
        if    ($node->{lexeme} =~ /^0+$/) {
            $str = '0';
        }
        elsif ($node->{lexeme} =~ /^0[Xx]/) {
            my $fmt;
            if    ($type->{value} eq 'octet') {
                $fmt = '0x%02x';
            }
            elsif ( $type->{value} eq 'short' ) {
                $fmt = '0x%04x';
            }
            elsif ( $type->{value} eq 'unsigned short' ) {
                $fmt = '0x%04x';
            }
            elsif ( $type->{value} eq 'long' ) {
                $fmt = '0x%08x';
            }
            elsif ( $type->{value} eq 'unsigned long' ) {
                $fmt = '0x%08x';
            }
            elsif ( $type->{value} eq 'long long' ) {
                $fmt = '0x%016x';
            }
            elsif ( $type->{value} eq 'unsigned long long' ) {
                $fmt = '0x%016x';
            }
            $str = sprintf($fmt, $node->{value});
        }
        elsif ($node->{lexeme} =~ /^0/) {
            $str = sprintf('0%o', $node->{value});
        }
        else {
            $str = sprintf('%d', $node->{value});
        }
        if (    $type->{value} eq 'short' ) {
            $str = '(short)' . $str;
        }
        elsif ( $type->{value} eq 'unsigned short' ) {
            $str = '(unsigned short)' . $str . 'U';
        }
        elsif ( $type->{value} eq 'long' ) {
            $str .= 'L';
        }
        elsif ( $type->{value} eq 'unsigned long' ) {
            $str .= 'UL';
        }
        elsif ( $type->{value} eq 'long long' ) {
            $str .= 'LL';
        }
        elsif ( $type->{value} eq 'unsigned long long' ) {
            $str .= 'ULL';
        }
    }
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
            $str .= sprintf "\\u%04x", $_;
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
    my $str = q{'};
    if ($c < 32 or $c >= 128) {
        $str .= sprintf "\\x%02x", $c;
    }
    else {
        $str .= chr $c;
    }
    $str .= q{'};
    $node->{$self->{key}} = $str;
}

sub visitWideCharacterLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C', $node->{value};
    my $c = $list[0];
    my $str = q{L'};
    if ($c < 32 or ($c >= 128 and $c < 256)) {
        $str .= sprintf "\\x%02x", $c;
    }
    elsif ($c >= 256) {
        $str .= sprintf "\\u%04x", $c;
    }
    else {
        $str .= chr $c;
    }
    $str .= q{'};
    $node->{$self->{key}} = $str;
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
        $node->{$self->{key}} = '0';
    }
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
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
        $self->_get_defn($_)->visit($self);     # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
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
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
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
    $self->_get_defn($node->{value})->visit($self); # member
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
    $node->{$self->{key}} = $node->{value};
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
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
        $self->_get_defn($_)->visit($self);         # member
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type}); # param_type_spec or void
    $type->visit($self);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type}); # param_type_spec
    $type->visit($self);
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
    my $type = $self->_get_defn($node->{type}); # param_type_spec
    $type->visit($self);
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
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
}

sub visitFinder {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
}

1;

