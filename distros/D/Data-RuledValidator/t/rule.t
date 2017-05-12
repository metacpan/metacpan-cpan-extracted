use Test::More;

BEGIN {
  use_ok('Data::RuledValidator');
}
use Data::Dumper;
use strict;
use File::Copy ();


my $q = bless {page => "a", i => "1", n => "123"}, 'main';
sub p{my($self, $k, $v) = @_; return @_ == 3 ? $self->{$k} = $v : @_ == 2 ? $self->{$k} : keys %$self}
sub fcopy{sleep 1;my($f, $t) = @_; unlink $t; File::Copy::copy($f, $t)};


fcopy("t/original.rule" => "t/validator.rule");

my $v = Data::RuledValidator->new(obj => $q, method => 'p', rule => "t/validator.rule");

ok(ref $v, 'Data::RuledValidator');

is($v->rule, "t/validator.rule");

# a
ok($v->by_rule);
ok($v);

# b
$q->p(page => "b");
ok($v->by_rule);
ok($v);

# c
$q->p(page => "c");
$q->p(mail => 'atsushi@example.com');
ok($v->by_rule);
ok($v);

# change rule
fcopy("t/original-2.rule" => "t/validator.rule");

# a
ok($v->by_rule);
ok($v);

# b
$q->p(i => '123');
$q->p(n => 'abc');
$q->p(page => "b");
ok($v->by_rule);
ok($v);

# c
$q->p(page => "c");
$q->p(mail => 'atsus/hi.@example.com');
ok($v->by_rule);
ok($v);

# change rule
fcopy("t/original.rule" => "t/validator.rule");

ok(not $v->by_rule);
ok(not $v);

done_testing;
