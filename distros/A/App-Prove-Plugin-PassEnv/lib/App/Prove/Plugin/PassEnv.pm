package App::Prove::Plugin::PassEnv;
our $VERSION = '0.002';

# ABSTRACT: a prove plugin to pass environment variables

use strict;
use warnings;

sub load {
    foreach my $key (keys %ENV) {
        if ($key =~ /^PROVE_PASS_(.+)$/) {
            $ENV{$1} = $ENV{$key};

        }
    }
}
1;