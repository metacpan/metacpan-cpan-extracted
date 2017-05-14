package Carrot::Personality::Elemental::Scalar::Textual::File_Name
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Elemental/Scalar/Textual/File_Name./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $stat_class = '::Personality::Valued::Perl5::Stat');

# =--------------------------------------------------------------------------= #

sub descend_value
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(${$_[THIS]} .= OS_FS_PATH_DELIMITER. $_[SPX_VALUE]);
}

sub descend
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(${$_[THIS]} .= OS_FS_PATH_DELIMITER. ${$_[THAT]});
}

sub change_mode
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(chown($_[SPX_VALUE], ${$_[THIS]}));
}

sub change_owner
# /type method
# /effect ""
# //parameters
#	uid
#	gid
# //returns
#	?
{
	my ($this, $uid, $gid) = @ARGUMENTS;
	return(chown($uid, $gid, $$this));
}

sub change_root_directory
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(chroot(${$_[THIS]}));
}

sub change_timestamps
# /type method
# /effect ""
# //parameters
#	atime
#	mtime
# //returns
#	?
{
	my ($this, $atime, $mtime) = @ARGUMENTS;
	return(chown($atime, $mtime, $$this));
}

sub change_working_directory
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(chdir(${$_[THIS]}));
}

sub create_directory
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(mkdir(${$_[THIS]}));
}

sub create_hard_link
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(link(${$_[THIS]}, $_[SPX_VALUE]));
}

sub create_symbolic_link
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(truncate(${$_[THIS]}, $_[SPX_VALUE]));
}

sub forward_execution
# /type method
# /effect ""
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);
	exec($$this, @ARGUMENTS);
}

sub remove_directory
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(rmdir(${$_[THIS]}));
}

#FIXME: questionable
sub open
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(CORE::open(my $fh, $_[SPX_VALUE], ${$_[THIS]}));
}

sub remove
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(unlink(${$_[THIS]}));
}

sub rename
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $name) = @ARGUMENTS;

	CORE::rename($$this, $name) || return(IS_FALSE);
	$$this = $name;
	return(IS_TRUE);
}

sub status
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($stat_class->constructor(stat(${$_[THIS]})));
}

sub status_of_link
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($stat_class->constructor(lstat(${$_[THIS]})));
}

sub concurrent_execution
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Number
{
	my $this = shift(\@ARGUMENTS);
	return(system($$this, @ARGUMENTS));
}

sub truncate
# /type method
# /effect ""
# //parameters
#	value
# //returns
#	?
{
	return(CORE::truncate(${$_[THIS]}, $_[SPX_VALUE]));
}

sub has_size_zero
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-z ${$_[THIS]});
}

sub has_size_greater_zero
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-s ${$_[THIS]});
}

sub has_bit_sticky
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-k ${$_[THIS]});
}

sub has_bit_gid
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-g ${$_[THIS]});
}

sub has_bit_uid
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-u ${$_[THIS]});
}

sub exists
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-e ${$_[THIS]});
}

sub is_readable_effectively
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-r ${$_[THIS]});
}

sub is_writable_effectively
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-w ${$_[THIS]});
}


sub is_executable_effectively
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-x ${$_[THIS]});
}

sub is_owned_effectively
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-o ${$_[THIS]});
}

sub is_readable_really
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-R ${$_[THIS]});
}

sub is_writable_really
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-W ${$_[THIS]});
}

sub is_executable_really
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-X ${$_[THIS]});
}

sub is_owned_really
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-O ${$_[THIS]});
}

sub is_type_regular
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-f ${$_[THIS]});
}

sub is_type_directory
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-d ${$_[THIS]});
}

sub is_type_symbolic_link
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-l ${$_[THIS]});
}

sub is_type_named_pipe
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-p ${$_[THIS]});
}

sub is_type_socket
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-S ${$_[THIS]});
}

sub is_type_block_special
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-b ${$_[THIS]});
}

sub is_type_character_special
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-c ${$_[THIS]});
}

sub is_type_opened_tty
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(-t ${$_[THIS]});
}

#FIXME: this is a lousy name
sub utime
# /type method
# /effect ""
# //parameters
#	atime
#	mtime
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);
	return(utime(@ARGUMENTS, $$this));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.113
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
