package My::DBI;
use strict;

use base qw( Class::DBI );
use vars qw( $VERSION );
$VERSION = '0.04';

# The Factory drops a _factory() method into each data class. Here we 
# rename it to factory() for simplicity on templates, since we know there
# are no data classes with a 'factory' column.

sub factory { return shift->_factory(@_); }

# these shortcuts provide data classes with quick access to the factory's 
# configuration and template objects.

sub config { return shift->_factory->config(@_) }
sub tt { return shift->_factory->tt(@_) }

# these are useful sometimes, and are included here so that they can be 
# omitted from data classes without causing any trouble.

sub class_title { '...' }
sub class_plural { '...' }
sub class_description { '...' }
sub is_ghost { 0 }

1;

