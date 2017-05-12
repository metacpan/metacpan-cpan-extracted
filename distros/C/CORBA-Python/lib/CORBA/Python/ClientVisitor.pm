
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Python::ClientVisitor;

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
    $self->{client} = 1;
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
                    . "import PyIDL.rpc_giop as RPC_GIOP\n"
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
        print $FH "class ",$node->{py_name};
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
        print $FH "class ",$node->{py_name},"(";
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
    print $FH "    def __init__(self, conn):\n";
    print $FH "        self.conn = conn\n";
    print $FH "        if not hasattr(conn, 'send'):\n";
    print $FH "            raise CORBA.SystemException('IDL:CORBA/INITIALIZE:1.0', 10, CORBA.CORBA_COMPLETED_NO)\n";
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
        print $FH "class ",$node->{py_name};
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
        print $FH "class ",$node->{py_name},"(";
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
    print $FH "    def __init__(self, *args, **kwargs):\n";
    print $FH "        raise CORBA.SystemException('IDL:CORBA/INITIALIZE:1.0', 10, CORBA.CORBA_COMPLETED_NO)\n";
    print $FH "\n";
    $self->{repos_id} = $node->{repos_id};
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
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
    print $FH "    def ",$node->{py_name},"(self, *args):\n";
    print $FH "        \"\"\" Operation ",$node->{repos_id}," \"\"\"\n" if ($node->{py_name} !~ /^_/);
    print $FH "        (request_header, request_body) = self._",$node->{py_name},"__marshal_request(*args)\n";
    if (exists $node->{modifier}) {     # oneway
        print $FH "        RPC_GIOP.RequestOneWay(self.conn, request_header, request_body)       # oneway\n";
    }
    else {
        print $FH "        (status, service_context, reply) = RPC_GIOP.RequestReply(self.conn, request_header, request_body)\n";
        print $FH "        return self._",$node->{py_name},"__demarshal_reply(status, service_context, reply)\n";
    }
    print $FH "\n";

    print $FH "    def _",$node->{py_name},"__marshal_request(self";
    foreach (@{$node->{list_param}}) {      # paramater
        if ( $_->{attr} eq 'in' or $_->{attr} eq 'inout') {
            print $FH ", ",$_->{py_name};
        }
    }
    print $FH "):\n";
    print $FH "        _request_header = GIOP.RequestHeader_1_2(\n";
    print $FH "            request_id=0,       # overloaded by RPC_GIOP.Request* \n";
    if (exists $node->{modifier}) {     # oneway
        print $FH "            response_flags=0,       # NONE\n";
    }
    else {
        print $FH "            response_flags=3,       # WITH_TARGET\n";
    }
    print $FH "            reserved='\\0\\0\\0',\n";
    print $FH "            target=GIOP.TargetAddress(object_key=self._get_id()),\n";
    print $FH "            operation='",$node->{idf},"',\n";
    print $FH "            service_context=IOP.ServiceContextList([])\n";
    print $FH "        )\n";
    print $FH "        _request_body = CDR.OutputBuffer()\n";
    foreach (@{$node->{list_param}}) {      # paramater
        next if ($_->{attr} eq 'out');
        my $type = $self->_get_defn($_->{type});
        if (exists $type->{full}) {
            print $FH "        ",$_->{py_name},".marshal(_request_body)\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH "        CORBA.marshal(_request_body, '",$type_name,"', ",$_->{py_name},")\n";
        }
    }
    print $FH "        return (_request_header, _request_body)\n";
    print $FH "\n";

    unless (exists $node->{modifier}) {     # !oneway
        print $FH "    def _",$node->{py_name},"__demarshal_reply(self, _status, _service_context, _reply):\n";
        print $FH "        if _status == GIOP.NO_EXCEPTION:\n";
        my $nb = 0;
        my $type = $self->_get_defn($node->{type});
        unless ($type->isa('VoidType')) {
            if (exists $type->{full}) {
                print $FH "            _return = ",$self->_get_scoped_name($type, $self->{itf}),".demarshal(_reply)\n";
            }
            else {
                my $type_name = $type->{value};
                $type_name =~ s/ /_/g;
                print $FH "            _return = CORBA.demarshal(_reply, '",$type_name,"')\n";
            }
            $nb ++;
        }
        foreach (@{$node->{list_param}}) {      # paramater
            next if ($_->{attr} eq 'in');
            $type = $self->_get_defn($_->{type});
            if (exists $type->{full}) {
                print $FH "            ",$_->{py_name}," = ",$self->_get_scoped_name($type, $self->{itf}),".demarshal(_reply)\n";
            }
            else {
                my $type_name = $type->{value};
                $type_name =~ s/ /_/g;
                print $FH "            ",$_->{py_name}," = CORBA.demarshal(_reply, '",$type_name,"')\n";
            }
            $nb ++;
        }
        print $FH "            return";
        print $FH " " if ($nb > 0);
        print $FH "(" if ($nb > 1);
        my $first = 1;
        $type = $self->_get_defn($node->{type});
        unless ($type->isa('VoidType')) {
            print $FH "_return";
            $first = 0;
        }
        foreach (@{$node->{list_param}}) {      # paramater
            next if ($_->{attr} eq 'in');
            print $FH ", " unless ($first);
            print $FH $_->{py_name};
            $first = 0;
        }
        print $FH ")" if ($nb > 1);
        print $FH "\n";
        print $FH "        elif _status == GIOP.USER_EXCEPTION:\n";
        print $FH "            _exception_id = CORBA.demarshal(_reply, 'string')\n";
        if (exists $node->{list_raise}) {
            my $if_elif = 'if';
            foreach (@{$node->{list_raise}}) {
                my $defn = $self->_get_defn($_);
                print $FH "            ",$if_elif," _exception_id == '",$defn->{repos_id},"':\n";
                print $FH "                _exception = ",$self->_get_scoped_name($defn, $self->{itf}),".demarshal(_reply)\n";
                print $FH "                raise _exception\n";
                $if_elif = 'elif';
            }
            print $FH "            else:\n";
            print $FH "                raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
        else {
            print $FH "            raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
        print $FH "        elif _status == GIOP.SYSTEM_EXCEPTION:\n";
        print $FH "            _exception_id = CORBA.demarshal(_reply, 'string')\n";
        print $FH "            _minor_code_value = CORBA.demarshal(_reply, 'unsigned_long')\n";
        print $FH "            _completion_status = CORBA.demarshal(_reply, 'unsigned_long')\n";
        print $FH "            raise CORBA.SystemException(\n";
        print $FH "                _exception_id,\n";
        print $FH "                _minor_code_value,\n";
        print $FH "                _completion_status\n";
        print $FH "            )\n";
        print $FH "        else:\n";
        print $FH "            raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
        print $FH "\n";
    }
}

#
#   3.14    Attribute Declaration
#

sub visitAttribute {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    $node->{_get}->visit($self);
    $node->{_set}->visit($self) if (exists $node->{_set});
    if (exists $node->{modifier}) {     # readonly
        print $FH "    ",$node->{py_name}," = property(fget=_get_",$node->{py_name},")\n";
    }
    else {
        print $FH "    ",$node->{py_name}," = property(fset=_set_",$node->{py_name},", fget=_get_",$node->{py_name},")\n";
    }
    print $FH "\n";
}

1;

