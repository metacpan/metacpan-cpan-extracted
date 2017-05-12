
package CORBA::XPIDL::XptVisitor;

use strict;
use warnings;

our $VERSION = '0.20';

use File::Basename;
use POSIX qw(ctime);
use CORBA::XPIDL::XPT;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    my ($parser) = @_;
    $self->{srcname} = $parser->YYData->{srcname};
    $self->{symbtab} = $parser->YYData->{symbtab};
    $self->{emit_typelib_annotations} = $parser->YYData->{opt_a};
    $self->{typelib} = $parser->YYData->{opt_t};
    my $filename;
    if ($parser->YYData->{opt_e}) {
        $filename = $parser->YYData->{opt_e};
    }
    else {
        if ($parser->YYData->{opt_o}) {
            $filename = $parser->YYData->{opt_o} . '.xpt';
        }
        else {
            $filename = basename($self->{srcname}, '.idl') . '.xpt';
        }
    }
    $self->{outfile} = $filename;
    return $self;
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

sub _arg_num {
    my $self = shift;
    my ($name, $node) = @_;
    my $count = 0;
    foreach (@{$node->{list_param}}) {
        return $count
                if ($_->{idf} eq $name);
        $count ++;
    }
    warn __PACKAGE__,"::_arg_num : can't found argument ($name) in method '$node->{idf}'.\n";
}

#
#   3.5     OMG IDL Specification
#

sub visitSpecification {
    my $self = shift;
    my ($node) = @_;

    my $major_version = substr($self->{typelib}, 0, 1);
    my $minor_version = substr($self->{typelib}, 2, 1);
    $self->{xpt} = new XPT::File(
            magic           => XPT::File::MAGIC,
            major_version   => $major_version,
            minor_version   => $minor_version,
    );
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
    $self->{xpt}->indexe();

    if ($self->{emit_typelib_annotations}) {
        my $creator = 'xpidl ' . $CORBA::XPIDL::VERSION;
        my $data = "Created from " . $self->{srcname} .
                   "\nCreation date: " . POSIX::ctime(time()) . "Interfaces:";
        foreach (sort keys %{$self->{xpt}->{interface_iid}}) {
            my $itf = ${$self->{xpt}->{interface_iid}}{$_};
            next unless (defined $itf->{interface_descriptor});
            $data .= q{ } . $itf->{name};
        }
        my $anno = new XPT::Annotation(
                tag                     => 1,
                creator                 => $creator,
                private_data            => $data,
        );
        $self->{xpt}->add_annotation($anno);
    }
    $self->{xpt}->terminate_annotations();

#   print $self->{xpt}->stringify();
    open my $OUT, '>', $self->{outfile}
            or die "FAILED: can't open $self->{outfile}\n";
    binmode $OUT, ':raw';
    print $OUT $self->{xpt}->marshal();
    close $OUT;
}

#
#   3.7     Module Declaration
#

sub visitModules {
    my $self = shift;
    my ($node) = @_;
    foreach (@{$node->{list_decl}}) {
        $self->_get_defn($_)->visit($self);
    }
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
    if ($self->{srcname} eq $node->{filename}) {
        my $parent_interface_name;
        if (exists $node->{inheritance}) {
            my $base = $self->_get_defn(${$node->{inheritance}->{list_interface}}[0]);
            my $namespace = $base->getProperty('namespace') || q{};
            $parent_interface_name = $namespace . '::' . $base->{idf};
            $self->_add_interface($base);
        }
        my $interface_descriptor = new XPT::InterfaceDescriptor(
                parent_interface        => $parent_interface_name,
                method_descriptors      => [],
                const_descriptors       => [],
                is_scriptable           => $node->hasProperty('scriptable'),
                is_function             => $node->hasProperty('function'),
        );
        $self->{itf} = $interface_descriptor;
        foreach (@{$node->{list_decl}}) {
            $self->_get_defn($_)->visit($self);
        }
        $self->_add_interface($node, $interface_descriptor);
    }
}

