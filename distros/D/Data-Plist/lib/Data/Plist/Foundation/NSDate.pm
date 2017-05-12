package Data::Plist::Foundation::NSDate;

use strict;
use warnings;

use base qw/Data::Plist::Foundation::NSObject DateTime/;

sub replacement {
    my $self = shift;
    my $dt = DateTime->from_epoch( epoch => $self->{"NS.time"} + 978307200 );
    bless $dt, ( ref $self );
    return $dt;
}

sub serialize_equiv {
    my $self = shift;
    my $secs = ( $self->epoch - 978307200 );
    $secs += $self->nanosecond / 1e9;
    $secs .= ".0"
        unless $secs =~ /\D/;    # This forces it to be stored as "real"
    return { "NS.time" => $secs };
}

1;

