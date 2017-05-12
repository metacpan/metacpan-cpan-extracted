
package CORBA::XPIDL::HeaderVisitor;

use strict;
use warnings;

our $VERSION = '0.21';

use File::Basename;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $base_includes) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{base_includes} = $base_includes;
    my $filename;
    if ($parser->YYData->{opt_e}) {
        $filename = $parser->YYData->{opt_e};
    }
    else {
        if ($parser->YYData->{opt_o}) {
            $filename = $parser->YYData->{opt_o} . '.h';
        }
        else {
            $filename = basename($self->{srcname}, '.idl') . '.h';
        }
    }
    $self->open_stream($filename);
    $self->{num_key} = 'num_header_xp';
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
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

sub _is_dipper {
    my $self = shift;
    my ($node) = @_;    # type
    return     $node->hasProperty('domstring')
            || $node->hasProperty('utf8string')
            || $node->hasProperty('cstring')
            || $node->hasProperty('astring');
}

sub _classname_iid {
    my $self = shift;
    my ($node) = @_;
    my $idf = $node->{idf};
    $idf =~ s/^ns/NS_/;     # backcompat naming styles
    my $classname = uc $idf;
    $classname .= '_IID';
    return $classname;
}

sub _doc_comments {
    my $self = shift;
    my ($node) = @_;
    return q{} unless ($node->{doc});
    my $FH = $self->{out};
    my @doc = split /\n/, $node->{doc};
    shift @doc if ($doc[0] =~ /^\s*$/);
    pop @doc if ($doc[-1] =~ /^\s*$/);
    print $FH "/**\n";
    foreach (@doc) {
        print $FH " *",$_,"\n";
    }
    print $FH " */\n";
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};

    my $basename = basename($self->{srcname}, '.idl');
    print $FH "/*\n";
    print $FH " * DO NOT EDIT.  THIS FILE IS GENERATED FROM ",$self->{srcname},"\n";
    print $FH " */\n";
    print $FH "\n";
    print $FH "#ifndef __gen_",$basename,"_h__\n";
    print $FH "#define __gen_",$basename,"_h__\n";

    if (scalar @{$self->{base_includes}}) {
        print $FH "\n";
        foreach (@{$self->{base_includes}}) {
            my $basename = basename($_, '.idl') ;
            print $FH "\n";
            print $FH "#ifndef __gen_",$basename,"_h__\n";
            print $FH "#include \"",$basename,".h\"\n";
            print $FH "#endif\n";
        }
        print $FH "\n";
    }
    if (exists $node->{list_import}) {
        print $FH "\n";
        foreach (@{$node->{list_import}}) {
            my $basename = $_->{value};
            $basename =~ s/^:://;
            $basename =~ s/::/_/g;
            print $FH "\n";
            print $FH "#ifndef __gen_",$basename,"_h__\n";
            print $FH "#include \"",$basename,".h\"\n";
            print $FH "#endif\n";
        }
        print $FH "\n";
    }
    # Support IDL files that don't include a root IDL file that defines
    # NS_NO_VTABLE.
    print $FH "/* For IDL files that don't want to include root IDL files. */\n";
    print $FH "#ifndef NS_NO_VTABLE\n";
    print $FH "#define NS_NO_VTABLE\n";
    print $FH "#endif\n";

    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }

    print $FH "\n";
    print $FH "#endif /* __gen_",$basename,"_h__ */\n";
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
    if ($self->{srcname} eq $node->{filename}) {
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
    }
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $classname = $node->{idf};
        my $indent = q{ } x 2;
        print $FH "\n";
        print $FH "/* starting interface:    ",$classname," */\n";
        my $name_space = $node->getProperty('namespace');
        if (defined $name_space) {
            print $FH "/* namespace:             ",$name_space," */\n";
            print $FH "/* fully qualified name:  ",$name_space,".",$classname," */\n";
        }
        my $iid = lc $node->getProperty('uuid');
        my $classname_iid = $self->_classname_iid($node);
        print $FH "#define ",$classname_iid,"_STR \"",$iid,"\"\n";
        print $FH "\n";
        print $FH "#define ",$classname_iid," \\\n";
        print $FH "  {0x",substr($iid,0,8),", 0x",substr($iid,9,4),", ";
        print $FH "0x",substr($iid,14,4),", \\\n";
        print $FH "    { 0x",substr($iid,19,2),", 0x",substr($iid,21,2),", ";
        print $FH "0x",substr($iid,24,2),", 0x",substr($iid,26,2),", ";
        print $FH "0x",substr($iid,28,2),", 0x",substr($iid,30,2),", ";
        print $FH "0x",substr($iid,32,2),", 0x",substr($iid,34,2)," }}\n";
        print $FH "\n";

        $self->_doc_comments($node) if (exists $node->{doc});

        # NS_NO_VTABLE is defined in nsISupportsUtils.h, and defined on windows
        # to __declspec(novtable) on windows.  This optimization is safe
        # whenever the constructor calls no virtual methods.  Writing in IDL
        # almost guarantees this, except for the case when a %{C++ block occurs in
        # the interface.  We detect that case, and emit a macro call that disables
        # the optimization.
        my $keepvtable;
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            $keepvtable = 1 if ($defn->isa('CodeFragment'));
        }

        # The interface declaration itself.
        print $FH "class ",($keepvtable ? q{} : "NS_NO_VTABLE "),$classname;
        if (exists $node->{inheritance}) {
            print $FH " : ";
            my $base = $self->_get_defn(${$node->{inheritance}->{list_interface}}[0]);
            print $FH "public ",$base->{idf};
        }
        print $FH " {\n";
        print $FH " public: \n";
        print $FH "\n";
        print $FH "  NS_DEFINE_STATIC_IID_ACCESSOR(",$classname_iid,")\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
        print $FH "};\n";
        print $FH "\n";

        my @attribute_operation = ();
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            if    ($defn->isa('Operation')) {
                push @attribute_operation, $defn;
            }
            elsif ($defn->isa('Attributes')) {
                foreach (@{$defn->{list_decl}}) {
                    my $defn = $self->_get_defn($_);
                    push @attribute_operation, $defn;
                }
            }
        }
        # #define NS_DECL_NSIFOO - create method prototypes that can be used in
        # class definitions that support this interface.
        #
        # Walk the tree explicitly to prototype a reworking of xpidl to get rid of
        # the callback mechanism.
        print $FH "/* Use this macro when declaring classes that implement this interface. */\n";
        print $FH "#define NS_DECL_",uc($classname)," \\\n";
        if (scalar @attribute_operation) {
            my $first = 1;
            foreach my $defn (@attribute_operation) {
                print $FH "; \\\n" unless ($first);
                if ($defn->isa('Operation')) {
                    print $FH $indent;
                    $self->_method($defn, 'AS_DECL', q{});
                }
                else {
                    print $FH $indent;
                    $self->_attr_getter($defn, 'AS_DECL', q{});
                    unless (exists $defn->{modifier}) { # readonly
                        print $FH "; \\\n";
                        print $FH $indent;
                        $self->_attr_setter($defn, 'AS_DECL', q{});
                    }
                }
                $first = 0;
            }
            print $FH ";\n";
        }
        else {
            print $FH "/* no methods! */\n";
        }
        print $FH "\n";

        # XXX abstract above and below into one function?
        #
        # #define NS_FORWARD_NSIFOO - create forwarding methods that can delegate
        # behavior from in implementation to another object.  As generated by
        # idlc.
        print $FH "/* Use this macro to declare functions that forward the behavior of this interface to another object. */\n";
        print $FH "#define NS_FORWARD_",uc($classname),"(_to) \\\n";
        if (scalar @attribute_operation) {
            my $first = 1;
            foreach my $defn (@attribute_operation) {
                print $FH "; } \\\n" unless ($first);
                if ($defn->isa('Operation')) {
                    print $FH $indent;
                    $self->_method($defn, 'AS_DECL', q{});
                    print $FH " { return _to ";
                    $self->_method($defn, 'AS_CALL', q{});
                }
                else {
                    print $FH $indent;
                    $self->_attr_getter($defn, 'AS_DECL', q{});
                    print $FH " { return _to ";
                    $self->_attr_getter($defn, 'AS_CALL', q{});
                    unless (exists $defn->{modifier}) { # readonly
                        print $FH "; } \\\n";
                        print $FH $indent;
                        $self->_attr_setter($defn, 'AS_DECL', q{});
                        print $FH " { return _to ";
                        $self->_attr_setter($defn, 'AS_CALL', q{});
                    }
                }
                $first = 0;
            }
            print $FH "; }\n";
        }
        else {
            print $FH "/* no methods! */\n";
        }
        print $FH "\n";

        # XXX abstract above and below into one function?
        #
        # #define NS_FORWARD_SAFE_NSIFOO - create forwarding methods that can delegate
        # behavior from in implementation to another object.  As generated by
        # idlc.
        print $FH "/* Use this macro to declare functions that forward the behavior of this interface to another object in a safe way. */\n";
        print $FH "#define NS_FORWARD_SAFE_",uc($classname),"(_to) \\\n";
        if (scalar @attribute_operation) {
            my $first = 1;
            foreach my $defn (@attribute_operation) {
                print $FH "; } \\\n" unless ($first);
                if ($defn->isa('Operation')) {
                    print $FH $indent;
                    $self->_method($defn, 'AS_DECL', q{});
                    print $FH " { return !_to ? NS_ERROR_NULL_POINTER : _to->";
                    $self->_method($defn, 'AS_CALL', q{});
                }
                else {
                    print $FH $indent;
                    $self->_attr_getter($defn, 'AS_DECL', q{});
                    print $FH " { return !_to ? NS_ERROR_NULL_POINTER : _to->";
                    $self->_attr_getter($defn, 'AS_CALL', q{});
                    unless (exists $defn->{modifier}) { # readonly
                        print $FH "; } \\\n";
                        print $FH $indent;
                        $self->_attr_setter($defn, 'AS_DECL', q{});
                        print $FH " { return !_to ? NS_ERROR_NULL_POINTER : _to->";
                        $self->_attr_setter($defn, 'AS_CALL', q{});
                    }
                }
                $first = 0;
            }
            print $FH "; }\n";
        }
        else {
            print $FH "/* no methods! */\n";
        }
        print $FH "\n";

        # Build a sample implementation template.
        my $classNameImpl;
        if ($classname =~ /^..I/) {
            $classNameImpl = substr($classname, 0, 2) . substr($classname, 3);
        }
        else {
            $classNameImpl = '_MYCLASS_';
        }
        print $FH "#if 0\n";
        print $FH "/* Use the code below as a template for the implementation class for this interface. */\n";
        print $FH "\n";
        print $FH "/* Header file */\n";
        print $FH "class ",$classNameImpl," : public ",$classname,"\n";
        print $FH "{\n";
        print $FH "public:\n";
        print $FH $indent,"NS_DECL_ISUPPORTS\n";
        print $FH $indent,"NS_DECL_",uc($classname),"\n";
        print $FH "\n";
        print $FH $indent,$classNameImpl,"();\n";
        print $FH $indent,"virtual ~",$classNameImpl,"();\n";
        print $FH $indent,"/* additional members */\n";
        print $FH "};\n";
        print $FH "\n";
        print $FH "/* Implementation file */\n";
        print $FH "NS_IMPL_ISUPPORTS1(",$classNameImpl,", ",$classname,")\n";
        print $FH "\n";
        print $FH $classNameImpl,"::",$classNameImpl,"()\n";
        print $FH "{\n";
        print $FH $indent,"/* member initializers and constructor code */\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH $classNameImpl,"::~",$classNameImpl,"()\n";
        print $FH "{\n";
        print $FH $indent,"/* destructor code */\n";
        print $FH "}\n";
        print $FH "\n";
        foreach my $defn (@attribute_operation) {
            if ($defn->isa('Operation')) {
                $self->_doc_comments($defn);
                $self->_method($defn, 'AS_IMPL', $classNameImpl);
                print $FH "\n";
                print $FH "{\n";
                print $FH $indent,$indent,"return NS_ERROR_NOT_IMPLEMENTED;\n";
                print $FH "}\n";
                print $FH "\n";
            }
            else {
                $self->_doc_comments($defn);
                $self->_attr_getter($defn, 'AS_IMPL', $classNameImpl);
                print $FH "\n";
                print $FH "{\n";
                print $FH $indent,$indent,"return NS_ERROR_NOT_IMPLEMENTED;\n";
                print $FH "}\n";
                unless (exists $defn->{modifier}) { # readonly
                    $self->_attr_setter($defn, 'AS_IMPL', $classNameImpl);
                    print $FH "\n";
                    print $FH "{\n";
                    print $FH $indent,$indent,"return NS_ERROR_NOT_IMPLEMENTED;\n";
                    print $FH "}\n";
                }
                print $FH "\n";
            }
        }
        print $FH "/* End of implementation class template. */\n";
        print $FH "#endif\n";
        print $FH "\n";
    }
}

