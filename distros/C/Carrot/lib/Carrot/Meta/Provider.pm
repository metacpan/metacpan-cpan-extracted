package Carrot::Meta::Provider
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Provide the meta monad of expressiveness"
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Provider./manual_modularity.pl');
	} #BEGIN


	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $shadow_class = '::Modularity::Package::Shadow',
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini',
		my $hash_class = '::Diversity::Attribute_Type::One_Anonymous::Hash',
		my $package_name_class = '::Modularity::Package::Name');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $loader = '::Modularity::Package::Loader',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $package_events = '::Modularity::Package::Event::Generic');

	my $monad_class = 'Carrot::Meta::Monad';
	my $prepare_class = 'Carrot::Meta::Monad::Phase::Prepare';
	my $begin_class = 'Carrot::Meta::Monad::Phase::Begin';
	my $run_class = 'Carrot::Meta::Monad::Phase::Run';
	my $universal_class = 'Carrot::Meta::Universal';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_MANAGED_DIVERSITY] = [];
	$this->[ATR_MANAGED_MODULARITY] = [];
	$this->[ATR_META_MONADS] = $hash_class->constructor;
	$this->[ATR_MONAD_PROVIDERS] = {};

	$loader->load($monad_class, $this);
	$loader->load($prepare_class, $this->[ATR_MANAGED_DIVERSITY]);
	$loader->load($begin_class, $this->[ATR_MANAGED_MODULARITY]);
	$loader->load($run_class, $this);

	return;
}

sub final_setup
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$package_events->subscribe_before($this);
	$package_events->subscribe_after($this);

	my $dot_ini = $dot_ini_class->constructor($this);
	$dot_ini->find_configuration;

	$loader->load($universal_class, $this, $translated_errors);

	foreach my $monad_provider (@{$this->[ATR_MANAGED_DIVERSITY]},
		@{$this->[ATR_MANAGED_MODULARITY]})
	{
		next unless ($monad_provider->can('final_setup'));
		$monad_provider->final_setup;
	}

	return;
}

sub dot_ini_got_package_name
# /type method
# /effect "Processes a package name from an .ini file."
# //parameters
#	package_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $package_name) = @ARGUMENTS;

	if (TRACE_FLAG)
	{
		print STDERR "Loading meta provider plugin ".$package_name->value."\n";
	}
	$this->monad_provider($package_name->value);
#	$this->detect_managers();

	return;
}

sub detect_managers
# /type method
# /effect ""
# //parameters
#	monad_provider
# //returns
{
	my ($this, $monad_provider) = @ARGUMENTS;

	if ($monad_provider->can('managed_diversity'))
	{
		push($this->[ATR_MANAGED_DIVERSITY], $monad_provider);
	}
	if ($monad_provider->can('managed_modularity'))
	{
		push($this->[ATR_MANAGED_MODULARITY], $monad_provider);
	}

	return;
}

sub modularity
# /type method
# /effect "Creates and returns the meta monad of a package."
# //parameters
#	pkg_name
#	pkg_file
#	pkg_line
# //returns
#	::Meta::Monad::Phase::Begin
{
	my ($this, $pkg_name, $pkg_file) = @ARGUMENTS;

	my $meta_monads = $this->[ATR_META_MONADS];
	unless (exists($meta_monads->{$pkg_name}))
	{
		if ($pkg_name eq 'main')
		{
			$this->prepare_monad($pkg_name, $pkg_file);

		} else {
			$translated_errors->advocate(
				'package_not_prepared',
				[$pkg_name]);
		}
	}
	my $meta_monad = $meta_monads->{$pkg_name};
#	$meta_monad->verify_pkg_file($pkg_file);
	return($begin_class->constructor($meta_monad));
}

