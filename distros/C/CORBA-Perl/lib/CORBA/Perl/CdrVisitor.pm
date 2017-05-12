
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Perl::CdrVisitor;

use strict;
use warnings;

our $VERSION = '0.43';

use File::Basename;
use POSIX qw(ctime);

# needs $node->{pl_name} $node->{pl_package} (PerlNameVisitor)

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser, $pkg_prefix) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{srcname_size} = $parser->YYData->{srcname_size};
    $self->{srcname_mtime} = $parser->YYData->{srcname_mtime};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{client} = 1;
    $self->{miop} = 0;
    $self->{use} = {};
    if ($pkg_prefix) {
        $self->{pkg_prefix} = $pkg_prefix;
        $self->{pkg_prefix} =~ s/\//::/g;
        $self->{pkg_prefix} .= '::';
    }
    else {
        $self->{pkg_prefix} = q{};
    }
    my $filename = basename($self->{srcname}, '.idl') . '.pm';
    $self->open_stream($filename);
    $self->{done_hash} = {};
    $self->{num_key} = 'num_pl_cdr';
    $self->{pkg_modif} = 0;
    $self->{stringify} = 1;
    $self->{id} = 1;
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($filename) = @_;
    open $self->{out}, '>', $filename
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
}

sub _insert_use {
    my $self = shift;
    my ($module) = @_;
    my $FH = $self->{out};
    $module = basename($module, '.idl');
    unless (exists $self->{use}->{$module}) {
        $self->{use}->{$module} = 1;
        print $FH "use ",$self->{pkg_prefix},$module,";\n";
        print $FH "\n";
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
#   3.5     OMG IDL Specification       (could be specialized)
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $self->{pkg_modif} = 0;
    print $FH "# ex: set ro:\n";
    print $FH "#   This file was generated (by ",$0,"). DO NOT modify it.\n";
    print $FH "# From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH "\n";
    print $FH "use strict;\n";
    print $FH "use warnings;\n";
    print $FH "\n";
    print $FH "package main;\n";
    print $FH "\n";
    print $FH "use CORBA::Perl::CORBA;\n";
    print $FH "use Carp;\n";
    print $FH "\n";
    if (exists $node->{list_import}) {
        foreach (@{$node->{list_import}}) {
            $_->visit($self);
        }
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
        if ($self->{pkg_modif}) {
            $self->{pkg_modif} = 0;
            print $FH "package main;\n";
            print $FH "\n";
        }
    }
    print $FH "1;\n";
    print $FH "\n";
    print $FH "#   end of file : ",$self->{filename},"\n";
    print $FH "\n";
    print $FH "# Local variables:\n";
    print $FH "#   buffer-read-only: t\n";
    print $FH "# End:\n";
    close $FH;
}

#
#   3.6     Import Declaration
#

sub visitImport {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->{symbtab}->Lookup($_)->visit($self);
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
    my $FH = $self->{out};
    if ($self->{srcname} eq $node->{filename}) {
        my $defn = $self->{symbtab}->Lookup($node->{full});
        $self->{pkg_modif} = 0;
        print $FH "#\n";
        print $FH "#   begin of module ",$defn->{pl_package},"\n";
        print $FH "#\n";
        print $FH "\n";
        print $FH "package ",$defn->{pl_package},";\n";
        print $FH "\n";
        print $FH "use Carp;\n";
        print $FH "use CORBA::Perl::CORBA;\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
            if ($self->{pkg_modif}) {
                $self->{pkg_modif} = 0;
                print $FH "package ",$defn->{pl_package},";\n";
                print $FH "\n";
            }
        }
        print $FH "\n";
        print $FH "#\n";
        print $FH "#   end of module ",$defn->{pl_package},"\n";
        print $FH "#\n";
        print $FH "\n";
        $self->{pkg_modif} = 1;
    }
    else {
        $self->_insert_use($node->{filename});
    }
}

#
#   3.8     Interface Declaration       (could be specialized)
#

sub visitBaseInterface {
    my $self = shift;
    my($node) = @_;
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        $self->{pkg_modif} = 0;
        print $FH "#\n";
        print $FH "#   begin of '",ref $node,"' ",$node->{pl_package},"\n";
        print $FH "#\n";
        print $FH "\n";
        print $FH "package ",$node->{pl_package},";\n";
        print $FH "\n";
        print $FH "use CORBA::Perl::CORBA;\n";
        print $FH "use Carp;\n";
        print $FH "\n";
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            if (       $defn->isa('Operation')
                    or $defn->isa('Attributes')
                    or $defn->isa('Initializer')
                    or $defn->isa('StateMembers') ) {
                next;
            }
            $defn->visit($self);
            if ($self->{pkg_modif}) {
                $self->{pkg_modif} = 0;
                print $FH "package ",$node->{pl_package},";\n";
                print $FH "\n";
            }
        }
        print $FH "\n";
        print $FH "#\n";
        print $FH "#   end of '",ref $node,"' ",$node->{pl_package},"\n";
        print $FH "#\n";
        print $FH "\n";
        $self->{pkg_modif} = 1;
    }
    else {
        $self->_insert_use($node->{filename});
    }
}

