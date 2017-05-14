package Carrot::Individuality::Singular::Process::Epoch_Time
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use Time::HiRes qw(time);

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $time_manipulation_detected = 'time_manipulation_detected');

	my $now = my $t0 = 0;

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my $class = shift(\@ARGUMENTS);

	my $this = \$now;
	bless($this, $class);
	$this->update;
	return($this);
}

sub update
# /type method
# /effect ""
# //parameters
# //returns
{
	unless ($t0 == $now)
	{
		$time_manipulation_detected->raise_exception(
			{'now' => $now,
			 't0' => $t0},
			ERROR_CATEGORY_IMPLEMENTATION);
	}
	$t0 = $now = Time::HiRes::time();
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.51
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
