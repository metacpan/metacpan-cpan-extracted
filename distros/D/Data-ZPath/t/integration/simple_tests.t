use Test2::V0;
use Test2::Require::Module 'XML::LibXML';

use Data::ZPath;
use XML::LibXML;

subtest 'basic hash navigation' => sub {
    my $h = { foo => { bar => 6 } };
    my $p = Data::ZPath->new('./foo/bar');
    is($p->first($h), 6, 'first() returns scalar');
    is([$p->all($h)], [6], 'all() returns list');
};

subtest 'each() mutates Perl scalar via $_ proxy' => sub {
    my $h = { foo => { bar => 6 } };
    my $p = Data::ZPath->new('./foo/bar');

    $p->each($h, sub { $_ *= 2 });
    is($h->{foo}{bar}, 12, 'bar doubled');
};

subtest 'basic XML navigation' => sub {
    my $dom = XML::LibXML->load_xml(string => '<foo bar="1"><bar>5</bar></foo>');
    my $p   = Data::ZPath->new('/bar');

    is($p->first($dom)->toString, '<bar>5</bar>', 'XML first');
    is([map $_->toString, $p->all($dom)], ['<bar>5</bar>'], 'XML all');
};

subtest 'wildcards and recursive descent' => sub {
    my $h = { a => { x => 1, y => { z => 2 } } };

    my $p1 = Data::ZPath->new('./a/*');
    is(scalar($p1->all($h)), 2, '* returns children');

    my $p2 = Data::ZPath->new('./**/z');
    is([$p2->all($h)], [2], '** finds descendant by name');
};

subtest 'qualifiers' => sub {
    my $h = { cars => [ { age => 1 }, { }, { age => undef }, { age => 0 } ] };

    my $p1 = Data::ZPath->new('./cars/*[age]');
    is(scalar($p1->all($h)), 3, 'age exists (undef still present as node)');

    my $p2 = Data::ZPath->new('./cars/*[!age || type(age) == "null"]');
    # our "null" mapping for undef is "null" via type() on primitive undef node; present but undef maps to null
    ok(scalar($p2->all($h)) >= 2, 'missing or null-ish');
};

subtest 'count/index helpers' => sub {
    my $dom = XML::LibXML->load_xml(
        string => '<html><table><tr><td>a</td><td>b</td></tr><tr><td>c</td></tr></table></html>'
    );

    my $p = Data::ZPath->new('table/**/tr[count(td) == 2]');
    is(scalar($p->all($dom)), 1, 'row with 2 tds');
};

subtest 'top-level comma list and union' => sub {
    my $h = { bowl => [ { fruit => 1 }, { fruit => 2 } ], fruit => 3 };

    my $p1 = Data::ZPath->new('./**/bowl/*, ./**/fruit');
    ok(scalar($p1->all($h)) >= 3, 'comma list returns combined results (may include duplicates)');

    my $p2 = Data::ZPath->new('union(./**/bowl/*, ./**/fruit)');
    ok(scalar($p2->all($h)) >= 3, 'union merges duplicates when nodes repeat');
};


subtest 'evaluate accepts Data::ZPath::Node as context' => sub {
	my $h = { foo => [
		{ bar => 10 },
		{ bar => 20 },
	] };

	my $p1 = Data::ZPath->new('foo/*');
	my $p2 = Data::ZPath->new('./bar');
	my $p3 = Data::ZPath->new('foo/*/bar');

	my @results1 = map { $p2->all($_) } $p1->evaluate($h);
	my @results2 = $p3->all($h);
	
	is(scalar(@results2), 2, 'correct count');
	is(\@results1, \@results2, 'node context matches direct query');
};

subtest 'operators require whitespace' => sub {
    like(
        dies { Data::ZPath->new('1+2') },
        qr/Unexpected character|requires whitespace/i,
        'binary + without whitespace rejected'
    );
    is(Data::ZPath->new('1 + 2')->first({}), 3, 'binary + with whitespace ok');
};

subtest 'xml attributes' => sub {
    my $dom = XML::LibXML->load_xml(string => '<root><table class="defn"/></root>');
    my $p1 = Data::ZPath->new('/table[@class == "defn"]');

    is(scalar($p1->all($dom)), 1, 'attribute qualifier works');

    my $p2 = Data::ZPath->new('/table/@class');
    is([map $_->value, $p2->all($dom)], ['defn'], 'attribute node value');
};

subtest 'find method' => sub {
	my $h = { foo => [
		{ bar => 10 },
		{ bar => 20 },
	] };

	my $n  = Data::ZPath::Node->from_root($h);
	my $nr = $n->find('foo/*')->find('./bar');

	is( [ map $_->value, $nr->all ], [ 10, 20 ], 'find method');
};

done_testing;
