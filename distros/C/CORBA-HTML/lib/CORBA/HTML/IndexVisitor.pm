#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::HTML::IndexVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{file_html} = q{};
    $self->{done_hash} = {};
    $self->{save_module} = {};
    $self->{num_key} = 'idx_html';
    return $self;
}

sub _get_name {
    my $self = shift;
    my ($node) = @_;
    my @list_name = split /::/, $node->{full};
    my @list_scope = split /::/, $self->{scope};
    shift @list_name;
    shift @list_scope;
    while (@list_scope) {
        last if ($list_scope[0] ne $list_name[0]);
        shift @list_name;
        shift @list_scope;
    }
    my $name = join '::', @list_name;
    return $name;
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

sub _get_file {
    my $self = shift;
    my ($defn) = @_;
    if ($self->{file_html}) {
        return $self->{file_html};
    }
    else {
        my $filename = $defn->{filename};
        return '__' . basename($defn->{filename}, '.idl') . '.html';
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = '::';
    # init
    $self->{index_module} = {};
    $self->{index_interface} = {};
    $self->{index_operation} = {};
    $self->{index_attribute} = {};
    $self->{index_constant} = {};
    $self->{index_exception} = {};
    $self->{index_type} = {};
    $self->{index_value} = {};
    $self->{index_boxed_value} = {};
    $self->{index_state_member} = {};
    $self->{index_initializer} = {};
    $self->{index_event} = {};
    $self->{index_component} = {};
    $self->{index_provides} = {};
    $self->{index_uses} = {};
    $self->{index_publishes} = {};
    $self->{index_emits} = {};
    $self->{index_consumes} = {};
    $self->{index_home} = {};
    $self->{index_factory} = {};
    $self->{index_finder} = {};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    # save
    $node->{index_module} = $self->{index_module};
    $node->{index_interface} = $self->{index_interface};
    $node->{index_operation} = $self->{index_operation};
    $node->{index_attribute} = $self->{index_attribute};
    $node->{index_constant} = $self->{index_constant};
    $node->{index_exception} = $self->{index_exception};
    $node->{index_type} = $self->{index_type};
    $node->{index_value} = $self->{index_value};
    $node->{index_boxed_value} = $self->{index_boxed_value};
    $node->{index_state_member} = $self->{index_state_member};
    $node->{index_initializer} = $self->{index_initializer};
    $node->{index_event} = $self->{index_event};
    $node->{index_component} = $self->{index_component};
    $node->{index_provides} = $self->{index_provides};
    $node->{index_uses} = $self->{index_uses};
    $node->{index_publishes} = $self->{index_publishes};
    $node->{index_emits} = $self->{index_emits};
    $node->{index_consumes} = $self->{index_consumes};
    $node->{index_home} = $self->{index_home};
    $node->{index_factory} = $self->{index_factory};
    $node->{index_finder} = $self->{index_finder};
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    my $filename = $node->{full};
    $filename =~ s/::/_/g;
    $filename .= '.html';
    $self->{index_module}->{$node->{idf}} = $node;
    $self->{save_module}->{$node->{full}} = {}
            unless (exists $self->{save_module}->{$node->{full}});
    # local save
    my $file_html = $self->{file_html};
    my $module = $self->{index_module};
    my $interface = $self->{index_interface};
    my $operation = $self->{index_operation};
    my $attribute = $self->{index_attribute};
    my $constant = $self->{index_constant};
    my $exception = $self->{index_exception};
    my $type = $self->{index_type};
    my $value = $self->{index_value};
    my $boxed_value = $self->{index_boxed_value};
    my $state_member = $self->{index_state_member};
    my $initializer = $self->{index_initializer};
    my $event = $self->{index_event};
    my $component = $self->{index_component};
    my $provides = $self->{index_provides};
    my $uses = $self->{index_uses};
    my $publishes = $self->{index_publishes};
    my $emits = $self->{index_emits};
    my $consumes = $self->{index_consumes};
    my $home = $self->{index_home};
    my $factory = $self->{index_factory};
    my $finder = $self->{index_finder};
    # re init
    $self->{file_html} = $filename;
    $self->{index_module} = $self->{save_module}->{$node->{full}}->{index_module} || {};
    $self->{index_interface} = $self->{save_module}->{$node->{full}}->{index_interface} || {};
    $self->{index_operation} = $self->{save_module}->{$node->{full}}->{index_operation} || {};
    $self->{index_attribute} = $self->{save_module}->{$node->{full}}->{index_attribute} || {};
    $self->{index_constant} = $self->{save_module}->{$node->{full}}->{index_constant} || {};
    $self->{index_exception} = $self->{save_module}->{$node->{full}}->{index_exception} || {};
    $self->{index_type} = $self->{save_module}->{$node->{full}}->{index_type} || {};
    $self->{index_value} = $self->{save_module}->{$node->{full}}->{index_value} || {};
    $self->{index_boxed_value} = $self->{save_module}->{$node->{full}}->{index_boxed_value} || {};
    $self->{index_state_member} = $self->{save_module}->{$node->{full}}->{index_state_member} || {};
    $self->{index_initializer} = $self->{save_module}->{$node->{full}}->{index_initializer} || {};
    $self->{index_event} = $self->{save_module}->{$node->{full}}->{index_event} || {};
    $self->{index_component} = $self->{save_module}->{$node->{full}}->{index_component} || {};
    $self->{index_provides} = $self->{save_module}->{$node->{full}}->{index_provides} || {};
    $self->{index_uses} = $self->{save_module}->{$node->{full}}->{index_uses} || {};
    $self->{index_publishes} = $self->{save_module}->{$node->{full}}->{index_publishes} || {};
    $self->{index_emits} = $self->{save_module}->{$node->{full}}->{index_emits} || {};
    $self->{index_consumes} = $self->{save_module}->{$node->{full}}->{index_consumes} || {};
    $self->{index_home} = $self->{save_module}->{$node->{full}}->{index_home} || {};
    $self->{index_factory} = $self->{save_module}->{$node->{full}}->{index_factory} || {};
    $self->{index_finder} = $self->{save_module}->{$node->{full}}->{index_finder} || {};
    unless (exists $node->{$self->{num_key}}) {
        $node->{$self->{num_key}} = 0;
    }
    ${$node->{list_decl}}[$node->{$self->{num_key}}]->visit($self);
    $node->{$self->{num_key}} ++;

    $node->{file_html} = $self->{file_html};
    $node->{index_module} = $self->{index_module};
    $node->{index_interface} = $self->{index_interface};
    $node->{index_operation} = $self->{index_operation};
    $node->{index_attribute} = $self->{index_attribute};
    $node->{index_constant} = $self->{index_constant};
    $node->{index_exception} = $self->{index_exception};
    $node->{index_type} = $self->{index_type};
    $node->{index_value} = $self->{index_value};
    $node->{index_boxed_value} = $self->{index_boxed_value};
    $node->{index_state_member} = $self->{index_state_member};
    $node->{index_initializer} = $self->{index_initializer};
    $node->{index_event} = $self->{index_event};
    $node->{index_component} = $self->{index_component};
    $node->{index_provides} = $self->{index_provides};
    $node->{index_uses} = $self->{index_uses};
    $node->{index_publishes} = $self->{index_publishes};
    $node->{index_emits} = $self->{index_emits};
    $node->{index_consumes} = $self->{index_consumes};
    $node->{index_home} = $self->{index_home};
    $node->{index_factory} = $self->{index_factory};
    $node->{index_finder} = $self->{index_finder};
    #
    $self->{save_module}->{$node->{full}}->{file_html} = $self->{file_html};
    $self->{save_module}->{$node->{full}}->{index_module} = $self->{index_module};
    $self->{save_module}->{$node->{full}}->{index_interface} = $self->{index_interface};
    $self->{save_module}->{$node->{full}}->{index_operation} = $self->{index_operation};
    $self->{save_module}->{$node->{full}}->{index_attribute} = $self->{index_attribute};
    $self->{save_module}->{$node->{full}}->{index_constant} = $self->{index_constant};
    $self->{save_module}->{$node->{full}}->{index_exception} = $self->{index_exception};
    $self->{save_module}->{$node->{full}}->{index_type} = $self->{index_type};
    $self->{save_module}->{$node->{full}}->{index_value} = $self->{index_value};
    $self->{save_module}->{$node->{full}}->{index_boxed_value} = $self->{index_boxed_value};
    $self->{save_module}->{$node->{full}}->{index_state_member} = $self->{index_state_member};
    $self->{save_module}->{$node->{full}}->{index_initializer} = $self->{index_initializer};
    $self->{save_module}->{$node->{full}}->{index_event} = $self->{index_event};
    $self->{save_module}->{$node->{full}}->{index_component} = $self->{index_component};
    $self->{save_module}->{$node->{full}}->{index_provides} = $self->{index_provides};
    $self->{save_module}->{$node->{full}}->{index_uses} = $self->{index_uses};
    $self->{save_module}->{$node->{full}}->{index_publishes} = $self->{index_publishes};
    $self->{save_module}->{$node->{full}}->{index_emits} = $self->{index_emits};
    $self->{save_module}->{$node->{full}}->{index_consumes} = $self->{index_consumes};
    $self->{save_module}->{$node->{full}}->{index_home} = $self->{index_home};
    $self->{save_module}->{$node->{full}}->{index_factory} = $self->{index_factory};
    $self->{save_module}->{$node->{full}}->{index_finder} = $self->{index_finder};
    # restore
    $self->{file_html} = $file_html;
    $self->{index_module} = $module;
    $self->{index_interface} = $interface;
    $self->{index_operation} = $operation;
    $self->{index_attribute} = $attribute;
    $self->{index_constant} = $constant;
    $self->{index_exception} = $exception;
    $self->{index_type} = $type;
    $self->{index_value} = $value;
    $self->{index_boxed_value} = $boxed_value;
    $self->{index_state_member} = $state_member;
    $self->{index_initializer} = $initializer;
    $self->{index_event} = $event;
    $self->{index_component} = $component;
    $self->{index_provides} = $provides;
    $self->{index_uses} = $uses;
    $self->{index_publishes} = $publishes;
    $self->{index_emits} = $emits;
    $self->{index_consumes} = $consumes;
    $self->{index_home} = $home;
    $self->{index_factory} = $factory;
    $self->{index_finder} = $finder;
}

sub visitModule {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration
#

sub _visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    $self->{scope} = $node->{full};
    my $filename = $node->{full};
    $filename =~ s/::/_/g;
    $filename .= '.html';
    $node->{file_html} = $filename;
    # local save
    my $file_html = $self->{file_html};
    my $module = $self->{index_module};
    my $interface = $self->{index_interface};
    my $operation = $self->{index_operation};
    my $attribute = $self->{index_attribute};
    my $constant = $self->{index_constant};
    my $exception = $self->{index_exception};
    my $type = $self->{index_type};
    my $value = $self->{index_value};
    my $boxed_value = $self->{index_boxed_value};
    my $state_member = $self->{index_state_member};
    my $initializer = $self->{index_initializer};
    my $event = $self->{index_event};
    my $component = $self->{index_component};
    my $provides = $self->{index_provides};
    my $uses = $self->{index_uses};
    my $publishes = $self->{index_publishes};
    my $emits = $self->{index_emits};
    my $consumes = $self->{index_consumes};
    my $home = $self->{index_home};
    my $factory = $self->{index_factory};
    my $finder = $self->{index_finder};
    # init
    $self->{file_html} = $filename;
    $self->{index_module} = {};
    $self->{index_interface} = {};
    $self->{index_operation} = {};
    $self->{index_attribute} = {};
    $self->{index_constant} = {};
    $self->{index_exception} = {};
    $self->{index_type} = {};
    $self->{index_value} = {};
    $self->{index_boxed_value} = {};
    $self->{index_state_member} = {};
    $self->{index_initializer} = {};
    $self->{index_event} = {};
    $self->{index_component} = {};
    $self->{index_provides} = {};
    $self->{index_uses} = {};
    $self->{index_publishes} = {};
    $self->{index_emits} = {};
    $self->{index_consumes} = {};
    $self->{index_home} = {};
    $self->{index_factory} = {};
    $self->{index_finder} = {};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $node->{file_html} = $self->{file_html};
    $node->{index_module} = $self->{index_module};
    $node->{index_interface} = $self->{index_interface};
    $node->{index_operation} = $self->{index_operation};
    $node->{index_attribute} = $self->{index_attribute};
    $node->{index_constant} = $self->{index_constant};
    $node->{index_exception} = $self->{index_exception};
    $node->{index_type} = $self->{index_type};
    $node->{index_value} = $self->{index_value};
    $node->{index_boxed_value} = $self->{index_boxed_value};
    $node->{index_state_member} = $self->{index_state_member};
    $node->{index_initializer} = $self->{index_initializer};
    $node->{index_event} = $self->{index_event};
    $node->{index_component} = $self->{index_component};
    $node->{index_provides} = $self->{index_provides};
    $node->{index_uses} = $self->{index_uses};
    $node->{index_publishes} = $self->{index_publishes};
    $node->{index_emits} = $self->{index_emits};
    $node->{index_consumes} = $self->{index_consumes};
    $node->{index_home} = $self->{index_home};
    $node->{index_factory} = $self->{index_factory};
    $node->{index_finder} = $self->{index_finder};
    # restore
    $self->{file_html} = $file_html;
    $self->{index_module} = $module;
    $self->{index_interface} = $interface;
    $self->{index_operation} = $operation;
    $self->{index_attribute} = $attribute;
    $self->{index_constant} = $constant;
    $self->{index_exception} = $exception;
    $self->{index_type} = $type;
    $self->{index_value} = $value;
    $self->{index_boxed_value} = $boxed_value;
    $self->{index_state_member} = $state_member;
    $self->{index_initializer} = $initializer;
    $self->{index_event} = $event;
    $self->{index_component} = $component;
    $self->{index_provides} = $provides;
    $self->{index_uses} = $uses;
    $self->{index_publishes} = $publishes;
    $self->{index_emits} = $emits;
    $self->{index_consumes} = $consumes;
    $self->{index_home} = $home;
    $self->{index_factory} = $factory;
    $self->{index_finder} = $finder;
}

sub visitInterface {
    my $self = shift;
    my ($node) = @_;
    $self->{index_interface}->{$node->{idf}} = $node;
    $self->_visitBaseInterface($node);
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.9     Value Declaration
#

sub visitValue {
    my $self = shift;
    my ($node) = @_;
    $self->{index_value}->{$node->{idf}} = $node;
    $self->_visitBaseInterface($node);
}

sub visitStateMembers {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_state_member}->{$node->{idf}} = $node;
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_initializer}->{$node->{idf}} = $node;
}

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_boxed_value}->{$node->{idf}} = $node;
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_constant}->{$node->{idf}} = $node;
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_type}->{$node->{idf}} = $node;
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType') ) {
        $type->visit($self);
    }
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_type}->{$node->{idf}} = $node;
}

