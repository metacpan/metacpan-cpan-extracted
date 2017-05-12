#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Data::CSel qw(csel);
use Data::CSel::WrapStruct qw(wrap_struct);

my $data = [
    0,
    1,
    [2, ["two","dua"], {url=>"http://example.com/two.jpg"}, ["even","prime"]],
    3,
    [4, ["four","empat"], {}, ["even"]],
];
my $tree = wrap_struct($data);

test_csel(
    expr   => "Hash",
    opts   => {class_prefixes=>['Data::CSel::WrapStruct']},
    tree   => $tree,
    result => [{url=>"http://example.com/two.jpg"}, {}],
);

test_csel(
    expr   => "Hash[length=0]",
    opts   => {class_prefixes=>['Data::CSel::WrapStruct']},
    tree   => $tree,
    result => [{}],
);

test_csel(
    expr   => "Hash[length>0]",
    opts   => {class_prefixes=>['Data::CSel::WrapStruct']},
    tree   => $tree,
    result => [{url=>"http://example.com/two.jpg"}],
);

DONE_TESTING:
done_testing;

sub test_csel {
    my %args = @_;

    my $opts = $args{opts} // {};
    my @res_nodes = csel($opts, $args{expr}, $args{tree});
    my $res = [map {$_->value} @res_nodes];

    subtest +($args{name} // $args{expr}) => sub {
        is_deeply($res, $args{result}, "result")
            or diag explain $res;
    };
}
