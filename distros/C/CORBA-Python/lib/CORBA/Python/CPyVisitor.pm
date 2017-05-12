
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Python::CPyVisitor;

use strict;
use warnings;

our $VERSION = '2.66';

use File::Basename;
use POSIX qw(ctime);

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
}

sub _get_defn {
    my $self = shift;
    my $defn = shift;
    if (ref $defn) {
        return $defn;
    }
    else {
        return $self->{symbtab}->Lookup($defn);
    }
}

sub _split_name {
    my $self = shift;
    my ($node) = @_;
    my $full = $node->{full};
    my $c_mod;
    my $py_mod;
    my $classname = q{};
    while (!$node->isa('Modules')) {
        $full =~ s/(::[0-9A-Z_a-z]+)$//;
        $classname = $1 . $classname;
        last unless ($full);
        $node = $self->{symbtab}->Lookup($full);
    }
    if ($full) {
        $c_mod = $node->{c_name};
        $py_mod = $node->{full};
        $py_mod =~ s/^:://;
        $py_mod =~ s/::/\./g;
    }
    else {
        $c_mod = $self->{root_module};
        $py_mod = $self->{root_module};
    }
    $classname =~ s/^:://;
    $classname =~ s/::/\./g;
    return ($c_mod, $py_mod, $classname);
}

sub _get_cpy_format {
    my $self = shift;
    my ($type) = @_;

    if ( $type->isa('BaseInterface')
      or $type->isa('ForwardBaseInterface')
      or $type->isa('TypeDeclarator')
      or $type->isa('StructType')
      or $type->isa('UnionType')
      or $type->isa('EnumType')
      or $type->isa('SequenceType') ) {
        return 'O';
    }
    elsif ( $type->isa('FloatingPtType') ) {
        if    ( $type->{value} eq 'float' ) {
            return 'f';
        }
        elsif ( $type->{value} eq 'double' ) {
            return 'd';
        }
        elsif ( $type->{value} eq 'long double' ) {
            return 'd';
        }
        else {
            warn "_get_cpy_format FloatingPtType : ERROR_INTERNAL $type->{value} \n";
        }
    }
    elsif ( $type->isa('IntegerType') ) {
        if    ( $type->{value} eq 'short' ) {
            return 'h';
        }
        elsif ( $type->{value} eq 'unsigned short' ) {
            return 'H';
        }
        elsif ( $type->{value} eq 'long' ) {
            return 'l';
        }
        elsif ( $type->{value} eq 'unsigned long' ) {
            return 'k';
        }
        elsif ( $type->{value} eq 'long long' ) {
            return 'L';
        }
        elsif ( $type->{value} eq 'unsigned long long' ) {
            return 'K';
        }
        else {
            warn "_get_cpy_format IntegerType : ERROR_INTERNAL $type->{value} \n";
        }
    }
    elsif ( $type->isa('OctetType')
         or $type->isa('BooleanType') ) {
        return 'B';
    }
    elsif ( $type->isa('CharType') ) {
        return 'c';
    }
    elsif ( $type->isa('StringType') ) {
        return 's';
    }
    elsif ( $type->isa('WideStringType') ) {
        return 'u';
    }
    elsif ( $type->isa('AnyType') ) {
        warn "_get_cpy_format AnyType : not supplied \n";
    }
    elsif ( $type->isa('FixedPtType') ) {
        warn "_get_cpy_format FixedPtType : not supplied \n";
    }
    elsif ( $type->isa('NativeType') ) {
        warn "_get_cpy_format NativeType : not supplied \n";
    }
    else {
        my $class = ref $type;
        warn "Please implement '$class' in '_get_cpy_format'.\n";
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
    print $FH "extern PyObject *find_class(PyObject *module, char *classname);\n";
    print $FH "extern int parse_object(PyObject *obj, char *format, void *addr);\n";
    print $FH "\n";
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            my $basename = $_->{value};
            $basename =~ s/^:://;
            $basename =~ s/::/_/g;
            print $FH "#include \"c",$basename,".h\"\n";
        }
        print $FH "\n";
    }
    my $empty = 1;
    foreach (@{$node->{list_decl}}) {
        my $defn = $self->_get_defn($_);
        unless (   $defn->isa('Modules')
                or $defn->isa('Import') ) {
            $empty = 0;
        }
    }
    unless ($empty) {
        print $FH "static PyObject* _mod_",$self->{root_module}," = NULL;\n";
        print $FH "\n";
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
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
    my $defn = $self->{symbtab}->Lookup($node->{full});
    print $FH "/*\n";
    print $FH " * begin of module ",$defn->{c_name},"\n";
    print $FH " */\n";
    print $FH "\n";
    print $FH "#ifndef _mod_",$defn->{c_name},"_defined\n";
    print $FH "#define _mod_",$defn->{c_name},"_defined\n";
    print $FH "static PyObject* _mod_",$defn->{c_name}," = NULL;\n";
    print $FH "#endif\n";
    print $FH "\n";
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "/*\n";
    print $FH " * end of module ",$defn->{c_name},"\n";
    print $FH " */\n";
}

#
#   3.8     Interface Declaration
#

