use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;

use AE;
my $cv;


plan 'no_plan';


my ($d, $p);
my (@result, %result);
my ($t, $tx);


# do (batch mode)
# - support ARRAY/HASH tasks:
#   * empty task list
#   * single task
#   * many tasks

$d = Async::Defer->new();
$d->do(sub{
    my ($d) = @_;
    $d->done(10,20);
});
lives_ok { $d->do([]) } 'empty (ARRAY)';
$d->do(sub{
    my ($d, @res) = @_;
    push @result, \@res;
    $d->done();
});
@result = (); $d->run();
is_deeply \@result, [[]], '… no results';

$d = Async::Defer->new();
$d->do(sub{
    my ($d) = @_;
    $d->done(10,20);
});
lives_ok { $d->do({}) } 'empty (HASH)';
$d->do(sub{
    my ($d, @res) = @_;
    push @result, \@res;
    $d->done();
});
@result = (); $d->run();
is_deeply \@result, [[]], '… no results';

$d = Async::Defer->new();
$d->do([ sub{
    my ($d_1, @param) = @_;
    push @result, \@param;
} ]);
@result = (); $d->run();
is_deeply \@result, [[]], 'single task (ARRAY)';

$d = Async::Defer->new();
$d->do({ a => sub{
    my ($d_a, @param) = @_;
    push @result, \@param;
} });
@result = (); $d->run();
is_deeply \@result, [[]], 'single task (HASH)';

$d = Async::Defer->new();
$d->do([ sub{
    my ($d_1, @param) = @_;
    push @result, \@param;
}, sub {
    my ($d_2, @param) = @_;
    push @result, \@param;
} ]);
@result = (); $d->run();
is_deeply \@result, [[],[]], 'many tasks (ARRAY)';

$d = Async::Defer->new();
$d->do({ a => sub{
    my ($d_a, @param) = @_;
    push @result, 'a', \@param;
}, b => sub {
    my ($d_b, @param) = @_;
    push @result, 'b', \@param;
} });
@result = (); $d->run();
is_deeply \@result, ['a',[],'b',[]], 'many tasks (HASH)';

# - task got params:
#   * without params
#   * with params
#   * some tasks with params, some without, and some extra params

$d = Async::Defer->new();
$d->do(sub{ shift->done() });
$d->do([ sub{
    my ($d_1, @param) = @_;
    push @result, \@param;
}, sub {
    my ($d_2, @param) = @_;
    push @result, \@param;
} ]);
@result = (); $d->run();
is_deeply \@result, [[],[]], 'without params (ARRAY)';

$d = Async::Defer->new();
$d->do(sub{ shift->done() });
$d->do({ a => sub{
    my ($d_a, @param) = @_;
    push @result, 'a', \@param;
}, b => sub {
    my ($d_b, @param) = @_;
    push @result, 'b', \@param;
} });
@result = (); $d->run();
is_deeply \@result, ['a',[],'b',[]], 'without params (HASH)';

$d = Async::Defer->new();
$d->do(sub{ shift->done( ['first'], [{second=>2}] ) });
$d->do([ sub{
    my ($d_1, @param) = @_;
    push @result, \@param;
}, sub {
    my ($d_2, @param) = @_;
    push @result, \@param;
} ]);
@result = (); $d->run();
is_deeply \@result, [['first'], [{second=>2}]], 'with params (ARRAY)';

$d = Async::Defer->new();
$d->do(sub{ shift->done( a=>['first'], b=>[{second=>2}] ) });
$d->do({ a => sub{
    my ($d_a, @param) = @_;
    push @result, 'a', \@param;
}, b => sub {
    my ($d_b, @param) = @_;
    push @result, 'b', \@param;
} });
@result = (); $d->run();
is_deeply \@result, ['a',['first'],'b',[{second=>2}]], 'with params (HASH)';

$d = Async::Defer->new();
$d->do(sub{ shift->done( undef, [{second=>2}] ) });
$d->do([ sub{
    my ($d_1, @param) = @_;
    push @result, \@param;
}, sub {
    my ($d_2, @param) = @_;
    push @result, \@param;
}, sub {
    my ($d_3, @param) = @_;
    push @result, \@param;
} ]);
@result = (); $d->run();
is_deeply \@result, [[], [{second=>2}], []], 'with&without params (ARRAY)';

$d = Async::Defer->new();
$d->do(sub{ shift->done( b=>[{second=>2}] ) });
$d->do({ a => sub{
    my ($d_a, @param) = @_;
    push @result, 'a', \@param;
}, b => sub {
    my ($d_b, @param) = @_;
    push @result, 'b', \@param;
}, c => sub {
    my ($d_c, @param) = @_;
    push @result, 'c', \@param;
} });
@result = (); $d->run();
is_deeply \@result, ['a',[],'b',[{second=>2}],'c',[]], 'with&without params (HASH)';

$d = Async::Defer->new();
$d->do(sub{ shift->done( ['first'], [{second=>2}], [['third']] ) });
$d->do([ sub{
    my ($d_1, @param) = @_;
    push @result, \@param;
}, sub {
    my ($d_2, @param) = @_;
    push @result, \@param;
} ]);
@result = (); $d->run();
is_deeply \@result, [['first'], [{second=>2}]], 'extra params (ARRAY)';

