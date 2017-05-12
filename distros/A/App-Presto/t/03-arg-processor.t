use strict;
use warnings;
use Test::More;

use App::Presto::ArgProcessor;
use App::Presto::Stash;
use Test::MockObject;
use HTTP::Headers;

my $client = Test::MockObject->new;
my $response_data = {};
my $headers = HTTP::Headers->new;
my $response = Test::MockObject->new;
$response->mock( header => sub { shift; $headers->header(@_) } );
$client->mock( response_data => sub { $response_data });
$client->set_always( response => $response );

my $p = App::Presto::ArgProcessor->new(client => $client, _stash => my $stash = App::Presto::Stash->new);
isa_ok $p, 'App::Presto::ArgProcessor';

is_deeply $p->process(['foo']), ['foo'], 'simple arg';
is_deeply $p->process(['foo','bar']), ['foo','bar'], 'simple args (two)';

$stash->set(TWO => 2);
is_deeply $p->process([1,'$(STASH[TWO])',3]), [1,2,3], 'full-stash subst (flat)';

$stash->set(TUPLE => [2,3]);
is_deeply $p->process([1,'$(STASH[TUPLE])',4]), [1,[2,3],4], 'full-stash subst (nested)';

is_deeply $p->process([1,'this-$(STASH[TUPLE])-that',4]), [1,'this-2,3-that',4], 'full-stash subst (nested interpolation)';

is_deeply $p->process([1,'this-$(STASH[TUPLE]/*[0])-that',4]), [1,'this-2-that',4], 'full-stash subst (array dpath interpolation)';

$stash->set(hash => {a=>1,b=>2,c=>3,d=>4});
is_deeply $p->process([1,'this-$(STASH[hash]/c)-that',4]), [1,'this-3-that',4], 'full-stash subst (hash dpath interpolation)';

is_deeply $p->process([1,'$(STASH[hash]/)',4]), [1,{a=>1,b=>2,c=>3,d=>4},4], 'full-stash subst (empty dpath)';

$headers->header('foo', 2);
is_deeply $p->process([1,'$(HEADER[foo])',3]), [1,2,3], 'header substitution';
$response_data = { data => { foo => 2, bar => 3}, blah => {foo => 4}, foo => 5 };

is_deeply $p->process([1,'$(HEADER)',3]), [1,'$(HEADER)',3], 'invalid header substitution';

is_deeply $p->process([1,'$(BODY)',3]), [1,$response_data,3], 'response substitution';
{
	my $processed = $p->process([1,'$(BODY//foo)',3]);
	is $processed->[0], 1, 'complex 1';
	is_deeply [sort { $a <=> $b} @{$processed->[1]}], [2,4,5], 'complex 2';
	is $processed->[2], 3, 'complex 3';
}
is_deeply $p->process([1,'$(BODY/)',3]), [1,$response_data,3], 'complex response data substitution';
is_deeply $p->process([1,2,'interp-$(BODY//bar)']), [1,2,'interp-3'], 'response data interpolated substitution';

done_testing;