sub visitForwardBaseInterface {
    # empty
}

#
#   3.9     Value Declaration
#

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        print $FH "# ",$node->{pl_package},"::",$node->{pl_name},"\n";
        print $FH "sub ",$node->{pl_name}," () {\n";
        print $FH "\treturn ",$node->{value}->{pl_literal},";\n";
        print $FH "}\n";
        print $FH "\n";
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
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        print $FH "# ",$node->{pl_package},"::",$node->{pl_name}," (typedef)\n";
        if (exists $node->{array_size}) {
            warn __PACKAGE__,"::visitTypeDecalarator $node->{idf} : empty array_size.\n"
                    unless (@{$node->{array_size}});
            my $n;

            print $FH "sub ",$node->{idf},"__marshal {\n";
            print $FH "\tmy (\$r_buffer, \$value) = \@_;\n";
            print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\tunless (defined \$value);\n";
            $n = 0;
            print $FH "\tlocal \$_ = \$value;\n";
            foreach (@{$node->{array_size}}) {
                $n ++;
                print $FH "\tcroak \"bad size of array '",$node->{idf},"'.\\n\"\n";
                print $FH "\t\t\tunless (scalar(\@{\$_}) == ",$_->{pl_literal},");\n";
                print $FH "\tforeach (\@{\$_}) {\n";
            }
            if (exists $type->{max}) {
                print $FH "\t\t",$type->{pl_package},'::',$type->{pl_name},"__marshal(\$r_buffer, \$_, ",$type->{max}->{value},");\n";
            }
            else {
                print $FH "\t\t",$type->{pl_package},'::',$type->{pl_name},"__marshal(\$r_buffer, \$_);\n";
            }
            while ($n--) {
                print $FH "\t}\n";
            }
            print $FH "}\n";
            print $FH "\n";

            print $FH "sub ",$node->{idf},"__demarshal {\n";
            print $FH "\tmy (\$r_buffer, \$r_offset, \$endian) = \@_;\n";
            $n = 0;
            foreach (@{$node->{array_size}}) {
                $n ++;
                print $FH "\tmy \@array",$n," = ();\n";
                print $FH "\tfor (my \$idx",$n," = 0; ";
                    print $FH "\$idx",$n," < ",$_->{pl_literal},"; ";
                    print $FH "\$idx",$n,"++) {\n";
            }
            print $FH "\t\tpush \@array",$n,", ";
                print $FH $type->{pl_package},'::',$type->{pl_name},"__demarshal(\$r_buffer, \$r_offset, \$endian);\n";
            print $FH "\t}\n";
            while ($n > 1) {
                print $FH "\t\tpush \@array",($n - 1),", ";
                    print $FH "\\\@array",$n,";\n";
                print $FH "\t}\n";
                $n --;
            }
            print $FH "\treturn \\\@array1;\n";
            print $FH "}\n";
            print $FH "\n";

            if ($self->{stringify}) {
                my $type2 = $type;
                while (     $type2->isa('TypeDeclarator')
                        and ! exists $type2->{array_size} ) {
                    $type2 = $self->_get_defn($type2->{type});
                }
                print $FH "sub ",$node->{idf},"__stringify {\n";
                print $FH "\tmy (\$value, \$tab) = \@_;\n";
                print $FH "\t\$tab = q{} unless (defined \$tab);\n";
                print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
                print $FH "\t\t\tunless (defined \$value);\n";
                $n = 0;
                print $FH "\tmy \$str = '{';\n";
                print $FH "\tlocal \$_ = \$value;\n";
                foreach (@{$node->{array_size}}) {
                    $n ++;
                    print $FH "\tcroak \"bad size of array '",$node->{idf},"'.\\n\"\n";
                    print $FH "\t\t\tunless (scalar(\@{\$_}) == ",$_->{pl_literal},");\n";
                    print $FH "\tmy \$first",$n," = 1;\n";
                    print $FH "\tforeach (\@{\$_}) {\n";
                    print $FH "\t\tif (\$first",$n,") {\n";
                    print $FH "\t\t\t\$first",$n," = 0;\n";
                    print $FH "\t\t}\n";
                    print $FH "\t\telse {\n";
                    print $FH "\t\t\t\$str .= ',';\n";
                    print $FH "\t\t}\n";
                    unless ($type2->isa('BasicType')) {
                        print $FH "\t\t\$str .= \"\\n\$tab  \";\n";
                    }
                }
                if (exists $type->{max}) {
                    print $FH "\t\t\$str .= ",$type->{pl_package},'::',$type->{pl_name},"__stringify(\$_, \$tab . q{ } x 2, ",$type->{max}->{value},");\n";
                }
                else {
                    print $FH "\t\t\$str .= ",$type->{pl_package},'::',$type->{pl_name},"__stringify(\$_, \$tab . q{ } x 2);\n";
                }
                while ($n--) {
                    print $FH "\t}\n";
                    unless ($type2->isa('BasicType')) {
                        print $FH "\t\$str .= \"\\n\$tab\";\n";
                    }
                    print $FH "\t\$str .= '}';\n";
                }
                print $FH "\treturn \$str;\n";
                print $FH "}\n";
                print $FH "\n";
            }
        }
        else {
            print $FH "sub ",$node->{idf},"__marshal {\n";
            print $FH "\tmy (\$r_buffer, \$value) = \@_;\n";
            print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\tunless (defined \$value);\n";
            if (exists $type->{max}) {
                print $FH "\t",$type->{pl_package},"::",$type->{pl_name},"__marshal(\$r_buffer, \$value, ",$type->{max}->{value},");\n";
            }
            else {
                print $FH "\t",$type->{pl_package},"::",$type->{pl_name},"__marshal(\$r_buffer, \$value);\n";
            }
            print $FH "}\n";
            print $FH "\n";
            print $FH "sub ",$node->{idf},"__demarshal {\n";
            print $FH "\tmy (\$r_buffer, \$r_offset, \$endian) = \@_;\n";
            print $FH "\treturn ",$type->{pl_package},"::",$type->{pl_name},"__demarshal(\$r_buffer, \$r_offset, \$endian);\n";
            print $FH "}\n";
            print $FH "\n";
            if ($self->{stringify}) {
                print $FH "sub ",$node->{idf},"__stringify {\n";
                print $FH "\tmy (\$value, \$tab) = \@_;\n";
                print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
                print $FH "\t\t\tunless (defined \$value);\n";
                if (exists $type->{max}) {
                    print $FH "\treturn ",$type->{pl_package},"::",$type->{pl_name},"__stringify(\$value, \$tab, ",$type->{max}->{value},");\n";
                }
                else {
                    print $FH "\treturn ",$type->{pl_package},"::",$type->{pl_name},"__stringify(\$value, \$tab);\n";
                }
                print $FH "}\n";
                print $FH "\n";
            }
        }
        if ($self->{id}) {
            print $FH "sub ",$node->{pl_name},"__id () {\n";
            print $FH "\treturn \"",$node->{repos_id},"\";\n";
            print $FH "}\n";
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
    my $name = $node->{pl_package} . '::' . $node->{pl_name};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('SequenceType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        print $FH "# ",$name," (struct)\n";
        print $FH "sub ",$node->{pl_name},"__marshal {\n";
        print $FH "\tmy (\$r_buffer, \$value) = \@_;\n";
        print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
        print $FH "\t\t\tunless (defined \$value);\n";
        print $FH "\tcroak \"invalid struct for '",$node->{idf},"' (not a HASH reference).\\n\"\n";
        print $FH "\t\t\tunless (ref \$value eq 'HASH');\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            print $FH "\tcroak \"no member '",$member->{idf},"' in structure '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\tunless (exists \$value->{",$member->{idf},"});\n";
        }
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            $self->_member_marshal($member, $node, "\$value->{" . $member->{idf} . "}");
        }
        print $FH "}\n";
        print $FH "\n";
        print $FH "sub ",$node->{pl_name},"__demarshal {\n";
        print $FH "\tmy (\$r_buffer, \$r_offset, \$endian) = \@_;\n";
        print $FH "\tmy \$value = {};\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            $self->_member_demarshal($member, $node, "\$value->{" . $member->{idf} . "}");
        }
        print $FH "\treturn \$value;\n";
        print $FH "}\n";
        print $FH "\n";
        if ($self->{stringify}) {
            print $FH "sub ",$node->{pl_name},"__stringify {\n";
            print $FH "\tmy (\$value, \$tab) = \@_;\n";
            print $FH "\t\$tab = q{} unless defined (\$tab);\n";
            print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\tunless (defined \$value);\n";
            print $FH "\tcroak \"invalid struct for '",$node->{idf},"' (not a HASH reference).\\n\"\n";
            print $FH "\t\t\tunless (ref \$value eq 'HASH');\n";
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);          # member
                print $FH "\tcroak \"no member '",$member->{idf},"' in structure '",$node->{idf},"'.\\n\"\n";
                print $FH "\t\t\tunless (exists \$value->{",$member->{idf},"});\n";
            }
            print $FH "\tmy \$str = \"struct ",$node->{pl_name}," {\";\n";
            my $idx = 0;
            my $first = 1;
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);          # member
                if ($first) {
                    $first = 0;
                }
                else {
                    print $FH "\t\$str .= ',';\n";
                }
                $self->_member_stringify($member, $node, "\$value->{" . $member->{idf} . "}", \$idx);
            }
            print $FH "\t\$str .= \"\\n\$tab}\";\n";
            print $FH "\treturn \$str;\n";
            print $FH "}\n";
            print $FH "\n";
        }
        if ($self->{id}) {
            print $FH "sub ",$node->{pl_name},"__id () {\n";
            print $FH "\treturn \"",$node->{repos_id},"\";\n";
            print $FH "}\n";
            print $FH "\n";
        }
    }
}

