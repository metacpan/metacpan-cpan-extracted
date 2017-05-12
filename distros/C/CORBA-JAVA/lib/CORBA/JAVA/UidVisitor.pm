
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           IDL to Java Language Mapping Specification, Version 1.2 August 2002
#

package CORBA::JAVA::UidVisitor;

use strict;
use warnings;

our $VERSION = '2.61';

use Data::Dumper;
use Digest::SHA1 qw(sha1_hex);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
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

sub _get_uid {
    my $self = shift;
    my ($tree) = @_;
    return uc(substr(sha1_hex(Dumper($tree)), 0, 16));
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
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_uid});
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
    my $uid = {};
    $uid->{$node->{java_name}} = undef;
    if (exists $node->{inheritance}) {
        if (exists $node->{inheritance}->{list_interface}) {
            foreach (@{$node->{inheritance}->{list_interface}}) {
                my $base = $self->_get_defn($_);
                $uid->{$base->{java_name}} = $base->{java_uid};
            }
        }
        if (exists $node->{inheritance}->{list_value}) {
            foreach (@{$node->{inheritance}->{list_value}}) {
                my $base = $self->_get_defn($_);
                $uid->{$base->{java_name}} = $base->{java_uid};
            }
        }
    }
    if ($node->{list_member}) {
        foreach (@{$node->{list_member}}) {
            my $defn = $self->_get_defn($_);
            $defn->visit($self);        # 'Member'
            $uid->{$defn->{java_name}} = $defn->{java_type};
        }
    }
    $node->{java_uid} = $self->_get_uid($uid);
}

sub visitForwardBaseInterface {
#   empty
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    # empty
}

sub visitInitializer {
    # empty
}

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_uid});

    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    my $uid = {};
    $uid->{$node->{java_name}} = $node->{java_type_code};
    $node->{java_uid} = $self->_get_uid($uid);
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
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
    return if (exists $node->{java_uid});
    my $uid = {};
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        $uid->{$defn->{java_name}} = $defn->{java_type};
        $self->_get_defn($defn->{type})->visit($self);
    }
    $node->{java_uid} = $self->_get_uid($uid);
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_uid});
    $self->_get_defn($node->{type})->visit($self);
    my $uid = {};
    $uid->{_d} = $self->_get_defn($node->{type})->{java_type};
    foreach (@{$node->{list_expr}}) {
        my $elt = $self->_get_defn($_->{element});
        $elt->visit($self);
        foreach my $label (@{$_->{list_label}}) {
            if (ref $label eq 'CORBA::IDL::Default') {
                $uid->{default} = $elt->{java_Name};
            }
            else {
                $uid->{$label->{java_literal}} = $elt->{java_Name};
            }
        }
    }
    $node->{java_uid} = $self->_get_uid($uid);
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    my $member = $self->_get_defn($node->{value});
    $self->_get_defn($member->{type})->visit($self);
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    my $uid = {};
    foreach (@{$node->{list_expr}}) {
        $uid->{$_->{java_name}} = undef;
    }
    $node->{java_uid} = $self->_get_uid($uid);
}

#
#   3.11.3  Template Types
#

sub visit_TemplateType {
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
    # empty
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    # empty
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
    # empty
}

sub visitFinder {
    # empty
}

1;

