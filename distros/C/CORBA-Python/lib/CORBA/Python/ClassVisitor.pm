
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#
#           Python Language Mapping Specification, Version 1.2 November 2002
#

package CORBA::Python::ClassVisitor;

use strict;
use warnings;

our $VERSION = '2.66';

use File::Basename;
use IO::File;
use File::Path;
use POSIX qw(ctime);

# needs $node->{py_name} $node->{py_literal}

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
                    . "\n";
    $self->{import_substitution} = {};
    return $self;
}

sub open_stream {
    my $self = shift;
    my ($filename, $node, $doc_string) = @_;
    my $dirname = dirname($filename);
    if ($dirname ne '.') {
        unless (-d $dirname) {
            mkpath($dirname)
                    or die "can't create $dirname ($!).\n";
        }
    }
    my $py_module = $filename;
    $py_module =~ s/\.py$//;
    $py_module =~ s/\//\./g;
    $self->{module} = $py_module;
    $self->{out} = new IO::File "> $filename"
            or die "can't open $filename ($!).\n";
    $self->{filename} = $filename;
    my $FH = $self->{out};
    print $FH "# ex: set ro:\n";
    print $FH "#   This file was generated (by ",basename($0),"). DO NOT modify it.\n";
    print $FH "# From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH "\n";
    if (defined $doc_string) {
        print $FH $doc_string,"\n";
        print $FH "\n";
    }
    print $FH $self->{import};
    foreach my $name (sort keys %{$node->{py_import}}) {
        if ($name eq '::CORBA') {
            print $FH "import PyIDL as CORBA\n";
            next;
        }
        if ($name eq '::IOP') {
            print $FH "import PyIDL.iop as IOP\n";
            next;
        }
        if ($name eq '::GIOP') {
            print $FH "import PyIDL.giop as GIOP\n";
            next;
        }
        if ( $name eq '::' or $name eq q{} ) {
            if ($self->{base_package}) {
                if (exists $self->{server}) {
                    $name = $self->{base_package} . '_skel';
                }
                else {
                    $name = $self->{base_package};
                }
                $name =~ s/\//\./g;
            }
            else {
                my $basename = basename($self->{srcname}, '.idl');
                $basename =~ s/\./_/g;
                if (exists $self->{server}) {
                    $name = '_' . $basename . '_skel';
                }
                else {
                    $name = '_' . $basename;
                }
            }
        }
        else {
            $name =~ s/^:://;
            if (exists $self->{server}) {
                $name =~ s/::/_skel\./g;
                $name .= '_skel';
            }
            else {
                $name =~ s/::/\./g;
            }
            if ($self->{base_package}) {
                my $full_import_name = $self->{base_package} . '.' . $name;
                $full_import_name =~ s/\//\./g;
                $self->{import_substitution}->{$name} = $full_import_name;
                $name = $full_import_name;
            }
        }
        print $FH "import ",$name,"\n";
    }
    print $FH "\n";
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

sub _get_scoped_name {
    my $self = shift;
    my ($node, $scope, $flag) = @_;
    my $scope_full = $scope->{full};
    $scope_full =~ s/::[0-9A-Z_a-z]+$//;
    my $name = $node->{full};
    if ($name eq $scope_full) {
        $name = $node->{py_name};
    }
    elsif ($name =~ /^::[0-9A-Z_a-z]+$/) {
        if ($scope_full) {
            my $basename = basename($self->{srcname}, '.idl');
            $basename =~ s/\./_/g;
            if (exists $self->{server}) {
                $name = '_' . $basename . '_skel.' . $node->{py_name};
            }
            else {
                $name = '_' . $basename . '.' . $node->{py_name};
            }
        }
        else {
            $name = $node->{py_name};
        }
    }
    else {
        if ($scope_full) {
            my $defn = $self->{symbtab}->Lookup($scope_full);
            while (!$defn->isa('Modules') and !$flag) {
                $scope_full =~ s/::[0-9A-Z_a-z]+$//;
                last unless ($scope_full);
                $defn = $self->{symbtab}->Lookup($scope_full);
            }
            $name =~ s/^$scope_full//;
            $name =~ s/^:://;
            if (exists $self->{server}) {
                $name =~ s/::/_skel\./;
            }
            $name =~ s/::/\./g;
            if ($self->{base_package}) {
                my $import_name = $name;
                $import_name =~ s/\.[0-9A-Z_a-z]+$//;
                if (exists $self->{import_substitution}->{$import_name}) {
                    $name =~ s/$import_name/$self->{import_substitution}->{$import_name}/;
                }
            }
        }
        else {
            my $name2 = $node->{py_name};
            $name =~ s/::[0-9A-Z_a-z]+$//;
            while ($name) {
                my $defn = $self->{symbtab}->Lookup($name);
                if ($defn->isa('Interface') and exists $self->{server}) {
                    $name2 = $defn->{py_name} . '_skel.' . $name2;
                }
                else {
                    $name2 = $defn->{py_name} . '.' . $name2;
                }
                $name =~ s/::[0-9A-Z_a-z]+$//;
            }
            $name = $name2;
        }
    }
    return $name;
}

sub _setup_py {
    my $self = shift;
    my $filename = (exists $self->{server}) ? 'setup_skel.py' : 'setup.py';
    open my $FH, '>', $filename
            or die "can't open $filename ($!).\n";

    print $FH "#   This file was generated (by ",basename($0),"). DO NOT modify it.\n";
    print $FH "# From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH "\n";
    print $FH "from distutils.core import setup\n";
    print $FH "\n";
    print $FH "setup(\n";
    print $FH "    name = '",$self->{setup_name},"',\n";
    print $FH "    py_modules = [ '",$self->{setup_py_modules},"' ],\n"
            if ($self->{setup_py_modules});
    print $FH "    packages = [ '",join("', '", @{$self->{setup_packages}}),"' ],\n"
            if (scalar @{$self->{setup_packages}});
    print $FH ")\n";
    print $FH "\n";
    close $FH;
}

sub empty_modules {
    my $self = shift;
    return unless ($self->{base_package});
    my $dirname = $self->{base_package};
    unless (-d $dirname) {
        mkpath($dirname)
                or die "can't create $dirname ($!).\n";
    }
    while ($dirname ne '.') {
        my $filename = $dirname . '/__init__.py';
        unless (-e $filename) {
            open my $FH, '>', $filename
                    or die "can't open $filename ($!).\n";
            close $FH;
        }
        $dirname = dirname($dirname);
    }
}

#
#   3.5     OMG IDL Specification       (could be specialized)
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $setup_name;
    my $filename;
    my $empty;
    $self->empty_modules();
    $self->{setup_packages} = [];
    if ($self->{base_package}) {
        $setup_name = $self->{base_package};
        if (exists $self->{server}) {
            $setup_name .= '_skel';
        }
        $filename = $setup_name . '/__init__.py';
        $self->{setup_name} = $setup_name;
        push @{$self->{setup_packages}}, $setup_name;
    }
    else {
        my $basename = basename($self->{srcname}, '.idl');
        $basename =~ s/\./_/g;
        $setup_name = '_' . $basename;
        if (exists $self->{server}) {
            $setup_name .= '_skel';
        }
        $filename = $setup_name . '.py';
        $empty = 1;
        foreach (@{$node->{list_decl}}) {
            my $defn = $self->_get_defn($_);
            unless (   $defn->isa('Modules')
                    or $defn->isa('Import') ) {
                $empty = 0;
            }
        }
        unless ($empty) {
            $self->{setup_name} = $setup_name;
            $self->{setup_py_modules} = $setup_name;
        }
    }
    unless ($empty) {
        $self->open_stream($filename, $node);
    }
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    unless ($empty) {
        my $FH = $self->{out};
        print $FH "\n";
        print $FH "# Local variables:\n";
        print $FH "#   buffer-read-only: t\n";
        print $FH "# End:\n";
        close $FH;
    }
    $self->_setup_py();
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{full};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    my $save_out = $self->{out};
    my $defn = $self->{symbtab}->Lookup($node->{full});
    my $setup_name = $node->{full};
    $setup_name =~ s/^:://;
    if (exists $self->{server}) {
        $setup_name =~ s/::/_skel\//g;
        $setup_name .= '_skel';
    }
    else {
        $setup_name =~ s/::/\//g;
    }
    if ($self->{base_package}) {
        $setup_name = $self->{base_package} . '/' . $setup_name;
    }
    $self->{setup_name} = $setup_name unless ($self->{setup_name});
    push @{$self->{setup_packages}}, $setup_name;
    my $filename = $setup_name . '/__init__.py';
    my $doc_string = "\"\"\" Module " . $defn->{repos_id} . " \"\"\"";
    $self->open_stream($filename, $node, $doc_string);
    my $FH = $self->{out};
    foreach (@{$node->{list_decl}}) {
        $_->visit($self);
    }
    print $FH "\n";
    print $FH "# Local variables:\n";
    print $FH "#   buffer-read-only: t\n";
    print $FH "# End:\n";
    close $FH;
    $self->{out} = $save_out;
}

