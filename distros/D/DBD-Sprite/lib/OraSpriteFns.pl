use Time::Local;

sub ABS
{
	return abs(shift);
}

sub ADD_MONTHS
{
	my ($d, $n) = @_;
	my @timestuff = localtime($d);
	my ($mday) = $timestuff[3];
	$d += (30*86400)*$n;
	@timestuff = localtime($d);
	my $thisdate = $timestuff[5] + 1900;
	$thisdate .= '0'  if ($timestuff[4] < 9);
	$thisdate .= $timestuff[4] + 1;
	$thisdate .= '0'  if ($mday < 10);
	$thisdate .= $mday;
    my $xx = timelocal(0,0,0,substr($thisdate,6,2),
                        (substr($thisdate,4,2)-1),substr($thisdate,0,4),0,0,0);
	return $xx;

}

sub ASCII
{
	return ord(shift);
}

sub CEIL
{
	my $n = shift;
	return int($n) + 1  if ($n > int($n));
	return int($n);
}

sub CHR
{
	return chr(shift);
}

sub CONCAT
{

	#@_ = &chkcolumnparms(@_);
	#return $_[0].$_[1];
	return join('',@_);
}

sub COS
{
	return cos(shift);
}

sub CURDATE
{
	my $fmt = shift || 'yyyy-mm-dd';
	return TO_CHAR(SYSTIME, $fmt)
}

sub DAYS_BETWEEN   #SPRITE-ONLY FUNCTION.
{
	my ($d1, $d2) = @_;
	my ($secbtn) = abs($d2 - $d1);
	return $secbtn / 86400;
}

sub EXP
{
	return 2.71828183 ** shift;
}

sub FLOOR
{
	my $n = shift;
	return int($n) - 1  if ($n < 0 && $n < int($n));
	return int($n);
}

sub INITCAP
{
	my ($s) = shift;
	$s =~ s/\b(\w)(\w*)/\U$1\L$2\E/g;
	return $s;
}

sub INSTR
{
	my ($s, $srch, $n, $m) = @_;
	my $t = $n;
	if ($n < 0)
	{
		$s = reverse($s);
		$srch = reverse($srch);
		$t = abs($n);
	}
	for (my $i=1;$i<=$m;$i++)
	{
		$t = index($s, $srch, $t) + 1;
		return 0  if ($t < 0);
	}
	return length($s) - $t  if ($n < 0);
	return $t;	
}

sub INSTRB
{
	return INSTR(@_);
}

sub LAST_DAY
{
	my ($t) = shift;

	my @timestuff = localtime($t);
	my @lastdate = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	my $thisdate = $timestuff[5] + 1900;
	$thisdate .= '0'  if ($timestuff[4] < 9);
	$thisdate .= $timestuff[4] + 1;
	#$thisdate .= '0'  if ($timestuff[3] < 10);
	#$thisdate .= $timestuff[3];
	if ($timestuff[4] == 1)
	{
		if (!(($timestuff[5]+300) % 400))
		{
			$thisdate .= '29';
		}
		elsif (!($timestuff[5] % 100))
		{
			$thisdate .= '28';
		}
		elsif (!($timestuff[5] % 4))
		{
			$thisdate .= '29';
		}
		else
		{
			$thisdate .= '28';
		}
	}
	else
	{
		$thisdate .= $lastdate[$timestuff[4]];
	}
    my $xx = timelocal(0,0,0,substr($thisdate,6,2),
                        (substr($thisdate,4,2)-1),substr($thisdate,0,4),0,0,0);
	return $xx;
}

sub LENGTH
{
	return length(shift);
}

sub LENGTHB
{
	return length(shift);
}

sub LPAD
{
	my ($s, $l, $p) = @_;
	my $t = $p x $l;
	return substr($t,0,($l-length($s))) . $s;
}

sub LTRIM
{
	my ($x, $y) = @_;
	$x =~ s/^[$y]+//;
	return $x;
}

