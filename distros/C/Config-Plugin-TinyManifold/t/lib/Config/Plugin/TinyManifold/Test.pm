package Config::Plugin::TinyManifold::Test;

use strict;
use warnings;

use Config::Plugin::TinyManifold;

our $VERSION = '1.02';

# ------------------------------------------------

sub marine
{
	my($self) = @_;

	return $self -> config_manifold('t/config.tiny.manifold.ini');

} # End of marine.

# ------------------------------------------------

sub new
{
	my($class) = @_;

	return bless {}, $class;

} # End of new.

# --------------------------------------------------

1;
