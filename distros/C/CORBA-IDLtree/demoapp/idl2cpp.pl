# idl2cpp.pl ################################################################
# This code is distributed under the same terms as Perl itself.
# Copyright/author:  (C) 2003, O. Kellogg (okellogg@users.sourceforge.net)
#
$Version = '0.0';
#
# At this point idl2cpp.pl is just a very rudimentary C++ code generator
# mainly intended as a demo program for CORBA::IDLtree.
#############################################################################

use CORBA::IDLtree;

my $indentlevel = 0;
my @scopes;   # List of scope strings; auxiliary to sub typeof
my $global_idlfile;   # name of the IDL file currently being processed
my $global_basename;  # basename of $global_idlfile
my $dump_idl_from_tree = 0;  # option -d: call CORBA::IDLtree::Dump_Symbols

# Shorthands for subs from CORBA::IDLtree
sub TYPE { &CORBA::IDLtree::TYPE; }
sub NAME { &CORBA::IDLtree::NAME; }
sub SUBORDINATES { &CORBA::IDLtree::SUBORDINATES; }

# Initialize file-scope variables per IDL input file to be parsed
sub init_variables {
    $indentlevel = 0;
    @scopes = ();
    $global_basename = "";
}

sub cpptypeof {  # Returns the string of a "type descriptor" in C++ syntax.
    my $type = shift;
    my $gen_scope = 0;       # generate scope-qualified name
    if (@_) {
        $gen_scope = shift;
    }
    my $rv = "";
    if ($type >= CORBA::IDLtree::BOOLEAN &&
        $type < CORBA::IDLtree::NUMBER_OF_TYPES) {
        if ($type <= CORBA::IDLtree::ANY) {
            my @cpptype = qw/ none Boolean Octet Char WChar Short Long
                            LongLong UShort ULong ULongLong Float Double
                            LongDouble String WString Object TypeCode Any /;
            $rv = "CORBA::" . $cpptype[$type];
        } else {
            # This shouldn't really happen...
            $rv = $CORBA::IDLtree::predef_types[$type];
        }
        return $rv;
    } elsif (! CORBA::IDLtree::isnode($type)) {
        warn "parameter to cpptypeof is not a node ($type)\n";
        return "";
    }
    my @node = @{$type};
    my $name = $node[NAME];
    my $prefix = "";
    if ($gen_scope) {
        my @tmpnode = @node;
        my @scope;
        while ((@scope = @{$tmpnode[CORBA::IDLtree::SCOPEREF]})) {
            $prefix = $scope[NAME] . "::" . $prefix;
            @tmpnode = @scope;
        }
        if (ref $gen_scope) {
            # @gen_scope contains the scope strings.
            # Now we can decide whether the scope prefix is needed.
            my $curr_scope = join("::", @{$gen_scope});
            if ($prefix eq "${curr_scope}::") {
                $prefix = "";
            }
        }
    }
    "$prefix$name"
}

sub typeof {
    cpptypeof(shift, \@scopes);
}



sub array_info {
    my $type = shift;
    if (! CORBA::IDLtree::isnode($type) ||
        $$type[TYPE] != CORBA::IDLtree::TYPEDEF) {
        return 0;
    }
    my $basetype_and_dimref = $$type[SUBORDINATES];
    my $dimref = $$basetype_and_dimref[1];
    if ($dimref && @{$dimref}) {
        return $basetype_and_dimref;
    }
    0;
}


sub is_a {
    # Determines whether node is of given type. Recurses through TYPEDEFs.
    my $type = shift;
    my $typeid = shift;
    if ($type == $typeid) {
        return 1;
    } elsif (not CORBA::IDLtree::isnode $type) {
        return 0;
    }
    my @node = @{$type};
    my $rv = 0;
    if ($node[TYPE] == $typeid) {
        $rv = 1;
    } elsif ($node[TYPE] == CORBA::IDLtree::TYPEDEF) {
        my @origtype_and_dim = @{$node[SUBORDINATES]};
        my $dimref = $origtype_and_dim[1];
        unless ($dimref && @{$dimref}) {
            $rv = is_a($origtype_and_dim[0], $typeid);
        }
    }
    $rv;
}


sub is_structured {
    my $type = shift;
    is_a($type, CORBA::IDLtree::STRUCT) ||
     is_a($type, CORBA::IDLtree::UNION);
}


sub fqname {
    cpptypeof(shift, 1);
}


# Subs for output to the C++ header

sub emit {
    print OUT shift;
}

sub dent {
    emit(' ' x ($indentlevel * 3));
    if (@_) {
        emit shift;
    }
}



