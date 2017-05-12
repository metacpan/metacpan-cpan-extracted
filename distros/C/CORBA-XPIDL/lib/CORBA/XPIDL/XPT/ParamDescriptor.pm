
package XPT::ParamDescriptor;

use strict;
use warnings;

use base qw(XPT);

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $flags = XPT::Read8($r_buffer, $r_offset);
    my $type = XPT::TypeDescriptor::demarshal($r_buffer, $r_offset);

    return new XPT::ParamDescriptor(
            in                      => ($flags & 0x80) ? 1 : 0,
            out                     => ($flags & 0x40) ? 1 : 0,
            retval                  => ($flags & 0x20) ? 1 : 0,
            shared                  => ($flags & 0x10) ? 1 : 0,
            dipper                  => ($flags & 0x08) ? 1 : 0,
            type                    => $type,
    );
}

sub marshal {
    my $self = shift;
    my $flags = 0;
    $flags |= 0x80 if ($self->{in});
    $flags |= 0x40 if ($self->{out});
    $flags |= 0x20 if ($self->{retval});
    $flags |= 0x10 if ($self->{shared});
    $flags |= 0x08 if ($self->{dipper});
    my $buffer = XPT::Write8($flags);
    $buffer .= $self->{type}->marshal();
    return $buffer;
}

sub stringify {         # allways VERBOSE
    my $self = shift;
    my ($indent) = @_;
    $indent = q{ } x 2 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;

    my $str = q{};
    $str .= $indent . "In Param?   " . ($self->{in} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Out Param?  " . ($self->{out} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Retval?     " . ($self->{retval} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Shared?     " . ($self->{shared} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Dipper?     " . ($self->{dipper} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $indent . "Type Descriptor:\n";
    $str .= $self->{type}->stringify($new_indent);
    return $str;
}

1;

