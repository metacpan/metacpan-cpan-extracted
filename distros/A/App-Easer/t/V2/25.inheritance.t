use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $child = {
   name        => 'foo',
   help        => 'foo sub-command',
   description => 'The foo sub-command',
   execute     => \&one_execute_is_enough,
};

my $app = {
   name        => 'MAIN',
   help        => 'example command',
   description => 'An example command',
   execute     => \&one_execute_is_enough,
   children    => [ $child ],
   options     => [
      { getopt => 'parent-only', transmit => 0,                      default => 'foo' },
      { getopt => 'inh_loose',   transmit => 1, transmit_exact => 0, default => 'bar' },
      { getopt => 'inh_strict',  transmit => 1, transmit_exact => 1, default => 'baz' },
   ],
};

$child->{options} = [ qw< +parent > ];
test_run($app, [ qw< help foo > ], {}, 'help')
   ->no_exceptions('inheritance via +parent')
   ->stdout_like(qr{\binh_loose\b}, 'inh_loose is present')
   ->stdout_like(qr{\binh_strict\b}, 'inh_strict is present')
   ;

$child->{options} = [ qw< inh_loose inh_strict > ];
test_run($app, [ qw< help foo > ], {}, 'help')
   ->no_exceptions('inheritance via exact names (both)')
   ->stdout_like(qr{\binh_loose\b}, 'inh_loose is present')
   ->stdout_like(qr{\binh_strict\b}, 'inh_strict is present')
   ;

$child->{options} = [ qw< inh_loose > ];
test_run($app, [ qw< help foo > ], {}, 'help')
   ->no_exceptions('inheritance via exact name (in_loose)')
   ->stdout_like(qr{\binh_loose\b}, 'inh_loose is present')
   ->stdout_unlike(qr{\binh_strict\b}, 'inh_strict is not present')
   ;

$child->{options} = [ qw< inh_strict > ];
test_run($app, [ qw< help foo > ], {}, 'help')
   ->no_exceptions('inheritance via exact name (in_strict)')
   ->stdout_unlike(qr{\binh_loose\b}, 'inh_loose is not present')
   ->stdout_like(qr{\binh_strict\b}, 'inh_strict is present')
   ;

$child->{options} = [ '(?:inh_.*)' ];
test_run($app, [ qw< help foo > ], {}, 'help')
   ->no_exceptions('inheritance via regex (?:inh_.*)')
   ->stdout_like(qr{\binh_loose\b}, 'inh_loose is present')
   ->stdout_unlike(qr{\binh_strict\b}, 'inh_strict is not present')
   ;

done_testing();

sub one_execute_is_enough ($self) {
   LocalTester::command_execute($self);
   return $self->name;
}
