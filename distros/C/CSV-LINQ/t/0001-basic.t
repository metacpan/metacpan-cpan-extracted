use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";

use CSV::LINQ;

my @tests = ();
my($PASS, $FAIL, $T) = (0, 0, 0);

sub ok {
    my($cond, $name) = @_;
    $T++;
    if ($cond) { $PASS++; print "ok $T - $name\n" }
    else { $FAIL++; print "not ok $T - $name\n" }
}

sub is {
    my($got, $exp, $name) = @_;
    $T++;
    if (defined $got && defined $exp && $got eq $exp) {
        $PASS++; print "ok $T - $name\n";
    }
    else {
        $FAIL++; print "not ok $T - $name\n";
        print "# got: " . (defined $got ? $got : '(undef)') . "\n";
        print "# exp: " . (defined $exp ? $exp : '(undef)') . "\n";
    }
}

# From + ToArray
push @tests, sub { my @d=({n=>'Alice'},{n=>'Bob'}); is(scalar(CSV::LINQ->From([@d])->ToArray()), 2, 'From->ToArray count') };
push @tests, sub { my @d=({n=>'Alice'},{n=>'Bob'}); my @r=CSV::LINQ->From([@d])->ToArray(); is($r[0]{n}, 'Alice', 'From->ToArray first') };

# Where coderef
push @tests, sub { my @d=map{{n=>$_}}(1..5); is(scalar(CSV::LINQ->From([@d])->Where(sub{$_[0]{n}>3})->ToArray()), 2, 'Where coderef count') };
push @tests, sub { my @d=map{{n=>$_}}(1..5); is(CSV::LINQ->From([@d])->Where(sub{$_[0]{n}>3})->First()->{n}, 4, 'Where coderef first') };

# Where DSL
push @tests, sub {
    my @d=({city=>'Tokyo',n=>1},{city=>'Osaka',n=>2},{city=>'Tokyo',n=>3});
    is(scalar(CSV::LINQ->From([@d])->Where(city=>'Tokyo')->ToArray()), 2, 'Where DSL count');
};
push @tests, sub {
    my @d=({city=>'Tokyo',n=>1},{city=>'Osaka',n=>2},{city=>'Tokyo',n=>3});
    my @r=CSV::LINQ->From([@d])->Where(city=>'Tokyo')->ToArray();
    is($r[1]{n}, 3, 'Where DSL second');
};

# Select
push @tests, sub { my @d=({n=>'Alice'},{n=>'Bob'}); my @r=CSV::LINQ->From([@d])->Select(sub{$_[0]{n}})->ToArray(); is($r[0], 'Alice', 'Select first') };
push @tests, sub { my @d=({n=>'Alice'},{n=>'Bob'}); my @r=CSV::LINQ->From([@d])->Select(sub{$_[0]{n}})->ToArray(); is($r[1], 'Bob', 'Select second') };

# OrderByNum
push @tests, sub { my @r=CSV::LINQ->From([map{{n=>$_}}(3,1,4,1,5,9,2,6)])->OrderByNum(sub{$_[0]{n}})->Select(sub{$_[0]{n}})->ToArray(); is($r[0], 1, 'OrderByNum first') };
push @tests, sub { my @r=CSV::LINQ->From([map{{n=>$_}}(3,1,4,1,5,9,2,6)])->OrderByNum(sub{$_[0]{n}})->Select(sub{$_[0]{n}})->ToArray(); is($r[-1], 9, 'OrderByNum last') };

# GroupBy
push @tests, sub {
    my @d=({cat=>'A',v=>1},{cat=>'B',v=>2},{cat=>'A',v=>3});
    is(scalar(CSV::LINQ->From([@d])->GroupBy(sub{$_[0]{cat}})->ToArray()), 2, 'GroupBy count');
};
push @tests, sub {
    my @d=({cat=>'A',v=>1},{cat=>'B',v=>2},{cat=>'A',v=>3});
    my %bk=map{$_->{Key}=>$_}CSV::LINQ->From([@d])->GroupBy(sub{$_[0]{cat}})->ToArray();
    is(scalar(@{$bk{A}{Elements}}), 2, 'GroupBy A count');
};

