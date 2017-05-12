#!perl

use strict;
use warnings;

use Test::More;


# Load module.
eval
{
	require Test::Kwalitee::Extra;

	# Load Module::CPANTS::Kwalitee::Uses so that we can override its analyse()
	# class method below.
	require Module::CPANTS::Kwalitee::Uses;
};
plan( skip_all => 'Test::Kwalitee::Extra required to evaluate code' )
	if $@;

# Module::CPANTS::Kwalitee::Uses calls Module::ExtractUse to find out what
# modules are used in the code. However Module::ExtractUse lumps optional
# modules loaded via Class::Load::try_load_class() along with required uses, so
# Module::CPANTS::Kwalitee::Uses incorrectly identifies String::Diff as a
# requirement for this distribution. The following code monkey-patches
# Module::CPANTS::Kwalitee::Uses->analyse() to remove String::Diff for now.
my $analyse_coderef = \&Module::CPANTS::Kwalitee::Uses::analyse;
no warnings 'redefine';
local *Module::CPANTS::Kwalitee::Uses::analyse = sub
{
	my ($class, $me) = @_;
	$analyse_coderef->($class, $me);
	delete($me->d->{uses}->{required_in_code}->{'String::Diff'});
	return;
};
use warnings 'redefine';

# Run extra tests.
Test::Kwalitee::Extra->import(
	qw(
		:optional
	)
);

# Clean up the additional file Test::Kwalitee::Extra generates.
END
{
	unlink 'Debian_CPANTS.txt'
		if -e 'Debian_CPANTS.txt';
}
