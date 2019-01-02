package App::Glacier::Timestamp;
use strict;
use warnings;
use Carp;
our @ISA = qw(Exporter);
our @EXPORT = qw(timestamp_deserialize);
use DateTime::Format::ISO8601;
use App::Glacier::DateTime;

sub _to_timestamp {
    my $obj = shift;
    my $ret;
    
    if (ref($obj) eq 'ARRAY') {
        $ret = [ map { _to_timestamp($_) } @{$obj} ];
    } elsif (ref($obj) eq 'HASH') {
        $ret = {map {
            my $v = $obj->{$_};
            if (/Date$/ && defined($v)) {
                $_ => bless DateTime::Format::ISO8601->
                                     parse_datetime($v),
                                   'App::Glacier::DateTime';
            } else {
                $_ => _to_timestamp($v);
            }
        } keys %$obj};
    } else {
        $ret = $obj;
    }
    
    return $ret;
}

sub timestamp_deserialize {
    return _to_timestamp(shift);
}

1;
