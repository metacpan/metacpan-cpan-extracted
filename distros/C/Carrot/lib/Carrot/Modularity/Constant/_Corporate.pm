package Carrot::Modularity::Constant::_Corporate
# /type class
# /instances none
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Constant/_Corporate./manual_modularity.pl');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide_instance(
		my $prefixed_list = '::Modularity::Package::Prefixed_List');

# =--------------------------------------------------------------------------= #

sub default_plugin_autoload
# /type method
# /effect "Fills an newly constructed instance with life."
# //parameters
# //returns
{
	#NOTE: don't recurse, it'd only find Monad classes
	return(Scalar::Util::blessed($_[THIS]).'::*');
}

sub add_plugins
# /type method
# /effect ""
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $caller = [caller()];
#NOTE: The use of caller() is not so elegant here, but the call traces to
# a BEGIN block. Nothing can to into a BEGIN block or leave it. Therefore
# caller() isn't such a big loss.

	my $this = shift(\@ARGUMENTS);

	my $monad_pkg = $caller->[RDX_CALLER_PACKAGE];
	my $plugin_names = $prefixed_list->resolved_package_names(
		[@ARGUMENTS], # copy of remaining parameters - read-only strings
		Scalar::Util::blessed($this), #'::Modularity::Constant',
		$monad_pkg);

	foreach my $plugin_name (@$plugin_names)
	{
		$this->add_plugin($plugin_name);
	}
	return;
}

sub add_plugin
# /type method
# /effect ""
# //parameters
#	plugin_name  ::Modularity::Package::Name
# //returns
{
	my ($this, $plugin_name) = @ARGUMENTS;

	$this->_add_plugin($plugin_name);
	return;
}

sub add_re_pattern
# /type method
# /effect ""
# //parameters
#	plugin_pkg
#	plugin_name    ::Modularity::Package::Name
# //returns
{
	my ($this, $plugin_pkg, $plugin_name) = @ARGUMENTS;

	return(IS_FALSE) if (exists($this->[ATR_PATTERNS]{$plugin_pkg}));

	my $plugin = $plugin_name->indirect_constructor;
	my ($prefix, $symbols) = $plugin->provide_constants;

	my $re = '(?s)('.$prefix.'(?:'.join('|', @$symbols).'))';
	$this->[ATR_PATTERNS]{$plugin_pkg} = qr{$re};

	return(IS_TRUE);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.166
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
