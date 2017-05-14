package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Data::Connection
# /type class
# //parent_classes
#	[=parent_pkg=]::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		my $expressiveness = Carrot::modularity;
		return unless ($expressiveness->managed_file->needs_update);
		$expressiveness->scalar_isset_methods->direct(
			'close', 'keep_alive');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	${$_[THIS]} //= 'close';
	return;
}

# sub set_keep_alive
# # /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# # //parameters
# # //returns
# {
# 	${$_[THIS]} = 'keep_alive';
# 	return;
# }
#
# sub is_keep_alive
# # /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# # //parameters
# # //returns
# #	::Personality::Abstract::Boolean
# {
# 	return(${$_[THIS]} eq 'keep-alive');
# }
#
# sub is_close
# # /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# # //parameters
# # //returns
# #	::Personality::Abstract::Boolean
# {
# 	return(${$_[THIS]} eq 'close');
# }
#
# sub set_close
# # /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# # //parameters
# # //returns
# {
# 	${$_[THIS]} = 'close';
# 	return;
# }

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.62
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"