sub visitBaseInterface {
    my $self = shift;
    my($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
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
    my $FH = $self->{out};
    my ($c_mod, $py_mod, $classname) = $self->_split_name($node);
    if (exists $node->{array_size}) {
        warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
                unless (@{$node->{array_size}});
        my @array = @{$node->{array_size}};
        my $size;
        if ( $type->isa('CharType') or $type->isa('OctetType') ) {
            $size = pop @array;
        }
        print $FH "static PyObject * _cls_",$node->{c_name}," = NULL;\n";
        print $FH "\n";
        if (exists $self->{embedded}) {
            print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj) \\\n";
            if (scalar @array) {
                print $FH "\tif (!PySequence_Check(obj)) { \\\n";
                if ($self->{assert}) {
                    print $FH "\t\tassert(0 == \"PYOBJ_CHECK_",$node->{c_name}," PySequence_Check\"); \\\n";
                }
            }
            else {
                print $FH "\tif (!PyString_Check(obj)) { \\\n";
                if ($self->{assert}) {
                    print $FH "\t\tassert(0 == \"PYOBJ_CHECK_",$node->{c_name}," PyString_Check\"); \\\n";
                }
            }
            print $FH "\t\t",$self->{error},"; \\\n";
            print $FH "\t}\n";
            print $FH "\n";
            print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(val, obj)\n";
            print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(val, obj)\n";
        }
        my @tab = ();
        my $obj = 'obj';
        my $args = '(val)';
        print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
        my $nb = 0;
        if (scalar @array) {
            print $FH "\t\t{ \\\n";
            print $FH "\t\t\tint _pos0; \\\n";
        }
        foreach (@array) {
            if (exists $self->{embedded}) {
                print $FH @tab,"\t\t\tif (PySequence_Size(",$obj,") != ",$_->{c_literal},") { \\\n";
                if ($self->{assert}) {
                    print $FH @tab,"\t\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," PySequence_Size\"); \\\n";
                }
                print $FH @tab,"\t\t\t\t",$self->{error},"; \\\n";
                print $FH @tab,"\t\t\t} \\\n";
            }
            print $FH @tab,"\t\t\tfor (_pos",$nb," = 0; _pos",$nb," < ",$_->{c_literal},"; _pos",$nb,"++) { \\\n";
            unless (scalar(@array) == $nb + 1) {
                print $FH @tab,"\t\t\t\tint _pos",$nb+1,"; \\\n";
            }
            print $FH @tab,"\t\t\t\tPyObject * _item",$nb," = PySequence_GetItem(",$obj,", _pos",$nb,"); /* New reference */ \\\n";
            if (exists $self->{embedded}) {
                print $FH @tab,"\t\t\t\tif (NULL == _item",$nb,") { \\\n";
                if ($self->{assert}) {
                    print $FH @tab,"\t\t\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," PySequence_GetItem\"); \\\n";
                }
                print $FH @tab,"\t\t\t\t\t",$self->{error},"; \\\n";
                print $FH @tab,"\t\t\t\t} \\\n";
            }
            $args .= '[_pos' . $nb . ']';
            push @tab, "\t";
            $obj = '_item' . $nb;
            $nb ++;
        }
        $nb --;
        if ( $type->isa('CharType') or $type->isa('OctetType') ) {
            push @tab, "\t" if (scalar @array);
            if (exists $self->{embedded}) {
                print $FH @tab,"\t\tif (PyString_Size(",$obj,") != ",$size->{c_literal},") { \\\n";
                if ($self->{assert}) {
                    print $FH @tab,"\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," PyString_Size\"); \\\n";
                }
                print $FH @tab,"\t\t\t",$self->{error},"; \\\n";
                print $FH @tab,"\t\t} \\\n";
            }
            print $FH @tab,"\t\tmemcpy(",$args,", PyString_AsString(",$obj,"), ",$size->{c_literal},"); \\\n";
            pop @tab if (scalar @array);
        }
        else {
            my $fmt = $self->_get_cpy_format($type);
            if ($fmt eq 'O') {
                if (exists $self->{embedded}) {
                    print $FH @tab,"\t\t\tPYOBJ_CHECK_",$type->{c_name},"(_item",$nb,"); \\\n";
                }
                print $FH @tab,"\t\t\tPYOBJ_AS_",$type->{c_name},"(",$args,", _item",$nb,"); \\\n";
            }
            else {
                print $FH @tab,"\t\t\tif (!parse_object(_item",$nb,", \"",$fmt,"\", &",$args,")) { \\\n";
                if ($self->{assert}) {
                    print $FH @tab,"\t\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," parse_object\"); \\\n";
                }
                print $FH @tab,"\t\t\t\tPy_DECREF(_item",$nb,"); \\\n";
                print $FH @tab,"\t\t\t\t",$self->{error},"; \\\n";
                print $FH @tab,"\t\t\t} \\\n";
                if (exists $self->{embedded} and $fmt eq "s") {
                    print $FH @tab,"\t\t\t{ CORBA_char *p = CORBA_string__alloc(strlen(",$args,")); if (p != NULL) strcpy(p, ",$args,"); ",$args,"= p; } \\\n";
                }
            }
        }
        foreach (@array) {
            pop @tab;
            $obj = '_item' . $nb;
            print $FH @tab,"\t\t\t\tPy_DECREF(",$obj,"); \\\n";
            print $FH @tab,"\t\t\t} \\\n";
            $nb --;
        }
        if (scalar @array) {
            print $FH "\t\t}\n";
        }
        print $FH "\n";
        $args = '(val)';
        $obj = '_obj' . ++$self->{num_typedef};
        print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
        print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
        print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
        print $FH "\t} \\\n";
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
        }
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t} else { \\\n";
        print $FH @tab,"\t\tPyObject * ",$obj,"; \\\n";
        print $FH @tab,"\t\tPyObject * _args; \\\n";
        $nb = 0;
        foreach (@array) {
            print $FH @tab,"\t\tint _pos",$nb,"; \\\n";
            print $FH @tab,"\t\t",$obj," = PyList_New(",$_->{c_literal},"); /* New reference */ \\\n";
            print $FH @tab,"\t\tfor (_pos",$nb," = 0; _pos",$nb," < ",$_->{c_literal},"; _pos",$nb,"++) { \\\n";
            print $FH @tab,"\t\t\tPyObject * _item",$nb,"; \\\n";
            $args .= '[_pos' . $nb . ']';
            push @tab, "\t";
            $obj = '_item' . $nb;
            $nb ++;
        }
        $nb --;
        if ($type->isa('CharType')) {
            print $FH @tab,"\t\t",$obj," = PyString_FromStringAndSize(",$args,", ",$size->{c_literal},"); /* New reference */ \\\n";
        }
        elsif ($type->isa('OctetType')) {
            print $FH @tab,"\t\t",$obj," = PyString_FromStringAndSize((char *)",$args,", ",$size->{c_literal},"); /* New reference */ \\\n";
        }
        else {
            my $fmt = $self->_get_cpy_format($type);
            if ($fmt eq 'O') {
                print $FH @tab,"\t\tPYOBJ_FROM_",$type->{c_name},"(_item",$nb,", ",$args,"); \\\n";
            }
            else {
                print $FH @tab,"\t\t_item",$nb," = Py_BuildValue(\"",$fmt,"\", ",$args,"); /* New reference */ \\\n";
            }
        }
        foreach (@array) {
            pop @tab;
            $obj = $nb ? '_item' . ($nb-1) : '_obj' . $self->{num_typedef};
            print $FH @tab,"\t\t\tPyList_SetItem(",$obj,", _pos",$nb,", _item",$nb,"); \\\n";
            print $FH @tab,"\t\t} \\\n";
            $nb --;
        }
        print $FH "\t\t_args = Py_BuildValue(\"(O)\", ",$obj,"); \\\n";
        if ($self->{old_object}) {
            print $FH "\t\tobj = PyInstance_New(_cls_",$node->{c_name},", _args, NULL); /* New reference */ \\\n";
        }
        else {
            print $FH "\t\tobj = PyObject_Call(_cls_",$node->{c_name},", _args, NULL); \\\n";
        }
        print $FH "\t\tPy_XDECREF(_args); \\\n";
        print $FH "\t\tassert(obj != NULL); \\\n";
        $obj = "_obj" . $self->{num_typedef};
        print $FH "\t\tPy_DECREF(",$obj,"); \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        if (defined $node->{length}) {
            my $start = q{};
            my $nb;
            my $first = 1;
            foreach (@{$node->{array_size}}) {
                $start .= '[0]';
                $nb .= ' * ' unless ($first);
                $nb .= $_->{c_literal};
                $first = 0;
            }
            if (exists $self->{extended}) {
                print $FH "#define FREE_in_",$node->{c_name},"(v) {\\\n";
                print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
                print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
                print $FH "\t\t\tFREE_in_",$type->{c_name},"(",$node->{c_name},"_ptr);\\\n";
                print $FH "\t\t}\\\n";
                print $FH "\t}\n";
                print $FH "#define FREE_inout_",$node->{c_name},"(v) {\\\n";
                print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
                print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
                print $FH "\t\t\tFREE_inout_",$type->{c_name},"(",$node->{c_name},"_ptr);\\\n";
                print $FH "\t\t}\\\n";
                print $FH "\t}\n";
            }
            print $FH "#define FREE_out_",$node->{c_name},"(v) {\\\n";
            print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
            print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
            print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
            print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
            print $FH "\t\t\tFREE_out_",$type->{c_name},"(",$node->{c_name},"_ptr);\\\n";
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
            print $FH "#define FREE_",$node->{c_name},"(v) {\\\n";
            print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
            print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
            print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
            print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
            print $FH "\t\t\tFREE_",$type->{c_name},"(",$node->{c_name},"_ptr);\\\n";
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
        }
    }
    else {
        my $fmt = $self->_get_cpy_format($type);
        if ($fmt eq 'O') {
            print $FH "static PyObject * _cls_",$node->{c_name}," = NULL;\n";
            print $FH "\n";
            if (exists $self->{embedded}) {
                print $FH "#define PYOBJ_CHECK_",$node->{c_name}," PYOBJ_CHECK_",$type->{c_name},"\n";
                print $FH "#define PYOBJ_AS_inout_",$node->{c_name}," PYOBJ_AS_inout_",$type->{c_name},"\n";
                print $FH "#define PYOBJ_AS_out_",$node->{c_name}," PYOBJ_AS_out_",$type->{c_name},"\n";
            }
            print $FH "#define PYOBJ_AS_",$node->{c_name}," PYOBJ_AS_",$type->{c_name},"\n";
            my $obj = '_obj' . ++$self->{num_typedef};
            print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
            print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
            print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
            print $FH "\t} \\\n";
            print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
            print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
            print $FH "\t} \\\n";
            if ($self->{assert}) {
                print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
            }
            print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
            print $FH "\t\t",$self->{error},"; \\\n";
            print $FH "\t} else { \\\n";
            print $FH "\t\tPyObject * ",$obj,"; \\\n";
            print $FH "\t\tPyObject * _args; \\\n";
            print $FH "\t\tPYOBJ_FROM_",$type->{c_name},"(",$obj,", val); \\\n";
            print $FH "\t\t_args = Py_BuildValue(\"(",$fmt,")\", ",$obj,"); \\\n";
            if ($self->{old_object}) {
                print $FH "\t\tobj = PyInstance_New(_cls_",$node->{c_name},", _args, NULL); /* New reference */ \\\n";
            }
            else {
                print $FH "\t\tobj = PyObject_Call(_cls_",$node->{c_name},", _args, NULL); \\\n";
            }
            print $FH "\t\tPy_XDECREF(_args); \\\n";
            print $FH "\t\tassert(obj != NULL); \\\n";
            print $FH "\t\tPy_DECREF(",$obj,"); \\\n";
            print $FH "\t} \n";
            print $FH "\n";
            if (defined $node->{length}) {
                if (exists $self->{extended}) {
                    print $FH "#define FREE_in_",$node->{c_name}," FREE_in_",$type->{c_name},"\n";
                    print $FH "#define FREE_inout_",$node->{c_name}," FREE_inout_",$type->{c_name},"\n";
                }
                print $FH "#define FREE_out_",$node->{c_name}," FREE_out_",$type->{c_name},"\n";
                print $FH "#define FREE_",$node->{c_name}," FREE_",$type->{c_name},"\n";
            }
            print $FH "\n";
        }
        else {
            print $FH "static PyObject * _cls_",$node->{c_name}," = NULL;\n";
            print $FH "\n";
            if (exists $self->{embedded}) {
                print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj)\n";
                print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
                print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
            }
            print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
            print $FH "\tif (!parse_object(obj, \"",$fmt,"\", &val)) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," parse_object\"); \\\n";
            }
            print $FH "\t\t",$self->{error},"; \\\n";
            if (exists $self->{embedded} and $fmt eq "s") {
                print $FH "\t} \\\n";
                print $FH "\t{ CORBA_char *p = CORBA_string__alloc(strlen(val)); if (p != NULL) strcpy(p, (val)); (val) = p; } \n";
            }
            else {
                print $FH "\t} \n";
            }
            print $FH "\n";
            print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
            print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
            print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
            print $FH "\t} \\\n";
            print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
            print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
            print $FH "\t} \\\n";
            if ($self->{assert}) {
                print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
            }
            print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
            print $FH "\t\t",$self->{error},"; \\\n";
            print $FH "\t} else { \\\n";
            print $FH "\t\tPyObject * _args; \\\n";
            print $FH "\t\t_args = Py_BuildValue(\"(",$fmt,")\", val); \\\n";
            if ($self->{old_object}) {
                print $FH "\t\tobj = PyInstance_New(_cls_",$node->{c_name},", _args, NULL); /* New reference */ \\\n";
            }
            else {
                print $FH "\t\tobj = PyObject_Call(_cls_",$node->{c_name},", _args, NULL); \\\n";
            }
            print $FH "\t\tPy_XDECREF(_args); \\\n";
            print $FH "\t\tassert(obj != NULL); \\\n";
            print $FH "\t} \n";
            print $FH "\n";
            print $FH "\n";
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
    my ($c_mod, $py_mod, $classname) = $self->_split_name($node);
    print $FH "/* struct ",$node->{idf}," */\n";
    print $FH "static PyObject * _cls_",$node->{c_name}," = NULL;\n";
    print $FH "\n";
    if (exists $self->{embedded}) {
        print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj) \\\n";
        print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
        print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
        print $FH "\t} \\\n";
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
        }
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(PyObject_IsInstance((obj), _cls_",$node->{c_name},")); \\\n";
        }
        print $FH "\tif (!PyObject_IsInstance((obj), _cls_",$node->{c_name},")) { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
        if (defined $node->{length}) {
            print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) \\\n";
            print $FH "\t{ \\\n";
            print $FH "\t\tif (NULL == (val)) { \\\n";
            print $FH "\t\t\t(val) = ",$node->{c_name},"__alloc(1); \\\n";
            print $FH "\t\t\tif (NULL == (val)) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\t\t\tassert(0 == \"PYOBJ_AS_inout_",$node->{c_name}," alloc\"); \\\n";
            }
            print $FH "\t\t\t\tPyErr_SetString(PyExc_MemoryError, NULL); \\\n";
            print $FH "\t\t\t\t",$self->{error},"; \\\n";
            print $FH "\t\t\t} \\\n";
            print $FH "\t\t} \\\n";
            print $FH "\t\tPYOBJ_AS_",$node->{c_name},"(*(val), obj); \\\n";
            print $FH "\t} \n";
        }
        else {
            print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
        }
    }
    print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
    print $FH "\t{ \\\n";
    print $FH "\t\tPyObject * _member; \\\n";
    my @fmt_inout = ();
    my $args_in = q{};
    my $args_out = q{};
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        my $fmt = $self->_member_fmt($defn);
        if ($fmt eq 'O') {
            print $FH "\t\tPyObject * _",$defn->{c_name},"; \\\n";
            $args_in .= ', &_' . $defn->{c_name};
            $args_out .= ', _' . $defn->{c_name};
        }
        else {
            $args_in .= ', &(val).' . $defn->{c_name};
            $args_out .= ', (val).' . $defn->{c_name};
        }
        push @fmt_inout, $fmt;
    }
    print $FH "\t\tPyObject * _args = PyTuple_New(",scalar(@{$node->{list_member}}),"); /* New reference */ \\\n";
    my $i = 0;
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        my $type = $self->_get_defn($defn->{type});
        print $FH "\t\t_member = PyObject_GetAttrString((obj), \"",$defn->{py_name},"\"); /* New reference */ \\\n";
        print $FH "\t\tPyTuple_SetItem(_args, ",$i,", _member); \\\n";
        $i ++;
    }
    print $FH "\t\tif (!PyArg_ParseTuple(_args, \"",@fmt_inout,"\"",$args_in,")) { \\\n";
    if ($self->{assert}) {
        print $FH "\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," PyArg_ParseTuple ",@fmt_inout,"\"); \\\n";
    }
    print $FH "\t\t\t",$self->{error},"; \\\n";
    print $FH "\t\t} \\\n";
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        $self->_member_as($defn);
    }
    print $FH "\t\tPy_DECREF(_args); \\\n";
    print $FH "\t}\n";
    print $FH "\n";
    print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
    print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
    print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
    print $FH "\t} \\\n";
    print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
    print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
    print $FH "\t} \\\n";
    if ($self->{assert}) {
        print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
    }
    print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
    print $FH "\t\t",$self->{error},"; \\\n";
    print $FH "\t} else { \\\n";
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        my $fmt = $self->_member_fmt($defn);
        if ($fmt eq 'O') {
            print $FH "\t\tPyObject * _",$defn->{c_name},"; \\\n";
        }
    }
    print $FH "\t\tPyObject * _args; \\\n";
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        $self->_member_from($defn);
    }
    if (scalar(@fmt_inout) == 1) {
        print $FH "\t\t_args = Py_BuildValue(\"(",@fmt_inout,")\"",$args_out,"); /* New reference */ \\\n";
    }
    else {
        print $FH "\t\t_args = Py_BuildValue(\"",@fmt_inout,"\"",$args_out,"); /* New reference */ \\\n";
    }
    if ($self->{old_object}) {
        print $FH "\t\tobj = PyInstance_New(_cls_",$node->{c_name},", _args, NULL); /* New reference */ \\\n";
    }
    else {
        print $FH "\t\tobj = PyObject_Call(_cls_",$node->{c_name},", _args, NULL); \\\n";
    }
    print $FH "\t\tPy_XDECREF(_args); \\\n";
    print $FH "\t\tassert(obj != NULL); \\\n";
    foreach (@{$node->{list_member}}) {
        my $defn = $self->_get_defn($_);
        my $fmt = $self->_member_fmt($defn);
        if ($fmt eq 'O') {
            print $FH "\t\tPy_DECREF(_",$defn->{c_name},"); \\\n";
        }
    }
    print $FH "\t}\n";
    print $FH "\n";
    if (defined $node->{length}) {
        if (exists $self->{extended}) {
            print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
            print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        }
        print $FH "#define FREE_out_",$node->{c_name},"(v) { \\\n";
        print $FH "\t\tif (NULL != (v)) { \\\n";
        print $FH "\t\t\tFREE_",$node->{c_name},"(v); \\\n";
        print $FH "\t\t\tCORBA_free(v); \\\n";
        print $FH "\t\t} \\\n";
        print $FH "\t}\n";
        print $FH "#define FREE_",$node->{c_name},"(v) { \\\n";
        foreach (@{$node->{list_member}}) {
            my $defn = $self->_get_defn($_);
            $self->_member_free($defn);
        }
        print $FH "\t}\n";
    }
}