sub visitModule {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
}

#
#   3.8     Interface Declaration       (could be specialized)
#

sub visitBaseInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{indent} = q{ } x 4;
    print $FH "\n";
    print $FH "class ",$node->{py_name};
    if ($self->{old_object}) {
        print $FH ":\n";
    }
    else {
        print $FH "(object):\n";
    }
    print $FH "    \"\"\" ",ref $node,": ",$node->{repos_id}," \"\"\"\n";
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
    }
    print $FH "    def __init__(self):\n";
    print $FH "        pass\n";
    print $FH "\n";
    if ($self->{id}) {
        print $FH "    def _get_id(cls):\n";
        print $FH "        return '",$node->{repos_id},"'\n";
        print $FH "    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    $self->{indent} = q{};
}

sub visitForwardBaseInterface {
    # empty
}

sub visitRegularInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{indent} = q{ } x 4;
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
    print $FH "    def __init__(self):\n";
    print $FH "        pass\n";
    print $FH "\n";
    $self->{repos_id} = $node->{repos_id};
    foreach (@{$node->{list_decl}}) {
        my $defn = $self->_get_defn($_);
        if (       $defn->isa('Operation')
                or $defn->isa('Attributes') ) {
            next;
        }
        $defn->visit($self);
    }
    if ($self->{id}) {
        print $FH "    def _get_id(cls):\n";
        print $FH "        return '",$node->{repos_id},"'\n";
        print $FH "    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    foreach (sort keys %{$node->{hash_attribute_operation}}) {
        my $defn = $self->_get_defn(${$node->{hash_attribute_operation}}{$_});
        $defn->visit($self);
    }
    print $FH "\n";
    $self->{indent} = q{};
}

sub visitAbstractInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{indent} = q{ } x 4;
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
    print $FH "    def __init__(self):\n";
    print $FH "        pass\n";
    print $FH "\n";
    $self->{repos_id} = $node->{repos_id};
    foreach (@{$node->{list_decl}}) {
        my $defn = $self->_get_defn($_);
        if (       $defn->isa('Operation')
                or $defn->isa('Attributes') ) {
            next;
        }
        $defn->visit($self);
    }
    foreach (sort keys %{$node->{hash_attribute_operation}}) {
        my $defn = $self->_get_defn(${$node->{hash_attribute_operation}}{$_});
        $defn->visit($self);
    }
    $self->{indent} = q{};
}

#
#   3.10    Constant Declaration
#

