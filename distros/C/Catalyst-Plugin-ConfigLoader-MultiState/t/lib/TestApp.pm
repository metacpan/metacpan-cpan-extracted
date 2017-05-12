package TestApp;
use strict;
use warnings;
use MRO::Compat;
BEGIN {$ENV{CATALYST_HOME} = $FindBin::Bin, $FindBin::Bin}
use Catalyst qw/ConfigLoader::MultiState/;

our $VERSION = '0.01';

sub import {
    my ($class, $rewrite_cfg) = @_;
    _merge_hash($class->config, $rewrite_cfg) if $rewrite_cfg;
    $class->setup unless $class->setup_finished;
}


sub run {
    my $class = shift;
    $class->setup unless $class->setup_finished;
    $class->next::method(@_);
}

sub _merge_hash {
    my ($h1, $h2) = (shift, shift);
    while (my ($k,$v2) = each %$h2) {
        my $v1 = $h1->{$k};
        if (ref($v1) eq 'HASH' && ref($v2) eq 'HASH') { merge_hash($v1, $v2) }
        else { $h1->{$k} = $v2 }
    }
}

sub finalize_config {
    my $c = shift;
}

1;

