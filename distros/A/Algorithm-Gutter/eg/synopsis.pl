use Algorithm::Gutter;
my $g = Algorithm::Gutter->new(
    gutter => [ map Algorithm::Gutter::Cell->new, 1 .. 4 ],
    rain   => sub {
        my ($gutter) = @_;
        $gutter->[ rand @$gutter ]->amount += 1 + int( rand 4 );
    },
);
$g->gutter->[1]->enabled = 1;
$g->gutter->[1]->update  = sub {
    my ( $cell, $index, $amount, $stash ) = @_;
    return [ $index, $amount ];
};
$g->gutter->[1]->threshold = 4;

for my $turn ( 1 .. 20 ) {
    $g->rain;
    my @out = $g->drain;
    if (@out) {
        warn "$turn drains $out[0][0] amount $out[0][1]\n";
    }
    $g->slosh;
}