sub _member_fmt {
    my $self = shift;
    my ($member) = @_;

    if (exists $member->{array_size}) {
        return 'O';
    }
    else {
        my $type = $self->_get_defn($member->{type});
        return $self->_get_cpy_format($type);
    }
}

sub _member_as {
    my $self = shift;
    my ($member, $union) = @_;

    my @tab = (defined $union) ? ("\t\t") : ();
    my $obj = (defined $union) ? '_v' : '_' . $member->{c_name};
    $union = q{} unless (defined $union);
    my $args = '(val).' . $union . $member->{c_name};
    my $fmt = $self->_member_fmt($member);
    my $FH = $self->{out};
    if ($fmt eq 'O') {
        my $type = $self->_get_defn($member->{type});
        if (exists $member->{array_size}) {
            my @array = @{$member->{array_size}};
            my $size;
            if ( $type->isa('CharType') or $type->isa('OctetType') ) {
                $size = pop @array;
            }
            my $nb = 0;
            if (scalar @array) {
                print $FH @tab,"\t\t{ \\\n";
                print $FH @tab,"\t\t\tint _pos0; \\\n";
            }
            foreach (@array) {
                if (exists $self->{embedded}) {
                    if ($self->{assert}) {
                        print $FH @tab,"\t\t\tassert(PySequence_Size(",$obj,") == ",$_->{c_literal},"); \\\n";
                    }
                    print $FH @tab,"\t\t\tif (PySequence_Size(",$obj,") != ",$_->{c_literal},") { \\\n";
                    print $FH @tab,"\t\t\t\t",$self->{error},"; \\\n";
                    print $FH @tab,"\t\t\t} \\\n";
                }
                print $FH @tab,"\t\t\tfor (_pos",$nb," = 0; _pos",$nb," < ",$_->{c_literal},"; _pos",$nb,"++) { \\\n";
                unless (scalar(@array) == $nb + 1) {
                    print $FH @tab,"\t\t\t\tint _pos",$nb+1,"; \\\n";
                }
                print $FH @tab,"\t\t\t\tPyObject * _item",$nb," = PySequence_GetItem(",$obj,", _pos",$nb,"); /* New reference */ \\\n";
                if (exists $self->{embedded}) {
                    print $FH @tab,"\t\t\t\tif (NULL == _item",$nb,") { \\\n";
                    if ($self->{assert}) {
                        print $FH @tab,"\t\t\t\t\tassert(0 == \"",$obj," PySequence_GetItem\"); \\\n";
                    }
                    print $FH @tab,"\t\t\t\t\t",$self->{error},"; \\\n";
                    print $FH @tab,"\t\t\t\t} \\\n";
                }
                $args .= '[_pos' . $nb . ']';
                push @tab, "\t";
                $obj = '_item' . $nb;
                $nb ++;
            }
            $nb --;
            if ( $type->isa('CharType') or $type->isa('OctetType') ) {
                push @tab, "\t" if (scalar @array);
                if (exists $self->{embedded}) {
                    if ($self->{assert}) {
                        print $FH @tab,"\t\tassert(PyString_Size(",$obj,") == ",$size->{c_literal},"); \\\n";
                    }
                    print $FH @tab,"\t\tif (PyString_Size(",$obj,") != ",$size->{c_literal},") { \\\n";
                    print $FH @tab,"\t\t\t",$self->{error},"; \\\n";
                    print $FH @tab,"\t\t} \\\n";
                }
                print $FH @tab,"\t\tmemcpy(",$args,", PyString_AsString(",$obj,"), ",$size->{c_literal},"); \\\n";
                pop @tab if (scalar @array);
            }
            else {
                my $fmt = $self->_get_cpy_format($type);
                if ($fmt eq 'O') {
                    if (exists $self->{embedded}) {
                        print $FH @tab,"\t\t\tPYOBJ_CHECK_",$type->{c_name},"(_item",$nb,"); \\\n";
                    }
                    print $FH @tab,"\t\t\tPYOBJ_AS_",$type->{c_name},"(",$args,", _item",$nb,"); \\\n";
                }
                else {
                    print $FH @tab,"\t\t\tif (!parse_object(_item",$nb,", \"",$fmt,"\", &",$args,")) { \\\n";
                    print $FH @tab,"\t\t\t\tPy_DECREF(_item",$nb,"); \\\n";
                    if ($self->{assert}) {
                        print $FH @tab,"\t\t\t\tassert(0 == \"",$obj," parse_object\"); \\\n";
                    }
                    print $FH @tab,"\t\t\t\t",$self->{error},"; \\\n";
                    print $FH @tab,"\t\t\t} \\\n";
                }
            }
            foreach (@array) {
                pop @tab;
                $obj = '_item' . $nb;
                print $FH @tab,"\t\t\t\tPy_DECREF(",$obj,"); \\\n";
                print $FH @tab,"\t\t\t} \\\n";
                $nb --;
            }
            if (scalar @array) {
                print $FH @tab,"\t\t} \\\n";
            }
        }
        else {
            print $FH @tab,"\t\tPYOBJ_AS_",$type->{c_name},"((val).",$union,$member->{c_name},", ",$obj,"); \\\n";
        }
    }
    else {
        if ($union) {
            print $FH @tab,"\t\tif (!parse_object(",$obj,", \"",$fmt,"\", &",$args,")) { \\\n";
            if ($self->{assert}) {
                print $FH @tab,"\t\t\tassert(0 == \"",$obj," parse_object\"); \\\n";
            }
            print $FH @tab,"\t\t\t",$self->{error},"; \\\n";
            print $FH @tab,"\t\t} \\\n";
        }
        if (exists $self->{embedded} and $fmt eq 's') {
            print $FH @tab,"\t\t{ CORBA_char *p = CORBA_string__alloc(strlen(",$args,")); if (p != NULL) strcpy(p, ",$args,"); ",$args,"= p; } \\\n";
        }
    }
}

