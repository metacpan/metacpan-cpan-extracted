package UNIVERSAL
# /type library
# //parameters
#	meta_provider  ::Meta::Provider
#	translated_errors  ::Meta::Greenhouse::Translated_Errors
# /capability ""
{
	my ($meta_provider, $translated_errors) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Universal./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE');

	my $parent_classes_provider = $meta_provider->monad_provider(
		'Carrot::Modularity::Object::Parent_Classes');

	my $hyper_cache = {}; #{instance_class}{method_class}{method_name}
	my $super_cache = {}; #{method_class}{method_name}

	$named_re->provide(
		my $re_perl_pkg_prefix = 'perl_pkg_prefix');

# =--------------------------------------------------------------------------= #

sub hyperseded
# /type method
# /effect ""
# /parameters *
# /returns *
{
	my $caller0 = [caller(0)];
	my $caller1 = [caller(1)];
	my ($this) = @ARGUMENTS;

	my $method_name =
		($caller1->[RDX_CALLER_SUB_NAME] =~ s{$re_perl_pkg_prefix}{}ro);

	my $method_class = $caller0->[RDX_CALLER_PACKAGE];
	my $instance_class = Scalar::Util::blessed($this) || $this; # might be the constructor

	unless (exists($hyper_cache->{$instance_class}))
	{
		$hyper_cache->{$instance_class} = {};
	}
	unless (exists($hyper_cache->{$instance_class}{$method_class}))
	{
		$hyper_cache->{$instance_class}{$method_class} = {};
	}
	unless (exists($hyper_cache->{$instance_class}{$method_class}{$method_name}))
	{
		eval {
			my $parent_classes = $parent_classes_provider->lookup(
				$instance_class);
			my $method_call = $parent_classes->hyperseded(
				$method_class, $method_name);
			$hyper_cache->{$instance_class}{$method_class}{$method_name} =
				$method_call;
			return(IS_TRUE);

		} or $translated_errors->escalate(
			'hyperseded_target_fetch',
			[$method_name, $instance_class, $method_class],
			$EVAL_ERROR);
	}

	goto(&{$hyper_cache->{$instance_class}{$method_class}{$method_name}});
}

sub superseded
# /type method
# /effect ""
# /parameters *
# /returns *
{
	my ($this) = @ARGUMENTS;
	my $caller0 = [caller(0)];
	my $caller1 = [caller(1)];

	my $method_name =
		($caller1->[RDX_CALLER_SUB_NAME] =~ s{$re_perl_pkg_prefix}{}ro);

	my $method_class = $caller0->[RDX_CALLER_PACKAGE];
	unless (exists($super_cache->{$method_class}))
	{
		$super_cache->{$method_class} = {};
	}
	unless (exists($super_cache->{$method_class}{$method_name}))
	{
		eval {
			my $parent_classes = $parent_classes_provider
				->lookup($method_class);
			$super_cache->{$method_class}{$method_name} =
				$parent_classes->superseded($method_name);
			return(IS_TRUE);

		} or $translated_errors->escalate(
			'superseded_target_fetch',
			[$method_name, $method_class],
			$EVAL_ERROR);
	}

	goto(&{$super_cache->{$method_class}{$method_name}});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.260
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
