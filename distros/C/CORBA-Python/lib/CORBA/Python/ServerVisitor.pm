
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Python::ServerVisitor;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::Python::ClassVisitor;
use base qw(CORBA::Python::ClassVisitor);

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
    $self->{server} = 1;
    if (exists $parser->YYData->{opt_J}) {
        $self->{base_package} = $parser->YYData->{opt_J};
    }
    else {
        $self->{base_package} = q{};
    }
    $self->{done_hash} = {};
    $self->{marshal} = 1;
    $self->{stringify} = 1;
    $self->{compare} = 1;
    $self->{id} = 1;
    $self->{old_object} = exists $parser->YYData->{opt_O};
    $self->{indent} = q{};
    $self->{out} = undef;
    $self->{import} = "import PyIDL as CORBA\n"
                    . "import PyIDL.cdr as CDR\n"
                    . "import PyIDL.iop as IOP\n"
                    . "import PyIDL.giop as GIOP\n"
                    . "\n";
    $self->{scope} = undef;
    return $self;
}

#
#   3.5     OMG IDL Specification       (inherited)
#

#
#   3.7     Module Declaration          (inherited)
#

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{indent} = q{ } x 4;
    $self->{itf} = $node;
    print $FH "\n";
    if ($self->{old_object}) {
        print $FH "class ",$node->{py_name},"_skel";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            print $FH "(";
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                my $base = $self->_get_defn($_);
                print $FH $self->_get_scoped_name($base, $node);
                $first = 0;
            }
            print $FH ")";
        }
        print $FH ":\n";
    }
    else {
        print $FH "class ",$node->{py_name},,"_skel(";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                my $base = $self->_get_defn($_);
                print $FH $self->_get_scoped_name($base, $node);
                $first = 0;
            }
        }
        else {
            print $FH "object";
        }
        print $FH "):\n";
    }
    print $FH "    \"\"\" Interface: ",$node->{repos_id}," \"\"\"\n";
    print $FH "\n";
    $self->{repos_id} = $node->{repos_id};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    if ($self->{id}) {
        print $FH "    def _get_id(cls):\n";
        print $FH "        return '",$node->{repos_id},"'\n";
        print $FH "    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    print $FH "\n";
    $self->{indent} = q{};
    delete $self->{itf};
}

sub visitAbstractInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{indent} = q{ } x 4;
    $self->{itf} = $node;
    print $FH "\n";
    if ($self->{old_object}) {
        print $FH "class ",$node->{py_name},"_skel";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            print $FH "(";
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                my $base = $self->_get_defn($_);
                print $FH $self->_get_scoped_name($base, $node);
                $first = 0;
            }
            print $FH ")";
        }
        print $FH ":\n";
    }
    else {
        print $FH "class ",$node->{py_name},,"_skel(";
        if (exists $node->{inheritance} and exists $node->{inheritance}->{list_interface}) {
            my $first = 1;
            foreach (@{$node->{inheritance}->{list_interface}}) {
                print $FH ", " unless ($first);
                my $base = $self->_get_defn($_);
                print $FH $self->_get_scoped_name($base, $node);
                $first = 0;
            }
        }
        else {
            print $FH "object";
        }
        print $FH "):\n";
    }
    print $FH "    \"\"\" Abstract Interface: ",$node->{repos_id}," \"\"\"\n";
    print $FH "\n";
    $self->{repos_id} = $node->{repos_id};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    print $FH "\n";
    $self->{indent} = q{};
    delete $self->{itf};
}

#
#   3.9     Value Declaration           (inherited)
#

#
#   3.10    Constant Declaration        (inherited)
#

#
#   3.11    Type Declaration            (inherited)
#

