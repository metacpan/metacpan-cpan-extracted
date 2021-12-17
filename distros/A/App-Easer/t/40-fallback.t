use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;
use Storable 'dclone';

my $base_app = {
   commands => {
      MAIN => {
         help        => 'example command',
         description => 'An example command',
         'default-child' => 'foo',
         children        => [qw< foo >],
         options     => [
            {
               getopt => 'bar!',
            },
         ],
      },
      foo => {
         help        => 'sub-command foo',
         description => 'first-level sub-command foo',
         supports    => ['foo'],
         children        => undef,
         options     => [],
         execute     => 'Whatever#foo',
      },
   },
};

my $app = dclone($base_app);
subtest 'foo as default' => sub {
   test_run($app, [], {}, undef)->no_exceptions
      ->stdout_like(qr{(?ms-x:\Afoo on out <>\z)});
};

subtest 'foo as default, option passed' => sub {
   test_run($app, ['--bar'], {}, undef)->no_exceptions
      ->stdout_like(qr{(?-ms:\Afoo on out <>\z)});
};

subtest 'no fallback' => sub {
   test_run($app, [qw< goo hey >], {}, undef)
      ->exception_like(qr{(?ms-x:cannot find sub-command 'goo')});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{'fallback-to'} = 'foo';
subtest 'fallback-to' => sub {
   test_run($app, [qw< goo hey >], {}, undef)->no_exceptions
      ->stdout_like(qr{(?ms-x:\Afoo on out <goo, hey>\z)});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{'fallback-to-default'} = 1;
subtest 'fallback-to-default' => sub {
   test_run($app, [qw< bar hey >], {}, undef)->no_exceptions
      ->stdout_like(qr{(?ms-x:\Afoo on out <bar, hey>\z)});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{'fallback'} = sub { 'foo' };
subtest 'fallback (returning foo)' => sub {
   test_run($app, [qw< hey you >], {}, undef)->no_exceptions
      ->stdout_like(qr{(?ms-x:\Afoo on out <hey, you>\z)});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{'fallback-to'} = 'GOO';
subtest 'fallback-to with non-existent command' => sub {
   test_run($app, [qw< goo hey >], {}, undef)
      ->exception_like(qr{(?ms-x:no definition for 'GOO')});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{'fallback-to-default'} = 1;
$app->{commands}{MAIN}{'default-child'} = 'GOO';
subtest 'fallback-to-default with non-existent command' => sub {
   test_run($app, [qw< bar hey >], {}, undef)
      ->exception_like(qr{(?ms-x:no definition for 'GOO')});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{'fallback'} = sub { 'GOO' };
subtest 'fallback (returning GOO)' => sub {
   test_run($app, [qw< hey you >], {}, undef)
      ->exception_like(qr{(?ms-x:no definition for 'GOO')});
};
done_testing();

package Whatever;

sub foo ($main, $conf, $args) {
   local $" = ', ';
   print {*STDOUT} "foo on out <$args->@*>";
   print {*STDERR} 'foo on err';
   return 'fOo';
}
