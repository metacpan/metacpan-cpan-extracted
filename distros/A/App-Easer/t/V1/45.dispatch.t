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
      bar => {
         help        => 'sub-command bar',
         description => 'first-level sub-command bar',
         supports    => ['bar'],
         children        => undef,
         options     => [],
         execute     => 'Whatever#bar',
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

$app = dclone($base_app);
$app->{commands}{MAIN}{dispatch} = sub { 'bar' };
subtest 'dispatch to existing sub-command' => sub {
   test_run($app, [qw< goo hey >], {}, undef)->no_exceptions
      ->stdout_like(qr{(?ms-x:\Abar on out <goo, hey>\z)});
};

$app = dclone($base_app);
$app->{commands}{MAIN}{dispatch} = sub { 'BAR' };
subtest 'dispatch to non-existing sub-command BAR' => sub {
   test_run($app, [qw< goo hey >], {}, undef)
      ->exception_like(qr{(?ms-x:no definition for 'BAR')});
};

done_testing();

package Whatever;

sub foo ($main, $conf, $args) {
   local $" = ', ';
   print {*STDOUT} "foo on out <$args->@*>";
   print {*STDERR} 'foo on err';
   return 'fOo';
}

sub bar ($main, $conf, $args) {
   local $" = ', ';
   print {*STDOUT} "bar on out <$args->@*>";
   print {*STDERR} 'bar on err';
   return 'fOo';
}
