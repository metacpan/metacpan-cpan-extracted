
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::JAVA::NameXmlVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::JAVA::Name2Visitor;
use base qw(CORBA::JAVA::Name2Visitor);

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
}

#
#   3.9     Value Declaration
#

sub visitValue {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
    foreach (@{$node->{list_export}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
    }
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});

    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if (exists $node->{java_primitive}) {
    }
    else {
        if ($type->isa('SequenceType')) {
            $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
            $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
        }
        else {
            $node->{java_read_xml} = $type->{java_read_xml};
            $node->{java_write_xml} = $type->{java_write_xml};
        }
    }
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});
    my $type = $self->_get_defn($node->{type});
    $type->visit($self);
    if (exists $node->{array_size}) {
        $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
        $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
    }
    else {
        if ($type->isa('SequenceType')) {
            $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
            $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
        }
        else {
            if (       $type->isa('BasicType')
                    or $type->isa('StringType')
                    or $type->isa('WideStringType')
                    or $type->isa('FixedPtType') ) {
                $node->{java_read_xml} = $type->{java_read_xml};
                $node->{java_write_xml} = $type->{java_write_xml};
            }
            else {
                $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
                $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
            }
        }
    }
}

sub visitNativeType {
    # empty
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
        $node->{java_read_xml} = "\$is.read_short (";
        $node->{java_write_xml} = "\$os.write_short (";
    }
    elsif ($node->{value} eq 'unsigned short') {
        $node->{java_read_xml} = "\$is.read_ushort (";
        $node->{java_write_xml} = "\$os.write_ushort (";
    }
    elsif ($node->{value} eq 'long') {
        $node->{java_read_xml} = "\$is.read_long (";
        $node->{java_write_xml} = "\$os.write_long (";
    }
    elsif ($node->{value} eq 'unsigned long') {
        $node->{java_read_xml} = "\$is.read_ulong (";
        $node->{java_write_xml} = "\$os.write_ulong (";
    }
    elsif ($node->{value} eq 'long long') {
        $node->{java_read_xml} = "\$is.read_longlong (";
        $node->{java_write_xml} = "\$os.write_longlong (";
    }
    elsif ($node->{value} eq 'unsigned long long') {
        $node->{java_read_xml} = "\$is.read_ulonglong (";
        $node->{java_write_xml} = "\$os.write_ulonglong (";
    }
    else {
        warn __PACKAGE__,"::visitIntegerType $node->{value}.\n";
    }
}

sub visitFloatingPtType {
    my $self = shift;
    my ($node) = @_;
    if    ($node->{value} eq 'float') {
        $node->{java_read_xml} = "\$is.read_float (";
        $node->{java_write_xml} = "\$os.write_float (";
    }
    elsif ($node->{value} eq 'double') {
        $node->{java_read_xml} = "\$is.read_double (";
        $node->{java_write_xml} = "\$os.write_double (";
    }
    elsif ($node->{value} eq 'long double') {
        $node->{java_read_xml} = "\$is.read_double (";
        $node->{java_write_xml} = "\$os.write_double (";
    }
    else {
        warn __PACKAGE__,"::visitFloatingPtType $node->{value}.\n";
    }
}

sub visitCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_char (";
    $node->{java_write_xml} = "\$os.write_char (";
}

sub visitWideCharType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_wchar (";
    $node->{java_write_xml} = "\$os.write_wchar (";
}

sub visitBooleanType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_boolean (";
    $node->{java_write_xml} = "\$os.write_boolean (";
}

sub visitOctetType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_octet (";
    $node->{java_write_xml} = "\$os.write_octet (";
}

sub visitAnyType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_any (";
    $node->{java_write_xml} = "\$os.write_any (";
}

sub visitObjectType {
    # empty ? TODO
}

sub visitValueBaseType {
    # empty ? TODO
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    while ($type->isa('TypeDeclarator') and !exists($type->{array_size})) {
        $type = $self->_get_defn($type->{type});
    }
    if ($type->isa('SequenceType') or exists ($type->{array_size})) {
        while ($type->isa('SequenceType')) {
            $type = $self->_get_defn($type->{type});
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
    return if (exists $node->{java_read_xml});
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
    $self->_get_defn($node->{type})->visit($self);
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);           # case
    }
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
}

#
#   3.11.3  Template Types
#
#   See 1.11    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});
    $self->_get_defn($node->{type})->visit($self);
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
}

#
#   See 1.12    Mapping for Strings
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_string (";
    $node->{java_write_xml} = "\$os.write_string (";
}

#
#   See 1.13    Mapping for Wide Strings
#

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_wstring (";
    $node->{java_write_xml} = "\$os.write_wstring (";
}

#
#   See 1.14    Mapping for Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    $node->{java_read_xml} = "\$is.read_fixed (";
    $node->{java_write_xml} = "\$os.write_fixed (";
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    return if (exists $node->{java_read_xml});
    $node->{java_read_xml} = $node->{java_Helper} . "XML.read (\$is, ";
    $node->{java_write_xml} = $node->{java_Helper} . "XML.write (\$os, ";
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);
    }
}

1;

