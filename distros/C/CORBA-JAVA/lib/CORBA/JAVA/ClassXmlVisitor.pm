
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::JAVA::ClassXmlVisitor;

use strict;
use warnings;

our $VERSION = '2.63';

use CORBA::JAVA::ClassVisitor;
use base qw(CORBA::JAVA::ClassVisitor);

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
    $self->{num_key} = 'num_javaxml';
    $self->{toString} = 1;
    $self->{equals} = 1;
    $self->{xml_pkg} = 'org.omg.CORBA.portable.XML';
    return $self;
}

#
#   3.8     Interface Declaration
#

sub _interface_helperXML {
    my ($self, $node) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    // TODO\n";
    print $FH "    return null;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_Object ((org.omg.CORBA.Object) value, tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#
#   3.9     Value Declaration
#
#   3.9.1   Regular Value Type
#

sub _value_helperXML {
    my ($self, $node) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    // TODO (Pb with instanciation)\n";
    print $FH "    return null;\n";
#   print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
#   print $FH "    \$is.read_open_tag (tag);\n";
    my $idx = 0;
#   foreach (@{$node->{list_member}}) {     # StateMember
#       my $member = $self->_get_defn($_);
#       $self->_member_helperXML_read($member, $node, \$idx);
#   }
#   print $FH "    \$is.read_close_tag (tag);\n";
#   print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_open_tag (tag);\n";
    $idx = 0;
    foreach (@{$node->{list_member}}) {     # StateMember
        my $member = $self->_get_defn($_);
        $self->_member_helperXML_write($member, $node, \$idx);
    }
    print $FH "    \$os.write_close_tag (tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#   3.9.2   Boxed Value Type
#

sub _boxed_helperXML {
    my ($self, $node, $type, $array, $type2, $array_max) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
#   print $FH "public final class ",$node->{java_helper},"HelperXML implements org.omg.CORBA.portable.BoxedValueHelperXML\n";
    print $FH "public final class ",$node->{java_helper},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    }
    else {
        print $FH "  public static ",$type->{java_Name},@{$array}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    }
    print $FH "  {\n";
    print $FH "    // TODO (PB instanciation)\n";
    print $FH "    return null;\n";
    print $FH "  }\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    }
    else {
        print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$type->{java_Name},@{$array}," value)\n";
    }
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    if (exists $node->{java_primitive}) {
        print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    }
    else {
        print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$type->{java_Name},@{$array}," value, java.lang.String tag)\n";
    }
    print $FH "  {\n";
    print $FH "    \$os.write_open_tag (tag);\n";
    if (exists $node->{java_primitive}) {
        print $FH "    ",$type->{java_write_xml},"value.value, \"value\");\n";
    }
    else {
        my @tab = (q{ } x 4);
        my $i = 0;
        my $idx = q{};
        my $tag;
        my $nb_item = scalar(@{$array});
        if (exists $node->{array_size}) {
            foreach (@{$node->{array_size}}) {
                $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"value\"";
                print $FH @tab,"\$os.write_open_tag (",$tag,");\n";
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
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"value\"";
            print $FH @tab,"\$os.write_open_tag (",$tag,");\n";
            if (defined $_) {
                print $FH @tab,"if (value",$idx,".length > (",$_->{java_literal},"))\n";
                print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
            }
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
        $tag = $i ? "\"item\"" : "\"value\"";
        print $FH @tab,$type2->{java_write_xml},"value",$idx,", ",$tag,");\n";
        foreach (@{$array_max}) {
            pop @tab;
            $i --;
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"value\"";
            print $FH @tab,"}\n";
            print $FH @tab,"\$os.write_close_tag (",$tag,");\n";
        }
        if (exists $node->{array_size}) {
            foreach (@{$node->{array_size}}) {
                pop @tab;
                $i --;
                $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"value\"";
                print $FH @tab,"}\n";
                print $FH @tab,"\$os.write_close_tag (",$tag,");\n";
            }
        }
    }
    print $FH "    \$os.write_close_tag (tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#
#   3.11    Type Declaration
#

sub _typedeclarator_helperXML {
    my ($self, $node, $type, $array, $type2, $array_max) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_helper},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$type->{java_Name},@{$array}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$type->{java_Name},@{$array}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
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
    my $tag;
    my $nb_item = scalar(@{$array});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
            pop @array1;
            print $FH @tab,"\$is.read_open_tag (",$tag,");\n";
            print $FH @tab,"value",$idx," = new ",$type->{java_Name}," [",$_->{java_literal},"]",@array1,";\n";
            print $FH @tab,"for (int _o",$i," = 0; _o",$i," < (",$_->{java_literal},"); _o",$i,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_o' . $i . ']';
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@{$array_max}) {
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
        pop @array1;
        print $FH @tab,"\$is.read_open_tag (",$tag,");\n";
        print $FH @tab,"value",$idx," = new ",$type->{java_Name}," [0]",@array1,";\n";
        print $FH @tab,"for (int _o",$i," = 0; true; _o",$i,"++)\n";
        print $FH @tab,"{\n";
        print $FH @tab,"  try {\n";
        $idx .= '[_o' . $i . ']';
        $i ++;
        push @tab, q{ } x 4;
    }
    $tag = $i ? "\"item\"" : "tag";
    print $FH @tab,"value",$idx," = ",$type2->{java_read_xml},$tag,");\n";
    if (($type2->isa('StringType') or $type2->isa('WideStringType')) and exists $type2->{max}) {
        print $FH @tab,"if (value",$idx,".length () > (",$type2->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    foreach (@{$array_max}) {
        pop @tab;
        $i --;
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
        $idx =~ s/\[[^\]]+\]$//;
        print $FH @tab,"  }\n";
        print $FH @tab,"  catch (Exception \$ex) {\n";
        print $FH @tab,"    break;\n";
        print $FH @tab,"  }\n";
        print $FH @tab,"}\n";
        if (defined $_) {
            print $FH @tab,"if (value",$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"\$is.read_close_tag (",$tag,");\n";
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @tab;
            $i --;
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
            print $FH @tab,"}\n";
            print $FH @tab,"\$is.read_close_tag (",$tag,");\n";
        }
    }
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$type->{java_Name},@{$array}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$type->{java_Name},@{$array}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    @tab = (q{ } x 4);
    $i = 0;
    $idx = q{};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
            print $FH @tab,"\$os.write_open_tag (",$tag,");\n";
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
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
        print $FH @tab,"\$os.write_open_tag (",$tag,");\n";
        if (defined $_) {
            print $FH @tab,"if (value",$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
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
    $tag = $i ? "\"item\"" : "tag";
    print $FH @tab,$type2->{java_write_xml},"value",$idx,", ",$tag,");\n";
    foreach (@{$array_max}) {
        pop @tab;
        $i --;
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
        print $FH @tab,"}\n";
        print $FH @tab,"\$os.write_close_tag (",$tag,");\n";
    }
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            pop @tab;
            $i --;
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "tag";
            print $FH @tab,"}\n";
            print $FH @tab,"\$os.write_close_tag (",$tag,");\n";
        }
    }
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#

sub _struct_helperXML {
    my ($self, $node) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_name},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
    print $FH "    \$is.read_open_tag (tag);\n";
    my $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helperXML_read($member, $node, \$idx);
    }
    print $FH "    \$is.read_close_tag (tag);\n";
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_open_tag (tag);\n";
    $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helperXML_write($member, $node, \$idx);
    }
    print $FH "    \$os.write_close_tag (tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

