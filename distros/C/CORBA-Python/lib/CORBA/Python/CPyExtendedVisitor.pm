
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Python::CPyExtendedVisitor;

use strict;
use warnings;

our $VERSION = '2.64';

use CORBA::Python::CPyVisitor;
use base qw(CORBA::Python::CPyVisitor);

use File::Basename;
use POSIX qw(ctime);

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
    $self->{client} = 1;
    if (exists $parser->YYData->{opt_J}) {
        $self->{base_package} = $parser->YYData->{opt_J};
    }
    else {
        $self->{base_package} = q{};
    }
    $self->{done_hash} = {};
    $self->{out} = undef;
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    $self->{out} = new IO::File "> $filename"
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

sub _import_module {
    my $self = shift;
    my ($defn) = @_;
    my $mod = $defn;
    my $full = $mod->{full};
    my $modulename;
    my $c_mod;
    my $classname = q{};
    while (!$mod->isa('Modules')) {
        $full =~ s/(::[0-9A-Z_a-z]+)$//;
        $classname = $1 . $classname;
        last unless ($full);
        $mod = $self->{symbtab}->Lookup($full);
    }
    $classname =~ s/^:://;
    $classname =~ s/::/\./g;
    if ($full) {
        $modulename = $full;
        $modulename =~ s/^:://;
        $modulename =~ s/::/\./g;
        $c_mod = $mod->{c_name};
    }
    else {
        $modulename = $self->{root_module};
        $c_mod = $modulename;
    }
    unless (exists $self->{imp_mod}->{$modulename}) {
        $self->{imp_mod}->{$modulename} = 1;
        $self->{init} .= "\t_mod_" . $c_mod . " = PyImport_ImportModule(\"" . $modulename . "\"); // New reference\n";
    }
}

sub _get_c_decl_var {
    my $self = shift;
    my ($type, $attr, $name) = @_;

    if ( $type->isa('BaseInterface')
      or $type->isa('BasicType')
      or $type->isa('EnumType')
      or $type->isa('StringType')
      or $type->isa('WideStringType')
      or $type->isa('FixedPtType') ) {
        if (    $attr eq 'in' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'inout' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'out' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'return' ) {
            return $type->{c_name} . q{ } . $name;
        }
    }
    elsif ( $type->isa('StructType')
         or $type->isa('UnionType') ) {
        if (    $attr eq 'in' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'inout' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'out' ) {
            if (defined $type->{length}) {      # variable
                return $type->{c_name} . ' * ' . $name;
            }
            else {
                return $type->{c_name} . q{ } . $name;
            }
        }
        elsif ( $attr eq 'return' ) {
            if (defined $type->{length}) {      # variable
                return $type->{c_name} . ' * ' . $name;
            }
            else {
                return $type->{c_name} . q{ } . $name;
            }
        }
    }
    elsif ( $type->isa('SequenceType') ) {
        if (    $attr eq 'in' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'inout' ) {
            return $type->{c_name} . q{ } . $name;
        }
        elsif ( $attr eq 'out' ) {
            return $type->{c_name} . ' * ' . $name;
        }
        elsif ( $attr eq 'return' ) {
            return $type->{c_name} . ' * ' . $name;
        }
    }
    elsif ( $type->isa('TypeDeclarator') ) {
        if (exists $type->{array_size}) {
            warn "_get_c_decl_var TypeDeclarator $type->{idf} : empty array_size.\n"
                    unless (@{$type->{array_size}});
            if (    $attr eq 'in' ) {
                return $type->{c_name} . q{ } . $name;
            }
            elsif ( $attr eq 'inout' ) {
                return $type->{c_name} . q{ } . $name;
            }
            elsif ( $attr eq 'out' ) {
                if (defined $type->{length}) {      # variable
                    return $type->{c_name} . '_slice * ' . $name;
                }
                else {
                    return $type->{c_name} . q{ } . $name;
                }
            }
            elsif ( $attr eq 'return' ) {
                return $type->{c_name} . '_slice ' . $name;
            }
        }
        else {
            my $type = $type->{type};
            unless (ref $type) {
                $type = $self->{symbtab}->Lookup($type);
            }
            return $self->_get_c_decl_var($type, $attr, $name);
        }
    }
    elsif ( $type->isa('NativeType') ) {
        warn "_get_c_decl_var NativeType : not supplied \n";
        return;
    }
    elsif ( $type->isa('AnyType') ) {
        warn "_get_c_decl_var AnyType : not supplied \n";
        return;
    }
    else {
        my $class = ref $type;
        warn "Please implement '$class' in '_get_c_decl_var'.\n";
        return;
    }
}

