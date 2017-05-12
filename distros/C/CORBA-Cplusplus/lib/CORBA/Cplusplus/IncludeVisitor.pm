
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           C++ Language Mapping Specification, New Edition June 1999
#

package CORBA::Cplusplus::IncludeVisitor;

use strict;
use warnings;

our $VERSION = '0.41';

# needs $node->{repos_id} (repositoryIdVisitor), $node->{cpp_name} (CplusplusNameVisitor)
# $node->{cpp_arg} ??? (CtypeVisitor) and $node->{cpp_literal} (CplusplusLiteralVisitor)

use File::Basename;
use POSIX qw(ctime);

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
    my $filename = basename($self->{srcname}, '.idl') . '.hpp';
    $self->open_stream($filename);
    $self->{filename} = $filename;
    $self->{done_hash} = {};
    $self->{num_key} = 'num_cpp_inc';
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
        $filename = basename($filename, '.idl') . '.hpp';
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
        print $FH "/* no mapping for ",$node->{cpp_name}," */\n";
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
    print $FH "// This file was generated (by ",$0,"). DO NOT modify it.\n";
    print $FH "// From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH "\n";
    print $FH "#include <",$self->{incpath},"corba.hpp>\n";
#   print $FH "#include \"corba.hpp\"\n";
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
    print $FH "// end of file : ",$self->{filename},"\n";
    close $FH;
}

