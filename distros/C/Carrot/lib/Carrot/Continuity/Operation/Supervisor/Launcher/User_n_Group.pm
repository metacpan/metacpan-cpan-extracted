package Carrot::Continuity::Operation::Supervisor::Launcher::User_n_Group
# /type class
# /implements [=component_pkg=]::_Plugin_Prototype
# /attribute_type ::Many_Declared::Ordered
# /capability "Change to effective user and group."
{
	use strict;
	use warnings 'FATAL' => 'all';


# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	user_dot_group
# //returns
{
	my ($this, $user_dot_group) = @ARGUMENTS;

	unless ($setting =~ m{^(\w*)\.(\w*)$})
	{
			die("Unknown format of setting '$setting'.");
	}
	my ($user, $group) = ($1, $2);

	if (length($user))
	{
		my $getgr = [getpwent($user)];
		unless (@$getgrnam)
		{
			die("Could not find a user named '$user'.");
		}
		$this->[ATR_USER] = $getgr->[RDX_GETGR_GID];

	} else {
		$this->[ATR_USER] = IS_UNDEFINED;
	}

	if (length($group))
	{
		my $getgr = [getgrent($group)];
		unless (@$getgrnam)
		{
			die("Could not find a group named '$group'.");
		}
		$this->[ATR_GROUP] = $getgr->[RDX_GETGR_GID];

	} else {
		$this->[ATR_GROUP] = IS_UNDEFINED;
	}

	return;
}

sub effect
# /type implementation
{
	my ($this) = @ARGUMENTS;

	if (defined($this->[ATR_USER]))
	{
		$EFFECTIVE_USER_ID = $this->[ATR_USER];
	}

	if (defined($this->[ATR_GROUP]))
	{
		$EFFECTIVE_GROUP_ID = $this->[ATR_GROUP];
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.110
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"