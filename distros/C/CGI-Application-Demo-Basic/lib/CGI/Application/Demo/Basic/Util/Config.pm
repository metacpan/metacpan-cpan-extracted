package CGI::Application::Demo::Basic::Util::Config;

use Config::Tiny;

use Hash::FieldHash qw(:all);

fieldhash my %config => 'config';

our $VERSION = '1.06';

# -----------------------------------------------

sub new
{
	my($class, $config_name) = @_;
	my($self) = bless({}, $class);

	my($name);

	for (keys %INC)
	{
		next if ($_ !~ m|CGI/Application/Demo/Basic/Util/Config.pm|);

		($name = $INC{$_}) =~ s|Config.pm|$config_name|;
	}

	$self -> config(Config::Tiny -> read($name) );
	$self -> config(${$self -> config}{_});

	return $self;

}	# End of new.

# --------------------------------------------------

1;