#
#   3.7     Module Declaration
#
#   See 1.2     Mapping for Modules
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
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "#ifndef _",$self->{prefix},$defn->{cpp_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$defn->{cpp_name},"_defined\n";
        print $FH "\n";
        print $FH "namespace ",$defn->{cpp_name}," {\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
        print $FH "\n";
        print $FH "} // end of module ",$defn->{cpp_name},"\n";
        print $FH "\n";
        print $FH "#endif\n";
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
    $self->{itf} = $node->{cpp_name};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "#ifndef _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "\n";
        print $FH "// begin of interface ",$node->{cpp_name},"\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},";\n";
        print $FH "typedef ",$node->{cpp_name}," *",$node->{cpp_name},"_ptr;\n";
        print $FH "class ",$node->{cpp_name},"_var;\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name}," : public virtual CORBA::Object {\n";
        print $FH "\tpublic:\n";
        print $FH "\t\ttypedef ",$node->{cpp_name},"_ptr _ptr_type;\n";
        print $FH "\t\ttypedef ",$node->{cpp_name},"_var _var_type;\n";
        print $FH "\n";
        print $FH "\t\tstatic ",$node->{cpp_name},"_ptr _duplicate(",$node->{cpp_name},"_ptr obj);\n";
        print $FH "\t\tstatic ",$node->{cpp_name},"_ptr _narrow(CORBA::Object_ptr obj);\n";
        print $FH "\t\tstatic ",$node->{cpp_name},"_ptr _nil();\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            if (       $defn->isa('Operation')
                    or $defn->isa('Attributes') ) {
                next;
            }
            $defn->visit($self);
        }
        print $FH "\n";
        if (keys %{$node->{hash_attribute_operation}}) {
            print $FH "\t\t// operations\n";
            print $FH "\n";
            foreach (values %{$node->{hash_attribute_operation}}) {
                my $defn = $self->_get_defn($_);
                next if ($defn->isa('Attribute'));
                $defn->visit($self);
            }
            print $FH "\n";
        }
        print $FH "\tprotected:\n";
        print $FH "\t\t",$node->{cpp_name},"();\n";
        print $FH "\t\tvirtual ~",$node->{cpp_name},"();\n";
        print $FH "\n";
        print $FH "\tprivate:\n";
        print $FH "\t\t",$node->{cpp_name},"(const ",$node->{cpp_name},"&);\n";
        print $FH "\t\tvoid operator=(const ",$node->{cpp_name},"&);\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_var : public _var {\n";
        print $FH "\tpublic:\n";
        print $FH "\t\t",$node->{cpp_name},"_var() : ptr_(",$node->{cpp_name},"::_nil()) {}\n";
        print $FH "\t\t",$node->{cpp_name},"_var(",$node->{cpp_name},"_ptr p) : ptr_(p) {}\n";
        print $FH "\t\t",$node->{cpp_name},"_var(const ",$node->{cpp_name},"_var &a) : ptr_(",$node->{cpp_name},"::_duplicate(",$node->{cpp_name},"_ptr(a)));\n";
        print $FH "\t\t~",$node->{cpp_name},"_var() { free(); }\n";
        print $FH "\n";
        print $FH "\t\t",$node->{cpp_name},"_var &operator=(",$node->{cpp_name},"_ptr p) {\n";
        print $FH "\t\t\treset(p); return *this;\n";
        print $FH "\t\t}\n";
        print $FH "\t\t",$node->{cpp_name},"_var &operator=(const ",$node->{cpp_name},"_var& a) {\n";
        print $FH "\t\t\tif (this != &a) {\n";
        print $FH "\t\t\t\tfree();\n";
        print $FH "\t\t\t\tptr_ = ",$node->{cpp_name},"::_duplicate(",$node->{cpp_name},"_ptr(a));\n";
        print $FH "\t\t\t}\n";
        print $FH "\t\treturn *this;\n";
        print $FH "\t\t}\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr in() const { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr inout() { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& out() {\n";
        print $FH "\t\t\treset(",$node->{cpp_name},"::_nil());\n";
        print $FH "\t\t\treturn ptr_;\n";
        print $FH "\t\t}\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& _retn() {\n";
        print $FH "\t\t\t",$node->{cpp_name},"_ptr val = ptr_;\n";
        print $FH "\t\t\tptr_ = ",$node->{cpp_name},"::_nil();\n";
        print $FH "\t\t\treturn val;\n";
        print $FH "\t\t}\n";
        print $FH "\n";
        print $FH "\t\toperator const ",$node->{cpp_name},"_ptr&() const { return ptr_; }\n";
        print $FH "\t\toperator ",$node->{cpp_name},"_ptr&() const { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr operator->() const { return ptr_; }\n";
        print $FH "\n";
        print $FH "\tprotected:\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr ptr_;\n";
        print $FH "\t\tvoid free() { release(ptr_); }\n";
        print $FH "\t\tvoid reset(",$node->{cpp_name},"_ptr p) { free(); ptr_ = p; }\n";
        print $FH "\n";
        print $FH "\tprivate:\n";
        print $FH "\t\t// hidden assignment operators for var types\n";
        print $FH "\t\tvoid operator=(const _var &);\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_out {\n";
        print $FH "\tpublic:\n";
        print $FH "\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_ptr& p) : ptr_(p) { ptr_ = ",$node->{cpp_name},"::_nil(); }\n";
        print $FH "\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"var& p) : ptr_(p.ptr) { release(ptr_); ptr_ = ",$node->{cpp_name},"::_nil(); }\n";
        print $FH "\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_out& a) : ptr_(a.ptr) { }\n";
        print $FH "\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_out& a) { ptr_ = a.ptr; return *this; }\n";
        print $FH "\t\t",$node->{cpp_name},"_out& operator=(const ",$node->{cpp_name},"_var& a) { ptr_ = ",$node->{cpp_name},"::_duplicate(",$node->{cpp_name},"_ptr(a)); return *this; }\n";
        print $FH "\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_ptr p) { ptr_ = p; return *this; }\n";
        print $FH "\t\toperator ",$node->{cpp_name},"_ptr&() { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& ptr() { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr operator->() { return ptr_; }\n";
        print $FH "\n";
        print $FH "\tprivate:\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& ptr_;\n";
        print $FH "}\n";
        print $FH "#endif\n";
        print $FH "// end of interface ",$node->{cpp_name},"\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
        $node->{cpp_has_ptr} = 1;
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{itf} = $node->{cpp_name};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "#ifndef _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "\n";
        print $FH "// begin of abstract interface ",$node->{cpp_name},"\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},";\n";
        print $FH "typedef ",$node->{cpp_name}," *",$node->{cpp_name},"_ptr;\n";
        print $FH "class ",$node->{cpp_name},"_var;\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name}," : public virtual CORBA::AbstractBase {\n";
        print $FH "\tpublic:\n";
        print $FH "\t\ttypedef ",$node->{cpp_name},"_ptr _ptr_type;\n";
        print $FH "\t\ttypedef ",$node->{cpp_name},"_var _var_type;\n";
        print $FH "\n";
        print $FH "\t\tstatic ",$node->{cpp_name},"_ptr _duplicate(",$node->{cpp_name},"_ptr obj);\n";
        print $FH "\t\tstatic ",$node->{cpp_name},"_ptr _narrow(CORBA::AbstractBase_ptr obj);\n";
        print $FH "\t\tstatic ",$node->{cpp_name},"_ptr _nil();\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            if (       $defn->isa('Operation')
                    or $defn->isa('Attributes') ) {
                next;
            }
            $defn->visit($self);
        }
        print $FH "\n";
        if (keys %{$node->{hash_attribute_operation}}) {
            print $FH "\t\t// operations\n";
            print $FH "\n";
            foreach (values %{$node->{hash_attribute_operation}}) {
                my $defn = $self->_get_defn($_);
                next if ($defn->isa('Attribute'));
                $defn->visit($self);
            }
            print $FH "\n";
        }
        print $FH "\tprotected:\n";
        print $FH "\t\t",$node->{cpp_name},"();\n";
        print $FH "\t\tvirtual ~",$node->{cpp_name},"();\n";
        print $FH "\n";
        print $FH "\tprivate:\n";
        print $FH "\t\t",$node->{cpp_name},"(const ",$node->{cpp_name},"&);\n";
        print $FH "\t\tvoid operator=(const ",$node->{cpp_name},"&);\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_var : public _var {\n";
        print $FH "\tpublic:\n";
        print $FH "\t\t",$node->{cpp_name},"_var() : ptr_(",$node->{cpp_name},"::_nil()) {}\n";
        print $FH "\t\t",$node->{cpp_name},"_var(",$node->{cpp_name},"_ptr p) : ptr_(p) {}\n";
        print $FH "\t\t",$node->{cpp_name},"_var(const ",$node->{cpp_name},"_var &a) : ptr_(",$node->{cpp_name},"::_duplicate(",$node->{cpp_name},"_ptr(a)));\n";
        print $FH "\t\t~",$node->{cpp_name},"_var() { free(); }\n";
        print $FH "\n";
        print $FH "\t\t",$node->{cpp_name},"_var &operator=(",$node->{cpp_name},"_ptr p) {\n";
        print $FH "\t\t\treset(p); return *this;\n";
        print $FH "\t\t}\n";
        print $FH "\t\t",$node->{cpp_name},"_var &operator=(const ",$node->{cpp_name},"_var& a) {\n";
        print $FH "\t\t\tif (this != &a) {\n";
        print $FH "\t\t\t\tfree();\n";
        print $FH "\t\t\t\tptr_ = ",$node->{cpp_name},"::_duplicate(",$node->{cpp_name},"_ptr(a));\n";
        print $FH "\t\t\t}\n";
        print $FH "\t\treturn *this;\n";
        print $FH "\t\t}\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr in() const { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr inout() { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& out() {\n";
        print $FH "\t\t\treset(",$node->{cpp_name},"::_nil());\n";
        print $FH "\t\t\treturn ptr_;\n";
        print $FH "\t\t}\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& _retn() {\n";
        print $FH "\t\t\t",$node->{cpp_name},"_ptr val = ptr_;\n";
        print $FH "\t\t\tptr_ = ",$node->{cpp_name},"::_nil();\n";
        print $FH "\t\t\treturn val;\n";
        print $FH "\t\t}\n";
        print $FH "\n";
        print $FH "\t\toperator const ",$node->{cpp_name},"_ptr&() const { return ptr_; }\n";
        print $FH "\t\toperator ",$node->{cpp_name},"_ptr&() const { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr operator->() const { return ptr_; }\n";
        print $FH "\n";
        print $FH "\tprotected:\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr ptr_;\n";
        print $FH "\t\tvoid free() { release(ptr_); }\n";
        print $FH "\t\tvoid reset(",$node->{cpp_name},"_ptr p) { free(); ptr_ = p; }\n";
        print $FH "\n";
        print $FH "\tprivate:\n";
        print $FH "\t\t// hidden assignment operators for var types\n";
        print $FH "\t\tvoid operator=(const _var &);\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_out {\n";
        print $FH "\tpublic:\n";
        print $FH "\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_ptr& p) : ptr_(p) { ptr_ = ",$node->{cpp_name},"::_nil(); }\n";
        print $FH "\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"var& p) : ptr_(p.ptr) { release(ptr_); ptr_ = ",$node->{cpp_name},"::_nil(); }\n";
        print $FH "\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_out& a) : ptr_(a.ptr) { }\n";
        print $FH "\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_out& a) { ptr_ = a.ptr; return *this; }\n";
        print $FH "\t\t",$node->{cpp_name},"_out& operator=(const ",$node->{cpp_name},"_var& a) { ptr_ = ",$node->{cpp_name},"::_duplicate(",$node->{cpp_name},"_ptr(a)); return *this; }\n";
        print $FH "\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_ptr p) { ptr_ = p; return *this; }\n";
        print $FH "\t\toperator ",$node->{cpp_name},"_ptr&() { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& ptr() { return ptr_; }\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr operator->() { return ptr_; }\n";
        print $FH "\n";
        print $FH "\tprivate:\n";
        print $FH "\t\t",$node->{cpp_name},"_ptr& ptr_;\n";
        print $FH "}\n";
        print $FH "#endif\n";
        print $FH "// end of abstract interface ",$node->{cpp_name},"\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
        $node->{cpp_has_ptr} = 1;
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitLocalInterface {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

sub visitForwardRegularInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "\n";
        print $FH "\t\tclass ",$defn->{cpp_name},";\n";
        print $FH "\t\ttypedef ",$defn->{cpp_name},"_ptr;\n";
        print $FH "\t\tclass ",$defn->{cpp_name},"_var;\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitForwardAbstractInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "\n";
        print $FH "\t\tclass ",$defn->{cpp_name},";\n";
        print $FH "\t\ttypedef ",$defn->{cpp_name},"_ptr;\n";
        print $FH "\t\tclass ",$defn->{cpp_name},"_var;\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitForwardLocalInterface {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

#
#   3.9     Value Declaration
#
#   3.9.1   Regular Value Type
#

sub visitRegularValue {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{itf} = $node->{cpp_name};
    if ($self->{srcname} eq $node->{filename}) {
        # TODO
        print $FH "#ifndef _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "\n";
        print $FH "// begin of value type ",$node->{cpp_name},"\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},";\n";
        print $FH "typedef ",$node->{cpp_name}," *",$node->{cpp_name},"_ptr;\n";
        print $FH "class ",$node->{cpp_name},"_var;\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name}," : public virtual CORBA::ValueBase {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_var : public _var {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_out {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class OBV_",$node->{cpp_name}," : public virtual ",$node->{cpp_name}," {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "#endif\n";
        print $FH "// end of value type ",$node->{cpp_name},"\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
        $node->{cpp_has_ptr} = 1;
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.9.2   Boxed Value Type
#

sub visitBoxedValue {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{itf} = $node->{cpp_name};
    if ($self->{srcname} eq $node->{filename}) {
        # TODO
        print $FH "#ifndef _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "\n";
        print $FH "// begin of boxed value ",$node->{cpp_name},"\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},";\n";
        print $FH "typedef ",$node->{cpp_name}," *",$node->{cpp_name},"_ptr;\n";
        print $FH "class ",$node->{cpp_name},"_var;\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name}," : public CORBA::DefaultValueRefCountBase {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_var : public _var {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_out {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class OBV_",$node->{cpp_name}," : public virtual ",$node->{cpp_name}," {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "#endif\n";
        print $FH "// end of boxed type ",$node->{cpp_name},"\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
        $node->{cpp_has_ptr} = 1;
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.9.3   Abstract Value Type
#

sub visitAbstractValue {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{itf} = $node->{cpp_name};
    if ($self->{srcname} eq $node->{filename}) {
        # TODO
        print $FH "#ifndef _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "#define _",$self->{prefix},$node->{cpp_name},"_defined\n";
        print $FH "\n";
        print $FH "// begin of abstract value ",$node->{cpp_name},"\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},";\n";
        print $FH "typedef ",$node->{cpp_name}," *",$node->{cpp_name},"_ptr;\n";
        print $FH "class ",$node->{cpp_name},"_var;\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name}," : public virtual CORBA::ValueBase {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_var : public _var {\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "class ",$node->{cpp_name},"_out {\n";
        print $FH "}\n";
        print $FH "#endif\n";
        print $FH "// end of abstract value ",$node->{cpp_name},"\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
        $node->{cpp_has_ptr} = 1;
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.9.4   Value Forward Declaration
#

sub visitForwardRegularValue {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "\n";
        print $FH "\t\tclass ",$defn->{cpp_name},";\n";
        print $FH "\t\ttypedef ",$defn->{cpp_name},"_ptr;\n";
        print $FH "\t\tclass ",$defn->{cpp_name},"_var;\n";
        print $FH "\t\tclass OBV_",$defn->{cpp_name},";\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

sub visitForwardAbstractValue {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "\n";
        print $FH "\t\tclass ",$defn->{cpp_name},";\n";
        print $FH "\t\ttypedef ",$defn->{cpp_name},"_ptr;\n";
        print $FH "\t\tclass ",$defn->{cpp_name},"_var;\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.10    Constant Declaration
#
#   See 1.4     Mapping for Constants
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn;
        my $type = $self->_get_defn($node->{type});
        my $type_decl = $type->{cpp_ns} . '::' . $type->{cpp_name};
        if    ($type->isa('StringType')) {
            $type_decl = 'CORBA::Char *const';
        }
        elsif ($type->isa('WideStringType')) {
            $type_decl = 'CORBA::WChar *const';
        }
        my $pkg = $node->{full};
        $pkg =~ s/::[0-9A-Z_a-z]+$//;
        $defn = $self->{symbtab}->Lookup($pkg) if ($pkg);
        if ( defined $defn and $defn->isa('BaseInterface') ) {
            print $FH "\t\tstatic const ",$type_decl," ";
                print $FH $node->{cpp_name},"; // ",$node->{value}->{cpp_literal},"\n";
        }
        else {
            print $FH "\t\tstatic const ",$type_decl," ";
                print $FH $node->{cpp_name}," = ",$node->{value}->{cpp_literal},";\n";
        }
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
        if (exists $node->{array_size}) {
            #
            #   See 1.14    Mapping for Array Types
            #
            warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
                    unless (@{$node->{array_size}});
            print $FH "\t\ttypedef ",$type->{cpp_name}," ",$node->{cpp_name};
            foreach (@{$node->{array_size}}) {
                print $FH "[",$_->{value},"]";
            }
            print $FH ";\n";
            my @list = @{$node->{array_size}};
            shift @list;
            print $FH "\t\ttypedef ",$type->{cpp_name}," ",$node->{cpp_name},"_slice";
            foreach (@list) {
                print $FH "[",$_->{value},"]";
            }
            print $FH ";\n";
            print $FH "\n";
            print $FH "\t\tclass ",$node->{cpp_name},"_var {\n";
            print $FH "\t\t\tpublic:\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_var();\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_var(",$node->{cpp_name},"_slice *);\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_var(const ",$node->{cpp_name},"_var &);\n";
            print $FH "\t\t\t\t~",$node->{cpp_name},"_var();\n";
            print $FH "\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(",$node->{cpp_name},"_slice *);\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(const ",$node->{cpp_name},"_var &);\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_slice &operator[](CORBA::ULong index);\n";
            print $FH "\t\t\t\tconst ",$node->{cpp_name},"_slice &operator[](CORBA::ULong index) const;\n";
            print $FH "\n";
            print $FH "\t\t\t\tconst ",$node->{cpp_name},"_slice* in() const;\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_slice* inout();\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_slice* out();\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_slice* _retn();\n";
            print $FH "\n";
#           print $FH "\t\t\t\toperator const ",$node->{cpp_name},"*&() const { return ptr_; }\n";
#           print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() const { return ptr_; }\n";
#           print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() const { return ptr_; }\n";
#           print $FH "\n";
#           print $FH "\t\t\tprotected:\n";
#           print $FH "\t\t\t\t",$node->{cpp_name},"* ptr_;\n";
            print $FH "\t\t};\n";
            print $FH "\n";
            print $FH "\t\tclass ",$node->{cpp_name},"_forany {\n";
            print $FH "\t\t\tpublic:\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_forany(",$node->{cpp_name},"_slice *, CORBA::Boolean nocopy = false);\n";
            print $FH "\t\t};\n";
            print $FH "\n";
            print $FH "\t\tclass ",$node->{cpp_name},"_out {\n";
            print $FH "\t\t\tpublic:\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"*& p) : ptr_(p) { ptr_ = 0; }\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_var& p) : ptr_(p.ptr_) { delete ptr_; ptr_ = 0; }\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_out& p) : ptr_(p.ptr_) {}\n";
            print $FH "\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_out& p) { ptr_ = p.ptr_; return *this; }\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"* p) { ptr_ = p; return *this; }\n";
            print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() { return ptr_; }\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr() { return ptr_; }\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() { return ptr_; }\n";
            print $FH "\n";
#           print $FH "\t\t\tprivate:\n";
#           print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr_;\n";
#           print $FH "\n";
#           print $FH "\t\t\t\t// assignment from ",$node->{cpp_name},"_var not allowed\n";
#           print $FH "\t\t\t\tvoid operator=(const ",$node->{cpp_name},"_var&);\n";
            print $FH "\t\t};\n";
            print $FH "\n";
            $node->{cpp_has_slice} = 1;
            $node->{cpp_has_var} = 1;
            $node->{cpp_has_forany} = 1;
        }
        else {
            unless ($type->isa('SequenceType')) {
                #
                #   See 1.15    Mapping for Typedefs
                #
                print $FH "\t\ttypedef ",$type->{cpp_name}," ",$node->{cpp_name},";\n";
                print $FH "\t\ttypedef ",$type->{cpp_name},"_out ",$node->{cpp_name},"_out;\n";
                print $FH "\t\ttypedef ",$type->{cpp_name},"_ptr ",$node->{cpp_name},"_ptr;\n"
                        if (exists $type->{cpp_has_ptr});
                print $FH "\t\ttypedef ",$type->{cpp_name},"_var ",$node->{cpp_name},"_var;\n"
                        if (exists $type->{cpp_has_var});
                print $FH "\t\ttypedef ",$type->{cpp_name},"_slice ",$node->{cpp_name},"_slice;\n"
                        if (exists $type->{cpp_has_slice});
                print $FH "\t\ttypedef ",$type->{cpp_name},"_forany ",$node->{cpp_name},"_forany;\n"
                        if (exists $type->{cpp_has_forany});
                if (exists $type->{cpp_has_slice}) {
                    print $FH "\n";
                    print $FH "\t\tinline ",$node->{cpp_name},"_slice *",$node->{cpp_name},"_alloc() { return ",$type->{cpp_name},"_alloc(); }\n";
                    print $FH "\t\tinline ",$node->{cpp_name},"_slice* ",$node->{cpp_name},"_dup(",$node->{cpp_name},"_slice *a) { return ",$type->{cpp_name},"_dup(a); }\n";
                    print $FH "\t\tinline void ",$node->{cpp_name},"_copy(",$node->{cpp_name},"_slice* to, const ",$node->{cpp_name},"_slice* from) { ",$type->{cpp_name},"_copy(to, from); }\n";
                    print $FH "\t\tinline void ",$node->{cpp_name},"_free(",$node->{cpp_name},"_slice *a) { ",$type->{cpp_name},"_free(a); }\n";
                }
                print $FH "\n";
            }
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
#   See 1.10        Mapping for Structure Types
#

sub visitStructType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{cpp_name}});
    $self->{done_hash}->{$node->{cpp_name}} = 1;
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
        print $FH "\t\tstruct ",$node->{cpp_name}," {\n";
        foreach (@{$node->{list_expr}}) {
            $_->visit($self);               # members
        }
        print $FH "\t\t};\n";
        print $FH "\n";
        print $FH "\t\tclass ",$node->{cpp_name},"_var {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var();\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var(",$node->{cpp_name}," *);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var(const ",$node->{cpp_name},"_var &);\n";
        print $FH "\t\t\t\t~",$node->{cpp_name},"_var();\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(",$node->{cpp_name}," *);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(const ",$node->{cpp_name},"_var &);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->();\n";
        print $FH "\t\t\t\tconst ",$node->{cpp_name},"* operator->() const;\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* in() const { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* inout() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& out() { delete ptr_; ptr_ = 0; ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* _retn() { ",$node->{cpp_name},"* tmp = ptr_; ptr_ = 0; return tmp; }\n";
        print $FH "\n";
        print $FH "\t\t\t\toperator const ",$node->{cpp_name},"*&() const { return ptr_; }\n";
        print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() const { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() const { return ptr_; }\n";
        print $FH "\n";
        print $FH "\t\t\tprotected:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* ptr_;\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        print $FH "\t\tclass ",$node->{cpp_name},"_out {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"*& p) : ptr_(p) { ptr_ = 0; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_var& p) : ptr_(p.ptr_) { delete ptr_; ptr_ = 0; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_out& p) : ptr_(p.ptr_) {}\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_out& p) { ptr_ = p.ptr_; return *this; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"* p) { ptr_ = p; return *this; }\n";
        print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() { return ptr_; }\n";
        print $FH "\n";
        print $FH "\t\t\tprivate:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr_;\n";
        print $FH "\n";
        print $FH "\t\t\t\t// assignment from ",$node->{cpp_name},"_var not allowed\n";
        print $FH "\t\t\t\tvoid operator=(const ",$node->{cpp_name},"_var&);\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
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
    if ($type->isa('SequenceType')) {
        my $value = $self->_get_defn(${$node->{list_member}}[0]);
        print $FH "\t\t\ttypedef ",$type->{cpp_name}," _",$value->{cpp_name},"_seq;\n";
        print $FH "\t\t\t_",$value->{cpp_name},"_seq";
    }
    else {
        print $FH "\t\t\t",$type->{cpp_ns},"::",$type->{cpp_name};
    }
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
    print $FH " ",$node->{cpp_name};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            print $FH "[",$_->{cpp_literal},"]";
        }
    }
}

#   3.11.2.2    Discriminated Unions
#
#   See 1.12    Mapping for Union Types
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{cpp_name}});
    $self->{done_hash}->{$node->{cpp_name}} = 1;
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
        print $FH "\t\tclass ",$node->{cpp_name}," {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"();\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"(const ",$node->{cpp_name}," &);\n";
        print $FH "\t\t\t\t~",$node->{cpp_name},"();\n";
        print $FH "\t\t\t\t",$node->{cpp_name}," &operator=(const ",$node->{cpp_name},"&);\n";
        print $FH "\n";
        print $FH "\t\t\t\tvoid _d(",$type->{cpp_name},");\n";
        print $FH "\t\t\t\t",$type->{cpp_name}," _d() const;\n";
        print $FH "\n";
#       TODO
#       foreach (@{$node->{list_expr}}) {
#           $_->visit($self);               # case
#       }
        print $FH "\t\t};\n";
        print $FH "\n";
        print $FH "\t\tclass ",$node->{cpp_name},"_var {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var();\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var(",$node->{cpp_name}," *);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var(const ",$node->{cpp_name},"_var &);\n";
        print $FH "\t\t\t\t~",$node->{cpp_name},"_var();\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(",$node->{cpp_name}," *);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(const ",$node->{cpp_name},"_var &);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->();\n";
        print $FH "\t\t\t\tconst ",$node->{cpp_name},"* operator->() const;\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* in() const { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* inout() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& out() { delete ptr_; ptr_ = 0; ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* _retn() { ",$node->{cpp_name},"* tmp = ptr_; ptr_ = 0; return tmp; }\n";
        print $FH "\n";
        print $FH "\t\t\t\toperator const ",$node->{cpp_name},"*&() const { return ptr_; }\n";
        print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() const { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() const { return ptr_; }\n";
        print $FH "\n";
        print $FH "\t\t\tprotected:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* ptr_;\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        print $FH "\t\tclass ",$node->{cpp_name},"_out {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"*& p) : ptr_(p) { ptr_ = 0; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_var& p) : ptr_(p.ptr_) { delete ptr_; ptr_ = 0; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_out& p) : ptr_(p.ptr_) {}\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_out& p) { ptr_ = p.ptr_; return *this; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"* p) { ptr_ = p; return *this; }\n";
        print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() { return ptr_; }\n";
        print $FH "\n";
        print $FH "\t\t\tprivate:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr_;\n";
        print $FH "\n";
        print $FH "\t\t\t\t// assignment from ",$node->{cpp_name},"_var not allowed\n";
        print $FH "\t\t\t\tvoid operator=(const ",$node->{cpp_name},"_var&);\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
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
    print $FH "\t\t",$type->{cpp_name};
        $self->_get_defn($node->{value})->visit($self);     # member
        print $FH ";\n";
}

#
#   3.11.2.3    Constructed Recursive Types and Forward Declarations
#

sub visitForwardStructType {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        print $FH "struct ",$defn->{cpp_name},";\n";
        print $FH "class ",$defn->{cpp_name},"_var;\n";
        print $FH "class ",$defn->{cpp_name},"_out;\n";
        $node->{cpp_has_var} = 1;
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
        print $FH "class ",$defn->{cpp_name},";\n";
        print $FH "class ",$defn->{cpp_name},"_var;\n";
        print $FH "class ",$defn->{cpp_name},"_out;\n";
        $node->{cpp_has_var} = 1;
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#   3.11.2.4    Enumerations
#
#   See 1.6     Mapping for Enums
#

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{cpp_name}});
    $self->{done_hash}->{$node->{idf}} = 1;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        print $FH "enum ",$node->{cpp_name}," {";
        my $first = 1;
        foreach (@{$node->{list_expr}}) {   # enum
            print $FH "," unless ($first);
            print $FH " ",$_->{cpp_name};
            $first = 0;
        }
        print $FH "};\n";
        print $FH "typedef ",$node->{cpp_name},"& ",$node->{cpp_name},"_out;\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.11.3  Template Types
#
#   See 1.13    Mapping for Sequence Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{cpp_name}});
    $self->{done_hash}->{$node->{cpp_name}} = 1;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $type = $self->_get_defn($node->{type});
        if (       $type->isa('SequenceType')
                or $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
        print $FH "\t\tclass ",$node->{cpp_name}," {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"();\n";
        if (exists $node->{max}) {
            print $FH "\t\t\t\t",$node->{cpp_name},"(CORBA::ULong length, ",$type->{cpp_ns},"::",$type->{cpp_name}," *data, CORBA::Boolean release = false);\n";
        }
        else {
            print $FH "\t\t\t\t",$node->{cpp_name},"(CORBA::ULong max);\n";
            print $FH "\t\t\t\t",$node->{cpp_name},"(CORBA::ULong max, CORBA::ULong length, ",$type->{cpp_ns},"::",$type->{cpp_name}," *data, CORBA::Boolean release = false);\n";
        }
        print $FH "\t\t\t\t",$node->{cpp_name},"(const ",$node->{cpp_name}," &);\n";
        print $FH "\t\t\t\t~",$node->{cpp_name},"();\n";
        print $FH "\t\t\t\t",$node->{cpp_name}," &operator=(const ",$node->{cpp_name},"&);\n";
        print $FH "\n";
        print $FH "\t\t\t\tCORBA::ULong maximum() const;\n";
        print $FH "\n";
        print $FH "\t\t\t\tvoid length (CORBA::ULong len);\n";
        print $FH "\t\t\t\tCORBA::ULong length() const;\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$type->{cpp_ns},"::",$type->{cpp_name}," &operator[](CORBA::ULong index);\n";
        print $FH "\t\t\t\tconst ",$type->{cpp_ns},"::",$type->{cpp_name}," &operator[](CORBA::ULong index) const;\n";
        print $FH "\n";
        print $FH "\t\t\t\tCORBA::Boolean release() const;\n";
        print $FH "\n";
        if (exists $node->{max}) {
            print $FH "\t\t\t\tvoid replace(CORBA::ULong length, ",$type->{cpp_ns},"::",$type->{cpp_name}," *data, CORBA::Boolean release = false);\n";
        }
        else {
            print $FH "\t\t\t\tvoid replace(CORBA::ULong max, CORBA::ULong length, ",$type->{cpp_ns},"::",$type->{cpp_name}," *data, CORBA::Boolean release = false);\n";
        }
        print $FH "\n";
        print $FH "\t\t\t\t",$type->{cpp_ns},"::",$type->{cpp_name},"* get_buffer(CORBA::Boolean orphan = false);\n";
        print $FH "\t\t\t\tconst ",$type->{cpp_ns},"::",$type->{cpp_name},"* get_buffer() const;\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        print $FH "\t\tclass ",$node->{cpp_name},"_var {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var();\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var(",$node->{cpp_name}," *);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var(const ",$node->{cpp_name},"_var &);\n";
        print $FH "\t\t\t\t~",$node->{cpp_name},"_var();\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(",$node->{cpp_name}," *);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_var &operator=(const ",$node->{cpp_name},"_var &);\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->();\n";
        print $FH "\t\t\t\tconst ",$node->{cpp_name},"* operator->() const;\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* in() const { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* inout() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& out() { delete ptr_; ptr_ = 0; ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* _retn() { ",$node->{cpp_name},"* tmp = ptr_; ptr_ = 0; return tmp; }\n";
        print $FH "\n";
        print $FH "\t\t\t\toperator const ",$node->{cpp_name},"*&() const { return ptr_; }\n";
        print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() const { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() const { return ptr_; }\n";
        # TODO operator[]
        print $FH "\n";
        print $FH "\t\t\tprotected:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* ptr_;\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        print $FH "\t\tclass ",$node->{cpp_name},"_out {\n";
        print $FH "\t\t\tpublic:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"*& p) : ptr_(p) { ptr_ = 0; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_var& p) : ptr_(p.ptr_) { delete ptr_; ptr_ = 0; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out(",$node->{cpp_name},"_out& p) : ptr_(p.ptr_) {}\n";
        print $FH "\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"_out& p) { ptr_ = p.ptr_; return *this; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"_out& operator=(",$node->{cpp_name},"* p) { ptr_ = p; return *this; }\n";
        print $FH "\t\t\t\toperator ",$node->{cpp_name},"*&() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr() { return ptr_; }\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"* operator->() { return ptr_; }\n";
        # TODO operator[]
        print $FH "\n";
        print $FH "\t\t\tprivate:\n";
        print $FH "\t\t\t\t",$node->{cpp_name},"*& ptr_;\n";
        print $FH "\n";
        print $FH "\t\t\t\t// assignment from ",$node->{cpp_name},"_var not allowed\n";
        print $FH "\t\t\t\tvoid operator=(const ",$node->{cpp_name},"_var&);\n";
        print $FH "\t\t};\n";
        print $FH "\n";
        $node->{cpp_has_var} = 1;
    }
}

#
#   See 1.12    Mapping for Strings
#

sub visitStringType {
    # empty
}

#
#   See 1.13    Mapping for Wide Strings
#

sub visitWideStringType {
    # empty
}

#
#   See 1.14    Mapping for Fixed
#

sub visitFixedPtType {
    # empty
}

sub visitFixedPtConstType {
    # empty
}

#
#   3.12    Exception Declaration
#
#   See 1.19    Mapping for Exception Types
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
        print $FH "\t\tclass ",$node->{cpp_name}," : public UserException {\n";
#       TODO
#       if (exists $node->{list_expr}) {
#           foreach (@{$node->{list_expr}}) {
#               $_->visit($self);               # members
#           }
#       }
        print $FH "\t\t};\n";
        print $FH "\n";
    }
    else {
        $self->_insert_inc($node->{filename});
    }
}

#
#   3.13    Operation Declaration
#
#   See 1.20    Mapping for Operations and Attributes
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    print $FH "\t\tvirtual ",$node->{cpp_arg}," ",$self->{prefix},$node->{cpp_name},"(";
    my $first = 1;
    my $comment = q{};
    foreach (@{$node->{list_param}}) {
        my $type = $self->_get_defn($_->{type});
        print $FH ", // ",$comment unless($first);
        print $FH "\n";
        print $FH "\t\t\t",$_->{cpp_arg};
        $first = 0;
        $comment = $_->{attr};
        $comment .= ' (variable length)' if (defined $type->{length});
        $comment .= ' (fixed length)' unless (defined $type->{length});
    }
    if (exists $node->{list_context}) {
        print $FH ", // ",$comment unless($first);
        print $FH "\n";
        print $FH "\t\t\tCORBA::Context_ptr _ctx\n";
    }
    else {
        print $FH " // ",$comment unless($first);
        print $FH "\n";
    }
    print $FH "\t\t) = 0;\n";
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

sub visitRegularEvent {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

sub visitAbstractEvent {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

sub visitForwardRegularEvent {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

sub visitForwardAbstractEvent {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

#
#   3.17    Component Declaration
#

sub visitComponent {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

sub visitForwardComponent {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

#
#   3.18    Home Declaration
#

sub visitHome {
    # C++ mapping is aligned with CORBA 2.3
    shift->_no_mapping(@_);
}

#
#   XPIDL
#

sub visitCodeFragment {
    # empty
}

1;