sub visitForwardRegularInterface {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        $self->_doc_comments($node);
        print $FH "class ",$node->{idf},"; /* forward declaration */\n";
        print $FH "\n";
    }
}

sub visitBaseInterface {
    # empty
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->_doc_comments($node);
    my $indent = q{ } x 2;
    my $value = $node->{value}->{value};
    my $type = $self->_get_defn($node->{type});
    while ($type->isa('TypeDeclarator')) {
        $type = $self->_get_defn($type->{type});
    }
    $value .= 'U' if (exists $type->{value} and $type->{value} =~ /^unsigned/);
    print $FH $indent,"enum { ",$node->{idf}," = ",$value," };\n";
    print $FH "\n";
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    return if ($type->isa('SequenceType'));

    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        $self->_doc_comments($node);
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
        print $FH "\n";
    }
}

sub visitTypeDeclarator {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    print $FH "typedef ",$type->{xp_name}," ",$node->{idf};
    if (exists $node->{array_size}) {   # usefull ?
        foreach (@{$node->{array_size}}) {
            print $FH "[",$_->{value},"]";
        }
    }
    print $FH ";\n";
}

sub visitNativeType {
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
    $self->_doc_comments($node);
    my $indent = q{ } x 2;
    print $FH $indent;
    $self->_method($node, 'AS_DECL', q{});
    print $FH " = 0;\n";
    print $FH "\n";
}