#
#   3.12    Exception Declaration       (inherited)
#

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    print $FH "    def _skel_",$node->{py_name},"(self, request):\n";
    print $FH "        \"\"\" Operation ",$node->{repos_id}," \"\"\"\n" if ($node->{py_name} !~ /^_/);
    print $FH "        reply_body = CDR.OutputBuffer()\n";
    if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}})) {
        print $FH "        _params = []\n";
        print $FH "        try:\n";
        foreach (@{$node->{list_param}}) {      # parameter
            next if ($_->{attr} eq 'out');
            my $type = $self->_get_defn($_->{type});
            if (exists $type->{full}) {
                print $FH "            _params.append(",$self->_get_scoped_name($type, $self->{itf}),".demarshal(request))\n";
            }
            else {
                my $type_name = $type->{value};
                $type_name =~ s/ /_/g;
                print $FH "            _params.append(CORBA.demarshal(request, '",$type_name,"'))\n";
            }
        }
        print $FH "        except:\n";
        print $FH "            CORBA.marshal(reply_body, 'string', 'IDL:CORBA/BAD_PARAM:1.0')\n";
        print $FH "            CORBA.marshal(reply_body, 'unsigned_long', 2)\n";
        print $FH "            CORBA.marshal(reply_body, 'unsigned_long', 1)    # COMPLETED_NO \n";
        print $FH "            return (GIOP.SYSTEM_EXCEPTION, reply_body)\n";
    }
    if (exists $node->{modifier}) {     # oneway
        if (scalar(@{$node->{list_in}})) {
            print $FH "        self.",$node->{py_name},"(_params)\n";
        }
        else {
            print $FH "        self.",$node->{py_name},"()\n";
        }
        print $FH "        return (None, None)\n";
    }
    else {
        print $FH "        try:\n";
        my $first = 1;
        my $nb = 0;
        my $ret = q{};
        my $type = $self->_get_defn($node->{type});
        unless ($type->isa('VoidType')) {
            $ret = '_return';
            $nb ++;
            $first = 0;
        }
        foreach (@{$node->{list_param}}) {      # paramater
            next if ($_->{attr} eq 'in');
            $ret .= ', ' unless ($first);
            $ret .= $_->{py_name};
            $nb ++;
            $first = 0;
        }
        if ($nb > 1) {
            $ret = '(' . $ret . ')';
        }
        if ($nb) {
            if (scalar(@{$node->{list_in}}) + scalar(@{$node->{list_inout}})) {
                print $FH "            ",$ret," = self.",$node->{py_name},"(*_params)\n";
            }
            else {
                print $FH "            ",$ret," = self.",$node->{py_name},"()\n";
            }
            print $FH "            try:\n";
            unless ($type->isa('VoidType')) {
                if (exists $type->{full}) {
                    print $FH "                _return.marshal(reply_body)\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH "                CORBA.marshal(reply_body, '",$type_name,"', _return)\n";
                }
            }
            foreach (@{$node->{list_param}}) {  # parameter
                next if ($_->{attr} eq 'in');
                $type = $self->_get_defn($_->{type});
                if (exists $type->{full}) {
                    print $FH "                ",$_->{py_name},".marshal(reply_body)\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH "                CORBA.marshal(reply_body, '",$type_name,"', ",$_->{py_name},")\n";
                }
            }
            print $FH "            except:\n";
            print $FH "                reply_body = CDR.OutputBuffer()  # reset\n";
            print $FH "                CORBA.marshal(reply_body, 'string', 'IDL:CORBA/MARSHAL:1.0')\n";
            print $FH "                CORBA.marshal(reply_body, 'unsigned_long', 9)\n";
            print $FH "                CORBA.marshal(reply_body, 'unsigned_long', 2)  # COMPLETED_MAYBE \n";
            print $FH "                return (GIOP.SYSTEM_EXCEPTION, reply_body)\n";
        }
        else {
            if (scalar(@{$node->{list_in}})) {
                print $FH "            self.",$node->{py_name},"(*_params)\n";
            }
            else {
                print $FH "            self.",$node->{py_name},"()\n";
            }
        }
        print $FH "            return (GIOP.NO_EXCEPTION, reply_body)\n";
        foreach (@{$node->{list_raise}}) {
            my $defn = $self->_get_defn($_);
            print $FH "        except ",$self->_get_scoped_name($defn, $self->{itf}),", e:\n";
            print $FH "            try:\n";
            print $FH "                CORBA.marshal(reply_body, 'string', e.corba_id())\n";
            if (exists $defn->{list_expr}) {
                print $FH "                e.marshal(reply_body)\n";
            }
            print $FH "            except:\n";
            print $FH "                reply_body = CDR.OutputBuffer()  # reset\n";
            print $FH "                CORBA.marshal(reply_body, 'string', 'IDL:CORBA/MARSHAL:1.0')\n";
            print $FH "                CORBA.marshal(reply_body, 'unsigned_long', 9)\n";
            print $FH "                CORBA.marshal(reply_body, 'unsigned_long', 2)  # COMPLETED_MAYBE \n";
            print $FH "                return (GIOP.SYSTEM_EXCEPTION, reply_body)\n";
            print $FH "            return (GIOP.USER_EXCEPTION, reply_body)\n";
        }
        print $FH "        except CORBA.SystemException, e:\n";
        print $FH "            CORBA.marshal(reply_body, 'string', e.repos_id)\n";
        print $FH "            CORBA.marshal(reply_body, 'unsigned_long', e.minor)\n";
        print $FH "            CORBA.marshal(reply_body, 'unsigned_long', e.completed)\n";
        print $FH "            return (GIOP.SYSTEM_EXCEPTION, reply_body)\n";
    }
    print $FH "\n";
}

#
#   3.14    Attribute Declaration       (inherited)
#

1;

