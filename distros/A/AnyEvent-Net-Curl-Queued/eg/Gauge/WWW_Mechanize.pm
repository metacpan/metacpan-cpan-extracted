package Gauge::WWW_Mechanize;
use strict;
use utf8;
use warnings qw(all);

use Any::Moose;
with qw(Gauge::Role);

use WWW::Mechanize;

sub run {
    my ($self) = @_;

    # Disable compression
    $WWW::Mechanize::HAS_ZLIB = 0;

    my $mech = WWW::Mechanize->new(stack_depth => 0);
    $self->run_forked(sub {
        $mech->get(shift);
    });

    return;
}

1;