sub visitConstant {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    print $FH $self->{indent},"# Constant: ",$node->{repos_id},"\n";
    print $FH $self->{indent},$node->{py_name}," = ",$node->{value}->{py_literal},"\n";
    print $FH "\n";
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
            or $type->isa('FixedPtType') ) {
        $type->visit($self);
    }
    my $FH = $self->{out};
    my $type2 = $type;
    while ($type2->isa('TypeDeclarator')) {
        $type2 = $self->_get_defn($type2->{type});
    }
    if ($type2->isa('EnumType')) {
        print $FH $self->{indent},"# Typedef: ",$node->{repos_id},"\n";
        print $FH $self->{indent},$node->{py_name}," = ",$self->_get_scoped_name($type, $node, 1),"\n";
        print $FH "\n";
        return;
    }
    if (exists $node->{array_size}) {
        if ( ( $type->isa('OctetType') or $type->isa('CharType') )
                and scalar(@{$node->{array_size}}) == 1 ) {
            if ($self->{old_object}) {
                print $FH $self->{indent},"class ",$node->{py_name},":\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __init__(self, val):\n";
                print $FH $self->{indent},"        self._value = str(val)\n";
                print $FH $self->{indent},"        if len(self._value) != ",${$node->{array_size}}[0]->{py_literal},":\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __cmp__(self, val):\n";
                print $FH $self->{indent},"        return cmp(self._value, val)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __nonzero__(self):\n";
                print $FH $self->{indent},"        return bool(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __str__(self):\n";
                print $FH $self->{indent},"        return str(self._value)\n";
                print $FH "\n";
                if ($self->{marshal}) {
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},"        CORBA.marshal(output, 'string', self._value)\n";
                    print $FH "\n";
                }
            }
            else {
                print $FH $self->{indent},"class ",$node->{py_name},"(str):\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __init__(self, val):\n";
                print $FH $self->{indent},"        if not isinstance(val, str):\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                print $FH $self->{indent},"        if len(val) != ",${$node->{array_size}}[0]->{py_literal},":\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                print $FH $self->{indent},"        str.__init__(val)\n";
                print $FH "\n";
                if ($self->{marshal}) {
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},"        for elt in self:\n";
                    if ($type->isa('OctetType')) {
                        print $FH $self->{indent},"            CORBA.marshal(output, 'octet', ord(elt))\n";
                    }
                    else {
                        print $FH $self->{indent},"            CORBA.marshal(output, 'char', elt)\n";
                    }
                    print $FH "\n";
                }
            }
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def demarshal(cls, input_):\n";
                print $FH $self->{indent},"        lst = []\n";
                print $FH $self->{indent},"        for _ in xrange(",${$node->{array_size}}[0]->{py_literal},"):\n";
                print $FH $self->{indent},"            lst.append(CORBA.demarshal(input_, '",$type->{value},"'))\n";
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},"        val = ''.join(map(chr, lst))\n";
                }
                else {
                    print $FH $self->{indent},"        val = ''.join(lst)\n";
                }
                print $FH $self->{indent},"        return cls(val)\n";
                print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
                print $FH "\n";
            }
        }
        else {
            my @array_max = ();
            while ($type->isa('SequenceType')) {
                if (exists $type->{max}) {
                    push @array_max, $type->{max};
                }
                else {
                    push @array_max, undef;
                }
                $type = $self->_get_defn($type->{type});
            }
            if ($self->{old_object}) {
                print $FH $self->{indent},"class ",$node->{py_name},":\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                my $n = 0;
                my @tab = (q{ } x 8);
                print $FH $self->{indent},"    def __init__(self, *params):\n";
                print $FH $self->{indent},"        self._value = list(*params)\n";
                print $FH $self->{indent},@tab,"_e",$n," = self._value\n";
                foreach (@{$node->{array_size}}) {
                    print $FH $self->{indent},@tab,"if len(_e",$n,") != ",$_->{py_literal},":\n";
                    print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                foreach (@array_max) {
                    if (defined $_) {
                        print $FH $self->{indent},@tab,"if len(_e",$n,") > ",$_->{py_literal},":\n";
                        print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    }
                    print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.check('octet', ord(_e",$n,"))\n";
                }
                elsif (exists $type->{full}) {
                    print $FH $self->{indent},@tab,"CORBA.check(",$self->_get_scoped_name($type, $node),", _e",$n,")\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH $self->{indent},@tab,"CORBA.check('",$type_name,"', _e",$n,")\n";
                }
                print $FH "\n";
                print $FH $self->{indent},"    def __cmp__(self, val):\n";
                print $FH $self->{indent},"        return cmp(self._value, val)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __contains__(self, elt):\n";
                print $FH $self->{indent},"        return elt in self._value, val\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __len__(self):\n";
                print $FH $self->{indent},"        return len(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __nonzero__(self):\n";
                print $FH $self->{indent},"        return bool(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __str__(self):\n";
                print $FH $self->{indent},"        return str(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __getitem__(self, key):\n";
                print $FH $self->{indent},"        return self._value[key]\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __setitem__(self, key, val):\n";
                print $FH $self->{indent},"        self._value[key] = val\n";
                print $FH "\n";
                if ($self->{marshal}) {
                    $n = 0;
                    @tab = (q{ } x 8);
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},@tab,"_e",$n," = self._value\n";
                    foreach (@{$node->{array_size}}) {
                        print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                        $n ++;
                        push @tab, q{ } x 4;
                    }
                    foreach (@array_max) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'long', len(_e",$n,"))\n";
                        print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                        $n ++;
                        push @tab, q{ } x 4;
                    }
                    if ($type->isa('OctetType')) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'octet', ord(_e",$n,"))\n";
                    }
                    elsif (exists $type->{full}) {
                        print $FH $self->{indent},@tab,"_e",$n,".marshal(output)\n";
                    }
                    else {
                        my $type_name = $type->{value};
                        $type_name =~ s/ /_/g;
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, '",$type_name,"', _e",$n,")\n";
                    }
                    print $FH "\n";
                }
            }
            else {
                print $FH $self->{indent},"class ",$node->{py_name},"(list):\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                my $n = 0;
                my @tab = (q{ } x 8);
                print $FH $self->{indent},"    def __init__(self, *params):\n";
                print $FH $self->{indent},"        list.__init__(self, *params)\n";
                print $FH $self->{indent},@tab,"_e",$n," = list(*params)\n";
                foreach (@{$node->{array_size}}) {
                    print $FH $self->{indent},@tab,"if len(_e",$n,") != ",$_->{py_literal},":\n";
                    print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                foreach (@array_max) {
                    if (defined $_) {
                        print $FH $self->{indent},@tab,"if len(_e",$n,") > ",$_->{py_literal},":\n";
                        print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    }
                    print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.check('octet', ord(_e",$n,"))\n";
                }
                elsif (exists $type->{full}) {
                    print $FH $self->{indent},@tab,"CORBA.check(",$self->_get_scoped_name($type, $node),", _e",$n,")\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH $self->{indent},@tab,"CORBA.check('",$type_name,"', _e",$n,")\n";
                }
                print $FH "\n";
                if ($self->{marshal}) {
                    $n = 0;
                    @tab = (q{ } x 8);
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},@tab,"_e",$n," = self\n";
                    foreach (@{$node->{array_size}}) {
                        print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                        $n ++;
                        push @tab, q{ } x 4;
                    }
                    foreach (@array_max) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'long', len(_e",$n,"))\n";
                        print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                        $n ++;
                        push @tab, q{ } x 4;
                    }
                    if ($type->isa('OctetType')) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'octet', ord(_e",$n,"))\n";
                    }
                    elsif (exists $type->{full}) {
                        print $FH $self->{indent},@tab,"_e",$n,".marshal(output)\n";
                    }
                    else {
                        my $type_name = $type->{value};
                        $type_name =~ s/ /_/g;
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, '",$type_name,"', _e",$n,")\n";
                    }
                    print $FH "\n";
                }
            }
            if ($self->{marshal}) {
                my $n = 0;
                my @tab = (q{ } x 8);
                print $FH $self->{indent},"    def demarshal(cls, input_):\n";
                foreach (@{$node->{array_size}}) {
                    print $FH $self->{indent},@tab,"_lst",$n," = []\n";
                    print $FH $self->{indent},@tab,"for _i",$n," in xrange(",$_->{py_literal},"):\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                foreach (@array_max) {
                    print $FH $self->{indent},@tab,"_len",$n," = CORBA.demarshal(input_, 'long')\n";
                    if (defined $_) {
                        print $FH $self->{indent},@tab,"if _len",$n," > ",$_->{py_literal},":\n";
                        print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    }
                    print $FH $self->{indent},@tab,"_lst",$n," = []\n";
                    print $FH $self->{indent},@tab,"for _i",$n," in xrange(_len",$n,"):\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                $n --;
                if (exists $type->{full}) {
                    print $FH $self->{indent},@tab,"_lst",$n,".append(",$self->_get_scoped_name($type, $node),".demarshal(input_))\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH $self->{indent},@tab,"_lst",$n,".append(CORBA.demarshal(input_, '",$type_name,"'))\n";
                }
                pop @tab;
                if ($type->isa('CharType')) {
                    print $FH $self->{indent},@tab,"_lst",$n," = ''.join(_lst",$n,")\n";
                }
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"_lst",$n," = ''.join(map(chr, _lst",$n,"))\n";
                }
                while ($n > 0) {
                    print $FH $self->{indent},@tab,"_lst",$n - 1,".append(_lst",$n,")\n";
                    $n --;
                    pop @tab;
                }
                print $FH $self->{indent},@tab,"return cls(_lst0)\n";
                print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
                print $FH "\n";
            }
        }
    }
    elsif ($type->isa('SequenceType')) {
        my @array_max = ();
        while ($type->isa('SequenceType')) {
            if (exists $type->{max}) {
                push @array_max, $type->{max};
            }
            else {
                push @array_max, undef;
            }
            $type = $self->_get_defn($type->{type});
        }
        if ( ( $type->isa('OctetType') or $type->isa('CharType') )
                and scalar(@array_max) == 1 ) {
            if ($self->{old_object}) {
                print $FH $self->{indent},"class ",$node->{py_name},":\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __init__(self, val):\n";
                print $FH $self->{indent},"        self._value = str(val)\n";
                if (defined $array_max[0]) {
                    print $FH $self->{indent},"        if len(self._value) > ",$array_max[0]->{py_literal},":\n";
                    print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                }
                print $FH "\n";
                print $FH $self->{indent},"    def __cmp__(self, val):\n";
                print $FH $self->{indent},"        return cmp(self._value, val)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __nonzero__(self):\n";
                print $FH $self->{indent},"        return bool(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __str__(self):\n";
                print $FH $self->{indent},"        return str(self._value)\n";
                print $FH "\n";
                if ($self->{marshal}) {
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},"        CORBA.marshal(output, 'string', self._value)\n";
                    print $FH "\n";
                }
            }
            else {
                print $FH $self->{indent},"class ",$node->{py_name},"(str):\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __init__(self, val):\n";
                print $FH $self->{indent},"        if val != None:\n";
                print $FH $self->{indent},"            if not isinstance(val, str):\n";
                print $FH $self->{indent},"                raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                if (defined $array_max[0]) {
                    print $FH $self->{indent},"            if len(val) > ",$array_max[0]->{py_literal},":\n";
                    print $FH $self->{indent},"                raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                }
                print $FH $self->{indent},"        str.__init__(val)\n";
                print $FH "\n";
                if ($self->{marshal}) {
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},"        CORBA.marshal(output, 'long', len(self))\n";
                    print $FH $self->{indent},"        for elt in self:\n";
                    if ($type->isa('OctetType')) {
                        print $FH $self->{indent},"            CORBA.marshal(output, 'octet', ord(elt))\n";
                    }
                    else {
                        print $FH $self->{indent},"            CORBA.marshal(output, 'char', elt)\n";
                    }
                    print $FH "\n";
                }
            }
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def demarshal(cls, input_):\n";
                print $FH $self->{indent},"        length = CORBA.demarshal(input_, 'long')\n";
                print $FH $self->{indent},"        lst = []\n";
                print $FH $self->{indent},"        for _ in xrange(length):\n";
                print $FH $self->{indent},"            lst.append(CORBA.demarshal(input_, '",$type->{value},"'))\n";
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},"        val = ''.join(map(chr, lst))\n";
                }
                else {
                    print $FH $self->{indent},"        val = ''.join(lst)\n";
                }
                print $FH $self->{indent},"        return cls(val)\n";
                print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
                print $FH "\n";
            }
        }
        else {
            if ($self->{old_object}) {
                print $FH $self->{indent},"class ",$node->{py_name},":\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                my $n = 0;
                my @tab = (q{ } x 8);
                print $FH $self->{indent},"    def __init__(self, *params):\n";
                print $FH $self->{indent},"        self._value = list(*params)\n";
                print $FH $self->{indent},@tab,"_e",$n," = self._value\n";
                foreach (@array_max) {
                    if (defined $_) {
                        print $FH $self->{indent},@tab,"if len(_e",$n,") > ",$_->{py_literal},":\n";
                            print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    }
                    print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.check('octet', ord(_e",$n,"))\n";
                }
                elsif (exists $type->{full}) {
                    print $FH $self->{indent},@tab,"CORBA.check(",$self->_get_scoped_name($type, $node),", _e",$n,")\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH $self->{indent},@tab,"CORBA.check('",$type_name,"', _e",$n,")\n";
                }
                print $FH "\n";
                print $FH $self->{indent},"    def __cmp__(self, val):\n";
                print $FH $self->{indent},"        return cmp(self._value, val)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __contains__(self, elt):\n";
                print $FH $self->{indent},"        return elt in self._value, val\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __len__(self):\n";
                print $FH $self->{indent},"        return len(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __nonzero__(self):\n";
                print $FH $self->{indent},"        return bool(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __str__(self):\n";
                print $FH $self->{indent},"        return str(self._value)\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __getitem__(self, key):\n";
                print $FH $self->{indent},"        return self._value[key]\n";
                print $FH "\n";
                print $FH $self->{indent},"    def __setitem__(self, key, val):\n";
                print $FH $self->{indent},"        self._value[key] = val\n";
                print $FH "\n";
                if ($self->{marshal}) {
                    $n = 0;
                    @tab = (q{ } x 8);
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},@tab,"_e",$n," = self._value\n";
                    foreach (@array_max) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'long', len(_e",$n,"))\n";
                        print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                        $n ++;
                        push @tab, q{ } x 4;
                    }
                    if ($type->isa('OctetType')) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'octet', ord(_e",$n,"))\n";
                    }
                    elsif (exists $type->{full}) {
                        print $FH $self->{indent},@tab,"_e",$n,".marshal(output)\n";
                    }
                    else {
                        my $type_name = $type->{value};
                        $type_name =~ s/ /_/g;
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, '",$type_name,"', _e",$n,")\n";
                    }
                    print $FH "\n";
                }
            }
            else {
                print $FH $self->{indent},"class ",$node->{py_name},"(list):\n";
                print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
                print $FH "\n";
                my $n = 0;
                my @tab = (q{ } x 8);
                print $FH $self->{indent},"    def __init__(self, *params):\n";
                print $FH $self->{indent},"        list.__init__(self, *params)\n";
                print $FH $self->{indent},@tab,"_e",$n," = list(*params)\n";
                foreach (@array_max) {
                    if (defined $_) {
                        print $FH $self->{indent},@tab,"if len(_e",$n,") > ",$_->{py_literal},":\n";
                            print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    }
                    print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.check('octet', ord(_e",$n,"))\n";
                }
                elsif (exists $type->{full}) {
                    print $FH $self->{indent},@tab,"CORBA.check(",$self->_get_scoped_name($type, $node),", _e",$n,")\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH $self->{indent},@tab,"CORBA.check('",$type_name,"', _e",$n,")\n";
                }
                print $FH "\n";
                if ($self->{marshal}) {
                    $n = 0;
                    @tab = (q{ } x 8);
                    print $FH $self->{indent},"    def marshal(self, output):\n";
                    print $FH $self->{indent},@tab,"_e",$n," = self\n";
                    foreach (@array_max) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'long', len(_e",$n,"))\n";
                        print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
                        $n ++;
                        push @tab, q{ } x 4;
                    }
                    if ($type->isa('OctetType')) {
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, 'octet', ord(_e",$n,"))\n";
                    }
                    elsif (exists $type->{full}) {
                        print $FH $self->{indent},@tab,"_e",$n,".marshal(output)\n";
                    }
                    else {
                        my $type_name = $type->{value};
                        $type_name =~ s/ /_/g;
                        print $FH $self->{indent},@tab,"CORBA.marshal(output, '",$type_name,"', _e",$n,")\n";
                    }
                    print $FH "\n";
                }
            }
            if ($self->{marshal}) {
                my $n = 0;
                my @tab = (q{ } x 8);
                print $FH $self->{indent},"    def demarshal(cls, input_):\n";
                foreach (@array_max) {
                    print $FH $self->{indent},@tab,"_len",$n," = CORBA.demarshal(input_, 'long')\n";
                    if (defined $_) {
                        print $FH $self->{indent},@tab,"if _len",$n," > ",$_->{py_literal},":\n";
                        print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
                    }
                    print $FH $self->{indent},@tab,"_lst",$n," = []\n";
                    print $FH $self->{indent},@tab,"for _i",$n," in xrange(_len",$n,"):\n";
                    $n ++;
                    push @tab, q{ } x 4;
                }
                $n --;
                if (exists $type->{full}) {
                    print $FH $self->{indent},@tab,"_lst",$n,".append(",$self->_get_scoped_name($type, $node),".demarshal(input_))\n";
                }
                else {
                    my $type_name = $type->{value};
                    $type_name =~ s/ /_/g;
                    print $FH $self->{indent},@tab,"_lst",$n,".append(CORBA.demarshal(input_, '",$type_name,"'))\n";
                }
                pop @tab;
                if ($type->isa('CharType')) {
                    print $FH $self->{indent},@tab,"_lst",$n," = ''.join(_lst",$n,")\n";
                }
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"_lst",$n," = ''.join(map(chr, _lst",$n,"))\n";
                }
                while ($n > 0) {
                    print $FH $self->{indent},@tab,"_lst",$n - 1,".append(_lst",$n,")\n";
                    $n --;
                    pop @tab;
                }
                print $FH $self->{indent},@tab,"return cls(_lst0)\n";
                print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
                print $FH "\n";
            }
        }
    }
    elsif ($type->isa('FixedPtType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(object):\n";
        }
        print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
        print $FH "\n";
        print $FH $self->{indent},"    # TODO\n";
        print $FH $self->{indent},"    pass\n";
        print $FH "\n";
    }
    elsif ($type->isa('StringType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = str(val)\n";
            if (exists $type->{max}) {
                print $FH $self->{indent},"        if len(self._value) > ",$type->{max}->{py_literal},":\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            }
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'string', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(str):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        if not isinstance(val, str):\n";
            print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            if (exists $type->{max}) {
                print $FH $self->{indent},"        if len(val) > ",$type->{max}->{py_literal},":\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            }
            print $FH $self->{indent},"        str.__init__(val)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'string', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, 'string')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif ($type->isa('WideStringType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            # TODO
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = str(val)\n";
            if (exists $type->{max}) {
                print $FH $self->{indent},"        if len(self._value) > ",$type->{max}->{py_literal},":\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            }
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'wstring', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(unicode):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        if not isinstance(val, basestring):\n";
            print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            if (exists $type->{max}) {
                print $FH $self->{indent},"        if len(val) > ",$type->{max}->{py_literal},":\n";
                print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            }
            print $FH $self->{indent},"        unicode.__init__(val)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'wstring', self)\n";
                print $FH "\n";
            }
        }
        print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
        print $FH "\n";
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, 'wstring')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif (  $type->isa('StructType')
            or $type->isa('UnionType')) {
        print $FH $self->{indent},"class ",$node->{py_name},"(",$self->_get_scoped_name($type, $node, 1),"):\n";
        print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
        print $FH "\n";
        print $FH $self->{indent},"    def __init__(self, *args, **kwargs):\n";
        print $FH $self->{indent},"        if len(args) == 1 and isinstance(args[0], ",$self->_get_scoped_name($type, $node),"):\n";
        print $FH $self->{indent},"            self.__dict__ = dict(args[0].__dict__)\n";
        print $FH $self->{indent},"        else:\n";
        print $FH $self->{indent},"            super(",$self->_get_scoped_name($node, $node),", self).__init__(*args, **kwargs)\n";
        print $FH "\n";
    }
    elsif (  $type->isa('TypeDeclarator')
            or $type->isa('BaseInterface') ) {
        print $FH $self->{indent},"class ",$node->{py_name},"(",$self->_get_scoped_name($type, $node, 1),"):\n";
        print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
        print $FH "\n";
    }
    elsif ($type->isa('FloatingPtType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = float(val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                my $value = $type->{value};
                $value =~ s/ /_/g;
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, '",$value,"', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(float):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            if ($self->{marshal}) {
                my $value = $type->{value};
                $value =~ s/ /_/g;
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, '",$value,"', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            my $value = $type->{value};
            $value =~ s/ /_/g;
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, '",$value,"')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif ($type->isa('IntegerType')) {
        my $value = $type->{value};
        $value =~ s/ /_/g;
        my $py_type;
        if (       $value eq 'short'
                or $value eq 'unsigned_short'
                or $value eq 'long' ) {
            $py_type = 'int';
        }
        else {
            $py_type = 'long';
        }
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = ",$py_type,"(val)\n";
            print $FH $self->{indent},"        CORBA.check('",$value,"', self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, '",$value,"', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(",$py_type,"):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        CORBA.check('",$value,"', val)\n";
            print $FH $self->{indent},"        ",$py_type,".__init__(val)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, '",$value,"', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, '",$value,"')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif ($type->isa('CharType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = str(val)\n";
            print $FH $self->{indent},"        CORBA.check('char', val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'char', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(str):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        CORBA.check('char', val)\n";
            print $FH $self->{indent},"        str.__init__(val)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'char', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, 'char')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif ($type->isa('WideCharType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        CORBA.check('wchar', self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'wchar', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(unicode):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        CORBA.check('wchar', val)\n";
            print $FH $self->{indent},"        unicode.__init__(val)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'wchar', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, 'wchar')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif ($type->isa('BooleanType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = bool(val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'boolean', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(int):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        int.__init__(bool(val))\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'boolean', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, 'boolean')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    elsif ($type->isa('OctetType')) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"class ",$node->{py_name},":\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        self._value = int(val)\n";
            print $FH $self->{indent},"        CORBA.check('octet', self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __cmp__(self, val):\n";
            print $FH $self->{indent},"        return cmp(self._value, val)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __nonzero__(self):\n";
            print $FH $self->{indent},"        return bool(self._value)\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __str__(self):\n";
            print $FH $self->{indent},"        return str(self._value)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'octet', self._value)\n";
                print $FH "\n";
            }
        }
        else {
            print $FH $self->{indent},"class ",$node->{py_name},"(int):\n";
            print $FH $self->{indent},"    \"\"\" Typedef ",$node->{repos_id}," \"\"\"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def __init__(self, val):\n";
            print $FH $self->{indent},"        CORBA.check('octet', val)\n";
            print $FH $self->{indent},"        int.__init__(val)\n";
            print $FH "\n";
            if ($self->{marshal}) {
                print $FH $self->{indent},"    def marshal(self, output):\n";
                print $FH $self->{indent},"        CORBA.marshal(output, 'octet', self)\n";
                print $FH "\n";
            }
        }
        if ($self->{marshal}) {
            print $FH $self->{indent},"    def demarshal(cls, input_):\n";
            print $FH $self->{indent},"        val = CORBA.demarshal(input_, 'octet')\n";
            print $FH $self->{indent},"        return cls(val)\n";
            print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
            print $FH "\n";
        }
    }
    else {
        warn __PACKAGE__,"::visitTypeDeclarator (",ref $type,").\n";
        return;
    }
    if ($self->{id}) {
        print $FH $self->{indent},"    def _get_id(cls):\n";
        print $FH $self->{indent},"        return '",$node->{repos_id},"'\n";
        print $FH $self->{indent},"    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    if (exists $node->{serial_uid}) {
        print $FH $self->{indent},"    def _get_uid(cls):\n";
        print $FH $self->{indent},"        return 0x",$node->{serial_uid},"L\n";
        print $FH $self->{indent},"    serial_uid = classmethod(_get_uid)\n";
        print $FH "\n";
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
    my $name = $node->{full};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    my $FH = $self->{out};
    if ($self->{old_object}) {
        print $FH $self->{indent},"class ",$node->{py_name},":\n";
    }
    else {
        print $FH $self->{indent},"class ",$node->{py_name},"(object):\n";
    }
    print $FH $self->{indent},"    \"\"\" Struct ",$node->{repos_id}," \"\"\"\n";
    print $FH "\n";
    foreach (@{$node->{list_expr}}) {
        my $indent = $self->{indent};
        $self->{indent} .= '    ';
        my $type = $self->_get_defn($_->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
        $self->{indent} = $indent;
    }
    print $FH $self->{indent},"    def __init__(self";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);          # member
        print $FH ", ",$member->{py_name};
    }
    print $FH "):\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);          # member
        print $FH $self->{indent},"        self._set",$member->{py_name},"(",$member->{py_name},")\n";
    }
    print $FH "\n";

    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);          # member
        print $FH $self->{indent},"    def _set",$member->{py_name},"(self, ",$member->{py_name},"):\n";
        $self->_member_check($member, $member->{py_name}, "        ", $node);
        print $FH $self->{indent},"        self._",$member->{py_name}," = ",$member->{py_name},"\n";
        print $FH "\n";
        print $FH $self->{indent},"    def _get",$member->{py_name},"(self):\n";
        print $FH $self->{indent},"        return self._",$member->{py_name},"\n";
        print $FH "\n";
        print $FH $self->{indent},"    ",$member->{py_name}," = property(fset=_set",$member->{py_name},", fget=_get",$member->{py_name},")\n";
        print $FH "\n";
    }
    if ($self->{marshal}) {
        print $FH $self->{indent},"    def marshal(self, output):\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            $self->_member_marshal($member, "self." . $member->{py_name});
        }
        print $FH "\n";
        print $FH $self->{indent},"    def demarshal(cls, input_):\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            $self->_member_demarshal($member, $node);
        }
        print $FH $self->{indent},"            return cls(";
        my $first = 1;
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            if ($first) {
                $first = 0;
            }
            else {
                print $FH ", ";
            }
            print $FH $member->{py_name};
        }
        print $FH ")\n";
        print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
        print $FH "\n";
    }
    if ($self->{compare}) {
        print $FH $self->{indent},"    def __eq__(self, obj):\n";
        print $FH $self->{indent},"        if obj == None:\n";
        print $FH $self->{indent},"            return False\n";
        print $FH $self->{indent},"        if not isinstance(obj, type(self)):\n";
        print $FH $self->{indent},"            return False\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            print $FH $self->{indent},"        if self.",$member->{py_name}," != obj.",$member->{py_name},":\n";
            print $FH $self->{indent},"            return False\n";
        }
        print $FH $self->{indent},"        return True\n";
        print $FH "\n";
        print $FH $self->{indent},"    def __ne__(self, obj):\n";
        print $FH $self->{indent},"        return not self.__eq__(obj)\n";
        print $FH "\n";
    }
    if ($self->{stringify}) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"    def __str__(self):\n";
        }
        else {
            print $FH $self->{indent},"    def __repr__(self):\n";
        }
        print $FH $self->{indent},"        lst = []\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            $self->_member_stringify($member);
        }
        print $FH $self->{indent},"        inner = ',\\n'.join(lst)\n";
        print $FH $self->{indent},"        inner = '\\n'.join(['   ' + line for line in inner.split('\\n')])\n";
        print $FH $self->{indent},"        return 'struct ",$node->{py_name}," {\\n' + inner + '\\n}'\n";
        print $FH "\n";
    }
    if ($self->{id}) {
        print $FH $self->{indent},"    def _get_id(cls):\n";
        print $FH $self->{indent},"        return '",$node->{repos_id},"'\n";
        print $FH $self->{indent},"    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    if (exists $node->{serial_uid}) {
        print $FH $self->{indent},"    def _get_uid(cls):\n";
        print $FH $self->{indent},"        return 0x",$node->{serial_uid},"L\n";
        print $FH $self->{indent},"    serial_uid = classmethod(_get_uid)\n";
        print $FH "\n";
    }
}

