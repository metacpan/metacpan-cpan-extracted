package Class::PINT::DataTypes::Bitmask;

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&_list2dec &_dec2bin &_bin2dec &_list2bin);

use Math::BigInt;
# use Math::BigIntFast; # faster uses Bit::Vector

use constant LENGTH => 128; # 16 bytes !!

sub _list2dec {
    my (@values) = @_;
    my $bitstring = '';
    my $c = 0;
    my $cur_val = $values[$c++];
    for ( my $i = 1; $i <= LENGTH; $i++ ) {
        my $val = "0";
#       warn "val:$val\n";
        if ($i == $cur_val) {
            $val = '1';
            $cur_val = $values[$c++];
            last unless (defined $cur_val);
        }
        $bitstring = $val.$bitstring;
    }

    warn "bitstring : $bitstring\n";
    my $value = new Math::BigInt ("0b".substr("0" x LENGTH . $bitstring, - LENGTH ));
    warn "value : $value \n";
    warn "value in binary : ", $value->as_bin(), "\n";
    return $value;
}

sub _list2bin {
    my $value = _list2dec(@_);
    my $bin = $value->as_bin();
    return $bin;
}

sub _bin2dec {
    my ($value,$size) = @_;
    $size ||= 32;
    my $bitstring = 0;
    if ($size > 32) {
	$bitstring = unpack("N", pack("B$size", substr("0" x 32 . $value, -32)));
    } else {
	my $bignum = $value = new Math::BigInt ("0b".substr("0" x LENGTH . $value, - LENGTH ));
	$bitstring = $bignum->as_int();
    }
    return $bitstring;
}

sub _dec2bin {
    my ($value,$size) = @_;
    $size ||= 32;
    my $decstring = 0;
    if ($size > 32) {
	$decstring = unpack("B$size", pack("N", $value));
    } else {
	my $bignum = $value = new Math::BigInt ("0b".substr("0" x LENGTH . $value, - LENGTH ));
	$decstring = $bignum->as_dec();
    }
    return $decstring;
}
