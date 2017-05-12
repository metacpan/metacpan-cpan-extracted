
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           IDL to Java Language Mapping Specification, Version 1.2 August 2002
#

package CORBA::JAVA::NameVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

# builds $node->{java_name} and $node->{java_package}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $prefix, $translate) = @_;
    $self->{key} = 'java_name';
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{num_key} = 'num_java_name';
    $self->{pkg_prefix} = {};
    if (defined $prefix) {
        foreach (split /;/, $prefix) {
            my @kv = split /=/, $_;
            if (scalar(@kv) == 2) {
                $self->{pkg_prefix}->{$kv[0]} = $kv[1];
            }
        }
    }
    $self->{pkg_translate} = {};
    if (defined $translate) {
        foreach (split /;/, $translate) {
            my @kv = split /=/, $_;
            if (scalar(@kv) == 2) {
                next if ($kv[0] eq 'org' or $kv[0] eq 'org.omg' or $kv[0] =~ /^org\.omg\./);
                $self->{pkg_translate}->{$kv[0]} = $kv[1];
            }
        }
    }
    $self->{java_keywords} = {
        # The keywords in the Java Language :
        # (from the Java Language Specification 1.0 First Edition, Section 3.9)
        'abstract'          => 1,
        'boolean'           => 1,
        'break'             => 1,
        'byte'              => 1,
        'case'              => 1,
        'catch'             => 1,
        'char'              => 1,
        'class'             => 1,
        'const'             => 1,
        'continue'          => 1,
        'default'           => 1,
        'do'                => 1,
        'double'            => 1,
        'else'              => 1,
        'extends'           => 1,
        'final'             => 1,
        'finally'           => 1,
        'float'             => 1,
        'for'               => 1,
        'goto'              => 1,
        'if'                => 1,
        'implements'        => 1,
        'import'            => 1,
        'instanceof'        => 1,
        'int'               => 1,
        'interface'         => 1,
        'long'              => 1,
        'native'            => 1,
        'new'               => 1,
        'package'           => 1,
        'private'           => 1,
        'protected'         => 1,
        'public'            => 1,
        'return'            => 1,
        'short'             => 1,
        'static'            => 1,
        'super'             => 1,
        'switch'            => 1,
        'synchronized'      => 1,
        'this'              => 1,
        'throw'             => 1,
        'throws'            => 1,
        'transcient'        => 1,
        'try'               => 1,
        'void'              => 1,
        'volatile'          => 1,
        'while'             => 1,
        # additionnal Java constant
        'true'              => 1,
        'false'             => 1,
        'null'              => 1,
        # methods on java.lang.Object
        # (from the Java Language Specification 1.0 First Edition, Section 20.1)
        'clone'             => 1,
        'equals'            => 1,
        'finalize'          => 1,
        'getClass'          => 1,
        'hashCode'          => 1,
        'notify'            => 1,
        'notifyAll'         => 1,
        'toString'          => 1,
        'wait'              => 1
    };
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

sub _get_name {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{idf};
    $name =~ s/^_get_//;
    $name =~ s/^_set_//;
    return '_' . $name if (exists $self->{java_keywords}->{$name});
    return '_' . $name if ($name =~ /Helper$/);
    return '_' . $name if ($name =~ /Holder$/);
    return '_' . $name if ($name =~ /Operations$/);
    return '_' . $name if ($name =~ /POA$/);
    return '_' . $name if ($name =~ /POATie$/);
    return '_' . $name if ($name =~ /Package$/);
    return $name;
}

sub _get_pkg {
    my $self = shift;
    my ($node) = @_;
    my $pkg = $node->{full};
    $pkg =~ s/::[0-9A-Z_a-z]+$//;
    return q{} unless ($pkg);
    my $defn = $self->{symbtab}->Lookup($pkg);
    my $package = $defn->{java_Name};
    if (        (  $node->isa('StructType')
                or $node->isa('UnionType')
                or $node->isa('EnumType')
                or $node->isa('Exception')
                or $node->isa('TypeDeclarator') )
            and (  $defn->isa('BaseInterface')
                or $defn->isa('UnionType')
                or $defn->isa('StructType') ) ) {
        $package .= 'Package';
    }
    foreach (keys %{$self->{pkg_prefix}}) {
        if ($package =~ /^$_/) {
            $package = $self->{pkg_prefix}->{$_} . '.' . $package;
            last;
        }
    }
    foreach (keys %{$self->{pkg_translate}}) {
        if ($package =~ s/^$_/$self->{pkg_translate}->{$_}/) {
            last;
        }
    }
    return $package;
}