# Count + Sum
push @tests, sub { is(CSV::LINQ->From([map{{v=>$_}}(1..10)])->Count(), 10, 'Count') };
push @tests, sub { is(CSV::LINQ->From([map{{v=>$_}}(1..10)])->Sum(sub{$_[0]{v}}), 55, 'Sum') };

# Range
push @tests, sub { is(scalar(CSV::LINQ->Range(1,5)->ToArray()), 5, 'Range count') };
push @tests, sub { my @r=CSV::LINQ->Range(1,5)->ToArray(); is($r[0], 1, 'Range first') };
push @tests, sub { my @r=CSV::LINQ->Range(1,5)->ToArray(); is($r[4], 5, 'Range last') };

# Distinct
push @tests, sub { is(scalar(CSV::LINQ->From([1,2,2,3,3,3])->Distinct()->ToArray()), 3, 'Distinct count') };

# Skip + Take
push @tests, sub { is(scalar(CSV::LINQ->Range(1,10)->Skip(3)->Take(3)->ToArray()), 3, 'Skip+Take count') };
push @tests, sub { my @r=CSV::LINQ->Range(1,10)->Skip(3)->Take(3)->ToArray(); is($r[0], 4, 'Skip+Take first') };
push @tests, sub { my @r=CSV::LINQ->Range(1,10)->Skip(3)->Take(3)->ToArray(); is($r[2], 6, 'Skip+Take last') };

# First / Last
push @tests, sub { is(CSV::LINQ->From([map{{v=>$_}}(1..5)])->First()->{v},  1, 'First') };
push @tests, sub { is(CSV::LINQ->From([map{{v=>$_}}(1..5)])->Last()->{v},   5, 'Last') };

# Any / All
push @tests, sub { ok( CSV::LINQ->From([map{{v=>$_}}(1..5)])->Any(sub{$_[0]{v}>4}), 'Any true') };
push @tests, sub { ok( CSV::LINQ->From([map{{v=>$_}}(1..5)])->All(sub{$_[0]{v}>0}), 'All true') };
push @tests, sub { ok(!CSV::LINQ->From([map{{v=>$_}}(1..5)])->All(sub{$_[0]{v}>3}), 'All false') };

# Average
push @tests, sub { is(CSV::LINQ->From([map{{v=>$_}}(1..5)])->Average(sub{$_[0]{v}}), 3, 'Average') };

# Concat
push @tests, sub { is(scalar(CSV::LINQ->Range(1,3)->Concat(CSV::LINQ->Range(4,3))->ToArray()), 6, 'Concat count') };
push @tests, sub { my @r=CSV::LINQ->Range(1,3)->Concat(CSV::LINQ->Range(4,3))->ToArray(); is($r[3], 4, 'Concat fourth') };

# SelectMany
push @tests, sub { is(scalar(CSV::LINQ->From([[1,2],[3,4],[5]])->SelectMany(sub{$_[0]})->ToArray()), 5, 'SelectMany count') };
push @tests, sub { my @r=CSV::LINQ->From([[1,2],[3,4],[5]])->SelectMany(sub{$_[0]})->ToArray(); is($r[0], 1, 'SelectMany first') };
push @tests, sub { my @r=CSV::LINQ->From([[1,2],[3,4],[5]])->SelectMany(sub{$_[0]})->ToArray(); is($r[4], 5, 'SelectMany last') };

# _parse_csv_line
push @tests, sub { my @f=CSV::LINQ::_parse_csv_line('a,b,c',','); is(scalar(@f), 3, 'parse basic count') };
push @tests, sub { my @f=CSV::LINQ::_parse_csv_line('a,b,c',','); is($f[1], 'b', 'parse basic second') };
push @tests, sub { my @f=CSV::LINQ::_parse_csv_line('"hello,world",foo',','); is(scalar(@f), 2, 'parse quoted count') };
push @tests, sub { my @f=CSV::LINQ::_parse_csv_line('"hello,world",foo',','); is($f[0], 'hello,world', 'parse quoted field') };
push @tests, sub { my @f=CSV::LINQ::_parse_csv_line('"say ""hi""",bar',','); is($f[0], 'say "hi"', 'parse escaped quote') };

