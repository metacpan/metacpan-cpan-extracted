
package XPT::ConstDescriptor;

use strict;
use warnings;

use base qw(XPT);

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $name = XPT::ReadCString($r_buffer, $r_offset);
    my $type = XPT::TypeDescriptor::demarshal($r_buffer, $r_offset);
    if ($type->{is_pointer}) {
        die "illegal type for const ! (is_pointer)\n";
    }
    my $value = undef;
    if    ($type->{tag} == XPT::int8) {
        $value = XPT::Read8($r_buffer, $r_offset);
        $value -= 256 if ($value > 127);
    }
    elsif ($type->{tag} == XPT::int16) {
        $value = XPT::Read16($r_buffer, $r_offset);
        $value -= 65536 if ($value > 32277);
    }
    elsif ($type->{tag} == XPT::int32) {
        $value = XPT::Read32($r_buffer, $r_offset);
        $value -= 4294967295 if ($value > 2147483647);
    }
    elsif ($type->{tag} == XPT::int64) {
        $value = XPT::Read64($r_buffer, $r_offset);
        # unsupported
    }
    elsif ($type->{tag} == XPT::uint8) {
        $value = XPT::Read8($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::uint16) {
        $value = XPT::Read16($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::uint32) {
        $value = XPT::Read32($r_buffer, $r_offset);
    }
    elsif ($type->{tag} == XPT::uint64) {
        $value = XPT::Read64($r_buffer, $r_offset);
        # unsupported
    }
    elsif ($type->{tag} == XPT::char) {
        $value = chr(XPT::Read8($r_buffer, $r_offset));
    }
    elsif ($type->{tag} == XPT::wchar_t) {
        $value = chr(XPT::Read16($r_buffer, $r_offset));
    }
    else {
        die "illegal type for const ! ($type->{tag})\n";
    }

    return new XPT::ConstDescriptor(
            name                    => $name,
            type                    => $type,
            value                   => $value,
    );
}

sub marshal {
    my $self = shift;
    my $type = $self->{type};
    my $value = $self->{value};
    my $buffer = XPT::WriteCString($self->{name});
    $buffer .= $type->marshal();
    if    ($type->{tag} == XPT::int8) {
        $value += 256 if ($value < 0);
        $buffer .= XPT::Write8($value);
    }
    elsif ($type->{tag} == XPT::int16) {
        $value += 65536 if ($value < 0);
        $buffer .= XPT::Write16($value);
    }
    elsif ($type->{tag} == XPT::int32) {
        $value += 4294967295 if ($value < 0);
        $buffer .= XPT::Write32($value);
    }
    elsif ($type->{tag} == XPT::int64) {
        $buffer .= XPT::Write64($value);
        # unsupported
    }
    elsif ($type->{tag} == XPT::uint8) {
        $buffer .= XPT::Write8($value);
    }
    elsif ($type->{tag} == XPT::uint16) {
        $buffer .= XPT::Write16($value);
    }
    elsif ($type->{tag} == XPT::uint32) {
        $buffer .= XPT::Write32($value);
    }
    elsif ($type->{tag} == XPT::uint64) {
        $buffer .= XPT::Write64($value);
        # unsupported
    }
    elsif ($type->{tag} == XPT::char) {
        $buffer .= XPT::Write8(ord $value);
    }
    elsif ($type->{tag} == XPT::wchar_t) {
        $buffer .= XPT::Write16(ord $value);
    }
    else {
        die "illegal type for const ! ($type->{tag})\n";
    }
    return $buffer;
}

sub stringify {
    my $self = shift;
    my ($indent) = @_;
    $indent = q{ } x 2 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;

    my $str = q{};
    if ($XPT::stringify_verbose) {
        $str .= $indent . "Name:   " . $self->{name} . "\n";
        $str .= $indent . "Type Descriptor: \n";
        $str .= $self->{type}->stringify($new_indent);
        $str .= $indent . "Value:  ";
    }
    else {
        $str .= $indent . $self->{type}->stringify() . q{ } . $self->{name} . ' = ';
    }
    $str .= $self->{value};
    if ($XPT::stringify_verbose) {
        $str .= "\n";
    }
    else {
        $str .= ";\n";
    }
    return $str;
}

1;

