use Test::More tests => 1;

sub foo {

}

my @results;

sub dothis {
    my $op = $_[0];
    push @results, $op->name;
}

sub test {
    use B::OPCheck entersub => check => \&dothis;
    foo(1,2);
    printf "foo";
    foo("dancing");
    no B::OPCheck;
    foo(2,3);
}

is_deeply(\@results, [('entersub') x 2]);
