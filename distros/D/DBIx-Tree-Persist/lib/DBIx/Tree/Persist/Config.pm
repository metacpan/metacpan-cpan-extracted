package DBIx::Tree::Persist::Config;

use strict;
use warnings;

use Config::Tiny;

use Hash::FieldHash ':all';

fieldhash my %config           => 'config';
fieldhash my %config_file_path => 'config_file_path';
fieldhash my %section          => 'section';
fieldhash my %verbose          => 'verbose';

our $VERSION = '1.04';

# -----------------------------------------------

sub init
{
	my($self, $path) = @_;

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );
	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of init.

# -----------------------------------------------

sub new
{
	my($class, %arg)   = @_;
	$arg{verbose}      ||= 0;
	my($self)          = from_hash(bless({}, $class), \%arg);
	my($name)          = '.htdbix.tree.persist.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|DBIx/Tree/Persist/Config.pm|);

		($path = $INC{$_}) =~ s|Config.pm|$name|;
	}

	$self -> init($path);

	return $self;

}	# End of new.

# --------------------------------------------------

1;
