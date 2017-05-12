package BreakMe;

while (1)
{
	$main::looping++;
}
$main::moving_on++;

sub breakit
{
	my $i;
	for (1 .. 10)
	{
		$i = $_;
	}
	$main::moving_on++ unless $i == 10;
}

1;
