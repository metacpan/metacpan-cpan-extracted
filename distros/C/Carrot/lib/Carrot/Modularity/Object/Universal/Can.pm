package Carrot::Modularity::Object::Universal::Can
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Universal/Can./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub can_all_of
# /type method
# /effect ""
# //parameters
#	method_name  +multiple
# //returns
#	::Personality::Abstract::Boolean
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		next if ($this->can($name));
		return(IS_FALSE);
	}
	return(IS_TRUE);
}

sub can_any_of
# /type method
# /effect ""
# //parameters
#	method_name  +multiple
# //returns
#	::Personality::Abstract::Boolean
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		next unless ($this->can($name));
		return(IS_TRUE);
	}
	return(IS_FALSE);
}

sub can_all_of_that
# /type method
# /effect ""
# //parameters
#	that  +multiple  ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $that) = @ARGUMENTS;

	return(($this->isa($that)
		or $this->can_all_of($that->registered_method_names))
		? IS_TRUE
		: IS_FALSE);
}

#Too much code for too little gain
#require Scalar::Util; # for distinguishing blessed from non-blessed references
#my $can_all_of_that = {};
#sub can_all_of_that
#{
#	my ($this, $that) = @ARGUMENTS;
#
#	my $this_class = Scalar::Util::blessed($this);
#	my $that_class = Scalar::Util::blessed($that);
#
#	unless (exists($can_all_of_that->{$this_class}))
#	{
#		$can_all_of_that->{$this_class} = {};
#	}
#	unless (exists($can_all_of_that->{$this_class}{$that_class}))
#	{
#		$can_all_of_that->{$this_class} =
#			(($this->isa($that)
#			or $this->can_all_of($that->registered_method_names))
#			? IS_TRUE
#			: IS_FALSE);
#	}
#	return($can_all_of_that->{$this_class}{$that_class});
#}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.40
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
