package Carrot::Personality::Valued::File::Name
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $english_re = '::Diversity::English::Regular_Expression',
		my $translated_errors =
			'::Meta::Greenhouse::Translated_Errors');

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $status_class =
			__PACKAGE__.'::Status',
		my $directory_name_class =
			__PACKAGE__.'::Type::Directory',
		my $directory_content_class =
			__PACKAGE__.'::Type::Directory::Content',
		my $regular_name_class =
			__PACKAGE__.'::Type::Regular',
		my $regular_content_class =
			__PACKAGE__.'::Type::Regular::Content::UTF8_wBOM');

	my $re_parent_path = $english_re->compile('
		ON_START ( ANY_CHARACTER ANY_TIMES ) OS_FS_PATH_DELIMITER');

	my $re_hidden_name = $english_re->compile('
	( ON_START  ALTERNATIVELY OS_FS_PATH_DELIMITER)
	PERIOD [ COMPLEMENT  OS_FS_PATH_DELIMITER ] ANY_TIMES  ON_END');

# =--------------------------------------------------------------------------= #

sub import_textual_value
# /type method
# /effect "Verifies the parameter"
# //parameters
#	name
# //returns
#	::Personality::Abstract::Boolean
{
	return($_[SPX_NAME] !~ m{\p{PosixCntrl}}s);
}

sub path_elements
# /type method
# /effect ""
# //parameters
# //returns
{
	return([split(
	 	OS_FS_PATH_DELIMITER,
		${$_[THIS]},
		PKY_SPLIT_RETURN_FULL_TRAIL)]);
}

sub canonified
# /type method
# /effect ""
# //parameters
# //returns
{
#tested with '/./../abc/.././../cde/efg/././hij/../../klm/./.'
#tested with './../abc/.././../cde/efg/././hij/../../klm/././'
	my $elements = $_[THIS]->path_elements;

	my $is_absolute = IS_FALSE;
	if ($elements->[ADX_FIRST_ELEMENT] eq '')
	{
		$is_absolute = IS_TRUE;
	}
	my $trailing_slash = IS_FALSE;
	if ($elements->[ADX_LAST_ELEMENT] eq '')
	{
		$trailing_slash = IS_TRUE;
	}

	my $canonified = [];
	foreach my $element (@$elements)
	{
		if ($element eq '')
		{
		} elsif ($element eq OS_FS_CURRENT_DIRECTORY)
		{
		} elsif ($element eq OS_FS_PARENT_DIRECTORY)
		{
			pop($canonified);
		} else {
			push($canonified, $element);
		}
	}
	if ($is_absolute)
	{
		unshift($canonified, '');
	}
	if ($trailing_slash)
	{
		push($canonified, '');
	}

	my $value = join(OS_FS_PATH_DELIMITER, @$canonified);
#	$value =~ s{[\000-\037^?]}{X}sg;

	return($value);
}

sub canonify
# /type method
# /effect ""
# //parameters
# //returns
{
	${$_[THIS]} = $_[THIS]->canonified;
	return;
}

sub qualify
# /type method
# /effect ""
# //parameters
#	name
# //returns
{
	my ($this, $name) = @ARGUMENTS;

	return if (substr($$this, 0, 1) eq OS_FS_PATH_DELIMITER);
	$$this = $name .OS_FS_PATH_DELIMITER. $$this;
	return;
}

sub qualified
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Instance
{
	my ($this, $name) = @ARGUMENTS;

	if (substr($$this, 0, 1) eq OS_FS_PATH_DELIMITER)
	{
		return($this->sibling_constructor($name));
	} else {
		return($this->sibling_constructor(
			       $$this
			       .OS_FS_PATH_DELIMITER
			       .$name));
	}
}

sub require_fatally
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($this->exists)
	{
		$translated_errors->oppose('file_not_found', [$$this]);
	}
	return;
}

sub require_type_regular_fatally
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($this->is_type_regular)
	{
		$translated_errors->advocate(
			'not_a_regular_file', [$$this]);
	}
	return;
}

sub require_type_directory_fatally
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	unless ($this->is_type_directory)
	{
		$translated_errors->advocate('not_a_directory', [$$this]);
	}
	return;
}

sub hierarchy_depth
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $canonified = $this->canonified;
	return(scalar(split(
		OS_FS_PATH_DELIMITER,
		$canonified,
		PKY_SPLIT_IGNORE_EMPTY_TRAIL)));
}

sub is_relative
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(substr(${$_[THIS]}, 0, 1) ne OS_FS_PATH_DELIMITER);
}

sub relative_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return((${$_[THIS]} =~ s{$re_parent_path}{}sro));
}

sub status
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($status_class->constructor([stat(${$_[THIS]})]));
}

sub access_timestamp_is_newer
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($exists1, $mtime1) = (-e ${$_[THIS]}, (stat(_))[RDX_STAT_ATIME]);
	return (IS_UNDEFINED) unless ($exists1);
	my ($exists2, $mtime2) = (-e ${$_[THAT]}, (stat(_))[RDX_STAT_ATIME]);
	return (IS_UNDEFINED) unless ($exists2);
	return($mtime2 > $mtime1);
}

