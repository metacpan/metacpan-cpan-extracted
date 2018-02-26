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
	$ret = {};
	while (my ($k, $val) = each %{$obj}) {
	    if ($k =~ /Date$/ && $val) {
		$ret->{$k} = bless DateTime::Format::ISO8601->
		                     parse_datetime($val),
		                   'App::Glacier::DateTime';
	    } else {
		$ret->{$k} = _to_timestamp($val);
	    }
	}
    } else {
	$ret = $obj;
    }
    return $ret;
}

sub timestamp_deserialize {
    return _to_timestamp(shift);
}

1;