sub _member_from {
    my $self = shift;
    my ($member, $union) = @_;

    my @tab = (defined $union) ? ("\t\t") : ();
    my $obj = (defined $union) ? '_v' : '_' . $member->{c_name};
    $union = q{} unless (defined $union);
    my $args = '(val).' . $union . $member->{c_name};
    my $fmt = $self->_member_fmt($member);
    my $FH = $self->{out};
    if ($fmt eq 'O') {
        my $type = $self->_get_defn($member->{type});
        if (exists $member->{array_size}) {
            my @array = @{$member->{array_size}};
            my $size;
            if ( $type->isa('CharType') or $type->isa('OctetType') ) {
                $size = pop @array;
            }
            my $nb = 0;
            if (scalar @array) {
                print $FH @tab,"\t\t{ \\\n";
            }
            foreach (@array) {
                print $FH @tab,"\t\t\tint _pos",$nb,"; \\\n";
                print $FH @tab,"\t\t\t",$obj," = PyList_New(",$_->{c_literal},"); /* New reference */ \\\n";
                print $FH @tab,"\t\t\tfor (_pos",$nb," = 0; _pos",$nb," < ",$_->{c_literal},"; _pos",$nb,"++) { \\\n";
                print $FH @tab,"\t\t\t\tPyObject * _item",$nb,"; \\\n";
                $args .= '[_pos' . $nb . ']';
                push @tab, "\t";
                $obj = '_item' . $nb;
                $nb ++;
            }
            $nb --;
            if ($type->isa('CharType')) {
                push @tab, "\t" if (scalar @array);
                print $FH @tab,"\t\t",$obj," = PyString_FromStringAndSize(",$args,", ",$size->{c_literal},"); /* New reference */ \\\n";
                pop @tab if (scalar @array);
            }
            elsif ($type->isa('OctetType')) {
                push @tab, "\t" if (scalar @array);
                print $FH @tab,"\t\t",$obj," = PyString_FromStringAndSize((char *)",$args,", ",$size->{c_literal},"); /* New reference */ \\\n";
                pop @tab if (scalar @array);
            }
            else {
                my $fmt = $self->_get_cpy_format($type);
                if ($fmt eq 'O') {
                    print $FH @tab,"\t\t\tPYOBJ_FROM_",$type->{c_name},"(_item",$nb,", ",$args,"); \\\n";
                }
                else {
                    print $FH @tab,"\t\t\t_item",$nb," = Py_BuildValue(\"",$fmt,"\", ",$args,"); /* New reference */ \\\n";
                }
            }
            foreach (@array) {
                pop @tab;
                $obj = $nb ? '_item' . ($nb-1) : $union ? '_v' : '_' . $member->{c_name};
                print $FH @tab,"\t\t\t\tPyList_SetItem(",$obj,", _pos",$nb,", _item",$nb,"); \\\n";
                print $FH @tab,"\t\t\t} \\\n";
                $nb --;
            }
            if (scalar @array) {
                print $FH @tab,"\t\t} \\\n";
            }
        }
        else {
            print $FH @tab,"\t\tPYOBJ_FROM_",$type->{c_name},"(",$obj,", (val).",$union,$member->{c_name},"); \\\n";
        }
    }
    else {
        if ($union) {
            print $FH @tab,"\t\t",$obj," = Py_BuildValue(\"",$fmt,"\", ",$args,"); /* New reference */ \\\n";
        }
    }
}

