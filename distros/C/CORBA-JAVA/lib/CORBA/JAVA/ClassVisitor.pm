
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           IDL to Java Language Mapping Specification, Version 1.2 August 2002
#

package CORBA::JAVA::ClassVisitor;

use strict;
use warnings;

our $VERSION = '2.63';

use Data::Dumper;
use Digest::SHA1 qw(sha1_hex);
use File::Basename;
use File::Path;
use POSIX qw(ctime);

# needs $node->{java_name} (JavaNameVisitor), $node->{java_literal} (JavaLiteralVisitor)

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{done_hash} = {};
    $self->{num_key} = 'num_java';
    $self->{toString} = 1;
    $self->{equals} = 1;
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($node, $suffix) = @_;
    my $filename;
    my $prefix = q{};
    $prefix = '_' if ($suffix =~ /^Stub/);
    my $dirname = $node->{java_package};
    if ($dirname) {
        $dirname =~ s/\./\//g;
        unless (-d $dirname) {
            mkpath($dirname)
                    or die "can't create $dirname ($!).\n";
        }
        $filename = $dirname . '/' . $prefix . $node->{java_helper} . $suffix;
    }
    else {
        $filename = $prefix . $node->{java_helper} . $suffix;
    }
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n",caller(),"\n";
    $self->{filename} = $filename;

    my $FH = $self->{out};
    print $FH "/* ex: set ro: */\n";
    print $FH "package ",$node->{java_package},";\n"
            if ($node->{java_package});
    print $FH "\n";
    print $FH "/**\n";
    print $FH " * ",$self->{filename},"\n";
    print $FH " * This file was generated (by ",basename($0),"). DO NOT modify it\n";
    print $FH " * from file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH " */\n";
    print $FH "\n";
}

sub _no_mapping {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    my $class = ref $node;
    $class = substr $class, rindex($class, ':') + 1;
    if ($class =~ /^Forward/) {
        $node = $self->{symbtab}->Lookup($node->{full});
    }
    my $FH = $self->{out};
    print $FH "\n";
    print $FH "/* no mapping for ",$node->{java_name}," (",ref $node,")*/\n";
    print $FH "\n";
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

sub _format_javadoc {
    my $self = shift;
    my ($node) = @_;
    return q{} unless ($node->{doc});
    my $str = "\n/**\n";
    foreach (split /\n/, $node->{doc}) {
        s/^\s+//;
        next unless ($_);
        $str .= " * " . $_ . "\n";
    }
    $str .= " */\n";
    return $str;
}

sub _holder {
    my $self = shift;
    my ($node, $type, @array) = @_;
    $type = $node unless ($type);
    $self->open_stream($node, 'Holder.java');
    my $FH = $self->{out};
    print $FH "public final class ",$node->{java_helper},"Holder implements org.omg.CORBA.portable.Streamable\n";
    print $FH "{\n";
    print $FH "  public ",$type->{java_Name},@array," value;\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_helper},"Holder ()\n";
    print $FH "  {\n";
    if (scalar(@array)) {
        print $FH "    value = null;\n";
    }
    else {
        print $FH "    value = ",$type->{java_init},";\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_helper},"Holder (",$type->{java_Name},@array," initialValue)\n";
    print $FH "  {\n";
    print $FH "    value = initialValue;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public void _read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    value = ",$node->{java_read},";\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public void _write (org.omg.CORBA.portable.OutputStream \$os)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_write},"value);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public org.omg.CORBA.TypeCode _type ()\n";
    print $FH "  {\n";
    print $FH "    return ",$node->{java_Helper},".type ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
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

sub _interface_helper {
    my ($self, $node) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_interface_tc (_id, \"",$node->{java_name},"\");\n";
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    if ($node->isa('AbstractInterface')) {
        print $FH "    return narrow (((org.omg.CORBA_2_3.portable.InputStream)\$is).read_abstract_interface (_",$node->{java_name},"Stub.class));\n";
    }
    else {
        print $FH "    return narrow (\$is.read_Object (_",$node->{java_name},"Stub.class));\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    if ($node->isa('AbstractInterface')) {
        print $FH "    ((org.omg.CORBA_2_3.portable.OutputStream)\$os).write_abstract_interface ((java.lang.Object)value);\n";
    }
    else {
        print $FH "    \$os.write_Object ((org.omg.CORBA.Object)value);\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    if ($node->isa('RegularInterface') and exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
        my $has_abstract = 0;
        foreach (@{$node->{inheritance}->{list_interface}}) {
            my $base = $self->_get_defn($_);
            $has_abstract = 1 if ($base->isa('AbstractInterface'));
        }
        if ($has_abstract) {
            print $FH "  public static ",$node->{java_Name}," narrow (java.lang.Object obj)\n";
            print $FH "  {\n";
            print $FH "    if (obj == null)\n";
            print $FH "      return null;\n";
            print $FH "    else if (obj instanceof org.omg.CORBA.Object)\n";
            print $FH "      return _narrow ((org.omg.CORBA.Object)obj, false);\n";
            print $FH "    throw new org.omg.CORBA.BAD_PARAM ();\n";
            print $FH "  }\n";
            print $FH "\n";
            print $FH "  public static ",$node->{java_Name}," unchecked_narrow (java.lang.Object obj)\n";
            print $FH "  {\n";
            print $FH "    if (obj == null)\n";
            print $FH "      return null;\n";
            print $FH "    else if (obj instanceof org.omg.CORBA.Object)\n";
            print $FH "      return _narrow ((org.omg.CORBA.Object)obj, true);\n";
            print $FH "    throw new org.omg.CORBA.BAD_PARAM ();\n";
            print $FH "  }\n";
            print $FH "\n";
        }
    }
    if ($node->isa('AbstractInterface')) {
        print $FH "  public static ",$node->{java_Name}," narrow (java.lang.Object obj)\n";
    }
    else {
        print $FH "  public static ",$node->{java_Name}," narrow (org.omg.CORBA.Object obj)\n";
    }
    print $FH "  {\n";
    print $FH "    return _narrow(obj, false);\n";
    print $FH "  }\n";
    print $FH "\n";
    if ($node->isa('AbstractInterface')) {
        print $FH "  public static ",$node->{java_Name}," unchecked_narrow (java.lang.Object obj)\n";
    }
    else {
        print $FH "  public static ",$node->{java_Name}," unchecked_narrow (org.omg.CORBA.Object obj)\n";
    }
    print $FH "  {\n";
    print $FH "    return _narrow(obj, true);\n";
    print $FH "  }\n";
    print $FH "\n";
    if ($node->isa('AbstractInterface')) {
        print $FH "  public static ",$node->{java_Name}," _narrow (java.lang.Object obj, boolean is_a)\n";
    }
    else {
        print $FH "  public static ",$node->{java_Name}," _narrow (org.omg.CORBA.Object obj, boolean is_a)\n";
    }
    print $FH "  {\n";
    print $FH "    if (obj == null)\n";
    print $FH "      return null;\n";
    print $FH "    else if (obj instanceof ",$node->{java_Name},")\n";
    print $FH "      return (",$node->{java_Name},")obj;\n";
    if ($node->isa('AbstractInterface')) {
        print $FH "    else if ((obj instanceof org.omg.CORBA.portable.ObjectImpl) &&\n";
        print $FH "             (is_a || ((org.omg.CORBA.Object)obj)._is_a (id ())))\n";
    }
    else {
        print $FH "    else if (is_a || obj._is_a (id ()))\n";
    }
    print $FH "    {\n";
    print $FH "      org.omg.CORBA.portable.ObjectImpl impl = (org.omg.CORBA.portable.ObjectImpl)obj;\n";
    print $FH "      org.omg.CORBA.portable.Delegate delegate = impl._get_delegate ();\n";
    print $FH "      ",$node->{java_stub}," stub = new ",$node->{java_stub}," ();\n";
    print $FH "      stub._set_delegate (delegate);\n";
    print $FH "      return stub;\n";
    print $FH "    }\n";
    print $FH "    throw new org.omg.CORBA.BAD_PARAM ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _interface {
    my ($self, $node) = @_;

    $self->{constants} = q{};
    $self->{methodes} = q{};
    $self->{stub} = q{};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }

    $self->open_stream($node, '.java');
    my $FH = $self->{out};
    print $FH $self->_format_javadoc($node);
    if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
        print $FH "public interface ",$node->{java_name}," extends ";
        my $first = 1;
        unless ($node->isa('AbstractInterface')) {
            print $FH $node->{java_name},"Operations";
            $first = 0;
        }
        foreach (@{$node->{inheritance}->{list_interface}}) {
            print $FH ", " unless ($first);
            print $FH $self->_get_defn($_)->{java_Name};
            $first = 0;
        }
        print $FH ", " unless ($first);
        print $FH "org.omg.CORBA.portable.IDLEntity\n";
    }
    else {
        if    ($node->isa('AbstractInterface')) {
            print $FH "public interface ",$node->{java_name}," extends org.omg.CORBA.portable.IDLEntity\n";
        }
        elsif ($node->isa('LocalInterface')) {
            print $FH "public interface ",$node->{java_name}," extends ",$node->{java_name},"Operations, org.omg.CORBA.LocalInterface, org.omg.CORBA.portable.IDLEntity\n";
        }
        else {
            print $FH "public interface ",$node->{java_name}," extends ",$node->{java_name},"Operations, org.omg.CORBA.Object, org.omg.CORBA.portable.IDLEntity\n";
        }
    }
    print $FH "{\n";
    print $FH $self->{constants};
    print $FH $self->{methodes} if ($node->isa('AbstractInterface'));
    print $FH "} // interface ",$node->{java_name},"\n";
    close $FH;

    delete $self->{constants};
    delete $self->{methodes};
    delete $self->{stub};
}

sub _interface_operations {
    my ($self, $node) = @_;

    $self->{methodes} = q{};
    $self->{stub} = q{};
    foreach (@{$node->{list_decl}}) {
        my $defn = $self->_get_defn($_);
        if (       $defn->isa('Operation')
                or $defn->isa('Attributes') ) {
            $defn->visit($self);
        }
    }

    $self->open_stream($node, 'Operations.java');
    my $FH = $self->{out};
    if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
        print $FH "public interface ",$node->{java_name},"Operations extends ";
        my $first = 1;
        foreach (@{$node->{inheritance}->{list_interface}}) {
            my $base = $self->_get_defn($_);
            print $FH ", " unless ($first);
            if ($base->isa('AbstractInterface')) {
                print $FH $base->{java_Name};
            }
            else {
                print $FH $base->{java_Name},"Operations";
            }
            $first = 0;
        }
        print $FH "\n";
    }
    else {
        print $FH "public interface ",$node->{java_name},"Operations\n";
    }
    print $FH "{\n";
    print $FH $self->{methodes};
    print $FH "} // interface ",$node->{java_name},"Operations\n";
    close $FH;

    delete $self->{methodes};
    delete $self->{stub};
}

