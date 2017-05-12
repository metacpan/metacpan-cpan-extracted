
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           IDL to Java Language Mapping Specification, Version 1.2 August 2002
#

package CORBA::JAVA::Name2Visitor;

use strict;
use warnings;

our $VERSION = '2.64';

use CORBA::JAVA::NameVisitor;
use base qw(CORBA::JAVA::NameVisitor);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{symbtab} = $parser->YYData->{symbtab};
    return $self;
}

sub _get_Helper {
    my $self = shift;
    my ($node, $java_package) = @_;
    $java_package = $node->{java_package} unless (defined $java_package);
    if ($java_package) {
        return $java_package . '.' . $node->{java_helper};
    }
    else {
        return $node->{java_helper};
    }
}

sub _get_stub {
    my $self = shift;
    my ($node) = @_;
    if ($node->{java_package}) {
        return $node->{java_package} . '._' . $node->{java_name} . 'Stub';
    }
    else {
        return '_' . $node->{java_name} . 'Stub';
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
    return if (exists $node->{java_Helper});
    $node->{java_stub} = $self->_get_stub($node);
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_Helper});
    $node->{java_stub} = $self->_get_stub($node);
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
}

#
#   3.9     Value Declaration
#

sub visitValue {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_Helper});
    $node->{java_stub} = $self->_get_stub($node);
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
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
    return if (exists $node->{java_Helper});

    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if (exists $node->{java_primitive}) {
        $node->{java_Helper} = $node->{java_Name} . 'Helper';
        $node->{java_helper} = $node->{java_name};
        $node->{java_Holder} = $node->{java_Name} . 'Holder';
        $node->{java_init} = 'null';
        $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
        $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
        $node->{java_type_code} = $node->{java_Helper} . ".type ()";
    }
    else {
        $node->{java_helper} = $self->_get_name($node);
        $node->{java_Helper} = $self->_get_Helper($node) . 'Helper';
        $node->{java_Holder} = $self->_get_Helper($node) . 'Holder';
        $node->{java_init} = $type->{java_init};
        $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
        $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
        $node->{java_type_code} = $node->{java_Helper} . ".type ()";
    }
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    $node->{java_helper} = $node->{java_name};
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
    return if (exists $node->{java_Helper});
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if (exists $node->{array_size}) {
        $node->{java_Helper} = $node->{java_Name} . 'Helper';
        $node->{java_helper} = $node->{java_name};
        $node->{java_Holder} = $node->{java_Name} . 'Holder';
        $node->{java_init} = 'null';
#       $node->{java_init} = "new java.util.Vector (0)";
        $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
        $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
        $node->{java_type_code} = $node->{java_Helper} . ".type ()";
    }
    else {
        if ($type->isa('SequenceType')) {
            $node->{java_helper} = $self->_get_name($node);
            $node->{java_Helper} = $self->_get_Helper($node) . 'Helper';
            $node->{java_Holder} = $self->_get_Helper($node) . 'Holder';
            $node->{java_init} = 'null';
#           $node->{java_init} = "new java.util.Vector (0)";
            $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
            $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
            $node->{java_type_code} = $node->{java_Helper} . ".type ()";
        }
        else {
            if (       $type->isa('BasicType')
                    or $type->isa('StringType')
                    or $type->isa('WideStringType')
                    or $type->isa('FixedPtType') ) {
                $node->{java_helper} = $self->_get_name($node);
                $node->{java_Helper} = $self->_get_Helper($node) . 'Helper';
                $node->{java_Holder} = $type->{java_Holder};
                $node->{java_init} = $type->{java_init};
                $node->{java_read} = $type->{java_read};
                $node->{java_write} = $type->{java_write};
                $node->{java_type_code} = $type->{java_type_code};
                $node->{java_tk} = $type->{java_tk} if (exists $type->{java_tk});
            }
            else {
                $node->{java_Helper} = $node->{java_Name} . 'Helper';
                $node->{java_helper} = $node->{java_name};
                $node->{java_Holder} = $node->{java_Name} . 'Holder';
#               $node->{java_init} = 'null';
                $node->{java_init} = $type->{java_init};
                $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
                $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
                $node->{java_type_code} = $node->{java_Helper} . ".type ()";
            }
        }
    }
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_helper} = $node->{java_name};
    $node->{java_Helper} = $self->_get_Helper($node, $self->_get_pkg($node)) . 'Helper';
    $node->{java_Holder} = $self->_get_Helper($node, $self->_get_pkg($node)) . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
}