# ToDictionary
push @tests, sub {
    my @d=({k=>'a',v=>1},{k=>'b',v=>2});
    my $dict=CSV::LINQ->From([@d])->ToDictionary(sub{$_[0]{k}},sub{$_[0]{v}});
    is($dict->{a}, 1, 'ToDictionary a');
};
push @tests, sub {
    my @d=({k=>'a',v=>1},{k=>'b',v=>2});
    my $dict=CSV::LINQ->From([@d])->ToDictionary(sub{$_[0]{k}},sub{$_[0]{v}});
    is($dict->{b}, 2, 'ToDictionary b');
};

# ToLookup
push @tests, sub {
    my @d=({k=>'x',v=>1},{k=>'x',v=>2},{k=>'y',v=>3});
    my $lkp=CSV::LINQ->From([@d])->ToLookup(sub{$_[0]{k}},sub{$_[0]{v}});
    is(scalar(@{$lkp->{x}}), 2, 'ToLookup x count');
};
push @tests, sub {
    my @d=({k=>'x',v=>1},{k=>'x',v=>2},{k=>'y',v=>3});
    my $lkp=CSV::LINQ->From([@d])->ToLookup(sub{$_[0]{k}},sub{$_[0]{v}});
    is($lkp->{y}[0], 3, 'ToLookup y');
};

# Join
push @tests, sub {
    my @o=({id=>1,cid=>'A',amt=>100},{id=>2,cid=>'B',amt=>200},{id=>3,cid=>'A',amt=>150});
    my @c=({id=>'A',name=>'Alice'},{id=>'B',name=>'Bob'});
    my @r=CSV::LINQ->From([@o])->Join(CSV::LINQ->From([@c]),sub{$_[0]{cid}},sub{$_[0]{id}},sub{{name=>$_[1]{name},amt=>$_[0]{amt}}})->ToArray();
    is(scalar(@r), 3, 'Join count');
};
push @tests, sub {
    my @o=({id=>1,cid=>'A',amt=>100},{id=>2,cid=>'B',amt=>200},{id=>3,cid=>'A',amt=>150});
    my @c=({id=>'A',name=>'Alice'},{id=>'B',name=>'Bob'});
    my @r=CSV::LINQ->From([@o])->Join(CSV::LINQ->From([@c]),sub{$_[0]{cid}},sub{$_[0]{id}},sub{{name=>$_[1]{name},amt=>$_[0]{amt}}})->ToArray();
    is($r[0]{name}, 'Alice', 'Join first name');
};

# ThenByStr
push @tests, sub {
    my @d=({city=>'Tokyo',name=>'Bob'},{city=>'Tokyo',name=>'Alice'},{city=>'Osaka',name=>'Carol'});
    my @r=CSV::LINQ->From([@d])->OrderByStr(sub{$_[0]{city}})->ThenByStr(sub{$_[0]{name}})->ToArray();
    is($r[0]{city}, 'Osaka', 'ThenByStr first city');
};
push @tests, sub {
    my @d=({city=>'Tokyo',name=>'Bob'},{city=>'Tokyo',name=>'Alice'},{city=>'Osaka',name=>'Carol'});
    my @r=CSV::LINQ->From([@d])->OrderByStr(sub{$_[0]{city}})->ThenByStr(sub{$_[0]{name}})->ToArray();
    is($r[1]{name}, 'Alice', 'ThenByStr second name');
};
push @tests, sub {
    my @d=({city=>'Tokyo',name=>'Bob'},{city=>'Tokyo',name=>'Alice'},{city=>'Osaka',name=>'Carol'});
    my @r=CSV::LINQ->From([@d])->OrderByStr(sub{$_[0]{city}})->ThenByStr(sub{$_[0]{name}})->ToArray();
    is($r[2]{name}, 'Bob', 'ThenByStr third name');
};

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
exit($FAIL ? 1 : 0);