sub _get_Name {
    my $self = shift;
    my ($node, $java_package) = @_;
    $java_package = $node->{java_package} unless (defined $java_package);
    if ($java_package) {
        return $java_package . '.' . $node->{java_name};
    }
    else {
        return $node->{java_name};
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
    foreach (@{$node->{list_decl}}) {
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
    unless (exists $node->{$self->{num_key}}) {
        $node->{$self->{num_key}} = 0;
        $node->{java_package} = $self->_get_pkg($node);
        $node->{java_name} = $self->_get_name($node);
        $node->{java_Name} = $self->_get_Name($node);
    }
    my $module = ${$node->{list_decl}}[$node->{$self->{num_key}}];
    $module->visit($self);
    $node->{$self->{num_key}} ++;
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

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_package});
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_package});
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

#
#   3.9     Value Declaration
#

sub visitStateMembers {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitStateMember {
    shift->visitMember(@_);
}

sub visitInitializer {
    shift->visitOperation(@_);
}

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_package});

    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('FloatingPtType')
            or $type->isa('IntegerType')
            or $type->isa('CharType')
            or $type->isa('WideCharType')
            or $type->isa('BooleanType')
            or $type->isa('OctetType') ) {
        $type->visit($self);
        $node->{java_package} = $self->_get_pkg($node);
        $node->{java_name} = $self->_get_name($node);
        $node->{java_Name} = $self->_get_Name($node);
        $node->{java_primitive} = 1;
    }
    else {
        if ($type->isa('SequenceType')) {
            $type->visit($self);
            $type->{repos_id} = $node->{repos_id};
            $type = $self->_get_defn($type->{type});
            $node->{java_name} = $type->{java_name} . '[]';
            while ($type->isa('SequenceType')) {
                $node->{java_name} .= '[]';
                $type = $self->_get_defn($type->{type});
            }
            $node->{java_Name} = $self->_get_Name($node, $type->{java_package});
            $node->{java_package} = $self->_get_pkg($node);
        }
        else {
            $node->{java_package} = $self->_get_pkg($node);
            $node->{java_name} = $self->_get_name($node);
            $node->{java_Name} = $self->_get_Name($node);
            $type->visit($self);
        }
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    my $type = $self->_get_defn($node->{type});
    my $defn;
    my $pkg = $node->{full};
    $pkg =~ s/::[0-9A-Z_a-z]+$//;
    $defn = $self->{symbtab}->Lookup($pkg) if ($pkg);
    if ( defined $defn and $defn->isa('BaseInterface') ) {
        $node->{java_Name} = $self->_get_Name($node);
    }
    else {
        $node->{java_Name} = $self->_get_Name($node) . '.value';
    }
    $type->visit($self);
}

sub visitExpression {
    # empty
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
    return if (exists $node->{java_package});
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if (       $type->isa('BasicType')
            or $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('FixedPtType') ) {
        $node->{java_primitive} = 1;
    }
    else {
        $node->{java_primitive} = 1 if (exists $type->{java_primitive});
    }
    if (exists $node->{array_size}) {
        $node->{java_package} = $self->_get_pkg($node);
        $node->{java_name} = $self->_get_name($node);
        $node->{java_Name} = $self->_get_Name($node);
    }
    else {
        if ($type->isa('SequenceType')) {
            $type->{repos_id} = $node->{repos_id};
            $type = $self->_get_defn($type->{type});
            $node->{java_name} = $type->{java_name} . '[]';
            while ($type->isa('SequenceType')) {
                $node->{java_name} .= '[]';
                $type = $self->_get_defn($type->{type});
            }
            $node->{java_Name} = $self->_get_Name($node, $type->{java_package});
            $node->{java_package} = $self->_get_pkg($node);
        }
        else {
            if (       $type->isa('BasicType')
                    or $type->isa('StringType')
                    or $type->isa('WideStringType')
                    or $type->isa('FixedPtType') ) {
                $node->{java_name} = $type->{java_name};
                $node->{java_Name} = $type->{java_Name};
                $node->{java_package} = $self->_get_pkg($node);
            }
            else {
                $node->{java_package} = $self->_get_pkg($node);
                $node->{java_name} = $self->_get_name($node);
                $node->{java_Name} = $self->_get_Name($node);
            }
        }
    }
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

#
#   3.11.1  Basic Types
#
#   See 1.4     Mapping for Basic Data Types
#

sub visitIntegerType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = q{};
    if    ($node->{value} eq 'short') {
        $node->{java_name} = 'short';
        $node->{java_Name} = 'short';
    }
    elsif ($node->{value} eq 'unsigned short') {
        $node->{java_name} = 'short';
        $node->{java_Name} = 'short';
    }
    elsif ($node->{value} eq 'long') {
        $node->{java_name} = 'int';
        $node->{java_Name} = 'int';
    }
    elsif ($node->{value} eq 'unsigned long') {
        $node->{java_name} = 'int';
        $node->{java_Name} = 'int';
    }
    elsif ($node->{value} eq 'long long') {
        $node->{java_name} = 'long';
        $node->{java_Name} = 'long';
    }
    elsif ($node->{value} eq 'unsigned long long') {
        $node->{java_name} = 'long';
        $node->{java_Name} = 'long';
    }
    else {
        warn __PACKAGE__,"::visitIntegerType $node->{value}.\n";
    }
}

