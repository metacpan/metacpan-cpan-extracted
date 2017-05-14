package Carrot::Continuity::Coordination::Episode::Local
# /type class
# /attribute_type ::One_Anonymous::Hash
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->distinguished_exceptions->provide(
		my $hash_key_duplicate = 'hash_key_duplicate',
		my $hash_element_missing = 'hash_element_missing');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->register_event(@ARGUMENTS) if ($#ARGUMENTS > ADX_NO_ELEMENTS);
	return;
}

sub register_event
# /type method
# /effect ""
# //parameters
#	event_name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $event_name (@ARGUMENTS)
	{
		if (exists($this->{$event_name}))
		{
			$hash_key_duplicate->raise_exception(
				{+HKY_DEX_BACKTRACK => $event_name,
				 'key' => $event_name,
				 'value' => \$this->{$event_name}},
				ERROR_CATEGORY_SETUP);
		}
		$this->{$event_name} = {};
	}
	return;
}

sub enforce_registration
# /type method
# /effect ""
# //parameters
#	event_name
# //returns
{
	my ($this, $event_name) = @ARGUMENTS;

	return if (exists($this->{$event_name}));
	$hash_element_missing->raise_exception(
		{+HKY_DEX_BACKTRACK => $event_name,
		 'key' => $event_name},
		ERROR_CATEGORY_SETUP);
	return;
}

sub deregister_event
# /type method
# /effect ""
# //parameters
#	event_name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $event_name (@ARGUMENTS)
	{
		$this->enforce_registration($event_name);
		delete($this->{$event_name});
	}
	return;
}

sub subscribe
# /type method
# /effect ""
# //parameters
#	event_name
#	event_receiver
# //returns
{
	my ($this, $event_name, $event_receiver) = @ARGUMENTS;

	$this->enforce_registration($event_name);
#	my $key = Scalar::Util::refaddr($event_receiver);
	my $key = $event_receiver->_internal_memory_address;
	$this->{$event_name}{$key} = $event_receiver;
	return;
}

sub unsubscribe
# /type method
# /effect ""
# //parameters
#	event_name
#	event_receiver
# //returns
{
	my ($this, $event_name, $event_receiver) = @ARGUMENTS;

	$this->enforce_registration($event_name);
#	my $key = Scalar::Util::refaddr($event_receiver);
	my $key = $event_receiver->_internal_memory_address;
	delete($this->{$event_name}{$key});
	return;
}

sub trigger_event
# /type method
# /effect ""
# //parameters
#	event_name
#	*
# //returns
{
	my ($this, $event_name) = splice(\@ARGUMENTS, 0, 2);

	$this->enforce_registration($event_name);
	my $method = "evt_$event_name";
	foreach my $event_receiver (values($this->{$event_name}))
	{
		$event_receiver->$method(@ARGUMENTS);
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