#
#   3.11.1  Basic Types
#
#   See 1.4     Mapping for Basic Data Types
#

sub visitIntegerType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'short') {
        $node->{java_Holder} = 'org.omg.CORBA.ShortHolder';
        $node->{java_init} = '(short)0';
        $node->{java_read} = "\$is.read_short ()";
        $node->{java_write} = "\$os.write_short (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_short)";
        $node->{java_tk} = 'short';
    }
    elsif ($node->{value} eq 'unsigned short') {
        $node->{java_Holder} = 'org.omg.CORBA.ShortHolder';
        $node->{java_init} = '(short)0';
        $node->{java_read} = "\$is.read_ushort ()";
        $node->{java_write} = "\$os.write_ushort (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_ushort)";
        $node->{java_tk} = 'ushort';
    }
    elsif ($node->{value} eq 'long') {
        $node->{java_Holder} = 'org.omg.CORBA.IntHolder';
        $node->{java_init} = '0';
        $node->{java_read} = "\$is.read_long ()";
        $node->{java_write} = "\$os.write_long (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_long)";
        $node->{java_tk} = 'long';
    }
    elsif ($node->{value} eq 'unsigned long') {
        $node->{java_Holder} = 'org.omg.CORBA.IntHolder';
        $node->{java_init} = '0';
        $node->{java_read} = "\$is.read_ulong ()";
        $node->{java_write} = "\$os.write_ulong (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_ulong)";
        $node->{java_tk} = 'ulong';
    }
    elsif ($node->{value} eq 'long long') {
        $node->{java_Holder} = 'org.omg.CORBA.LongHolder';
        $node->{java_init} = '(long)0';
        $node->{java_read} = "\$is.read_longlong ()";
        $node->{java_write} = "\$os.write_longlong (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_longlong)";
        $node->{java_tk} = 'longlong';
    }
    elsif ($node->{value} eq 'unsigned long long') {
        $node->{java_Holder} = 'org.omg.CORBA.LongHolder';
        $node->{java_init} = '(long)0';
        $node->{java_read} = "\$is.read_ulonglong ()";
        $node->{java_write} = "\$os.write_ulonglong (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_ulonglong)";
        $node->{java_tk} = 'ulonglong';
    }
    else {
        warn __PACKAGE__,"::visitIntegerType $node->{value}.\n";
    }
}

sub visitFloatingPtType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'float') {
        $node->{java_Holder} = 'org.omg.CORBA.FloatHolder';
        $node->{java_init} = '(float)0';
        $node->{java_read} = "\$is.read_float ()";
        $node->{java_write} = "\$os.write_float (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_float)";
        $node->{java_tk} = 'float';
    }
    elsif ($node->{value} eq 'double') {
        $node->{java_Holder} = 'org.omg.CORBA.DoubleHolder';
        $node->{java_init} = '(double)0';
        $node->{java_read} = "\$is.read_double ()";
        $node->{java_write} = "\$os.write_double (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_double)";
        $node->{java_tk} = 'double';
    }
    elsif ($node->{value} eq 'long double') {
        warn __PACKAGE__," 'long double' not available at this time for Java.\n";
        $node->{java_Holder} = 'org.omg.CORBA.DoubleHolder';
        $node->{java_init} = '(double)0';
        $node->{java_read} = "\$is.read_double ()";
        $node->{java_write} = "\$os.write_double (";
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_double)";
        $node->{java_tk} = 'double';
    }
    else {
        warn __PACKAGE__,"::visitFloatingPtType $node->{value}.\n";
    }
}

sub visitCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.CharHolder';
    $node->{java_init} = "'\\0'";
    $node->{java_read} = "\$is.read_char ()";
    $node->{java_write} = "\$os.write_char (";
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_char)";
    $node->{java_tk} = 'char';
}

sub visitWideCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.CharHolder';
    $node->{java_init} = "'\\0'";
    $node->{java_read} = "\$is.read_wchar ()";
    $node->{java_write} = "\$os.write_wchar (";
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_wchar)";
    $node->{java_tk} = 'wchar';
}

sub visitBooleanType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.BooleanHolder';
    $node->{java_init} = 'false';
    $node->{java_read} = "\$is.read_boolean ()";
    $node->{java_write} = "\$os.write_boolean (";
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_boolean)";
    $node->{java_tk} = 'boolean';
}

