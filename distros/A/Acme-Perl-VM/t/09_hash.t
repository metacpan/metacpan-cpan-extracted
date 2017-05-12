#!perl -w

use strict;
use Test::More tests => 24;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

sub Dump{
    require Data::Dumper;
    diag(Data::Dumper::Dumper(@_));
}

my $x = run_block{
    my %h;
};
ok !$x;

$x = run_block{
    my %h = (key => 10);
};
ok $x;

my %hash = run_block{
    my %h = (foo => 10, bar => 20);
};
is_deeply(\%hash, { foo => 10, bar => 20 }) or Dump(\%hash);

%hash = run_block{
    our %h = (foo => 10, bar => 20);
};
is_deeply(\%hash, { foo => 10, bar => 20 }) or Dump(\%hash);

%hash = run_block{
    my %h = (foo => 10, foo => 20, bar => 30);
};
is_deeply \%hash, { foo => 20, bar => 30 } or Dump($x);

%hash = run_block{
    my %h = (a => 1, foo => 10, b => 2, foo => 20, c => 3);
};
is_deeply \%hash, { a => 1, foo => 10, b => 2, foo => 20, c => 3 };

$x = run_block{
    my %h = (foo => 10, bar => 20);
    return \%h;
};
is_deeply $x, { foo => 10, bar => 20 } or Dump($x);

$x = run_block{
    my %h = (foo => 10, bar => 20);
    $h{foo} = $h{bar} + 1;
    return \%h;
};
is_deeply $x, { foo => 21, bar => 20 } or Dump($x);

$x = run_block{
    my %h = (foo => 10, bar => 20);
    return $h{foo};
};
is_deeply $x, 10;

$x = run_block{
    our %h = (foo => 10, bar => 20);
    return $h{foo};
};
is_deeply $x, 10;
$x = run_block{
    our %h = (foo => 10, bar => 20);
    return \$h{foo};
};
is_deeply $x, \10;

sub f{
    my %h;
    return \$h{foo};
}
$x = run_block(\&f);
is_deeply $x, \undef;
$$x++;
is_deeply run_block(\&f), \undef;

my %h = (foo => 10, bar => 20);
is_deeply [ run_block{        keys   %h } ], [        keys   %h ], 'keys';
is_deeply [ run_block{        values %h } ], [        values %h ], 'values';
is_deeply [ run_block{ scalar keys   %h } ], [ scalar keys   %h ];
is_deeply [ run_block{ scalar values %h } ], [ scalar values %h ];
is_deeply \%h, {foo => 10, bar => 20};

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
