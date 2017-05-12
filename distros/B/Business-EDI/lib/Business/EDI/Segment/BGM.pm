package Business::EDI::Segment::BGM;

use base qw/Business::EDI::Segment/;

use strict;
use warnings;
use Carp;

our $VERSION = 0.02;
our $debug = 0;
our @codes = (
    'C002',
    'C106',
    1225,
    4343,
);
our @required_codes = ();

sub new {
    my $class = shift;
    my $obj = $class->SUPER::unblessed(shift, \@codes, $debug);
    unless ($obj) {
        carp "Unblessed object creation failed";
        return;
    }
    my $self = bless($obj, $class);
    $self->spec or $self->spec('default');
    return $self;
}

1;
__END__


THIS MODULE IS DEPRECATED.  Use Business::EDI->segment('BGM', $body)

Data comes in looking like, where the hashref is what gets passed to new():

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
