
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::XS::CdrCVisitor;

use strict;
use warnings;

our $VERSION = '0.60';

# needs $node->{c_name} (CnameVisitor), $node->{c_literal} (CliteralVisitor)

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

#
#   3.5     OMG IDL Specification       (specialized)
#

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
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "\n";
    print $FH "/*\n";
    print $FH " * end of module ",$defn->{c_name},"\n";
    print $FH " */\n";
    print $FH "\n";
}

#
#   3.8     Interface Declaration       (specialized)
#

sub visitForwardRegularInterface {
    # empty
}

sub visitBaseInterface {
    # C mapping is aligned with CORBA 2.1
}

sub visitForwardBaseInterface {
    # C mapping is aligned with CORBA 2.1
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
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    my $FH = $self->{out};
    if (exists $node->{array_size}) {
        warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
                unless (@{$node->{array_size}});

        my $start = q{};
        my $nb;
        my $first = 1;
        foreach (@{$node->{array_size}}) {
            $start .= '[0]';
            $nb .= ' * ' unless ($first);
            $nb .= $_->{c_literal};
            $first = 0;
        }
        print $FH "#define ADD_SIZE_",$node->{c_name},"(size,v) {\\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
        print $FH "\t\tfor (",$node->{c_name},"_ptr = &(v)" . $start . ";\\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr < &(v)" . $start . " + (",$nb,");\\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
        print $FH "\t\t\tADD_SIZE_",$type->{c_name},"(size,*",$node->{c_name},"_ptr);\\\n";
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
        print $FH "#define PUT_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
        print $FH "\t\tfor (",$node->{c_name},"_ptr = &(v)" . $start . ";\\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr < &(v)" . $start . " + (",$nb,");\\\n";
        print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
        print $FH "\t\t\tPUT_",$type->{c_name},"(ptr,*",$node->{c_name},"_ptr);\\\n";
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
        if (defined $node->{length}) {
            if (exists $self->{client}) {
                print $FH "#define GET_inout_",$node->{c_name},"(ptr,v) {\\\n";
                print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
                print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
                print $FH "\t\t\tGET_inout_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
                print $FH "\t\t}\\\n";
                print $FH "\t}\n";
                print $FH "#define GET_out_",$node->{c_name},"(ptr,v) {\\\n";
                print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
                print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
                print $FH "\t\t\tGET_out_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
                print $FH "\t\t}\\\n";
                print $FH "\t}\n";
                print $FH "#define ALLOC_GET_out_",$node->{c_name},"(ptr,v) {\\\n";
                print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
                print $FH "\t\tptr = ",$type->{c_name},"__alloc(",$nb,");\\\n";
                print $FH "\t\tif (NULL == ptr) goto err;\\\n";
                print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
                print $FH "\t\t\tGET_out_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
                print $FH "\t\t}\\\n";
                print $FH "\t}\n";
            }
            else {
                print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
                print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
                print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
                print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
                print $FH "\t\t\tGET_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
                print $FH "\t\t}\\\n";
                print $FH "\t}\n";
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
        else {
            print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
            print $FH "\t\tfor (",$node->{c_name},"_ptr = &(*(v))" . $start . ";\\\n";
            print $FH "\t\t     ",$node->{c_name},"_ptr < &(*(v))" . $start . " + (",$nb,");\\\n";
            print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
            print $FH "\t\t\tGET_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
            if (exists $self->{client}) {
                print $FH "#define GET_inout_",$node->{c_name}," GET_",$node->{c_name},"\n";
                print $FH "#define GET_out_",$node->{c_name}," GET_",$node->{c_name},"\n";
            }
        }
    }
    else {
        print $FH "#define ADD_SIZE_",$node->{c_name}," ADD_SIZE_",$type->{c_name},"\n";
        print $FH "#define PUT_",$node->{c_name}," PUT_",$type->{c_name},"\n";
        print $FH "#define GET_",$node->{c_name}," GET_",$type->{c_name},"\n";
        if (defined $node->{length}) {
            if (exists $self->{client}) {
                print $FH "#define GET_inout_",$node->{c_name}," GET_inout_",$type->{c_name},"\n";
                print $FH "#define GET_out_",$node->{c_name}," GET_out_",$type->{c_name},"\n";
                print $FH "#define ALLOC_GET_out_",$node->{c_name}," ALLOC_GET_out_",$type->{c_name},"\n";
            }
            else {
                print $FH "#define FREE_in_",$node->{c_name}," FREE_in_",$type->{c_name},"\n";
                print $FH "#define FREE_inout_",$node->{c_name}," FREE_inout_",$type->{c_name},"\n";
            }
            print $FH "#define FREE_out_",$node->{c_name}," FREE_out_",$type->{c_name},"\n";
            print $FH "#define FREE_",$node->{c_name}," FREE_",$type->{c_name},"\n";
        }
        else {
            if (exists $self->{client}) {
                print $FH "#define GET_inout_",$node->{c_name}," GET_",$node->{c_name},"\n";
                print $FH "#define GET_out_",$node->{c_name}," GET_",$node->{c_name},"\n";
            }
        }
    }
    print $FH "\n";
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
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    $self->{add_size} = q{};
    $self->{put} = q{};
    $self->{get} = q{};
    $self->{get_in} = q{};
    $self->{get_inout} = q{};
    $self->{get_out} = q{};
    $self->{free} = q{};
    $self->{union} = q{};
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
    my $FH = $self->{out};
    print $FH "#define ADD_SIZE_",$node->{c_name},"(size,v) {\\\n";
    print $FH $self->{add_size};
    print $FH "\t}\n";
    print $FH "#define PUT_",$node->{c_name},"(ptr,v) {\\\n";
    print $FH $self->{put};
    print $FH "\t}\n";
    if (defined $node->{length}) {
        if (exists $self->{client}) {
            print $FH "#define GET_inout_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH $self->{get_inout};
            print $FH "\t}\n";
            print $FH "#define GET_out_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH $self->{get_out};
            print $FH "\t}\n";
            print $FH "#define ALLOC_GET_out_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH "\t\tv = ",$node->{c_name},"__alloc(1);\\\n";
            print $FH "\t\tif (NULL == (v)) goto err;\\\n";
            print $FH $self->{get_out};
            print $FH "\t}\n";
        }
        else {
            print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH $self->{get};
            print $FH "\t}\n";
            print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
            print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        }
        print $FH "#define FREE_out_",$node->{c_name},"(v) {\\\n";
        print $FH "\t\tif (NULL != (v)) {\\\n";
        print $FH "\t\t\tFREE_",$node->{c_name},"(v);\\\n";
        print $FH "\t\t\tCORBA_free(v);\\\n";
        print $FH "\t}\\\n";
        print $FH "\t}\n";
        print $FH "#define FREE_",$node->{c_name},"(v) {\\\n";
        print $FH $self->{free};
        print $FH "\t}\n";
    }
    else {
        print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH $self->{get};
        print $FH "\t}\n";
        if (exists $self->{client}) {
            print $FH "#define GET_inout_",$node->{c_name}," GET_",$node->{c_name},"\n";
            print $FH "#define GET_out_",$node->{c_name}," GET_",$node->{c_name},"\n";
        }
    }
    print $FH "\n";
    delete $self->{add_size};
    delete $self->{put};
    delete $self->{get};
    delete $self->{get_in};
    delete $self->{get_inout};
    delete $self->{get_out};
    delete $self->{free};
    delete $self->{union};
}

sub visitMember {
    my $self = shift;
    my ($node) = @_;
    if (exists $node->{array_size}) {
        $self->_visitArray($node);
    }
    else {
        $self->_visitSingle($node);
    }
}

sub _visitArray {
    my $self = shift;
    my ($node) = @_;

    my $start = q{};
    my $nb;
    my $first = 1;
    foreach (@{$node->{array_size}}) {
        $start .= '[0]';
        $nb .= ' * ' unless ($first);
        $nb .= $_->{c_literal};
        $first = 0;
    }

    my $type = $self->_get_defn($node->{type});
    $self->{add_size}  .= "\t\t{\\\n";
    $self->{add_size}  .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
    $self->{add_size}  .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)." . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
    $self->{add_size}  .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)." . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
    $self->{add_size}  .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
    $self->{add_size}  .= "\t\t\t\tADD_SIZE_" . $type->{c_name} . "(size,*" . $node->{c_name} . "_ptr);\\\n";
    $self->{add_size}  .= "\t\t\t}\\\n";
    $self->{add_size}  .= "\t\t}\\\n";
    $self->{put}       .= "\t\t{\\\n";
    $self->{put}       .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
    $self->{put}       .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)." . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
    $self->{put}       .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)." . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
    $self->{put}       .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
    $self->{put}       .= "\t\t\t\tPUT_" . $type->{c_name} . "(ptr,*" . $node->{c_name} . "_ptr);\\\n";
    $self->{put}       .= "\t\t\t}\\\n";
    $self->{put}       .= "\t\t}\\\n";
    $self->{get}       .= "\t\t{\\\n";
    $self->{get}       .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
    $self->{get}       .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
    $self->{get}       .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
    $self->{get}       .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
    $self->{get}       .= "\t\t\t\tGET_" . $type->{c_name} . "(ptr," . $node->{c_name} . "_ptr);\\\n";
    $self->{get}       .= "\t\t\t}\\\n";
    $self->{get}       .= "\t\t}\\\n";
    $self->{get_in}    .= "\t\t{\\\n";
    $self->{get_in}    .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
    $self->{get_in}    .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
    $self->{get_in}    .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
    $self->{get_in}    .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
    $self->{get_in}    .= "\t\t\t\tGET_in_" . $type->{c_name} . "(ptr," . $node->{c_name} . "_ptr);\\\n";
    $self->{get_in}    .= "\t\t\t}\\\n";
    $self->{get_in}    .= "\t\t}\\\n";
    $self->{get_inout} .= "\t\t{\\\n";
    $self->{get_inout} .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
    $self->{get_inout} .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
    $self->{get_inout} .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
    $self->{get_inout} .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
    $self->{get_inout} .= "\t\t\t\tGET_inout_" . $type->{c_name} . "(ptr," . $node->{c_name} . "_ptr);\\\n";
    $self->{get_inout} .= "\t\t\t}\\\n";
    $self->{get_inout} .= "\t\t}\\\n";
    $self->{get_out}   .= "\t\t{\\\n";
    $self->{get_out}   .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
    $self->{get_out}   .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
    $self->{get_out}   .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
    $self->{get_out}   .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
    $self->{get_out}   .= "\t\t\t\tGET_" . $type->{c_name} . "(ptr," . $node->{c_name} . "_ptr);\\\n";
    $self->{get_out}   .= "\t\t\t}\\\n";
    $self->{get_out}   .= "\t\t}\\\n";
    if (defined $type->{length}) {
        $self->{free}      .= "\t\t{\\\n";
        $self->{free}      .= "\t\t\t" . $type->{c_name} . " * " . $node->{c_name} . "_ptr;\\\n";
        $self->{free}      .= "\t\t\tfor (" . $node->{c_name} . "_ptr = &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . ";\\\n";
        $self->{free}      .= "\t\t\t     " . $node->{c_name} . "_ptr < &((v)->" . $self->{union} . $node->{c_name} . ")" . $start . " + (" . $nb . ");\\\n";
        $self->{free}      .= "\t\t\t     " . $node->{c_name} . "_ptr++) {\\\n";
        $self->{free}      .= "\t\t\t\tFREE_" . $type->{c_name} . "(" . $node->{c_name} . "_ptr);\\\n";
        $self->{free}      .= "\t\t\t}\\\n";
        $self->{free}      .= "\t\t}\\\n";
    }
}

