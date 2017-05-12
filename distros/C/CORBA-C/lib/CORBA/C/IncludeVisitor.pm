
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C Language Mapping Specification, New Edition June 1999
#

package CORBA::C::IncludeVisitor;

use strict;
use warnings;

our $VERSION = '2.62';

use File::Basename;
use POSIX qw(ctime);

# needs $node->{repos_id} (repositoryIdVisitor), $node->{c_name} (CnameVisitor)
# $node->{c_arg} (CtypeVisitor) and $node->{c_literal} (CliteralVisitor)

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $incpath) = @_;
    $self->{incpath} = $incpath || q{};
    $self->{prefix} = q{};              # provision for incskel
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{inc} = {};
    my $filename = basename($self->{srcname}, '.idl') . '.h';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_c';
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
}

sub _insert_inc {
    my $self = shift;
    my ($filename) = @_;
    my $FH = $self->{out};
    unless (exists $self->{inc}->{$filename}) {
        $self->{inc}->{$filename} = 1;
        $filename = basename($filename, '.idl') . '.h';
        print $FH "#include \"",$self->{prefix},$filename,"\"\n";
    }
}

sub _no_mapping {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $class = ref $node;
        $class = substr $class, rindex($class, ':') + 1;
        if ($class =~ /^Forward/) {
            $node = $self->{symbtab}->Lookup($node->{full});
        }
        print $FH "\n";
        print $FH "/* no mapping for ",$node->{c_name}," */\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
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
    my $FH = $self->{out};
    print $FH "/* ex: set ro: */\n";
    print $FH "/* This file was generated (by ",basename($0),"). DO NOT modify it */\n";
    print $FH "/* From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH " */\n";
    print $FH "\n";
    print $FH "#include <",$self->{incpath},"corba.h>\n";
#   print $FH "#include \"corba.h\"\n";
    print $FH "\n";
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            my $basename = $_->{value};
            $basename =~ s/^:://;
            $basename =~ s/::/_/g;
            print $FH "#include \"",$basename,".h\"\n";
        }
        print $FH "\n";
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "\n";
    print $FH "/* end of file : ",$self->{filename}," */\n";
    print $FH "\n";
    print $FH "/*\n";
    print $FH " * Local variables:\n";
    print $FH " *   buffer-read-only: t\n";
    print $FH " * End:\n";
    print $FH " */\n";    
    close $FH;
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
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $filename = basename($self->{srcname}, '.idl') . '.h';
        $filename =~ s/\./_/g;
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "/*\n";
        print $FH " * begin of module ",$defn->{c_name},"\n";
        print $FH " */\n";
        print $FH "#ifndef _",$self->{prefix},$defn->{c_name},"_",$filename,"_defined\n";
        print $FH "#define _",$self->{prefix},$defn->{c_name},"_",$filename,"_defined\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
        print $FH "#endif\n";
        print $FH "/*\n";
        print $FH " * end of module ",$defn->{c_name},"\n";
        print $FH " */\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.8     Interface Declaration
#
#   See 1.3     Mapping for Interfaces
#

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{itf} = $node->{c_name};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "/*\n";
        print $FH " * begin of interface ",$node->{c_name},"\n";
        print $FH " */\n";
        print $FH "#ifndef _",$self->{prefix},$node->{c_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{c_name},"_defined\n";
        print $FH "\n";
        if (exists $self->{reposit}) {
            print $FH "#define id_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
        }
        print $FH "typedef CORBA_Object ",$node->{c_name},";\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            if (       $defn->isa('Operation')
                    or $defn->isa('Attributes') ) {
                next;
            }
            $defn->visit($self);
        }
        print $FH "#endif\n";
        print $FH "\n";
        if (keys %{$node->{hash_attribute_operation}}) {
            print $FH "#ifndef _proto_",$self->{prefix},$node->{c_name},"_defined\n";
            print $FH "#define _proto_",$self->{prefix},$node->{c_name},"_defined\n";
            print $FH "\n";
            $self->{itf} = $node->{c_name};
            foreach (values %{$node->{hash_attribute_operation}}) {
                $self->_get_defn($_)->visit($self);
            }
            delete $self->{itf};
            print $FH "#endif\n";
        }
        print $FH "/*\n";
        print $FH " * end of interface ",$node->{c_name},"\n";
        print $FH " */\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitAbstractInterface {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{itf} = $node->{c_name};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "/*\n";
        print $FH " * begin of abstract interface ",$node->{c_name},"\n";
        print $FH " */\n";
        print $FH "#ifndef _",$self->{prefix},$node->{c_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{c_name},"_defined\n";
        print $FH "\n";
        print $FH "typedef CORBA_Object ",$node->{c_name},";\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            if (       $defn->isa('Operation')
                    or $defn->isa('Attributes') ) {
                next;
            }
            $defn->visit($self);
        }
        print $FH "#endif\n";
        print $FH "\n";
        print $FH "/*\n";
        print $FH " * end of abstract interface ",$node->{c_name},"\n";
        print $FH " */\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitForwardRegularInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "\n";
        print $FH "typedef ",$defn->{c_name},";\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitForwardAbstractInterface {
    # C mapping is aligned with CORBA 2.1
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "\n";
        print $FH "typedef ",$defn->{c_name},";\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitBaseInterface {
    # C mapping is aligned with CORBA 2.1
    shift->_no_mapping(@_);
}