$d = Async::Defer->new();
$d->do(sub{ shift->done( a=>['first'], b=>[{second=>2}], c=>[['third']] ) });
$d->do({ a => sub{
    my ($d_a, @param) = @_;
    push @result, 'a', \@param;
}, b => sub {
    my ($d_b, @param) = @_;
    push @result, 'b', \@param;
} });
@result = (); $d->run();
is_deeply \@result, ['a',['first'],'b',[{second=>2}]], 'extra params (HASH)';

# - task return results:
#   * no result
#   * some result
#   * throw error

$d = Async::Defer->new();
$d->do([ sub{
    my ($d_1) = @_;
    $d_1->done(10,11,12);
}, sub {
    my ($d_2) = @_;
    $d_2->throw('error');
}, sub {
    my ($d_3) = @_;
    $d_3->done();
} ]);
$d->do(sub{
    my ($d, @results) = @_;
    @result = @results;
    $d->done();
});
@result = (); $d->run();
is_deeply \@result, [[10,11,12],'error',[]], 'results (ARRAY)';

$d = Async::Defer->new();
$d->do({ a => sub{
    my ($d_a) = @_;
    $d_a->done(10,11,12);
}, b => sub {
    my ($d_b) = @_;
    $d_b->throw('error');
}, c => sub {
    my ($d_c) = @_;
    $d_c->done();
} });
$d->do(sub{
    my ($d, @results) = @_;
    %result = @results;
    $d->done();
});
%result = (); $d->run();
is_deeply \%result, {a=>[10,11,12],b=>'error',c=>[]}, 'results (HASH)';

# - some tasks are CODE, some Defer objects
#   * they all doesn't share state (except ref-vars in same Defer clones)

my %seen;

$d = Async::Defer->new();
$d->do(sub{
    my ($d, @param) = @_;
    $param[0]++;
    $d->{t} = AE::timer 0.01, 0, sub { $d->done(@param) };
});
$d->do(sub{
    my ($d, @param) = @_;
    $seen{$d} = 1;
    push @result, {
        type => 'Defer',
        param=> \@param,
        state=> $d->{state}++,
        share=> ${$d->{share}}++,
    };
    $d->done(@param);
});
$d->{state} = 5;
$d->{share} = \do{my $tmp = 1};

sub code {
    my ($d, @param) = @_;
    $seen{$d} = 1;
    push @result, {
        type => 'sub',
        param=> \@param,
        state=> $d->{state}++,
        share=> ${$d->{share}}++,
    };
    $d->done(@param);
}

$p = Async::Defer->new();
$p->do([ \&code, \&code, $d, $d, sub{
    my ($d, @param) = @_;
    $seen{$d} = 1;
    push @result, {
        type => 'anon',
        param=> \@param,
        state=> $d->{state}++,
        share=> ${$d->{share}}++,
    };
    $d->done(@param);
} ]);
$p->do(sub{
    my ($p, @results) = @_;
    push @result, @results;
    $p->done();
});
(%seen, @result) = ();
$t = AE::timer 0.01, 0, sub{ $p->run(undef, [10], [20], [30], [40], [50]) };
$tx= AE::timer 0.5,  0, sub{ $cv->send };
$cv = AE::cv; $cv->recv;
is scalar(keys %seen), 5, 'all batch objects are different (ARRAY)';
is_deeply \@result, [
    { type=>'sub',      state=>0,   share=>0,   param=>[10] },
    { type=>'sub',      state=>0,   share=>0,   param=>[20] },
    { type=>'anon',     state=>0,   share=>0,   param=>[50] },
    { type=>'Defer',    state=>5,   share=>1,   param=>[31] },
    { type=>'Defer',    state=>5,   share=>2,   param=>[41] },
    [10], [20], [31], [41], [50],
    ], 'they all does not share state (ARRAY)';

$p = Async::Defer->new();
$p->do({ sub1=>\&code, sub2=>\&code, defer1=>$d, defer2=>$d, anon=>sub{
    my ($d, @param) = @_;
    $seen{$d} = 1;
    push @result, {
        type => 'anon',
        param=> \@param,
        state=> $d->{state}++,
        share=> ${$d->{share}}++,
    };
    $d->done(@param);
} });
$p->do(sub{
    my ($p, @results) = @_;
    %result = @results;
    $p->done();
});
(%seen, @result, %result) = ();
$t = AE::timer 0.01, 0, sub{ $p->run(undef, sub1=>[10], sub2=>[20], defer1=>[30], defer2=>[40], anon=>[50]) };
$tx= AE::timer 0.5,  0, sub{ $cv->send };
$cv = AE::cv; $cv->recv;
is scalar(keys %seen), 5, 'all batch objects are different (HASH)';
@result = sort { $a->{param}[0] <=> $b->{param}[0] } @result;
is_deeply \@result, [
    { type=>'sub',      state=>0,   share=>0,   param=>[10] },
    { type=>'sub',      state=>0,   share=>0,   param=>[20] },
    { type=>'Defer',    state=>5,   share=>3,   param=>[31] },
    { type=>'Defer',    state=>5,   share=>4,   param=>[41] },
    { type=>'anon',     state=>0,   share=>0,   param=>[50] },
    ], 'they all does not share state (HASH)';
is_deeply \%result, {sub1=>[10], sub2=>[20], defer1=>[31], defer2=>[41], anon=>[50]},
    '… results (HASH)';

