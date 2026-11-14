use strict;
use warnings;
use Test::More;

use Scalar::Util qw(refaddr reftype);
use Storable ();

# The Conformance case lists hold qr// objects. A Storable older than 3.08
# (Perl before 5.28) cannot store REGEXP items, so the lists must be copied
# without Storable::dclone. Here Storable::dclone is made to die on a Regexp
# exactly as the old one does, and every list must still come out.

use DBIO::Util ();
use DBIO::Test::Conformance::Cases::DDL;
use DBIO::Test::Conformance::Cases::Diff;
use DBIO::Test::Conformance::Cases::Names;
use DBIO::Test::Conformance::Cases::Bind;

my $real_dclone = \&Storable::dclone;

sub holds_regexp {
  my ($x, $seen) = @_;
  $seen ||= {};
  return 0 unless ref $x;
  return 0 if $seen->{ refaddr $x }++;
  my $t = reftype $x;
  return 1 if $t eq 'REGEXP';
  return scalar grep { holds_regexp($_, $seen) } @$x if $t eq 'ARRAY';
  return scalar grep { holds_regexp($_, $seen) } values %$x if $t eq 'HASH';
  return holds_regexp($$x, $seen) if $t eq 'REF' || $t eq 'SCALAR';
  return 0;
}

{
  no warnings 'redefine';
  local *Storable::dclone = sub {
    die "Can't store REGEXP items at fake-old-storable\n" if holds_regexp($_[0]);
    goto &$real_dclone;
  };

  for my $module (qw(DDL Diff Names Bind)) {
    my $class = "DBIO::Test::Conformance::Cases::$module";
    my $cases = eval { $class->cases };
    is $@, '', "$module->cases copies with a Storable that cannot store a Regexp";
    ok ref $cases eq 'ARRAY' && @$cases, "$module->cases returns its cases";
  }
}

# The copy helper itself.
my $re = qr/boom/i;
my $code = sub { 42 };
my $orig = { list => [ 1, { a => 'x' } ], re => $re, code => $code, sref => \ 'text', n => undef };
my $copy = DBIO::Util::deep_copy($orig);

is_deeply [ sort keys %$copy ], [ sort keys %$orig ], 'same keys';
isnt refaddr $copy,       refaddr $orig,       'hash is copied';
isnt refaddr $copy->{list}, refaddr $orig->{list}, 'array is copied deeply';
isnt refaddr $copy->{list}[1], refaddr $orig->{list}[1], 'nested hash is copied deeply';
is refaddr $copy->{re},   refaddr $re,   'a Regexp is shared, not cloned';
is refaddr $copy->{code}, refaddr $code, 'a code ref is shared';
is ${ $copy->{sref} }, 'text', 'a scalar ref is followed';
ok exists $copy->{n} && !defined $copy->{n}, 'undef stays undef';

$copy->{list}[1]{a} = 'changed';
push @{ $copy->{list} }, 3;
is $orig->{list}[1]{a}, 'x', 'changing the copy leaves the original untouched';
is scalar @{ $orig->{list} }, 2, 'the original list keeps its length';

my $obj = bless { v => [1] }, 'Some::Class';
my $obj_copy = DBIO::Util::deep_copy($obj);
is ref $obj_copy, 'Some::Class', 'a blessed hash keeps its class';
isnt refaddr $obj_copy->{v}, refaddr $obj->{v}, 'and its content is copied';

my $cycle = { name => 'c' };
$cycle->{self} = $cycle;
my $cycle_copy = DBIO::Util::deep_copy($cycle);
is refaddr $cycle_copy->{self}, refaddr $cycle_copy, 'a cycle stays a cycle in the copy';
isnt refaddr $cycle_copy, refaddr $cycle, 'and is not the original';

done_testing;
