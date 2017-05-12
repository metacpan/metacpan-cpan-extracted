
package XPT::Annotation;

use strict;
use warnings;

use base qw(XPT);

sub demarshal {
    my ($r_buffer, $r_offset) = @_;
    my $annotation = new XPT::Annotation();

    my $flags = XPT::Read8($r_buffer, $r_offset);
    my $tag = $flags & 0x7f;

    if ($tag) {
        my $creator = XPT::ReadStringInline($r_buffer, $r_offset);
        my $private_data = XPT::ReadStringInline($r_buffer, $r_offset);

        return new XPT::Annotation(
                is_last                 => ($flags & 0x80) ? 1 : 0,
                tag                     => $tag,
                creator                 => $creator,
                private_data            => $private_data,
        );
    }
    else {
        return new XPT::Annotation(
                is_last                 => ($flags & 0x80) ? 1 : 0,
                tag                     => 0,
        );
    }
}

sub marshal {
    my $self = shift;
    my $tag = $self->{tag};
    $tag += 0x80 if ($self->{is_last});
    my $buffer = XPT::Write8($tag);
    if ($self->{tag}) {
        $buffer .= XPT::WriteStringInline($self->{creator});
        $buffer .= XPT::WriteStringInline($self->{private_data});
    }
    return $buffer;
}

sub stringify {
    my $self = shift;
    my ($indent) = @_;
    $indent = q{ } x 3 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;

    my $str = q{};
    if ($self->{tag}) {
        if ($XPT::stringify_verbose) {
            $str .= " is private.\n";
        }
        else {
            $str .= ":\n";
        }
        $indent .= q{ } x 3;
        $str .= $new_indent . "Creator:      " . $self->{creator} . "\n";
        $str .= $new_indent . "Private Data: " . $self->{private_data} . "\n";
    }
    else {
        $str .= " is empty.\n";
    }
    return $str;
}

1;

