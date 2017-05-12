
package XPT::InterfaceDirectoryEntry;

use strict;
use warnings;

use base qw(XPT);

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $iid = XPT::IID::demarshal($r_buffer, $r_offset);
    my $name = XPT::ReadCString($r_buffer, $r_offset);
    my $name_space = XPT::ReadCString($r_buffer, $r_offset);
    my $interface_descriptor_offset = XPT::Read32($r_buffer, $r_offset);
    my $interface_descriptor = undef;
    if ($interface_descriptor_offset) {
        my $offset = $XPT::data_pool_offset + $interface_descriptor_offset - 1;
        $interface_descriptor = XPT::InterfaceDescriptor::demarshal($r_buffer, \$offset);
    }

    return new XPT::InterfaceDirectoryEntry(
            iid                     => $iid,
            name                    => $name,
            name_space              => $name_space,
            interface_descriptor    => $interface_descriptor,
    );
}

sub marshal {
    my $self = shift;
    my $buffer = $self->{iid}->marshal();
    $buffer .= XPT::WriteCString($self->{name});
    $buffer .= XPT::WriteCString($self->{name_space});
    if (defined $self->{interface_descriptor}) {
        $buffer .= $self->{interface_descriptor}->marshal();
    }
    else {
        $buffer .= XPT::Write32(0);
    }
    return $buffer;
}

sub stringify {
    my $self = shift;
    my ($indent) = @_;
    $indent = q{ } x 3 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;

    my $str = q{};
    my $iid = $self->{iid}->stringify();
    if ($XPT::stringify_verbose) {
        my $name_space = $self->{name_space} || 'none';
        $str .= $indent . "IID:                             " . $iid . "\n";
        $str .= $indent . "Name:                            " . $self->{name} . "\n";
        $str .= $indent . "Namespace:                       " . $name_space . "\n";
        $str .= $indent . "Descriptor:\n";
    }
    else {
        $str .= $indent . '- ' . $self->{name_space} . '::' . $self->{name};
        $str .= " (" . $iid . "):\n";
    }
    if (defined $self->{interface_descriptor}) {
        $str .= $self->{interface_descriptor}->stringify($new_indent);
    }
    else {
        $str .= $indent . "   [Unresolved]\n";
    }
    return $str;
}

1;

