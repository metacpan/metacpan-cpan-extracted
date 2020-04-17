#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Walk::More;

my $data = [0, 1, ["2.0", {"2.1.a"=>"v1", "2.1.b"=>["2.1.b.0"]}, "2.2"], 3];

subtest basics => sub {
    my @res;
    walk sub { push @res, $_ unless ref $_ }, $data;
    is_deeply(\@res, [0, 1, "2.0", "v1", "2.1.b.0", "2.2", 3]) or diag explain \@res;
};

subtest "opt:bydepth" => sub {
    my @res;

    walk { bydepth=>0, wanted=>sub { push @res, $_ } }, [0, 1];
    is_deeply(\@res, [[0,1], 0, 1]) or diag explain \@res;

    @res = ();
    walk { bydepth=>1, wanted=>sub { push @res, $_ } }, [0, 1];
    is_deeply(\@res, [0, 1, [0,1]]) or diag explain \@res;
};

subtest "var:depth" => sub {
    my @res;

    walk sub { push @res, $_ if $Data::Walk::More::depth==3 }, $data;
    is_deeply(\@res, ['v1', ['2.1.b.0']]) or diag explain \@res;
};

subtest "var:container & index" => sub {
    my @res;

    walk sub { push @res, $Data::Walk::More::index, $Data::Walk::More::container if $Data::Walk::More::depth==4 }, $data;
    is_deeply(\@res, [0, ["2.1.b.0"]]) or diag explain \@res;
};

subtest "var:containers & indexes" => sub {
    my @res;

    walk sub { push @res, \@Data::Walk::More::indexes, \@Data::Walk::More::containers if $Data::Walk::More::depth==4 }, $data;
    is_deeply($res[0], [2,1,'2.1.b',0]) or diag explain $res[0];
    is_deeply($res[1][0], $data) or diag explain $res[1][0];
    is_deeply($res[1][1], $data->[2]) or diag explain $res[1][1];
    is_deeply($res[1][2], $data->[2][1]) or diag explain $res[1][2];
    is_deeply($res[1][3], $data->[2][1]{'2.1.b'}) or diag explain $res[1][3];
};

# XXX test var:prune

# XXX test opt:follow=1
# XXX test opt:sortkeys=0
# XXX test opt:recurseobjects

DONE_TESTING:
done_testing;