sub individuality
# /type method
# /effect "Returns the already created meta monad of a package."
# //parameters
#	pkg_name
#	pkg_file
#	pkg_line
# //returns
#	::Meta::Monad::Phase::Run
{
	my ($this, $pkg_name, $pkg_file) = @ARGUMENTS;

	my $meta_monads = $this->[ATR_META_MONADS];
	unless (exists($meta_monads->{$pkg_name}))
	{
		if ($pkg_name =~ m{\ACarrot::(?:Meta|Diversity|Modularity)::}s)
		{
			$this->prepare_monad($pkg_name, $pkg_file);
		} else {
			$translated_errors->advocate(
				'individuality_without_modularity',
				[$pkg_name]);
		}
	}
	return($run_class->constructor($meta_monads->{$pkg_name}));
}

sub prepare_monad
# /type method
# /effect ""
# //parameters
#	pkg_name
#	pkg_file
# //returns
#	::Meta::Monad::Phase::Run
{
	my ($this, $pkg_name, $pkg_file) = @ARGUMENTS;

	my $meta_monads = $this->[ATR_META_MONADS];
	if (exists($meta_monads->{$pkg_name}))
	{
		$translated_errors->advocate(
			'already_prepared',
			[$pkg_name]);
	}
	$meta_monads->{$pkg_name} =
		$monad_class->constructor($pkg_name, $pkg_file);

	return;
}

sub remove_meta_monad
# /type method
# /effect ""
# //parameters
#	pkg_name
# //returns
{
	delete($_[THIS][ATR_META_MONADS]{$_[SPX_PKG_NAME]});
	return;
}

sub add_provider
# /type method
# /effect ""
# //parameters
#	meta_monad 	::Meta::Monad::Phase::Run
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $package_name = $meta_monad->package_name;
	my $monad_provider = $package_name->indirect_constructor;
	$this->[ATR_MONAD_PROVIDERS]{$package_name->value} = $monad_provider;

	$this->detect_managers($monad_provider);

	if ($monad_provider->can('final_monad_setup'))
	{
		$monad_provider->final_monad_setup;
	}
	return;
}

# called by other monads
sub monad_provider
# /type method
# /effect "Creates and returns a monad provider."
# //parameters
#	pkg_name        ::Personality::Abstract::Package_Name
# //returns
#	::Personality::Abstract::Instance
{
	my ($this, $pkg_name) = @ARGUMENTS;

	my $monad_providers = $this->[ATR_MONAD_PROVIDERS];
	unless (exists($monad_providers->{$pkg_name}))
	{
		my $package_name = $package_name_class
			->constructor($pkg_name);
		$package_name->load; # indirectly stores in ATR_META_MONADS
	}
	unless (exists($monad_providers->{$pkg_name}))
	{
		$translated_errors->advocate(
			'not_a_provider',
			[$pkg_name]);
	}

	return($monad_providers->{$pkg_name});
}

sub evt_package_load_before
# /type method
# /effect ""
# //parameters
#	pkg_name
#	pkg_file
# //returns
{
	my ($this, $pkg_name, $pkg_file) = @ARGUMENTS;

	$this->prepare_monad($pkg_name, $pkg_file);

	return if ($pkg_name =~ m{::(Abstract|Meta|Diversity)::}s);
	return if ($pkg_file =~ m{\./shadow}s);
	unless ($shadow_class->is_current($_[SPX_PKG_FILE]))
	{
		my $meta_monad = $prepare_class->constructor(
			$this->[ATR_META_MONADS]{$pkg_name});
		eval {
			$meta_monad->_mangled_diversity(
				$pkg_name,
				$_[SPX_PKG_FILE]);
			return(IS_TRUE);

		} or $translated_errors->escalate(
			'diversity_failed',
			[$pkg_name],
			$EVAL_ERROR);
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
	$_[THIS]->remove_meta_monad($_[SPX_PKG_NAME]);
	return;
}

sub attribute_destruction
# /type method
# /effect "Destructs the attributes of an instance (breaks circular references)"
# //parameters
#	?
# //returns
{
	$package_events->unsubscribe($_[THIS]);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.472
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"