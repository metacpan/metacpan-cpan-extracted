use t::boilerplate;

use Test::More;
use Capture::Tiny qw( capture );

use_ok 'Class::Usul::Lock';

my $lock = Class::Usul::Lock->new_with_options
   (  appclass => 'Class::Usul',
      config   => { logsdir => 't', tempdir => 't', },
      lock_key => 'test',
      method   => 'list',
      noask    => 1,
      quiet    => 1, );

$lock->set;

my ($stdout) = capture { $lock->list };

like $stdout, qr{ \A test, }mx, 'Sets and lists';

$lock->reset;

($stdout) = capture { $lock->list };

is length $stdout, 0, 'Resets and lists';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
