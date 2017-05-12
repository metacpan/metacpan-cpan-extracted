
use Chart::Strip;
my $n = 1;

print "1..5\n";

my $c = Chart::Strip->new();

my $data;
for(my $t=10; $t<210; $t++){
    my $v = ($t % 20) ? .25 : 1;
    push @$data, {
        time  => $^T + $t  * 5000,
        value => $v + $t / 100 - 1.5,
    };
}

$c->add_data( $data, {style => 'line', color => 'FF0000'} );

my $p = $c->png();

t( $p );
t( $c->{margin_bottom} == 20 );
t( $c->{margin_left} == 34 );
t( $c->{yd_max} == 1.5 );
t( $c->{yd_min} == -1.15 );

sub t {
    my $x = shift;

    print "not " unless $x;
    print "ok $n\n";
    $n ++;
}