sub _interface_stub {
    my ($self, $node) = @_;

    $self->{methodes} = q{};
    $self->{stub} = q{};
    foreach (values %{$node->{hash_attribute_operation}}) {
        $self->_get_defn($_)->visit($self);
    }

    $self->open_stream($node, 'Stub.java');
    my $FH = $self->{out};
    print $FH "public class _",$node->{java_name},"Stub extends org.omg.CORBA.portable.ObjectImpl implements ",$node->{java_Name},"\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    print $FH "\n";
    print $FH $self->{stub};
    print $FH "  // Type-specific CORBA::Object operations\n";
    print $FH "  private static java.lang.String[] __ids = {\n";
    print $FH "    \"",$node->{repos_id},"\"";
    if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
        foreach (sort keys %{$node->{inheritance}->{hash_interface}}) {
            my $base = $self->_get_defn($_);
            print $FH ",\n";
            print $FH "    \"",$base->{repos_id},"\"";
        }
    }
    print $FH "\n";
    print $FH "  };\n";
    print $FH "\n";
    print $FH "  public java.lang.String[] _ids ()\n";
    print $FH "  {\n";
    print $FH "    return (java.lang.String[])__ids.clone ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private void readObject (java.io.ObjectInputStream s) throws java.io.IOException\n";
    print $FH "  {\n";
    print $FH "     java.lang.String str = s.readUTF ();\n";
    print $FH "     java.lang.String[] args = null;\n";
    print $FH "     java.util.Properties props = null;\n";
    print $FH "     org.omg.CORBA.Object obj = org.omg.CORBA.ORB.init (args, props).string_to_object (str);\n";
    print $FH "     org.omg.CORBA.portable.Delegate delegate = ((org.omg.CORBA.portable.ObjectImpl)obj)._get_delegate ();\n";
    print $FH "     _set_delegate (delegate);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private void writeObject (java.io.ObjectOutputStream s) throws java.io.IOException\n";
    print $FH "  {\n";
    print $FH "     java.lang.String[] args = null;\n";
    print $FH "     java.util.Properties props = null;\n";
    print $FH "     java.lang.String str = org.omg.CORBA.ORB.init (args, props).object_to_string (this);\n";
    print $FH "     s.writeUTF (str);\n";
    print $FH "  }\n";
    print $FH "} // class _",$node->{java_name},"Stub\n";
    close $FH;

    delete $self->{methodes};
    delete $self->{stub};
}

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    $self->_holder($node);
    $self->_interface_helper($node);
    $self->_interface($node);
    $self->_interface_operations($node);
    $self->_interface_stub($node);
    $self->_interface_helperXML($node) if ($self->can('_interface_helperXML'));
    $self->_interface_stubXML($node) if ($self->can('_interface_stubXML'));
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    $self->_holder($node);
    $self->_interface_helper($node);
    $self->_interface($node);
    $self->_interface_stub($node);
    $self->_interface_helperXML($node) if ($self->can('_interface_helperXML'));
    $self->_interface_stubXML($node) if ($self->can('_interface_stubXML'));
}

sub visitLocalInterface {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    $self->_holder($node);
    $self->_interface_helper($node);
    $self->_interface($node);
    $self->_interface_operations($node);
    $self->_interface_stub($node);
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.9     Value Declaration
#
#   3.9.1   Regular Value Type
#

sub _value_helper {
    my ($self, $node) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    if (exists $node->{list_member}) {
        print $FH "          org.omg.CORBA.ValueMember[] _members0 = new org.omg.CORBA.ValueMember [",scalar(@{$node->{list_member}}),"];\n";
        print $FH "          org.omg.CORBA.TypeCode _tcOf_members0 = null;\n";
        my $i = 0;
        foreach (@{$node->{list_member}}) {     # StateMember
            my $member = $self->_get_defn($_);
            print $FH "          // ValueMember instance for ",$member->{java_name},"\n";
            $self->_member_helper_type($member, $node, $i);
            $i ++;
        }
    }
    else {
        print $FH "          org.omg.CORBA.ValueMember[] _members0 = new org.omg.CORBA.ValueMember [0];\n";
        print $FH "          org.omg.CORBA.TypeCode _tcOf_members0 = null;\n";
    }
    if ($node->isa('AbstractValue')) {
        print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_value_tc (_id, \"",$node->{java_name},"\", org.omg.CORBA.VM_ABSTRACT.value, null, _members0);\n";
    }
    else {
        print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_value_tc (_id, \"",$node->{java_name},"\", org.omg.CORBA.VM_NONE.value, null, _members0);\n";
    }
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return (",$node->{java_Name},")((org.omg.CORBA_2_3.portable.InputStream)\$is).read_value (id ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    ((org.omg.CORBA_2_3.portable.OutputStream)\$os).write_value (value, id ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH $self->{factory};
    print $FH "}\n";
    close $FH;
}

sub _value {
    my ($self, $node) = @_;

    $self->open_stream($node, '.java');
    my $FH = $self->{out};

    print $FH $self->_format_javadoc($node);
    my $super;
    if ($node->isa('AbstractValue')) {
        print $FH "public interface ",$node->{java_name}," extends org.omg.CORBA.portable.ValueBase";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_value}) {
            foreach (@{$node->{inheritance}->{list_value}}) {
                my $base = $self->_get_defn($_);
                print $FH ", ",$base->{java_Name};
            }
        }
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            foreach (@{$node->{inheritance}->{list_interface}}) {
                my $base = $self->_get_defn($_);
                print $FH ", ",$base->{java_Name},"Operations";
            }
        }
    }
    else {
        print $FH "public abstract class ",$node->{java_name};
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_value}) {
            foreach (@{$node->{inheritance}->{list_value}}) {
                my $base = $self->_get_defn($_);
                next unless ($base->isa('RegularValue'));
                print $FH " extends ",$base->{java_Name};
                $super = 1;
                last;
            }
        }
        if (exists $node->{modifier}) {     # custom
            print $FH " implements org.omg.CORBA.portable.CustomValue";
        }
        else {
            print $FH " implements org.omg.CORBA.portable.StreamableValue";
        }
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_value}) {
            foreach (@{$node->{inheritance}->{list_value}}) {
                my $base = $self->_get_defn($_);
                next unless ($base->isa('AbstractValue'));
                print $FH ", ",$base->{java_Name};
            }
        }
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            foreach (@{$node->{inheritance}->{list_interface}}) {
                my $base = $self->_get_defn($_);
                print $FH ", ",$base->{java_Name},"Operations";
            }
        }
    }
    print $FH "\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        my $mod = ($member->{modifier} eq "private") ? "protected" : "public";
        print $FH "  ",$mod," ",$member->{java_type}," ",$member->{java_name}," = ",$member->{java_init},";\n";
    }
    print $FH $self->{abstract_methodes};
    if ($node->isa('RegularValue')) {
        print $FH "\n";
        print $FH "  private static java.lang.String[] _truncatable_ids = {\n";
        print $FH "    ",$node->{java_Name},"Helper.id ()\n";
        print $FH "  };\n";
        print $FH "\n";
        print $FH "  public java.lang.String[] _truncatable_ids ()\n";
        print $FH "  {\n";
        print $FH "    return _truncatable_ids;\n";
        print $FH "  }\n";
        print $FH "\n";
        unless (exists $node->{modifier}) {     # custom
            print $FH "  public void _read (org.omg.CORBA.portable.InputStream \$is)\n";
            print $FH "  {\n";
            print $FH "    super._read (\$is);\n" if ($super);
            my $idx = 0;
            foreach (@{$node->{list_member}}) {     # StateMember
                my $member = $self->_get_defn($_);
                $self->_member_helper_read($member, $node, \$idx);
            }
            print $FH "  }\n";
            print $FH "\n";
            print $FH "  public void _write (org.omg.CORBA.portable.OutputStream \$os)\n";
            print $FH "  {\n";
            print $FH "    super._write (\$os);\n" if ($super);
            $idx = 0;
            foreach (@{$node->{list_member}}) {     # StateMember
                my $member = $self->_get_defn($_);
                $self->_member_helper_write($member, $node, \$idx);
            }
            print $FH "  }\n";
            print $FH "\n";
            print $FH "  public org.omg.CORBA.TypeCode _type ()\n";
            print $FH "  {\n";
            print $FH "    return ",$node->{java_Name},"Helper.type ();\n";
            print $FH "  }\n";
            print $FH "\n";
        }
        if ($self->{toString}) {
            print $FH "  public java.lang.String toString ()\n";
            print $FH "  {\n";
            print $FH "    java.lang.StringBuffer _ret = new java.lang.StringBuffer (\"valuetype ",$node->{java_name}," {\");\n";
            my $first = 1;
            my $idx = 0;
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);
                if ($first) {
                    print $FH "    _ret.append (\"\\n\");\n";
                    $first = 0;
                }
                else {
                    print $FH "    _ret.append (\",\\n\");\n";
                }
                $self->_member_toString($member, $node, \$idx);
            }
            print $FH "    _ret.append (\"\\n\");\n";
            print $FH "    _ret.append (\"}\");\n";
            print $FH "    return _ret.toString ();\n";
            print $FH "  }\n";
            print $FH "\n";
        }
        if ($self->{equals}) {
            print $FH "  public boolean equals (java.lang.Object o)\n";
            print $FH "  {\n";
            print $FH "    if (this == o) return true;\n";
            print $FH "    if (o == null) return false;\n";
            print $FH "\n";
            print $FH "    if (o instanceof ",$node->{java_name},")\n";
            print $FH "    {\n";
            if (scalar (@{$node->{list_member}})) {
                print $FH "      ",$node->{java_name}," obj = (",$node->{java_name},")o;\n";
                print $FH "      boolean res;\n";
                my $first = 1;
                my $idx = 0;
                foreach (@{$node->{list_member}}) {
                    my $member = $self->_get_defn($_);
                    if ($first) {
                        $first = 0;
                    }
                    else {
                        print $FH "      if (!res) return false;\n";
                    }
                    $self->_member_equals($member, $node, \$idx);
                }
                print $FH "      return res;\n";
            }
            else {
                print $FH "      return true;\n";
            }
            print $FH "    }\n";
            print $FH "    return false;\n";
            print $FH "  }\n";
            print $FH "\n";
            print $FH "  public int hashCode ()\n";
            print $FH "  {\n";
            print $FH "    // this method returns always the same value, to force equals() to be called.\n";
            print $FH "    return 0;\n";
            print $FH "  }\n";
            print $FH "\n";
        }
    }
    print $FH "} // class ",$node->{java_name},"\n";
    close $FH;
}

sub _value_factory {    # non-abstract
    my ($self, $node) = @_;

    $self->open_stream($node, 'ValueFactory.java');
    my $FH = $self->{out};
    print $FH "public interface ",$node->{java_name},"ValueFactory extends org.omg.CORBA.portable.ValueFactory\n";
    print $FH "{\n";
    print $FH $self->{value_factory};
    print $FH "}\n";
    close $FH;
}

sub visitRegularValue {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    $self->{factory} = q{};
    $self->{value_factory} = q{};
    $self->{abstract_methodes} = q{};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $node);
    }

    $self->_holder($node);
    $self->_value_helper($node);
    $self->_value($node);
    $self->_value_factory($node) if ($self->{factory});
    $self->_value_helperXML($node) if ($self->can('_value_helperXML'));

    delete $self->{abstract_methodes};
    delete $self->{factory};
    delete $self->{value_factory};
}

sub visitStateMembers {
    # empty
}