sub visitForwardBaseInterface {
    # C mapping is aligned with CORBA 2.1
    shift->_no_mapping(@_);
}

#
#   3.10    Constant Declaration
#
#   See 1.6     Mapping for Constants
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "#define ",$node->{c_name},"\t",$node->{value}->{c_literal},"\n";
    }
    else {
        $self->_insert_inc($node->{filename});
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

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StructType')
            or $type->isa('UnionType')
            or $type->isa('EnumType')
            or $type->isa('SequenceType')
            or $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        if (exists $self->{reposit}) {
            print $FH "#define id_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
            print $FH "#define uid_",$node->{c_name}," 0x",$node->{serial_uid},"ULL\n"
                    if (exists $node->{serial_uid});
        }
        if (exists $node->{array_size}) {
            #
            #   See 1.15    Mapping for Array
            #
            warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
                    unless (@{$node->{array_size}});
            print $FH "typedef ",
                    $type->{c_name},
                    " ",$node->{c_name};
            foreach (@{$node->{array_size}}) {
                print $FH "[",$_->{c_literal},"]";
            }
            print $FH ";\n";
            my @list = @{$node->{array_size}};
            shift @list;
            print $FH "typedef ",
                    $type->{c_name},
                    " ",$node->{c_name},"_slice";
            foreach (@list) {
                print $FH "[",$_->{c_literal},"]";
            }
            print $FH ";\n";
            if (defined $type->{length}) {
                if (exists $self->{use_define}) {
                    print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name},"_slice *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"_slice))\n";
                }
                else {
                    print $FH "extern ",$node->{c_name},"_slice * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
                }
            }
        }
        else {
            print $FH "typedef ",
                    $type->{c_name},
                    " ",$node->{c_name},";\n";
        }
    }
}

sub visitNativeType {
    # empty
}

#
#   3.11.2  Constructed Types
#
#   3.11.2.1    Structures
#
#   See 1.9     Mapping for Structure Types
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('SequenceType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        if (exists $self->{reposit}) {
            print $FH "#define id_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
            print $FH "#define uid_",$node->{c_name}," 0x",$node->{serial_uid},"ULL\n"
                    if (exists $node->{serial_uid});
        }
        print $FH "typedef struct {\n";
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);               # members
        }
        print $FH "} ",$node->{c_name},";\n";
        if (defined $node->{length}) {
            if (exists $self->{use_define}) {
                print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n"
            }
            else {
                print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
            }
        }
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitMembers {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    print $FH "\t",$type->{c_name};
    my $first = 1;
    foreach (@{$node->{list_member}}) {
        if ($first) {
            $first = 0;
        }
        else {
            print $FH ",";
        }
        $self->_get_defn($_)->visit($self);     # member
    }
    print $FH ";\n";
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    print $FH " ",$node->{c_name};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            print $FH "[",$_->{c_literal},"]";
        }
    }
}

#   3.11.2.2    Discriminated Unions
#
#   See 1.10    Mapping for Union Types
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('SequenceType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    my $type = $self->_get_defn($node->{type});
    if ($type->isa('EnumType')) {
        $type->visit($self);
    }
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        if (exists $self->{reposit}) {
            print $FH "#define id_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
            print $FH "#define uid_",$node->{c_name}," 0x",$node->{serial_uid},"ULL\n"
                    if (exists $node->{serial_uid});
        }
        print $FH "typedef struct {\n";
        print $FH "\t",$type->{c_name}," _d; /* discriminator */\n";
        print $FH "\tunion {\n";
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);               # case
        }
        print $FH "\t} _u;\n";
        print $FH "} ",$node->{c_name},";\n";
        if (defined $type->{length}) {
            if (exists $self->{use_define}) {
                print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n"
            }
            else {
                print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
            }
        }
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    $node->{element}->visit($self);
}

sub visitElement {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    print $FH "\t\t",$type->{c_name};
        $self->_get_defn($node->{value})->visit($self);     # member
        print $FH ";\n";
}

#   3.11.2.3    Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "typedef ",$defn->{c_name},";\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitForwardUnionType {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "typedef ",$defn->{c_name},";\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#   3.11.2.4    Enumerations
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "/* enum ",$node->{c_name}," */\n";
        print $FH "#define ",$node->{c_name}," CORBA_unsigned_long\n";
        if (exists $self->{reposit}) {
            print $FH "#define id_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
            print $FH "#define uid_",$node->{c_name}," 0x",$node->{serial_uid},"ULL\n"
                    if (exists $node->{serial_uid});
        }
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);               # enum
        }
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitEnum {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    print $FH "#define ",$node->{c_name},"\t",$node->{c_literal},"\n";
}

