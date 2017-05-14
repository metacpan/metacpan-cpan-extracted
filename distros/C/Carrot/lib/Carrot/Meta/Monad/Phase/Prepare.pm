package Carrot::Meta::Monad::Phase::Prepare
# /type class
# //parent_classes
#	::Meta::Monad
# //parameters
#	managed_diversity  ::Personality::Abstract::Array
# /capability "Capabilities of the $meta_monad before loading."
{
	my ($managed_diversity) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad/Phase/Prepare./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $writable_overlay = '::Meta::Greenhouse::Writable_Overlay',
		my $narrowed_re = '::Meta::Greenhouse::Narrowed_RE',
		my $compilation_name = '::Meta::Greenhouse::Compilation_Name');

	my $substitute_diversity1 = $narrowed_re->substitute_softspace_line(
		'DIVERSITY \{',
		'^-------^___');
	my $substitute_diversity2 = $narrowed_re->substitute_softspace_line(
		'\} #DIVERSITY',
		'____^-------^');

	my $substitute_modularity1 = $narrowed_re->substitute_softspace_line(
		'MODULARITY \{',
		'^--------^___');
	my $substitute_modularity2 = $narrowed_re->substitute_softspace_line(
		'\} #MODULARITY',
		'____^--------^');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that  ::Meta::Monad
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	@$this = @$that;
	$this->[ATR_PRINCIPLE] = 'diversity';

	return;
}

sub _mangled_diversity
# /type method
# /effect ""
# //parameters
#	pkg_name
#	pkg_file
# //returns
{
	my ($this, $pkg_name, $pkg_file) = @ARGUMENTS;

	my $source_code = $this->source_code;
	return if ($$source_code =~ m{require\('Carrot/}s);

	my $pmt_file = $pkg_patterns->dot_directory_from_file($pkg_file)
		. "/shadow-$$compilation_name.pmt";
	my $shadow_tmp = $pmt_file;
	$writable_overlay->redirect_write(\$shadow_tmp);
	$_[SPX_PKG_FILE] = $shadow_tmp;

	if ($substitute_diversity1->($source_code, 'PREPARE'))
	{
		$substitute_diversity2->($source_code, 'PREPARE');
	}
	if ($substitute_modularity1->($source_code, 'BEGIN'))
	{
		$substitute_modularity2->($source_code, 'BEGIN');
	}

	if ($source_code->has_begin_block)
	{
		$source_code->add_modularity_markers;

	} else {
		$source_code->add_begin_block_after_warnings;
	}
	$source_code->add_end_block_after_begin(time, $pmt_file);
	if ($source_code->has_carrot_individuality)
	{
		$source_code->add_individuality_markers;

	} else {
		$source_code->add_individuality_after_end;
	}

	#NOTE: the following is manual diversity
	if ($$source_code =~ s{
			(?:\012|\015\012?)(\h+)PREPARE\h+\{(?:\012|\015\012?)
			((?:\h+[^\012\015]+(?:\012|\015\012?))+?)
			\g{1}\}\ \#PREPARE
		}
		{}sx)
	{
		my $block_code = $2;
		$block_code =~ s
			{Carrot::diversity\h+;}
			{\$this;}s;
		# the code might modify $_[SPX_PKG_FILE]
		#FIXME: access to $source_code too much?
		eval $block_code;
		die($@) if ($@); #simple escalation
	}
	#NOTE: from here onwards managed diversity

	foreach my $monad_provider (@$managed_diversity)
	{
		$monad_provider->managed_diversity(
			$this,
			$source_code);
	}

	$source_code->store_in_file($shadow_tmp);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.397
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
