
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::IDL::UidVisitor;

use strict;
use warnings;

our $VERSION = '2.62';

use Digest::SHA1 qw(sha1_hex);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
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
    my ($str) = @_;
    return uc(substr(sha1_hex($str),0, 16));
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
    return if (exists $node->{serial_uid});
    my $uid_str = $node->{idf};
    foreach ($node->getInheritance()) {
        my $base = $self->_get_defn($_);
        $uid_str .= $base->{idf} . $base->{serial_uid};
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
    foreach (@{$node->{list_export}}) {
        $self->_get_defn($_)->visit($self);
    }
    if (exists $node->{list_member}) {
        foreach (@{$node->{list_member}}) {
            my $defn = $self->_get_defn($_);
            my $type = $self->_get_defn($defn->{type});
            $type->visit($self);
            $uid_str .= $defn->{idf};
            $uid_str .= $type->{serial_uid} || $type->{value};
        }
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
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
    return if (exists $node->{serial_uid});

    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    my $uid_str = $node->{idf};
    $uid_str .= $type->{serial_uid} || $type->{value};
    $node->{serial_uid} = $self->_get_uid($uid_str);
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
    return if (exists $node->{serial_uid});
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    my $uid_str = $node->{idf};
    $uid_str .= $type->{serial_uid} || $type->{value};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $uid_str .= '[' . $_->{value} . ']';
        }
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    my $uid_str = $node->{idf};
    $node->{serial_uid} = $self->_get_uid($uid_str);
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
    return if (exists $node->{serial_uid});
    my $uid_str = $node->{idf};
    $node->{serial_uid} = $self->_get_uid($uid_str);
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        my $type = $self->_get_defn($defn->{type});
        $type->visit($self);
        $uid_str .= $defn->{idf};
        $uid_str .= $type->{serial_uid} || $type->{value};
        if (exists $defn->{array_size}) {
            foreach (@{$defn->{array_size}}) {
                $uid_str .= '[' . $_->{value} . ']';
            }
        }
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{serial_uid});
    $self->_get_defn($node->{type})->visit($self);
    my $uid_str = $node->{idf};
    my $type = $self->_get_defn($node->{type});
    $uid_str .= $type->{serial_uid} || $type->{value};
    $node->{serial_uid} = $self->_get_uid($uid_str);
    foreach my $case (@{$node->{list_expr}}) {
        my $elt = $self->_get_defn($case->{element});
        foreach my $label (@{$case->{list_label}}) {
            if (ref $label eq 'CORBA::IDL::Default') {
                $uid_str .= '_default_';
            }
            else {
                if (ref $label->{value} eq 'CORBA::IDL::Enum') {
                    $uid_str .= $label->{value}->{idf};
                }
                else {
                    $uid_str .= $label->{value};
                }
            }
        }
        my $defn = $self->_get_defn($elt->{value});
        my $type = $self->_get_defn($defn->{type});
        $uid_str .= $defn->{idf};
        $uid_str .= ($type->{serial_uid} || $type->{value} || q{});
        if (exists $defn->{array_size}) {
            foreach (@{$defn->{array_size}}) {
                $uid_str .= '[' . $_->{value} . ']';
            }
        }
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    my $uid_str = $node->{idf};
    foreach (@{$node->{list_expr}}) {
        $uid_str .= $_->{idf};
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{serial_uid});
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    my $uid_str = '_seq_';
    $uid_str .= $type->{serial_uid} || $type->{value};
    if (exists $node->{max}) {
        $uid_str .= '_max_' . $node->{max}->{value};
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    my $uid_str = $node->{value};
    if (exists $node->{max}) {
        $uid_str .= '_max_' . $node->{max}->{value};
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    my $uid_str = $node->{value};
    if (exists $node->{max}) {
        $uid_str .= '_max_' . $node->{max}->{value};
    }
    $node->{serial_uid} = $self->_get_uid($uid_str);
}

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    my $uid_str .= '_d_' . $node->{d}->{value};
    $uid_str .= '_s_' . $node->{s}->{value};
    $node->{serial_uid} = $self->_get_uid($uid_str);
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

