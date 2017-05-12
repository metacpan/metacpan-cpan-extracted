#!perl -w

use strict;
use Test::More tests => 24;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);
use B qw(svref_2object);

our $x = 10;
sub inc_global{
    our $x;
    $x++;
    return $x;
}

sub inc_local{
    local $x;
    $x++;
    return $x;
}

is_deeply [run_block{ our $x = 10 }], [10];
is_deeply [run_block{ our @x = 20 }], [20];

is_deeply [run_block{  *STDIN }], [ *STDIN];
is_deeply [run_block{ \*STDIN }], [\*STDIN];

#is_deeply [run_block{ \&ok }];

is_deeply [inc_global()], [11];
is_deeply [inc_global()], [12];

is_deeply [inc_local()], [1];
is_deeply [inc_local()], [1];

$x = 10;
is scalar(run_block{
    local $x = 100;
    $x++;
    return $x;
}), 101;
is $x, 10;

{
    local $|;
    my $autoflush = run_block{
        local $| = 1;
        return $|;
    };
    ok $autoflush;
    ok !$|;
}
{
    local $| = 1;
    my $autoflush = run_block{
        local $| = 0;
        return $|;
    };
    ok !$autoflush;
    ok $|;
}

our @a = (1);
$x = run_block{
    local @a = (2);
    return $a[0];
};
is_deeply  $x, 2;
is_deeply \@a, [1];

our %h = (foo => 1);
$x = run_block{
    local %h = (bar => 2);
    return $h{bar};
};
is_deeply  $x, 2;
is_deeply \%h, {foo => 1};

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