sub _member_free {
    my $self = shift;
    my ($member, $union) = @_;

    my $type = $self->_get_defn($member->{type});
    if (defined $type->{length}) {
        my $tab = (defined $union) ? "\t" : q{};
        $union = q{} unless (defined $union);
        my $FH = $self->{out};
        if (exists $member->{array_size}) {
            my $start = q{};
            my $nb;
            my $first = 1;
            foreach (@{$member->{array_size}}) {
                $start .= '[0]';
                $nb .= ' * ' unless ($first);
                $nb .= $_->{c_literal};
                $first = 0;
            }
            print $FH $tab,"\t\t{ \\\n";
            print $FH $tab,"\t\t\t",$type->{c_name}," * ",$member->{c_name},"_ptr; \\\n";
            print $FH $tab,"\t\t\tfor (",$member->{c_name},"_ptr = &((v)->",$union,$member->{c_name},")",$start, "; \\\n";
            print $FH $tab,"\t\t\t     ",$member->{c_name},"_ptr < &((v)->",$union,$member->{c_name},")",$start," + (",$nb,"); \\\n";
            print $FH $tab,"\t\t\t     ",$member->{c_name},"_ptr++) { \\\n";
            print $FH $tab,"\t\t\t\tFREE_",$type->{c_name},"(",$member->{c_name},"_ptr); \\\n";
            print $FH $tab,"\t\t\t} \\\n";
            print $FH $tab,"\t\t} \\\n";
        }
        else {
            print $FH $tab,"\t\tFREE_",$type->{c_name},"(&((v)->",$union,$member->{c_name},")); \\\n";
        }
    }
}

#   3.11.2.2    Discriminated Unions
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
    my ($c_mod, $py_mod, $classname) = $self->_split_name($node);
    print $FH "/* union ",$node->{idf}," */\n";
    print $FH "static PyObject * _cls_",$node->{c_name}," = NULL;\n";
    print $FH "\n";
    if (exists $self->{embedded}) {
        print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj) \\\n";
        print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
        print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
        print $FH "\t} \\\n";
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
        }
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(PyObject_IsInstance((obj), _cls_",$node->{c_name},")); \\\n";
        }
        print $FH "\tif (!PyObject_IsInstance((obj), _cls_",$node->{c_name},")) { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
        print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
    }
    print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
    print $FH "\t{ \\\n";
    print $FH "\t\tPyObject * _v; \\\n";
    print $FH "\t\tPyObject * _d = PyObject_GetAttrString((obj), \"_d\"); /* New reference */ \\\n";
    print $FH "\t\tif (_d == NULL) { \\\n";
    if ($self->{assert}) {
        print $FH "\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," (_d == NULL)\"); \\\n";
    }
    print $FH "\t\t\t",$self->{error},"; \\\n";
    print $FH "\t\t} \\\n";
    print $FH "\t\t_v = PyObject_GetAttrString((obj), \"_v\"); /* New reference */ \\\n";
    print $FH "\t\tif (_v == NULL) { \\\n";
    if ($self->{assert}) {
        print $FH "\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," (_v == NULL)\"); \\\n";
    }
    print $FH "\t\t\t",$self->{error},"; \\\n";
    print $FH "\t\t} \\\n";
    my $fmt = $self->_get_cpy_format($type);
    if ($fmt eq 'O') {
        print $FH "\t\tPYOBJ_AS_",$type->{c_name},"((val)._d, _d); \\\n";
    }
    else {
        my $args = '&(val)._d';
        print $FH "\t\tif (!parse_object(_d, \"",$fmt,"\", ",$args,")) { \\\n";
        if ($self->{assert}) {
            print $FH "\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," parse_object\"); \\\n";
        }
        print $FH "\t\t\t",$self->{error},"; \\\n";
        print $FH "\t\t} \\\n";
    }
    print $FH "\t\tswitch ((val)._d) { \\\n";
    foreach my $case (@{$node->{list_expr}}) {
        foreach my $label (@{$case->{list_label}}) {    # default or expression
            if ($label->isa('Default')) {
                print $FH "\t\t\tdefault: \\\n";
            }
            else {
                print $FH "\t\t\tcase " . $label->{c_literal} . ": \\\n";
            }
        }
        my $defn = $self->_get_defn($case->{element}->{value});
        $self->_member_as($defn, '_u.');
        print $FH "\t\t\t\tbreak; \\\n";
    }
    print $FH "\t\t} \\\n";
    print $FH "\t}\n";
    print $FH "\n";
    print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
    print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
    print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
    print $FH "\t} \\\n";
    print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
    print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
    print $FH "\t} \\\n";
    if ($self->{assert}) {
        print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
    }
    print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
    print $FH "\t\t",$self->{error},"; \\\n";
    print $FH "\t} else { \\\n";
    print $FH "\t\tPyObject * _v; \\\n";
    print $FH "\t\tPyObject * _d; \\\n";
    print $FH "\t\tPyObject * _duo = PyTuple_New(2); /* New reference */ \\\n";
    if ($fmt eq 'O') {
        print $FH "\t\tPYOBJ_FROM_",$type->{c_name},"(_d, (val)._d); \\\n";
    }
    else {
        my $args = '(val)._d';
        print $FH "\t\t_d = Py_BuildValue(\"",$fmt,"\", ",$args,"); /* New reference */ \\\n";
    }
    print $FH "\t\tPyTuple_SetItem(_duo, 0, _d); \\\n";
    print $FH "\t\tswitch ((val)._d) { \\\n";
    foreach my $case (@{$node->{list_expr}}) {
        foreach my $label (@{$case->{list_label}}) {    # default or expression
            if ($label->isa('Default')) {
                print $FH "\t\t\tdefault: \\\n";
            }
            else {
                print $FH "\t\t\tcase " . $label->{c_literal} . ": \\\n";
            }
        }
        my $defn = $self->_get_defn($case->{element}->{value});
        $self->_member_from($defn, '_u.');
        print $FH "\t\t\t\tbreak; \\\n";
    }
    print $FH "\t\t} \\\n";
    print $FH "\t\tPyTuple_SetItem(_duo, 1, _v); \\\n";
    if ($self->{old_object}) {
        print $FH "\t\tobj = PyInstance_New(_cls_",$node->{c_name},", _duo, NULL); /* New reference */ \\\n";
    }
    else {
        print $FH "\t\tobj = PyObject_Call(_cls_",$node->{c_name},", _duo, NULL); \\\n";
    }
    print $FH "\t\tassert(obj != NULL); \\\n";
    print $FH "\t}\n";
    print $FH "\n";
    if (defined $node->{length}) {
        if (exists $self->{extended}) {
            print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
            print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        }
        print $FH "#define FREE_out_",$node->{c_name},"(v) { \\\n";
        print $FH "\t\tif (NULL != (v)) { \\\n";
        print $FH "\t\t\tFREE_",$node->{c_name},"(v); \\\n";
        print $FH "\t\t\tCORBA_free(v); \\\n";
        print $FH "\t}\n";
        print $FH "#define FREE_",$node->{c_name},"(v) { \\\n";
        print $FH "\t\tswitch ((v)->_d) { \\\n";
        foreach my $case (@{$node->{list_expr}}) {
            foreach my $label (@{$case->{list_label}}) {    # default or expression
                if ($label->isa('Default')) {
                    print $FH "\t\t\tdefault: \\\n";
                }
                else {
                    print $FH "\t\t\tcase " . $label->{c_literal} . ": \\\n";
                }
            }
            my $defn = $self->_get_defn($case->{element}->{value});
            $self->_member_free($defn, '_u.');
            print $FH "\t\t\t\tbreak; \\\n";
        }
        print $FH "\t\t} \\\n";
        print $FH "\t}\n";
    }
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