sub visitInitializer {
    my $self = shift;
    my ($node, $value) = @_;

    $self->{value_factory} .= $self->_format_javadoc($node);
    $self->{value_factory} .= "  " . $value->{java_name} . " " . $node->{java_proto} . ";\n";

    if ($node->{java_params}) {
        $self->{factory} .= "  public static " . $value->{java_Name} . " " . $node->{java_name} . " (org.omg.CORBA.ORB \$orb, " . $node->{java_params} . ")\n";
    }
    else {
        $self->{factory} .= "  public static " . $value->{java_Name} . " " . $node->{java_name} . " (org.omg.CORBA.ORB \$orb)\n";
    }
    $self->{factory} .= "  {\n";
    $self->{factory} .= "    try {\n";
    $self->{factory} .= "      " . $value->{java_Name} . "ValueFactory \$factory = (" . $value->{java_Name} . "ValueFactory)\n";
    $self->{factory} .= "          ((org.omg.CORBA_2_3.ORB)\$orb).lookup_value_factory (id ());\n";
    $self->{factory} .= "      return \$factory." . $node->{java_call} . ";\n";
    $self->{factory} .= "    } catch (ClassCastException \$ex) {\n";
    $self->{factory} .= "      throw new org.omg.CORBA.BAD_PARAM ();\n";
    $self->{factory} .= "    }\n";
    $self->{factory} .= "  }\n";
    $self->{factory} .= "\n";
}

#
#   3.9.2   Boxed Value Type
#

sub _boxed_holder {     # primitive type
    my $self = shift;
    my ($node, $type) = @_;
    $self->open_stream($node, 'Holder.java');
    my $FH = $self->{out};
    print $FH "public final class ",$node->{java_helper},"Holder implements org.omg.CORBA.portable.Streamable\n";
    print $FH "{\n";
    print $FH "  public ",$type->{java_Name}," value;\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_helper},"Holder ()\n";
    print $FH "  {\n";
    print $FH "    value = ",$type->{java_init},";\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_helper},"Holder (",$type->{java_Name}," initialValue)\n";
    print $FH "  {\n";
    print $FH "    value = initialValue;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public void _read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    value = ",$node->{java_read},".value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public void _write (org.omg.CORBA.portable.OutputStream \$os)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_helper}," vb = new ",$node->{java_helper}," (value);\n";
    print $FH "    ",$node->{java_write},"vb);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public org.omg.CORBA.TypeCode _type ()\n";
    print $FH "  {\n";
    print $FH "    return ",$node->{java_Helper},".type ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _boxed_helper {
    my ($self, $node, $type, $array, $type2, $array_max) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "public final class ",$node->{java_helper},"Helper implements org.omg.CORBA.portable.BoxedValueHelper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  private static ",$node->{java_helper},"Helper _instance = new ",$node->{java_helper},"Helper ();\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_helper},"Helper()\n";
    print $FH "  {\n";
    print $FH "  }\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    }
    else {
        print $FH "  public static void insert (org.omg.CORBA.Any a, ",$type->{java_Name},@{$array}," that)\n";
    }
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    }
    else {
        print $FH "  public static ",$type->{java_Name},@{$array}," extract (org.omg.CORBA.Any a)\n";
    }
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    print $FH "          __typeCode = ",$type->{java_type_code},";\n";
    foreach (reverse @{$array_max}) {
        if (defined $_) {
            print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_sequence_tc (",$_->{java_literal},", __typeCode);\n";
        }
        else {
            print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_sequence_tc (0, __typeCode);\n";
        }
    }
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_value_box_tc (_id, \"",$node->{java_helper},"\", __typeCode);\n";
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    }
    else {
        print $FH "  public static ",$type->{java_Name},@{$array}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    }
    print $FH "  {\n";
    print $FH "    if (\$is instanceof org.omg.CORBA_2_3.portable.InputStream)\n";
    if (exists $node->{java_primitive}) {
        print $FH "      return (",$node->{java_Name},")((org.omg.CORBA_2_3.portable.InputStream)\$is).read_value (_instance);\n";
    }
    else {
        print $FH "      return (",$type->{java_Name},@{$array},")((org.omg.CORBA_2_3.portable.InputStream)\$is).read_value (_instance);\n";
    }
    print $FH "    else\n";
    print $FH "      throw new org.omg.CORBA.BAD_PARAM ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public java.io.Serializable read_value (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    ",$type->{java_Name},@{$array}," value;\n";
    my @tab = (q{ } x 4);
    my $i = 0;
    my $idx = q{};
    my @array1= @{$array};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @array1;
            print $FH @tab,"value",$idx," = new ",$type->{java_Name}," [",$_->{java_literal},"]",@array1,";\n";
            print $FH @tab,"for (int _o",$i," = 0; _o",$i," < (",$_->{java_literal},"); _o",$i,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_o' . $i . ']';
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@{$array_max}) {
        pop @array1;
        print $FH @tab,"int _len",$i," = \$is.read_long ();\n";
        if (defined $_) {
            print $FH @tab,"if (_len",$i," > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"value",$idx," = new ",$type->{java_Name}," [_len",$i,"]",@array1,";\n";
        print $FH @tab,"for (int _o",$i," = 0; _o",$i," < value",$idx,".length; _o",$i,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_o' . $i . ']';
        $i ++;
        push @tab, q{ } x 2;
    }
    print $FH @tab,"value",$idx," = ",$type2->{java_read},";\n";
    if (($type2->isa('StringType') or $type2->isa('WideStringType')) and exists $type2->{max}) {
        print $FH @tab,"if (value",$idx,".length () > (",$type2->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    foreach (@{$array_max}) {
        pop @tab;
        print $FH @tab,"}\n";
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @tab;
            print $FH @tab,"}\n";
        }
    }
    if (exists $node->{java_primitive}) {
        print $FH "    return new ",$node->{java_Name}," (value);\n";
    }
    else {
        print $FH "    return (java.io.Serializable)value;\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    }
    else {
        print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$type->{java_Name},@{$array}," value)\n";
    }
    print $FH "  {\n";
    print $FH "    if (\$os instanceof org.omg.CORBA_2_3.portable.OutputStream)\n";
    print $FH "      ((org.omg.CORBA_2_3.portable.OutputStream)\$os).write_value (value, _instance);\n";
    print $FH "    else\n";
    print $FH "      throw new org.omg.CORBA.BAD_PARAM ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public void write_value (org.omg.CORBA.portable.OutputStream \$os, java.io.Serializable value)\n";
    print $FH "  {\n";
    if (exists $node->{java_primitive}) {
        print $FH "    if (value instanceof ",$node->{java_Name},")\n";
        print $FH "    {\n";
        print $FH "      ",$node->{java_Name}," valueType = (",$node->{java_Name},")value;\n";
    }
    else {
        print $FH "    if (value instanceof ",$type->{java_Name},@{$array},")\n";
        print $FH "    {\n";
        print $FH "      ",$type->{java_Name},@{$array}," valueType = (",$type->{java_Name},@{$array},")value;\n";
    }
    @tab = (q{ } x 6);
    $i = 0;
    $idx = q{};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            print $FH @tab,"if (valueType",$idx,".length != (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
            print $FH @tab,"for (int _i",$i," = 0; _i",$i," < (",$_->{java_literal},"); _i",$i,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_i' . $i . ']';
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@{$array_max}) {
        if (defined $_) {
            print $FH @tab,"if (valueType",$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"\$os.write_long (valueType",$idx,".length);\n";
        print $FH @tab,"for (int _i",$i," = 0; _i",$i," < valueType",$idx,".length; _i",$i,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_i' . $i . ']';
        $i ++;
        push @tab, q{ } x 2;
    }
    if (($type2->isa('StringType') or $type2->isa('WideStringType')) and exists $type2->{max}) {
        print $FH @tab,"if (valueType",$idx,".length () > (",$type2->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    if (exists $node->{java_primitive}) {
        print $FH @tab,$type2->{java_write},"valueType.value);\n";
    }
    else {
        print $FH @tab,$type2->{java_write},"valueType",$idx,");\n";
    }
    foreach (@{$array_max}) {
        pop @tab;
        print $FH @tab,"}\n";
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @tab;
            print $FH @tab,"}\n";
        }
    }
    print $FH "    } else\n";
    print $FH "      throw new org.omg.CORBA.MARSHAL ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public java.lang.String get_id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _boxed {        # primitive type
    my ($self, $node, $type) = @_;

    $self->open_stream($node, '.java');
    my $FH = $self->{out};
    print $FH $self->_format_javadoc($node);
    print $FH "public class ",$node->{java_name}," implements org.omg.CORBA.portable.ValueBase\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    print $FH "  public ",$type->{java_Name}," value;\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_Name}," (",$type->{java_Name}," initial)\n";
    print $FH "  {\n";
    print $FH "    value = initial;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static java.lang.String[] _truncatable_ids = {\n";
    print $FH "    ",$node->{java_Name},"Helper.id ()\n";
    print $FH "  };\n";
    print $FH "\n";
    print $FH "  public java.lang.String[] _truncatable_ids()\n";
    print $FH "  {\n";
    print $FH "    return _truncatable_ids;\n";
    print $FH "  }\n";
    print $FH "\n";
    if ($self->{toString}) {
        print $FH "  public java.lang.String toString ()\n";
        print $FH "  {\n";
        print $FH "    java.lang.StringBuffer _ret = new java.lang.StringBuffer (\"valuebox ",$node->{java_name}," {\");\n";
        print $FH "    _ret.append (\"",$type->{java_Name}," value=\");\n";
        print $FH "    _ret.append (value);\n";
        print $FH "    _ret.append (\"\\n\");\n";
        print $FH "    _ret.append (\"}\");\n";
        print $FH "    return _ret.toString ();\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    if ($self->{equals}) {
        print $FH "  public boolean equals (java.lang.Object o)\n";
        print $FH "  {\n";
        print $FH "    if (this == o) return true;\n";
        print $FH "    if (o == null) return false;\n";
        print $FH "\n";
        print $FH "    if (o instanceof ",$node->{java_name},")\n";
        print $FH "    {\n";
        print $FH "      ",$node->{java_name}," obj = (",$node->{java_name},")o;\n";
        print $FH "      return (this.value == obj.value);\n";
        print $FH "    }\n";
        print $FH "    return false;\n";
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public int hashCode ()\n";
        print $FH "  {\n";
        print $FH "    // this method returns always the same value, to force equals() to be called.\n";
        print $FH "    return 0;\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    print $FH "} // class ",$node->{java_name},"\n";
    close $FH;
}

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType') ) {
        $type->visit($self);
    }
    if (exists $node->{java_primitive}) {
        $self->_boxed_holder($node, $type);
        $self->_boxed($node, $type);
        $self->_boxed_helper($node, $type, [], $type, []);
        $self->_boxed_helperXML($node, $type, [], $type, [])
                if ($self->can("_boxed_helperXML"));
    }
    else {
        my @array = ();
        my @array_max = ();
        while (     $type->isa('TypeDeclarator')
                and ! exists $type->{array_size} ) {
            $type = $self->_get_defn($type->{type});
        }
        while ($type->isa('SequenceType')) {
            push @array, '[]';
            if (exists $type->{max}) {
                push @array_max, $type->{max};
            }
            else {
                push @array_max, undef;
            }
            $type = $self->_get_defn($type->{type});
            while (     $type->isa('TypeDeclarator')
                    and ! exists $type->{array_size} ) {
                $type = $self->_get_defn($type->{type});
            }
        }
        my $type2 = $type;
        while ($type->isa('TypeDeclarator')) {
            foreach (@{$type->{array_size}}) {
                push @array, '[]';
            }
            $type = $self->_get_defn($type->{type});
        }
        while ($type->isa('SequenceType')) {
            push @array, '[]';
            if (exists $type->{max}) {
                push @array_max, $type->{max};
            }
            else {
                push @array_max, undef;
            }
            $type = $self->_get_defn($type->{type});
            while (     $type->isa('TypeDeclarator')
                    and ! exists $type->{array_size} ) {
                $type = $self->_get_defn($type->{type});
            }
        }
        $self->_holder($node, $type, @array);
        $self->_boxed_helper($node, $type, \@array, $type2, \@array_max);
        $self->_boxed_helperXML($node, $type, \@array, $type2, \@array_max)
                if ($self->can('_boxed_helperXML'));
    }
}

