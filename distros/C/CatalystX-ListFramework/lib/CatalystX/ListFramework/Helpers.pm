package CatalystX::ListFramework::Helpers;
use strict;
use warnings;
our $VERSION = '0.1';

sub lc {
    my ($data, $c, $formdef) = @_;
    return lc($data);
}
sub uc {
    my ($data, $c, $formdef) = @_;
    return uc($data);
}


package CatalystX::ListFramework::Helpers::Types;

our $VERSION = '0.1';

sub date {
    my ($data, $c, $formdef) = @_;
    $data =~ s/(\d{4})-(\d{2})-(\d{2})/$3\/$2\/$1/g;
    $data;
}

sub inversedate {
    my ($data, $c, $formdef) = @_;
    return $data if ($data =~ /^\d{4}\-\d{2}-\d{2}$/);
    if ($data =~ m/(\d+)\D(\d+)\D(\d+)/) {
        my ($d, $m, $y) = ($1, $2, $3);
        $y = $y+2000 if ($y<50);
        $y = $y+1900 if ($y<100);
        $data = sprintf('%04d-%02d-%02d', $y, $m, $d);
    }
    $data;
}

1;