sub _member_helperXML_read {
    my $self = shift;
    my ($member, $parent, $r_idx) = @_;

    my $FH = $self->{out};
    my $label = q{};
#   unless ($member->isa('StateMember')) {
        if ($parent->isa('UnionType')) {
            $label = '_';
        }
        else {  # StructType or ExceptionType
            $label = 'value.';
        }
#   }
    my $type = $self->_get_defn($member->{type});
    my $name = $member->{java_name};
    my @tab = (q{ } x 4);
    push @tab, q{ } x 4 if ($parent->isa('UnionType'));
    my $idx = q{};
    my $i = 0;
    my $tag;
    my @array1 = ();
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            push @array1, '[]';
        }
    }
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        push @array1, '[]';
        $type = $self->_get_defn($type->{type});
    }
    my $nb_item = scalar(@array_max);
    $nb_item += scalar(@{$member->{array_size}}) if (exists $member->{array_size});
    if ($parent->isa('UnionType')) {
        print $FH @tab,"  ",$member->{java_type}," _",$member->{java_name}," = ",$member->{java_init},";\n";
    }
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
            pop @array1;
            print $FH @tab,"\$is.read_open_tag (",$tag,");\n";
            if ($parent->isa('UnionType')) {
                print $FH @tab,"_",$name,$idx," = new ",$type->{java_Name}," [",$_->{java_literal},"]",@array1,";\n";
            }
            else {  # StructType or ExceptionType
                print $FH @tab,"value.",$name,$idx," = new ",$type->{java_Name}," [",$_->{java_literal},"]",@array1,";\n";
            }
            print $FH @tab,"for (int _o",$$r_idx," = 0; _o",$$r_idx," < (",$_->{java_literal},"); _o",$$r_idx,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_o' . $$r_idx . ']';
            $$r_idx ++;
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@array_max) {
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
        pop @array1;
        print $FH @tab,"\$is.read_open_tag (",$tag,");\n";
        if ($parent->isa('UnionType')) {
            print $FH @tab,"_",$name,$idx," = new ",$type->{java_Name}," [0]",@array1,";\n";
        }
        else {  # StructType or ExceptionType
            print $FH @tab,"value.",$name,$idx," = new ",$type->{java_Name}," [0]",@array1,";\n";
        }
        print $FH @tab,"for (int _o",$$r_idx," = 0; true; _o",$$r_idx,"++)\n";
        print $FH @tab,"{\n";
        print $FH @tab,"  try {\n";
        $idx .= '[_o' . $$r_idx . ']';
        $$r_idx ++;
        $i ++;
        push @tab, q{ } x 4;
    }
    $tag = $i ? "\"item\"" : "\"" . $member->{xsd_name} . "\"";
    if ($parent->isa('UnionType')) {
        print $FH @tab,"_",$name,$idx," = ",$type->{java_read_xml},$tag,");\n";
    }
    else {  # StructType or ExceptionType
        print $FH @tab,"value.",$name,$idx," = ",$type->{java_read_xml},$tag,");\n";
    }
    if (($type->isa('StringType') or $type->isa('WideStringType')) and exists $type->{max}) {
        print $FH @tab,"if (",$label,$name,$idx,".length () > (",$type->{max}->{java_literal},"))\n";
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    foreach (@array_max) {
        pop @tab;
        $i --;
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
        $idx =~ s/\[[^\]]+\]$//;
        print $FH @tab,"  }\n";
        print $FH @tab,"  catch (Exception \$ex) {\n";
        print $FH @tab,"    break;\n";
        print $FH @tab,"  }\n";
        print $FH @tab,"}\n";
        if (defined $_) {
            print $FH @tab,"if (value",$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"\$is.read_close_tag (",$tag,");\n";
    }
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            pop @tab;
            $i --;
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
            print $FH @tab,"}\n";
            print $FH @tab,"\$is.read_close_tag (",$tag,");\n";
            pop @tab;
        }
    }
}