sub visitFloatingPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = q{};
    if    ($node->{value} eq 'float') {
        $node->{java_name} = 'float';
        $node->{java_Name} = 'float';
    }
    elsif ($node->{value} eq 'double') {
        $node->{java_name} = 'double';
        $node->{java_Name} = 'double';
    }
    elsif ($node->{value} eq 'long double') {
        warn __PACKAGE__," 'long double' not available at this time for Java.\n";
        $node->{java_name} = 'double';
        $node->{java_Name} = 'double';
    }
    else {
        warn __PACKAGE__,"::visitFloatingPtType $node->{value}.\n";
    }
}

sub visitCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = q{};
    $node->{java_name} = 'char';
    $node->{java_Name} = 'char';
}

sub visitWideCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = q{};
    $node->{java_name} = 'char';
    $node->{java_Name} = 'char';
}

sub visitBooleanType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = q{};
    $node->{java_name} = 'boolean';
    $node->{java_Name} = 'boolean';
}

sub visitOctetType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = q{};
    $node->{java_name} = 'byte';
    $node->{java_Name} = 'byte';
}

sub visitAnyType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = 'org.omg.CORBA';
    $node->{java_name} = 'Any';
    $node->{java_Name} = 'org.omg.CORBA.Any';
}

sub visitObjectType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = 'org.omg.CORBA';
    $node->{java_name} = 'Object';
    $node->{java_Name} = 'org.omg.CORBA.Object';
}

sub visitValueBaseType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = 'java.io';
    $node->{java_name} = 'Serializable';
    $node->{java_Name} = 'java.io.Serializable';
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_package});
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # 'Member'
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $node->{java_name} = $self->_get_name($node);
    while ($type->isa('TypeDeclarator') and !exists($type->{array_size})) {
        $type = $self->_get_defn($type->{type});
    }
    if ($type->isa('SequenceType') or exists ($type->{array_size})) {
        while ($type->isa('SequenceType')) {
            $type = $self->_get_defn($type->{type});
            while ($type->isa('TypeDeclarator')) {
                $type = $self->_get_defn($type->{type});
            }
        }
        $type->visit($self);
    }
    else {
        $type->visit($self);
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_package});
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
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
    $self->_get_defn($node->{value})->visit($self);     # 'Member'
}

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # enum
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $node->{java_package} = $type->{java_Name};
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

#
#   3.11.3  Template Types
#
#   See 1.11    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node, $name) = @_;
    return if (exists $node->{java_package});
    $node->{java_package} = $self->_get_pkg($node);
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    unless (defined $name) {
        $name = '_seq_' . $type->{java_name};
        if (exists $node->{max}) {
            $name .= '_' . $node->{max}->{value};
            $name =~ s/\+//g;
        }
    }
    $node->{java_name} = $name;
    $node->{java_Name} = $self->_get_Name($node);
}

#
#   See 1.12    Mapping for Strings
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = 'java.lang';
    $node->{java_name} = 'String';
    $node->{java_Name} = 'java.lang.String';
}

#
#   See 1.13    Mapping for Wide Strings
#

sub visitWideStringType {
    shift->visitStringType(@_);
}

#
#   See 1.14    Mapping for Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = 'java.math';
    $node->{java_name} = 'BigDecimal';
    $node->{java_Name} = 'java.math.BigDecimal';
}

sub visitFixedPtConstType {
    shift->visitFixedPtType(@_);
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
#   See 1.4     Inheritance and Operation Names
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
    $self->_get_defn($node->{type})->visit($self)
            if (exists $node->{type});              # initializer or factory or finder
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
}

sub visitParameter {
    my $self = shift;
    my($node) = @_;
    $node->{java_name} = $self->_get_name($node);
    $self->_get_defn($node->{type})->visit($self);
}

sub visitVoidType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Name} = 'void';
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
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

sub visitUses {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

sub visitPublishes {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

sub visitEmits {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
}

sub visitConsumes {
    my $self = shift;
    my ($node) = @_;
    $node->{java_package} = $self->_get_pkg($node);
    $node->{java_name} = $self->_get_name($node);
    $node->{java_Name} = $self->_get_Name($node);
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