# Shared between the interface class declaration and the NS_DECL_IFOO macro
# provided to aid declaration of implementation classes.
# mode...
#  AS_DECL writes 'NS_IMETHOD foo(string bar, long sil)'
#  AS_IMPL writes 'NS_IMETHODIMP className::foo(string bar, long sil)'
#  AS_CALL writes 'foo(bar, sil)'
sub _method {
    my $self = shift;
    my ($node, $mode, $className) = @_;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    my $op_notxpcom = $node->hasProperty('notxpcom');

    if     ($mode eq 'AS_DECL') {
        if ($op_notxpcom) {
            print $FH "NS_IMETHOD_(",$type->{xp_name},")";
        }
        else {
            print $FH 'NS_IMETHOD';
        }
        print $FH " ";
    }
    elsif ($mode eq 'AS_IMPL') {
        if ($op_notxpcom) {
            print $FH "NS_IMETHODIMP_(",$type->{xp_name},")";
        }
        else {
            print $FH "NS_IMETHODIMP";
        }
        print $FH " ";
    }

    if ($mode eq 'AS_IMPL') {
        print $FH $className,"::",ucfirst($node->{idf}),"(";
    }
    else {
        print $FH ucfirst($node->{idf}),"(";
    }

    my $first = 1;
    foreach (@{$node->{list_param}}) {
        next if ($_->isa('Ellipsis'));
        print $FH ", " unless ($first);
        if ($mode eq 'AS_DECL' or $mode eq 'AS_IMPL') {
            $self->_param($_);
        }
        else {
            print $FH $_->{idf};
        }
        $first = 0;
    }

    # make IDL return value into trailing out argument
    if ( !$type->isa('VoidType') and !$op_notxpcom ) {
        my $fake_param = _Build CORBA::IDL::Node (
                'attr'  => 'out',
                'type'  => $type,
                'idf'   => '_retval',
        );
        bless $fake_param, 'CORBA::IDL::Parameter';
        print $FH ", " unless ($first);
        if ($mode eq 'AS_DECL' or $mode eq 'AS_IMPL') {
            $self->_param($fake_param);
        }
        else {
            print $FH "_retval";
        }
        $first = 0;
    }

    # varargs go last
    if (        scalar @{$node->{list_param}}
            and ${$node->{list_param}}[-1]->isa('Ellipsis') ) {
        print $FH ", " unless ($first);
        if ($mode eq 'AS_DECL' or $mode eq 'AS_IMPL') {
            print $FH "nsVarArgs *";
        }
        print $FH "_varargs";
        $first = 0;
    }

    # If generated method has no arguments, output 'void' to avoid C legacy
    # behavior of disabling type checking.
    if ($first and $mode eq 'AS_DECL') {
        print $FH "void";
    }

    print $FH ")";
}