#
#   3.9.3   Abstract Value Type
#

sub visitAbstractValue {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    $self->{factory} = q{};
    $self->{value_factory} = q{};
    $self->{abstract_methodes} = q{};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self, $node);
    }

    $self->_holder($node);
    $self->_value_helper($node);
    $self->_value($node);
    $self->_value_helperXML($node) if ($self->can('_value_helperXML'));

    delete $self->{abstract_methodes};
    delete $self->{factory};
    delete $self->{value_factory};
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    my $type = $self->_get_defn($node->{type});
    while (     $type->isa('TypeDeclarator')
            and ! exists $type->{array_size} ) {
        $type = $self->_get_defn($type->{type});
    }
    my $value = $node->{value};
    my $defn;
    my $pkg = $node->{full};
    $pkg =~ s/::[0-9A-Z_a-z]+$//;
    $defn = $self->{symbtab}->Lookup($pkg) if ($pkg);
    if ( defined $defn and $defn->isa('BaseInterface') ) {
        $self->{constants} .= $self->_format_javadoc($node);
        $self->{constants} .= "  public static final " . $type->{java_Name} . " " . $node->{java_name} . " = ";
        if (       $type->isa('FloatingPtType')
                or $type->isa('IntegerType')
                or $type->isa('CharType')
                or $type->isa('WideCharType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('BooleanType')
                or $type->isa('OctetType')
                or $type->isa('EnumType') ) {
            $self->{constants} .= $value->{java_literal} . ";\n";
        }
        else {
            $self->{constants} .= "new " . $type->{java_Name} . " (" . $value->{java_literal} . ");\n";
        }
    }
    else {
        $self->open_stream($node, '.java');
        my $FH = $self->{out};
        print $FH $self->_format_javadoc($node);
        print $FH "public interface ",$node->{java_name},"\n";
        print $FH "{\n";
        print $FH "  public static final ",$type->{java_Name}," value = ";
        if (       $type->isa('FloatingPtType')
                or $type->isa('IntegerType')
                or $type->isa('CharType')
                or $type->isa('WideCharType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('BooleanType')
                or $type->isa('OctetType')
                or $type->isa('EnumType') ) {
            print $FH $value->{java_literal},";\n";
        }
        else {
            print $FH "new ",$type->{java_Name}," (",$value->{java_literal},");\n";
        }
        print $FH "}\n";
        close $FH;
    }
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

sub _typedeclarator_helper {
    my ($self, $node, $type, $array, $type2, $array_max) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH $self->_format_javadoc($node);
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$type->{java_Name},@{$array}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$type->{java_Name},@{$array}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
##  print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
##  print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
##  print $FH "      {\n";
##  print $FH "        if (__typeCode == null)\n";
##  print $FH "        {\n";
##  print $FH "          if (__active)\n";
##  print $FH "          {\n";
##  print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
##  print $FH "          }\n";
##  print $FH "          __active = true;\n";
    print $FH "          __typeCode = ",$type->{java_type_code},";\n";
    foreach (reverse @{$array_max}) {
        if (defined $_) {
            print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_sequence_tc (",$_->{java_literal},", __typeCode);\n";
        }
        else {
            print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_sequence_tc (0, __typeCode);\n";
        }
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_array_tc (",$_->{java_literal},", __typeCode );\n";
        }
    }
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_alias_tc (",$node->{java_Helper},".id (), \"",$node->{java_helper},"\", __typeCode);\n";
##  print $FH "          __active = false;\n";
##  print $FH "        }\n";
##  print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$type->{java_Name},@{$array}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    if (scalar(@{$array})) {
        print $FH "    ",$type->{java_Name}," value",@{$array}," = null;\n";
    }
    else {
        print $FH "    ",$type->{java_Name}," value = ",$type->{java_init},";\n";
    }
    my @tab = (q{ } x 4);
    my $i = 0;
    my $idx = q{};
    my @array1= @{$array};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @array1;
            print $FH @tab,"value",$idx," = new ",$type->{java_Name}," [",$_->{java_literal},"]",@array1,";\n";
            print $FH @tab,"for (int _o",$i," = 0; _o",$i," < (",$_->{java_literal},"); _o",$i,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_o' . $i . ']';
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@{$array_max}) {
        pop @array1;
        print $FH @tab,"int _len",$i," = \$is.read_long ();\n";
        if (defined $_) {
            print $FH @tab,"if (_len",$i," > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"value",$idx," = new ",$type->{java_Name}," [_len",$i,"]",@array1,";\n";
        print $FH @tab,"for (int _o",$i," = 0; _o",$i," < value",$idx,".length; _o",$i,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_o' . $i . ']';
        $i ++;
        push @tab, q{ } x 2;
    }
    print $FH @tab,"value",$idx," = ",$type2->{java_read},";\n";
    if (($type2->isa('StringType') or $type2->isa('WideStringType')) and exists $type2->{max}) {
        print $FH @tab,"if (value",$idx,".length () > (",$type2->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    foreach (@{$array_max}) {
        pop @tab;
        print $FH @tab,"}\n";
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @tab;
            print $FH @tab,"}\n";
        }
    }
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$type->{java_Name},@{$array}," value)\n";
    print $FH "  {\n";
    @tab = (q{ } x 4);
    $i = 0;
    $idx = q{};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            print $FH @tab,"if (value",$idx,".length != (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
            print $FH @tab,"for (int _i",$i," = 0; _i",$i," < (",$_->{java_literal},"); _i",$i,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_i' . $i . ']';
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@{$array_max}) {
        if (defined $_) {
            print $FH @tab,"if (value",$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"\$os.write_long (value",$idx,".length);\n";
        print $FH @tab,"for (int _i",$i," = 0; _i",$i," < value",$idx,".length; _i",$i,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_i' . $i . ']';
        $i ++;
        push @tab, q{ } x 2;
    }
    if (($type2->isa('StringType') or $type2->isa('WideStringType')) and exists $type2->{max}) {
        print $FH @tab,"if (value",$idx,".length () > (",$type2->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    print $FH @tab,$type2->{java_write},"value",$idx,");\n";
    foreach (@{$array_max}) {
        pop @tab;
        print $FH @tab,"}\n";
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @tab;
            print $FH @tab,"}\n";
        }
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType') ) {
        $type->visit($self);
    }
    while (     $type->isa('TypeDeclarator')
            and ! exists $type->{array_size} ) {
        $type = $self->_get_defn($type->{type});
    }
    my @array_max = ();
    my @array = ();
    while ($type->isa('SequenceType')) {
        push @array, '[]';
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        $type = $self->_get_defn($type->{type});
        while (     $type->isa('TypeDeclarator')
                and ! exists $type->{array_size} ) {
            $type = $self->_get_defn($type->{type});
        }
    }
    my $type2 = $type;

    if (exists $node->{array_size} or exists $type->{array_size} or scalar(@array)) {
        if (exists $node->{array_size}) {
            foreach (@{$node->{array_size}}) {
                push @array, '[]';
            }
        }
        while ($type->isa('TypeDeclarator')) {
            foreach (@{$type->{array_size}}) {
                push @array, '[]';
            }
            $type = $self->_get_defn($type->{type});
        }
        while ($type->isa('SequenceType')) {
            push @array, '[]';
            $type = $self->_get_defn($type->{type});
            while (     $type->isa('TypeDeclarator')
                    and ! exists $type->{array_size} ) {
                $type = $self->_get_defn($type->{type});
            }
        }
        $self->_holder($node, $type, @array);
        $self->_typedeclarator_helper($node, $type, \@array, $type2, \@array_max);
        $self->_typedeclarator_helperXML($node, $type, \@array, $type2, \@array_max)
                if ($self->can('_typedeclarator_helperXML'));
    }
    else {
        while (     $type->isa('TypeDeclarator')
                and ! exists $type->{array_size} ) {
            $type = $self->_get_defn($type->{type});
        }
        $self->_typedeclarator_helper($node, $type, \@array, $type2, \@array_max);
        $self->_typedeclarator_helperXML($node, $type, \@array, $type2, \@array_max)
                if ($self->can('_typedeclarator_helperXML'));
    }
}

sub _native_helper {
    my ($self, $node) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    throw new org.omg.CORBA.MARSHAL();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    throw new org.omg.CORBA.MARSHAL();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      __typeCode = org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_objref);\n";
    print $FH "      __typeCode = org.omg.CORBA.ORB.init ().create_alias_tc (",$node->{java_Helper},".id (), \"",$node->{java_helper},"\", __typeCode);\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    throw new org.omg.CORBA.MARSHAL();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    throw new org.omg.CORBA.MARSHAL();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub visitNativeType {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    $self->_native_helper($node);
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub _struct_helper {
    my ($self, $node) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    print $FH "          org.omg.CORBA.StructMember[] _members0 = new org.omg.CORBA.StructMember [",scalar(@{$node->{list_member}}),"];\n";
    print $FH "          org.omg.CORBA.TypeCode _tcOf_members0 = null;\n";
    my $i = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helper_type($member, $node, $i);
        $i ++;
    }
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_struct_tc (_id, \"",$node->{java_name},"\", _members0);\n";
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
    my $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helper_read($member, $node, \$idx);
    }
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helper_write($member, $node, \$idx);
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _struct {
    my ($self, $node) = @_;

    $self->open_stream($node, '.java');
    my $FH = $self->{out};
    print $FH $self->_format_javadoc($node);
    print $FH "public final class ",$node->{java_name}," implements org.omg.CORBA.portable.IDLEntity\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH $self->_format_javadoc($member);
        print $FH "  public ",$member->{java_type}," ",$member->{java_name},";\n";
    }
    print $FH "\n";
    print $FH "  public ",$node->{java_name}," ()\n";
    print $FH "  {\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH "    ",$member->{java_name}," = ",$member->{java_init},";\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_name}," (";
    my $first = 1;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH ", " unless ($first);
        print $FH $member->{java_type}," _",$member->{java_name};
        $first = 0;
    }
    print $FH ")\n";
    print $FH "  {\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH "    ",$member->{java_name}," = _",$member->{java_name},";\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    if ($self->{toString}) {
        print $FH "  public java.lang.String toString ()\n";
        print $FH "  {\n";
        print $FH "    java.lang.StringBuffer _ret = new java.lang.StringBuffer (\"struct ",$node->{java_name}," {\");\n";
        $first = 1;
        my $idx = 0;
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            if ($first) {
                $first = 0;
            }
            else {
                print $FH "    _ret.append (\",\");\n";
            }
            $self->_member_toString($member, $node, \$idx);
        }
        print $FH "    _ret.append (\"\\n}\");\n";
        print $FH "    return _ret.toString ();\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    if ($self->{equals}) {
        print $FH "  public boolean equals (java.lang.Object o)\n";
        print $FH "  {\n";
        print $FH "    if (this == o) return true;\n";
        print $FH "    if (o == null) return false;\n";
        print $FH "\n";
        print $FH "    if (o instanceof ",$node->{java_name},")\n";
        print $FH "    {\n";
        print $FH "      ",$node->{java_name}," obj = (",$node->{java_name},")o;\n";
        print $FH "      boolean res;\n";
        $first = 1;
        my $idx = 0;
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            if ($first) {
                $first = 0;
            }
            else {
                print $FH "      if (!res) return false;\n";
            }
            $self->_member_equals($member, $node, \$idx);
        }
        print $FH "      return res;\n";
        print $FH "    }\n";
        print $FH "    return false;\n";
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public int hashCode ()\n";
        print $FH "  {\n";
        print $FH "    // this method returns always the same value, to force equals() to be called.\n";
        print $FH "    return 0;\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    print $FH "} // class ",$node->{java_name},"\n";
    close $FH;
}

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    return if (exists $self->{done_hash}->{$node->{java_Name}});
    $self->{done_hash}->{$node->{java_Name}} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType') ) {
            $type->visit($self);
        }
    }

    $self->_holder($node);
    $self->_struct_helper($node);
    $self->_struct($node);
    $self->_struct_helperXML($node) if ($self->can('_struct_helperXML'));
}

