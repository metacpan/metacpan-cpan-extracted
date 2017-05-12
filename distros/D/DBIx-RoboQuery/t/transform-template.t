# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $qmod = 'DBIx::RoboQuery';
eval "require $qmod";

sub new_query {
  new_ok($qmod, [
    sql => 'hi',
    transformations => {
      uc => sub { uc $_[0] },
      map {
        ($_ => eval 'sub { my $h = $_[0]; $h->{'.$_.'} = [ sort '.$_.' %$h ]; $h }')
      } qw( keys values )
    },
    @_,
  ]);
}

sub do_tr {
  shift->{transformations}->call(@_)
}

my $query = new_query();

{
  my $cb = $query->template_tr_callback;
  is_deeply
    $cb->(
      {
        i => 1,
      },
      'row.i = row.i + 1; row.hi = "there"',
    ),
    {
      i => 2,
      hi => 'there',
    },
    'row updated by template callback';
}

$query->tr_fields(uc => 'name');
$query->tr_row(values => 'before');
$query->tr_row(template => 'after' => 'IF row.name.match("MAX"); row.maximum = 1; END');
$query->transform(keys => hook => 'after');

is_deeply
  do_tr($query, {
    name => 'brown bear',
  }),
  {
    name   => 'BROWN BEAR',
    values => ['brown bear'],  # before
    keys   => [qw(name values)], # after
  },
  'row transformed';

is_deeply
  do_tr($query, {
    name => 'max headroom',
  }),
  {
    name    => 'MAX HEADROOM',
    maximum => 1,
    values  => ['max headroom'], # before
    keys    => [qw(maximum name values)],  # after
  },
  'row transformed';

{
  my $q = new_query(template_tr_name => 'fooey');

  $q->tr_row(fooey => 'after', 'row.foo = "ey"');
  is_deeply
    do_tr($q, {bar => 'baz'}),
    { bar => 'baz', foo => 'ey' },
    'changed template_tr_name';
}

{
  my $q = new_query(template_tr_name => undef);

  $q->tr_row(template => 'after', 'row.foo = "ey"');
  eval { do_tr($q, {baz => 'qux'}) };
  like $@, qr/no sub defined for name: template/i, 'template func not available';
}

{
  my $q = new_query(transformations => {template => sub { uc $_[0] }});

  $q->transform(template => fields => 'duck');
  is_deeply
    do_tr($q, {duck => 'quack'}),
    { duck => 'QUACK' },
    'template func not overridden';
}

{
  my $q = new_query();

  $q->tr_row(template => after => 'row.rub = "ber"');
  is_deeply
    do_tr($q, [qw( duck rub )], ['quack', '']),
    ['quack', 'ber'],
    'template func receives hash';
}

done_testing;