#   3.11.2  Constructed Types
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{full}});
    $self->{done_hash}->{$node->{full}} = 1;
    my $name = $self->_get_name($node);
    $self->{index_type}->{$name} = $node;
    $node->{html_name} = $name;
    $node->{file_html} = $self->_get_file($node);
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType') ) {
            $type->visit($self);
        }
    }
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self, $node->{file_html});     # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node, $filename) = @_;
    $node->{file_html} = $filename;
    $node->{html_name} = $self->_get_name($node);
}

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{full}});
    $self->{done_hash}->{$node->{full}} = 1;
    my $name = $self->_get_name($node);
    $self->{index_type}->{$name} = $node;
    $node->{html_name} = $name;
    $node->{file_html} = $self->_get_file($node);
    my $type = $self->_get_defn($node->{type});
    if ($type->isa('EnumType')) {
        $type->visit($self);
    }
    foreach (@{$node->{list_expr}}) {   # case
        $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType') ) {
            $type->visit($self);
        }
        $self->_get_defn($_->{element}->{value})->visit($self, $node->{file_html});     # member
    }
}

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    my $name = $self->_get_name($node);
    $self->{index_type}->{$name} = $node;
    $node->{html_name} = $name;
    $node->{file_html} = $self->_get_file($node);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self, $node->{file_html});               # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node, $filename) = @_;
    $node->{file_html} = $filename;
    $node->{html_name} = $self->_get_name($node);
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_exception}->{$node->{idf}} = $node;
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_operation}->{$node->{idf}} = $node;
}

