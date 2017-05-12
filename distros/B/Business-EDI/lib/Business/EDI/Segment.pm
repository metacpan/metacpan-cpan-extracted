package Business::EDI::Segment;

use base qw/Business::EDI/;
use strict;
use warnings;

use Carp;

our $VERSION = 0.01;

our $debug = 0;
our @codes = ();
our @required_codes = ();

sub new {
    my $class = shift;
    my $unblessed = $class->SUPER::unblessed(shift, \@codes);
    $unblessed or return;
    my $self = bless($unblessed, $class);
    $self->debug($debug);
    return $self;
}

1;
__END__

Data comes in looking like this, where the hashref is what gets passed to new():

    'BGM',
    {
        '1004' => '582822',
        '4343' => 'AC',
        '1225' => '29',     # ACCEPTED!
        'C002' => { '1001' => '231' }
    }

From the ORDRSP spec:

BGM - Beginning of message

A segment by which the sender must uniquely identify the order response by means of its number and when necessary its function.

 MESSAGE |
FUNCTION | Meaning
    CODE |
=================================================================
      12 | Total message was NOT processed, rejected or accepted. 
      27 | Rejected
      29 | ACCEPTED  (w/o Amendment)

      28 | Accepted w/ Amendment in Heading info 
      30 | Accepted w/ Amendment in Detail section (LIN)
      34 | Accepted w/ Amendment in Heading AND Detail

      12 | NOT PROCESSED: acknowledgement of receipt by seller, but remains to be processed within his application system.
       2 | NOT ACCEPTED

If 28 or 34, then all segments in the heading section must be used from the ORDRES or ORDCHG message being responded to. This includes both amended and non amended segments.
For 28, the Detail Section is considered as acknowledged without change.
