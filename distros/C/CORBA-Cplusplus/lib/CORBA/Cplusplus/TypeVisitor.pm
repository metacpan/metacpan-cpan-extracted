
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C++ Language Mapping Specification, New Edition June 1999
#

package CORBA::Cplusplus::TypeVisitor;

use strict;
use warnings;

our $VERSION = '0.41';

use CORBA::C::TypeVisitor;
use base qw(CORBA::C::TypeVisitor);

# builds $node->{cpp_arg}

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

#
#   See 1.22    Argument Passing Considerations
#

sub _get_cpp_arg {
    my $self = shift;
    my ($type, $v_name, $attr) = @_;

    if (    $type->isa('BasicType')
         or $type->isa('EnumType') ) {
        my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . q{ }   . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . '_out ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . '_out ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name;
        }
    }
    elsif ( $type->isa('Value')
         or $type->isa('ForwardValue') ) {
        my $t_name = $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . '* '   . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . '** ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . '** ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name;
        }
    }
    elsif ( $type->isa('BaseInterface')
         or $type->isa('ForwardBaseInterface') ) {
        my $t_name = $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . '_ptr '   . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . '_out ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . '_out ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name . '_ptr';
        }
    }
    elsif ( $type->isa('StructType')
         or $type->isa('UnionType') ) {
        my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . ' * ' . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . ' * ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            if (defined $type->{length}) {      # variable
                return $t_name . ' ** ' . $v_name;
            }
            else {
                return $t_name . ' * '  . $v_name;
            }
        }
        elsif ( $attr eq 'return' ) {
            if (defined $type->{length}) {      # variable
                return $t_name . ' *';
            }
            else {
                return $t_name;
            }
        }
    }
    elsif ( $type->isa('StringType')
         or $type->isa('WideStringType') ) {
        my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return 'const ' . $t_name . q{ } . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . '_out ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . '_out ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name;
        }
    }
    elsif ( $type->isa('SequenceType') ) {      # TODO
        my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . ' * '  . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . ' * '  . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . ' ** ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name . ' *';
        }
    }
    elsif ( $type->isa('TypeDeclarator') ) {    # TODO
        if (exists $type->{array_size}) {
            my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
#            my $t_name = $type->{type}->{c_name};
#            my $array = q{};
#            foreach (@{$type->{array_size}}) {
#                $array .= '[' . $_->{c_literal} . ']';
#            }
            if (    $attr eq 'in' ) {
#                return $t_name . q{ } . $v_name . $array;
                return $t_name . q{ } . $v_name;
            }
            elsif ( $attr eq 'inout' ) {
#                return $t_name . q{ } . $v_name . $array;
                return $t_name . q{ } . $v_name;
            }
            elsif ( $attr eq 'out' ) {
                if (defined $type->{length}) {      # variable
                    return $t_name . '_slice ** ' . $v_name;
                }
                else {
#                    return $t_name . q{ } . $v_name . $array;
                    return $t_name . q{ } . $v_name;
                }
            }
            elsif ( $attr eq 'return' ) {
                return $t_name . '_slice *';
            }
        }
        else {
            my $type = $type->{type};
            unless (ref $type) {
                $type = $self->{symbtab}->Lookup($type);
            }
            return $self->_get_cpp_arg($type, $v_name, $attr);
        }
    }
    elsif ( $type->isa('NativeType') ) {
        my $t_name = $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . q{ }   . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . ' * ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . ' * ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name;
        }
    }
    elsif ( $type->isa('AnyType') ) {       # TODO
        my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
        $type->{length} = 'variable';
        if (    $attr eq 'in' ) {
            return $t_name . ' * '  . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . ' * '  . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . ' ** ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name . ' *';
        }
    }
    elsif ( $type->isa('FixedPtType') ) {   # TODO
        my $t_name = $type->{cpp_ns} . '::' . $type->{cpp_name};
        if (    $attr eq 'in' ) {
            return $t_name . ' * '  . $v_name;
        }
        elsif ( $attr eq 'inout' ) {
            return $t_name . ' * ' . $v_name;
        }
        elsif ( $attr eq 'out' ) {
            return $t_name . ' * ' . $v_name;
        }
        elsif ( $attr eq 'return' ) {
            return $t_name;
        }
    }
    elsif ( $type->isa('VoidType') ) {
        my $t_name = $type->{cpp_name};
        if ($attr eq 'return') {
            return $t_name;
        }
    }
    else {
        my $class = ref $type;
        warn "Please implement '$class' in '_get_cpp_arg'.\n";
        return;
    }
    my $class = ref $type;
    warn "_get_cpp_arg : ERROR_INTERNAL $class $attr \n";
}

#
#   3.9     Value Declaration
#

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{cpp_arg} = $self->_get_cpp_arg($type, $_->{cpp_name}, $_->{attr});
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_type($node->{type});
    $node->{cpp_arg} = $self->_get_cpp_arg($type, q{}, 'return');
    foreach (@{$node->{list_param}}) {  # parameter
        $type = $self->_get_type($_->{type});
        $_->{cpp_arg} = $self->_get_cpp_arg($type, $_->{cpp_name}, $_->{attr});
    }
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{cpp_arg} = $self->_get_cpp_arg($type, $_->{cpp_name}, $_->{attr});
    }
}

sub visitFinder {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_type($_->{type});
        $_->{cpp_arg} = $self->_get_cpp_arg($type, $_->{cpp_name}, $_->{attr});
    }
}

1;

