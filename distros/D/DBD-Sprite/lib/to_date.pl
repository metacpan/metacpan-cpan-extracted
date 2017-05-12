use Time::Local;

my ($s) = $_[0];
my ($f) = $_[1];

@fmts = split(/\b/, $f);
@fmts = split(/\b/, $f);
@inputs = split(/\b/, $s);
@today = localtime(time);
$err = '';
$rtnTime = '';
@tl = ();
$begofyear = timelocal(0,0,0,1,0,$today[5]);


for (my $i=0;$i<=$#fmts;$i++)
{
	foreach my $f (qw(month ddd dd yyyymmdd yyyy yy hh24 hh mi mm mon sssss ss a p rm rr))
	{
		if ($fmts[$i] =~ /^$f/i)
		{
			$err .= &$f($i);
			last;
		}
	}
}
$tl[3] = '1'  unless ($tl[3]);
$rtnTime = timelocal(@tl)  unless ($rtnTime);
$t = localtime($rtnTime);

sub month
{
	my %mthhash = (
		'january' => '0',
		'february' => 1,
		'march' => 2,
		'april' => 3,
		'may' => 4,
		'june' => 5,
		'july' => 6,
		'august' => 7,
		'september' => 8,
		'october' => 9,
		'november' => 10,
		'december' => 11
	);

	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$inputs[$indx]};
	return "Invalid Month ($inputs[$indx])! "  unless (length($tl[4]));
	return '';
}

sub mon
{
	my %mthhash = (
		'jan' => '0',
		'feb' => 1,
		'mar' => 2,
		'apr' => 3,
		'may' => 4,
		'jun' => 5,
		'jul' => 6,
		'aug' => 7,
		'sep' => 8,
		'oct' => 9,
		'nov' => 10,
		'dec' => 11
	);

	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$inputs[$indx]};
	return "Invalid Mth ($inputs[$indx])! "  unless (length($tl[4]));
	return '';
}

sub rm
{
	my %mthhash = (
		'i' => '0',
		'ii' => 1,
		'iii' => 2,
		'iv' => 3,
		'v' => 4,
		'vi' => 5,
		'vii' => 6,
		'viii' => 7,
		'ix' => 8,
		'x' => 9,
		'xi' => 10,
		'xii' => 11
	);

	my $indx = shift;
	$inputs[$indx] =~ tr/A-Z/a-z/;
	$tl[4] = $mthhash{$inputs[$indx]};
	return "Invalid Roman Mth. ($inputs[$indx])! "  unless (length($tl[4]));
	return '';
}

sub mm
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid month ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 && $inputs[$indx] <= 12);
	$tl[4] = $inputs[$indx] - 1;
	return '';
}

sub yyyymmdd
{
	$tl[5] = substr($inputs[$indx],0,4);
	$tl[4] = substr($inputs[$indx],4,2) - 1;
	$tl[3] = substr($inputs[$indx],6,2);
	return '';
}

sub yyyy
{
	my $indx = shift;
	return "Invalid year ($inputs[$indx])! "  
			unless ($inputs[$indx] =~ /^\d\d\d\d$/);
	$tl[5] = $inputs[$indx];
	return '';
}

sub yy
{
	return rr(shift);
}

sub rr
{
	my $indx = shift;
	return "Invalid year ($inputs[$indx])! "  
			unless ($inputs[$indx] =~ /^\d\d$/);
	if (($today[5] % 100) > 50)
	{
		$inputs[$indx] += 100  if ($inputs[$indx] < 50);
	}
	else
	{
		#$inputs[$indx] -= 100  if ($inputs[$indx] > 50);
		$inputs[$indx] += 100  if ($inputs[$indx] < 50);
	}
	$tl[5] = $inputs[$indx] + 1900;
	return '';
}

sub rrrr
{
	my $indx = shift;
	return &rr($indx)  if ($inputs[$indx] =~ /^\d\d?$/);
	return "Invalid year ($inputs[$indx])! "  
			unless ($inputs[$indx] =~ /^\d\d\d\d?$/);
	if (($today[5] % 100) > 50)
	{
		$inputs[$indx] += 100  if (($inputs[$indx] % 100) < 50);
	}
	else
	{
		#$inputs[$indx] -= 100  if (($inputs[$indx] % 100) > 50);
		$inputs[$indx] += 100  if ($inputs[$indx] < 50);
	}
	$tl[5] = $inputs[$indx];
	return '';
}

sub ddd
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0+//;
	return "Invalid year-day ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 and $inputs[$indx] <= 366);
	$rtnTime = $begofyear + (($inputs[$indx]*86400) - 86400);
	return '';
}

sub dd
{
	my $indx = shift;
	return "Invalid day ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 and $inputs[$indx] <= 31);
	$inputs[$indx] =~ s/^0//;
	$tl[3] = $inputs[$indx];
	return '';
}

sub hh24
{
	my $indx = shift;
	return "Invalid 24-hr time ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 2400 
			and ($inputs[$indx] % 100) < 60);
	$tl[1] = ($inputs[$indx] % 100);
	$inputs[$indx] = int($inputs[$indx] / 100);
	$tl[2] = $inputs[$indx];
	return '';
}

sub hh
{
	my $indx = shift;
	return "Invalid hour ($inputs[$indx])! "  
			unless ($inputs[$indx] > 0 and $inputs[$indx] <= 12);
	$tl[2] = $inputs[$indx];
	$rtnTime += ($inputs[$indx] * 3600)  if ($rtnTime);
	return '';
}

sub a
{
	my $indx = shift;
	if ($tl[2] < 12)
	{
		$tl[2] += 12  if ($inputs[$indx] =~ /p/);
	}
	else
	{
		$tl[2] -= 12  if ($inputs[$indx] =~ /a/);
	}
	return '';
}

sub p
{
	return &a;
}

sub mi
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid minutes ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 59);
	$tl[1] = $inputs[$indx];
	$rtnTime += ($inputs[$indx] * 60)  if ($rtnTime);
	return '';
}

sub sssss
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid seconds ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 86400);
	$tl[0] = $inputs[$indx] % 60;
	$tl[1] = int($inputs[$indx]/60) % 60;
	$tl[2] = $inputs[$indx] % 3600;
	$rtnTime += $inputs[$indx]  if ($rtnTime);
	return '';
}

sub ss
{
	my $indx = shift;
	$inputs[$indx] =~ s/^0//;
	return "Invalid seconds ($inputs[$indx])! "  
			unless ($inputs[$indx] >= 0 and $inputs[$indx] <= 59);
	$tl[0] = $inputs[$indx];
	$rtnTime += $inputs[$indx]  if ($rtnTime);
	return '';
}

1