sub visitEnumType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{idf}});
    $self->{done_hash}->{$node->{idf}} = 1;
    my $FH = $self->{out};
    my ($c_mod, $py_mod, $classname) = $self->_split_name($node);
    print $FH "/* enum ",$node->{c_name}," */\n";
    print $FH "static PyObject* _cls_",$node->{c_name}," = NULL;\n";
    print $FH "\n";
    if (exists $self->{embedded}) {
        print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj) \\\n";
        print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
        print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
        print $FH "\t} \\\n";
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
        }
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(PyObject_IsInstance((obj), _cls_",$node->{c_name},")); \\\n";
        }
        print $FH "\tif (!PyObject_IsInstance((obj), _cls_",$node->{c_name},")) { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
        print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) PYOBJ_AS_",$node->{c_name},"(*(val), obj)\n";
    }
    print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
    print $FH "\t{ \\\n";
    print $FH "\t\tPyObject* _val = PyObject_GetAttrString((obj), \"_val\"); /* New reference */ \\\n";
    print $FH "\t\tif (_val == NULL) { \\\n";
    if ($self->{assert}) {
        print $FH "\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name},"\"); \\\n";
    }
    print $FH "\t\t\t",$self->{error},"; \\\n";
    print $FH "\t\t} \\\n";
    print $FH "\t\t(val) = PyInt_AsLong(_val); \\\n";
    print $FH "\t\tPy_DECREF(_val); \\\n";
    print $FH "\t}\n";
    print $FH "\n";
    print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
    print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
    print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
    print $FH "\t} \\\n";
    print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
    print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
    print $FH "\t} \\\n";
    if ($self->{assert}) {
        print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
    }
    print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
    print $FH "\t\t",$self->{error},"; \\\n";
    print $FH "\t} else { \\\n";
    print $FH "\t\tPyObject* _long; \\\n";
    print $FH "\t\tPyObject* _enum = PyObject_GetAttrString(_cls_",$node->{c_name},", \"_enum\"); /* New reference */ \\\n";
    print $FH "\t\tif (_enum == NULL) { \\\n";
    if ($self->{assert}) {
        print $FH "\t\t\tassert(0 == \"PYOBJ_FROM_",$node->{c_name}," (_enum == NULL)\"); \\\n";
    }
    print $FH "\t\t\t",$self->{error},"; \\\n";
    print $FH "\t\t} \\\n";
    print $FH "\t\t_long = PyInt_FromLong(val); \\\n";
    print $FH "\t\t(obj) = PyDict_GetItem(_enum, _long); /* Borrowed reference */ \\\n";
    print $FH "\t\tPy_DECREF(_long); \\\n";
    print $FH "\t\tif ((obj) == NULL) { \\\n";
    print $FH "\t\t\tPy_DECREF(_enum); \\\n";
    if ($self->{assert}) {
        print $FH "\t\t\tassert(0 == \"PYOBJ_FROM_",$node->{c_name}," (obj == NULL)\"); \\\n";
    }
    print $FH "\t\t\tPyErr_Format(PyExc_RuntimeError, \"can't retrieve enum '",$node->{py_name},"'(%lu)\", (val)); \\\n";
    print $FH "\t\t\t",$self->{error},"; \\\n";
    print $FH "\t\t} \\\n";
    print $FH "\t\tPy_INCREF((obj)); \\\n";
    print $FH "\t\tPy_DECREF(_enum); \\\n";
    print $FH "\t}\n";
    print $FH "\n";
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('SequenceType')
            or $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    my $nb = '(val)._length';
    $nb = $node->{max}->{c_literal} if (exists $node->{max});
    if (exists $self->{extended}) {
        print $FH "#ifndef _hpy_",$node->{c_name},"_defined\n";
        print $FH "#define _hpy_",$node->{c_name},"_defined\n";
    }
    if ($type->isa('CharType') or $type->isa('OctetType')) {
        if (exists $self->{embedded}) {
            print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj) \\\n";
            print $FH "\tif (!PyString_Check(obj)) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\tassert(0 == \"PYOBJ_CHECK_",$node->{c_name}," PyString_Check\"); \\\n";
            }
            print $FH "\t\t",$self->{error},"; \\\n";
            print $FH "\t} \\\n";
            print $FH "\n";
            print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) \\\n";
            print $FH "\t{ \\\n";
            if (exists $node->{max}) {
                print $FH "\t\tif (PyString_Size(obj) > ",$node->{max}->{c_literal},") { \\\n";
                print $FH "\t\t\tPyErr_SetString(PyExc_RuntimeError, NULL); \\\n";
                if ($self->{assert}) {
                    print $FH "\t\t\tassert(0 == \"PYOBJ_AS_inout_",$node->{c_name}," PyString_Size\"); \\\n";
                }
                print $FH "\t\t\t",$self->{error},"; \\\n";
                print $FH "\t\t} \\\n";
                print $FH "\t\t(val)->_length = PyString_Size(obj); \\\n";
                print $FH "\t\tif (0 != (val)->_length) { \\\n";
                print $FH "\t\t\tmemcpy((val)->_buffer, PyString_AsString(obj), (val)->_length); \\\n";
                print $FH "\t\t} \\\n";
            }
            else {
                print $FH "\t\tif (PyString_Size(obj) > (val)->_maximum) { \\\n";
                print $FH "\t\t\tfree((val)->_buffer); \\\n";
                print $FH "\t\t\tPYOBJ_AS_",$node->{c_name},"(*(val), obj); \\\n";
                print $FH "\t\t} else { \\\n";
                print $FH "\t\t\t(val)->_length = PyString_Size(obj); \\\n";
                print $FH "\t\t\tif (0 != (val)->_length) { \\\n";
                print $FH "\t\t\t\tmemcpy((val)->_buffer, PyString_AsString(obj), (val)->_length); \\\n";
                print $FH "\t\t\t} \\\n";
                print $FH "\t\t} \\\n";
            }
            print $FH "\t}\n";
            print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) \\\n";
            print $FH "\t{ \\\n";
            print $FH "\t\t(val) = ",$node->{c_name},"__alloc(1); \\\n";
            print $FH "\t\tif (NULL == (val)) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\t\tassert(0 == \"PYOBJ_AS_out_",$node->{c_name}," alloc\"); \\\n";
            }
            print $FH "\t\t\tPyErr_SetString(PyExc_MemoryError, NULL); \\\n";
            print $FH "\t\t\t",$self->{error},"; \\\n";
            print $FH "\t\t} \\\n";
            print $FH "\t\tPYOBJ_AS_",$node->{c_name},"(*(val), obj); \\\n";
            print $FH "\t}\n";
        }
        print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
        print $FH "\t{ \\\n";
        print $FH "\t\t(val)._length = PyString_Size(obj); \\\n";
        if (exists $self->{embedded}) {
            print $FH "\t\t(val)._maximum = ",$nb,"; \\\n";
        }
        print $FH "\t\tif (0 != ",$nb,") { \\\n";
        print $FH "\t\t\t(val)._buffer = ",$node->{c_name},"__allocbuf(",$nb,"); \\\n";
        print $FH "\t\t\tif (NULL == (val)._buffer) { \\\n";
        if ($self->{assert}) {
            print $FH "\t\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," alloc\"); \\\n";
        }
        print $FH "\t\t\t\tPyErr_SetString(PyExc_MemoryError, NULL); \\\n";
        print $FH "\t\t\t\t",$self->{error},"; \\\n";
        print $FH "\t\t\t} \\\n";
        print $FH "\t\t\tmemcpy((val)._buffer, PyString_AsString(obj), (val)._length); \\\n";
        print $FH "\t\t} else { \\\n";
        print $FH "\t\t\t(val)._buffer = NULL; \\\n";
        print $FH "\t\t} \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
        if (exists $self->{embedded}) {
            print $FH "\tif (NULL == &(val)) { \\\n";
            print $FH "\t\t(obj) = Py_None; \\\n";
            print $FH "\t} else { \\\n";
        }
        else {
            print $FH "\t{ \\\n";
        }
        if ($type->isa('CharType')) {
            print $FH "\t\t(obj) = PyString_FromStringAndSize((val)._buffer, (val)._length); /* New reference */ \\\n";
        }
        else {
            print $FH "\t\t(obj) = PyString_FromStringAndSize((char *)((val)._buffer), (val)._length); /* New reference */ \\\n";
        }
        print $FH "\t}\n";
        print $FH "\n";
    }
    else {
        if (exists $self->{embedded}) {
            print $FH "#define PYOBJ_CHECK_",$node->{c_name},"(obj) \\\n";
            print $FH "\tif (!PySequence_Check(obj)) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\tassert(0 == \"PYOBJ_CHECK_",$node->{c_name}," PySequence_Check\"); \\\n";
            }
            print $FH "\t\t",$self->{error},"; \\\n";
            print $FH "\t}\n";
            print $FH "\n";
            print $FH "#define PYOBJ_AS_inout_",$node->{c_name},"(val, obj) \\\n";
            print $FH "\t{ \\\n";
            print $FH "\t\tint pos; \\\n";
            print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr; \\\n";
            if (exists $node->{max}) {
                print $FH "\t\tif (PySequence_Size(obj) > ",$node->{max}->{c_literal},") { \\\n";
                print $FH "\t\t\tPyErr_SetString(PyExc_RuntimeError, NULL); \\\n";
                if ($self->{assert}) {
                    print $FH "\t\t\tassert(0 == \"PYOBJ_AS_inout_",$node->{c_name},"\"); \\\n";
                }
                print $FH "\t\t\t",$self->{error},"; \\\n";
                print $FH "\t\t} \\\n";
                print $FH "\t\t(val)->_length = PySequence_Size(obj); \\\n";
                print $FH "\t\tCOPY_AS_",$node->{c_name},"(*(val), obj); \\\n";
            }
            else {
                print $FH "\t\tif (PySequence_Size(obj) > (val)->_maximum) { \\\n";
                print $FH "\t\t\tfree((val)->_buffer); \\\n";
                print $FH "\t\t\tPYOBJ_AS_",$node->{c_name},"(*(val), obj); \\\n";
                print $FH "\t\t} else { \\\n";
                print $FH "\t\t\t(val)->_length = PySequence_Size(obj); \\\n";
                print $FH "\t\t\tCOPY_AS_",$node->{c_name},"(*(val), obj); \\\n";
                print $FH "\t\t} \\\n";
            }
            print $FH "\t}\n";
            print $FH "#define PYOBJ_AS_out_",$node->{c_name},"(val, obj) \\\n";
            print $FH "\t{ \\\n";
            print $FH "\t\t(val) = ",$node->{c_name},"__alloc(1); \\\n";
            print $FH "\t\tif (NULL == (val)) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\t\tassert(0 == \"PYOBJ_AS_out_",$node->{c_name}," alloc\"); \\\n";
            }
            print $FH "\t\t\tPyErr_SetString(PyExc_MemoryError, NULL); \\\n";
            print $FH "\t\t\t",$self->{error},"; \\\n";
            print $FH "\t\t} \\\n";
            print $FH "\t\tPYOBJ_AS_",$node->{c_name},"(*(val), obj); \\\n";
            print $FH "\t}\n";
        }
        print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
        print $FH "\t{ \\\n";
        print $FH "\t\t(val)._length = PySequence_Size(obj); \\\n";
        if (exists $self->{embedded}) {
            print $FH "\t\t(val)._maximum = ",$nb,"; \\\n";
        }
        print $FH "\t\tif (0 != ",$nb,") { \\\n";
        print $FH "\t\t\t(val)._buffer = ",$node->{c_name},"__allocbuf(",$nb,"); \\\n";
        print $FH "\t\t\tif (NULL == (val)._buffer) { \\\n";
        if ($self->{assert}) {
            print $FH "\t\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," alloc\"); \\\n";
        }
        print $FH "\t\t\t\tPyErr_SetString(PyExc_MemoryError, NULL); \\\n";
        print $FH "\t\t\t\t",$self->{error},"; \\\n";
        print $FH "\t\t\t} \\\n";
        print $FH "\t\t\tCOPY_AS_",$node->{c_name},"(val, obj); \\\n";
        print $FH "\t\t} else { \\\n";
        print $FH "\t\t\t(val)._buffer = NULL; \\\n";
        print $FH "\t\t} \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        print $FH "#define COPY_AS_",$node->{c_name},"(val, obj) \\\n";
        print $FH "\t{ \\\n";
        print $FH "\t\tint pos; \\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr; \\\n";
        print $FH "\t\tfor (",$node->{c_name},"_ptr = (val)._buffer, pos = 0; \\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr < (val)._buffer + (val)._length; \\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr++, pos++) { \\\n";
        print $FH "\t\t\tPyObject * _item = PySequence_GetItem(obj, pos); /* New reference */ \\\n";
        print $FH "\t\t\tif (NULL == _item) { \\\n";
        if ($self->{assert}) {
            print $FH "\t\t\t\tassert(0 == \"COPY_AS_",$node->{c_name}," PySequence_GetItem\"); \\\n";
        }
        print $FH "\t\t\t\t",$self->{error},"; \\\n";
        print $FH "\t\t\t} \\\n";
        my $fmt = $self->_get_cpy_format($type);
        if ($fmt eq 'O') {
            if (exists $self->{embedded}) {
            print $FH "\t\t\tPYOBJ_CHECK_",$type->{c_name},"(_item); \\\n";
            }
            print $FH "\t\t\tPYOBJ_AS_",$type->{c_name},"(*",$node->{c_name},"_ptr, _item); \\\n";
        }
        else {
            my $args = $node->{c_name} . '_ptr';
            print $FH "\t\t\tif (!parse_object(_item, \"",$fmt,"\", ",$args,")) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\t\t\tassert(0 == \"COPY_AS_",$node->{c_name}," parse_object\"); \\\n";
            }
            print $FH "\t\t\t\tPy_DECREF(_item); \\\n";
            print $FH "\t\t\t\t",$self->{error},"; \\\n";
            print $FH "\t\t\t} \\\n";
        }
        print $FH "\t\t\tPy_DECREF(_item); \\\n";
        print $FH "\t\t} \\\n";
        print $FH "\t}\n";
        print $FH "\n";
        print $FH "#define PYOBJ_FROM_",$node->{c_name},"(obj, val) \\\n";
        if (exists $self->{embedded}) {
            print $FH "\tif (NULL == &(val)) { \\\n";
            print $FH "\t\t(obj) = Py_None; \\\n";
            print $FH "\t} else { \\\n";
        }
        else {
            print $FH "\t{ \\\n";
        }
        print $FH "\t\tint pos; \\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr; \\\n";
        print $FH "\t\t(obj) = PyList_New((val)._length); /* New reference */ \\\n";
        print $FH "\t\tfor (",$node->{c_name},"_ptr = (val)._buffer, pos = 0; \\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr < (val)._buffer + (val)._length; \\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr++, pos++) { \\\n";
        print $FH "\t\t\tPyObject * _item; \\\n";
        if ($fmt eq 'O') {
            print $FH "\t\t\tPYOBJ_FROM_",$type->{c_name},"(_item, *",$node->{c_name},"_ptr); \\\n";
        }
        else {
            my $args = '*' . $node->{c_name} . '_ptr';
            print $FH "\t\t\t_item = Py_BuildValue(\"",$fmt,"\", ",$args,"); /* New reference */ \\\n";
        }
        print $FH "\t\t\tPyList_SetItem((obj), pos, _item); \\\n";
        print $FH "\t\t} \\\n";
        print $FH "\t}\n";
        print $FH "\n";
    }
    if (exists $self->{extended}) {
        print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
    }
    print $FH "#define FREE_out_",$node->{c_name},"(v) \\\n";
    print $FH "\t{ \\\n";
    print $FH "\t\tif (NULL != (v)) {\\\n";
    print $FH "\t\t\tFREE_",$node->{c_name},"(v);\\\n";
    print $FH "\t\t\tCORBA_free(v);\\\n";
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    print $FH "#define FREE_",$node->{c_name},"(v) \\\n";
    print $FH "\t{ \\\n";
    print $FH "\t\tif (NULL != (v)->_buffer) {\\\n";
    if (defined $type->{length}) {
        print $FH "\t\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
        print $FH "\t\t\tfor (",$node->{c_name},"_ptr = (v)->_buffer;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr < (v)->_buffer + (v)->_length;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr++) {\\\n";
        print $FH "\t\t\t\tFREE_",$type->{c_name},"(",$node->{c_name},"_ptr);\\\n";
        print $FH "\t\t\t}\\\n";
    }
    print $FH "\t\t\tCORBA_free((v)->_buffer);\\\n";
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    if (exists $self->{extended}) {
        print $FH "#endif\n";
    }
    print $FH "\n";
}

