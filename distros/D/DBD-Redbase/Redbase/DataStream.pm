###############################################################################
#
#                BUNGISOFT, INC.
#
#                PROPRIETARY DATA
#
#  THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF
#  BUNGISOFT, INC. THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
#  CONFIDENCE. INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR
#  DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT
#  SIGNED BY AN OFFICER OF BUNGISOFT, INC.
#
#  THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
#  SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE.
#  UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
#
#  Copyright (c) 2002 Bungisoft, Inc.
#
#  Version: $Id: DataStream.pm,v 1.2 2002/08/20 21:22:21 ilya Exp $
#
###############################################################################

#Note: Functions currently not implemented: 
# writeDate($$)
# writeTime($$)
# writeTimestamp($$)
# writeButeArray($$)
# writeDecimal($$)

package DBD::Redbase::DataStream;

use strict;
use warnings;

use Math::BigInt;
use Math::BigFloat;
use POSIX;
use IO::Handle;
use Unicode::String qw(utf8);
use Bit::Vector::Overload;

#Global variables
my $CONST = 2102; #1 carry bit + 1023 + 1 + 1022 + 53 + 2 (round bits)
my $BIAS = 1024;
my $NORMAL = 1;
my $UNDERFLOW = 2;
my $OVERFLOW = 3;
my $DENORMALIZED = 4;
my $FLOAT_MAX_EXP = 38;
my $FLOAT_MAX_NUM = 3.40282347;
my $DOUBLE_MAX_EXP = 308;
my $DOUBLE_MAX_NUM = 1.7976931348623157;

my $EXPBIAS;
my $MAXEXP;
my $MINEXP;
my $MINUNNORMEXP;
my $FLOATSTATUS;

#Input/output filehandles
my $FHOUT;
my $FHIN;

#Resettable bytes counter
my $byte_count;

###############################################################################
# Constructor for DataStream, takes in two arguments input filehandle and
# output file handle
###############################################################################
sub new($$$)
{
	my $this = shift();
	$FHIN = shift();
	$FHOUT = shift();
	$byte_count = 0;

	my $class = ref($this) || $this;
	return bless({}, $class);
}

###############################################################################
# This routine resets the byte counter
###############################################################################
sub resetByteCount()
{
	$byte_count = 0;
}

###############################################################################
# This routine is used to query byte counter
###############################################################################
sub getByteCount()
{
	return $byte_count;
}

###############################################################################
# The following is public write functions for the object
###############################################################################
sub writeUTF($)
{
	my $this = shift;
	my $string = _writeUTF(shift);
	$FHOUT->print(_writeShort(length($string)));
	$FHOUT->print($string);
}

sub writeString($)
{
	my $this = shift;
	my $string = _writeUTF(shift);
	$FHOUT->print(_writeInt(length($string)));
	$FHOUT->print($string);
}

sub writeChar($)
{
	my $this = shift;
	$FHOUT->print(_writeChar(shift()));
}

sub writeBoolean($)
{
	my $this = shift;
	$FHOUT->print(_writeBoolean(shift()));
}

sub writeByte($)
{
	my $this = shift;
	$FHOUT->print(_writeByte(shift()));
}

sub writeUnsignedByte($)
{
	my $this = shift;
	$FHOUT->print(_writeUnsignedByte(shift()));
}

sub writeShort($)
{
	my $this = shift;
	$FHOUT->print(_writeShort(shift()));
}

sub writeUnsignedShort($)
{
	my $this = shift;
	$FHOUT->print(_writeUnsignedShort(shift()));
}

sub writeInt($)
{
	my $this = shift;
	$FHOUT->print(_writeInt(shift()));
}

sub writeLong($)
{
	my $this = shift;
	$FHOUT->print(_writeLong(shift()));
}

sub writeFloat($)
{
	my $this = shift;
	$FHOUT->print(_writeFloat(shift()));
}

sub writeDouble($)
{
	my $this = shift;
	$FHOUT->print(_writeDouble(shift()));
}

