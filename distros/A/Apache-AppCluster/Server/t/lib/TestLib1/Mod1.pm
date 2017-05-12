package TestLib1::Mod1;
use Digest::MD5 qw( md5_hex );
use strict;

sub send_digest
{
	my $input = shift @_;

	my $data = $input->{data};
	my $digest = $input->{digest};
	
	my $check = md5_hex($data);
	if($check ne $digest)
	{
		die "Digest check failed!\n";
	} else
	{
		return $check;
	}
}

1;
	
	