sub _member_marshal {
    my $self = shift;
    my ($node, $parent, $val) = @_;
    my $tab = $parent->isa('UnionType') ? "\t\t" : "\t";
    my $n = 0;
    my $type = $self->_get_defn($node->{type});
    my $FH = $self->{out};
    if (exists $node->{array_size}) {
        print $FH $tab,"local \$_ = ",$val,";\n";
        foreach (@{$node->{array_size}}) {
            $n ++;
            print $FH $tab,"croak \"bad size of array '",$node->{idf},"'.\\n\"\n";
            print $FH $tab,"\t\tunless (scalar(\@{\$_}) == ",$_->{pl_literal},");\n";
            print $FH $tab,"foreach (\@{\$_}) {\n";
        }
        if (exists $type->{max}) {
            print $FH $tab,"\t",$type->{pl_package},'::',$type->{pl_name};
                print $FH "__marshal(\$r_buffer, \$_, ",$type->{max}->{value},");\n";
        }
        else {
            print $FH $tab,"\t",$type->{pl_package},'::',$type->{pl_name};
                print $FH "__marshal(\$r_buffer, \$_);\n";
        }
        while ($n--) {
            print $FH $tab,"}\n";
        }
    }
    else {
        if (exists $type->{max}) {
            print $FH $tab,$type->{pl_package},'::',$type->{pl_name};
                print $FH "__marshal(\$r_buffer, ",$val,", ",$type->{max}->{value},");\n";
        }
        else {
            print $FH $tab,$type->{pl_package},'::',$type->{pl_name};
                print $FH "__marshal(\$r_buffer, ",$val,");\n";
        }
    }
}