sub _get_c_name_call {
    my $self = shift;
    my ($type, $attr) = @_;

    if ( $type->isa('BaseInterface')
      or $type->isa('BasicType')
      or $type->isa('EnumType')
      or $type->isa('StringType')
      or $type->isa('WideStringType') ) {
        if (    $attr eq 'in' ) {
            return q{};
        }
        elsif ( $attr eq 'inout' ) {
            return '&';
        }
        elsif ( $attr eq 'out' ) {
            return '&';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $type->isa('StructType')
         or $type->isa('UnionType')
         or $type->isa('SequenceType')
         or $type->isa('FixedPtType') ) {
        if (    $attr eq 'in' ) {
            return '&';
        }
        elsif ( $attr eq 'inout' ) {
            return '&';
        }
        elsif ( $attr eq 'out' ) {
            return '&';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $type->isa('TypeDeclarator') ) {
        if (exists $type->{array_size}) {
            warn "_get_c_name_call TypeDeclarator $type->{idf} : empty array_size.\n"
                    unless (@{$type->{array_size}});
            if (    $attr eq 'in' ) {
                return q{};
            }
            elsif ( $attr eq 'inout' ) {
                return q{};
            }
            elsif ( $attr eq 'out' ) {
                if (defined $type->{length}) {      # variable
                    return q{};
                }
                else {
                    return q{};
                }
            }
            elsif ( $attr eq 'return' ) {
                return q{};
            }
        }
        else {
            my $type = $type->{type};
            unless (ref $type) {
                $type = $self->{symbtab}->Lookup($type);
            }
            return $self->_get_c_name_call($type, $attr);
        }
    }
    elsif ( $type->isa('NativeType') ) {
        warn "_get_c_name_call NativeType : not supplied \n";
        return;
    }
    elsif ( $type->isa('AnyType') ) {
        warn "_get_c_name_call AnyType : not supplied \n";
        return;
    }
    else {
        my $class = ref $type;
        warn "Please implement '$class' in '_get_c_name_call'.\n";
        return;
    }
}

sub _get_c_free {
    my $self = shift;
    my ($type, $attr) = @_;

    if ( $type->isa('BaseInterface')
      or $type->isa('BasicType')
      or $type->isa('EnumType')
      or $type->isa('FixedPtType') ) {
        if (    $attr eq 'in' ) {
            return '&';
        }
        elsif ( $attr eq 'inout' ) {
            return '&';
        }
        elsif ( $attr eq 'out' ) {
            return '&';
        }
        elsif ( $attr eq 'return' ) {
            return '&';
        }
    }
    elsif ( $type->isa('StructType')
         or $type->isa('UnionType') ) {
        if (    $attr eq 'in' ) {
            return '&';
        }
        elsif ( $attr eq 'inout' ) {
            return '&';
        }
        elsif ( $attr eq 'out' ) {
            if (defined $type->{length}) {      # variable
                return q{};
            }
            else {
                return '&';
            }
        }
        elsif ( $attr eq 'return' ) {
            if (defined $type->{length}) {      # variable
                return q{};
            }
            else {
                return '&';
            }
        }
    }
    elsif ( $type->isa('SequenceType') ) {
        if (    $attr eq 'in' ) {
            return '&';
        }
        elsif ( $attr eq 'inout' ) {
            return '&';
        }
        elsif ( $attr eq 'out' ) {
            return q{};
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $type->isa('StringType')
         or $type->isa('WideStringType') ) {
        if (    $attr eq 'in' ) {
            return '&';
        }
        elsif ( $attr eq 'inout' ) {
            return '&';
        }
        elsif ( $attr eq 'out' ) {
            return '&';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $type->isa('TypeDeclarator') ) {
        if (exists $type->{array_size}) {
            warn "_get_c_free TypeDeclarator $type->{idf} : empty array_size.\n"
                    unless (@{$type->{array_size}});
            if (    $attr eq 'in' ) {
                return '&';
            }
            elsif ( $attr eq 'inout' ) {
                return '&';
            }
            elsif ( $attr eq 'out' ) {
                if (defined $type->{length}) {      # variable
                    return '&';
                }
                else {
                    return '&';
                }
            }
            elsif ( $attr eq 'return' ) {
                return '&';
            }
        }
        else {
            my $type = $type->{type};
            unless (ref $type) {
                $type = $self->{symbtab}->Lookup($type);
            }
            return $self->_get_c_free($type, $attr);
        }
    }
    elsif ( $type->isa('NativeType') ) {
        warn "_get_c_free NativeType : not supplied \n";
        return;
    }
    elsif ( $type->isa('AnyType') ) {
        warn "_get_c_free AnyType : not supplied \n";
        return;
    }
    else {
        my $class = ref $type;
        warn "Please implement '$class' in '_get_c_free'.\n";
        return;
    }
}

sub _get_c_ext_obj {
    my $self = shift;
    my ($type, $attr) = @_;

    if ( $type->isa('BaseInterface')
      or $type->isa('FloatingPtType')
      or $type->isa('IntegerType')
      or $type->isa('OctetType')
      or $type->isa('CharType')
      or $type->isa('BooleanType')
      or $type->isa('EnumType')
      or $type->isa('StringType') ) {
        if (    $attr eq 'in' ) {
            return q{};
        }
        elsif ( $attr eq 'inout' ) {
            return q{};
        }
        elsif ( $attr eq 'out' ) {
            return q{};
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $type->isa('StructType')
         or $type->isa('UnionType') ) {
        if (    $attr eq 'in' ) {
            return q{};
        }
        elsif ( $attr eq 'inout' ) {
            return q{};
        }
        elsif ( $attr eq 'out' ) {
            if (defined $type->{length}) {      # variable
                return '*';
            }
            else {
                return q{};
            }
        }
        elsif ( $attr eq 'return' ) {
            if (defined $type->{length}) {      # variable
                return '*';
            }
            else {
                return q{};
            }
        }
    }
    elsif ( $type->isa('SequenceType') ) {
        if (    $attr eq 'in' ) {
            return q{};
        }
        elsif ( $attr eq 'inout' ) {
            return q{};
        }
        elsif ( $attr eq 'out' ) {
            return '*';
        }
        elsif ( $attr eq 'return' ) {
            return q{};
        }
    }
    elsif ( $type->isa('TypeDeclarator') ) {
        if (exists $type->{array_size}) {
            warn __PACKAGE__,"::NameAttrTypeDeclarator $type->{idf} : empty array_size.\n"
                    unless (@{$type->{array_size}});
            if (    $attr eq 'in' ) {
                return q{};
            }
            elsif ( $attr eq 'inout' ) {
                return q{};
            }
            elsif ( $attr eq 'out' ) {
                if (defined $type->{length}) {      # variable
                    return q{};
                }
                else {
                    return q{};
                }
            }
            elsif ( $attr eq 'return' ) {
                return q{};
            }
        }
        else {
            my $type = $type->{type};
            unless (ref $type) {
                $type = $self->{symbtab}->Lookup($type);
            }
            return $self->_get_c_ext_obj($type, $attr);
        }
    }
    elsif ( $type->isa('NativeType') ) {
        warn "_get_c_ext_obj NativeType : not supplied \n";
        return;
    }
    elsif ( $type->isa('AnyType') ) {
        warn "_get_c_ext_obj AnyType : not supplied \n";
        return;
    }
    else {
        my $class = ref $type;
        warn "Please implement '$class' in '_get_c_ext_obj'.\n";
        return;
    }
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $basename = basename($self->{srcname}, '.idl');
    my $py_name = '_' . $basename;
    $py_name =~ s/\./_/g;
    $self->{root_module} = $py_name;
    $self->{init} = q{};
    $self->{methods} = q{};
    $self->{imp_mod} = {};
    my $empty = 1;
    foreach (@{$node->{list_decl}}) {
        my $defn = $self->_get_defn($_);
        unless (   $defn->isa('Modules')
                or $defn->isa('Import') ) {
            $empty = 0;
        }
    }
    unless ($empty) {
        my $filename = 'c' . $py_name . 'module.c';
        $self->open_stream($filename);
        my $FH = $self->{out};
        print $FH "/* ex: set ro: */\n";
        print $FH "/* This file was generated (by ",basename($0),"). DO NOT modify it */\n";
        print $FH "/* From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
        print $FH " */\n";
        print $FH "\n";
        print $FH "#include \"Python.h\"\n";
        print $FH "#include \"",$basename,".h\"\n";
        print $FH "\n";
        print $FH "#include \"hpy_",$basename,".h\"\n";
        print $FH "\n";
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    unless ($empty) {
        my $FH = $self->{out};
        print $FH "static PyMethodDef ",$py_name,"Methods[] = {\n";
        print $FH $self->{methods};
        print $FH "\t{ NULL, NULL }\n";
        print $FH "};\n";
        print $FH "\n";
        print $FH "PyMODINIT_FUNC\n";
        print $FH "initc",$py_name,"(void)\n";
        print $FH "{\n";
        print $FH "\tPyObject *m;\n";
        print $FH "\n";
        print $FH "\tm = Py_InitModule(\"c",$py_name,"\", ",$py_name,"Methods); // Borrowed reference\n";
        print $FH $self->{init};
        print $FH "}\n";
        print $FH "\n";
        print $FH "/* end of file : ",$self->{filename}," */\n";
        print $FH "/*\n";
        print $FH " * Local variables:\n";
        print $FH " *   buffer-read-only: t\n";
        print $FH " * End:\n";
        print $FH " */\n";    
        close $FH;
    }
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    my $basename = basename($self->{srcname}, '.idl');
    my @name = split /::/, $node->{full};
    shift @name;
    my $py_name = join '_', @name;
    $name[-1] = 'c' . $name[-1];
    my $filename = join '/', @name;
    $filename .= 'module.c';
    my $save_out = $self->{out};
    my $save_init = $self->{init};
    my $save_methods = $self->{methods};
    my $save_imp_mod = $self->{imp_mod};
    $self->open_stream($filename);
    $self->{init} = q{};
    $self->{methods} = q{};
    $self->{imp_mod} = {};
    my $FH = $self->{out};
    print $FH "/* ex: set ro: */\n";
    print $FH "/* This file was generated (by ",basename($0),"). DO NOT modify it */\n";
    print $FH "/* From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH " */\n";
    print $FH "\n";
    print $FH "#include \"Python.h\"\n";
    print $FH "#include \"",$basename,".h\"\n";
    print $FH "\n";
    print $FH "#include \"hpy_",$basename,".h\"\n";
    print $FH "\n";
    $self->{methods} = q{};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "static PyMethodDef ",$py_name,"Methods[] = {\n";
    print $FH $self->{methods};
    print $FH "\t{ NULL, NULL }\n";
    print $FH "};\n";
    print $FH "\n";
    print $FH "PyMODINIT_FUNC\n";
    print $FH "init",$name[-1],"(void)\n";
    print $FH "{\n";
    print $FH "\tPyObject *m;\n";
    print $FH "\n";
    print $FH "\tm = Py_InitModule(\"",$name[-1],"\", ",$py_name,"Methods); // Borrowed reference\n";
    print $FH $self->{init};
    print $FH "}\n";
    print $FH "\n";
    print $FH "/* end of file : ",$self->{filename}," */\n";
    print $FH "\n";
    print $FH "/*\n";
    print $FH " * Local variables:\n";
    print $FH " *   buffer-read-only: t\n";
    print $FH " * End:\n";
    print $FH " */\n";    
    close $FH;
    $self->{out} = $save_out;
    $self->{init} = $save_init;
    $self->{imp_mod} = $save_imp_mod;
    $self->{methods} = $save_methods;
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
    # empty
}

sub visitForwardBaseInterface {
    # empty
}

sub visitRegularInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    print $FH "/*\n";
    print $FH " * begin of interface ",$node->{py_name},"\n";
    print $FH " */\n";
    print $FH "\n";
    print $FH "typedef struct {\n";
    print $FH "\tPyObject_HEAD\n";
    print $FH "} ",$node->{c_name},"Object;\n";
    print $FH "\n";
    $self->{itf} = $node;
    my $save_methods = $self->{methods};
    $self->{methods} = q{};
    $self->{init} .= "\t" . $node->{c_name} . "Type.tp_new = PyType_GenericNew;\n";
    $self->{init} .= "\tif (PyType_Ready(&" . $node->{c_name} . "Type) < 0)\n";
    $self->{init} .= "\t\treturn;\n";
    $self->{init} .= "\tPy_INCREF(&" . $node->{c_name} . "Type);\n";
    $self->{init} .= "\tPyModule_AddObject(m, \"" . $node->{py_name} . "\", (PyObject*)&" . $node->{c_name} . "Type);\n";
    foreach (values %{$node->{hash_attribute_operation}}) {
        $self->_get_defn($_)->visit($self);
    }
    delete $self->{itf};
    print $FH "PyDoc_STRVAR(",$node->{c_name},"__doc__,";
    if (exists $node->{doc}) {
        print $FH "\n";
        print $FH "\"",$node->{doc},"\");\n";
    }
    else {
        print $FH " \"interface '",$node->{repos_id},"'\");\n";
    }
    print $FH "\n";
    print $FH "static PyMethodDef ",$node->{c_name},"Methods[] = {\n";
    print $FH $self->{methods};
    print $FH "\t{ NULL, NULL }\n";
    print $FH "};\n";
    print $FH "\n";
    print $FH "static PyTypeObject ",$node->{c_name},"Type = {\n";
    print $FH "\tPyObject_HEAD_INIT(NULL)\n";
    print $FH "\t0,\t/*ob_size*/\n";
    print $FH "\t\"",$node->{py_name},"\",\t/*tp_name*/\n";
    print $FH "\tsizeof(",$node->{c_name},"Object),\t/*tp_basicsize*/\n";
    print $FH "\t0,\t/*tp_itemsize*/\n";
    print $FH "\t0,\t/*tp_dealloc*/\n";
    print $FH "\t0,\t/*tp_print*/\n";
    print $FH "\t0,\t/*tp_getattr*/\n";
    print $FH "\t0,\t/*tp_setattr*/\n";
    print $FH "\t0,\t/*tp_compare*/\n";
    print $FH "\t0,\t/*tp_repr*/\n";
    print $FH "\t0,\t/*tp_as_number*/\n";
    print $FH "\t0,\t/*tp_as_sequence*/\n";
    print $FH "\t0,\t/*tp_as_mapping*/\n";
    print $FH "\t0,\t/*tp_hash */\n";
    print $FH "\t0,\t/*tp_call*/\n";
    print $FH "\t0,\t/*tp_str*/\n";
    print $FH "\t0,\t/*tp_getattro*/\n";
    print $FH "\t0,\t/*tp_setattro*/\n";
    print $FH "\t0,\t/*tp_as_buffer*/\n";
    print $FH "\tPy_TPFLAGS_DEFAULT,\t/*tp_flags*/\n";
    print $FH "\t",$node->{c_name},"__doc__,\t/* tp_doc */\n";
    print $FH "\t0,\t/*tp_traverse*/\n";
    print $FH "\t0,\t/*tp_clear*/\n";
    print $FH "\t0,\t/*tp_richcompare*/\n";
    print $FH "\t0,\t/*tp_weaklistoffset*/\n";
    print $FH "\t0,\t/*tp_iter*/\n";
    print $FH "\t0,\t/*tp_iternext*/\n";
    print $FH "\t",$node->{c_name},"Methods,\t/*tp_methods*/\n";
    print $FH "\t0,\t/*tp_members*/\n";
    print $FH "\t0,\t/*tp_getset*/\n";
    print $FH "\t0,\t/*tp_base*/\n";
    print $FH "\t0,\t/*tp_dict*/\n";
    print $FH "\t0,\t/*tp_descr_get*/\n";
    print $FH "\t0,\t/*tp_descr_set*/\n";
    print $FH "\t0,\t/*tp_dictoffset*/\n";
    print $FH "\t0,\t/*tp_init*/\n";
    print $FH "\t0,\t/*tp_alloc*/\n";
    print $FH "\t0,\t/*tp_new*/\n";
    print $FH "\t0,\t/*tp_free*/\n";
    print $FH "\t0,\t/*tp_is_gc*/\n";
    print $FH "};\n";
    print $FH "\n";
    print $FH "/*\n";
    print $FH " * end of interface ",$node->{py_name},"\n";
    print $FH " */\n";
    print $FH "\n";
    $self->{methods} = $save_methods;
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
    # empty
}

#
#   3.11.2  Constructed Types
#

sub visitStructType {
    # empty
}

sub visitUnionType {
    # empty
}

sub visitForwardStructType {
    # empty
}

sub visitForwardUnionType {
    # empty
}

sub visitEnumType {
    # empty
}

#
#   3.11.3  Template Types
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

sub visitException {
    # empty
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    my $name = $self->{itf}->{c_name} . '_' . $node->{c_name};
    print $FH "PyDoc_STRVAR(",$name,"__doc__,";
    if (exists $node->{doc}) {
        print $FH "\n";
        print $FH "\"",$node->{doc},"\");\n";
    }
    else {
        print $FH " \"\");\n";
    }
    print $FH "\n";
    my $label_err = undef;
    my $type = $self->_get_defn($node->{type});
    unless ($type->isa('VoidType')) {               # return
        $label_err = $type->{length};
    }
    foreach (@{$node->{list_in}}) {                 # parameter
        my $type = $self->_get_defn($_->{type});
        $label_err ||= $type->{length};
    }
    foreach (@{$node->{list_inout}}) {              # parameter
        my $type = $self->_get_defn($_->{type});
        $label_err ||= $type->{length};
    }
    foreach (@{$node->{list_out}}) {                # parameter
        my $type = $self->_get_defn($_->{type});
    }
    my $nb_user_except = 0;
    $nb_user_except = @{$node->{list_raise}} if (exists $node->{list_raise});
    print $FH "static PyObject *\n";
    print $FH $name,"_meth(",$self->{itf}->{c_name},"Object *self, PyObject *args)\n";
    print $FH "{\n";
    print $FH "\tCORBA_Environment _ev = { CORBA_NO_EXCEPTION, NULL, NULL, NULL };\n";
    if (exists $node->{list_context}) {
        print $FH "\tCORBA_Context _ctx;\n";
    }
    unless ($type->isa('VoidType')) {
        print $FH "\t",$self->_get_c_decl_var($type, 'return', '_ret'),";\n";
    }
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_defn($_->{type});
        print $FH "\t",$self->_get_c_decl_var($type, $_->{attr}, $_->{c_name}),";\n";
    }
    print $FH "#ifdef WITH_THREAD\n";
    print $FH "\tPyGILState_STATE _gstate;\n";
    print $FH "#endif\n";
    unless (exists $node->{modifier}) {     # oneway
        print $FH "\tPyObject * _result = NULL;\n";
    }
    my @fmt_in = ();
    my @fmt_out = ();
    my $args_in = q{};
    my $args_out = q{};
    unless ($type->isa('VoidType')) {
        my $fmt = $self->_get_cpy_format($type);
        if ($fmt eq 'O') {
            print $FH "\tPyObject * __ret;\n";
            $args_out .= ', __ret';
        }
        else {
            $args_out .= ', _ret';
        }
        push @fmt_out, $fmt;
    }
    foreach (@{$node->{list_param}}) {  # parameter
        my $type = $self->_get_defn($_->{type});
        my $fmt = $self->_get_cpy_format($type);
        if ($fmt eq 'O') {
            print $FH "\tPyObject * _",$_->{c_name},";\n";
        }
        if      ($_->{attr} eq "in") {
            if ($fmt eq 'O') {
                $args_in .= ', &_' . $_->{c_name};
            }
            else {
                $args_in .= ', &' . $_->{c_name};
            }
            push @fmt_in, $fmt;
        }
        elsif ($_->{attr} eq 'inout') {
            if ($fmt eq 'O') {
                $args_in .= ', &_' . $_->{c_name};
                $args_out .= ', _' . $_->{c_name};
            }
            else {
                $args_in .= ', &' . $_->{c_name};
                $args_out .= ', ' . $_->{c_name};
            }
            push @fmt_in, $fmt;
            push @fmt_out, $fmt;
        }
        elsif ($_->{attr} eq 'out') {
            if ($fmt eq 'O') {
                $args_out .= ', _' . $_->{c_name};
            }
            else {
                $args_out .= ', ' . $_->{c_name};
            }
            push @fmt_out, $fmt;
        }
    }
    print $FH "\n";
    if (scalar @fmt_in) {
        print $FH "\tif (!PyArg_ParseTuple(args, \"",@fmt_in,"\"",$args_in,"))\n";
        print $FH "\t\treturn NULL;\n";
        print $FH "\n";
    }
    foreach (@{$node->{list_param}}) {  # parameter
        next if ($_->{attr} eq 'out');
        my $type = $self->_get_defn($_->{type});
        my $fmt = $self->_get_cpy_format($type);
        if ($fmt eq 'O') {
            print $FH "\tPYOBJ_AS_",$type->{c_name},"(",$_->{c_name},", _",$_->{c_name},");\n";
        }
    }
    print $FH "\n";
    print $FH "#ifdef WITH_THREAD\n";
    print $FH "\t_gstate = PyGILState_Ensure();\n";
    print $FH "#endif\n";
    $type = $self->_get_defn($node->{type});
    if ($type->isa('VoidType')) {
        print $FH "\t",$self->{itf}->{c_name},"_",$node->{c_name},"(\n";
    }
    else {
        print $FH "\t",$self->_get_c_name_call($type, 'return'),"_ret = ";
            print $FH $self->{itf}->{c_name},"_",$node->{c_name},"(\n";
    }
    print $FH "\t\tNULL,\n";
    foreach (@{$node->{list_param}}) {
        my $type = $self->_get_defn($_->{type});
        print $FH "\t\t",$self->_get_c_name_call($type, $_->{attr}), $_->{c_name},",";
            print $FH " // ",$_->{attr}," (variable length)\n" if (defined $type->{length});
            print $FH " // ",$_->{attr}," (fixed length)\n" unless (defined $type->{length});
    }
    if (exists $node->{list_context}) {
        print $FH "\t\tCORBA_Context _ctx,\n";
    }
    print $FH "\t\t&_ev\n";
    print $FH "\t);\n";
    print $FH "#ifdef WITH_THREAD\n";
    print $FH "\tPyGILState_Release(_gstate);\n";
    print $FH "#endif\n";
    print $FH "\n";
    if (exists $node->{modifier}) {     # oneway
        print $FH "\tPy_RETURN_NONE;\n";
    }
    else {
        print $FH "\tif (CORBA_NO_EXCEPTION == _ev._major)\n";
        print $FH "\t{\n";
        unless ($type->isa('VoidType')) {
            my $fmt = $self->_get_cpy_format($type);
            if ($fmt eq 'O') {
                $self->_import_module($type);
                print $FH "\t\tPYOBJ_FROM_",$type->{c_name},"(__ret, ",$self->_get_c_ext_obj($type, 'return'),"_ret);\n";
            }
        }
        foreach (@{$node->{list_param}}) {  # parameter
            next if ($_->{attr} eq 'in');
            my $type = $self->_get_defn($_->{type});
            my $fmt = $self->_get_cpy_format($type);
            if ($fmt eq 'O') {
                $self->_import_module($type);
                print $FH "\t\tPYOBJ_FROM_",$type->{c_name},"(_",$_->{c_name},", ",$self->_get_c_ext_obj($type, $_->{attr}),$_->{c_name},");\n";
            }
        }
        print $FH "\t\t_result = Py_BuildValue(\"",@fmt_out,"\"",$args_out,"); // New reference\n";
        print $FH "\t}\n";
        print $FH "\telse if (CORBA_SYSTEM_EXCEPTION == _ev._major)\n";
        print $FH "\t{\n";
        print $FH "\t\tPyErr_SetString(PyExc_RuntimeError, CORBA_exception_id(&_ev));\n";
        print $FH "\t}\n";
        if (exists $node->{list_raise}) {
            print $FH "\telse if (CORBA_USER_EXCEPTION == _ev._major)\n";
            print $FH "\t{\n";
            my $condition = 'if ';
            foreach (@{$node->{list_raise}}) {
                my $defn = $self->_get_defn($_);
                $self->_import_module($defn);
                if ($nb_user_except > 1) {
                    print $FH "\t\t",$condition,"(0 == strcmp(ex_",$defn->{c_name},", CORBA_exception_id(&_ev)))\n";
                    print $FH "\t\t{\n";
                }
                print $FH "\t\t\tRAISE_",$defn->{c_name},"\n";
                $condition = 'else if ';
                if ($nb_user_except > 1) {
                    print $FH "\t\t}\n";
                }
            }
            print $FH "\t}\n";
        }
        if ($label_err) {
            print $FH "\n";
            print $FH "err:\n";
        }
        foreach (@{$node->{list_param}}) {  # parameter
            my $type = $self->_get_defn($_->{type});
            print $FH "\tFREE_",$_->{attr},"_",$type->{c_name},"(",$self->_get_c_free($type, $_->{attr}),$_->{c_name},");\n"
                    if (defined $type->{length});
        }
        unless ($type->isa("VoidType")) {
            print $FH "\tFREE_out_",$type->{c_name},"(",$self->_get_c_free($type, "out"),"_ret);\n"
                    if (defined $type->{length});
        }
        print $FH "\treturn _result;\n";
    }

    print $FH "}\n";
    print $FH "\n";
    if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}})) {
        $self->{methods} .= "\t{ \"" . $node->{py_name} . "\", (PyCFunction)" . $name . "_meth, METH_VARARGS, " . $name . "__doc__ },\n";
    }
    else {
        $self->{methods} .= "\t{ \"" . $node->{py_name} . "\", (PyCFunction)" . $name . "_meth, METH_NOARGS, " . $name . "__doc__ },\n";
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