#
#   3.14    Attribute Declaration
#

sub visitAttributes {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_attribute}->{$node->{idf}} = $node;
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

sub visitEvent {
    my $self = shift;
    my ($node) = @_;
    $self->{index_event}->{$node->{idf}} = $node;
    $self->_visitBaseInterface($node);
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    my $self = shift;
    my ($node) = @_;
    $self->{index_component}->{$node->{idf}} = $node;
    $self->_visitBaseInterface($node);
}

sub visitProvides {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_provides}->{$node->{idf}} = $node;
}

sub visitUses {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_uses}->{$node->{idf}} = $node;
}

sub visitPublishes {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_publishes}->{$node->{idf}} = $node;
}

sub visitEmits {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_emits}->{$node->{idf}} = $node;
}

sub visitConsumes {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_consumes}->{$node->{idf}} = $node;
}

#
#   3.18    Home Declaration
#

sub visitHome {
    my $self = shift;
    my ($node) = @_;
    $self->{index_home}->{$node->{idf}} = $node;
    $self->_visitBaseInterface($node);
}

sub visitFactory {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_factory}->{$node->{idf}} = $node;
}

sub visitFinder {
    my $self = shift;
    my ($node) = @_;
    $node->{file_html} = $self->_get_file($node);
    $self->{index_finder}->{$node->{idf}} = $node;
}

#
#   XPIDL
#

sub visitCodeFragment {
    # empty
}

1;