sub LOWER
{
	#@_ = &chkcolumnparms(@_);
	my ($s) = shift;
	$s =~ tr/A-Z/a-z/;
	return $s;
}

sub MOD
{
	my ($m, $n) = @_;
	return $m  unless ($n);
	return $m % $n;
}

sub MONTHS_BETWEEN   #ASSUMES 30-DAY MONTHS - APPROXIMATES THE ORACLE FUNCTION!
{
	my ($d1, $d2) = @_;
	my ($secbtn) = abs($d2 - $d1);
	return $secbtn / (30*86400);
}

sub NOW
{
	my $fmt = shift || 'yyyy-mm-dd hh:mi:ss';
	return TO_CHAR(SYSTIME, $fmt)
}

sub now
{
	my $fmt = shift || 'yyyy-mm-dd hh:mi:ss';
	return TO_CHAR(SYSTIME, $fmt)
}

sub NVL    #CHGD. TO LAST LINE 20040325 TO MAKE WORK LIKE ORACLE!?
{
#	my (@parms) = @_;
#	my ($t);
#	while ($#parms >= 0)
#	{
#		$t = shift(@parms);
#		return $t  if (defined($t) && $t ne '');
#	}
#	return defined($t) ? $t : '';
	return (length($_[0]) ? $_[0] : $_[1]);
}

sub POWER
{
	return $_[0] ** $_[1];
}

sub REPLACE
{
	my ($s, $x, $y) = (@_[0..2]);
	if ($_[3] eq 'i')
	{
		$s =~ s/\Q$x\E/\Q$y\E/ig;   #SPRITE EXTENSION, NOT SUPPORTED IN ORACLE!
	}
	else
	{
		$s =~ s/\Q$x\E/\Q$y\E/g;
	}
	return $s;
}

sub ROUND
{
	my ($m, $n) = @_;
	return sprintf("%.${n}f", $m)  if ($n >= 0);
	$m *= 10 ** $n;
	return (1 * sprintf('%.0f', $m)) / (10 ** $n);
}

sub RPAD
{
	my ($s, $l, $p) = @_;
	while (length($s) < $l)
	{
		$s .= $p;
	}
	return substr($s, 0, $l);
}

sub RTRIM
{
	my ($x, $y) = @_;
	$x =~ s/[$y]+$//;
	return $x;
}

sub SIGN
{
	return -1  if ($_[0] < 0);
	return 0   unless ($_[0]);
	return 1;
}

sub SIN
{
	return sin(shift);
}

sub SQRT
{
	return sqrt(shift);
}

sub SUBSTR
{
	#@_ = &chkcolumnparms(@_);
	my ($s) = shift;
	my ($p) = shift;
	#($s, $p) = &chkcolumnparms(@_);

	return ''  unless ($p);

	--$p  if ($p > 0);

	my ($l) = shift;
	return (substr($s, $p))  unless ($l);
	return substr($s, $p, $l);
}

sub SUBSTRB
{
	return SUBSTR(@_);
}

sub TO_CHAR
{
	do 'to_char.pl';
	if ($err =~ /^Invalid/)
	{
		$errdetails = $err;
		$rtnTime = '';
		$self->display_error(-503);
	}
	return $rtnTime;
}

sub TO_DATE
{
	do 'to_date.pl';
	if ($err =~ /^Invalid/)
	{
		$errdetails = $err;
		$rtnTime = '';
		$self->display_error(-503);
	}
	return $rtnTime;
}

