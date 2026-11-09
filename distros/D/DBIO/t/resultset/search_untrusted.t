use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;

# search_untrusted takes a condition whose structure is not trusted: columns as
# keys, values (scalars) as operands and a fixed list of operators. It passes
# what it lets through to search unchanged.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $rs     = $schema->resultset('CD');
my $joined = $rs->search(undef, { join => 'artist' });

my $same = sub {
  my ($label, $cond, $base) = @_;
  $base ||= $rs;
  my $got = $base->search_untrusted($cond)->as_query;
  my $exp = $base->search($cond)->as_query;
  is_deeply $got, $exp, "allowed: $label";
};

my @ok = (
  'column scalar'      => { title => 'x' },
  'undef'              => { title => undef },
  'empty hash'         => {},
  'empty array'        => [],
  'value list'         => { title => [ 'a', 'b' ] },
  '='                  => { year => { '=' => 1 } },
  '!='                 => { year => { '!=' => 1 } },
  '<>'                 => { year => { '<>' => 1 } },
  '<'                  => { year => { '<' => 1 } },
  '<='                 => { year => { '<=' => 1 } },
  '>'                  => { year => { '>' => 1 } },
  '>='                 => { year => { '>=' => 1 } },
  '-like'              => { title => { -like => 'a%' } },
  '-not_like'          => { title => { -not_like => 'a%' } },
  '-in'                => { year => { -in => [ 1, 2 ] } },
  '-not_in'            => { year => { -not_in => [ 1, 2 ] } },
  '-between'           => { year => { -between => [ 1, 2 ] } },
  '-not_between'       => { year => { -not_between => [ 1, 2 ] } },
  '-is undef'          => { year => { -is => undef } },
  '-is_not undef'      => { year => { -is_not => undef } },
  'me.column'          => { 'me.title' => 'x' },
  'array of conditions'=> [ { title => 'a' }, { year => 1 } ],
  '-and array'         => { -and => [ { title => 'a' }, { year => 1 } ] },
  '-or array'          => { -or => [ { title => 'a' }, { year => 1 } ] },
  '-and hash'          => { -and => { title => 'a', year => 1 } },
  '-or hash'           => { -or => { title => 'a', year => 1 } },
  'nested'             => { -and => [ { -or => [ { title => 'a' }, [ { year => 1 } ] ] } ] },
);
while (my ($label, $cond) = splice @ok, 0, 2) {
  $same->($label, $cond);
}
$same->('alias.column of a join', { 'artist.name' => 'x' }, $joined);
$same->('me.column with a join', { 'me.title' => 'x' }, $joined);

# the result is a resultset, in every context, and search stays the entry
isa_ok scalar $rs->search_untrusted({ title => 'x' }), 'DBIO::ResultSet';
throws_ok { my @l = $rs->search_untrusted({ title => 'x' }) } qr/list context/,
  'list context throws like search';

my $cycle = {}; $cycle->{-and} = [ $cycle ];
my $cyclic_array = []; push @$cyclic_array, $cyclic_array;

my @bad = (
  '-literal'              => { -literal => 'x' },
  '-literal on a column'  => { title => { -literal => 'x' } },
  'scalar ref'            => { title => \'x' },
  'literal with binds'    => { title => \[ 'x = ?', 1 ] },
  'ref ref'               => { title => \\'x' },
  'code ref'              => { title => sub { 1 } },
  'object'                => { title => bless({}, 'Foo') },
  'object in a list'      => { title => [ 'a', bless({}, 'Foo') ] },
  '-func'                 => { -func => [ 'pg_sleep', 1 ] },
  '-func on a column'     => { title => { -func => 'x' } },
  '-op'                   => { -op => [ '=', 1, 1 ] },
  '-ident'                => { title => { -ident => 'year' } },
  '-value'                => { title => { -value => 'x' } },
  '-bool'                 => { -bool => 'x' },
  '-not'                  => { -not => { title => 'x' } },
  'unknown operator'      => { title => { '= 1 OR 1=1 OR title =' => 'x' } },
  'unlisted operator'     => { title => { -ilike => 'x' } },
  'upper case operator'   => { title => { -LIKE => 'x' } },
  'two operators'         => { year => { '<' => 5, '>' => 1 } },
  'empty operator hash'   => { year => {} },
  'unknown column'        => { nope => 'x' },
  'unknown alias'         => { 'nope.title' => 'x' },
  'column of the wrong source' => { 'artist.title' => 'x' },
  'join not in the resultset' => { 'artist.name' => 'x' },
  'key with sql'          => { 'title) OR (1=1' => 'x' },
  '-in with a scalar'     => { year => { -in => 1 } },
  '-in with a ref member' => { year => { -in => [ \'1' ] } },
  '-between one value'    => { year => { -between => [1] } },
  '-between three values' => { year => { -between => [ 1, 2, 3 ] } },
  '-between scalar'       => { year => { -between => 1 } },
  '-is a value'           => { year => { -is => 1 } },
  '-is_not a value'       => { year => { -is_not => 1 } },
  'like with an array'    => { title => { -like => [ 'a' ] } },
  '< with a hash'         => { year => { '<' => { '>' => 1 } } },
  'value hash'            => { title => { title => 'x' } },
  'array operand with hash' => { title => [ { -like => 'a' } ] },
  'scalar as a condition' => [ 'title', 'x' ],
  'scalar in -and'        => { -and => [ 'title' ] },
  '-and a scalar'         => { -and => 'x' },
  '-or a ref'             => { -or => \'x' },
  'blessed container'     => bless({ title => 'x' }, 'Foo'),
  'blessed -and'          => { -and => bless([ { title => 'x' } ], 'Foo') },
  'cycle'                 => $cycle,
  'cycle in an array'     => $cyclic_array,
  'scalar'                => 'title',
  'scalar ref condition'  => \'1=1',
  'undef'                 => undef,
);
while (my ($label, $cond) = splice @bad, 0, 2) {
  throws_ok { $rs->search_untrusted($cond) } qr/search_untrusted/,
    "refused: $label";
}

throws_ok { $rs->search_untrusted() } qr/search_untrusted/, 'no argument';
throws_ok { $rs->search_untrusted({}, { rows => 1 }) } qr/search_untrusted/,
  'attributes are no argument';
throws_ok { $rs->search_untrusted(title => 'x') } qr/search_untrusted/,
  'list form';

throws_ok { $joined->search_untrusted({ 'artist.title' => 'x' }) } qr/search_untrusted/,
  'a column of another source under the alias of a join';
throws_ok { $joined->search_untrusted({ 'me.name' => 'x' }) } qr/search_untrusted/,
  'a column of the join under the alias of the resultset';

# the path names the offending key
throws_ok { $rs->search_untrusted({ -and => [ { title => { -literal => 'x' } } ] }) }
  qr/-and.*title.*-literal/s, 'the message holds the key path';

done_testing;
