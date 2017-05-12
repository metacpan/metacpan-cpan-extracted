
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::IDL::RepositoryIdVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

# builds $node->{repos_id}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);
    my ($parser) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub _set_repos_id {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{typeid}) {
        $node->{repos_id} = $node->{typeid};
    }
    elsif (exists $node->{id}) {
        $node->{repos_id} = $node->{id};
    }
    else {
        my $version;
        my $scoped_name;
        if (exists $node->{version}) {
            $version = $node->{version};
        }
        else {
            $version = '1.0';
        }
        if (defined $node->{_typeprefix}) {
            if ($node->{_typeprefix}) {
                $scoped_name = $node->{_typeprefix} . '/' . $node->{idf}
            }
            else {
                $scoped_name = $node->{idf};
            }
        }
        elsif ($node->{prefix}) {
            $scoped_name = $node->{prefix} . '/' . $node->{idf}
        }
        else {
            $scoped_name = $node->{idf};
        }
        $node->{repos_id} = 'IDL:' . $scoped_name . ':' . $version;
    }
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
    $self->_set_repos_id($node);
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
    $self->_set_repos_id($node);
    foreach (@{$node->{list_export}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
}

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
}

#
#   3.10        Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
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

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
    foreach (@{$node->{list_expr}}) {
        if (ref $_->{type}) {
            if (       $_->{type}->isa('StructType')
                    or $_->{type}->isa('UnionType')
                    or $_->{type}->isa('SequenceType')
                    or $_->{type}->isa('FixedPtType') ) {
                $_->{type}->visit($self);
            }
        }
    }
}

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
    foreach (@{$node->{list_expr}}) {
        if (ref $_->{element}->{type}) {
            if (       $_->{element}->{type}->isa('StructType')
                    or $_->{element}->{type}->isa('UnionType')
                    or $_->{element}->{type}->isa('SequenceType')
                    or $_->{element}->{type}->isa('FixedPtType') ) {
                $_->{element}->{type}->visit($self);
            }
        }
    }
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
}

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
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

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});
        foreach (@{$node->{list_expr}}) {
            if (ref $_->{type}) {
                if (       $_->{type}->isa('StructType')
                        or $_->{type}->isa('UnionType')
                        or $_->{type}->isa('SequenceType')
                        or $_->{type}->isa('FixedPtType') ) {
                    $_->{type}->visit($self);
                }
            }
        }
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
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
    $self->_set_repos_id($node);
}

sub visitFinder {
    my $self = shift;
    my ($node) = @_;
    $self->_set_repos_id($node);
}

1;

