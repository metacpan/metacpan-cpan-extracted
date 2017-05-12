use Test::More tests => 12;

use strict;

use DataFlow::Proc;

# tests: 2
my $n = DataFlow::Proc->new(
    deref => 1,
    p     => sub { ucfirst },
);
ok($n);
is( ( $n->process('iop') )[0], 'Iop' );

# scalars
ok( !defined( $n->process() ) );
ok( ( $n->process('aaa') )[0] eq 'Aaa' );

# scalar refs
my $val = 'babaloo';
ok( ( $n->process( \$val ) )[0] eq 'Babaloo' );

# array refs
my @res_aref = $n->process( [qw/aa bb cc dd ee ff gg hh ii jj/] );
is( scalar @res_aref, 10, 'result has the right size' );
is( $res_aref[0],     'Aa' );
is( $res_aref[9],     'Jj' );

# hash refs
my %res_href =
  $n->process( { ii => 'jj', kk => 'll', mm => 'nn', oo => 'pp' } );
is( $res_href{'ii'}, 'Jj' );
is( $res_href{'kk'}, 'Ll' );
is( $res_href{'mm'}, 'Nn' );
is( $res_href{'oo'}, 'Pp' );

