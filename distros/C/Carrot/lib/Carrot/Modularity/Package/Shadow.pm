package Carrot::Modularity::Package::Shadow
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Shadow./manual_modularity.pl');
	} #BEGIN

#	require Carrot::Modularity::Package::Patterns;
#	my $pkg_patterns = Carrot::Modularity::Package::Patterns->constructor;

	require Carrot::Meta::Greenhouse::File_Content;
	my $file_content = Carrot::Meta::Greenhouse::File_Content->constructor;

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
#		my $file_content = '::Meta::Greenhouse::File_Content',
		my $writable_overlay = '::Meta::Greenhouse::Writable_Overlay',
		my $compilation_name = '::Meta::Greenhouse::Compilation_Name');

# =--------------------------------------------------------------------------= #

sub is_current
# /type function
# /effect ""
# //parameters
#	pkg_file
# //returns
#	::Personality::Abstract::Boolean
{
	my ($pkg_file) = @ARGUMENTS;

	my $shadow_pkg = $pkg_patterns->dot_directory_from_file($pkg_file)
		. "shadow-$$compilation_name.pm";
	$writable_overlay->redirect_read(\$shadow_pkg);

	if (-f $shadow_pkg and -s _)
	{
		my $mtime1 = (stat($shadow_pkg))[RDX_STAT_MTIME];
		my $mtime2 = (stat($pkg_file))[RDX_STAT_MTIME];
		if ($mtime1 > $mtime2)
		{
			$_[SPX_PKG_FILE] = $shadow_pkg;
			return(IS_TRUE);
#		} else {
#			unlink($shadow_pkg);
		}
	}

	return(IS_FALSE);
}

sub compile
# /type function
# /effect ""
# //parameters
#	pkg_file
# //returns
{
	my ($pkg_file) = @ARGUMENTS;

	return if ($PROCESS_EXIT_CODE > 0);

#	unless ($pkg_file =~ m{\.tmp\.}s)
#	{
#		die("$pkg_file: doesn't seem to be a temporary file.");
#	}

	my $shadow_pkg = ($pkg_file =~ s{\.pmt\z}{.pm}sr);
	$writable_overlay->redirect_write(\$shadow_pkg);

	$writable_overlay->redirect_read(\$pkg_file);
	unless (-f $pkg_file)
	{
		die("$pkg_file: can't compile a non-existing file.");
	}
	$file_content->read_into($pkg_file, my $buffer);

	my $external_modularity = $pkg_patterns
		->dot_directory_from_file($pkg_file)
		. 'manual_modularity.pll';
	unless (-f $external_modularity)
	{
		$external_modularity = $pkg_patterns
			->dot_directory_from_file($pkg_file)
			. "managed_modularity-$$compilation_name.pl";
		$writable_overlay->redirect_read(\$external_modularity);
	}

	if (-f $external_modularity)
	{
		$file_content->read_into(
			$external_modularity,
			my $extra_begin_code);

		$extra_begin_code =~ s{
			\A.*?
			\#--8<--\ cut\ -->8--
			(?:\012|\015\012?)}{\n}sx;
		$extra_begin_code =~ s{
			(?:\012|\015\012?)
			\#--8<--\ cut\ -->8--
			.*\z}{\n}sx;
		$extra_begin_code =~ s{(?:\012|\015\012?)\K}{\t\t}sg;

		$buffer =~ s{\A.*?(?:\012|\015\012?)(package\h+\w)}{$1}s;
		unless ($buffer =~ s
			{((?:\012|\015\012?)+\h+\}\ \#BEGIN)}
			{$extra_begin_code$1}s)
		{
			die("Could not add extra_begin_code for package '$pkg_file'.\n");
		}
	}

	my $managed_hardcoded = '$expressiveness->managed_hardcoded;';
	unless ($buffer =~ s
		{(((?:\012|\015\012?)+\h+)\}\ \#BEGIN)}
		{$1$managed_hardcoded$2}s)
	{
		die("Could not add ->managed_hardcoded for package '$pkg_file'.\n");
	}

#	$buffer =~ s{(?:\012|\015\012?)\h+use (?:strict|warnings);(?=\012|\015\012?)}{\n}sg;
	$buffer =~ s{
		(?:\012|\015\012?)\#(?:[\ \t]+)PREPARE\ \{
		.*\}\ \#PREPARE\s*}{}sx;

	$buffer =~ s{\ *\#--8<--\ \w+-[\w\:]+-\w+\ -->8--\#}{}sgx;
#	$buffer =~ s{
#		(?:\012|\015\012?)\h+use\h+strict;}{}sx;
	my $modified = ($buffer =~ s{
		(?:\012|\015\012?)\h+(END)\h+\{\h+\#(\d+)
		.*
		(?:\012|\015\012?)\h+\}\h+\#\g{1}-\g{2}}{\n}sgx);
	unless ($modified == 1)
	{
		die("Could not remove end block in '$pkg_file'.");
	}
	$buffer =~ s{#--8<-- carrot-(modularity|individuality)-(start|end) -->8--#}{}saag;

	$file_content->overwrite_from($shadow_pkg, $buffer);
	$writable_overlay->remove($pkg_file);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.160
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