sub visitOctetType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.ByteHolder';
    $node->{java_init} = '(byte)0';
    $node->{java_read} = "\$is.read_octet ()";
    $node->{java_write} = "\$os.write_octet (";
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_octet)";
    $node->{java_tk} = 'octet';
}

sub visitAnyType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.AnyHolder';
    $node->{java_init} = 'null';
    $node->{java_read} = "\$is.read_any ()";
    $node->{java_write} = "\$os.write_any (";
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_any)";
    $node->{java_tk} = 'any';
}

sub visitObjectType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.ObjectHolder';
    $node->{java_init} = 'null';
    $node->{java_read} = "org.omg.CORBA.ObjectHelper.read (\$is)";
    $node->{java_write} = "org.omg.CORBA.ObjectHelper.write (\$os, ";
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_objref)";
    $node->{java_tk} = 'objref';
}

sub visitValueBaseType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.ValueBaseHolder';
    $node->{java_init} = 'null';
    $node->{java_read} = "org.omg.CORBA.ValueBaseHelper.read (\$is)";
    $node->{java_write} = "org.omg.CORBA.ValueBaseHelper.write (\$os, ";
    $node->{java_type_code} = "org.omg.CORBA.ValueBaseHelper.type ()";
#   $node->{java_tk} = 'objref';
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_Helper});
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # 'Member'
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    my $array = q{};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $array .= '[]';
        }
    }
    while ($type->isa('TypeDeclarator') and !exists($type->{array_size})) {
        $type = $self->_get_defn($type->{type});
    }
    while ($type->isa('SequenceType') or exists ($type->{array_size})) {
        if ($type->{array_size}) {
            foreach (@{$type->{array_size}}) {
                $array .= '[]';
            }
            $type = $self->_get_defn($type->{type});
            while ($type->isa('TypeDeclarator') and !exists($type->{array_size})) {
                $type = $self->_get_defn($type->{type});
            }
        }
        if ($type->isa('SequenceType')) {
            $array .= '[]';
            $type = $self->_get_defn($type->{type});
            while ($type->isa('TypeDeclarator')) {
                if (exists $type->{array_size}) {
                    foreach (@{$type->{array_size}}) {
                        $array .= '[]';
                    }
                }
                $type = $self->_get_defn($type->{type});
            }
        }
    }
    $type->visit($self);
    $node->{type_java} = $type;
    $node->{java_array} = $array;
    $node->{java_type} = $type->{java_Name} . $array;
    if (length $array) {
        $node->{java_init} = 'null';
    }
    else {
        $node->{java_init} = $type->{java_init};
        if      ($type->isa('FloatingPtType')) {
            if    ($type->{value} eq 'float') {
                $node->{java_object} = 'java.lang.Float';
            }
            elsif ($type->{value} eq 'double') {
                $node->{java_object} = 'java.lang.Double';
            }
            elsif ($type->{value} eq 'long double') {
                $node->{java_object} = 'java.lang.Double';
            }
        }
        elsif ($type->isa('IntegerType')) {
            if    ($type->{value} eq 'short') {
                $node->{java_object} = 'java.lang.Short';
            }
            elsif ($type->{value} eq 'unsigned short') {
                $node->{java_object} = 'java.lang.Short';
            }
            elsif ($type->{value} eq 'long') {
                $node->{java_object} = 'java.lang.Integer';
            }
            elsif ($type->{value} eq 'unsigned long') {
                $node->{java_object} = 'java.lang.Integer';
            }
            elsif ($type->{value} eq 'long long') {
                $node->{java_object} = 'java.lang.Long';
            }
            elsif ($type->{value} eq 'unsigned long long') {
                $node->{java_object} = 'java.lang.Long';
            }
        }
        elsif ($type->isa('CharType')) {
            $node->{java_object} = 'java.lang.Character';
        }
        elsif ($type->isa('WideCharType')) {
            $node->{java_object} = 'java.lang.Character';
        }
        elsif ($type->isa('BooleanType')) {
            $node->{java_object} = 'java.lang.Boolean';
        }
        elsif ($type->isa('OctetType')) {
            $node->{java_object} = 'java.lang.Byte';
        }
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_Helper});
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
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
    $self->_get_defn($node->{value})->visit($self);     # single or array
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
}

#
#   3.11.3  Template Types
#
#   See 1.11    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_Helper});
    $self->_get_defn($node->{type})->visit($self);
    $node->{java_Helper} = $node->{java_Name} . 'Helper';
    $node->{java_helper} = $node->{java_name};
    $node->{java_Holder} = $node->{java_Name} . 'Holder';
    $node->{java_init} = 'null';
