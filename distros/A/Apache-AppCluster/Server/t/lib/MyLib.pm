package MyLib;
use strict;

sub testit
{
	my $input = shift @_;
	
	if($input->[0] eq 'val1' && $input->[1] eq 'val2' && 
		$input->[2] eq 'another_val' &&
		$input->[3] eq 'more_stuff')
	{
		return { key1 => 'val1' };
	
	} else
	{
		die "Server did not receive data correctly!\n";
	}
}
1;
