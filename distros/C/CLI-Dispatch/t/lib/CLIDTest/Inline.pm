use strict;
use warnings;

package CLIDTest::Inline;
use base 'CLI::Dispatch';
CLI::Dispatch->run('CLIDTest::Inline');

package CLIDTest::Inline::Simple;
use base 'CLI::Dispatch::Command';
sub run { return 'simple' }

package CLIDTest::Inline::WithArgs;
use base 'CLI::Dispatch::Command';
sub run { shift; join '', @_ }

package CLIDTest::Inline::WithOptions;
use base 'CLI::Dispatch::Command';
sub options {qw( hello target|t=s )}
sub run {
  my ($self, @args) = @_;
  my $hello = $self->option('hello') ? 'hello' : 'goodbye';
  return join ' ', $hello, $self->option('target');
}

1;