sub readUTF($)
{
	my $this = shift;
	my $bytes_to_read;
	my $buf;

	$bytes_to_read = $this->readShort();
	$FHIN->read($buf, $bytes_to_read);

	$byte_count += $bytes_to_read;

	return _readUTF($buf);
}

sub readString($)
{
	my $this = shift;
	my $bytes_to_read;
	my $buf;

	$bytes_to_read = $this->readInt();
	$FHIN->read($buf, $bytes_to_read);
	
	$byte_count += $bytes_to_read;

	return _readUTF($buf);
}

sub readChar($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 2);

	$byte_count += 2;

	return _readChar($buf);
}

sub readBoolean($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 1);

	$byte_count += 1;

	return _readBoolean($buf);
}

sub readByte($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 1);

	$byte_count += 1;

	return _readByte($buf);
}

sub readUnsignedByte($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 1);

	$byte_count += 1;

	return _readUnsignedByte($buf);
}

sub readShort($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 2);

	$byte_count += 2;

	return _readShort($buf);
}

sub readUnsignedShort($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 2);

	$byte_count += 2;

	return _readUnsignedShort($buf);
}

sub readInt($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 4);

	$byte_count += 4;

	return _readInt($buf);
}


sub readLong($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 8);

	$byte_count += 8;

	return _readLong($buf);
}

sub readFloat($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 4);

	$byte_count += 4;

	return _readFloat($buf);
}

sub readDouble($)
{
	my $this = shift;
	my $buf;

	$FHIN->read($buf, 8);

	$byte_count += 8;

	return _readDouble($buf);
}

sub readDate($)
{
	my $this = shift;
	my $long;
	my @time;
	
	$long = $this->readLong();
	
	#Since number is in milliseconds and not seconds
	@time = localtime(substr($long, 0, length($long) - 3));

	return sprintf("%04d-%02d-%02d", ($time[5] + 1900), ($time[4] + 1), $time[3]);
}

sub readTime($)
{
	my $this = shift;
	my $long;
	my @time;
	
	$long = $this->readLong();
	
	#Since number is in milliseconds and not seconds
	@time = localtime(substr($long,0, length($long) - 3));

	return sprintf("%02d:%02d:%02d", $time[2], $time[1], $time[0]);
}

sub readTimestamp($)
{
	my $this = shift;
	my $stamp;
	my $nanos;
	my @time;

	$stamp = $this->readLong();
	$nanos = $this->readInt();
	
	#Since number is in milliseconds and not seconds
	@time = localtime(substr($stamp, 0, length($stamp) - 3));

	return sprintf("%04d-%02d-%02d %02d:%02d:%02d.%d",
		($time[5] + 1900),
		($time[4] + 1),
		$time[3],
		$time[2],
		$time[1],
		$time[0],
		$nanos);
}

sub readByteArray($)
{
	my $this = shift;
	my $buf;
	my $size;

	$size = $this->readInt();
	$FHIN->read($buf, $size);

	$byte_count += $size;

	return $buf;
}

sub readDecimal($)
{
	my $this = shift;
	my $bytes;
	my $scale;

	return _readDecimal($this->readByteArray(), $this->readInt());

}

###############################################################################
#                 PRIVATE FUNCTIONS
###############################################################################

###############################################################################
# This function return string compatible with with javas Input/OutputStream
# readUTF method
###############################################################################
sub _writeUTF($)
{
	my $unicode_string = utf8(shift());
	while ((my $pos = index($unicode_string, "\000")) > -1)
	{
		$unicode_string = substr($unicode_string, 0, $pos) . chr(192) . chr(128) . substr($unicode_string, $pos + 1);
	}
	return $unicode_string;
}

###############################################################################
# This method writes binary char compatible with Java
###############################################################################
sub _writeChar($)
{
	my $u = new Unicode::String(shift());
	my $f = $u->hex();
	
	#Chopping to have only a single char
	$f =~ s/ .*$//;
	$f =~ s/^U\+/0x/;
	return _writeShort(oct($f));
}

