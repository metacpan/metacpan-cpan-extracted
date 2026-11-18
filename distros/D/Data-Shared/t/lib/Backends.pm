package Backends;
use strict;
use warnings;
use Exporter 'import';
use Data::Shared ();

our @EXPORT_OK = qw(have);

# A backend older than the registry's minimum is as unusable as a missing one.
sub have {
    for my $spec (@_) {
        my $resolved = Data::Shared::Registry::resolve_spec($spec) or return 0;
        eval { Data::Shared::Storage::_load($resolved); 1 } or return 0;
    }
    return 1;
}

1;