sub _member_demarshal {
    my $self = shift;
    my ($node, $parent, $val) = @_;
    my $tab = $parent->isa('UnionType') ? "\t\t" : "\t";
    my $n = 0;
    my $FH = $self->{out};
    my $type = $self->_get_defn($node->{type});
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $n ++;
            print $FH $tab,"my \@",$node->{idf},"_array",$n," = ();\n";
            print $FH $tab,"for (my \$idx",$n," = 0; ";
                print $FH "\$idx",$n," < ",$_->{pl_literal},"; ";
                print $FH "\$idx",$n,"++) {\n";
        }
        print $FH $tab,"\tpush \@",$node->{idf},"_array",$n,", ";
            print $FH $type->{pl_package},'::',$type->{pl_name},"__demarshal(\$r_buffer, \$r_offset, \$endian);\n";
        print $FH $tab,"}\n";
        while ($n > 1) {
            print $FH $tab,"\tpush \@",$node->{idf},"_array",($n - 1),", ";
                print $FH "\\\@",$node->{idf},"_array",$n,";\n";
            print $FH $tab,"}\n";
            $n --;
        }
        print $FH $tab,$val," = \\\@",$node->{idf},"_array1;\n";
    }
    else {
        print $FH $tab,$val," = ";
            print $FH $type->{pl_package},'::',$type->{pl_name},"__demarshal(\$r_buffer, \$r_offset, \$endian);\n";
    }
}

