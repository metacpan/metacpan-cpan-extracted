package Carrot::Modularity::Package::Event::Specific
# /type class
# /attribute_type ::Diversity::Attribute_Type::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Event/Specific./manual_modularity.pl');
	} #BEGIN

	require Carrot::Modularity::Package::Patterns;
	my $pkg_patterns =
		Carrot::Modularity::Package::Patterns->constructor;

# =--------------------------------------------------------------------------= #

sub constructor
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
# //returns
{
	my $this = [];
	$this->[ATR_IDS] = {};
	$this->[ATR_COUNTER] = 0;
	$this->[ATR_CALLBACKS] = {};
	$this->[ATR_UPGRADES] = {};

	foreach my $key (keys(%INC))
	{
		$this->[ATR_COUNTER] += 1;
		$key = $pkg_patterns->file_as_package_name($key);
		$this->[ATR_IDS]{$key} = $this->[ATR_COUNTER];
	}
	bless($this, $_[SPX_CLASS]);

	return($this);
}

sub lookup_id
# /type class_method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	if (exists($this->[ATR_IDS]{$_[SPX_PKG_NAME]}))
	{
		return($this->[ATR_IDS]{$_[SPX_PKG_NAME]});
	} else {
		return(IS_UNDEFINED);
	}

}

sub evt_package_load_after
# /type method
# /effect ""
# //parameters
#	pkg_name
# //returns
{
	my ($this, $pkg_name) = @ARGUMENTS;

	my $package_ids = $this->[ATR_IDS];
	unless (exists($package_ids->{$pkg_name}))
	{
		$this->[ATR_COUNTER] += 1;
		$package_ids->{$pkg_name} = $this->[ATR_COUNTER];
	}
	if (exists($this->[ATR_CALLBACKS]{$pkg_name}))
	{
		if (TRACE_FLAG)
		{
			print STDERR "Executing callbacks for package '$pkg_name'.\n";
		}
		my $callbacks = delete($this->[ATR_CALLBACKS]{$pkg_name});
		foreach my $callback (@$callbacks)
		{
			$callback->($pkg_name);
		}
	}
	if (exists($this->[ATR_UPGRADES]{$pkg_name}))
	{
		if (TRACE_FLAG)
		{
			print STDERR "Executing upgrades for package '$pkg_name'.\n";
		}
		my $instances = delete($this->[ATR_UPGRADES]{$pkg_name});
		if ($pkg_name->can('re_constructor'))
		{
			$_->re_constructor($pkg_name) foreach (@$instances);
		} else {
			bless($_, $pkg_name) foreach (@$instances);
		}
	}

	return;
}

sub subscribe_upgrade
# /type method
# /effect ""
# //parameters
#	pkg_name
#	instance
# //returns
{
	my ($this, $pkg_name, $instance) = @ARGUMENTS;

	my $upgrades = $this->[ATR_UPGRADES];
	unless (exists($upgrades->{$pkg_name}))
	{
		$upgrades->{$pkg_name} = [];
	}
	push($upgrades->{$pkg_name}, $instance);
	return;
}

sub subscribe_callback
# /type class_method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	callback
# //returns
{
	my ($this, $pkg_name, $callback) = @ARGUMENTS;

	if (TRACE_FLAG)
	{
		print STDERR "Request to callback for package '$pkg_name'.\n";
	}
	if (exists($this->[ATR_IDS]{$pkg_name}))
	{
		$callback->($pkg_name);
		return;
	}
	my $callbacks = $this->[ATR_CALLBACKS];
	unless (exists($callbacks->{$pkg_name}))
	{
		$callbacks->{$pkg_name} = [];
	}
	push($callbacks->{$pkg_name}, $callback);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.331
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
