package DateTime::Event::Cron::Quartz::ValueSet;

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.05';

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/pos value/);

sub new { return bless {}, shift; }

1;
