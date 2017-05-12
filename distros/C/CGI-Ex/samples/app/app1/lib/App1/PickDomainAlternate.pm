package App1::PickDomainAlternate;

=head1 NAME

App1::PickDomainAlternate - pick from a list of generated alternates when pick_domain fails

=cut

use strict;
use warnings;
use base qw(App1);

sub skip { return 1 if shift->stash->{'domain_available'} }

sub hash_swap {
    my $self = shift;
    return $self->{'pda_hash_swap'} ||= do { # cache since hash_fill is using us also
        my $dom  = $self->stash->{'domain_prefix'} || die "Missing domain_prefix";

        my @domains = map {"$dom.$_"} qw(net org biz info us); # contrived availability check
        my $hash = {domains => \@domains};
    };
}

sub hash_fill {
    my $self = shift;
    my $doms = $self->hash_swap->{'domains'};
    return {
        domain => $doms->[1], # promote .org #[rand @$doms],
    };
}

sub info_complete { 0 } # step always shows when called

1;