#
#   3.11.3  Template Types
#
#   See 1.11    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $type = $self->_get_defn($node->{type});
        if (       $type->isa('SequenceType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
        print $FH "#ifndef _",$node->{c_name},"_defined\n";
        print $FH "#define _",$node->{c_name},"_defined\n";
        print $FH "typedef struct {\n";
        print $FH "\tCORBA_unsigned_long _maximum;\n";
        print $FH "\tCORBA_unsigned_long _length;\n";
        print $FH "\t",$type->{c_name}," * _buffer;\n";
        print $FH "} ",$node->{c_name},";\n";
        if (exists $self->{use_define}) {
            print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n";
            print $FH "#define ",$node->{c_name},"__allocbuf(len)\t(",$type->{c_name}," *)CORBA_alloc((len) * sizeof(",$type->{c_name},"))\n";
        }
        else {
            print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
            print $FH "extern ",$type->{c_name}," * ",$node->{c_name},"__allocbuf(CORBA_unsigned_long len);\n";
        }
        print $FH "#endif\n";
    }
}

#
#   See 1.12    Mapping for Strings
#

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    print $FH "#ifndef _",$node->{c_name},"_defined\n";
    print $FH "#define _",$node->{c_name},"_defined\n";
    print $FH "typedef CORBA_char * ",$node->{c_name},";\n";
    print $FH "#endif\n";
}

#
#   See 1.13    Mapping for Wide Strings
#

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    print $FH "#ifndef _",$node->{c_name},"_defined\n";
    print $FH "#define _",$node->{c_name},"_defined\n";
    print $FH "typedef CORBA_wchar * ",$node->{c_name},";\n";
    print $FH "#endif\n";
}

#
#   See 1.14    Mapping for Fixed
#

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "#ifndef _",$node->{c_name},"_defined\n";
        print $FH "#define _",$node->{c_name},"_defined\n";
        print $FH "typedef struct {\n";
        print $FH "\tCORBA_unsigned_short _digits;\n";
        print $FH "\tCORBA_short _scale;\n";
        print $FH "\tCORBA_char _value [(",
                $node->{d}->{value}, "+",
                $node->{s}->{value}, ")/2];\n";
        print $FH "} ",$node->{c_name},";\n";
        # alloc : TODO
        print $FH "#endif\n";
    }
}

sub visitFixedPtConstType {
    # empty
}

#
#   3.12    Exception Declaration
#
#   See 1.16    Mapping for Exception Types
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});
        foreach (@{$node->{list_expr}}) {
            my $type = $self->_get_defn($_->{type});
            if (       $type->isa('StructType')
                    or $type->isa('UnionType')
                    or $type->isa('SequenceType')
                    or $type->isa('StringType')
                    or $type->isa('WideStringType')
                    or $type->isa('FixedPtType') ) {
                $type->visit($self);
            }
        }
    }
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "/* exception ",$node->{c_name}," */\n";
        print $FH "typedef struct ",$node->{c_name}," {\n";
        if (exists $node->{list_expr}) {
            foreach (@{$node->{list_expr}}) {
                $_->visit($self);               # members
            }
        }
        else {
            print $FH "\tCORBA_long _dummy;\n";
        }
        print $FH "} ",$node->{c_name},";\n";
        print $FH "#define ex_",$node->{c_name}," \"",$node->{repos_id},"\"\n";
        if (exists $self->{reposit}) {
            print $FH "#define uid_",$node->{c_name}," 0x",$node->{serial_uid},"ULL\n"
                    if (exists $node->{serial_uid});
        }
        if (exists $self->{use_define}) {
            print $FH "#define ",$node->{c_name},"__alloc(nb)\t(",$node->{c_name}," *)CORBA_alloc((nb) * sizeof(",$node->{c_name},"))\n";
        }
        else {
            print $FH "extern ",$node->{c_name}," * ",$node->{c_name},"__alloc(CORBA_unsigned_long nb);\n";
        }
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_param}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StringType')
                or $type->isa('WideStringType') ) {
            $type->visit($self);
        }
    }
    my $FH = $self->{out};
    print $FH "extern ",$node->{c_arg}," ",$self->{prefix},$self->{itf},"_",$node->{c_name},"(\n";
    print $FH "\t",$self->{itf}," _o,\n";
    foreach (@{$node->{list_param}}) {
        $_->visit($self);               # parameter
    }
    print $FH "\tCORBA_Context _ctx,\n"
            if (exists $node->{list_context});
    print $FH "\tCORBA_Environment * _ev\n";
    print $FH ");\n";
}

sub visitParameter {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    print $FH "\t",$node->{c_arg},", /* ",$node->{attr};
        print $FH " (variable length) */\n" if (defined $type->{length});
        print $FH " (fixed length) */\n" unless (defined $type->{length});
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
#   XPIDL
#

sub visitCodeFragment {
    # empty
}

##############################################################################

package CORBA::C::IncDefVisitor;

use strict;
use warnings;

use base qw(CORBA::C::IncludeVisitor);

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $incpath) = @_;
    $self->{incpath} = $incpath || q{};
    $self->{prefix} = q{};
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{inc} = {};
    $self->{use_define} = 1;
    $self->{reposit} = 1;
    my $filename = basename($self->{srcname}, '.idl') . '.h';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_inc_c';
    return $self;
}

1;

