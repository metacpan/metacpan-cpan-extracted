
package XPT::InterfaceDescriptor;

use strict;
use warnings;

use base qw(XPT);

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $parent_interface_index = XPT::Read16($r_buffer, $r_offset);
    my @method_descriptors = ();
    my @const_descriptors = ();
    my $flags = 0;
    eval {
        my $num_methods = XPT::Read16($r_buffer, $r_offset);
        while ($num_methods --) {
            my $method = XPT::MethodDescriptor::demarshal($r_buffer, $r_offset);
            push @method_descriptors, $method;
        }
        my $num_constants = XPT::Read16($r_buffer, $r_offset);
        while ($num_constants --) {
            my $const = XPT::ConstDescriptor::demarshal($r_buffer, $r_offset);
            push @const_descriptors, $const;
        }
        $flags = XPT::Read8($r_buffer, $r_offset);
    };
    if ($@) {
        $XPT::demarshal_retcode = 1;
        if ($XPT::demarshal_not_abort) {
            warn $@;
        }
        else {
            die $@;
        }
    }

    return new XPT::InterfaceDescriptor(
            parent_interface_index  => $parent_interface_index,
            method_descriptors      => \@method_descriptors,
            const_descriptors       => \@const_descriptors,
            is_scriptable           => ($flags & 0x80) ? 1 : 0,
            is_function             => ($flags & 0x40) ? 1 : 0,
    );
}

sub marshal {
    my $self = shift;
    my $method_descriptors = q{};
    foreach (@{$self->{method_descriptors}}) {
        $method_descriptors .= $_->marshal();
    }
    my $const_descriptors = q{};
    foreach (@{$self->{const_descriptors}}) {
        $const_descriptors .= $_->marshal();
    }
    my $flags = 0;
    $flags |= 0x80 if ($self->{is_scriptable});
    $flags |= 0x40 if ($self->{is_function});
    my $offset = 1 + length($XPT::data_pool);
    $XPT::data_pool .= XPT::Write16($self->{parent_interface_index});
    $XPT::data_pool .= XPT::Write16(scalar(@{$self->{method_descriptors}}));
    $XPT::data_pool .= $method_descriptors;
    $XPT::data_pool .= XPT::Write16(scalar(@{$self->{const_descriptors}}));
    $XPT::data_pool .= $const_descriptors;
    $XPT::data_pool .= XPT::Write8($flags);
    return XPT::Write32($offset);
}

sub stringify {
    my $self = shift;
    my ($indent) = @_;
    $indent = q{ } x 2 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;
    my $more_indent = $new_indent . q{ } x 3;

    my $str = q{};
    if ($self->{parent_interface_index}) {
        my $name;
        if (defined $self->{parent_interface}) {
            my $itf = $self->{parent_interface};
            if (ref $itf) {
                $name = $itf->{name_space} . '::' . $itf->{name};
            }
            else {
                $name = $itf;
            }
        }
        else {
            $name = "UNKNOWN_INTERFACE";
        }
        $str .= $indent . "Parent: " . $name . "\n"
    }
    $str .= $indent . "Flags:\n";
    $str .= $new_indent . "Scriptable: " . ($self->{is_scriptable} ? 'TRUE' : 'FALSE') . "\n";
    $str .= $new_indent . "Function: " . ($self->{is_function} ? 'TRUE' : 'FALSE') . "\n";
    if ($XPT::stringify_verbose and exists $self->{parent_interface_index}) {
        $str .= $indent . "Index of parent interface (in data pool): ";
            $str .= $self->{parent_interface_index} . "\n";
    }
    if (scalar @{$self->{method_descriptors}}) {
        if ($XPT::stringify_verbose) {
            $str .= $indent . "# of Method Descriptors:                   ";
                $str .= scalar(@{$self->{method_descriptors}}) . "\n";
        }
        else {
            $str .= $indent . "Methods:\n";
        }
        my $nb = 0;
        foreach (@{$self->{method_descriptors}}) {
            if ($XPT::stringify_verbose) {
                $str .= $new_indent . "Method #" . $nb ++ . ":\n";
                $str .= $_->stringify($more_indent);
            }
            else {
                $str .= $_->stringify($new_indent);
            }
        }
    }
    else {
        $str .= $indent . "Methods:\n";
        $str .= $new_indent . "No Methods\n";
    }
    if (scalar @{$self->{const_descriptors}}) {
        if ($XPT::stringify_verbose) {
            $str .= $indent . "# of Constant Descriptors:                  ";
                $str .= scalar(@{$self->{const_descriptors}}) . "\n";
        }
        else {
            $str .= $indent . "Constants:\n";
        }
        my $nb = 0;
        foreach (@{$self->{const_descriptors}}) {
            if ($XPT::stringify_verbose) {
                $str .= $new_indent . "Constant #" . $nb ++ . ":\n";
                $str .= $_->stringify($more_indent);
            }
            else {
                $str .= $_->stringify($new_indent);
            }
        }
    }
    else {
        $str .= $indent . "Constants:\n";
        $str .= $new_indent . "No Constants\n";
    }
    return $str;
}

1;

