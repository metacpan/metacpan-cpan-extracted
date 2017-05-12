
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::Python::PyExtendedVisitor;

use strict;
use warnings;

our $VERSION = '2.64';

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
    $self->{marshal} = 0;
    $self->{stringify} = 1;
    $self->{compare} = 1;
    $self->{id} = 1;
    $self->{old_object} = exists $parser->YYData->{opt_O};
    $self->{indent} = q{};
    $self->{out} = undef;
    $self->{import} = "import PyIDL as CORBA\n";
    $self->{scope} = undef;
    return $self;
}

sub _setup_py {
    my $self = shift;
    my $filename = 'setup.py';
    open my $FH, '>', $filename
            or die "can't open $filename ($!).\n";

    print $FH "#   This file was generated (by ",basename($0),"). DO NOT modify it.\n";
    print $FH "# From file : ",$self->{srcname},", ",$self->{srcname_size}," octets, ",POSIX::ctime($self->{srcname_mtime});
    print $FH "\n";
    print $FH "from distutils.core import setup, Extension\n";
    print $FH "\n";
    print $FH $self->{setup_Extension},"\n"
            if ($self->{setup_Extension});
    print $FH "setup(\n";
    print $FH "    name = '",$self->{setup_name},"',\n";
    print $FH "    py_modules = [ '",$self->{setup_py_modules},"' ],\n"
            if ($self->{setup_py_modules});
    print $FH "    packages = [ '",join("', '", @{$self->{setup_packages}}),"' ],\n"
            if (scalar @{$self->{setup_packages}});
    print $FH "    ext_modules = [ ",join(", ", @{$self->{setup_ext_modules}})," ],\n"
            if (scalar @{$self->{setup_ext_modules}});
    print $FH ")\n";
    print $FH "\n";
    close $FH;
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;
    my $setup_name;
    my $filename;
    my $empty;
    $self->empty_modules();
    $self->{setup_packages} = [];
    $self->{setup_ext_modules} = [];
    $self->{setup_Extension} = q{};
    if ($self->{base_package}) {
        $setup_name = $self->{base_package};
        $filename = $setup_name . '/__init__.py';
        $self->{setup_name} = $setup_name;
        push @{$self->{setup_packages}}, $setup_name;
    }
    else {
        my $basename = basename($self->{srcname}, '.idl');
        $basename =~ s/\./_/g;
        $setup_name = '_' . $basename;
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
    $self->{has_itf} = 0;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    if ($self->{has_itf}) {
        my $c_name = basename($self->{srcname}, '.idl');
        my $ext_name = 'ext_' . $setup_name;
        push @{$self->{setup_ext_modules}}, $ext_name;
        $self->{setup_Extension} .= $ext_name . " = Extension('c" . $setup_name . "',\n";
        $self->{setup_Extension} .= "    sources = [ 'c" . $setup_name . "module.c', '" . $c_name . ".c', 'corba.c', 'cpyhelper.c' ],\n";
        $self->{setup_Extension} .= ")\n";
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
    my $setup_name = $node->{full};
    $setup_name =~ s/^:://;
    $setup_name =~ s/::/\//g;
    if ($self->{base_package}) {
        $setup_name = $self->{base_package} . '/' . $setup_name;
    }
    $self->{setup_name} = $setup_name unless ($self->{setup_name});
    push @{$self->{setup_packages}}, $setup_name;
    my $defn = $self->{symbtab}->Lookup($node->{full});
    my $doc_string = "\"\"\" Module " . $defn->{repos_id} . " \"\"\"";
    my $filename = $setup_name . '/__init__.py';
    $self->open_stream($filename, $node, $doc_string);
    my $FH = $self->{out};
    my $save_has_itf = $self->{has_itf};
    $self->{has_itf} = 0;
    foreach (@{$node->{list_decl}}) {
        $_->visit($self);
    }
    if ($self->{has_itf}) {
        my $c_name = basename($self->{srcname}, '.idl');
        my $ext_name = 'ext_' . $setup_name;
        $ext_name =~ s/\//_/g;
        my @name = split /::/, $node->{full};
        shift @name;
        $name[-1] = 'c' . $name[-1];
        push @{$self->{setup_ext_modules}}, $ext_name;
        $self->{setup_Extension} .= $ext_name . " = Extension('" . join(".", @name) . "',\n";
        $self->{setup_Extension} .= "    include_dirs = [ '.' ],\n";
        $self->{setup_Extension} .= "    sources = [ '" . join("/", @name) . "module.c', '" . $c_name . ".c', 'corba.c', 'cpyhelper.c' ],\n";
        $self->{setup_Extension} .= ")\n";
    }
    $self->{has_itf} = $save_has_itf;
    print $FH "\n";
    print $FH "# Local variables:\n";
    print $FH "#   buffer-read-only: t\n";
    print $FH "# End:\n";
    close $FH;
    $self->{out} = $save_out;
}

#
#   3.8     Interface Declaration
#

sub visitRegularInterface {
    my $self = shift;
    my($node) = @_;
    my $FH = $self->{out};
    $self->{indent} = q{ } x 4;
    $self->{itf} = $node;
    $self->{has_itf} ++;
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
    my @name = split /::/, $node->{full};
    shift @name;
    if (scalar @name > 1) {
        $name[-2] = 'c' . $name[-2];
        print $FH "        self._native = ",join(".", @name),"()\n";
    }
    else {
        print $FH "        self._native = c",$self->{module},".",$name[0],"()\n";
    }
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
    print $FH "    def ",$node->{py_name},"(self";
    foreach (@{$node->{list_param}}) {      # paramater
        next if ($_->{attr} eq 'out');
        print $FH ", ",$_->{py_name};
    }
    print $FH "):\n";
    print $FH "        \"\"\" Operation ",$node->{repos_id}," \"\"\"\n" if ($node->{py_name} !~ /^_/);

    foreach (@{$node->{list_param}}) {      # paramater
        next if ($_->{attr} eq 'out');
        $self->_member_check($_, $_->{py_name}, '    ', $self->{itf});
    }
    print $FH "        return self._native.",$node->{py_name},"(";
    my $first = 1;
    foreach (@{$node->{list_param}}) {      # paramater
        next if ($_->{attr} eq 'out');
        print $FH ", " unless ($first);
        print $FH $_->{py_name};
        $first = 0;
    }
    print $FH ")\n";
    print $FH "\n";
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