sub _member_helperXML_write {
    my $self = shift;
    my ($member, $parent, $r_idx) = @_;

    my $FH = $self->{out};
#   my $label = ($member->isa('StateMember')) ? q{} : 'value.';
    my $label = 'value.';
    my $type = $self->_get_defn($member->{type});
    my $name = $member->{java_name};
    my @tab = (q{ } x 4);
    push @tab, q{ } x 4 if ($parent->isa('UnionType'));
    my $idx = q{};
    my $i = 0;
    my $tag;
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        $type = $self->_get_defn($type->{type});
    }
    my $nb_item = scalar(@array_max);
    $nb_item += scalar(@{$member->{array_size}}) if (exists $member->{array_size});
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
            print $FH @tab,"\$os.write_open_tag (",$tag,");\n";
            print $FH @tab,"if (value.",$name,$idx,".length != (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
            print $FH @tab,"for (int _i",$$r_idx," = 0; _i",$$r_idx," < (",$_->{java_literal},"); _i",$$r_idx,"++)\n";
            print $FH @tab,"{\n";
            $idx .= '[_i' . $$r_idx . ']';
            $$r_idx ++;
            $i ++;
            push @tab, q{ } x 2;
        }
    }
    foreach (@array_max) {
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
        print $FH @tab,"\$os.write_open_tag (",$tag,");\n";
        if (defined $_) {
            print $FH @tab,"if (value.",$name,$idx,".length > (",$_->{java_literal},"))\n";
            print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
        }
        print $FH @tab,"for (int _i",$$r_idx," = 0; _i",$$r_idx," < value.",$name,$idx,".length; _i",$$r_idx,"++)\n";
        print $FH @tab,"{\n";
        $idx .= '[_i' . $$r_idx . ']';
        $$r_idx ++;
        $i ++;
        push @tab, q{ } x 2;
    }
    if (($type->isa('StringType') or $type->isa('WideStringType')) and exists $type->{max}) {
        if ($parent->isa('UnionType')) {
            print $FH @tab,"if (",$label,$name,$idx," ().length () > (",$type->{max}->{java_literal},"))\n";
        }
        else {  # StructType or ExceptionType
            print $FH @tab,"if (",$label,$name,$idx,".length () > (",$type->{max}->{java_literal},"))\n";
        }
        print $FH @tab,"  throw new org.omg.CORBA.MARSHAL (0, org.omg.CORBA.CompletionStatus.COMPLETED_MAYBE);\n";
    }
    $tag = $i ? "\"item\"" : "\"" . $member->{xsd_name} . "\"";
    if ($parent->isa('UnionType')) {
        print $FH @tab,$type->{java_write_xml},"value.",$name," ()",$idx,", ",$tag,");\n";
    }
    else {  # StructType or ExceptionType
        print $FH @tab,$type->{java_write_xml},"value.",$name,$idx,", ",$tag,");\n";
    }
    foreach (@array_max) {
        pop @tab;
        $i --;
        $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
        print $FH @tab,"}\n";
        print $FH @tab,"\$os.write_close_tag (",$tag,");\n";
    }
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            pop @tab;
            $i --;
            $tag = $i ? "\"item" . ($nb_item - $i) . "\"" : "\"" . $member->{xsd_name} . "\"";
            print $FH @tab,"}\n";
            print $FH @tab,"\$os.write_close_tag (",$tag,");\n";
        }
    }
}

