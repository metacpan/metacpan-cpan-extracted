use warnings;
use strict;


package CommitBit::Test;

=head2 NAME

CommitBit::Test

=head2 DESCRIPTION

This class defines helper functions for testing BTDT.

=cut

use base qw/Jifty::Test/;

sub test_config {
    my $class = shift;
    my ($config) = @_;

    my $hash = $class->SUPER::test_config($config);
    $hash->{application}{repository_prefix} = 'repos-test';
    return $hash;
}

use File::Path;

sub setup {
    my $class = shift;
    $class->SUPER::setup;
    rmtree ['repos-test'];
    mkpath ['repos-test'];
}

1;
