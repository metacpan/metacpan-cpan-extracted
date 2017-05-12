use Test::More;

use lib qw(./t/lib);
use Data::RuledValidator (plugin =>[qw/URL/], filter => [qw/X X2/]);
use Data::Dumper;
use strict;
use File::Copy ();

sub init{
  my $q = shift;
  %$q = (page => "a", i => " 1 ", n => " 123 ");
  bless $q, 'main';
}

my $q = {};
init($q);
sub p{my($self, $k, $v) = @_; return @_ == 3 ? $self->{$k} = $v : @_ == 2 ? $self->{$k} : keys %$self}

my $v = Data::RuledValidator->new
  (
   obj    => $q             ,
   method => 'p'            ,
   rule   => "t/filter.rule",
   filter_replace => 1      ,
  );

ok(ref $v, 'Data::RuledValidator');
is($v->rule, "t/filter.rule");

# a
init($q);
is($q->p('i'), ' 1 ', "a-i");
is($q->p('n'), ' 123 ', "a-n");
is($q->p('page'), 'a');
ok($v->by_rule);
ok($v);
is($q->p('i'), '1', "a-i");
is($q->p('n'), '123', "a-n");


# b
init($q);
is($q->p('i'), ' 1 ', "b-i");
is($q->p('n'), ' 123 ', "b-n");
$q->p(page => "b");
is($q->p('page'), 'b');
is($v->by_rule->valid, '');
is($v->valid, '');
is($q->p('i'), 'x', "b-i");
is($q->p('n'), 'xxx', "b-n");


# c
init($q);
is($q->p('i'), ' 1 ', "c-i");
is($q->p('n'), ' 123 ', "c-n");
$q->p(page => "c");
is($q->p('page'), 'c');
is($v->by_rule->valid, '');
is($v->valid, '');
is($q->p('i'), 'xx', "c-i");
is($q->p('n'), 'xxxxxx', "c-n");


# d
init($q);
is($q->p('i'), ' 1 ', "d-i");
is($q->p('n'), ' 123 ', "d-n");
$q->p(page => "d");
is($q->p('page'), 'd');
is($v->by_rule->valid, '');
is($v->valid, '');
is($q->p('i'), 'xxxxxx', "d-i");
is($q->p('n'), 'xxxxxxxxxx', "d-n");

# e
init($q);
is($q->p('i'), ' 1 ', "e-i");
is($q->p('n'), ' 123 ', "e-n");
$q->p(page => "e");
$q->p(default => " xyz ");
is($q->p('default'), " xyz ");
is($q->p('page'), 'e');
ok($v->by_rule);
ok($v);
is($q->p('i'), 'xxxxxx', "e-i");
is($q->p('n'), 'xxxxxxxxxx', "e-n");
is($q->p('page'), 'e', "e-page");
is($q->p('default'), 'xyz');

done_testing;
