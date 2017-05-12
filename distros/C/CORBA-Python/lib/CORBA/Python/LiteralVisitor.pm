
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           Python Language Mapping Specification, Version 1.2 November 2002
#

package CORBA::Python::LiteralVisitor;

use strict;
use warnings;

our $VERSION = '2.66';

use File::Basename;

# builds $node->{py_literal}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $server) = @_;
    $self->{key} = 'py_literal';
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    if (exists $parser->YYData->{opt_J}) {
        $self->{base_package} = $parser->YYData->{opt_J};
    }
    else {
        $self->{base_package} = q{};
    }
    $self->{server} = 1 if (defined $server);
    $self->{import_substitution} = {};
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

sub _get_scoped_name {
    my $self = shift;
    my ($node, $scope) = @_;
    my $scope_full = $scope->{full};
    $scope_full =~ s/::[0-9A-Z_a-z]+$//;
    my $name = $node->{full};
    if ($name =~ /^::[0-9A-Z_a-z]+$/) {
        if ($scope_full) {
            my $basename = basename($self->{srcname}, '.idl');
            $basename =~ s/\./_/g;
            if (exists $self->{server}) {
                $name = '_' . $basename . '_skel.' . $node->{py_name};
            }
            else {
                $name = '_' . $basename . '.' . $node->{py_name};
            }
        }
        else {
            $name = $node->{py_name};
        }
    }
    else {
        if ($scope_full) {
            if ($scope->isa('Constant')) {
                while ($name !~ /^$scope_full/) {
                    my $defn = $self->_get_defn($scope_full);
                    last if ($defn->isa('Modules'));
                    $scope_full =~ s/::[0-9A-Z_a-z]+$//;
                    last unless ($scope_full);
                }
            }
            else {
                my $defn = $self->_get_defn($scope_full);
                while (!$defn->isa('Modules')) {
                    $scope_full =~ s/::[0-9A-Z_a-z]+$//;
                    last unless ($scope_full);
                    $defn = $self->_get_defn($scope_full);
                }
            }
            $name =~ s/^$scope_full//;
            $name =~ s/^:://;
            if (exists $self->{server}) {
                $name =~ s/::/_skel\./;
            }
            $name =~ s/::/\./g;
            if ($self->{base_package}) {
                my $import_name = $name;
                $import_name =~ s/\.[0-9A-Z_a-z]+$//;
                if (exists $self->{import_substitution}->{$import_name}) {
                    $name =~ s/$import_name/$self->{import_substitution}->{$import_name}/;
                }
            }
        }
        else {
            my $name2 = $node->{py_name};
            $name =~ s/::[0-9A-Z_a-z]+$//;
            while ($name) {
                my $defn = $self->{symbtab}->Lookup($name);
                if ($defn->isa('Interface') and exists $self->{server}) {
                    $name2 = $defn->{py_name} . '_skel.' . $name2;
                }
                else {
                    $name2 = $defn->{py_name} . '.' . $name2;
                }
                $name =~ s/::[0-9A-Z_a-z]+$//;
            }
            $name =  $name2;
        }
    }
    return $name;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $self->_get_defn($_)->visit($self);
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
    foreach my $name (sort keys %{$node->{py_import}}) {
        next if ($name eq '::CORBA');
        next if ($name eq '::IOP');
        next if ($name eq '::GIOP');
        unless ( $name eq '::' or $name eq q{} ) {
            $name =~ s/^:://;
            if (exists $self->{server}) {
                $name =~ s/::/_skel\./g;
                $name .= '_skel';
            }
            else {
                $name =~ s/::/\./g;
            }
            if ($self->{base_package}) {
                my $full_import_name = $self->{base_package} . '.' . $name;
                $full_import_name =~ s/\//\./g;
                $self->{import_substitution}->{$name} = $full_import_name;
            }
        }
    }
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
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);    # type_spec
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
        $_->visit($self);               # parameter
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{value}->visit($self, $node);        # expression
}

