package Carrot::Individuality::Singular::Process::Id::PID_File
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	#FIXME: find another solution
	require Carrot::Meta::Greenhouse::File_Content;

	my $expressiveness = Carrot::individuality;
#	$expressiveness->package_loader->provide(
#		my $file_name_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');

	$expressiveness->distinguished_exceptions->provide(
		my $file_not_plain = 'file_not_plain',
		my $file_not_owned = 'file_not_owned',
		my $file_not_writable = 'file_not_writable',
		my $perl_unlink_failed = 'perl_unlink_failed');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $file_name) = @ARGUMENTS;

	return unless (defined($file_name));
	if (-e $file_name)
	{
		unless (-f $file_name)
		{
			$file_not_plain->raise_exception(
				{+HKY_DEX_BACKTRACK => $file_name,
				 'file_name' => $file_name },
				ERROR_CATEGORY_SETUP);
		}
		unless (-O $file_name)
		{
			$file_not_owned->raise_exception(
				{+HKY_DEX_BACKTRACK => $file_name,
				 'file_name' => $file_name,
				'uid' => $EFFECTIVE_USER_ID},
				ERROR_CATEGORY_SETUP);
		}
	}
	$$this = $file_name;

	return;
}

sub retrieve
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $pid = IS_UNDEFINED;
#FIXME: this is correct?
	return($pid) unless (-f $$this);

	Carrot::Meta::Greenhouse::File_Content::read_into(
		$$this,
		$pid);
	$pid =~ s{\D+}{}sg;

	return($pid);
}

sub store
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $rv = open(my $file, PKY_OPEN_MODE_WRITE, $$this);
	if (defined($rv))
	{
		truncate($file, 0);
		print {$file} $$;
		close($file);
	} else {
		$file_not_writable->raise_exception(
			{+HKY_DEX_BACKTRACK => $$this,
			 'file_name' => $$this },
			ERROR_CATEGORY_SETUP);
	}
	return;
}

sub clear
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $rv = open(my $file, PKY_OPEN_MODE_WRITE, $$this);
	if (defined($rv))
	{
		truncate($file, 0);
		close($file);
	} else {
		$file_not_writable->raise_exception(
			{+HKY_DEX_BACKTRACK => $$this,
			 'file_name' => $$this},
			ERROR_CATEGORY_SETUP);
	}
	return;
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	if (-f $$this)
	{
		unless (unlink($$this))
		{
			$perl_unlink_failed->raise_exception(
				{+HKY_DEX_BACKTRACK => $$this,
				 'file_name' => $$this,
				 'os_error' => $OS_ERROR},
				ERROR_CATEGORY_SETUP);
		}
	}
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.63
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"