###############################################################################
# This method writes binary boolean compatible with Java
###############################################################################
sub _writeBoolean($)
{
	my $b = shift();
	if ((!defined($b)) || ($b == 0) || ($b =~ /^false$/i))
	{
		return pack("x");
	}
	else
	{
		return pack("C", 0x01);
	}
}

###############################################################################
# This method writes binary byte compatible with Java
###############################################################################
sub _writeUnsignedByte($)
{
	return _writeByte(shift());
}

###############################################################################
# This method writes binary byte compatible with Java
###############################################################################
sub _writeByte($)
{
	my $i = int(shift());

	#Chopping integer if too big
	if ($i > 0xff)
	{
		$i = $i & 0xff;
	}

	return pack("C", $i);
}

###############################################################################
# This method writes binary short compatible with Java
###############################################################################
sub _writeShort($)
{
	my $i = int(shift());

	#Chopping integer if too big
	if ($i > 0xffff)
	{
		$i = $i & 0xffff;
	}

	return pack("CC", (($i & 0xff00) >> 8), ($i & 0x00ff));
}

###############################################################################
# This method writes unsigned binary short compatible with Java
###############################################################################
sub _writeUnsignedShort($)
{
	return _writeShort(shift());
}

###############################################################################
# This method writes binary int compatible with Java
###############################################################################
sub _writeInt($)
{
	my $i = int(shift());

	#Chopping integer if too big
	if ($i > 0xffffffff)
	{
		$i = $i & 0xffffffff;
	}

	return pack("CCCC", (($i & 0xff000000) >> 24), (($i & 0x00ff0000) >> 16), (($i & 0x0000ff00) >> 8), ($i & 0x000000ff));
}

###############################################################################
# This method writes binary long compatible with Java
###############################################################################
sub _writeLong($)
{
	my $bvector = Bit::Vector->new_Dec(64, shift());
	return pack("B64", $bvector->to_Bin());
}

###############################################################################
# This method writes float number compatible with java and
# IEEE 754 single precision
###############################################################################
sub _writeFloat($)
{
	return pack("B32", _convert_to_ieee(shift(), 32));
}

###############################################################################
# This method writes float number compatible with java and
# IEEE 754 single precision
###############################################################################
sub _writeDouble($)
{
	return pack("B64", _convert_to_ieee(shift(), 64));
}

###############################################################################
# The following functions support ieee 754 conversion from strings
###############################################################################
sub _convert_to_ieee($$)
{
	my $number = shift;
	my $size = shift;

	my @Result;
	my @BinValue;

	$FLOATSTATUS = $NORMAL;

	if($size == 32)
	{
		$EXPBIAS = 127;
		$MAXEXP = 127;
		$MINEXP = -126;
		$MINUNNORMEXP = -149;
	}
	else
	{
		$EXPBIAS = 1023;
		$MAXEXP = 1023;
		$MINEXP = -1022;
		$MINUNNORMEXP = -1074;
	}

	#Intializing @BinValue
	for(my $i = 0; $i < $CONST; $i++)
	{
		$BinValue[$i] = 0;
	}

	#Initializing @Result
	for(my $i = 0; $i < $size; $i++)
	{
		$Result[$i] = 0;
	}

	_dec_2_bin($number, $size, \@BinValue, \@Result);

	if ($FLOATSTATUS == $NORMAL)
	{
		_convert_2_bin($number,$size, \@BinValue, \@Result);
	}

	if ($FLOATSTATUS == $OVERFLOW)
	{
		if ($Result[0] == 1)
		{
			#Negative infinity
			if ($size == 32)
			{
				return "11111111100000000000000000000000";
			}
			else
			{
				return "1111111111110000000000000000000000000000000000000000000000000000";
			}
		}
		else
		{
			#Positive Infinity
			if ($size == 32)
			{
				return "1111111100000000000000000000000";
			}
			else
			{
				return "111111111110000000000000000000000000000000000000000000000000000";
			}
		}
	}
	elsif ($FLOATSTATUS == $UNDERFLOW)
	{
		if ($size == 32)
		{
			return "00000000000000000000000000000000";
		}
		else
		{
			return "0000000000000000000000000000000000000000000000000000000000000000";
		}
	}
	else
	{
		return join ("", @Result);
	}
}

