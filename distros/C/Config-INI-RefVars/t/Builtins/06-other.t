use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Basename qw(dirname basename);

use Config::INI::RefVars::Builtins ();

my $dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();

subtest 'not and eq' => sub {
  is($dispatch->{not}->(''), '1', 'not empty string is true');
  is($dispatch->{not}->('x'), '', 'not non-empty string is false');

  is($dispatch->{eq}->('a', 'a'), '1', 'eq returns true for equal strings');
  is($dispatch->{eq}->('a', 'b'), '', 'eq returns empty for different strings');

  throws_ok(sub { $dispatch->{not}->() }, qr/^not: expected 1 argument/, 'not rejects no args');
  throws_ok(sub { $dispatch->{eq}->('a') }, qr/^eq: expected 2 arguments/, 'eq rejects one arg');
};

subtest 'dirname and basename' => sub {
  is($dispatch->{dirname}->('/foo/bar/baz.txt'),
     dirname('/foo/bar/baz.txt'),
     'dirname');
  is($dispatch->{basename}->('/foo/bar/baz.txt'),
     basename('/foo/bar/baz.txt'),
     'basename');
};


#==================================================================================================
done_testing();

