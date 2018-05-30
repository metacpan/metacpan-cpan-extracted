#!/usr/bin/perl
# Authenticate a user using the native linux
# So the username/password should exist at local linux 
#
# George Mpouras, 7 June 2016

my  $USER    = pack 'H*', $ARGV[0];
my  $PASS    = pack 'H*', $ARGV[1];
my  %GROUP   = map {$_,1} split /,/, $ARGV[2];
my  $RESULT  = 0;
my  $MESSAGE = 'An authentication error have occured';
my  @MEMBER  = ();
sub Exit       { print STDOUT "$RESULT\n$MESSAGE\n". join ',', @MEMBER; exit ($RESULT==1?0:1) }


my @inf;
if    ( not @inf = getpwnam $USER )		{ $MESSAGE = "User $USER does not exist"; Exit}				# Get user properties. This also a test if the user exists
elsif ( $inf[1] eq 'x' )			{ $MESSAGE = 'Effective user can not check the authorization';&Exit}	# Run as root, use sudo or  chmod a+r /etc/shadow
elsif ( $inf[1] =~/^!+$/ )			{ $MESSAGE = "User $USER have not a defined password"; Exit}	# passwd Joe
elsif ( $inf[1] eq '' )				{ $MESSAGE = 'User $USER have a null password'; Exit}
elsif ( $inf[1] ne crypt $PASS, $inf[1] )	{ $MESSAGE = 'Wrong password'; Exit}

endgrent;

while (@inf = getgrent)
{
next unless exists $GROUP{$inf[0]}; # skip if the group is not one of the defined at applications file
# $inf[0] is the group name
# $inf[3] are members of this group

	if (( $inf[0] eq $USER ) && ( $inf[3] eq '' ))
	{
	push @MEMBER, $inf[0]
	}
	else
	{
		foreach (split /\s+/, $inf[3])
		{
			if ($_ eq $USER)
			{
			push @MEMBER, $inf[0];
			last
			}
		}
	}
}

endgrent;

if (@MEMBER)
{
$RESULT  = 1;
$MESSAGE = 'Authorized'
}
else
{
$MESSAGE = "user $USER do not belong to any group: ". join ',',sort keys %GROUP
}

Exit