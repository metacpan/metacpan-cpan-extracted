package Config::Plugin::Tiny::Test;

use strict;
use warnings;

use Config::Plugin::Tiny;

use File::Spec;

our $VERSION = '1.01';

# ------------------------------------------------

sub marine
{
	my($self) = @_;

	return $self -> config_tiny(File::Spec -> catfile('t', 'config.tiny.ini') );

} # End of marine.

# ------------------------------------------------

sub new
{
	my($class) = @_;

	return bless {}, $class;

} # End of new.

# --------------------------------------------------

1;