sub _visitSingle {
    my $self = shift;
    my ($node) = @_;
    my $tab = q{};
    $tab = "\t" if ($self->{union});
    my $type = $self->_get_defn($node->{type});
    $self->{add_size}  .= $tab . "\t\tADD_SIZE_" . $type->{c_name};
        $self->{add_size}  .= "(size,(v)." . $self->{union} . $node->{c_name} . ");\\\n";
    $self->{put}       .= $tab . "\t\tPUT_" . $type->{c_name};
        $self->{put}       .= "(ptr,(v)." . $self->{union} . $node->{c_name} . ");\\\n";
    $self->{get}       .= $tab . "\t\tGET_" . $type->{c_name};
        $self->{get}       .= "(ptr,&((v)->" . $self->{union} . $node->{c_name} . "));\\\n";
    $self->{get_in}    .= $tab . "\t\tGET_in_" . $type->{c_name};
        $self->{get_in}    .= "(ptr,&((v)->" . $self->{union} . $node->{c_name} . "));\\\n";
    $self->{get_inout} .= $tab . "\t\tGET_inout_" . $type->{c_name};
        $self->{get_inout} .= "(ptr,&((v)->" . $self->{union} . $node->{c_name} . "));\\\n";
    $self->{get_out}   .= $tab . "\t\tGET_out_" . $type->{c_name};
        $self->{get_out}   .= "(ptr,&((v)->" . $self->{union} . $node->{c_name} . "));\\\n";
    if (defined $type->{length}) {
        $self->{free}  .= $tab . "\t\tFREE_" . $type->{c_name};
            $self->{free}   .= "(&((v)->" . $self->{union} . $node->{c_name} . "));\\\n";
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
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    my $FH = $self->{out};
    $self->{add_size} = q{};
    $self->{put} = q{};
    $self->{get} = q{};
    $self->{get_in} = q{};
    $self->{get_inout} = q{};
    $self->{get_out} = q{};
    $self->{free} = q{};
    $self->{union} = '_u.';
    foreach (@{$node->{list_expr}}) {
        $_->visit($self);               # case
    }
    my $type = $self->_get_defn($node->{type});
    print $FH "#define ADD_SIZE_",$node->{c_name},"(size,v) {\\\n";
    print $FH "\t\tADD_SIZE_",$type->{c_name},"(size,(v)._d);\\\n";
    print $FH "\t\tswitch ((v)._d) {\\\n";
    print $FH $self->{add_size};
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    print $FH "#define PUT_",$node->{c_name},"(ptr,v) {\\\n";
    print $FH "\t\tPUT_",$type->{c_name},"(ptr,(v)._d);\\\n";
    print $FH "\t\tswitch ((v)._d) {\\\n";
    print $FH $self->{put};
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    if (defined $node->{length}) {
        if (exists $self->{client}) {
            print $FH "#define GET_inout_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH "\t\tGET_inout_",$type->{c_name},"(ptr,&((v)->_d));\\\n";
            print $FH "\t\tswitch ((v)->_d) {\\\n";
            print $FH $self->{get_inout};
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
            print $FH "#define GET_out_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH "\t\tGET_out_",$type->{c_name},"(ptr,&((v)->_d));\\\n";
            print $FH "\t\tswitch ((v)->_d) {\\\n";
            print $FH $self->{get_out};
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
            print $FH "#define ALLOC_GET_out_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH "\t\tv = ",$node->{c_name},"__alloc(1);\\\n";
            print $FH "\t\tif (NULL == (v)) goto err;\\\n";
            print $FH "\t\tGET_out_",$type->{c_name},"(ptr,&((v)->_d));\\\n";
            print $FH "\t\tswitch ((v)->_d) {\\\n";
            print $FH $self->{get_out};
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
        }
        else {
            print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH "\t\tGET_",$type->{c_name},"(ptr,&((v)->_d));\\\n";
            print $FH "\t\tswitch ((v)->_d) {\\\n";
            print $FH $self->{get};
            print $FH "\t\t}\\\n";
            print $FH "\t}\n";
            print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
            print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        }
        print $FH "#define FREE_out_",$node->{c_name},"(v) {\\\n";
        print $FH "\t\tif (NULL != (v)) {\\\n";
        print $FH "\t\t\tFREE_",$node->{c_name},"(v);\\\n";
        print $FH "\t\t\tCORBA_free(v);\\\n";
        print $FH "\t}\n";
        print $FH "#define FREE_",$node->{c_name},"(v) {\\\n";
        print $FH "\t\tswitch ((v)->_d) {\\\n";
        print $FH $self->{free};
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
    }
    else {
        print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH "\t\tGET_",$type->{c_name},"(ptr,&((v)->_d));\\\n";
        print $FH "\t\tswitch ((v)->_d) {\\\n";
        print $FH $self->{get};
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
        if (exists $self->{client}) {
            print $FH "#define GET_inout_",$node->{c_name}," GET_",$node->{c_name},"\n";
            print $FH "#define GET_out_",$node->{c_name}," GET_",$node->{c_name},"\n";
        }
    }
    print $FH "\n";
    delete $self->{add_size};
    delete $self->{put};
    delete $self->{get};
    delete $self->{get_in};
    delete $self->{get_inout};
    delete $self->{get_out};
    delete $self->{free};
    delete $self->{union};
}

sub visitCase {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    foreach (@{$node->{list_label}}) {  # default or expression
        if ($_->isa('Default')) {
            $self->{add_size}  .= "\t\tdefault:\\\n";
            $self->{put}       .= "\t\tdefault:\\\n";
            $self->{get}       .= "\t\tdefault:\\\n";
            $self->{get_in}    .= "\t\tdefault:\\\n";
            $self->{get_inout} .= "\t\tdefault:\\\n";
            $self->{get_out}   .= "\t\tdefault:\\\n";
            $self->{free}      .= "\t\tdefault:\\\n";
        }
        else {
            $self->{add_size}  .= "\t\tcase " . $_->{c_literal} . ":\\\n";
            $self->{put}       .= "\t\tcase " . $_->{c_literal} . ":\\\n";
            $self->{get}       .= "\t\tcase " . $_->{c_literal} . ":\\\n";
            $self->{get_in}    .= "\t\tcase " . $_->{c_literal} . ":\\\n";
            $self->{get_inout} .= "\t\tcase " . $_->{c_literal} . ":\\\n";
            $self->{get_out}   .= "\t\tcase " . $_->{c_literal} . ":\\\n";
            $self->{free}      .= "\t\tcase " . $_->{c_literal} . ":\\\n";
        }
    }
    $self->_get_defn($node->{element}->{value})->visit($self);      # member
    $self->{add_size}  .= "\t\tbreak;\\\n";
    $self->{put}       .= "\t\tbreak;\\\n";
    $self->{get}       .= "\t\tbreak;\\\n";
    $self->{get_in}    .= "\t\tbreak;\\\n";
    $self->{get_inout} .= "\t\tbreak;\\\n";
    $self->{get_out}   .= "\t\tbreak;\\\n";
    $self->{free}      .= "\t\tbreak;\\\n";
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
    return if (exists $self->{done_hash}->{$node->{c_name}});
    $self->{done_hash}->{$node->{c_name}} = 1;
    my $FH = $self->{out};
    print $FH "#define ADD_SIZE_",$node->{c_name}," ADD_SIZE_CORBA_unsigned_long\n";
    print $FH "#define PUT_",$node->{c_name}," PUT_CORBA_unsigned_long\n";
    print $FH "#define GET_",$node->{c_name}," GET_CORBA_unsigned_long\n";
    if (exists $self->{client}) {
        print $FH "#define GET_inout_",$node->{c_name}," GET_",$node->{c_name},"\n";
        print $FH "#define GET_out_",$node->{c_name}," GET_",$node->{c_name},"\n";
    }
    print $FH "\n";
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    my $type = $self->_get_defn($node->{type});
    if (       $type->isa('SequenceType')
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    my $FH = $self->{out};
    print $FH "#ifndef _ALIGN_",$node->{c_name},"_defined\n";
    print $FH "#define _ALIGN_",$node->{c_name},"_defined\n";
    print $FH "#define ADD_SIZE_",$node->{c_name},"(size,v) {\\\n";
    print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
    print $FH "\t\tADD_SIZE_CORBA_unsigned_long(size,(v)._length);\\\n";
    print $FH "\t\tfor (",$node->{c_name},"_ptr = (v)._buffer;\\\n";
    print $FH "\t\t     ",$node->{c_name},"_ptr < (v)._buffer + (v)._length;\\\n";
    print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
    print $FH "\t\t\tADD_SIZE_",$type->{c_name},"(size,*",$node->{c_name},"_ptr);\\\n";
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    print $FH "#define PUT_",$node->{c_name},"(ptr,v) {\\\n";
    print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
    print $FH "\t\tPUT_CORBA_unsigned_long(ptr,(v)._length);\\\n";
    print $FH "\t\tfor (",$node->{c_name},"_ptr = (v)._buffer;\\\n";
    print $FH "\t\t     ",$node->{c_name},"_ptr < (v)._buffer + (v)._length;\\\n";
    print $FH "\t\t     ",$node->{c_name},"_ptr++) {\\\n";
    print $FH "\t\t\tPUT_",$type->{c_name},"(ptr,*",$node->{c_name},"_ptr);\\\n";
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    my $nb = "(v)->_length";
    if (exists $self->{client}) {
        $nb = $node->{max}->{c_literal} if (exists $node->{max});
        print $FH "#define GET_inout_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
        print $FH "\t\tGET_CORBA_unsigned_long(ptr,&((v)->_length));\\\n";
        print $FH "\t\tif (NULL != (v)->_buffer) CORBA_free((v)->_buffer);\\\n";
        print $FH "\t\tif (0 != ",$nb,") {\\\n";
        print $FH "\t\t\t(v)->_buffer = ",$node->{c_name},"__allocbuf(",$nb,");\\\n";
        print $FH "\t\t\tif (NULL == (v)->_buffer) goto err;\\\n";
        print $FH "\t\t\tfor (",$node->{c_name},"_ptr = (v)->_buffer;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr < (v)->_buffer + (v)->_length;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr++) {\\\n";
        print $FH "\t\t\t\tGET_inout_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
        print $FH "\t\t\t}\\\n";
        print $FH "\t\t} else {\\\n";
        print $FH "\t\t\t(v)->_buffer = NULL;\\\n";
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
        print $FH "#define GET_out_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
        print $FH "\t\tGET_CORBA_unsigned_long(ptr,&((v)->_length));\\\n";
        print $FH "\t\tif (0 != ",$nb,") {\\\n";
        print $FH "\t\t\t(v)->_buffer = ",$node->{c_name},"__allocbuf(",$nb,");\\\n";
        print $FH "\t\t\tif (NULL == (v)->_buffer) goto err;\\\n";
        print $FH "\t\t\tfor (",$node->{c_name},"_ptr = (v)->_buffer;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr < (v)->_buffer + (v)->_length;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr++) {\\\n";
        print $FH "\t\t\t\tGET_out_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
        print $FH "\t\t\t}\\\n";
        print $FH "\t\t} else {\\\n";
        print $FH "\t\t\t(v)->_buffer = NULL;\\\n";
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
        print $FH "#define ALLOC_GET_out_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH "\t\tv = ",$node->{c_name},"__alloc(1);\\\n";
        print $FH "\t\tif (NULL == (v)) goto err;\\\n";
        print $FH "\t\tGET_out_",$node->{c_name},"(ptr, v);\\\n";
        print $FH "\t}\n";
    }
    else {
        print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH "\t\t",$type->{c_name}," * ",$node->{c_name},"_ptr;\\\n";
        print $FH "\t\tGET_CORBA_unsigned_long(ptr,&((v)->_length));\\\n";
        print $FH "\t\tif (0 != (v)->_length) {\\\n";
        print $FH "\t\t\t(v)->_buffer = ",$node->{c_name},"__allocbuf(",$nb,");\\\n";
        print $FH "\t\t\tif (NULL == (v)->_buffer) goto err;\\\n";
        print $FH "\t\t\tfor (",$node->{c_name},"_ptr = (v)->_buffer;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr < (v)->_buffer + (v)->_length;\\\n";
        print $FH "\t\t\t     ",$node->{c_name},"_ptr++) {\\\n";
        print $FH "\t\t\t\tGET_",$type->{c_name},"(ptr,",$node->{c_name},"_ptr);\\\n";
        print $FH "\t\t\t}\\\n";
        print $FH "\t\t} else {\\\n";
        print $FH "\t\t\t(v)->_buffer = NULL;\\\n";
        print $FH "\t\t}\\\n";
        print $FH "\t}\n";
        print $FH "#define FREE_in_",$node->{c_name}," FREE_",$node->{c_name},"\n";
        print $FH "#define FREE_inout_",$node->{c_name}," FREE_",$node->{c_name},"\n";
    }
    print $FH "#define FREE_out_",$node->{c_name},"(v) {\\\n";
    print $FH "\t\tif (NULL != (v)) {\\\n";
    print $FH "\t\t\tFREE_",$node->{c_name},"(v);\\\n";
    print $FH "\t\t\tCORBA_free(v);\\\n";
    print $FH "\t\t}\\\n";
    print $FH "\t}\n";
    print $FH "#define FREE_",$node->{c_name},"(v) {\\\n";
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
    if (exists $self->{client}) {
        print $FH "\t\tCORBA_free(v);\\\n";
    }
    print $FH "\t}\n";
    print $FH "#endif\n";
    print $FH "\n";
}

sub visitFixedPtType {
    my $self = shift;
    my ($node) = @_;
    warn __PACKAGE__,"::visitFixedPtType : TODO.\n";
}

sub visitFixedPtConstType {
    my $self = shift;
    my ($node) = @_;
    warn __PACKAGE__,"::visitFixedPtConstType : TODO.\n";
}

#
#   3.12    Exception Declaration
#

sub visitException {
    my $self = shift;
    my ($node) = @_;
    return unless (exists $node->{list_expr});
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('SequenceType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    $self->{add_size} = q{};
    $self->{put} = q{};
    $self->{get} = q{};
    $self->{get_in} = q{};
    $self->{get_inout} = q{};
    $self->{get_out} = q{};
    $self->{free} = q{};
    $self->{union} = q{};
    foreach (@{$node->{list_member}}) {
        $self->_get_defn($_)->visit($self);     # member
    }
    my $FH = $self->{out};
    if (exists $self->{client}) {
        if (defined $node->{length}) {
            print $FH "#define GET_out_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH $self->{get_out};
            print $FH "\t}\n";
            print $FH "#define FREE_",$node->{c_name},"(v) {\\\n";
            print $FH $self->{free};
            print $FH "\t\tCORBA_free(v);\\\n";
            print $FH "\t}\n";
        }
        else {
            print $FH "#define GET_",$node->{c_name},"(ptr,v) {\\\n";
            print $FH $self->{get};
            print $FH "\t}\n";
        }
    }
    else {
        print $FH "#define ADD_SIZE_",$node->{c_name},"(size,v) {\\\n";
        print $FH $self->{add_size};
        print $FH "\t}\n";
        print $FH "#define PUT_",$node->{c_name},"(ptr,v) {\\\n";
        print $FH $self->{put};
        print $FH "\t}\n";
    }
    print $FH "\n";
    delete $self->{add_size};
    delete $self->{put};
    delete $self->{get};
    delete $self->{get_in};
    delete $self->{get_inout};
    delete $self->{get_out};
    delete $self->{free};
    delete $self->{union};
}

#
#   3.13    Operation Declaration       (specialized)
#

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

1;

