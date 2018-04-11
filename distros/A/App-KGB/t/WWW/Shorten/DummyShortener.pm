package WWW::Shorten::DummyShortener;

use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw(makeashorterlink makealongerlink);
our $VERSION = '0.0';

use Carp;

my $LINK_COUNTER = 0;
my $URL_BASE = 'http://l.nk/';

sub makeashorterlink {
    my $url = shift or croak 'No URL passed to makeashorterlink';
    return sprintf( "%s%d", $URL_BASE, $LINK_COUNTER++ );
}

sub makealongerlink {
    die "Not implemented. This is a dummy test module, okay?";
}

1;
