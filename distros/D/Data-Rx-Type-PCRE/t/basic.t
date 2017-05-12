use strict;
use warnings;

use Data::Rx;
use Data::Rx::Type::PCRE;
use Test::More tests => 28;

my $rx = Data::Rx->new({
  type_plugins => [ 'Data::Rx::Type::PCRE' ]
});

{
  my $rerx = $rx->make_schema({
    type  => 'tag:rjbs.manxome.org,2008-10-04:rx/pcre/str',
    regex => 'fo + bar?',
  });

  ok(  $rerx->check('fo  ba'),  'accept: fo  ba');
  ok(! $rerx->check('FO  BA'),  'reject: FO  BA');
  ok(! $rerx->check('foo bar'), 'reject: foo bar');
  ok(! $rerx->check('quux'),    'reject: quux');

  ok(! $rerx->check('foba'),    'reject: foba');
  ok(! $rerx->check('FOBA'),    'reject: FOBA');
  ok(! $rerx->check('foobar'),  'reject: foobar');
}

{
  my $rerx = $rx->make_schema({
    type  => 'tag:rjbs.manxome.org,2008-10-04:rx/pcre/str',
    regex => 'fo + bar?',
    flags => 'i',
  });

  ok(  $rerx->check('fo  ba'),  'accept: fo  ba');
  ok(  $rerx->check('FO  BA'),  'accept: FO  BA');
  ok(! $rerx->check('foo bar'), 'reject: foo bar');
  ok(! $rerx->check('quux'),    'reject: quux');

  ok(! $rerx->check('foba'),    'reject: foba');
  ok(! $rerx->check('FOBA'),    'reject: FOBA');
  ok(! $rerx->check('foobar'),  'reject: foobar');
}

{
  my $rerx = $rx->make_schema({
    type  => 'tag:rjbs.manxome.org,2008-10-04:rx/pcre/str',
    regex => 'fo + bar?',
    flags => 'x',
  });

  ok(! $rerx->check('fo  ba'),  'reject: fo  ba');
  ok(! $rerx->check('FO  BA'),  'reject: FO  BA');
  ok(! $rerx->check('foo bar'), 'reject: foo bar');
  ok(! $rerx->check('quux'),    'reject: quux');

  ok(  $rerx->check('foba'),    'accept: foba');
  ok(! $rerx->check('FOBA'),    'reject: FOBA');
  ok(  $rerx->check('foobar'),  'accept: foobar');
}

{
  my $rerx = $rx->make_schema({
    type  => 'tag:rjbs.manxome.org,2008-10-04:rx/pcre/str',
    regex => 'fo + bar?',
    flags => 'xi',
  });

  ok(! $rerx->check('fo  ba'),  'reject: fo  ba');
  ok(! $rerx->check('FO  BA'),  'reject: FO  BA');
  ok(! $rerx->check('foo bar'), 'reject: foo bar');
  ok(! $rerx->check('quux'),    'reject: quux');

  ok(  $rerx->check('foba'),    'accept: foba');
  ok(  $rerx->check('FOBA'),    'reject: FOBA');
  ok(  $rerx->check('foobar'),  'accept: foobar');
}