sub _dec_2_bin($$$$)
{
	my ($number, $size, $BinValue, $Result) = @_;
	my $value;
	my $intpart;
	my $decpart;
	my $binexpnt;
	my $index1;
	my $sign;
	my $exp;
	my $num;

	$number = _canonical($number);

	#Sign bit
	if($number < 0)
	{
		$Result->[0] = 1;
	}
	else
	{
		$Result->[0] = 0;
	}

	#Checking for overflow
	$exp = $number;
	$num = $number;
	$exp =~ s/^.*E//;
	$exp =~ s/^\+//;
	$num =~ s/E.*$//;
	if ($size == 32)
	{
		if (($exp > $FLOAT_MAX_EXP) || (($exp == $FLOAT_MAX_EXP) && ($num >= $FLOAT_MAX_NUM)))
		{
			$FLOATSTATUS = $OVERFLOW;
			return;
		}
	}
	else
	{
		if (($exp > $DOUBLE_MAX_EXP) || (($exp == $DOUBLE_MAX_EXP) && ($num >= $DOUBLE_MAX_NUM)))
		{
			$FLOATSTATUS = $OVERFLOW;
			return;
		}
	}

	$value = abs($number);
	($decpart, $intpart) = modf($value);

	#converting integer part
	for($index1 = $BIAS; ((($intpart / 2) != 0) && ($index1 >= 0)); $index1--)
	{
		$BinValue->[$index1] = $intpart % 2;
		if (($intpart % 2) == 0)
		{
			$intpart = $intpart / 2;
		}
		else
		{
			$intpart = ($intpart - 1) / 2;
		}
	}

	#converting decimal part
	for($index1 = $BIAS + 1; (($decpart > 0) && ($index1 < $CONST)); $index1++)
	{
		$decpart *= 2;
		if ($decpart >= 1)
		{
			$BinValue->[$index1] = 1;
			$decpart--;
		}
		else
		{
			$BinValue->[$index1] = 0;
		}
	}

	return;
}


sub _convert_2_bin($$)
{
	my ($number, $size, $BinValue, $Result) = @_;

	my $binexp;
	my $i1;
	my $i2;

	#Find most significant bit of the the mantissa
	for($i1 = 0; (($i1 < $CONST) && ($BinValue->[$i1] != 1)); $i1++) {};
	$binexp = $BIAS - $i1;

	if ($FLOATSTATUS == $NORMAL)
	{
		#regular normalized numbers
		if ($binexp >= $MINEXP && $binexp <= $MAXEXP)
		{
			$i1++;
		}
		#Support for 0 and de-normalized numbers
		#exponent underflow at this precision
		elsif($binexp < $MINEXP)
		{
			if   ($binexp == $BIAS - $CONST)
			{
				#Value is trully 0
				$FLOATSTATUS = $NORMAL;
				return;
			}
			elsif($binexp < $MINUNNORMEXP)
			{
				$FLOATSTATUS = $UNDERFLOW;
				return;
			}
			else
			{
				$FLOATSTATUS = $DENORMALIZED;
			}

			$binexp = $MINEXP - 1;
			$i1 = $BIAS - $binexp;
		}
		else #$binexp > $MAXEXP
		{
			$FLOATSTATUS = $OVERFLOW;
			return;
		}

	}

	if ($size == 32)
	{
		$i2 = 9;
	}
	else
	{
		$i2 = 12;
	}

	#copy the Result mantissa
	for(; (($i2 < $size) && ($i1 < $CONST)); $i2++, $i1++)
	{
		$Result->[$i2] = $BinValue->[$i1];
	}

	#Convert result exponent
	if ($size == 32)
	{
		$i1 = 8;
	}
	else
	{
		$i1 = 11;
	}
	$binexp += $EXPBIAS;
	for(; ($binexp / 2) != 0; $i1--)
	{
		my $r = $binexp % 2;
		$Result->[$i1] = $r;
		if ($r == 0)
		{
			$binexp = $binexp / 2;
		}
		else
		{
			$binexp = ($binexp - 1) / 2;
		}
	}
}

