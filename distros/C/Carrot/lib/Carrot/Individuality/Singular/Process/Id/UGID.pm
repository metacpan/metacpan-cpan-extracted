package Carrot::Individuality::Singular::Process::Id::UGID
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $unknown_user_name = 'unknown_user_name',
		my $unknown_group_name = 'unknown_group_name');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);
	@$this = @ARGUMENTS;
	return;
}

sub run_effectively
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	($#ARGUMENTS == ADX_FIRST_ELEMENT)
		? $_[THIS][ATR_SAVED]
		: ($_[THIS][ATR_SAVED] = $_[SPX_VALUE]);
}

sub defined_xid
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	(defined($_[THIS][ATR_UID]) or defined($_[THIS][ATR_GID]))
}

sub resolve_user_n_group
# /type method
# /effect ""
# //parameters
#	user_name
#	group_name
# //returns
{
	my ($this, $user_name, $group_name) = @ARGUMENTS;

	$this->resolve_user_name($user_name) if (defined($user_name));
	$this->resolve_group_name($group_name) if (defined($group_name));
	return;
}

sub resolve_user_name
# /type method
# /effect ""
# //parameters
#	user_name
# //returns
{
	my ($this, $user_name) = @ARGUMENTS;

	my ($user_id, $group_id) = (getpwnam($user_name))[2,3];
	unless (defined($user_id))
	{
		$unknown_user_name->raise_exception(
			{+HKY_DEX_BACKTRACK => $user_name,
			 'user_name' => $user_name},
			ERROR_CATEGORY_SETUP);
	}
	$this->[ATR_UID] = $user_id;
	$this->[ATR_GID] = $group_id;
	return;
}

sub resolve_group_name
# /type method
# /effect ""
# //parameters
#	group_name
# //returns
{
	my ($this, $group_name) = @ARGUMENTS;

	my $group_id = (getgrnam($group_name))[2];
	unless (defined($group_id))
	{
		$unknown_group_name->raise_exception(
			{+HKY_DEX_BACKTRACK => $group_name,
			 'group_name' => $group_name},
			ERROR_CATEGORY_SETUP);
	}
	$this->[ATR_GID] = $group_id;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.56
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"