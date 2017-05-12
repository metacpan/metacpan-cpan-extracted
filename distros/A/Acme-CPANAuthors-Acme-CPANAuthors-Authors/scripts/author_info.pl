#!perl -I../lib
use strict;
use Acme::CPANAuthors;
die "usage: $0 PAUSE_ID [PAUSE_ID ...]\n" unless @ARGV;
my $authors
    = Acme::CPANAuthors->new("Acme::CPANAuthors::Acme::CPANAuthors::Authors");
for my $id (@ARGV) {
    $id = uc $id;
    my $name     = $authors->name($id) || $id;
    my @dists    = $authors->distributions($id);
    my $kwalitee = $authors->kwalitee($id);
    print "$name has published ", ~~ @dists, " distributions:\n";
    @dists = sort { lc($a->dist) cmp lc($b->dist) } @dists;
    for my $dist (@dists) {
        printf " - %s v%s, kwalitee %s\n",
            $dist->dist, $dist->version,
            $kwalitee->{distributions}{$dist->dist}{kwalitee},
            ;
    }
    print $/ if @ARGV > 1;
}

# Stolen from Acme::CPANAuthors::French
