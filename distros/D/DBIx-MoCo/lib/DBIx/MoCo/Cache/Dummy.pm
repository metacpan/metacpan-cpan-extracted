package DBIx::MoCo::Cache::Dummy;
use strict;
use warnings;
use base qw/Class::Singleton/;

sub new { die "use instance() instead" }
sub set {}
sub get {}
sub clear {}
sub remove {}
sub cache_expire {}

1;