sub access_timestamp_is_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($exists1, $mtime1) = (-e ${$_[THIS]}, (stat(_))[RDX_STAT_ATIME]);
	return (IS_UNDEFINED) unless ($exists1);
	my ($exists2, $mtime2) = (-e ${$_[THAT]}, (stat(_))[RDX_STAT_ATIME]);
	return (IS_UNDEFINED) unless ($exists2);
	return($mtime2 == $mtime1);
}

sub modification_timestamp_is_newer
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($exists1, $mtime1) = (-e ${$_[THIS]}, (stat(_))[RDX_STAT_MTIME]);
	return (IS_UNDEFINED) unless ($exists1);
	my ($exists2, $mtime2) = (-e ${$_[THAT]}, (stat(_))[RDX_STAT_MTIME]);
	return (IS_UNDEFINED) unless ($exists2);
	return($mtime2 > $mtime1);
}

sub modification_timestamp_is_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($exists1, $mtime1) = (-e ${$_[THIS]}, (stat(_))[RDX_STAT_MTIME]);
	return (IS_UNDEFINED) unless ($exists1);
	my ($exists2, $mtime2) = (-e ${$_[THAT]}, (stat(_))[RDX_STAT_MTIME]);
	return (IS_UNDEFINED) unless ($exists2);
	return($mtime2 == $mtime1);
}

sub status_timestamp_is_newer
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($exists1, $mtime1) = (-e ${$_[THIS]}, (stat(_))[RDX_STAT_CTIME]);
	return (IS_UNDEFINED) unless ($exists1);
	my ($exists2, $mtime2) = (-e ${$_[THAT]}, (stat(_))[RDX_STAT_CTIME]);
	return (IS_UNDEFINED) unless ($exists2);
	return($mtime2 > $mtime1);
}

sub status_timestamp_is_equal
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	?
{
	my ($exists1, $mtime1) = (-e ${$_[THIS]}, (stat(_))[RDX_STAT_CTIME]);
	return (IS_UNDEFINED) unless ($exists1);
	my ($exists2, $mtime2) = (-e ${$_[THAT]}, (stat(_))[RDX_STAT_CTIME]);
	return (IS_UNDEFINED) unless ($exists2);
	return($mtime2 == $mtime1);
}

sub has_extension
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $name) = @ARGUMENTS;

	my $l = length($name)+1;
	return(substr(${$_[THIS]}, -$l) eq ('.'.$name));
}

sub parent_directory
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	if (${$_[THIS]} =~ m{$re_parent_path})
	{
		return($directory_name_class->constructor($1));

	} else {
		return(IS_UNDEFINED);
	}
}

sub is_hidden_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{$re_hidden_name}o);
}

sub is_current_directory_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} eq OS_FS_CURRENT_DIRECTORY);
}

sub is_parent_directory_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} eq OS_FS_PARENT_DIRECTORY);
}

sub recognize_type
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	my $type = IS_UNDEFINED;
	if (-f ${$_[THIS]})
	{
		$type = $regular_name_class;

	} elsif (-d _)
	{
		$type = $directory_name_class;

	} elsif (-p _)
	{
		#FIXME: require is missing
		$type = __PACKAGE__.'::Type::FIFO';

	} elsif (-S _)
	{
		$type = __PACKAGE__.'::Type::Socket';

	} elsif (-b _)
	{
		$type = __PACKAGE__.'::Type::Block';

	} elsif (-c _)
	{
		$type = __PACKAGE__.'::Type::Character';

	} elsif (-l _)
	{
		$type = __PACKAGE__.'::Type::Symbolic_Link';

	}

	return($type);
}

sub consider_automatically
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $name_class = $this->recognize_type;
	bless($this, $name_class) if (defined($name_class));
	return;
}

sub considered_automatically
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance +undefined
{
	my ($this) = @ARGUMENTS;

	my $name_class = $this->recognize_type;
	if (defined($name_class))
	{
		my $clone = $this->clone_constructor;
		bless($clone, $name_class);
		return($clone);
	} else {
		return(IS_UNDEFINED);
	}
}

sub consider_directory
# /type method
# /effect ""
# //parameters
# //returns
{
	bless($_[THIS], $directory_name_class);
	return;
}

sub considered_directory
# /type method
# /effect ""
# //parameters
# //returns
{
	return(bless($_[THIS]->clone_constructor,
		$directory_name_class));
}

sub consider_directory_content
# /type method
# /effect ""
# //parameters
# //returns
{
	bless($_[THIS], $directory_content_class);
	return;
}

sub considered_directory_content
# /type method
# /effect ""
# //parameters
# //returns
{
	return(bless($_[THIS]->clone_constructor,
		$directory_content_class));
}

sub consider_regular
# /type method
# /effect ""
# //parameters
# //returns
{
	bless($_[THIS], $regular_name_class);
	return;
}

sub considered_regular
# /type method
# /effect ""
# //parameters
# //returns
{
	return(bless($_[THIS]->clone_constructor,
		$regular_name_class));
}

sub consider_regular_content
# /type method
# /effect ""
# //parameters
# //returns
{
	bless($_[THIS], $regular_content_class);
	return;
}

sub considered_regular_content
# /type method
# /effect ""
# //parameters
# //returns
{
	return(bless($_[THIS]->clone_constructor,
		$regular_content_class));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.254
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