#   $node->{java_init} = "new java.util.Vector (0)";
    $node->{java_read} = $node->{java_Helper} . ".read (\$is)";
    $node->{java_write} = $node->{java_Helper} . ".write (\$os, ";
    $node->{java_type_code} = $node->{java_Helper} . ".type ()";
}

#
#   See 1.12    Mapping for Strings
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.StringHolder';
    $node->{java_init} = "\"\"";
    $node->{java_read} = "\$is.read_string ()";
    $node->{java_write} = "\$os.write_string (";
    if (exists $node->{max}) {
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().create_string_tc (" . $node->{max}->{java_literal} . ")";
    }
    else {
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().create_string_tc (0)";
    }
}

#
#   See 1.13    Mapping for Wide Strings
#

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.StringHolder';
    $node->{java_init} = "\"\"";
    $node->{java_read} = "\$is.read_wstring ()";
    $node->{java_write} = "\$os.write_wstring (";
    if (exists $node->{max}) {
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().create_string_tc (" . $node->{max}->{java_literal} . ")";
    }
    else {
        $node->{java_type_code} = "org.omg.CORBA.ORB.init ().create_wstring_tc (0)";
    }
}

#
#   See 1.14    Mapping for Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_Holder} = 'org.omg.CORBA.FixedHolder';
    $node->{java_init} = 'null';
    $node->{java_read} = "\$is.read_fixed ()";      # deprecated by CORBA 2.4
    $node->{java_write} = "\$os.write_fixed (";     # deprecated by CORBA 2.4
    $node->{java_type_code} = "org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_fixed)";
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
    if (exists $node->{type}) {         # initializer or factory or finder
        my $type = $self->_get_defn($node->{type});
        $type->visit($self);
        while (     $type->isa('TypeDeclarator')
                and exists $type->{java_primitive} ) {
            $type = $self->_get_defn($type->{type});
        }
        $node->{java_Type} = $type->{java_Name};
    }
    foreach (@{$node->{list_param}}) {
        $_->visit($self);           # parameter
    }
    $node->{java_params} = q{};
    my $first = 1;
    foreach (@{$node->{list_param}}) {
        $node->{java_params} .= ", " unless ($first);
        $node->{java_params} .= $_->{java_Type};
        $node->{java_params} .= " " . $_->{java_name};
        $first = 0;
    }
    if (exists $node->{list_context}) {
        $node->{java_params} .= ", " unless ($first);
        $node->{java_params} .= "org.omg.CORBA.Context context";
    }
    $node->{java_proto} = q{};
    if (exists $node->{type}) {         # initializer or factory or finder
        $node->{java_proto} = $node->{java_Type} . q{ };
    }
    $node->{java_proto} .= $node->{java_name} . ' (' . $node->{java_params} . ')';
    if (exists $node->{list_raise}) {
        $node->{java_proto} .= ' throws ';
        $first = 1;
        foreach (@{$node->{list_raise}}) {      # exception
            my $defn = $self->_get_defn($_);
            $node->{java_proto} .= ', ' unless ($first);
            $node->{java_proto} .= $defn->{java_Name};
            $first = 0;
        }
    }
    $node->{java_call} = $node->{java_name} . ' (';
    $first = 1;
    foreach (@{$node->{list_param}}) {
        $node->{java_call} .= ', ' unless ($first);
        $node->{java_call} .= $_->{java_name};
        $first = 0;
    }
    if (exists $node->{list_context}) {
        $node->{java_call} .= ', ' unless ($first);
        $node->{java_call} .= 'context';
    }
    $node->{java_call} .= ')';
}

sub visitParameter {
    my $self = shift;
    my($node) = @_;
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if ($node->{attr} eq 'in') {
        my $array = q{};
        while (     $type->isa('TypeDeclarator')
                and exists $type->{java_primitive} ) {
            if (exists $type->{array_size}) {
                foreach (@{$type->{array_size}}) {
                    $array .= '[]';
                }
            }
            $type = $self->_get_defn($type->{type});
        }
        $node->{java_Type} = $type->{java_Name} . $array;
    }
    else {
        $node->{java_Type} = $type->{java_Holder};
    }
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
    shift->visitOperation(@_);
}

sub visitFinder {
    shift->visitOperation(@_);
}

1;

