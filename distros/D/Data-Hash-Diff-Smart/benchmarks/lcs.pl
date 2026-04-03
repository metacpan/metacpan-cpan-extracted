# lcs.pl
{
	my @old = map { int(rand(50)) } 1..2000;
	my @new = @old;

	# introduce random changes
	$new[rand @new] = int(rand(50)) for 1..200;

	(\@old, \@new, array_mode => 'lcs');
}
