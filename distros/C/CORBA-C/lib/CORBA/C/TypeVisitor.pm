
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::TypeVisitor;

use strict;
use warnings;

our $VERSION = '2.61';

# builds $node->{c_arg}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub _get_type {
    my $self = shift;
    my ($type) = @_;

    if (ref $type) {
        return $type;
    }
    else {
        $self->{symbtab}->Lookup($type);
    }
}

sub _get_c_arg {
    my $self = shift;
    my ($type, $v_name, $attr) = @_;

    my $t_name = $type->{c_name};
    return $t_name . $self->_get_name_attr($type, $attr) . $v_name;
}

#
#   See 1.21    Summary of Argument/Result Passing
#

sub _get_name_attr {
    my $self = shift;
    my ($node, $attr) = @_;

    if (    $node->isa('BasicType')
         or $node->isa('EnumType') ) {
        if (    $attr eq 'in' ) {
            return q{ };
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' * ';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $node->isa('FixedPtType') ) {
        if (    $attr eq 'in' ) {
            return ' * ';
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' * ';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $node->isa('BaseInterface')
         or $node->isa('ForwardBaseInterface') ) {
        if (    $attr eq 'in' ) {
            return q{ };
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' * ';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $node->isa('StructType')
         or $node->isa('UnionType') ) {
        if (    $attr eq 'in' ) {
            return ' * ';
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            if (defined $node->{length}) {      # variable
                return ' ** ';
            }
            else {
                return ' * ';
            }
        }
        elsif ( $attr eq 'return' ) {
            if (defined $node->{length}) {      # variable
                return ' *';
            }
            else {
                return q{};
            }
        }
    }
    elsif ( $node->isa('SequenceType') ) {
        if (    $attr eq 'in' ) {
            return ' * ';
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' ** ';
        }
        elsif ( $attr eq 'return' ) {
            return ' *';
        }
    }
    elsif ( $node->isa('StringType')
         or $node->isa('WideStringType') ) {
        if (    $attr eq 'in' ) {
            return q{ };
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' * ';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $node->isa('TypeDeclarator') ) {
        if (exists $node->{array_size}) {
            if (    $attr eq 'in' ) {
                return q{ };
            }
            elsif ( $attr eq 'inout' ) {
                return q{ };
            }
            elsif ( $attr eq 'out' ) {
                if (defined $node->{length}) {      # variable
                    return '_slice ** ';
                }
                else {
                    return q{ };
                }
            }
            elsif ( $attr eq 'return' ) {
                return '_slice *';
            }
        }
        else {
            my $type = $node->{type};
            unless (ref $type) {
                $type = $self->{symbtab}->Lookup($type);
            }
            return $self->_get_name_attr($type, $attr);
        }
    }
    elsif ( $node->isa('NativeType') ) {
        # C mapping is aligned with CORBA 2.1
        if (    $attr eq 'in' ) {
            return q{ };
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' * ';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
        else {
            warn caller()," NativeType : ERROR_INTERNAL $attr \n";
        }
    }
    elsif ( $node->isa('AnyType') ) {
        if (    $attr eq 'in' ) {
            return ' * ';
        }
        elsif ( $attr eq 'inout' ) {
            return ' * ';
        }
        elsif ( $attr eq 'out' ) {
            return ' ** ';
        }
        elsif ( $attr eq 'return' ) {
            return ' *';
        }
    }
    elsif ( $node->isa('VoidType') ) {
        if ($attr eq 'return') {
            return q{};
        }
    }
    else {
        my $class = ref $node;
        warn "Please implement '$class' in '_get_name_attr'.\n";
        return;
    }
    my $class = ref $node;
    warn "_get_name_attr : ERROR_INTERNAL $class $attr \n";
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
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    # C mapping is aligned with CORBA 2.1
}

sub visitInitializer {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
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
    # empty
}

sub visitNativeType {
    # C mapping is aligned with CORBA 2.1
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

sub visitEnumType {
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
    my $type = $self->_get_type($node->{type});
    $node->{c_arg} = $self->_get_c_arg($type, q{}, 'return');
    foreach (@{$node->{list_param}}) {  # parameter
        $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
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
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
}

sub visitFinder {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{c_arg} = $self->_get_c_arg($type, $_->{c_name}, $_->{attr});
    }
}

1;