sub _member_check {
    my $self = shift;
    my ($member, $label, $tab, $node) = @_;

    my $type = $self->_get_defn($member->{type});
    my $FH = $self->{out};
    my @tab = ($tab);
    my $n = 0;
    my $m = 0;
    my $idx = q{};
    if (exists $member->{array_size}) {
        print $FH $self->{indent},@tab,"_e",$n," = ",$label,"\n";
        foreach (@{$member->{array_size}}) {
            print $FH $self->{indent},@tab,"if len(_e",$n,") != ",$_->{py_literal},":\n";
            print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
            print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
            $n ++;
            push @tab, q{ } x 4;
            if ($n == scalar(@{$member->{array_size}})) {
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.check('octet', ord(_e",$n,"))\n";
                    return;
                }
            }
        }
        $m = $n;
    }
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        $type = $self->_get_defn($type->{type});
    }
    if (scalar @array_max) {
        print $FH $self->{indent},@tab,"_e",$n," = ",$label,"\n" unless ($n);
        foreach (@array_max) {
            print $FH $self->{indent},@tab,"CORBA.check('long', len(_e",$n,"))\n";
            print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
            $n ++;
            push @tab, q{ } x 4;
            if ($n == $m + scalar(@array_max)) {
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.check('octet', ord(_e",$n,"))\n";
                    return;
                }
            }
        }
    }
    if ($n) {
        if (exists $type->{full}) {
            print $FH $self->{indent},@tab,"CORBA.check(",$self->_get_scoped_name($type, $node),", _e",$n,")\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},@tab,"CORBA.check('",$type_name,"', _e",$n,")\n";
        }
    }
    else {
        if (exists $type->{full}) {
            print $FH $self->{indent},@tab,"CORBA.check(",$self->_get_scoped_name($type, $node),", ",$label,")\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},@tab,"CORBA.check('",$type_name,"', ",$label,")\n";
        }
        if ( ($type->isa('StringType') or $type->isa('WideStringType'))
                and exists $type->{max} ) {
            print $FH $self->{indent},@tab,"if len(",$label,") > ",$type->{max}->{py_literal},":\n";
            print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
    }
}