sub _add_interface {
    my $self = shift;
    my ($node, $desc) = @_;
    my $iid = chr(0) x 16;
    my $str_iid = $node->getProperty('uuid');
    if (defined $str_iid) {
        $str_iid =~ s/-//g;
        $iid = q{};
        while ($str_iid) {
            $iid .= chr(hex(substr $str_iid, 0, 2));
            $str_iid = substr $str_iid, 2;
        }
    }
    my $name = $node->{idf};
    my $namespace = $node->getProperty('namespace') || q{};
    my $entry = new XPT::InterfaceDirectoryEntry(
            iid                     => new XPT::IID($iid),
            name                    => $name,
            name_space              => $namespace,
            interface_descriptor    => $desc,
    );
    $self->{xpt}->add_interface($entry);
}

sub visitForwardRegularInterface {
    my $self = shift;
    my ($node) = @_;
    if ($self->{srcname} eq $node->{filename}) {
        $self->_add_interface($node);
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
    my $type = $self->_get_defn($node->{type});
    my $desc = $self->_type($type);
    my $value = $node->{value}->{value};
    my $cst = new XPT::ConstDescriptor(
            name                    => $node->{idf},
            type                    => $desc,
            value                   => $value,
    );
    push @{$self->{itf}->{const_descriptors}}, $cst;
}

#
#   3.11    Type Declaration
#

sub visitTypeDeclarators {
    # empty
}

sub visitNativeType {
    # empty
}

sub _type {
    my $self = shift;
    my ($node, $param, $method) = @_;

    my $is_array = defined $method && $param->hasProperty('array');
    my $type = $node;
    while ($type->isa('TypeDeclarator')) {
        $type = $self->_get_defn($type->{type});
    }
    my %hash;
    my $iid_is = $param->getProperty('iid_is') if (defined $param);

    if (     $type->isa('IntegerType')) {
        if    ($type->{value} eq 'short') {
            $hash{tag} = XPT::int16;
        }
        elsif ($type->{value} eq 'unsigned short') {
            $hash{tag} = XPT::uint16;
        }
        elsif ($type->{value} eq 'long') {
            $hash{tag} = XPT::int32;
        }
        elsif ($type->{value} eq 'unsigned long') {
            $hash{tag} = XPT::uint32;
        }
        elsif ($type->{value} eq 'long long') {
            $hash{tag} = XPT::int64;
        }
        elsif ($type->{value} eq 'unsigned long long') {
            $hash{tag} = XPT::uint64;
        }
        else {
            warn __PACKAGE__,"::_type (IntegerType) $node->{value}.\n";
        }
    }
    elsif ($type->isa('OctetType')) {
        $hash{tag} = XPT::uint8;
    }
    elsif ($type->isa('FloatingPtType')) {
        if (   $type->{value} eq 'float') {
            $hash{tag} = XPT::float;
        }
        elsif ($type->{value} eq 'double') {
            $hash{tag} = XPT::double;
        }
        else {
            warn __PACKAGE__,"::_type (FloatingPtType) $node->{value}.\n";
        }
    }
    elsif ($type->isa('BooleanType')) {
        $hash{tag} = XPT::boolean;
    }
    elsif ($type->isa('CharType')) {
        $hash{tag} = XPT::char;
    }
    elsif ($type->isa('WideCharType')) {
        $hash{tag} = XPT::wchar_t;
    }
    elsif ($type->isa('StringType')) {
        my $size_is = $param->getProperty('size_is')
                if (defined $param);
        if ($is_array or !defined $method or !defined $size_is) {
            $hash{tag} = XPT::pstring;
            $hash{is_pointer} = 1;
        }
        else {
            $hash{tag} = XPT::StringWithSizeTypeDescriptor;
            $hash{is_pointer} = 1;
            $hash{size_is_arg_num} = $self->_arg_num($size_is, $method);
            $hash{length_is_arg_num} = $hash{size_is_arg_num};
            my $length_is = $param->getProperty('length_is');
            $hash{length_is_arg_num} = $self->_arg_num($length_is, $method)
                    if (defined $length_is);
        }
    }
    elsif ($type->isa('WideStringType')) {
        my $size_is = $param->getProperty('size_is')
                if (defined $param);
        if ($is_array or !defined $method or !defined $size_is) {
            $hash{tag} = XPT::pwstring;
            $hash{is_pointer} = 1;
        }
        else {
            $hash{tag} = XPT::WideStringWithSizeTypeDescriptor;
            $hash{is_pointer} = 1;
            $hash{size_is_arg_num} = $self->_arg_num($size_is, $method);
            $hash{length_is_arg_num} = $hash{size_is_arg_num};
            my $length_is = $param->getProperty('length_is');
            $hash{length_is_arg_num} = $self->_arg_num($length_is, $method)
                    if (defined $length_is);
        }
    }
    elsif ($type->isa('NativeType') and !defined $iid_is) {
        if      ($node->hasProperty('nsid')) {
            $hash{tag} = XPT::nsIID;
            if    ($node->hasProperty('ref')) {
                $hash{is_pointer} = 1;
                $hash{is_reference} = 1;
            }
            elsif ($node->hasProperty('ptr')) {
                $hash{is_pointer} = 1;
            }
        }
        elsif ($node->hasProperty('domstring')) {
            $hash{tag} = XPT::domstring;
            $hash{is_pointer} = 1;
            if ($node->hasProperty('ref')) {
                $hash{is_reference} = 1;
            }
        }
        elsif ($node->hasProperty('astring')) {
            $hash{tag} = XPT::astring;
            $hash{is_pointer} = 1;
            if ($node->hasProperty('ref')) {
                $hash{is_reference} = 1;
            }
        }
        elsif ($node->hasProperty('utf8string')) {
            $hash{tag} = XPT::utf8string;
            $hash{is_pointer} = 1;
            if ($node->hasProperty('ref')) {
                $hash{is_reference} = 1;
            }
        }
        elsif ($node->hasProperty('cstring')) {
            $hash{tag} = XPT::cstring;
            $hash{is_pointer} = 1;
            if ($node->hasProperty('ref')) {
                $hash{is_reference} = 1;
            }
        }
        else {
            $hash{tag} = XPT::void;
            $hash{is_pointer} = 1;
        }
    }
    elsif (    $type->isa('RegularInterface')
            or $type->isa('ForwardRegularInterface')
            or $type->isa('NativeType') ) {
        if (defined $iid_is) {
            $hash{tag} = XPT::InterfaceIsTypeDescriptor;
            $hash{is_pointer} = 1;
            $hash{arg_num} = $self->_arg_num($iid_is, $method);
        }
        else {
            $self->_add_interface($type);
            my $namespace = $type->getProperty('namespace') || q{};
            $hash{interface} = $namespace . '::' . $type->{idf};
            $hash{tag} = XPT::InterfaceTypeDescriptor;
            $hash{is_pointer} = 1;
        }
    }
    elsif ($type->isa('VoidType')) {
        $hash{tag} = XPT::void;
    }
    my $desc = new XPT::TypeDescriptor( %hash );

    if ($is_array) {
        # size_is is required
        my $size_is = $param->getProperty('size_is');
#       die "[array] requires [size_is()].\n"
#               unless (defined $size_is);
        my $size_is_arg_num = $self->_arg_num($size_is, $method);
        # length_is is optional
        my $length_is_arg_num = $size_is_arg_num;
        my $length_is = $param->getProperty('length_is');
        $length_is_arg_num = $self->_arg_num($size_is, $method)
                if (defined $length_is);
        return new XPT::TypeDescriptor(
                is_pointer              => 1,
                is_unique_pointer       => 0,
                is_reference            => 0,
                tag                     => XPT::ArrayTypeDescriptor,
                size_is_arg_num         => $size_is_arg_num,
                length_is_arg_num       => $length_is_arg_num,
                type_descriptor         => $desc,
        );
    }
    else {
        return $desc
    }
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
    my $notxpcom = $node->hasProperty('notxpcom');
    my @params = ();
    foreach (@{$node->{list_param}}) {
        push @params, $self->_param($_, $node);
    }
    my $type = $self->_get_defn($node->{type});
    my $result;
    if ($notxpcom) {
        $result = new XPT::ParamDescriptor(
                in                      => 0,
                out                     => 0,
                retval                  => 1,
                shared                  => 0,
                dipper                  => 0,
                type                    => $self->_type($type),
        );
    }
    else {
        unless ($type->isa('VoidType')) {
            my $dipper = $self->_is_dipper($type);
            my $desc = $self->_type($type);
            push @params, new XPT::ParamDescriptor(
                    in                      => $dipper,
                    out                     => !$dipper,
                    retval                  => 1,
                    shared                  => 0,
                    dipper                  => $dipper,
                    type                    => $desc,
            );
        }

        $result = $self->_ns_result();
    }
    my $method = new XPT::MethodDescriptor(
            is_getter               => 0,
            is_setter               => 0,
            is_not_xpcom            => $notxpcom,
            is_constructor          => 0,
            is_hidden               => $node->hasProperty('noscript'),
            name                    => $node->{idf},
            params                  => \@params,
            result                  => $result,
    );
    push @{$self->{itf}->{method_descriptors}}, $method;
}

sub _param {
    my $self = shift;
    my ($node, $parent) = @_;
    my $type = $self->_get_defn($node->{type});
    my $in = 0;
    my $out = 0;
    if ($node->{attr} eq 'in') {
        $in = 1;
    }
    elsif ($node->{attr} eq 'out') {
        $out = 1;
    }
    elsif ($node->{attr} eq 'inout') {
        $in = 1;
        $out = 1;
    }
#   my $dipper = $self->_is_dipper($type);
    my $dipper = $self->_is_dipper($node);
    if ($dipper and $out) {
        $out = 0;
        $in = 1;
    }
    my $desc = $self->_type($type, $node, $parent);
    return new XPT::ParamDescriptor(
            in                      => $in,
            out                     => $out,
            retval                  => $node->hasProperty('retval'),
            shared                  => $node->hasProperty('shared'),
            dipper                  => $dipper,
            type                    => $desc,
    );
}

sub _ns_result {
    my $self = shift;
    return new XPT::ParamDescriptor(
            in                      => 0,
            out                     => 0,
            retval                  => 0,
            shared                  => 0,
            dipper                  => 0,
            type                    => new XPT::TypeDescriptor(
                    is_pointer              => 0,
                    is_unique_pointer       => 0,
                    is_reference            => 0,
                    tag                     => XPT::uint32,
            ),
    );
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
    my $type = $self->_get_defn($node->{type});
    my $dipper = $self->_is_dipper($type);
    my $getter = new XPT::MethodDescriptor(
            is_getter               => 1,
            is_setter               => 0,
#           is_not_xpcom            => $node->hasProperty('notxpcom'),
            is_not_xpcom            => 0,   # functionality or bug
            is_constructor          => 0,
            is_hidden               => $node->hasProperty('noscript'),
            name                    => $node->{idf},
            params                  => [
                new XPT::ParamDescriptor(
                        in                      => $dipper,
                        out                     => !$dipper,
                        retval                  => 1,
                        shared                  => 0,
                        dipper                  => $dipper,
                        type                    => $self->_type($type),
                )
            ],
            result                  => $self->_ns_result(),
    );
    push @{$self->{itf}->{method_descriptors}}, $getter;
    unless (exists $node->{modifier}) {     # readonly
        my $setter = new XPT::MethodDescriptor(
                is_getter               => 0,
                is_setter               => 1,
#               is_not_xpcom            => $node->hasProperty('notxpcom'),
                is_not_xpcom            => 0,   # functionality or bug
                is_constructor          => 0,
                is_hidden               => $node->hasProperty('noscript'),
                name                    => $node->{idf},
                params                  => [
                    new XPT::ParamDescriptor(
                            in                      => 1,
                            out                     => 0,
                            retval                  => 0,
                            shared                  => 0,
                            dipper                  => 0,
                            type                    => $self->_type($type),
                    )
                ],
                result                  => $self->_ns_result(),
        );
        push @{$self->{itf}->{method_descriptors}}, $setter;
    }
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