#   3.11.2.2    Discriminated Unions
#

sub _union_helperXML {
    my ($self, $node, $dis, $effective_dis) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_name},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
    print $FH "    ",$effective_dis->{java_Name}," _dis0 = ",$effective_dis->{java_init},";\n";
    print $FH "    \$is.read_open_tag (tag);\n";
    print $FH "    _dis0 = ",$dis->{java_read_xml},"\"discriminator\");\n";
    if ($effective_dis->isa('EnumType')) {
        print $FH "    switch (_dis0.value ())\n";
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
                print $FH "      case ",$_->{java_literal},":\n";
            }
        }
        my $elt = $case->{element};
        my $value = $self->_get_defn($elt->{value});
        $self->_member_helperXML_read($value, $node, \$idx);
        if (scalar(@{$case->{list_label}}) > 1 || $flag_default) {
            if ($effective_dis->isa('EnumType')) {
                print $FH "        value.",$value->{java_name}," (_dis0.value (), _",$value->{java_name},");\n";
            }
            else {
                print $FH "        value.",$value->{java_name}," (_dis0, _",$value->{java_name},");\n";
            }
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
    print $FH "    \$is.read_close_tag (tag);\n";
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_open_tag (tag);\n";
    print $FH "    ",$dis->{java_write_xml},"value.discriminator (), \"discriminator\");\n";
    if ($effective_dis->isa('EnumType')) {
        print $FH "    switch (value.discriminator ().value ())\n";
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
                print $FH "      case ",$_->{java_literal},":\n";
            }
        }
        my $elt = $case->{element};
        my $value = $self->_get_defn($elt->{value});
        $self->_member_helperXML_write($value, $node, \$idx);
        print $FH "        break;\n";
    }
    if (exists $node->{need_default}) {
        print $FH "      default:\n";
        print $FH "        throw new org.omg.CORBA.BAD_OPERATION ();\n";
    }
    print $FH "    }\n";
    print $FH "    \$os.write_close_tag (tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#   3.11.2.4    Enumerations
#

sub _enum_helperXML {
    my ($self, $node) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_name},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$is.read_open_tag (tag);\n";
    print $FH "    java.lang.String str = \$is.read_pcdata ();\n";
    print $FH "    \$is.read_close_tag (tag);\n";
    foreach (@{$node->{list_expr}}) {
        print $FH "    if (str.equals (\"",$_->{java_name},"\"))\n";
        print $FH "      return ",$_->{java_Name},";\n";
    }
    print $FH "    throw new org.omg.CORBA.BAD_PARAM ();\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_open_tag (tag);\n";
    print $FH "    \$os.write_pcdata (value.toString ());\n";
    print $FH "    \$os.write_close_tag (tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

#
#   3.12    Exception Declaration
#

sub _exception_helperXML {
    my ($self, $node) = @_;

    $self->open_stream($node, 'HelperXML.java');
    my $FH = $self->{out};
    print $FH "abstract public class ",$node->{java_name},"HelperXML\n";
    print $FH "{\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is)\n";
    print $FH "  {\n";
    print $FH "    return read (\$is, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static ",$node->{java_Name}," read (",$self->{xml_pkg},"InputStream \$is, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    ",$node->{java_Name}," value = new ",$node->{java_Name}," ();\n";
    print $FH "    \$is.read_open_tag (tag);\n";
    my $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helperXML_read($member, $node, \$idx);
    }
    print $FH "    \$is.read_close_tag (tag);\n";
    print $FH "    return value;\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value)\n";
    print $FH "  {\n";
    print $FH "    write (\$os, value, \"",$node->{xsd_name},"\");\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "  public static void write (",$self->{xml_pkg},"OutputStream \$os, ",$node->{java_Name}," value, java.lang.String tag)\n";
    print $FH "  {\n";
    print $FH "    \$os.write_open_tag (tag);\n";
    $idx = 0;
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);
        $self->_member_helperXML_write($member, $node, \$idx);
    }
    print $FH "    \$os.write_close_tag (tag);\n";
    print $FH "  }\n";
    print $FH "\n";
    print $FH "}\n";
    close $FH;
}

1;

