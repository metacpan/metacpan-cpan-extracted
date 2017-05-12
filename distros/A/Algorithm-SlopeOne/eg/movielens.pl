#!/usr/bin/env perl
use autodie;
use open qw(:locale);
use strict;
use warnings qw(all);

# Requires files available at the
# MovieLens Data Sets: http://www.grouplens.org/node/73

use Algorithm::SlopeOne;
#use Sort::Key::Top qw(rnkeytopsort);

my $slopeone = Algorithm::SlopeOne->new;
my %names;

# ml-100k.zip
load_names(q(u.item), qr/\|/x);
load_data(q(u.data), qr/\t/x);

# ml-1m.zip
#load_names(q(movies.dat), qr/::/x);
#load_data(q(ratings.dat), qr/::/x);

my $result = $slopeone->predict({
    q|Casablanca (1942)|            => 5,
    q|Contact (1997)|               => 4,
    q|Ed Wood (1994)|               => 4,
    q|Eraser (1996)|                => 3,
    q|Independence Day (ID4) (1996)|=> 4,
    q|Lawnmower Man, The (1992)|    => 2,
    q|Liar Liar (1997)|             => 1,
    q|Pink Floyd - The Wall (1982)| => 5,
    q|Seven (Se7en) (1995)|         => 5,
    q|Star Wars (1977)|             => 5,
    q|Terminator, The (1984)|       => 5,
    q|Toy Story (1995)|             => 5,
    q|Waterworld (1995)|            => 3,
});

#my @top10 = rnkeytopsort { $result->{$_} } 10 => keys %{$result};
my @top10 = (sort
    { ($result->{$b} <=> $result->{$a}) or ($a cmp $b) }
    keys %{$result}
) [0 .. 9];

for my $key (@top10) {
    printf qq(%-50s\t%0.2f\n), $key, $result->{$key};
}

sub load_names {
    my ($file, $sep) = @_;
    open(my $fh, q(<:encoding(latin1)), $file);
    while (<$fh>) {
        chomp;
        my ($id, $name) = split $sep;
        $names{$id} = $name;
    }
    close $fh;
    return;
}

sub load_data {
    my ($file, $sep) = @_;
    my %user;
    open(my $fh, q(<), $file);
    while (<$fh>) {
        chomp;
        my ($user_id, $movie_id, $rating) = split $sep;
        my $name = $names{$movie_id};
        $user{$user_id}->{$name} = $rating;
    }
    close $fh;
    while (my (undef, $ratings) = each %user) {
        $slopeone->add($ratings);
    }
    return;
}
