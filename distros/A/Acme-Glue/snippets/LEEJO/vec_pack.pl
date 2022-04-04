#!/usr/bin/env perl -wl

print <<'EOT';
								  0         1         2         3
				   unpack("V",$_) 01234567890123456789012345678901
------------------------------------------------------------------
EOT

for $w (0..3) {
	$width = 2**$w;
	for ($shift=0; $shift < $width; ++$shift) {
		for ($off=0; $off < 32/$width; ++$off) {
			$str = pack("B*", "0"x32);
			$bits = (1<<$shift);
			vec($str, $off, $width) = $bits;
			$res = unpack("b*",$str);
			$val = unpack("V", $str);
			write;
		}
	}
}

format STDOUT =
vec($_,@#,@#) = @<< == @######### @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$off, $width, $bits, $val, $res
.
__END__