sub _member_helper_type {
    my $self = shift;
    my ($member, $parent, $i) = @_;

    my $FH = $self->{out};
    my $tab = '          ';
    my $type = $self->_get_defn($member->{type});
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        $type = $self->_get_defn($type->{type});
        while ($type->isa('TypeDeclarator')) {
            $type = $self->_get_defn($type->{type});
        }
    }
    print $FH $tab,"_tcOf_members0 = ",$type->{java_type_code},";\n";
    foreach (reverse @array_max) {
        if (defined $_) {
            print $FH $tab,"_tcOf_members0 = org.omg.CORBA.ORB.init ().create_sequence_tc (",$_->{java_literal},", _tcOf_members0);\n";
        }
        else {
            print $FH $tab,"_tcOf_members0 = org.omg.CORBA.ORB.init ().create_sequence_tc (0, _tcOf_members0);\n";
        }
    }
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            print $FH $tab,"_tcOf_members0 = org.omg.CORBA.ORB.init ().create_array_tc (",$_->{java_literal},", _tcOf_members0 );\n";
        }
    }
    if    ($parent->isa('Value')) {
        print $FH $tab,"_members0[",$i,"] = new org.omg.CORBA.ValueMember (\n";
    }
    elsif ($parent->isa('UnionType')) {
        print $FH $tab,"_members0[",$i,"] = new org.omg.CORBA.UnionMember (\n";
    }
    else {  # StructType or ExceptionType
        print $FH $tab,"_members0[",$i,"] = new org.omg.CORBA.StructMember (\n";
    }
    print $FH $tab,"  \"",$member->{java_name},"\",\n";
    if    ($parent->isa('Value')) {
        print $FH $tab,"  \"\",\n";
        print $FH $tab,"  _id,\n";
        print $FH $tab,"  \"\",\n";
    }
    elsif ($parent->isa('UnionType')) {
        print $FH $tab,"  _anyOf_members0,\n";
    }
    print $FH $tab,"  _tcOf_members0,\n";
    if      ($parent->isa('Value')) {
        my $mod = ($member->{modifier} eq "private") ? "PRIVATE_MEMBER" : "PUBLIC_MEMBER";
        print $FH $tab,"  null,\n";
        print $FH $tab,"  org.omg.CORBA.",$mod,".value);\n";
    }
    else {
        print $FH $tab,"  null);\n";
    }
}

sub _member_helper_read {
    my $self = shift;
    my ($member, $parent, $r_idx) = @_;

    my $FH = $self->{out};
    my $label = q{};
    unless ($member->isa('StateMember')) {
        if ($parent->isa('UnionType')) {
            $label = '_';
        }
        else {  # StructType or ExceptionType
            $label = 'value.';
        }
    }
    my $type = $self->_get_defn($member->{type});
    my $typeh = $type;
    my $name = $member->{java_name};
    my @tab = (q{ } x 4);
    push @tab, q{ } x 4 if ($parent->isa('UnionType'));
    my $idx = q{};
    my @array1 = ();
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            push @array1, '[]';
        }
    }
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        push @array1, '[]';
        $type = $self->_get_defn($type->{type});
        while ($type->isa('TypeDeclarator')) {
            if (exists $type->{array_size}) {
                foreach (@{$type->{array_size}}) {
                    push @array1, '[]';
                }
            }
            $type = $self->_get_defn($type->{type});
        }
    }
    while ($typeh->isa('SequenceType')) {
        if (exists $typeh->{max}) {
            push @array_max, $typeh->{max};
        }
        else {
            push @array_max, undef;
        }
        $typeh = $self->_get_defn($typeh->{type});
    }
    if ($parent->isa('UnionType')) {
        print $FH @tab,$member->{java_type}," _",$member->{java_name}," = ",$member->{java_init},";\n";
    }
    if (exists $member->{array_size}) {
        my $java_array = $member->{java_array};
        foreach (@{$member->{array_size}}) {
            $java_array =~ s/^\[\]/\[$_->{java_literal}\]/;
            if ($parent->isa('UnionType')) {
                print $FH @tab,"_",$name,$idx," = new ",$member->{type_java}->{java_Name}," ",$java_array,";\n";
            }
            else {  # StructType or ExceptionType
                print $FH @tab,$label,$name,$idx," = new ",$member->{type_java}->{java_Name}," ",$java_array,";\n";
            }
            print $FH @tab,"for (int _o",$$r_idx," = 0; _o",$$r_idx," < (",$_->{java_literal},"); _o",$$r_idx,"++)\n";
            print $FH @tab,"{\n";
            $java_array =~ s/^\[[^\]]+\]//;
            pop @array1;
            $idx .= '[_o' . $$r_idx . ']';
            $$r_idx ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@array_max) {
        pop @array1;
        print $FH @tab,"int _len",$$r_idx," = \$is.read_long ();\n";
        if (defined $_) {
            print $FH @tab,"if (_len",$$r_idx," > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        if ($parent->isa('UnionType')) {
            print $FH @tab,"_",$name,$idx," = new ",$type->{java_Name}," [_len",$$r_idx,"]",@array1,";\n";
        }
        else {  # StructType or ExceptionType
            print $FH @tab,$label,$name,$idx," = new ",$type->{java_Name}," [_len",$$r_idx,"]",@array1,";\n";
        }
        print $FH @tab,"for (int _o",$$r_idx," = 0; _o",$$r_idx," < ",$label,$name,$idx,".length; _o",$$r_idx,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_o' . $$r_idx . ']';
        $$r_idx ++;
        push @tab, q{ } x 2;
    }
    if ($parent->isa('UnionType')) {
        print $FH @tab,"_",$name,$idx," = ",$typeh->{java_read},";\n";
    }
    else {  # StructType or ExceptionType
        print $FH @tab,$label,$name,$idx," = ",$typeh->{java_read},";\n";
    }
    if (($type->isa('StringType') or $type->isa('WideStringType')) and exists $type->{max}) {
        print $FH @tab,"if (",$label,$name,$idx,".length () > (",$type->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    foreach (@array_max) {
        pop @tab;
        print $FH @tab,"}\n";
    }
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            pop @tab;
            print $FH @tab,"}\n";
        }
    }
}

sub _member_helper_write {
    my $self = shift;
    my ($member, $parent, $r_idx) = @_;

    my $FH = $self->{out};
    my $label = ($member->isa('StateMember')) ? q{} : 'value.';
    my $len = ($parent->isa('UnionType')) ? ' ()' : q{};
    my $type = $self->_get_defn($member->{type});
    my $typeh = $type;
    my $name = $member->{java_name};
    my @tab = (q{ } x 4);
    push @tab, q{ } x 4 if ($parent->isa('UnionType'));
    my $idx = q{};
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            print $FH @tab,"if (",$label,$name,$len,$idx,".length != (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
            print $FH @tab,"for (int _i",$$r_idx," = 0; _i",$$r_idx," < (",$_->{java_literal},"); _i",$$r_idx,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_i' . $$r_idx . ']';
            $$r_idx ++;
            push @tab, q{ } x 2;
        }
    }
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        $type = $self->_get_defn($type->{type});
        while ($type->isa('TypeDeclarator')) {
            $type = $self->_get_defn($type->{type});
        }
    }
    while ($typeh->isa('SequenceType')) {
        if (exists $typeh->{max}) {
            push @array_max, $typeh->{max};
        }
        else {
            push @array_max, undef;
        }
        $typeh = $self->_get_defn($typeh->{type});
    }
    foreach (@array_max) {
        if (defined $_) {
            print $FH @tab,"if (",$label,$name,$len,$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"\$os.write_long (",$label,$name,$len,$idx,".length);\n";
        print $FH @tab,"for (int _i",$$r_idx," = 0; _i",$$r_idx," < ",$label,$name,$len,$idx,".length; _i",$$r_idx,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_i' . $$r_idx . ']';
        $$r_idx ++;
        push @tab, q{ } x 2;
    }
    if (($type->isa('StringType') or $type->isa('WideStringType')) and exists $type->{max}) {
        print $FH @tab,"if (",$label,$name,$len,$idx,".length () > (",$type->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    if ($parent->isa('UnionType')) {
        print $FH @tab,$typeh->{java_write},$label,$name," ()",$idx,");\n";
    }
    else {  # StructType or ExceptionType
        print $FH @tab,$typeh->{java_write},$label,$name,$idx,");\n";
    }
    foreach (@array_max) {
        pop @tab;
        print $FH @tab,"}\n";
    }
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            pop @tab;
            print $FH @tab,"}\n";
        }
    }
}

sub _member_toString {
    my $self = shift;
    my ($member, $parent, $r_idx) = @_;

    my $FH = $self->{out};
    my $name = $member->{java_name};
    my $label = q{};
    my $len = ($parent->isa('UnionType')) ? ' ()' : q{};
    my @tab = (q{ } x 4);
    push @tab, q{ } x 4 if ($parent->isa('UnionType'));
    print $FH @tab,"_ret.append (\"\\n",$member->{java_type}," ",$member->{java_name},"=\");\n";
    my $idx = q{};
    foreach (my $a = 0; $a < length($member->{java_array})/2; $a ++) {
        print $FH @tab,"_ret.append (\"{\");\n";
        print $FH @tab,"if (",$label,$name,$len,$idx," == null)\n";
        print $FH @tab,"{\n";
        print $FH @tab,"  _ret.append (",$label,$name,$len,$idx,");\n";
        print $FH @tab,"}\n";
        print $FH @tab,"else\n";
        print $FH @tab,"{\n";
        print $FH @tab,"  for (int _i",$$r_idx," = 0; _i",$$r_idx," < ",$label,$name,$len,$idx,".length; _i",$$r_idx,"++)\n";
        print $FH @tab,"  {\n";
        unless ($member->{type_java}->isa("BasicType")) {
            print $FH @tab,"    _ret.append (\"\\n\");\n";
        }
        $idx .= '[_i' . $$r_idx . ']';
        $$r_idx ++;
        push @tab, q{ } x 4;
    }
    if ($parent->isa('UnionType')) {
        if (       $member->{type_java}->isa('StringType')
                or $member->{type_java}->isa('WideStringType') ) {
            print $FH @tab,"_ret.append (",$label,$name," ()",$idx," != null ? '\\\"' + ",$label,$name," ()",$idx," + '\\\"' : null);\n";
        }
        else {
            print $FH @tab,"_ret.append (",$label,$name," ()",$idx,");\n";
        }
    }
    else {  # StructType or ExceptionType
        if (       $member->{type_java}->isa('StringType')
                or $member->{type_java}->isa('WideStringType') ) {
            print $FH @tab,"_ret.append (",$label,$name,$idx," != null ? '\\\"' + ",$label,$name,$idx," + '\\\"' : null);\n";
        }
        else {
            print $FH @tab,"_ret.append (",$label,$name,$idx,");\n";
        }
    }
    foreach (my $a = 0; $a < length($member->{java_array})/2; $a ++) {
        pop @tab;
        $idx =~ s/\[[^\]]+\]$//;
        print $FH @tab,"    if (_i",$$r_idx-$a-1," < ",$label,$name,$len,$idx,".length - 1)\n";
        print $FH @tab,"    {\n";
        print $FH @tab,"      _ret.append (\",\");\n";
        print $FH @tab,"    }\n";
        print $FH @tab,"  }\n";
        unless ($member->{type_java}->isa("BasicType")) {
            print $FH @tab,"  _ret.append (\"\\n\");\n";
        }
        print $FH @tab,"  _ret.append (\"}\");\n";
        print $FH @tab,"}\n";
    }
}

