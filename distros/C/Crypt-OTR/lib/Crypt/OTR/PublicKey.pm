package Crypt::OTR::PublicKey;

use strict;
use warnings;

sub new {
    my ($class, %opts) = @_;

    return bless \%opts, $class;
}

sub data { $_[0]->{data} }
sub type { $_[0]->{type} }
sub size { $_[0]->{size} }

1;
