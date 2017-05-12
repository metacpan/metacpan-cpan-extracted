
use Test::More tests => 24;

use List::MoreUtils qw/any/;

BEGIN {
    use_ok('DataFlow::Proc::DPath');
}

my $fail = eval q{DataFlow::Proc::DPath->new};
ok($@);

my $ok = DataFlow::Proc::DPath->new( search_dpath => '//*[2]' );
ok($ok);

@res = $ok->process( [ 0, 10, 20, 30, 40 ] );
is( scalar @res, 1 );
is( $res[0],     20 );

@res = $ok->process( [ 0, 10, 20, 30, [ 40, 41, 42 ] ] );
is( scalar @res, 2 );
is( scalar( grep { $_ == 20 } @res ), 1 );
is( scalar( grep { $_ == 42 } @res ), 1 );

my $data = {
    aList => [qw/aa bb cc dd ee ff gg hh ii jj/],
    aHash => {
        apple  => 'pie',
        banana => 'split',
        potato => [qw(baked chips fries fish&chips mashed)],
    },
};

sub pick {
    my $dpath = $_[0];
    return DataFlow::Proc::DPath->new( search_dpath => $dpath )->process($data);
}

is_deeply( pick('/aList'), [qw/aa bb cc dd ee ff gg hh ii jj/], 'list' );
is_deeply( pick('/aList/*[2]'), 'cc', 'list element' );

@res = pick('//*[3]');
is( scalar @res, 2 );
ok( any { $_ eq 'dd' } @res );
ok( any { $_ eq 'fish&chips' } @res );

is_deeply(
    pick('/aHash'),
    {
        apple  => 'pie',
        banana => 'split',
        potato => [ qw(baked chips fries), 'fish&chips', 'mashed' ],
    },
    'hash'
);

@res = pick('//*[ value =~ /i/ ]');
is( scalar @res, 6 );
ok( any { $_ eq 'split' } @res );
ok( any { $_ eq 'pie' } @res );
ok( any { $_ eq 'ii' } @res );
ok( any { $_ eq 'chips' } @res );
ok( any { $_ eq 'fries' } @res );
ok( any { $_ eq 'fish&chips' } @res );

@res = pick('//*[ value =~ /f/ ]');
ok( any { $_ eq 'ff' } @res );
ok( any { $_ eq 'fries' } @res );
ok( any { $_ eq 'fish&chips' } @res );