# param generation:
# in string foo        -->     nsString *foo
# out string foo       -->     nsString **foo;
# inout string foo     -->     nsString **foo;
sub _param {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});

    # in string, wstring, nsid, domstring, utf8string, cstring and
    # astring any explicitly marked [const] are const
    if (        $node->{attr} eq 'in'
            and (  $type->isa('StringType')
                or $type->isa('WideStringType')
                or $node->hasProperty('const')
                or $type->hasProperty('nsid')
                or $type->hasProperty('domstring')
                or $type->hasProperty('utf8string')
                or $type->hasProperty('cstring')
                or $type->hasProperty('astring') ) ) {
        print $FH "const ";
    }
    elsif (   $node->{attr} eq 'out'
            and $node->hasProperty('shared') ) {
        print $FH "const ";
    }

    print $FH $type->{xp_name};

    # unless the type ended in a *, add a space
    unless (   $type->isa('StringType')
            or $type->isa('WideStringType')
            or $type->isa('Interface')
            or $type->isa('ForwardInterface') ) {
        print $FH " ";
    }

    # out and inout params get a bonus '*' (unless this is type that has a
    # 'dipper' class that is passed in to receive 'out' data)
    if (        $node->{attr} ne 'in'
            and !$self->_is_dipper($type) ) {
        print $FH "*";
    }

    # arrays get a bonus * too
    # XXX Should this be a leading '*' or a trailing "[]" ?
    if ($node->hasProperty('array')) {
        print $FH "*";
    }

    print $FH $node->{idf};
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
    my $FH = $self->{out};
    $self->_doc_comments($node);
    my $indent = q{ } x 2;
    print $FH $indent;
    $self->_attr_getter($node, 'AS_DECL', q{});
    print $FH " = 0;\n";
    unless (exists $node->{modifier}) {     # readonly
        print $FH $indent;
        $self->_attr_setter($node, 'AS_DECL', q{});
        print $FH " = 0;\n";
    }
    print $FH "\n";
}

