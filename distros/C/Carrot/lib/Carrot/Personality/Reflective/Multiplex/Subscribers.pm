package Carrot::Personality::Reflective::Multiplex::Subscribers
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Reflective/Multiplex/Subscribers./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_SUBSCRIBERS] = {};

	return;
}

sub method_on_all
# /type method
# /effect ""
# //parameters
#	method
#	*
# //returns
{
	my ($this, $method) = splice(\@ARGUMENTS, 0, 2);

	my $subscribers = $this->[ATR_SUBSCRIBERS];
	foreach my $key (keys($subscribers))
	{
		next unless (exists($subscribers->{$key}));
		$subscribers->{$key}->$method(@ARGUMENTS);
	}
	return;
}

sub first_defined_result
# /type method
# /effect ""
# //parameters
#	method
#	*
# //returns
#	?
{
	my ($this, $method) = splice(\@ARGUMENTS, 0, 2);

	my $subscribers = $this->[ATR_SUBSCRIBERS];
	foreach my $key (keys($subscribers))
	{
		next unless (exists($subscribers->{$key}));
		my $rv = $subscribers->{$key}->$method(@ARGUMENTS);
		return($rv) if (defined($rv));
	}
	return($rv);
}

sub all_defined_results
# /type method
# /effect ""
# //parameters
#	method
#	*
# //returns
#	?
{
	my ($this, $method) = splice(\@ARGUMENTS, 0, 2);

	my $subscribers = $this->[ATR_SUBSCRIBERS];
	my $rvs = [];
	foreach my $key (keys($subscribers))
	{
		next unless (exists($subscribers->{$key}));
		my $rv = $subscribers->{$key}->$method(@ARGUMENTS);
		next unless (defined($rv));
		push($rvs, $rv);
	}
	return($rvs);
}

sub subscribe
# /type method
# /effect ""
# //parameters
#	subscriber
# //returns
{
	my ($this, $subscriber) = @ARGUMENTS;

	my $key = $subscriber->_internal_memory_address;
	$this->[ATR_SUBSCRIBERS]{$key} = $subscriber;

	return;
}

sub unsubscribe
# /type method
# /effect ""
# //parameters
#	subscriber
# //returns
{
	my ($this, $subscriber) = @ARGUMENTS;

	my $key = $subscriber->_internal_memory_address;
	delete($this->[ATR_SUBSCRIBERS]{$key});

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.79
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"