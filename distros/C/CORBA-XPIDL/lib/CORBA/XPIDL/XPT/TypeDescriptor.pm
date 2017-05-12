
package XPT::TypeDescriptor;

use strict;
use warnings;

use base qw(XPT);

use Carp;

use constant TYPE_ARRAY => [
    'int8',        'int16',       'int32',       'int64',
    'uint8',       'uint16',      'uint32',      'uint64',
    'float',       'double',      'boolean',     'char',
    'wchar_t',     'void',        'reserved',    'reserved',
    'reserved',    'reserved',    'reserved',    'reserved',
    'reserved',    'reserved',    'reserved',    'reserved',
    'reserved',    'reserved',    'reserved',    'reserved',
    'reserved',    'reserved',    'reserved',    'reserved'
];

use constant PTYPE_ARRAY => [
    'int8 *',      'int16 *',     'int32 *',     'int64 *',
    'uint8 *',     'uint16 *',    'uint32 *',    'uint64 *',
    'float *',     'double *',    'boolean *',   'char *',
    'wchar_t *',   'void *',      'nsIID *',     'DOMString *',
    'string',      'wstring',     'Interface *', 'InterfaceIs *',
    'array',       'string_s',    'wstring_s',   'UTF8String *',
    'CString *',   'AString *',   'reserved',    'reserved',
    'reserved',    'reserved',    'reserved',    'reserved'
];

use constant RTYPE_ARRAY => [
    'int8 &',      'int16 &',     'int32 &',     'int64 &',
    'uint8 &',     'uint16 &',    'uint32 &',    'uint64 &',
    'float &',     'double &',    'boolean &',   'char &',
    'wchar_t &',   'void &',      'nsIID &',     'DOMString &',
    'string &',    'wstring &',   'Interface &', 'InterfaceIs &',
    'array &',     'string_s &',  'wstring_s &', 'UTF8String &',
    'CString &',   'AString &',   'reserved',    'reserved',
    'reserved',    'reserved',    'reserved',    'reserved'
];

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $flags = XPT::Read8($r_buffer, $r_offset);

    my $type = new XPT::TypeDescriptor(
            is_pointer              => ($flags & 0x80) ? 1 : 0,
            is_unique_pointer       => ($flags & 0x40) ? 1 : 0,
            is_reference            => ($flags & 0x20) ? 1 : 0,
            tag                     => $flags & 0x1f,
    );

    if    ($type->{tag} <  XPT::InterfaceTypeDescriptor) {
        # SimpleTypeDescriptor
    }
    elsif ($type->{tag} == XPT::InterfaceTypeDescriptor) {
        croak "is_pointer is not set!\n"
                unless ($type->{is_pointer});
        $type->{interface_index} = XPT::Read16($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::InterfaceIsTypeDescriptor) {
        croak "is_pointer is not set!\n"
                unless ($type->{is_pointer});
        $type->{arg_num} = XPT::Read8($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::ArrayTypeDescriptor) {
        croak "is_pointer is not set!\n"
                unless ($type->{is_pointer});
        $type->{size_is_arg_num} = XPT::Read8($r_buffer, $r_offset);
        $type->{length_is_arg_num} = XPT::Read8($r_buffer, $r_offset);
        $type->{type_descriptor} = XPT::TypeDescriptor::demarshal($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::StringWithSizeTypeDescriptor) {
        croak "is_pointer is not set!\n"
                unless ($type->{is_pointer});
        $type->{size_is_arg_num} = XPT::Read8($r_buffer, $r_offset);
        $type->{length_is_arg_num} = XPT::Read8($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::WideStringWithSizeTypeDescriptor) {
        croak "is_pointer is not set!\n"
                unless ($type->{is_pointer});
        $type->{size_is_arg_num} = XPT::Read8($r_buffer, $r_offset);
        $type->{length_is_arg_num} = XPT::Read8($r_buffer, $r_offset);
    }
    else {
        # reserved
    }
    return $type;
}

sub marshal {
    my $self = shift;
    my $flags = $self->{tag};
    $flags |= 0x80 if ($self->{is_pointer});
    $flags |= 0x40 if ($self->{is_unique_pointer});
    $flags |= 0x20 if ($self->{is_reference});
    my $buffer = XPT::Write8($flags);
    if    ($self->{tag} <  XPT::InterfaceTypeDescriptor) {
        # SimpleTypeDescriptor
    }
    elsif ($self->{tag} == XPT::InterfaceTypeDescriptor) {
        $buffer .= XPT::Write16($self->{interface_index});
    }
    elsif ($self->{tag} == XPT::InterfaceIsTypeDescriptor) {
        $buffer .= XPT::Write8($self->{arg_num});
    }
    elsif ($self->{tag} == XPT::ArrayTypeDescriptor) {
        $buffer .= XPT::Write8($self->{size_is_arg_num});
        $buffer .= XPT::Write8($self->{length_is_arg_num});
        $buffer .= $self->{type_descriptor}->marshal();
    }
    elsif ($self->{tag} == XPT::StringWithSizeTypeDescriptor) {
        $buffer .= XPT::Write8($self->{size_is_arg_num});
        $buffer .= XPT::Write8($self->{length_is_arg_num});
    }
    elsif ($self->{tag} == XPT::WideStringWithSizeTypeDescriptor) {
        $buffer .= XPT::Write8($self->{size_is_arg_num});
        $buffer .= XPT::Write8($self->{length_is_arg_num});
    }
    else {
        # reserved
    }
    return $buffer;
}

sub stringify {
    my $self = shift;
    return $self->_get_string()
            unless ($XPT::stringify_verbose);
    my ($indent) = @_;
    $indent = q{ } x 2 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;

    my $str = q{};
    $str .= $indent . "Is Pointer?        " . ($self->{is_pointer} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Is Unique Pointer? " . ($self->{is_unique_pointer} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Is Reference?      " . ($self->{is_reference} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Tag:               " . $self->{tag} . "\n";

    if       ( $self->{tag} == XPT::StringWithSizeTypeDescriptor
            or $self->{tag} == XPT::WideStringWithSizeTypeDescriptor ) {
        $str .= $indent . " - size in arg " . $self->{size_is_arg_num};
            $str .= " and length in arg " . $self->{length_is_arg_num} . "\n";
    }
    if ($self->{tag} == XPT::InterfaceTypeDescriptor) {
        $str .= $indent . "InterfaceTypeDescriptor:\n";
        $str .= $new_indent . "Index of IDE:             " . $self->{interface_index} . "\n";
    }
    if ($self->{tag} == XPT::InterfaceIsTypeDescriptor) {
        $str .= $indent . "InterfaceTypeDescriptor:\n";
        $str .= $new_indent . "Index of Method Argument: " . $self->{arg_num} . "\n";
    }
    return $str;
}

sub _get_string {
    my $self = shift;

    if ($self->{tag} == XPT::ArrayTypeDescriptor) {
        return $self->{type_descriptor}->_get_string() . ' []';
    }

    my $str = q{};
    if ($self->{tag} == XPT::InterfaceTypeDescriptor) {
        if (defined $self->{interface}) {
            $str = $self->{interface}->{name};
        }
        else {
            $str = 'UNKNOWN_INTERFACE';
        }
    }
    elsif ($self->{is_pointer}) {
        if ($self->{is_reference}) {
            $str = RTYPE_ARRAY->[$self->{tag}];
        }
        else {
            $str = PTYPE_ARRAY->[$self->{tag}];
        }
    }
    else {
        $str = TYPE_ARRAY->[$self->{tag}];
    }

    return $str;
}

1;