sub _member_marshal {
    my $self = shift;
    my ($member, $label) = @_;

    my $FH = $self->{out};
    my $type = $self->_get_defn($member->{type});
    my @tab = (q{ } x 12);
    my $n = 0;
    my $m = 0;
    my $idx = q{};
    if (exists $member->{array_size}) {
        print $FH $self->{indent},@tab,"_e",$n," = ",$label,"\n";
        foreach (@{$member->{array_size}}) {
            print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
            $n ++;
            push @tab, q{ } x 4;
            if ($n == scalar(@{$member->{array_size}})) {
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.marshal(output, 'octet', ord(_e",$n,"))\n";
                    return;
                }
            }
        }
        $m = $n;
    }
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        $type = $self->_get_defn($type->{type});
    }
    if (scalar @array_max) {
        print $FH $self->{indent},@tab,"_e",$n," = ",$label,"\n" unless ($n);
        foreach (@array_max) {
            print $FH $self->{indent},@tab,"CORBA.marshal(output, 'long', len(_e",$n,"))\n";
            print $FH $self->{indent},@tab,"for _e",$n + 1," in _e",$n,":\n";
            $n ++;
            push @tab, q{ } x 4;
            if ($n == $m + scalar(@array_max)) {
                if ($type->isa('OctetType')) {
                    print $FH $self->{indent},@tab,"CORBA.marshal(output, 'octet', ord(_e",$n,"))\n";
                    return;
                }
            }
        }
    }
    if ($n) {
        if (exists $type->{full}) {
            print $FH $self->{indent},@tab,"_e",$n,".marshal(output)\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},@tab,"CORBA.marshal(output, '",$type_name,"', _e",$n,")\n";
        }
    }
    else {
        if (exists $type->{full}) {
            print $FH $self->{indent},@tab,$label,".marshal(output)\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},@tab,"CORBA.marshal(output, '",$type_name,"', ",$label,")\n";
        }
    }
}

