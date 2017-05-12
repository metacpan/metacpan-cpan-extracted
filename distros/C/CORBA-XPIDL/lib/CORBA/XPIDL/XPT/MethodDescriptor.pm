
package XPT::MethodDescriptor;

use strict;
use warnings;

use base qw(XPT);

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $flags = XPT::Read8($r_buffer, $r_offset);
    my $name = XPT::ReadCString($r_buffer, $r_offset);
    my $num_args = XPT::Read8($r_buffer, $r_offset);
    my @params = ();
    while ($num_args --) {
        my $param = XPT::ParamDescriptor::demarshal($r_buffer, $r_offset);
        push @params, $param;
    }
    my $result = XPT::ParamDescriptor::demarshal($r_buffer, $r_offset);

    return new XPT::MethodDescriptor(
            is_getter               => ($flags & 0x80) ? 1 : 0,
            is_setter               => ($flags & 0x40) ? 1 : 0,
            is_not_xpcom            => ($flags & 0x20) ? 1 : 0,
            is_constructor          => ($flags & 0x10) ? 1 : 0,
            is_hidden               => ($flags & 0x08) ? 1 : 0,
            name                    => $name,
            params                  => \@params,
            result                  => $result,
    );
}

sub marshal {
    my $self = shift;
    my $flags = 0;
    $flags |= 0x80 if ($self->{is_getter});
    $flags |= 0x40 if ($self->{is_setter});
    $flags |= 0x20 if ($self->{is_not_xpcom});
    $flags |= 0x10 if ($self->{is_constructor});
    $flags |= 0x08 if ($self->{is_hidden});
    my $buffer = XPT::Write8($flags);
    $buffer .= XPT::WriteCString($self->{name});
    $buffer .= XPT::Write8(scalar(@{$self->{params}}));
    foreach (@{$self->{params}}) {
        $buffer .= $_->marshal();
    }
    $buffer .= $self->{result}->marshal();
    return $buffer;
}

sub stringify {
    my $self = shift;
    my ($indent) = @_;
    $indent = q{ } x 6 unless (defined $indent);
    my $new_indent = $indent . q{ } x 3;
    my $more_indent = $new_indent . q{ } x 3;

    my $str = q{};
    if ($XPT::stringify_verbose) {
        $str .= $indent . "Name:             " . $self->{name} . "\n";
        $str .= $indent . "Is Getter?        " . ($self->{is_getter} ? 'TRUE' : 'FALSE') . "\n";
        $str .= $indent . "Is Setter?        " . ($self->{is_setter} ? 'TRUE' : 'FALSE') . "\n";
        $str .= $indent . "Is NotXPCOM?      " . ($self->{is_not_xpcom} ? 'TRUE' : 'FALSE') . "\n";
        $str .= $indent . "Is Constructor?   " . ($self->{is_constructor} ? 'TRUE' : 'FALSE') . "\n";
        $str .= $indent . "Is Hidden?        " . ($self->{is_hidden} ? 'TRUE' : 'FALSE') . "\n";
        $str .= $indent . "# of arguments:   " . scalar(@{$self->{params}}) . "\n";
        $str .= $indent . "Parameter Descriptors:\n";
        my $nb = 0;
        foreach (@{$self->{params}})  {
            $str .= $new_indent . "Parameter #" . $nb ++ . ":\n";
            if (!$_->{in} and !$_->{out}) {
                $str .= "XXX\n";
                $XPT::param_problems = 1;
            }
            $str .= $_->stringify($more_indent);
        }
        $str .= $indent . "Result:\n";
        if (        $self->{result}->{type}->{tag} != XPT::void
                and $self->{result}->{type}->{tag} != XPT::uint32) {
            $str .= "XXX\n";
            $XPT::param_problems = 1;
        }
        $str .= $self->{result}->stringify($new_indent);
    }
    else {
        $str .= substr($indent, 6);
        $str .= ($self->{is_getter} ? 'G' :  q{ });
        $str .= ($self->{is_setter} ? 'S' :  q{ });
        $str .= ($self->{is_hidden} ? 'H' :  q{ });
        $str .= ($self->{is_not_xpcom} ? 'N' :  q{ });
        $str .= ($self->{is_constructor} ? 'C' :  q{ });
        $str .= q{ } . $self->{result}->{type}->stringify() . q{ } . $self->{name} . '(';
        my $first = 1;
        foreach (@{$self->{params}})  {
            $str .= ', ' unless ($first);
            if ($_->{in}) {
                $str .= 'in';
                if ($_->{out}) {
                    $str .= 'out ';
                    $str .= 'retval ' if ($_->{retval});
                    $str .= 'shared ' if ($_->{shared});
                }
                else {
                    $str .= q{ };
                    $str .= 'dipper ' if ($_->{dipper});
                    $str .= 'retval ' if ($_->{retval});
                }
            }
            else {
                if ($_->{out}) {
                    $str .= 'out ';
                    $str .= 'retval ' if ($_->{retval});
                    $str .= 'shared ' if ($_->{shared});
                }
                else {
                    $XPT::params_problems = 1;
                    $str .= 'XXX ';
                }
            }
            $str .= $_->{type}->stringify();
            $first = 0;
        }
        $str .= ");\n";
    }
    return $str;
}

1;