sub visitStringType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    if (exists $self->{extended}) {
        print $FH "#ifndef _hpy_",$node->{c_name},"_defined\n";
        print $FH "#define _hpy_",$node->{c_name},"_defined\n";
        print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
    }
    print $FH "#define FREE_out_",$node->{c_name}," FREE_",$node->{c_name},"\n";
    print $FH "#define FREE_",$node->{c_name},"(v) CORBA_free(*(v))\n";
    if (exists $self->{extended}) {
        print $FH "#endif\n";
    }
    print $FH "\n";
}

sub visitWideStringType {
    my $self = shift;
    my ($node) = @_;
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    if (exists $self->{extended}) {
        print $FH "#ifndef _hpy_",$node->{c_name},"_defined\n";
        print $FH "#define _hpy_",$node->{c_name},"_defined\n";
        print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
    }
    print $FH "#define FREE_out_",$node->{c_name}," FREE_",$node->{c_name},"\n";
    print $FH "#define FREE_",$node->{c_name},"(v) CORBA_free(*(v))\n";
    if (exists $self->{extended}) {
        print $FH "#endif\n";
    }
    print $FH "\n";
}

sub visitFixedPtType {
    # empty
}

sub visitFixedPtConstType {
    # empty
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    my $len = 0;
    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});
        $len = scalar(@{$node->{list_expr}});
        foreach (@{$node->{list_expr}}) {
            my $type = $self->_get_defn($_->{type});
            if (       $type->isa('StructType')
                    or $type->isa('UnionType')
                    or $type->isa('SequenceType')
                    or $type->isa('FixedPtType') ) {
                $type->visit($self);
            }
        }
    }
    my $FH = $self->{out};
    my ($c_mod, $py_mod, $classname) = $self->_split_name($node);
    print $FH "/* exception ",$node->{idf}," */\n";
    print $FH "static PyObject* _cls_",$node->{c_name}," = NULL;\n";
    print $FH "\n";
    if (exists $self->{extended}) {
        print $FH "#define RAISE_",$node->{c_name}," \\\n";
        print $FH "\tif (NULL == _mod_",$c_mod,") { \\\n";
        print $FH "\t\t_mod_",$c_mod," = PyImport_ImportModule(\"",$py_mod,"\"); /* New reference */ \\\n";
        print $FH "\t} \\\n";
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t_cls_",$node->{c_name}," = find_class(_mod_",$c_mod,", \"",$classname,"\"); \\\n";
        print $FH "\t} \\\n";
        if ($self->{assert}) {
            print $FH "\tassert(NULL != _cls_",$node->{c_name},"); \\\n";
        }
        print $FH "\tif (NULL == _cls_",$node->{c_name},") { \\\n";
        print $FH "\t\t",$self->{error},"; \\\n";
        print $FH "\t} else { \\\n";
        if ($len) {
            my @fmt_out = ();
            my $args_out = q{};
            foreach (@{$node->{list_member}}) {
                my $defn = $self->_get_defn($_);
                my $fmt = $self->_member_fmt($defn);
                if ($fmt eq 'O') {
                    print $FH "\t\tPyObject* _",$defn->{c_name},"; \\\n";
                    $args_out .= ', _' . $defn->{c_name};
                }
                else {
                    $args_out .= ', ((' . $node->{c_name} . '*)CORBA_exception_value(&_ev))->' . $defn->{c_name};
                }
                push @fmt_out, $fmt;
            }
            print $FH "\t\tPyObject* _args; \\\n";
            foreach (@{$node->{list_member}}) {
                my $defn = $self->_get_defn($_);
                $self->_member_from($defn);
            }
            print $FH "\t\t_args = Py_BuildValue(\"",@fmt_out,"\"",$args_out,"); /* New reference */ \\\n";
            print $FH "\t\tPyErr_SetObject(_cls_",$node->{c_name},", _args); \\\n";
        }
        else {
            print $FH "\t\tPyErr_SetObject(_cls_",$node->{c_name},", PyTuple_New(0)); \\\n";
        }
        print $FH "\t}\n";
    }
    else {
        print $FH "#define PYOBJ_AS_",$node->{c_name},"(val, obj) \\\n";
        print $FH "\t{ \\\n";
        if ($len) {
            print $FH "\t\tPyObject * _member; \\\n";
            my @fmt_inout = ();
            my $args_in = q{};
            my $args_out = q{};
            foreach (@{$node->{list_member}}) {
                my $defn = $self->_get_defn($_);
                my $fmt = $self->_member_fmt($defn);
                if ($fmt eq 'O') {
                    print $FH "\t\tPyObject * _",$defn->{c_name},"; \\\n";
                    $args_in .= ', &_' . $defn->{c_name};
                    $args_out .= ', _' . $defn->{c_name};
                }
                else {
                    $args_in .= ', &(val).' . $defn->{c_name};
                    $args_out .= ', (val).' . $defn->{c_name};
                }
                push @fmt_inout, $fmt;
            }
            print $FH "\t\tPyObject * _args = PyTuple_New(",scalar(@{$node->{list_member}}),"); /* New reference */ \\\n";
            my $i = 0;
            foreach (@{$node->{list_member}}) {
                my $defn = $self->_get_defn($_);
                my $type = $self->_get_defn($defn->{type});
                print $FH "\t\t_member = PyObject_GetAttrString((obj), \"",$defn->{py_name},"\"); /* New reference */ \\\n";
                print $FH "\t\tPyTuple_SetItem(_args, ",$i,", _member); \\\n";
                $i ++;
            }
            print $FH "\t\tif (!PyArg_ParseTuple(_args, \"",@fmt_inout,"\"",$args_in,")) { \\\n";
            if ($self->{assert}) {
                print $FH "\t\t\tassert(0 == \"PYOBJ_AS_",$node->{c_name}," PyArg_ParseTuple ",@fmt_inout,"\"); \\\n";
            }
            print $FH "\t\t\t",$self->{error},"; \\\n";
            print $FH "\t\t} \\\n";
            foreach (@{$node->{list_member}}) {
                my $defn = $self->_get_defn($_);
                $self->_member_as($defn);
            }
        }
        print $FH "\t}\n";
        print $FH "\n";
        if (defined $node->{length}) {
            print $FH "#define FREE_",$node->{c_name},"(v) { \\\n";
            foreach (@{$node->{list_member}}) {
                my $defn = $self->_get_defn($_);
                $self->_member_free($defn);
            }
            print $FH "\t}\n";
        }
    }
    print $FH "\n";
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('StringType')
            or $type->isa('WideStringType') ) {
        $type->visit($self);
    }
    foreach (@{$node->{list_param}}) {
        my $defn = $self->_get_defn($_);
        my $type = $self->_get_defn($defn->{type});
        if (       $type->isa('StringType')
                or $type->isa('WideStringType') ) {
            $type->visit($self);
        }
    }
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
#   XPIDL
#

sub visitCodeFragment {
    # empty
}

1;