sub _Eval {
    my $self = shift;
    my ($list_expr, $type, $scope) = @_;
    my $elt = $self->_get_defn(pop @{$list_expr});
    if    ( $elt->isa('Literal') ) {
        $elt->visit($self, $type);
        return $elt->{$self->{key}};
    }
    elsif ( $elt->isa('Enum') ) {
        return $self->_get_scoped_name($elt, $scope);
    }
    elsif ( $elt->isa('Constant') ) {
        return $self->_get_scoped_name($elt, $scope);
    }
    elsif ( $elt->isa('UnaryOp') ) {
        my $right = $self->_Eval($list_expr, $type, $scope);
        return $elt->{op} . $right;
    }
    elsif ( $elt->isa('BinaryOp') ) {
        my $right = $self->_Eval($list_expr, $type, $scope);
        my $left = $self->_Eval($list_expr, $type, $scope);
        return '(' . $left . q{ } . $elt->{op} . q{ } . $right . ')';
    }
    else {
        warn __PACKAGE__,"::_Eval: INTERNAL ERROR ",ref $elt,".\n";
        return undef;
    }
}

sub visitExpression {
    my $self = shift;
    my ($node, $scope) = @_;
    my $type = $self->_get_defn($node->{type});
    while ($type->isa('TypeDeclarator')) {
        $type = $self->_get_defn($type->{type});
    }
    my @list_expr = @{$node->{list_expr}};      # create a copy
    my $str = $self->_Eval(\@list_expr, $type, $scope);
    $type = $self->_get_defn($node->{type});
    if ($type->isa('TypeDeclarator')) {
        my $type2 = $self->_get_defn($type->{type});
        unless ($type2->isa('EnumType')) {
            $node->{$self->{key}} = $type->{py_name} . '(' . $str . ')';
            return;
        }
    }
    $node->{$self->{key}} = $str;
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
        if (       $type->{value} eq 'unsigned long'
                or $type->{value} eq 'long long'
                or $type->{value} eq 'unsigned long long' ) {
            $str .= 'L';
        }
    }
    $node->{$self->{key}} = $str;
}

sub visitStringLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C*', $node->{value};
    my $str = q{'};
    foreach (@list) {
        if ($_ < 32 or $_ >= 128) {
            $str .= sprintf "\\x%02x", $_;
        }
        else {
            $str .= chr $_;
        }
    }
    $str .= q{'};
    $node->{$self->{key}} = $str;
}

sub visitWideStringLiteral {
    my $self = shift;
    my ($node) = @_;
    my @list = unpack 'C*', $node->{value};
    my $str = q{u'};
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
    $str .= q{'};
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
    my $str = q{u'};
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
        $node->{$self->{key}} = 'True';
    }
    else {
        $node->{$self->{key}} = 'False';
    }
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self, $node);
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
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = 1;
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        $defn->visit($self, $node);         # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node, $type) = @_;
    $self->_get_defn($node->{type})->visit($self, $type);
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
    return if (exists $node->{$self->{key}});
    $node->{$self->{key}} = 1;
    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $node);                # case
    }
}

sub visitCase {
    my $self = shift;
    my ($node, $type) = @_;
    foreach (@{$node->{list_label}}) {
        $_->visit($self, $type);                # default or expression
    }
    $node->{element}->visit($self, $type);
}

sub visitDefault {
    # empty
}

sub visitElement {
    my $self = shift;
    my ($node, $type) = @_;
    my $defn = $self->_get_defn($node->{value});    # member
    $defn->visit($self, $type);
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
    my $self = shift;
    my ($node, $scope) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self, $type);
    $node->{max}->visit($self, $scope) if (exists $node->{max});
}

sub visitStringType {
    my $self = shift;
    my ($node, $scope) = @_;
    $node->{max}->visit($self, $scope) if (exists $node->{max});
}

sub visitWideStringType {
    my $self = shift;
    my ($node, $scope) = @_;
    $node->{max}->visit($self, $scope) if (exists $node->{max});
}

sub visitFixedPtType {
    my $self = shift;
    my ($node, $scope) = @_;
    $node->{d}->visit($self, $scope);
    $node->{s}->visit($self, $scope);
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
        my $defn = $self->_get_defn($_);
        $defn->visit($self, $node);         # member
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);        # param_type_spec or void
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);    # param_type_spec
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
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);    # param_type_spec
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

