
package XPT::IID;

use strict;
use warnings;

use Carp;

use base qw(XPT);

use constant IID_NUL    => chr(0) x 16;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $data = shift;
    my $self = \$data;
    bless $self, $class;
    return $self
}

sub demarshal {
    my ($r_buffer, $r_offset) = @_;

    my $iid = XPT::ReadBuffer($r_buffer, $r_offset, 16);

    return new XPT::IID($iid);
}

sub marshal {
    my $self = shift;
    croak "bad length.\n"
            unless (length ${$self} == length XPT::File::MAGIC);
    return ${$self};
}

sub stringify {
    my $self = shift;
    my $str = q{};
    my $idx = 0;
    foreach (split //, ${$self}) {
        $str .= sprintf("%02x", ord $_);
        $idx ++;
        $str .= '-' if ($idx == 4 or $idx == 6 or $idx == 8 or $idx == 10);
    }
    return $str;
}

sub _is_nul {
    my $self = shift;
    return ${$self} eq IID_NUL;
}

1;