sub _member_demarshal {
    my $self = shift;
    my ($member, $node) = @_;

    my $FH = $self->{out};
    my $type = $self->_get_defn($member->{type});
    my @tab = (q{ } x 12);
    my $n = 0;
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            print $FH $self->{indent},@tab,"_lst",$n," = []\n";
            print $FH $self->{indent},@tab,"for _i",$n," in xrange(",$_->{py_literal},"):\n";
            $n ++;
            push @tab, q{ } x 4;
        }
    }
    my @array_max = ();
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            push @array_max, $type->{max};
        }
        else {
            push @array_max, undef;
        }
        $type = $self->_get_defn($type->{type});
    }
    my $name = $member->{py_name};
    foreach (@array_max) {
        print $FH $self->{indent},@tab,"_len",$n," = CORBA.demarshal(input_, 'long')\n";
        if (defined $_) {
            print $FH $self->{indent},@tab,"if _len",$n," > ",$_->{py_literal},":\n";
            print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
        print $FH $self->{indent},@tab,"_lst",$n," = []\n";
        print $FH $self->{indent},@tab,"for _i",$n," in xrange(_len",$n,"):\n";
        $n ++;
        push @tab, q{ } x 4;
    }
    if ($n) {
        $n --;
        if (exists $type->{full}) {
            print $FH $self->{indent},@tab,"_lst",$n,".append(",$self->_get_scoped_name($type, $node),".demarshal(input_))\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},@tab,"_lst",$n,".append(CORBA.demarshal(input_, '",$type_name,"'))\n";
        }
        pop @tab;
        if ($type->isa('CharType')) {
            print $FH $self->{indent},@tab,"_lst",$n," = ''.join(_lst",$n,")\n";
        }
        if ($type->isa('OctetType')) {
            print $FH $self->{indent},@tab,"_lst",$n," = ''.join(map(chr, _lst",$n,"))\n";
        }
        while ($n > 0) {
            print $FH $self->{indent},@tab,"_lst",$n - 1,".append(_lst",$n,")\n";
            $n --;
            pop @tab;
        }
        print $FH $self->{indent},@tab,$name," = _lst0\n";
    }
    else {
        if (exists $type->{full}) {
            print $FH $self->{indent},@tab,$name," = ",$self->_get_scoped_name($type, $node),".demarshal(input_)\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},@tab,$name," = CORBA.demarshal(input_, '",$type_name,"')\n";
        }
        if ( ($type->isa('StringType') or $type->isa('WideStringType'))
                and exists $type->{max} ) {
            print $FH $self->{indent},@tab,"if len(",$name,") > ",$type->{max}->{py_literal},":\n";
            print $FH $self->{indent},@tab,"    raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
    }
}

sub _member_stringify {
    my $self = shift;
    my ($member) = @_;
    my $array = q{};
    if (exists $member->{array_size}) {
        foreach (@{$member->{array_size}}) {
            $array .= '[' . $_->{py_literal} . ']';
        }
    }
    my $type = $self->_get_defn($member->{type});
    while ($type->isa('SequenceType')) {
        if (exists $type->{max}) {
            $array .= '<' . $type->{max}->{py_literal} . '>';
        }
        else {
            $array .= '<>';
        }
        $type = $self->_get_defn($type->{type});
    }
    my $FH = $self->{out};
    print $FH $self->{indent},"        lst.append('",$type->{py_name},$array," ",$member->{py_name},"=' + repr(self.",$member->{py_name},"))\n";
}

#   3.11.2.2    Discriminated Unions
#

sub visitUnionType {
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{full};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    my $type = $self->_get_defn($node->{type});
    my $default = undef;
    foreach my $case (@{$node->{list_expr}}) {  # case
        foreach (@{$case->{list_label}}) {  # default or expression
            $default = $case if ($_->isa('Default'));
        }
    }
    my $FH = $self->{out};
    if ($self->{old_object}) {
        print $FH $self->{indent},"class ",$node->{py_name},":\n";
    }
    else {
        print $FH $self->{indent},"class ",$node->{py_name},"(object):\n";
    }
    print $FH $self->{indent},"    \"\"\" Union ",$node->{repos_id}," \"\"\"\n";
    print $FH "\n";
    my $indent = $self->{indent};
    $self->{indent} .= q{ } x 4;
    if ($type->isa('EnumType')) {
        $type->visit($self);
    }
    foreach (@{$node->{list_expr}}) {
        my $type = $self->_get_defn($_->{element}->{type});
        if (       $type->isa('StructType')
                or $type->isa('UnionType')
                or $type->isa('FixedPtType') ) {
            $type->visit($self);
        }
    }
    $self->{indent} = $indent;
    print $FH $self->{indent},"    def __init__(self, *args, **kwargs):\n";
    print $FH $self->{indent},"        if len(args) == 2:\n";
    print $FH $self->{indent},"            _d, _v = args\n";
    if (exists $type->{full}) {
        print $FH $self->{indent},"            CORBA.check(",$self->_get_scoped_name($type, $node),", _d)\n";
    }
    else {
        my $type_name = $type->{value};
        $type_name =~ s/ /_/g;
        print $FH $self->{indent},"            CORBA.check('",$type_name,"', _d)\n";
    }
    my $elif = 'if';
    foreach my $case (@{$node->{list_expr}}) {  # case
        foreach (@{$case->{list_label}}) {  # default or expression
            unless ($_->isa('Default')) {
                print $FH $self->{indent},"            ",$elif," _d == ",$_->{py_literal},":\n";
                my $member = $self->_get_defn($case->{element}->{value});
                $self->_member_check($member, '_v', '                ', $node);
                $elif = 'elif';
            }
        }
    }
    if ($elif eq 'if') {
        print $FH $self->{indent},"            if False: pass\n";
    }
    if (defined $default) {
        print $FH $self->{indent},"            else:   # default\n";
        my $member = $self->_get_defn($default->{element}->{value});
        $self->_member_check($member, '_v', '                ', $node);
    }
    else {
        print $FH $self->{indent},"            else:\n";
        print $FH $self->{indent},"                raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
    }
    print $FH $self->{indent},"            self.__d = _d\n";
    print $FH $self->{indent},"            self.__v = _v\n";
    foreach my $case (@{$node->{list_expr}}) {  # case
        if (scalar(@{$case->{list_label}}) == 1) {
            foreach (@{$case->{list_label}}) {  # default or expression
                unless ($_->isa('Default')) {
                    my $elt = $self->_get_defn($case->{element});
                    my $label = ${$elt->{list_expr}}[0];
                    print $FH $self->{indent},"        elif '",$label,"' in kwargs:\n";
                    print $FH $self->{indent},"            self._set",$label,"(kwargs['",$label,"'])\n";
                }
            }
        }
    }
    print $FH $self->{indent},"        else:\n";
    print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
    print $FH "\n";
    print $FH $self->{indent},"    def _get_d(self):\n";
    print $FH $self->{indent},"        return self.__d\n";
    print $FH "\n";
    print $FH $self->{indent},"    _d = property(fget=_get_d)\n";
    print $FH "\n";
    print $FH $self->{indent},"    def _get_v(self):\n";
    $elif = 'if';
    foreach my $case (@{$node->{list_expr}}) {  # case
        foreach (@{$case->{list_label}}) {  # default or expression
            unless ($_->isa('Default')) {
                print $FH $self->{indent},"        ",$elif," self.__d == ",$_->{py_literal},":\n";
                my $member = $self->_get_defn($case->{element}->{value});
                print $FH $self->{indent},"            return self.__v\n";
                $elif = 'elif';
            }
        }
    }
    if ($elif eq 'if') {
        print $FH $self->{indent},"        if False: pass\n";
    }
    if (defined $default) {
        print $FH $self->{indent},"        else:   # default\n";
        my $member = $self->_get_defn($default->{element}->{value});
        print $FH $self->{indent},"            return self.__v\n";
    }
    else {
        print $FH $self->{indent},"        else:\n";
        print $FH $self->{indent},"            return None\n";
    }
    print $FH "\n";
    print $FH $self->{indent},"    _v = property(fget=_get_v)\n";
    print $FH "\n";
    foreach my $case (@{$node->{list_expr}}) {  # case
        if (scalar(@{$case->{list_label}}) == 1) {
            foreach (@{$case->{list_label}}) {  # default or expression
                unless ($_->isa('Default')) {
                    my $elt = $self->_get_defn($case->{element});
                    my $label = ${$elt->{list_expr}}[0];
                    print $FH $self->{indent},"    def _set",$label,"(self, ",$label,"):\n";
                    my $member = $self->_get_defn($case->{element}->{value});
                    $self->_member_check($member, $label, "        ", $node);
                    print $FH $self->{indent},"        self.__d = ",$_->{py_literal},"\n";
                    print $FH $self->{indent},"        self.__v = ",$label,"\n";
                    print $FH "\n";
                    print $FH $self->{indent},"    def _get",$label,"(self):\n";
                    print $FH $self->{indent},"        if self.__d == ",$_->{py_literal},":\n";
                    print $FH $self->{indent},"            return self.__v\n";
                    print $FH $self->{indent},"        return None\n";
                    print $FH "\n";
                    print $FH $self->{indent},"    ",$label," = property(fset=_set",$label,", fget=_get",$label,")\n";
                    print $FH "\n";
                }
            }
        }
    }
    if ($self->{marshal}) {
        print $FH $self->{indent},"    def marshal(self, output):\n";
        if (exists $type->{full}) {
            print $FH $self->{indent},"        self._d.marshal(output)\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},"        CORBA.marshal(output, '",$type_name,"', self._d)\n";
        }
        $elif = 'if';
        foreach my $case (@{$node->{list_expr}}) {  # case
            foreach (@{$case->{list_label}}) {  # default or expression
                unless ($_->isa('Default')) {
                    print $FH $self->{indent},"        ",$elif," self._d == ",$_->{py_literal},":\n";
                    my $member = $self->_get_defn($case->{element}->{value});
                    $self->_member_marshal($member, 'self.__v');
                    $elif = 'elif';
                }
            }
        }
        if ($elif eq 'if') {
            print $FH $self->{indent},"        if False: pass\n";
        }
        if (defined $default) {
            print $FH $self->{indent},"        else:   # default\n";
            my $member = $self->_get_defn($default->{element}->{value});
            $self->_member_marshal($member, "self.__v");
        }
        else {
            print $FH $self->{indent},"        else:\n";
            print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/BAD_PARAM:1.0', 2, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
        print $FH "\n";
        print $FH $self->{indent},"    def demarshal(cls, input_):\n";
        if (exists $type->{full}) {
            print $FH $self->{indent},"        _d = ",$self->_get_scoped_name($type, $node),".demarshal(input_)\n";
        }
        else {
            my $type_name = $type->{value};
            $type_name =~ s/ /_/g;
            print $FH $self->{indent},"        _d = CORBA.demarshal(input_, '",$type_name,"')\n";
        }
        $elif = 'if';
        foreach my $case (@{$node->{list_expr}}) {  # case
            foreach (@{$case->{list_label}}) {  # default or expression
                unless ($_->isa('Default')) {
                    print $FH $self->{indent},"        ",$elif," _d == ",$_->{py_literal},":\n";
                    my $member = $self->_get_defn($case->{element}->{value});
                    $self->_member_demarshal($member, $node);
                    print $FH $self->{indent},"            return cls(_d, ",$member->{py_name},")\n";
                    $elif = 'elif';
                }
            }
        }
        if ($elif eq 'if') {
            print $FH $self->{indent},"        if False: pass\n";
        }
        if (defined $default) {
            print $FH $self->{indent},"        else:   # default\n";
            my $member = $self->_get_defn($default->{element}->{value});
            $self->_member_demarshal($member, $node);
            print $FH $self->{indent},"            return cls(_d, ",$member->{py_name},")\n";
        }
        else {
            print $FH $self->{indent},"        else:\n";
            print $FH $self->{indent},"            raise CORBA.SystemException('IDL:CORBA/MARSHAL:1.0', 9, CORBA.CORBA_COMPLETED_MAYBE)\n";
        }
        print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
        print $FH "\n";
    }
    if ($self->{compare}) {
        print $FH $self->{indent},"    def __eq__(self, obj):\n";
        print $FH $self->{indent},"        if obj == None:\n";
        print $FH $self->{indent},"            return False\n";
        print $FH $self->{indent},"        if isinstance(obj, type(self)):\n";
        print $FH $self->{indent},"            if self._d == obj._d:\n";
        print $FH $self->{indent},"                return self._v == obj._v\n";
        print $FH $self->{indent},"            else:\n";
        print $FH $self->{indent},"                return False\n";
        print $FH $self->{indent},"        else:\n";
        print $FH $self->{indent},"            return False\n";
        print $FH "\n";
        print $FH $self->{indent},"    def __ne__(self, obj):\n";
        print $FH $self->{indent},"        return not self.__eq__(obj)\n";
        print $FH "\n";
    }
    if ($self->{stringify}) {
        if ($self->{old_object}) {
            print $FH $self->{indent},"    def __str__(self):\n";
        }
        else {
            print $FH $self->{indent},"    def __repr__(self):\n";
        }
        print $FH $self->{indent},"        lst = []\n";
        print $FH $self->{indent},"        lst.append('_d=' + repr(self._d))\n";
        print $FH $self->{indent},"        lst.append('_v=' + repr(self._v))\n";
        print $FH $self->{indent},"        inner = ',\\n'.join(lst)\n";
        print $FH $self->{indent},"        inner = '\\n'.join(['   ' + line for line in inner.split('\\n')])\n";
        print $FH $self->{indent},"        return 'union ",$node->{py_name}," {\\n' + inner + '\\n}'\n";
        print $FH "\n";
    }
    if ($self->{id}) {
        print $FH $self->{indent},"    def _get_id(cls):\n";
        print $FH $self->{indent},"        return '",$node->{repos_id},"'\n";
        print $FH $self->{indent},"    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    if (exists $node->{serial_uid}) {
        print $FH $self->{indent},"    def _get_uid(cls):\n";
        print $FH $self->{indent},"        return 0x",$node->{serial_uid},"L\n";
        print $FH $self->{indent},"    serial_uid = classmethod(_get_uid)\n";
        print $FH "\n";
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
    my $name = $node->{full};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    my $FH = $self->{out};
    print $FH $self->{indent},"class ",$node->{py_name},"(CORBA.Enum):\n";
    print $FH $self->{indent},"    \"\"\" Enum ",$node->{repos_id}," \"\"\"\n";
    print $FH "\n";
    print $FH $self->{indent},"    _enum_str = dict()\n";
    print $FH $self->{indent},"    _enum = dict()\n";
    print $FH "\n";
    if ($self->{id}) {
        print $FH $self->{indent},"    def _get_id(cls):\n";
        print $FH $self->{indent},"        return '",$node->{repos_id},"'\n";
        print $FH $self->{indent},"    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    if (exists $node->{serial_uid}) {
        print $FH $self->{indent},"    def _get_uid(cls):\n";
        print $FH $self->{indent},"        return 0x",$node->{serial_uid},"L\n";
        print $FH $self->{indent},"    serial_uid = classmethod(_get_uid)\n";
        print $FH "\n";
    }
    my $value = 0;
    foreach (@{$node->{list_expr}}) {
        print $FH $self->{indent},$_->{py_name}," = ",$node->{py_name},"('",$_->{py_name},"', ",$value,")\n";
        $value ++;
    }
    print $FH "\n";
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
    my $self = shift;
    my ($node) = @_;
    my $name = $node->{full};
    return if (exists $self->{done_hash}->{$name});
    $self->{done_hash}->{$name} = 1;
    my $FH = $self->{out};
    print $FH $self->{indent},"class ",$node->{py_name},"(CORBA.UserException):\n";
    print $FH $self->{indent},"    \"\"\" Exception ",$node->{repos_id}," \"\"\"\n";
    print $FH "\n";
    if (exists $node->{list_expr}) {
        warn __PACKAGE__,"::visitException $node->{idf} : empty list_expr.\n"
                unless (@{$node->{list_expr}});

        foreach (@{$node->{list_expr}}) {
            my $indent = $self->{indent};
            $self->{indent} .= q{ } x 4;
            my $type = $self->_get_defn($_->{type});
            if (       $type->isa('StructType')
                    or $type->isa('UnionType')
                    or $type->isa('FixedPtType') ) {
                $type->visit($self);
            }
            $self->{indent} = $indent;
        }
    }
    print $FH $self->{indent},"    def __init__(self";
    if (exists $node->{list_expr}) {
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            print $FH ", ",$member->{py_name};
        }
    }
    print $FH "):\n";
    print $FH $self->{indent},"        CORBA.UserException.__init__(self)\n";
    foreach (@{$node->{list_member}}) {
        my $member = $self->_get_defn($_);          # member
        print $FH $self->{indent},"        self._set",$member->{py_name},"(",$member->{py_name},")\n";
    }
    print $FH "\n";

    if (exists $node->{list_expr}) {
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);          # member
            print $FH $self->{indent},"    def _set",$member->{py_name},"(self, ",$member->{py_name},"):\n";
            $self->_member_check($member, $member->{py_name}, "        ", $node);
            print $FH $self->{indent},"        self._",$member->{py_name}," = ",$member->{py_name},"\n";
            print $FH "\n";
            print $FH $self->{indent},"    def _get",$member->{py_name},"(self):\n";
            print $FH $self->{indent},"        return self._",$member->{py_name},"\n";
            print $FH "\n";
            print $FH $self->{indent},"    ",$member->{py_name}," = property(fset=_set",$member->{py_name},", fget=_get",$member->{py_name},")\n";
            print $FH "\n";
        }
    }
    if ($self->{marshal}) {
        print $FH $self->{indent},"    def marshal(self, output):\n";
        if (exists $node->{list_expr}) {
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);
                $self->_member_marshal($member, "self." . $member->{py_name});
            }
        }
        else {
            print $FH $self->{indent},"        pass\n";
        }
        print $FH "\n";
        print $FH $self->{indent},"    def demarshal(cls, input_):\n";
        if (exists $node->{list_expr}) {
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);
                $self->_member_demarshal($member, $node);
            }
        }
        print $FH $self->{indent},"            return cls(";
        my $first = 1;
        if (exists $node->{list_expr}) {
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);
                if ($first) {
                    $first = 0;
                }
                else {
                    print $FH ", ";
                }
                print $FH $member->{py_name};
            }
        }
        print $FH ")\n";
        print $FH $self->{indent},"    demarshal = classmethod(demarshal)\n";
        print $FH "\n";
    }
    if ($self->{compare}) {
        print $FH $self->{indent},"    def __eq__(self, obj):\n";
        print $FH $self->{indent},"        if obj == None:\n";
        print $FH $self->{indent},"            return False\n";
        print $FH $self->{indent},"        if not isinstance(obj, type(self)):\n";
        print $FH $self->{indent},"            return False\n";
        foreach (@{$node->{list_member}}) {
            my $member = $self->_get_defn($_);
            print $FH $self->{indent},"        if self.",$member->{py_name}," != obj.",$member->{py_name},":\n";
            print $FH $self->{indent},"            return False\n";
        }
        print $FH $self->{indent},"        return True\n";
        print $FH "\n";
        print $FH $self->{indent},"    def __ne__(self, obj):\n";
        print $FH $self->{indent},"        return not self.__eq__(obj)\n";
        print $FH "\n";
    }
    if ($self->{stringify}) {
        print $FH $self->{indent},"    def __str__(self):\n";
        if (exists $node->{list_expr}) {
            print $FH $self->{indent},"        lst = []\n";
            foreach (@{$node->{list_member}}) {
                my $member = $self->_get_defn($_);
                $self->_member_stringify($member);
            }
            print $FH $self->{indent},"        inner = ',\\n'.join(lst)\n";
            print $FH $self->{indent},"        inner = '\\n'.join(['   ' + line for line in inner.split('\\n')])\n";
            print $FH $self->{indent},"        return 'exception ",$node->{py_name}," {\\n' + inner + '\\n}'\n";
        }
        else {
            print $FH $self->{indent},"        return 'exception ",$node->{py_name}," {}'\n";
        }
        print $FH "\n";
    }
    if ($self->{id}) {
        print $FH $self->{indent},"    def _get_id(cls):\n";
        print $FH $self->{indent},"        return '",$node->{repos_id},"'\n";
        print $FH $self->{indent},"    corba_id = classmethod(_get_id)\n";
        print $FH "\n";
    }
    if (exists $node->{serial_uid}) {
        print $FH $self->{indent},"    def _get_uid(cls):\n";
        print $FH $self->{indent},"        return 0x",$node->{serial_uid},"L\n";
        print $FH $self->{indent},"    serial_uid = classmethod(_get_uid)\n";
        print $FH "\n";
    }
}

#
#   3.13    Operation Declaration
#

sub visitOperation {
    my $self = shift;
    my ($node) = @_;
    my $FH = $self->{out};
    print $FH "#   def ",$node->{py_name},"(self";
    foreach (@{$node->{list_param}}) {      # paramater
        if ( $_->{attr} eq 'in' or $_->{attr} eq 'inout') {
            print $FH ", ",$_->{py_name};
        }
    }
    print $FH "): ";
    my @out = ();
    my $type = $self->_get_defn($node->{type});
    unless ($type->isa('VoidType')) {
        push @out, '_ret';
    }
    foreach (@{$node->{list_param}}) {      # paramater
        if ( $_->{attr} eq 'inout' or $_->{attr} eq 'out') {
            push @out, $_->{py_name};
        }
    }
    if (scalar(@out)) {
        print $FH "return ", join(', ', @out);
    }
    else {
        print $FH "pass";
    }
    print $FH "\n";
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

