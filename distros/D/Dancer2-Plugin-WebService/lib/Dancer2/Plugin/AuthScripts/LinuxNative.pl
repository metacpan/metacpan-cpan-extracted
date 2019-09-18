#!/usr/bin/perl
# Authenticate using the Linux native api
# George Bouras

my  $USER=pack 'H*',$ARGV[0];
my  $PASS=pack 'H*',$ARGV[1];
our @MEMBER;
my  @inf;
sub	Exit {print STDOUT "$_[0]\n". join(',',@MEMBER)."\n"; exit $_[0]?1:0}

if    (not @inf = getpwnam $USER)		{Exit('User does not exist')}	# Get user properties. This also a test if the user exists
elsif ($inf[1] eq 'x')					{Exit('Effective user '.getpwuid($<).' can not check authorization')}
elsif ($inf[1] =~/^!+$/)				{Exit('User password is not defined')}
elsif ($inf[1] eq '')					{Exit('User have a null password')}
elsif ($inf[1] ne crypt $PASS, $inf[1])	{Exit('Wrong password')}

endgrent; # reread from the start

while (@inf = getgrent) {
# $inf[0] is the group name
# $inf[3] are members of this group

	if (($inf[0] eq $USER) && ($inf[3] eq '')) {
	push @MEMBER,$inf[0]
	}
	else {

		foreach (split /\s+/, $inf[3]) {

			if ($_ eq $USER) {
			push @MEMBER,$inf[0];
			last
			}
		}
	}
}

Exit(0)