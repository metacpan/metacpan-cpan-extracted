package CLIDTest::Sub::Cmd::WithOptionsSub;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub options {qw( subcommand works|w=s )}

sub run {
  my ($self, @args) = @_;

  my $cmd = $self->option('subcommand') ? 'subcommand' : 'command';

  return join ' ', $self->option('works'), $cmd;
}

1;

__END__

=head1 NAME

CLIDTest::Sub::Cmd::WithOptionsSub - option test

=head1 DESCRIPTION

test with options