sub _member_equals {
    my $self = shift;
    my ($member, $parent, $r_idx) = @_;

    my $FH = $self->{out};
    my $name = $member->{java_name};
    my $label = q{};
    my @tab = (q{ } x 6);
    my $idx = q{};
    foreach (my $a = 0; $a < length($member->{java_array})/2; $a ++) {
        print $FH @tab,"if (res = (this.",$label,$name,$idx,".length == obj.",$label,$name,$idx,".length))\n";
        print $FH @tab,"{\n";
        print $FH @tab,"  for (int _i",$$r_idx," = 0; res && _i",$$r_idx," < this.",$label,$name,$idx,".length; _i",$$r_idx,"++)\n";
        print $FH @tab,"  {\n";
        $idx .= '[_i' . $$r_idx . ']';
        $$r_idx ++;
        push @tab, q{ } x 4;
    }
    if (       $member->{type_java}->isa('StringType')
            or $member->{type_java}->isa('WideStringType')
            or $member->{type_java}->isa('StructType')
            or $member->{type_java}->isa('UnionType')
            or $member->{type_java}->isa('Interface')
            or $member->{type_java}->isa('Value') ) {
        print $FH @tab,"res = (this.",$label,$name,$idx," == null && obj.",$label,$name,$idx," == null) || (this.",$label,$name,$idx," != null && this.",$member->{java_name},".equals(obj.",$label,$name,$idx,"));\n";
    }
    else {
        print $FH @tab,"res = (this.",$label,$name,$idx," == obj.",$label,$name,$idx,");\n";
    }
    foreach (my $a = 0; $a < length($member->{java_array})/2; $a ++) {
        pop @tab;
        print $FH @tab,"  }\n";
        print $FH @tab,"}\n";
    }
}

#   3.11.2.2    Discriminated Unions
#

sub _union_helper {
    my ($self, $node, $dis, $effective_dis) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    print $FH "          org.omg.CORBA.TypeCode _disTypeCode0;\n";
    if ($effective_dis->isa('EnumType')) {
        print $FH "          _disTypeCode0 = ",$dis->{java_Name},"Helper.type ();\n";
    }
    else {
        print $FH "          _disTypeCode0 = org.omg.CORBA.ORB.init ().get_primitive_tc (org.omg.CORBA.TCKind.tk_",$dis->{java_tk},");\n";
    }
    print $FH "          org.omg.CORBA.UnionMember[] _members0 = new org.omg.CORBA.UnionMember [",scalar(keys %{$node->{hash_member}}),"];\n";
    print $FH "          org.omg.CORBA.TypeCode _tcOf_members0;\n";
    print $FH "          org.omg.CORBA.Any _anyOf_members0;\n";
    my $i = 0;
    foreach my $case (@{$node->{list_expr}}) {
        my $elt = $case->{element};
        my $value = $self->_get_defn($elt->{value});
        foreach (@{$case->{list_label}}) {  # default or expression
            print $FH "\n";
            if ($_->isa('Default')) {
                print $FH "          // Branch for ",$value->{java_name}," (Default case)\n";
                print $FH "          _anyOf_members0 = org.omg.CORBA.ORB.init ().create_any ();\n";
                print $FH "          _anyOf_members0.insert_octet ((byte)0); // default member label\n";
            }
            else {
                print $FH "          // Branch for ",$value->{java_name}," (case label ",$_->{java_literal},")\n";
                print $FH "          _anyOf_members0 = org.omg.CORBA.ORB.init ().create_any ();\n";
                if ($effective_dis->isa('EnumType')) {
                    print $FH "          ",$dis->{java_Name},"Helper.insert (_anyOf_members0, ",$_->{value}->{java_literal},");\n";
                }
                else {
                    print $FH "          _anyOf_members0.insert_",$dis->{java_tk}," (",$_->{java_literal},");\n";
                    # TODO
                }
            }
            $self->_member_helper_type($value, $node, $i);
            $i ++;
        }
    }
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_union_tc (_id, \"",$node->{java_name},"\", _disTypeCode0, _members0);\n";
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
    print $FH "    ",$effective_dis->{java_Name}," _dis0 = ",$effective_dis->{java_init},";\n";
    print $FH "    _dis0 = ",$dis->{java_read},";\n";
    if    ($effective_dis->isa('EnumType')) {
        print $FH "    switch (_dis0.value ())\n";
    }
    elsif ($effective_dis->isa('BooleanType')) {
        print $FH "    int __dis0 = (_dis0) ? 1 : 0;\n";
        print $FH "    switch (__dis0)\n";
    }
    else {
        print $FH "    switch (_dis0)\n";
    }
    print $FH "    {\n";
    my $idx = 0;
    foreach my $case (@{$node->{list_expr}}) {
        my $flag_default = 0;
        foreach (@{$case->{list_label}}) {  # default or expression
            if ($_->isa('Default')) {
                print $FH "      default:\n";
                $flag_default = 1;
            }
            else {
                if ($effective_dis->isa('BooleanType')) {
                    my $value = ($_->{value} eq 'TRUE') ? '1' : '0';
                    print $FH "      case ",$value,":\n";
                }
                else {
                    print $FH "      case ",$_->{java_literal},":\n";
                }
            }
        }
        my $elt = $case->{element};
        my $value = $self->_get_defn($elt->{value});
        $self->_member_helper_read($value, $node, \$idx);
        if (scalar(@{$case->{list_label}}) > 1 || $flag_default) {
            print $FH "        value.",$value->{java_name}," (_dis0, _",$value->{java_name},");\n";
        }
        else {
            print $FH "        value.",$value->{java_name}," (_",$value->{java_name},");\n";
        }
        print $FH "        break;\n";
    }
    if (exists $node->{need_default}) {
        print $FH "      default:\n";
        print $FH "        throw new org.omg.CORBA.BAD_OPERATION ();\n";
    }
    print $FH "    }\n";
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    ",$dis->{java_write},"value.discriminator ());\n";
    if    ($effective_dis->isa('EnumType')) {
        print $FH "    switch (value.discriminator ().value ())\n";
    }
    elsif ($effective_dis->isa('BooleanType')) {
        print $FH "    int _dis = (value.discriminator ()) ? 1 : 0;\n";
        print $FH "    switch (_dis)\n";
    }
    else {
        print $FH "    switch (value.discriminator ())\n";
    }
    print $FH "    {\n";
    $idx = 0;
    foreach my $case (@{$node->{list_expr}}) {
        foreach (@{$case->{list_label}}) {  # default or expression
            if ($_->isa('Default')) {
                print $FH "      default:\n";
            }
            else {
                if ($effective_dis->isa('BooleanType')) {
                    my $value = ($_->{value} eq 'TRUE') ? '1' : '0';
                    print $FH "      case ",$value,":\n";
                }
                else {
                    print $FH "      case ",$_->{java_literal},":\n";
                }
            }
        }
        my $elt = $case->{element};
        my $value = $self->_get_defn($elt->{value});
        $self->_member_helper_write($value, $node, \$idx);
        print $FH "        break;\n";
    }
    if (exists $node->{need_default}) {
        print $FH "      default:\n";
        print $FH "        throw new org.omg.CORBA.BAD_OPERATION ();\n";
    }
    print $FH "    }\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _union {
    my ($self, $node, $dis, $effective_dis) = @_;

    $self->open_stream($node, '.java');
    my $FH = $self->{out};
    my $first;
    my $find;
    print $FH $self->_format_javadoc($node);
    print $FH "public final class ",$node->{java_name}," implements org.omg.CORBA.portable.IDLEntity\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    print $FH "  private java.lang.Object __object;\n";
    print $FH "  private ",$effective_dis->{java_Name}," __discriminator;\n";
    print $FH "  private boolean __uninitialized;\n";
    print $FH "\n";
    print $FH "  public ",$node->{java_name}," ()\n";
    print $FH "  {\n";
    print $FH "    __object = null;\n";
    print $FH "    __uninitialized = true;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public ",$effective_dis->{java_Name}," discriminator ()\n";
    print $FH "  {\n";
    print $FH "    if (__uninitialized)\n";
    print $FH "      throw new org.omg.CORBA.BAD_OPERATION ();\n";
    print $FH "    return __discriminator;\n";
    print $FH "  }\n";
    print $FH "\n";
    foreach my $case (@{$node->{list_expr}}) {
        my $elt = $case->{element};
        my $value = $self->_get_defn($elt->{value});
        my $type = $self->_get_defn($elt->{type});
        my $flag_default = 0;
        foreach (@{$case->{list_label}}) {  # default or expression
            if ($_->isa('Default')) {
                $flag_default = 1;
                last;
            }
        }
        my $label;
        print $FH $self->_format_javadoc($value);
        print $FH "  public ",$value->{java_type}," ",$value->{java_name}," ()\n";
        print $FH "  {\n";
        print $FH "    if (__uninitialized)\n";
        print $FH "      throw new org.omg.CORBA.BAD_OPERATION ();\n";
        my $cond = q{};
        if ($flag_default) {
            $first = 1;
            foreach (@{$node->{list_member}}) {
                $find = 0;
                foreach my $label (@{$case->{list_label}}) {
                    $find = 1 if ($_ == $label);
                }
                next if ($find);
                $cond .= "\n     || " unless ($first);
                if ($effective_dis->isa('EnumType')) {
                    $cond .= "__discriminator == " . $_->{value}->{java_literal};
                }
                else {
                    $cond .= "__discriminator == " . $_->{java_literal};
                }
                $first = 0;
            }
        }
        else {
            $first = 1;
            foreach (@{$case->{list_label}}) {
                $cond .= "\n     && " unless ($first);
                if ($effective_dis->isa('EnumType')) {
                    $cond .= "__discriminator != " . $_->{value}->{java_literal};
                }
                else {
                    $cond .= "__discriminator != " . $_->{java_literal};
                }
                $first = 0;
            }
        }
        if ($cond) {
            print $FH "    if (",$cond,")\n";
            print $FH "      throw new org.omg.CORBA.BAD_OPERATION ();\n";
        }
        if (exists $value->{java_object}) {
            print $FH "    return ((",$value->{java_object},")__object).",$value->{java_type},"Value ();\n";
        }
        else {
            print $FH "    return (",$value->{java_type},")__object;\n";
        }
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public void ",$value->{java_name}," (",$value->{java_type}," value)\n";
        print $FH "  {\n";
        if (defined $node->{default} and $case eq $node->{default}) {
            print $FH "    __discriminator = ",$dis->{java_init},";\n";
        }
        else {
            $label = ${$case->{list_label}}[0];
            if ($effective_dis->isa('EnumType')) {
                print $FH "    __discriminator = ",$label->{value}->{java_literal},";\n";
            }
            else {
                print $FH "    __discriminator = ",$label->{java_literal},";\n";
            }
        }
        if (exists $value->{java_object}) {
            print $FH "    __object = new ",$value->{java_object}," (value);\n";
        }
        else {
            print $FH "    __object = value;\n";
        }
        print $FH "    __uninitialized = false;\n";
        print $FH "  }\n";
        print $FH "\n";
        if (scalar(@{$case->{list_label}}) > 1 || $flag_default) {
            print $FH "  public void ",$value->{java_name}," (",$effective_dis->{java_Name}," discriminator, ",$value->{java_type}," value)\n";
            print $FH "  {\n";
            $cond = q{};
            if (defined $node->{default} and $case eq $node->{default}) {
                $first = 1;
                foreach (@{$node->{list_member}}) {
                    $find = 0;
                    foreach my $label (@{$case->{list_label}}) {
                        $find = 1 if ($_ == $label);
                    }
                    next if ($find);
                    $cond .= "\n     || " unless ($first);
                    if ($effective_dis->isa('EnumType')) {
                        $cond .= "discriminator == " . $_->{value}->{java_literal};
                    }
                    else {
                        $cond .= "discriminator == " . $_->{java_literal};
                    }
                    $first = 0;
                }
            }
            else {
                $first = 1;
                foreach (@{$case->{list_label}}) {
                    $cond .= "\n     && " unless ($first);
                    if ($effective_dis->isa('EnumType')) {
                        $cond .= "discriminator != " . $_->{value}->{java_literal};
                    }
                    else {
                        $cond .= "discriminator != " . $_->{java_literal};
                    }
                    $first = 0;
                }
            }
            if ($cond) {
                print $FH "    if (",$cond,")\n";
                print $FH "      throw new org.omg.CORBA.BAD_OPERATION ();\n";
            }
            print $FH "    __discriminator = discriminator;\n";
            if (exists $value->{java_object}) {
                print $FH "    __object = new ",$value->{java_object}," (value);\n";
            }
            else {
                print $FH "    __object = value;\n";
            }
            print $FH "    __uninitialized = false;\n";
            print $FH "  }\n";
            print $FH "\n";
        }
    }
    if (exists $node->{need_default}) {
        print $FH "  public void _default ()\n";
        print $FH "  {\n";
        if    ($effective_dis->isa('EnumType')) {
            foreach (@{$dis->{list_expr}}) {
                unless (exists $node->{hash_member}->{$_}) {
                    print $FH "    __discriminator = ",$_->{java_literal},";\n";
                    last;
                }
            }
        }
        elsif ($effective_dis->isa('BooleanType')) {
            if (exists $node->{hash_member}->{0}) {
                print $FH "    __discriminator = true;\n";
            }
            else {
                print $FH "    __discriminator = false;\n";
            }
        }
        else {
            my $v = new Math::BigInt(0);
            while (1) {
                unless (exists $node->{hash_member}->{$v}) {
                    print $FH "    __discriminator = ",$v,";\n";
                    last;
                }
                $v ++;
            }
        }
        print $FH "    __uninitialized = false;\n";
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public void _default (",$dis->{java_Name}," discriminator)\n";
        print $FH "  {\n";
        if    ($effective_dis->isa('EnumType')) {
            print $FH "    switch (discriminator.value ())\n";
        }
        elsif ($effective_dis->isa('BooleanType')) {
            print $FH "    int _dis = (discriminator) ? 1 : 0;\n";
            print $FH "    switch (_dis)\n";
        }
        else {
            print $FH "    switch (discriminator)\n";
        }
        print $FH "    {\n";
        foreach my $case (@{$node->{list_expr}}) {
            foreach (@{$case->{list_label}}) {  # expression
                if ($effective_dis->isa('BooleanType')) {
                    my $value = ($_->{value} eq 'TRUE') ? '1' : '0';
                    print $FH "      case ",$value,":\n";
                }
                else {
                    print $FH "      case ",$_->{java_literal},":\n";
                }
            }
        }
        print $FH "        throw new org.omg.CORBA.BAD_OPERATION ();\n";
        print $FH "      default:\n";
        print $FH "        __discriminator = discriminator;\n";
        print $FH "        __uninitialized = false;\n";
        print $FH "    }\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    if ($self->{toString}) {
        print $FH "  public java.lang.String toString ()\n";
        print $FH "  {\n";
        print $FH "    java.lang.StringBuffer _ret = new java.lang.StringBuffer (\"union ",$node->{java_name}," {\");\n";
        if    ($effective_dis->isa('EnumType')) {
            print $FH "    switch (discriminator ().value ())\n";
        }
        elsif ($effective_dis->isa('BooleanType')) {
            print $FH "    int _dis = (discriminator ()) ? 1 : 0;\n";
            print $FH "    switch (_dis)\n";
        }
        else {
            print $FH "    switch (discriminator ())\n";
        }
        print $FH "    {\n";
        my $idx = 0;
        foreach my $case (@{$node->{list_expr}}) {
            my $elt = $case->{element};
            my $value = $self->_get_defn($elt->{value});
            foreach (@{$case->{list_label}}) {  # default or expression
                if ($_->isa('Default')) {
                    print $FH "      default:\n";
                }
                else {
                    if ($effective_dis->isa('BooleanType')) {
                        my $value = ($_->{value} eq 'TRUE') ? '1' : '0';
                        print $FH "      case ",$value,":\n";
                    }
                    else {
                        print $FH "      case ",$_->{java_literal},":\n";
                    }
                }
            }
            print $FH "      {\n";
            $self->_member_toString($value, $node, \$idx);
            print $FH "        break;\n";
            print $FH "      }\n";
        }
        print $FH "    }\n";
        print $FH "    _ret.append (\"\\n}\");\n";
        print $FH "    return _ret.toString ();\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    if ($self->{equals}) {
        print $FH "  public boolean equals (java.lang.Object o)\n";
        print $FH "  {\n";
        print $FH "    if (this == o) return true;\n";
        print $FH "    if (o == null) return false;\n";
        print $FH "\n";
        print $FH "    if (o instanceof ",$node->{java_name},")\n";
        print $FH "    {\n";
        print $FH "      ",$node->{java_name}," obj = (",$node->{java_name},")o;\n";
        print $FH "      boolean res;\n";
        print $FH "      res = (this.__discriminator == obj.__discriminator);\n";
        print $FH "      if (!res) return false;\n";
        print $FH "      res = (this.__object == obj.__object) ||\n";
        print $FH "       (this.__object != null && obj.__object != null && this.__object.equals(obj.__object));\n";
        print $FH "      return res;\n";
        print $FH "    }\n";
        print $FH "    return false;\n";
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public int hashCode ()\n";
        print $FH "  {\n";
        print $FH "    // this method returns always the same value, to force equals() to be called.\n";
        print $FH "    return 0;\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    print $FH "} // class ",$node->{java_name},"\n";
    close $FH;
}

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    return if (exists $self->{done_hash}->{$node->{java_Name}});
    $self->{done_hash}->{$node->{java_Name}} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('EnumType') ) {
            $type->visit($self);
        }
    }
    my $dis = $self->_get_defn($node->{type});
    my $effective_dis = $dis;
    while (     $effective_dis->isa('TypeDeclarator')
           and ! exists $effective_dis->{array_size} ) {
        $effective_dis = $self->_get_defn($effective_dis->{type});
    }

    $dis->visit($self) if ($effective_dis->isa('EnumType'));

    $self->_holder($node);
    $self->_union_helper($node, $dis, $effective_dis);
    $self->_union($node, $dis, $effective_dis);
    $self->_union_helperXML($node, $dis, $effective_dis) if ($self->can('_union_helperXML'));
}

