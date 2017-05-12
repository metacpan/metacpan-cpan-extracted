package DBICx::Modeler::Carp;

use strict;
use warnings;

our $TRACE = sub { print STDERR join "", @_, "\n" };

use Carp::Clan::Share;
use constant TRACE_DEFAULT => 0;
use constant TRACE => (exists $ENV{DBIC_MODELER_TRACE} ? $ENV{DBIC_MODELER_TRACE} : TRACE_DEFAULT) ? sub { $TRACE->(@_) } : sub {};

1;
