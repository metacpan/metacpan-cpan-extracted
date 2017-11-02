package App::Office::CMS::Util::Config;

use strict;
use warnings;

use Config::Tiny;

use Moo;

use Types::Standard qw/Any/;

has config =>
(
	is  => 'rw',
	isa => Any,
);

has config_file_path =>
(
	is  => 'rw',
	isa => Any,
);

has section =>
(
	is  => 'rw',
	isa => Any,
);

our $VERSION = '0.93';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($name) = '.htoffice.cms.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|App/Office/CMS/Util/Config.pm|);

		($path = $INC{$_}) =~ s|Util/Config.pm|$name|;
	}

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );
	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{host});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of BEGIN.

# --------------------------------------------------

1;
