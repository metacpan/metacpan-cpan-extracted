
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C++ Language Mapping Specification, New Edition June 1999
#

package CORBA::Cplusplus::NameVisitor;

use strict;
use warnings;

our $VERSION = '0.40';

# builds $node->{cpp_name} and $node->{cpp_ns}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{key} = 'cpp_name';
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{cpp_keywords} = {       # See 1.43  C++ Keywords
        'and'               => 1,
        'and_ep'            => 1,
        'asm'               => 1,
        'auto'              => 1,
        'bitand'            => 1,
        'bitor'             => 1,
        'bool'              => 1,
        'break'             => 1,
#IDL    'case'              => 1,
        'catch'             => 1,
#IDL    'char'              => 1,
        'class'             => 1,
        'compl'             => 1,
#IDL    'const'             => 1,
        'const_cast'        => 1,
        'continue'          => 1,
#IDL    'default'           => 1,
        'delete'            => 1,
        'do'                => 1,
#IDL    'double'            => 1,
        'dynamic_cast'      => 1,
        'else'              => 1,
#IDL    'enum'              => 1,
        'explicit'          => 1,
        'export'            => 1,
        'extern'            => 1,
#IDL    'false'             => 1,
#IDL    'float'             => 1,
        'for'               => 1,
        'friend'            => 1,
        'goto'              => 1,
        'if'                => 1,
        'inline'            => 1,
        'int'               => 1,
#IDL    'long'              => 1,
        'mutable'           => 1,
        'namespace'         => 1,
        'new'               => 1,
        'not'               => 1,
        'not_eq'            => 1,
        'operator'          => 1,
        'or'                => 1,
        'or_eq'             => 1,
        'private'           => 1,
        'protected'         => 1,
        'public'            => 1,
        'register'          => 1,
        'reinterpret_cast'  => 1,
        'return'            => 1,
#IDL    'short'             => 1,
        'signed'            => 1,
        'sizeof'            => 1,
        'static'            => 1,
        'static_cast'       => 1,
#IDL    'struct'            => 1,
#IDL    'switch'            => 1,
        'template'          => 1,
        'this'              => 1,
        'throw'             => 1,
#IDL    'true'              => 1,
        'try'               => 1,
#IDL    'typedef'           => 1,
        'typeid'            => 1,
        'typename'          => 1,
#IDL    'union'             => 1,
#IDL    'unsigned'          => 1,
        'using'             => 1,
        'virtual'           => 1,
#IDL    'void'              => 1,
        'volatile'          => 1,
        'wchar_t'           => 1,
        'while'             => 1,
        'xor'               => 1,
        'xor_eq'            => 1
    };
    return $self;
}

sub _get_name {         # See 1.1.2 Scoped Names
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{idf};
    $name =~ s/^_get_//;
    $name =~ s/^_set_//;
    if (exists $self->{cpp_keywords}->{name}) {
        return '_cxx_' . $name;
    }
    else {
        return $name;
    }
}

sub _get_ns {
    my $self = shift;
    my ($node) = @_;
    my $pkg = $node->{full};
    $pkg =~ s/::[0-9A-Z_a-z]+$//;
    return q{} unless ($pkg);
    my $defn = $self->{symbtab}->Lookup($pkg);
    if (       $defn->isa('StructType')
            or $defn->isa('UnionType')
            or $defn->isa('ExceptionType') ) {
        $pkg =~ s/::[0-9A-Z_a-z]+$//;
    }
    return q{} unless ($pkg);
    my $ns = q{};
    $pkg =~ s/^:://;
    foreach (split /::/, $pkg) {
        if (exists $self->{cpp_keywords}->{$_}) {
            $ns .= '::_cxx_' . $_;
        }
        else {
            $ns .= '::' . $_;
        }
    }
    $ns =~ s/^:://;
    return $ns;
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
    my $ns_save = $self->{ns_curr};
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
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
    return if (exists $node->{cpp_name});
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $node->{cpp_has_ptr} = 1;
    $node->{cpp_has_var} = 1;
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{cpp_name});
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $node->{cpp_has_ptr} = 1;
    $node->{cpp_has_var} = 1;
}

