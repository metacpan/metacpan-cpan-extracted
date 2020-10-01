package Module::Exists;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(dummy is_dummy);

sub dummy {
    return scalar @_;
}

sub is_dummy {
    my @pair = @_;
    return if $_[0] == $_[1];
}

1;
