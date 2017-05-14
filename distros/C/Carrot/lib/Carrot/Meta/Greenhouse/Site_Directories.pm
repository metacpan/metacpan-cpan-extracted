package Carrot::Meta::Greenhouse::Site_Directories
# /type class
# /instances singular
# /attribute_type ::One_Anonymous::Hash
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Site_Directories./manual_modularity.pl');
	} #BEGIN

	my $path = [];
	my $program_directory =
		__PACKAGE__->dot_directory_from_file($PROGRAM_NAME);

	foreach my $directory ($program_directory,
		"$ENV{'HOME'}/.carrot",
		'/etc/carrot')
	{
		next unless (-d $directory);
		push($path, $directory);
	}
	my $THIS = bless($path, __PACKAGE__);

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance of the class"
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($THIS);
}

#FIXME: duplicates ::Patterns and is already out of sync
sub dot_directory_from_file
# /type class_method
# /effect ""
# //parameters
#	pkg_file        ::Personality::Abstract::Text
# //returns
#	?
{
	return((($_[SPX_PKG_FILE] =~ m{\A(.+?)\.(?:[^/]+|/shadow.+)\z}saa)
			? $1
			: $_[SPX_PKG_FILE])
		.'.');
}

sub subdirectories
# /type method
# /effect ""
# //parameters
#	directory  ::Personality::Abstract::Text
# //returns
#	?
{
	my $rv = [];
	foreach my $directory (@$path)
	{
		my $subdirectory = "$directory/$_[SPX_SUBDIRECTORY]";
		next unless (-d $subdirectory);
		push($rv, $subdirectory);
	}
	return($rv);
}

# sub file_names
# # /type method
# # /effect ""
# # //parameters
# #	file_name  ::Personality::Abstract::Text
# # //returns
# #	?
# {
# 	my $rv = [];
# 	foreach my $directory (@$path)
# 	{
# 		my $file_name = "$directory/$_[SPX_FILE_NAME]";
# 		next unless (-f $file_name);
# 		push($rv, $file_name);
# 	}
# 	return($rv);
# }

sub dot_ini_got_directory_name
# /type method
# /effect "Processes a directory name from an .ini file."
# //parameters
#	directory_name  ::Personality::Valued::File::Name::Type::Directory
# //returns
{
	my ($class, $directory_name) = @ARGUMENTS;

	$directory_name->require_fatally;
	push($path, $directory_name->value);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.24
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