sub _member_stringify {
    my $self = shift;
    my ($node, $parent, $val, $r_idx) = @_;
    my $tab = $parent->isa('UnionType') ? "\t\t" : "\t";
    my $n = 0;
    my $type = $self->_get_defn($node->{type});
    my $array = q{};
    if (exists $node->{array_size}) {
        foreach (@{$node->{array_size}}) {
            $array .= '[]';
        }
    }
    my $FH = $self->{out};
    print $FH $tab,"\$str .= \"\\n\$tab  ",$type->{pl_name},$array," ",$node->{pl_name}," = \";\n";
    if (exists $node->{array_size}) {
        my $type2 = $type;
        while (     $type2->isa('TypeDeclarator')
                and ! exists $type2->{array_size} ) {
            $type2 = $self->_get_defn($type2->{type});
        }
        print $FH $tab,"local \$_ = ",$val,";\n";
        foreach (@{$node->{array_size}}) {
            $n ++;
            $$r_idx ++;
            print $FH $tab,"croak \"bad size of array '",$node->{idf},"'.\\n\"\n";
            print $FH $tab,"\t\tunless (scalar(\@{\$_}) == ",$_->{pl_literal},");\n";
            print $FH $tab,"\$str .= \"{\";\n";
            print $FH $tab,"my \$first",$$r_idx," = 1;\n";
            print $FH $tab,"foreach (\@{\$_}) {\n";
            print $FH $tab,"\tif (\$first",$$r_idx,") {\n";
            print $FH $tab,"\t\t\$first",$$r_idx," = 0;\n";
            print $FH $tab,"\t}\n";
            print $FH $tab,"\telse {\n";
            print $FH $tab,"\t\t\$str .= \",\";\n";
            print $FH $tab,"\t}\n";
            unless ($type2->isa('BasicType')) {
                print $FH $tab,"\$str .= \"\\n\";\n";
            }
        }
        if (exists $type->{max}) {
            print $FH $tab,"\t\$str .= ",$type->{pl_package},'::',$type->{pl_name};
                print $FH "__stringify(\$_, \$tab . \"  \", ",$type->{max}->{value},");\n";
        }
        else {
            print $FH $tab,"\t\$str .= ",$type->{pl_package},'::',$type->{pl_name};
                print $FH "__stringify(\$_, \$tab . \"  \");\n";
        }
        while ($n--) {
            print $FH $tab,"}\n";
            unless ($type2->isa('BasicType')) {
                print $FH "\t\t\$str .= \"\\n\";\n";
            }
            print $FH $tab,"\$str .= \"}\";\n";
        }
    }
    else {
        if (exists $type->{max}) {
            print $FH $tab,"\$str .= ",$type->{pl_package},'::',$type->{pl_name};
                print $FH "__stringify(",$val,", \$tab . \"  \", ",$type->{max}->{value},");\n";
        }
        else {
            print $FH $tab,"\$str .= ",$type->{pl_package},'::',$type->{pl_name};
                print $FH "__stringify(",$val,", \$tab . \"  \");\n";
        }
    }
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{pl_package} . '::' . $node->{pl_name};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('EnumType')
                or $type->isa('SequenceType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    if ($self->{srcname} eq $node->{filename}) {
        my $type = $self->_get_defn($node->{type});
        while ($type->isa('TypeDeclarator')) {
            $type = $self->_get_defn($type->{type});
        }
        my $equal;
        if ($type->isa('IntegerType')) {
            $equal = '==';
        }
        else {
            $equal = 'eq';
        }
        $type = $self->_get_defn($node->{type});
        my $default = undef;
        foreach my $case (@{$node->{list_expr}}) {  # case
            foreach (@{$case->{list_label}}) {  # default or expression
                $default = $case if ($_->isa('Default'));
            }
        }
        my $FH = $self->{out};
        print $FH "# ",$name," (union)\n";
        print $FH "sub ",$node->{pl_name},"__marshal {\n";
        print $FH "\tmy (\$r_buffer, \$union) = \@_;\n";
        print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
        print $FH "\t\t\tunless (defined \$union);\n";
        print $FH "\tcroak \"invalid union for '",$node->{idf},"' (not a ARRAY reference).\\n\"\n";
        print $FH "\t\t\tunless (ref \$union eq 'ARRAY');\n";
        print $FH "\tcroak \"invalid union '",$node->{idf},"'.\\n\"\n";
        print $FH "\t\t\tunless (scalar(\@{\$union}) == 2);\n";
        print $FH "\tmy \$d = \${\$union}[0];\n";
        print $FH "\tmy \$value = \${\$union}[1];\n";
        print $FH "\t",$type->{pl_package},"::",$type->{pl_name},"__marshal(\$r_buffer,\$d);\n";
        print $FH "\tif (0) {\n";
        print $FH "\t\t# empty\n";
        foreach my $case (@{$node->{list_expr}}) {  # case
            foreach (@{$case->{list_label}}) {  # default or expression
                unless ($_->isa('Default')) {
                    print $FH "\t}\n";
                    print $FH "\telsif (\$d ",$equal," ",$_->{pl_literal},") {\n";
                    my $member = $self->_get_defn($case->{element}->{value});
                    $self->_member_marshal($member, $node, "\$value");
                }
            }
        }
        if (defined $default) {
            print $FH "\t}\n";
            print $FH "\telse {\t# default\n";
            my $member = $self->_get_defn($default->{element}->{value});
            $self->_member_marshal($member, $node, "\$value");
        }
        else {
            print $FH "\t}\n";
            print $FH "\telse {\n";
            print $FH "\t\tcroak \"invalid discriminator (\$d) for '",$node->{idf},"'.\\n\";\n";
        }
        print $FH "\t}\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "sub ",$node->{pl_name},"__demarshal {\n";
        print $FH "\tmy (\$r_buffer, \$r_offset, \$endian) = \@_;\n";
        print $FH "\tmy \$value = undef;\n";
        print $FH "\tmy \$d = ",$type->{pl_package},"::",$type->{pl_name},"__demarshal(\$r_buffer,\$r_offset,\$endian);\n";
        print $FH "\tif (0) {\n";
        print $FH "\t\t# empty\n";
        foreach my $case (@{$node->{list_expr}}) {  # case
            foreach (@{$case->{list_label}}) {  # default or expression
                unless ($_->isa('Default')) {
                    print $FH "\t}\n";
                    print $FH "\telsif (\$d ",$equal," ",$_->{pl_literal},") {\n";
                    my $member = $self->_get_defn($case->{element}->{value});
                    $self->_member_demarshal($member, $node, "\$value");
                }
            }
        }
        if (defined $default) {
            print $FH "\t}\n";
            print $FH "\telse {\t# default\n";
            my $member = $self->_get_defn($default->{element}->{value});
            $self->_member_demarshal($member, $node, "\$value");
        }
        else {
            print $FH "\t}\n";
            print $FH "\telse {\n";
            print $FH "\t\tcroak \"invalid discriminator (\$d) for '",$node->{idf},"'.\\n\";\n";
        }
        print $FH "\t}\n";
        print $FH "\treturn [\$d, \$value];\n";
        print $FH "}\n";
        print $FH "\n";
        if ($self->{stringify}) {
            print $FH "sub ",$node->{pl_name},"__stringify {\n";
            print $FH "\tmy (\$union, \$tab) = \@_;\n";
            print $FH "\t\$tab = q{} unless defined (\$tab);\n";
            print $FH "\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\tunless (defined \$union);\n";
            print $FH "\tcroak \"invalid union for '",$node->{idf},"' (not a ARRAY reference).\\n\"\n";
            print $FH "\t\t\tunless (ref \$union eq 'ARRAY');\n";
            print $FH "\tcroak \"invalid union '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\tunless (scalar(\@{\$union}) == 2);\n";
            print $FH "\tmy \$d = \${\$union}[0];\n";
            print $FH "\tmy \$value = \${\$union}[1];\n";
            print $FH "\tmy \$str = \"union ",$node->{pl_name}," {\";\n";
            print $FH "\tif (0) {\n";
            print $FH "\t\t# empty\n";
            my $idx = 0;
            foreach my $case (@{$node->{list_expr}}) {  # case
                foreach (@{$case->{list_label}}) {  # default or expression
                    unless ($_->isa('Default')) {
                        print $FH "\t}\n";
                        print $FH "\telsif (\$d ",$equal," ",$_->{pl_literal},") {\n";
                        my $member = $self->_get_defn($case->{element}->{value});
                        $self->_member_stringify($member, $node, "\$value", \$idx);
                    }
                }
            }
            if (defined $default) {
                print $FH "\t}\n";
                print $FH "\telse {\t# default\n";
                my $member = $self->_get_defn($default->{element}->{value});
                $self->_member_stringify($member, $node, "\$value", \$idx);
            }
            else {
                print $FH "\t}\n";
                print $FH "\telse {\n";
                print $FH "\t\tcroak \"invalid discriminator (\$d) for '",$node->{idf},"'.\\n\";\n";
            }
            print $FH "\t}\n";
            print $FH "\t\$str .= \"\\n\$tab}\";\n";
            print $FH "\treturn \$str;\n";
            print $FH "}\n";
            print $FH "\n";
        }
        if ($self->{id}) {
            print $FH "sub ",$node->{pl_name},"__id () {\n";
            print $FH "\treturn \"",$node->{repos_id},"\";\n";
            print $FH "}\n";
            print $FH "\n";
        }
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
    my $name = $node->{pl_package} . '::' . $node->{pl_name};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        print $FH "# ",$name," (enum)\n";
        print $FH "sub ",$node->{pl_name},"__marshal {\n";
        print $FH "\tmy (\$r_buffer, \$value) = \@_;\n";
        print $FH "\tif (0) {\n";
        my $idx = 0;
        foreach (@{$node->{list_expr}}) {
            print $FH "\t}\n";
            print $FH "\telsif (\$value eq '",$_->{pl_name},"') {\n";
            print $FH "\t\tCORBA::Perl::CORBA::unsigned_long__marshal(\$r_buffer, ",$idx++,");\n";
        }
        print $FH "\t}\n";
        print $FH "\telse {\n";
        print $FH "\t\tcroak \"bad value for '",$name,"'.\\n\";\n";
        print $FH "\t}\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "sub ",$node->{pl_name},"__demarshal {\n";
        print $FH "\tmy \$value = CORBA::Perl::CORBA::unsigned_long__demarshal(\@_);\n";
        print $FH "\tif (0) {\n";
        $idx = 0;
        foreach (@{$node->{list_expr}}) {
            print $FH "\t}\n";
            print $FH "\telsif (\$value == ",$idx++,") {\n";
            print $FH "\t\treturn '",$_->{pl_name},"';\n";
        }
        print $FH "\t}\n";
        print $FH "\telse {\n";
        print $FH "\t\tcroak \"bad value for '",$name,"'.\\n\";\n";
        print $FH "\t}\n";
        print $FH "}\n";
        print $FH "\n";
        if ($self->{stringify}) {
            print $FH "sub ",$node->{pl_name},"__stringify {\n";
            print $FH "\tmy (\$value) = \@_;\n";
            print $FH "\treturn \$value;\n";
            print $FH "}\n";
            print $FH "\n";
        }
        if ($self->{id}) {
            print $FH "sub ",$node->{pl_name},"__id () {\n";
            print $FH "\treturn \"",$node->{repos_id},"\";\n";
            print $FH "}\n";
            print $FH "\n";
        }
        foreach (@{$node->{list_expr}}) {   # enum
            print $FH "sub ",$_->{pl_name}," () {\n";
            print $FH "\treturn '",$_->{pl_name},"';\n";
            print $FH "}\n";
        }
        print $FH "\n";
    }
}

#
#   3.11.3  Template Types
#

sub visitSequenceType {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{pl_package} . '::' . $node->{pl_name};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    if ($self->{srcname} eq $node->{filename}) {
        my $type = $self->_get_defn($node->{type});
        if (       $type->isa('SequenceType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
        my $FH = $self->{out};
        print $FH "# ",$name," (sequence)\n";
        print $FH "sub ",$node->{pl_name},"__marshal {\n";
        print $FH "\tmy (\$r_buffer, \$value, \$max) = \@_;\n";
        print $FH "\tcroak \"undefined value for '",$node->{pl_name},"'.\\n\"\n";
        print $FH "\t\t\tunless (defined \$value);\n";
        if        ( $type->{pl_name} eq 'char'
                 or $type->{pl_name} eq 'octet' ) {
            print $FH "\tcroak \"value '\$value' is not a string.\\n\"\n";
            print $FH "\t\t\tif (ref \$value);\n";
            print $FH "\tmy \$len = length(\$value);\n";
            print $FH "\tcroak \"too long sequence for '",$node->{pl_name},"' (max:\$max).\\n\"\n";
            print $FH "\t\t\tif (defined \$max and \$len > \$max);\n";
            print $FH "\tCORBA::Perl::CORBA::unsigned_long__marshal(\$r_buffer, \$len);\n";
            print $FH "\t\$\$r_buffer .= \$value;\n";
        }
        else {
            print $FH "\tmy \$len = scalar(\@{\$value});\n";
            print $FH "\tcroak \"too long sequence for '",$node->{pl_name},"' (max:\$max).\\n\"\n";
            print $FH "\t\t\tif (defined \$max and \$len > \$max);\n";
            print $FH "\tCORBA::Perl::CORBA::unsigned_long__marshal(\$r_buffer, \$len);\n";
            print $FH "\tforeach (\@{\$value}) {\n";
            print $FH "\t\t",$type->{pl_package},"::",$type->{pl_name},"__marshal(\$r_buffer, \$_);\n";
            print $FH "\t}\n";
        }
        print $FH "}\n";
        print $FH "\n";
        print $FH "sub ",$node->{pl_name},"__demarshal {\n";
        print $FH "\tmy (\$r_buffer, \$r_offset, \$endian) = \@_;\n";
        print $FH "\tmy \$len = CORBA::Perl::CORBA::unsigned_long__demarshal(\$r_buffer, \$r_offset, \$endian);\n";
        print $FH "\tmy \@seq = ();\n";
        if        ( $type->{pl_name} eq 'char'
                 or $type->{pl_name} eq 'octet' ) {
            print $FH "\tmy \$str = substr \$\$r_buffer, \$\$r_offset, \$len;\n";
            print $FH "\t\$\$r_offset += \$len;\n";
            print $FH "\treturn \$str;\n";
        }
        else {
            print $FH "\twhile (\$len--) {\n";
            print $FH "\t\tpush \@seq,",$type->{pl_package},"::",$type->{pl_name},"__demarshal(\$r_buffer, \$r_offset, \$endian);\n";
            print $FH "\t}\n";
            print $FH "\treturn \\\@seq;\n";
        }
        print $FH "}\n";
        print $FH "\n";
        if ($self->{stringify}) {
            my $type2 = $type;
            while (     $type2->isa('TypeDeclarator')
                    and ! exists $type2->{array_size} ) {
                $type2 = $self->_get_defn($type2->{type});
            }
            print $FH "sub ",$node->{pl_name},"__stringify {\n";
            print $FH "\tmy (\$value, \$tab, \$max) = \@_;\n";
            print $FH "\t\$tab = q{} unless (defined \$tab);\n";
            print $FH "\tcroak \"undefined value for '",$node->{pl_name},"'.\\n\"\n";
            print $FH "\t\t\tunless (defined \$value);\n";
            if ($type->{pl_name} eq 'char') {
                print $FH "\tcroak \"value '\$value' is not a string.\\n\"\n";
                print $FH "\t\t\tif (ref \$value);\n";
                print $FH "\tmy \$len = length(\$value);\n";
                print $FH "\tcroak \"too long sequence for '",$node->{pl_name},"' (max:\$max).\\n\"\n";
                print $FH "\t\t\tif (defined \$max and \$len > \$max);\n";
                print $FH "\treturn \"\$value\";\n";
            }
            else {
                if ($type->{pl_name} eq 'octet') {
                    print $FH "\t\$value = [map ord, split //, \$value];\n";
                }
                print $FH "\tmy \$len = scalar(\@{\$value});\n";
                print $FH "\tcroak \"too long sequence for '",$node->{pl_name},"' (max:\$max).\\n\"\n";
                print $FH "\t\t\tif (defined \$max and \$len > \$max);\n";
                print $FH "\tmy \$str = '{';\n";
                print $FH "\tmy \$first = 1;\n";
                print $FH "\tforeach (\@{\$value}) {\n";
                print $FH "\t\tif (\$first) {\n";
                print $FH "\t\t\t\$first = 0;\n";
                print $FH "\t\t}\n";
                print $FH "\t\telse {\n";
                print $FH "\t\t\t\$str .= ',';\n";
                print $FH "\t\t}\n";
                unless ($type2->isa('BasicType')) {
                    print $FH "\t\t\$str .= \"\\n\$tab  \";\n";
                }
                print $FH "\t\t\$str .= ",$type->{pl_package},"::",$type->{pl_name},"__stringify(\$_, \$tab . q{ } x 2);\n";
                print $FH "\t}\n";
                unless ($type2->isa('BasicType')) {
                    print $FH "\t\$str .= \"\\n\$tab\";\n";
                }
                print $FH "\t\$str .= '}';\n";
                print $FH "\treturn \$str;\n";
            }
            print $FH "}\n";
            print $FH "\n";
        }
    }
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
    my $name = $node->{pl_package} . '::' . $node->{pl_name};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});

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
    if ($self->{srcname} eq $node->{filename}) {
        my $FH = $self->{out};
        print $FH "# ",$name," (exception)\n";
        print $FH "sub ",$node->{pl_name},"__marshal {\n";
        print $FH "\t\tmy (\$r_buffer,\$value) = \@_;\n";
        print $FH "\t\tcroak \"undefined value for '",$node->{idf},"'.\\n\"\n";
        print $FH "\t\t\t\tunless (defined \$value);\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            print $FH "\t\tcroak \"no member '",$member->{idf},"' in structure '",$node->{idf},"'.\\n\"\n";
            print $FH "\t\t\t\tunless (exists \$value->{",$member->{idf},"});\n";
        }
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            $self->_member_marshal($member, $node, "\$value->{" . $member->{idf} . "}");
        }
        print $FH "}\n";
        print $FH "\n";
        print $FH "sub ",$node->{pl_name},"__demarshal {\n";
        print $FH "\t\tmy (\$r_buffer,\$r_offset,\$endian) = \@_;\n";
        print $FH "\t\tmy \$value = {};\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            $self->_member_demarshal($member, $node, "\$value->{" . $member->{idf} . "}");
        }
        print $FH "\t\treturn \$value;\n";
        print $FH "}\n";
        print $FH "\n";
        if ($self->{id}) {
            print $FH "sub ",$node->{pl_name},"__id () {\n";
            print $FH "\treturn \"",$node->{repos_id},"\";\n";
            print $FH "}\n";
            print $FH "\n";
        }
        print $FH "package ",$node->{pl_package},"::",$node->{pl_name},";\n";
        print $FH "\n";
        print $FH "use base qw(CORBA::Perl::CORBA::UserException);\n";
        print $FH "\n";
        print $FH "sub new {\n";
        print $FH "\tmy \$self = shift;\n";
        print $FH "\tlocal \$Error::Depth = \$Error::Depth + 1;\n";
        print $FH "\t\$self->SUPER::new(\@_);\n";
        print $FH "}\n";
        print $FH "\n";
        print $FH "sub stringify {\n";
        print $FH "\tmy \$self = shift;\n";
        print $FH "\tmy \$str = \$self->SUPER::stringify() . \"\\n\";\n";
        if (scalar(@{$node->{list_member}})) {
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);          # member
                print $FH "\t\$str .= \"\\t",$member->{idf}," => \$self->{",$member->{idf},"}\\n\";\n";
            }
        }
        else {
            print $FH "\t\$str .= \"\\t(no data)\";\n";
        }
        print $FH "\t\$str .= sprintf(\" at \%s line \%d.\\n\", \$self->file, \$self->line);\n";
        print $FH "\treturn \$str;\n";
        print $FH "}\n";
        print $FH "\n";
        $self->{pkg_modif} = 1;
    }
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

#
#   XPIDL
#

sub visitCodeFragment {
    # empty
}

1;