###############################################################################
# This function canonizes float of arbitrary length into scientific notation
# of form [+,-][0-9].[0-9]*E[+,-][0-9][0-9][0-9][0-9]+
###############################################################################
sub _canonical($)
{
	my $number = shift();
	my $sign;
	my $exp;
	my $mantissa;
	my $index;

	$number = uc($number);	 #In case we have exponential notation

	if ($number >= 0)
	{
		$sign = "+";
	}
	else
	{
		#if sign is negative sprintf will produce it
		$sign = "-"
	}

	$number =~ s/^\+//;
	$number =~ s/^-//;

	if ($number =~ /E/)
	{
		$exp = $number;
		$exp =~ s/[+,-]*[0-9,.]+E//;
		$exp =~ s/^\+0*//;
		$exp =~ s/^-0*/-/;
		$mantissa = $number;
		$mantissa =~ s/E.*$//;
	}
	else
	{
		$exp = 0;
		$mantissa = $number;
	}

	$mantissa .= "." if (!($mantissa =~ /\./));
	$mantissa = "0" . $mantissa if ($mantissa =~ /^\./);

	$index = index($mantissa, '.');
	if ($index != 1)
	{
		$exp += $index - 1;
	}
	$mantissa =~ s/\.//;

	if ($mantissa =~ /^0+$/)
	{
		$mantissa = 0;
	}
	elsif ($mantissa =~ /^0/)
	{
		while($mantissa =~ /^0/)
		{
			$exp -= 1;
			$mantissa =~ s/^0//;
		}
	}

	$mantissa = substr($mantissa, 0, 1) . "." . substr($mantissa, 1);
	$mantissa =~ s/0*$//;

	$number = $sign . $mantissa . "E" . sprintf("%05d", $exp);

	return $number;
}

###############################################################################
# This method converts Java UTF-8 string into current encoding
###############################################################################
sub _readUTF($)
{
	my $unicode_string = utf8(shift());
	while ((my $pos = index($unicode_string, chr(192) . chr(128))) > -1)
	{
		$unicode_string = substr($unicode_string, 0, $pos) . chr(0) . substr($unicode_string, $pos + 2);
	}
	return $unicode_string->latin1();
}

###############################################################################
# This method reads binary char compatible with Java
###############################################################################
sub _readChar($)
{
	return chr(_readShort(shift) & 0x00ff);
}

###############################################################################
# This method reads binary boolean compatible with Java
###############################################################################
sub _readBoolean($)
{
	return unpack("C", shift());
}

###############################################################################
# This method reads binary byte compatible with Java
###############################################################################
sub _readByte($)
{
	return unpack("c", shift());
}

###############################################################################
# This method reads binary unsigned byte compatible with Java
###############################################################################
sub _readUnsignedByte($)
{
	return unpack("C", shift());
}

###############################################################################
# This method reads binary short compatible with Java
###############################################################################
sub _readShort($)
{
	my $i = shift;
	my $a = unpack("C", substr($i,0,1));
	my $b = unpack("C", substr($i,1,1));
	
	#Trick to make perl treat this as signed
	return unpack("s", pack("s", (($a << 8) | ($b & 0xff)))); 
}

###############################################################################
# This method reads binary unsigned short compatible with Java
###############################################################################
sub _readUnsignedShort($)
{
	my $i = shift;
	return (
		((unpack("C", substr($i,0,1)) & 0xff) << 8) |
		 (unpack("C", substr($i,1,1)) & 0xff))
}

