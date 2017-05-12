#!perl -T

use Test::More;

BEGIN {
    use_ok('Config::TT2') || print "Bail out!\n";
}

my $ctt2 = Config::TT2->new();
$ctt2->context->stash->define_vmethod( 'list', 'sum', \&sum );

my $list = [qw(1 2 3 4 5 6 7 8 9 0)];
my $cfg  = '[% all = list.sum %]';

my $stash = $ctt2->process( \$cfg, { list => $list } );

is( $stash->{all}, 45, 'define_method: sum' );

done_testing(2);

# simple list vmethod without checks
sub sum {
    my $list = shift;
    my $result;
    foreach my $item (@$list) {
        $result += $item;
    }
    return $result;
}

