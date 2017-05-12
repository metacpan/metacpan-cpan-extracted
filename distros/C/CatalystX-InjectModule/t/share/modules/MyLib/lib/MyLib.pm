package MyLib;

use Moose;
use Exporter qw(import);

our @EXPORT_OK = qw(ping);

sub ping { return 'pong' }

1;