#
#   3.9     Value Declaration
#

sub visitStateMember {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitExpression {
    # empty
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{cpp_ns});
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    my $type = $self->_get_defn($node->{type});
    if ($type->isa('SequenceType') and !exists $node->{array_size}) {
        $type->{repos_id} = $node->{repos_id};
        $node->{cpp_has_var} = 1;
        $type->visit($self, $node->{cpp_name});
    }
    else {
        $type->visit($self);
    }
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
}

#
#   3.11.1  Basic Types
#
#   See 1.5     Mapping for Basic Data Types
#

sub visitIntegerType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    if    ($node->{value} eq 'short') {
        $node->{cpp_name} = 'Short';
    }
    elsif ($node->{value} eq 'unsigned short') {
        $node->{cpp_name} = 'UShort';
    }
    elsif ($node->{value} eq 'long') {
        $node->{cpp_name} = 'Long';
    }
    elsif ($node->{value} eq 'unsigned long') {
        $node->{cpp_name} = 'ULong';
    }
    elsif ($node->{value} eq 'long long') {
        $node->{cpp_name} = 'LongLong';
    }
    elsif ($node->{value} eq 'unsigned long long') {
        $node->{cpp_name} = 'ULongLong';
    }
    else {
        warn __PACKAGE__,"::visitIntegerType $node->{value}.\n"
    }
}

sub visitFloatingPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    if    ($node->{value} eq 'float') {
        $node->{cpp_name} = 'Float';
    }
    elsif ($node->{value} eq 'double') {
        $node->{cpp_name} = 'Double';
    }
    elsif ($node->{value} eq 'long double') {
        $node->{cpp_name} = 'LongDouble';
    }
    else {
        warn __PACKAGE__,"::visitFloatingPtType $node->{value}.\n"
    }
}

sub visitCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'Char';
}

sub visitWideCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'WChar';
}

sub visitBooleanType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'Boolean';
}

sub visitOctetType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'Octet';
}

sub visitAnyType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'Any';
    $node->{cpp_has_var} = 1;
}

sub visitObjectType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'Object';
    $node->{cpp_has_var} = 1;
}

sub visitValueBaseType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'ValueBase';
    $node->{cpp_has_var} = 1;
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{cpp_ns});
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $node->{cpp_has_var} = 1;
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{cpp_ns});
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $node->{cpp_has_var} = 1;
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # case
    }
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_label}}) {
        $_->visit($self);           # default or expression
    }
    $node->{element}->visit($self);
}

sub visitDefault {
    # empty
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    $self->_get_defn($node->{value})->visit($self);     # member
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_name} = $self->_get_name($node);
}

#
#   3.11.3  Template Types
#
#   See 1.13    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node, $name) = @_;
    return if (exists $node->{cpp_ns});
    $node->{cpp_ns} = $self->_get_ns($node);
    my $type =  $self->_get_defn($node->{type});
    $type->visit($self);
    unless (defined $name) {
        $name = '_seq_' . $type->{cpp_name};
        if (exists $node->{max}) {
            $name .= '_' . $node->{max}->{value};
            $name =~ s/\+//g;
        }
    }
    $node->{cpp_name} = $name;
}

#
#   See 1.7     Mapping for String Types
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'String';
}

#
#   See 1.8     Mapping for Wide String Types
#

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = 'WString';
}

#
#
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    my $name = 'Fixed';
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = $name;
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node) = @_;
    my $name = 'Fixed';
    $node->{cpp_ns} = 'CORBA';
    $node->{cpp_name} = $name;
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{cpp_ns});
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
}

#
#   3.13    Operation Declaration
#


sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_name} = 'void';
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
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
}

sub visitUses {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
}

sub visitPublishes {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
}

sub visitEmits {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
}

sub visitConsumes {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
}

#
#   3.18    Home Declaration
#

sub visitFactory {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitFinder {
    # C++ mapping is aligned with CORBA 2.3
    my $self = shift;
    my ($node) = @_;
    $node->{cpp_ns} = $self->_get_ns($node);
    $node->{cpp_name} = $self->_get_name($node);
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

1;