sub _attr_getter {
    my $self = shift;
    my ($node, $mode, $className) = @_;
    my $FH = $self->{out};
    if    ($mode eq 'AS_DECL') {
        print $FH "NS_IMETHOD ";
    }
    elsif ($mode eq 'AS_IMPL') {
        print $FH "NS_IMETHODIMP ",$className,"::";
    }
    print $FH "Get",ucfirst($node->{idf}),"(";
    if ($mode eq 'AS_DECL' or $mode eq 'AS_IMPL') {
        my $type = $self->_get_defn($node->{type});
        print $FH $type->{xp_name}," ";
        unless ($self->_is_dipper($type)) {
            print $FH "*";
        }
    }
    print $FH "a",ucfirst($node->{idf}),")";
}

sub _attr_setter {
    my $self = shift;
    my ($node, $mode, $className) = @_;
    my $FH = $self->{out};
    if    ($mode eq 'AS_DECL') {
        print $FH "NS_IMETHOD ";
    }
    elsif ($mode eq 'AS_IMPL') {
        print $FH "NS_IMETHODIMP ",$className,"::";
    }
    print $FH "Set",ucfirst($node->{idf}),"(";
    if ($mode eq 'AS_DECL' or $mode eq 'AS_IMPL') {
        my $type = $self->_get_defn($node->{type});
        # Setters for string, wstring, nsid, domstring, utf8string,
        # cstring and astring get const.
        if (       $type->isa('StringType')
                or $type->isa('WideStringType')
                or $type->hasProperty('nsid')
                or $type->hasProperty('domstring')
                or $type->hasProperty('utf8string')
                or $type->hasProperty('cstring')
                or $type->hasProperty('astring') ) {
            print $FH "const ";
        }
        print $FH $type->{xp_name}," ";
    }
    print $FH "a",ucfirst($node->{idf}),")";
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
    my $self = shift;
    my ($node) = @_;
    if ($self->{srcname} eq $node->{filename}) {
        my @code = split /\n/, $node->{value};
        shift @code;
        my $FH = $self->{out};
        foreach (@code) {
            print $FH $_,"\n";
        }
    }
}

1;

