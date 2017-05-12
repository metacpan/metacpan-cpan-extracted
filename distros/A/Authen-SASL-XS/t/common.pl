
our $me;

1;

# Pluginpath
#$ENV{'SASL_PATH'} = "/opt/products/sasl/1.5.28/lib/sasl";
sub sendreply
{
	$SIG{PIPE} = 'IGNORE'; # Client is closing too fast
	my ($s,$so) = @_;
	$s = " " unless $s;
	print "$me Sendreply: ",substr($s,0,10),"\n";
	syswrite ($so,$s);
}

sub getreply
{
	my ($so) = @_;
	my $s;
	print "$me-Getreply is waiting.\n";
	sysread($so,$s,4096);
	print "$me Getreply: ",substr($s,0,10),"\n";
	return $s;
}

sub checkpass
{
	my ($user,$pass) = @_;
	print "$me CB Checkpass: $user: $pass\n";
	return ($pass eq "klaus");
}

sub getsecret
{
	my ($mech,$user,$realm) = @_;
	print "$me CB Checkpass: $mech, $user, $realm\n";
	return "klaus";
}

sub canonuser 
{
	my ($type,$realm,$maxlen,$user) = @_;
	print "$me CB Canonuser: $type, $realm, $maxlen, $user\n";
	
	return $user;
}

sub authorize
{
	my ($username,$req_user) = @_;

	print "$me CB Authorize: $username, $req_user\n";

#	return $username;
	return 1;
}

sub getusername
{
	print "$me CB username.\n";
	return $ENV{'USER'};
}

sub getauthname
{
	print "$me CB authname.\n";
	return $ENV{'USER'};
}

sub getpassword
{
	print "$me CB password.\n";
	return "klaus";
}