#   3.11.2.3    Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

#   3.11.2.4    Enumerations
#

sub _enum_helper {
    my ($self, $node) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_enum_tc (_id, \"",$node->{java_name},"\", new java.lang.String [] { ";
        my $first = 1;
        foreach (@{$node->{list_expr}}) {
            print $FH ", " unless ($first);
            print $FH "\"",$_->{java_name},"\"";
            $first = 0;
        }
        print $FH "} );\n";
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return ",$node->{java_Name},".from_int (\$is.read_long ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_long (value.value ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _enum {
    my ($self, $node) = @_;

    $self->open_stream($node, '.java');
    my $FH = $self->{out};
    print $FH $self->_format_javadoc($node);
    print $FH "public class ",$node->{java_name}," implements org.omg.CORBA.portable.IDLEntity\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    print $FH "  private        int __value;\n";
    print $FH "\n";
    foreach (@{$node->{list_expr}}) {
        print $FH "  public static final int _",$_->{java_name}," = ",$_->{value},";\n";
        print $FH "  public static final ",$node->{java_Name}," ",$_->{java_name}," = new ",$node->{java_Name}," (_",$_->{java_name},");\n";
    }
    print $FH "\n";
    print $FH "  protected ",$node->{java_name}," (int value)\n";
    print $FH "  {\n";
    print $FH "    __value = value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public int value ()\n";
    print $FH "  {\n";
    print $FH "    return __value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," from_int (int value)\n";
    print $FH "  {\n";
    print $FH "    switch (value)\n";
    print $FH "    {\n";
    foreach (@{$node->{list_expr}}) {
        print $FH "      case ",$_->{value},":\n";
        print $FH "        return ",$_->{java_name},";\n";
    }
    print $FH "      default:\n";
    print $FH "        throw new org.omg.CORBA.BAD_PARAM ();\n";
    print $FH "    }\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public java.lang.Object readResolve() throws java.io.ObjectStreamException\n";
    print $FH "  {\n";
    print $FH "    return from_int (value ());\n";
    print $FH "  }\n";
    print $FH "\n";
    if ($self->{toString} or $self->can("_enum_helperXML")) {
        print $FH "  public java.lang.String toString ()\n";
        print $FH "  {\n";
        print $FH "    switch (this.__value)\n";
        print $FH "    {\n";
        foreach (@{$node->{list_expr}}) {
            print $FH "      case ",$_->{value},":\n";
            print $FH "        return \"",$_->{java_name},"\";\n";
        }
        print $FH "      default:\n";
        print $FH "        throw new org.omg.CORBA.BAD_PARAM ();\n";
        print $FH "    }\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    if ($self->{equals}) {
        print $FH "  public boolean equals (java.lang.Object o)\n";
        print $FH "  {\n";
        print $FH "    if (this == o) return true;\n";
        print $FH "    if (o == null) return false;\n";
        print $FH "\n";
        print $FH "    if (o instanceof ",$node->{java_name},")\n";
        print $FH "      return (this.__value == ((",$node->{java_name},")o).__value);\n";
        print $FH "    return false;\n";
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public int hashCode ()\n";
        print $FH "  {\n";
        print $FH "    // this method returns always the same value, to force equals() to be called.\n";
        print $FH "    return 0;\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    print $FH "} // class ",$node->{java_name},"\n";
    close $FH;
}

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});

    $self->_holder($node);
    $self->_enum_helper($node);
    $self->_enum($node);
    $self->_enum_helperXML($node) if ($self->can('_enum_helperXML'));
}

#
#   3.12    Exception Declaration
#

sub _exception_helper {
    my ($self, $node) = @_;

    $self->open_stream($node, 'Helper.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"Helper\n";
    print $FH "{\n";
    print $FH "  private static java.lang.String _id = \"",$node->{repos_id},"\";\n";
    print $FH "\n";
    print $FH "  public static void insert (org.omg.CORBA.Any a, ",$node->{java_Name}," that)\n";
    print $FH "  {\n";
    print $FH "    org.omg.CORBA.portable.OutputStream out = a.create_output_stream ();\n";
    print $FH "    a.type (type ());\n";
    print $FH "    write (out, that);\n";
    print $FH "    a.read_value (out.create_input_stream (), type ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," extract (org.omg.CORBA.Any a)\n";
    print $FH "  {\n";
    print $FH "    return read (a.create_input_stream ());\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  private static org.omg.CORBA.TypeCode __typeCode = null;\n";
    print $FH "  private static boolean __active = false;\n";
    print $FH "  synchronized public static org.omg.CORBA.TypeCode type ()\n";
    print $FH "  {\n";
    print $FH "    if (__typeCode == null)\n";
    print $FH "    {\n";
    print $FH "      synchronized (org.omg.CORBA.TypeCode.class)\n";
    print $FH "      {\n";
    print $FH "        if (__typeCode == null)\n";
    print $FH "        {\n";
    print $FH "          if (__active)\n";
    print $FH "          {\n";
    print $FH "            return org.omg.CORBA.ORB.init().create_recursive_tc ( ",$node->{java_Helper},".id () );\n";
    print $FH "          }\n";
    print $FH "          __active = true;\n";
    print $FH "          org.omg.CORBA.StructMember[] _members0 = new org.omg.CORBA.StructMember [",scalar(@{$node->{list_member}}),"];\n";
    print $FH "          org.omg.CORBA.TypeCode _tcOf_members0 = null;\n";
    my $i = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helper_type($member, $node, $i);
        $i ++;
    }
    print $FH "          __typeCode = org.omg.CORBA.ORB.init ().create_exception_tc (_id, \"",$node->{java_name},"\", _members0);\n";
    print $FH "          __active = false;\n";
    print $FH "        }\n";
    print $FH "      }\n";
    print $FH "    }\n";
    print $FH "    return __typeCode;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static java.lang.String id ()\n";
    print $FH "  {\n";
    print $FH "    return _id;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (org.omg.CORBA.portable.InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
    print $FH "    // read and discard the repository ID\n";
    print $FH "    \$is.read_string ();\n";
    my $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helper_read($member, $node, \$idx);
    }
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (org.omg.CORBA.portable.OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    // write the repository ID\n";
    print $FH "    \$os.write_string (id ());\n";
    $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helper_write($member, $node, \$idx);
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _exception {
    my ($self, $node) = @_;

    $self->open_stream($node, '.java');
    my $FH = $self->{out};
    print $FH $self->_format_javadoc($node);
    print $FH "public final class ",$node->{java_name}," extends org.omg.CORBA.UserException\n";
    print $FH "{\n";
    if (exists $node->{serial_uid}) {
        print $FH "  private static final long serialVersionUID = 0x",$node->{serial_uid},"L;\n";
    }
    else {
        print $FH "  private static final long serialVersionUID = 0x",$node->{java_uid},"L;\n";
    }
    print $FH "\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH $self->_format_javadoc($member);
        print $FH "  public ",$member->{java_type}," ",$member->{java_name},";\n";
    }
    print $FH "\n";
    print $FH "  public ",$node->{java_name}," ()\n";
    print $FH "  {\n";
    print $FH "    super (",$node->{java_name},"Helper.id ());\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH "    ",$member->{java_name}," = ",$member->{java_init},";\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    if (scalar(@{$node->{list_member}})) {
        print $FH "  public ",$node->{java_name}," (";
        my $first = 1;
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            print $FH ", " unless ($first);
            print $FH $member->{java_type}," _",$member->{java_name};
            $first = 0;
        }
        print $FH ")\n";
        print $FH "  {\n";
        print $FH "    super (",$node->{java_name},"Helper.id ());\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            print $FH "    ",$member->{java_name}," = _",$member->{java_name},";\n";
        }
        print $FH "  }\n";
        print $FH "\n";
    }
    if (scalar(@{$node->{list_member}})) {
        print $FH "  public ",$node->{java_name}," (java.lang.String \$reason";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            print $FH ", ",$member->{java_type}," _",$member->{java_name};
        }
        print $FH ")\n";
    }
    else {
        print $FH "  public ",$node->{java_name}," (java.lang.String \$reason)\n";
    }
    print $FH "  {\n";
    print $FH "    super(new StringBuffer (",$node->{java_name},"Helper.id ()).append (\"  \").append (\$reason).toString ());\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        print $FH "    ",$member->{java_name}," = _",$member->{java_name},";\n";
    }
    print $FH "  }\n";
    print $FH "\n";
    if ($self->{toString}) {
        print $FH "  public java.lang.String toString ()\n";
        print $FH "  {\n";
        print $FH "    java.lang.StringBuffer _ret = new java.lang.StringBuffer (\"exception ",$node->{java_Name}," {\");\n";
        if (scalar(@{$node->{list_member}})) {
            my $first = 1;
            my $idx = 0;
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);
                if ($first) {
                    $first = 0;
                }
                else {
                    print $FH "    _ret.append (\",\");\n";
                }
                $self->_member_toString($member, $node, \$idx);
            }
            print $FH "    _ret.append (\"\\n\");\n";
        }
        print $FH "    _ret.append (\"}\");\n";
        print $FH "    return _ret.toString ();\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    if ($self->{equals} and scalar(@{$node->{list_member}})) {
        print $FH "  public boolean equals (java.lang.Object o)\n";
        print $FH "  {\n";
        print $FH "    if (this == o) return true;\n";
        print $FH "    if (o == null) return false;\n";
        print $FH "\n";
        print $FH "    if (o instanceof ",$node->{java_name},")\n";
        print $FH "    {\n";
        print $FH "      ",$node->{java_name}," obj = (",$node->{java_name},")o;\n";
        print $FH "      boolean res;\n";
        my $first = 1;
        my $idx = 0;
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            if ($first) {
                $first = 0;
            }
            else {
                print $FH "      if (!res) return false;\n";
            }
            $self->_member_equals($member, $node, \$idx);
        }
        print $FH "      return res;\n";
        print $FH "    }\n";
        print $FH "    return false;\n";
        print $FH "  }\n";
        print $FH "\n";
        print $FH "  public int hashCode ()\n";
        print $FH "  {\n";
        print $FH "    // this method returns always the same value, to force equals() to be called.\n";
        print $FH "    return 0;\n";
        print $FH "  }\n";
        print $FH "\n";
    }
    print $FH "} // class ",$node->{java_name},"\n";
    close $FH;
}

