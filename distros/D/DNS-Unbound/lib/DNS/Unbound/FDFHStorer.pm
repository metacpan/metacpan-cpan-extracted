package DNS::Unbound::FDFHStorer;

use strict;
use warnings;

use parent 'DNS::Unbound';

# This class ensures that DNS::Unbound never close()s libunbound’s
# file descriptor.

my %fdfh;

sub _get_fh {
    my $fd = $_[0]->fd();

    if (!$fdfh{$fd}) {
        open $fdfh{$fd}, '+<&=' . $fd or die "FD ($fd) to Perl FH failed: $!";
    }

    return $fdfh{$fd};
}

1;