sub idl2cpp {
    my $tree_ref = shift;
    if (! $tree_ref) {
        print STDERR "idl2cpp: encountered empty elem (returning)\n";
        return;
    }
    if (not CORBA::IDLtree::isnode $tree_ref) {
        foreach $elem (@{$tree_ref}) {
            &idl2cpp($elem);
        }
        return;
    }
    my @node = @{$tree_ref};
    my $type = $node[TYPE];
    my $name = $node[NAME];
    my $subord = $node[CORBA::IDLtree::SUBORDINATES];
    my @arg = @{$subord};
    my $i;
    if ($type == CORBA::IDLtree::INCFILE) {
        emit "\#include ";
        $name =~ s/^.*\///;
        $name =~ s/\.idl$//;
        $name .= '.h';
        emit "\"$name\"\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::PRAGMA_PREFIX) {
        emit "#pragma prefix \"$name\"\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::ATTRIBUTE) {
        dent;
        emit("readonly ") if ($arg[0]);
        emit("attribute " . typeof($arg[1]) . " $name;\n\n");
        return;
    } elsif ($type == CORBA::IDLtree::METHOD) {
        my $t = shift @arg;
        my $rettype;
        if ($t == CORBA::IDLtree::ONEWAY ||
            $t == CORBA::IDLtree::VOID) {
            $rettype = 'void';
        } else {
            $rettype = typeof $t;
        }
        my @exc_list = @{pop @arg};
        dent($rettype . " $name (");
        if (@arg) {
            unless ($#arg == 0) {
                emit "\n";
                $indentlevel += 5;
            }
            for ($i = 0; $i <= $#arg; $i++) {
                my $pnode = $arg[$i];
                my $ptype = typeof($$pnode[TYPE]);
                my $pname = $$pnode[NAME];
                my $m     = $$pnode[SUBORDINATES];
                my $pmode;
                ######## NOT READY YET.
                $pmode = ($m == &CORBA::IDLtree::IN ? 'in' :
                          $m == &CORBA::IDLtree::OUT ? 'out' : 'inout');
                dent unless ($#arg == 0);
                emit "$pmode $ptype $pname";
                emit(",\n") if ($i < $#arg);
            }
            unless ($#arg == 0) {
                $indentlevel -= 5;
            }
        }
        emit ")";
        if (@exc_list) {
            emit "\n";
            $indentlevel++;
            dent " raises (";
            for ($i = 0; $i <= $#exc_list; $i++) {
                emit(${$exc_list[$i]}[NAME]);
                emit(", ") if ($i < $#exc_list);
            }
            emit ")";
            $indentlevel--;
        }
        emit ";\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::VALUETYPE) {
        dent;
        my $abstract = $arg[0];
        emit "class $name ";
        if ($arg[1]) {          # ancestor info
            my($truncatable, $ancestors_ref) = @{$arg[1]};
            if (@{$ancestors_ref}) {
                emit ": public ";
                my $first = 1;
                foreach $ancref (@{$ancestors_ref}) {
                    if ($first) {
                        $first = 0;
                    } else {
                        emit ", ";
                    }
                    # my @ancnode = @{$ancref};
                    emit fqname($ancref);
                }
                emit ' ';
            }
        }
        emit "{    // TBD: This is really the OBV_ class.\n";
        my @memberinfo_tuplerefs = @{$arg[2]};
        dent "private:\n";
        $indentlevel++;
        foreach $memberinfo_tupleref (@memberinfo_tuplerefs) {
            my($memberkind, $member_ref) = @{$memberinfo_tupleref};
            my @member = @{$member_ref};
            my $mname = $member[NAME];
            my $mtype = typeof($member[TYPE]);
            if ($memberkind) {  # private or public
                dent "$mtype _$mname;\n";
            }
        }
        my $did_protected = 0;
        foreach $memberinfo_tupleref (@memberinfo_tuplerefs) {
            my($memberkind, $member_ref) = @{$memberinfo_tupleref};
            if ($memberkind == CORBA::IDLtree::PRIVATE) {
                unless ($did_protected) {
                    $did_protected = 1;
                    $indentlevel--;
                    dent "protected:\n";
                    $indentlevel++;
                }
                gen_accessors $member_ref;
            }
        }
        ### Cannot nest a valuetype inside a union as long as
        ### we have a constructor here !!!
        # dent "$name () { memset (this, 0, sizeof ($name)); }\n\n";
        my $did_public = 0;
        foreach $memberinfo_tupleref (@memberinfo_tuplerefs) {
            my($memberkind, $member_ref) = @{$memberinfo_tupleref};
            next if ($memberkind == CORBA::IDLtree::PRIVATE);
            unless ($did_public) {
                $indentlevel--;
                dent "public:\n";
                $indentlevel++;
                $did_public = 1;
            }
            if ($memberkind == CORBA::IDLtree::PUBLIC) {
                gen_accessors $member_ref;
                next;
            }
            # It's an ATTRIBUTE or METHOD.
            my @member = @{$member_ref};
            if ($member[TYPE] == CORBA::IDLtree::ATTRIBUTE) {
                print STDERR "attribute member in valuetype not yet supported\n";
                return;
            } elsif ($member[TYPE] != CORBA::IDLtree::METHOD) {
                print STDERR ("tree error: valuetype member cannot be " .
                              CORBA::IDLtree::typeof($member_ref) . "\n");
                return;
            }
            # It's a METHOD.
            my @params = @{$member[SUBORDINATES]};
            my $rettype = fqname(shift(@params));
            dent("virtual $rettype " . $member[NAME] . " (");
            my $i;
            my $s = (' ' x 24);
            for ($i = 0; $i < scalar(@params); $i++) {
                my @param = @{$params[$i]};
                if ($i == 0) {
                    emit "\n";
                }
                dent($s . fqname($param[TYPE]) . " " . $param[NAME]);
                if ($i < $#params) {
                    emit ",";
                }
                emit "\n";
            }
            emit ") = 0;\n\n";
        }
        $indentlevel--;
        dent "};\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::MODULE ||
             $type == CORBA::IDLtree::INTERFACE) {
        push @scopes, $name;
        if ($type == CORBA::IDLtree::INTERFACE) {
            dent "class $name ";
            my @ancestors = @{shift @arg};
            my $abstract = shift(@arg);  # NYI
            if (@ancestors) {
                emit ": public ";
                for ($i = 0; $i <= $#ancestors; $i++) {
                    emit fqname($ancestors[$i]);
                    emit(", ") if ($i < $#ancestors);
                }
            }
        } else {
            dent "namespace $name ";
        }
        emit "{\n\n";
        $indentlevel++;
        foreach $component (@arg) {
            &idl2cpp($component);
        }
        $indentlevel--;
        dent "};\n\n";
        pop @scopes;
        return;
    } elsif ($type == CORBA::IDLtree::INTERFACE_FWD) {
        dent "class $name;\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::UNION) {
        my $switchtype = shift(@arg);
        my $sw = typeof($switchtype);
        dent "class $name {\n";
        dent "private:\n";
        $indentlevel++;
        dent "$sw _discr;\n";
        dent "union {\n";
        $indentlevel++;
        foreach $node (@arg) {
            my $type = $$node[TYPE];
            my $name = $$node[NAME];
            my $suboref = $$node[SUBORDINATES];
            unless ($type == CORBA::IDLtree::SWITCHNAME ||
                    $type == CORBA::IDLtree::CASE ||
                    $type == CORBA::IDLtree::DEFAULT) {
                dent(typeof($type) . " $name;\n");
            }
        }
        $indentlevel--;
        dent "} _u;\n\n";
        $indentlevel--;
        dent "public:\n";
        $indentlevel++;
        #### Cannot have a constructor because this union might
        ###  be nested inside a further union and then 
        ##   the constructor bothers !!!
        # dent "$name () { memset (this, 0, sizeof ($name)); }\n\n";

        # Setting the discriminant separately almost always fails.
        # "Almost always" is, the discrim. can only be set to the 
        # value that it had before anyway. (Sort of a no-op.)
        # Therefore we simply don't generate the setter at all.
        ## dent "void _d ($sw discr) { _discr = discr; }\n";
        dent "const $sw _d () const { return _discr; }\n\n";
        my $had_default = 0;
        my $the_case;
        foreach $node (@arg) {
            my $type = $$node[TYPE];
            my $nm = $$node[NAME];
            my $suboref = $$node[SUBORDINATES];
            next if ($type == CORBA::IDLtree::SWITCHNAME);
            if ($type == CORBA::IDLtree::CASE) {
                $the_case = $$suboref[0];
                next;
            } elsif ($type == CORBA::IDLtree::DEFAULT) {
                die "$name: default branch not implemented\n";
                # $had_default = 1;
                # next;
            }
            my $arr_info = array_info($type);
            my $t = typeof($type);
            dent "const $t";
            if ($arr_info) {
                emit "_slice*";
            } elsif (is_structured $type) {
                emit "&";
            }
            emit " $nm () const { return _u.$nm; }\n";
            dent "void $nm ($t";
            if (is_structured $type) {
                emit "&";
            }
            emit " val) {\n";
            $indentlevel ++;
            dent "_discr = $the_case;\n";
            if ($arr_info) {
                dent "memcpy (_u.$nm, val, sizeof($t));\n";
            } else {
                dent "_u.$nm = val;\n";
            }
            $indentlevel --;
            dent "}\n\n";
        }
        $indentlevel --;
        dent "};\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::EXCEPTION) {
        dent "class $name : public CORBA::UserException {\n";
        dent "public:\n";
        $indentlevel++;
        while (@arg) {
            my $node = shift @arg;
            my $type = $$node[TYPE];
            my $name = $$node[NAME];
            my $suboref = $$node[SUBORDINATES];
            foreach $dim (@{$suboref}) {
                $name .= '[' . $dim . ']';
            }
            dent(typeof($type) . " _$name;\n");
        }
        emit "\n";
        dent "$name () {}\n";
        dent "// $name (const $name\& src) {}   // ToBeDone.\n";
        dent "~$name () {}\n\n";
        dent "void _raise (void) { throw *this; }\n\n";
        $indentlevel--;
        dent "};\n\n";
        return;
    } elsif ($type == CORBA::IDLtree::REMARK) {
        my @comment = @$name;
        if (scalar(@comment) == 1) {
            dent("//" . $comment[0] . "\n\n");
        } else {
            dent "/*\n";
            foreach (@comment) {
                dent "$_\n";
            }
            dent " */\n\n";
        }
        return;
    }
    dent(typeof($type) . " ");
    if ($type == CORBA::IDLtree::TYPEDEF) {
        my $origtype = $arg[0];
        my $eltype = typeof($origtype);
        emit "$eltype $name";
        if ($type == CORBA::IDLtree::TYPEDEF) {
            my $dimref = $arg[1];
            if ($dimref and @{$dimref}) {
                my @dims = @{$dimref};
                foreach $dim (@dims) {
                    emit "[$dim]";
                }
                emit ";\n\n";
                dent "typedef $eltype ${name}_slice";
                my $i;
                for ($i = 1; $i <= $#dims; $i++) {
                    emit "\[$dims[$i]\]";
                }
            }
        }
    } elsif ($type == CORBA::IDLtree::CONST) {
        emit(typeof($arg[0]) . " $name = ");
        emit join(' ', @{$arg[1]});
    } elsif ($type == CORBA::IDLtree::ENUM) {
        emit "$name { ";
        if ($#arg > 2) {
            $indentlevel += 5;
            emit "\n";
        }
        for ($i = 0; $i <= $#arg; $i++) {
            dent if ($#arg > 2);
            emit $arg[$i];
            if ($i < $#arg) {
                emit(", ");
                emit("\n") if ($#arg > 2);
            }
        }
        if ($#arg > 2) {
            $indentlevel -= 5;
            emit "\n";
            dent "}";
        } else {
            emit " }";
        }
    } elsif ($type == CORBA::IDLtree::STRUCT) {
        emit "$name {\n";
        $indentlevel++;
        my $had_case = 0;
        while (@arg) {
            my $node = shift @arg;
            my $type = $$node[TYPE];
            my $name = $$node[NAME];
            my $suboref = $$node[SUBORDINATES];
            if ($type == CORBA::IDLtree::CASE ||
                $type == CORBA::IDLtree::DEFAULT) {
                if ($had_case) {
                    $indentlevel--;
                } else {
                    $had_case = 1;
                }
                if ($type == CORBA::IDLtree::CASE) {
                    foreach $case (@{$suboref}) {
                       dent "case $case:\n";
                    }
                } else {
                    dent "default:\n";
                }
                $indentlevel++;
            } else {
                foreach $dim (@{$suboref}) {
                    $name .= '[' . $dim . ']';
                }
                dent(typeof($type) . " $name;\n");
            }
        }
        $indentlevel -= $had_case + 1;
        dent "}";
    } else {
        print STDERR "idl2cpp: unknown type value $type\n";
    }
    emit ";\n\n";
}

# Main program

$CORBA::IDLtree::enable_comments = 1;
foreach $arg (@ARGV) {
    if ($arg =~ /^-/) {
        for (substr($arg, 1)) {
            /^v$/          and CORBA::IDLtree::set_verbose, last;
            /^V$/          and print "version $Version\n", last;
            /^d$/          and $dump_idl_from_tree = 1, last;
            /^I/           and push(@CORBA::IDLtree::include_path,
                                    substr($_, 1)), last;
            print STDERR "unknown option: $arg\n", last;
        }
        next;
    }
    $global_idlfile = $arg;
    my $idltree = CORBA::IDLtree::Parse_File($global_idlfile);
    $idltree or die "exiting...\n";
    CORBA::IDLtree::Dump_Symbols($idltree) if ($dump_idl_from_tree);
    init_variables;
    $global_basename = $global_idlfile;
    $global_basename =~ s/^.*\///;
    $global_basename =~ s/\.\w+$//;
    my $outfilename = $global_basename . ".h";
    open(OUT, ">$outfilename") or die "cannot create $outfilename\n";
    my $hfence = uc("${global_basename}__H");
    print OUT "#ifndef $hfence\n";
    print OUT "#define $hfence\n\n";
    print OUT "#include <string.h>\n";
    print OUT "#include <p_orb.h>   // CORBA definitions\n\n";
    idl2cpp $idltree;
    print OUT "#endif  // $hfence\n\n";
    close OUT;
}

1;

