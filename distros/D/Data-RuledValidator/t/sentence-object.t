use Test::More;

BEGIN {
  use lib qw(t/lib/);
  use_ok('Data::RuledValidator');
}

use strict;

my $q = bless {page => 123, num_or_url => 123}, 'main';

sub p{my($self, $k, $v) = @_; return @_ == 3 ? $self->{$k} = $v : @_ == 2 ? $self->{$k} : keys %$self}

my $v = Data::RuledValidator->new(obj => $q, method => 'p');

is($q->p('page'), "123");
is($q->p('num_or_url'), "123");

ok(ref $v, 'Data::RuledValidator');

is($v->obj, $q);
is($v->method, 'p');

# correct rule
ok($v->by_sentence('page is word, num', 'num_or_url is num,url'), 'by sentence');
ok($v);

$v->reset;
$q->p(page => "abc");
$q->p(num_or_url => 'http://www.example.jp/');

ok($v->by_sentence('page is word, num', 'num_or_url is num,url'), 'by sentence');
ok($v);

$v->reset;
$q->p(page => "///");
$q->p(num_or_url => 'xxxx');

ok(! $v->by_sentence('page is word, num', 'num_or_url is num, url', 'num_or_url is word'), 'by sentence');
ok(! $v);

# use Data::Dumper;
# warn Data::Dumper::Dumper($v);

done_testing;