sub visitException {
    my $self = shift;
    my ($node) = @_;
    return unless ($self->{srcname} eq $node->{filename});
    return if (exists $self->{done_hash}->{$node->{java_Name}});
    $self->{done_hash}->{$node->{java_Name}} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType') ) {
            $type->visit($self);
        }
    }

    $self->_holder($node);
    $self->_exception_helper($node);
    $self->_exception($node);
    $self->_exception_helperXML($node) if ($self->can('_exception_helperXML'));
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;

    $self->{methodes} .= $self->_format_javadoc($node);
    $self->{methodes} .= "  " . $node->{java_proto} . ";\n";                                # Interface

    $self->{abstract_methodes} .= $self->_format_javadoc($node);
    $self->{abstract_methodes} .= "  public abstract " . $node->{java_proto} . ";\n";   # Value

    $self->{stub} .= "  public " . $node->{java_proto} . "\n";
    $self->{stub} .= "  {\n";
    $self->{stub} .= "    org.omg.CORBA.portable.InputStream \$is = null;\n";
    $self->{stub} .= "    try {\n";
    if (exists $node->{modifier}) {     # oneway
        $self->{stub} .= "      org.omg.CORBA.portable.OutputStream \$os = _request (\"" . $node->{idf} . "\", false);\n";
    }
    else {
        $self->{stub} .= "      org.omg.CORBA.portable.OutputStream \$os = _request (\"" . $node->{idf} . "\", true);\n";
    }
    foreach (@{$node->{list_param}}) {
        my $type = $self->_get_defn($_->{type});
        if ($_->{attr} eq 'in') {
            $self->{stub} .= "      " . $type->{java_write} . $_->{java_name} . ");\n";
        }
        elsif ($_->{attr} eq 'inout') {
            if ($type->isa('BoxedValue') and exists $type->{java_primitive}) {
                $self->{stub} .= "      " . $type->{java_Helper} . ".write (\$os, new " . $type->{java_Name} . " (" . $_->{java_name} . ".value));\n";
            }
            else {
                $self->{stub} .= "      " . $type->{java_write} . $_->{java_name} . ".value);\n";
            }
        }
    }
    if (exists $node->{list_context}) {
        $self->{stub} .= "      \$os.write_Context (context);\n";
    }
    $self->{stub} .= "      \$is = _invoke (\$os);\n";
    my $type = $self->_get_defn($node->{type});
    unless ($type->isa('VoidType')) {
        $self->{stub} .= "      " . $type->{java_Name} . " \$result = " . $type->{java_read} . ";\n";
    }
    foreach (@{$node->{list_param}}) {
        my $type = $self->_get_defn($_->{type});
        next if ($_->{attr} eq 'in');
        if ($type->isa('BoxedValue') and exists $type->{java_primitive}) {
            $self->{stub} .= "      " . $_->{java_name} . ".value = (" . $type->{java_Helper} . ".read (\$is)).value;\n";
        }
        else {
            $self->{stub} .= "      " . $_->{java_name} . ".value = " . $type->{java_read} . ";\n";
        }
    }
    $type = $self->_get_defn($node->{type});
    if ($type->isa('VoidType')) {
        $self->{stub} .= "      return;\n";
    }
    else {
        $self->{stub} .= "      return \$result;\n";
    }
    $self->{stub} .= "    } catch (org.omg.CORBA.portable.ApplicationException \$ex) {\n";
    $self->{stub} .= "      \$is = \$ex.getInputStream ();\n";
    $self->{stub} .= "      java.lang.String _id = \$ex.getId ();\n";
    if (exists $node->{list_raise}) {
        my $first = 1;
        foreach (@{$node->{list_raise}}) {      # exception
            my $defn = $self->_get_defn($_);
            $self->{stub} .= "      ";
            $self->{stub} .= "else " unless ($first);
            $self->{stub} .= "if (_id.equals (\"" . $defn->{repos_id} . "\"))\n";
            $self->{stub} .= "        throw " . $defn->{java_Helper} . ".read (\$is);\n";
            $first = 0;
        }
    $self->{stub} .= "      else\n";
    $self->{stub} .= "        throw new org.omg.CORBA.MARSHAL (_id);\n";
    }
    else {
        $self->{stub} .= "      throw new org.omg.CORBA.MARSHAL (_id);\n";
    }
    $self->{stub} .= "    } catch (org.omg.CORBA.portable.RemarshalException \$rm) {\n";
    if ($type->isa('VoidType')) {
        $self->{stub} .= "      " . $node->{java_call} . ";\n";
    }
    else {
        $self->{stub} .= "      return " . $node->{java_call} . ";\n";
    }
    $self->{stub} .= "    } finally {\n";
    $self->{stub} .= "      _releaseReply (\$is);\n";
    $self->{stub} .= "    }\n";
    $self->{stub} .= "  } // " . $node->{java_name} . "\n";
    $self->{stub} .= "\n";
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

sub visitRegularEvent {
    shift->_no_mapping(@_);
}

sub visitAbstractEvent {
    shift->_no_mapping(@_);
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    shift->_no_mapping(@_);
}

sub visitForwardComponent {
    shift->_no_mapping(@_);
}

#
#   3.18    Home Declaration
#

sub visitHome {
    shift->_no_mapping(@_);
}

1;