###############################################################################
# This method reads binary int compatible with Java
###############################################################################
sub _readInt($)
{
	my $i = shift;
	
	#Trick to make perl treat this as signed
	return unpack("i", pack("i", (
		((unpack("C", substr($i,1,1)) & 0xff) << 24) |
		((unpack("C", substr($i,1,1)) & 0xff) << 16) |
		((unpack("C", substr($i,2,1)) & 0xff) << 8) |
		 (unpack("C", substr($i,3,1)) & 0xff))))
}

###############################################################################
# This method reads binary long compatible with Java
###############################################################################
sub _readLong($)
{
	my $input = shift;
	my $bvector;
	my $bstring;

	$bvector = Bit::Vector->new_Bin(64, unpack("B64", $input));
	return $bvector->to_Dec();
}

###############################################################################
# This method reads Java's BigDecimal
###############################################################################
sub _readDecimal($$)
{
	my $bytes = shift;
	my $scale = shift;
	my $bin_string;
	my $bvector;
	my $bvector_scale;
	my $decstring;
	my $negative = 0;

	$bin_string = unpack("B*", $bytes);
	$bvector = Bit::Vector->new_Bin(length($bin_string), $bin_string);
	$decstring = $bvector->to_Dec();

	$decstring =~ s/^\+//;
	if ($decstring =~ /^-/)
	{
		$negative = 1;
		$decstring =~ s/^-//;
	}

	if (length($decstring) < $scale)
	{
		$decstring = ('0' x ($scale - length($decstring))) . $decstring;
	}

	$decstring = substr($decstring, 0, length($decstring) - $scale) . "." . substr($decstring, length($decstring) - $scale);
	$decstring = "-" . $decstring if ($negative);

	return $decstring;
}

###############################################################################
# This method reads binary float compatible with Java
###############################################################################
#XXX need to check for positive and negative infinity
sub _readFloat($)
{
	my $bitvec = Bit::Vector->new_Bin(32, unpack("B32", shift()));
	my $evec = new Bit::Vector(8);
	my $mvec = new Bit::Vector(24);
	my $s;
	my $m;
	my $e;

	if ($bitvec->bit_test(31))
	{
		$s = -1;
	}
	else
	{
		$s = 1;
	}

	$evec->Interval_Copy($bitvec, 0, 23, 8);
	$e = oct("0x" . $evec->to_Hex());

	$mvec->Interval_Copy($bitvec, 0, 0, 23);
	if ($e == 0)
	{
		$mvec <<= 1;
	}
	else
	{
		$mvec->Bit_On(23);
	}
	$m = oct("0x". $mvec->to_Hex());

	return $s * $m * pow(2, ($e - 150));
}

###############################################################################
# This method reads binary double compatible with Java
###############################################################################
#XXX need to check for positive and negative infinity
sub _readDouble($)
{
	my $bitvec = Bit::Vector->new_Bin(64, unpack("B64", shift()));
	my $evec = new Bit::Vector(11);
	my $mvec = new Bit::Vector(54);
	my $s;
	my $m;
	my $e;
	my $result;

	if ($bitvec->bit_test(63))
	{
		$s = -1;
	}
	else
	{
		$s = 1;
	}

	$evec->Interval_Copy($bitvec, 0, 52, 11);
	$e = oct("0x" . $evec->to_Hex());

	$mvec->Interval_Copy($bitvec, 0, 0, 52);
	if ($e == 0)
	{
		$mvec <<= 1;
	}
	else
	{
		$mvec->Bit_On(52);
	}
	$m = new Math::BigFloat($mvec->to_Dec());

	return $s * $m * big_pow2($e - 1075);
}

sub big_pow2($)
{
	my $pow = shift;
	my $base = Bit::Vector->new_Dec(2048, 2);


	Bit::Vector->Configuration("in=dec,ops=arithmetic,out=dec");
	$base **= abs($pow);

	$base = new Math::BigFloat($base->to_Dec());
	if ($pow < 0)
	{
		$base = 1 / $base;
	}

	return $base;
}

1;
