use Data::Selector;
use Test::More;
use Time::HiRes ();
use strict;
use warnings FATAL => 'all';

my $data_tree_gen;
$data_tree_gen = sub {
    my $depth = $_[0];
    return if $depth-- <= 0;
    my $data_tree_part = {};
    for ( 'a' .. 'h' ) {
        if ( ord($_) % 2 ) { $data_tree_part->{$_} = 's' x 10; }
        else {
            $data_tree_part->{$_} =
              [ map { $data_tree_gen->($depth); } 1 .. 3, ];
        }
    }
    return $data_tree_part;
};

my $data_tree;
{
    my $before = Time::HiRes::time;
    $data_tree = $data_tree_gen->( my $depth = 5, );
    diag( 'data tree build:  ' . ( Time::HiRes::time - $before ) );
};
my $selector_string = 'b.0..2.d.+-2.b.*.a.0,c';
my $before          = Time::HiRes::time;

Data::Selector->apply_tree(
    {
        selector_tree => Data::Selector->parse_string(
            { selector_string => $selector_string, }
        ),
        data_tree => $data_tree,
    }
);

my $elapsed_got = Time::HiRes::time - $before;
diag( 'apply_tree:  ' . ( Time::HiRes::time - $before ) );
my $elasped_expected = 0.060;
cmp_ok( $elapsed_got, '<', $elasped_expected, "fast enough" );

done_testing;
