package Carrot::Modularity::Package::Event::Generic
# /type class
# /instances singular
# /capability "Subscription to package loading (before and after)."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Event/Generic./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
#	class
# //returns
{
	my $this = [];

	$this->[ATR_BEFORE] = [];
	$this->[ATR_AFTER] = [];
	bless($this, $_[SPX_CLASS]);

	return($this);
}

sub evt_package_load_before
# /type method
# /effect ""
# //parameters
#	pkg_name
#	pkg_file
# //returns
{
	my ($this) = @ARGUMENTS;

	foreach my $subscriber (@{$this->[ATR_BEFORE]})
	{
		$subscriber->evt_package_load_before(
			$_[SPX_PKG_NAME],
			$_[SPX_PKG_FILE]); # eventually modified in Prepare.pm
	}
	return;
}

sub evt_package_load_after
# /type method
# /effect ""
# //parameters
#	pkg_name
# //returns
{
	my ($this, $pkg_name) = @ARGUMENTS;

	foreach my $subscriber (@{$this->[ATR_AFTER]})
	{
		$subscriber->evt_package_load_after($pkg_name);
	}
	return;
}

sub subscribe_before
# /type method
# /effect ""
# //parameters
#	subscriber
# //returns
{
	if (TRACE_FLAG)
	{
		print STDERR "PKG EVENT $_[THIS] subscribe_before $_[SPX_SUBSCRIBER]\n";
	}
	push(@{$_[THIS][ATR_BEFORE]}, $_[SPX_SUBSCRIBER]);

	return;
}

sub subscribe_after
# /type method
# /effect ""
# //parameters
#	subscriber
# //returns
{
	if (TRACE_FLAG)
	{
		print STDERR "PKG EVENT $_[THIS] subscribe_after $_[SPX_SUBSCRIBER]\n";
	}
	push(@{$_[THIS][ATR_AFTER]}, $_[SPX_SUBSCRIBER]);
	return;
}

sub unsubscribe
# /type method
# /effect ""
# //parameters
#	subscriber
# //returns
{
	my ($this, $subscriber) = @ARGUMENTS;

	if (TRACE_FLAG)
	{
		print STDERR "PKG EVENT unsubscribe $_[SPX_SUBSCRIBER]\n";
	}
	my $key = "$_[SPX_SUBSCRIBER]";
	@{$_[THIS][ATR_BEFORE]} = grep(($key eq $_), @{$_[THIS][ATR_BEFORE]});
	@{$_[THIS][ATR_AFTER]} = grep(($key eq $_), @{$_[THIS][ATR_AFTER]});

	return;
}

# =--------------------------------------------------------------------------= #

	return(1);
}
# //revision_control
#	version 1.1.364
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