sub TO_NUMBER
{
	$rtnTime = shift;
	my $fmt = shift;

	my $fmtstr = 'f';
	$fmtstr = $1  if ($rtnTime =~ s/(e)eee//i);
	$rtnTime =~ s/[^\d\.\+\-Vv]//g;
	my $dec = 0;
	$dec = length($2)  if ($fmt =~ /([\d\+\-]*)V(\d*)/);
	#my ($dec) = length($2);
	$rtnTime *= (10 ** $dec);
	return sprintf('%.0f',$rtnTime);   #ROUND IT.
	return $rtnTime;
}

sub TRANSLATE
{
	my ($s, $a, $b) = @_;
	eval "\$s =~ tr/$a/$b/d";
	return $s;
}

sub TRUNC
{
	my ($m, $n) = @_;
	if ($n =~ /D/i)
	{
		my @timestuff = localtime($m);
		my $thisdate = $timestuff[5] + 1900;
		$thisdate .= '0'  if ($timestuff[4] < 9);
		$thisdate .= $timestuff[4] + 1;
		$thisdate .= '0'  if ($timestuff[3] < 10);
		$thisdate .= $timestuff[3];
	    my $xx = timelocal(0,0,0,substr($thisdate,6,2),
                        (substr($thisdate,4,2)-1),substr($thisdate,0,4),0,0,0);
		return $xx;
	}
	elsif ($n =~ /Y/i)
	{
		my @timestuff = localtime($m);
		my $thisdate = $timestuff[5] + 1900;
	    my $xx = timelocal(0,0,0,1,0,$thisdate,0,0,0);
		return $xx;
	}
	elsif ($n =~ /MI/i)
	{
		my @timestuff = localtime($m);
		my $thisdate = $timestuff[5] + 1900;
		$thisdate .= '0'  if ($timestuff[4] < 9);
		$thisdate .= $timestuff[4] + 1;
		$thisdate .= '0'  if ($timestuff[3] < 10);
		$thisdate .= $timestuff[3];
		$thisdate .= '0'  if ($timestuff[2] < 10);
		$thisdate .= $timestuff[2];
		$thisdate .= '0'  if ($timestuff[1] < 10);
		$thisdate .= $timestuff[1];
	    my $xx = timelocal(0,substr($thisdate,10,2),substr($thisdate,8,2),substr($thisdate,6,2),
                        (substr($thisdate,4,2)-1),substr($thisdate,0,4),0,0,0);
		return $xx;
	}
	elsif ($n =~ /M/i)
	{
		my @timestuff = localtime($m);
		my $thisdate = $timestuff[5] + 1900;
		$thisdate .= '0'  if ($timestuff[4] < 9);
		$thisdate .= $timestuff[4] + 1;
	    my $xx = timelocal(0,0,0,1,(substr($thisdate,4,2)-1),substr($thisdate,0,4),0,0,0);
		return $xx;
	}
	elsif ($n =~ /H/i)
	{
		my @timestuff = localtime($m);
		my $thisdate = $timestuff[5] + 1900;
		$thisdate .= '0'  if ($timestuff[4] < 9);
		$thisdate .= $timestuff[4] + 1;
		$thisdate .= '0'  if ($timestuff[3] < 10);
		$thisdate .= $timestuff[3];
		$thisdate .= '0'  if ($timestuff[2] < 10);
		$thisdate .= $timestuff[2];
	    my $xx = timelocal(0,0,substr($thisdate,8,2),substr($thisdate,6,2),
                        (substr($thisdate,4,2)-1),substr($thisdate,0,4),0,0,0);
		return $xx;
	}
	else
	{
		return int($m * (10 ** $n)) / (10 ** $n);
	}
}

sub UPPER
{
	my ($s) = shift;
	$s =~ tr/a-z/A-Z/;
	return $s;
}

sub WEEKS_BETWEEN   #SPRITE-ONLY FUNCTION.
{
	my ($d1, $d2) = @_;
	my ($secbtn) = abs($d2 - $d1);
	return $secbtn / (7*86400);
}

sub YEARS_BETWEEN   #SPRITE-ONLY FUNCTION.
{
	my ($d1, $d2) = @_;
	my ($secbtn) = abs($d2 - $d1);
	return $secbtn / (365.25*86400);
}

1
