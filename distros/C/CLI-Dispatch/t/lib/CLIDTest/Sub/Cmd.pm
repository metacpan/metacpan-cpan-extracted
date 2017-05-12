package CLIDTest::Sub::Cmd;

use strict;
use warnings;
use CLI::Dispatch;
use base qw( CLI::Dispatch::Command );

sub run {
  my $self = shift;
  my $dispatcher = CLI::Dispatch->new(%$self);
  $dispatcher->run('CLIDTest::Sub::Cmd');
}

1;

__END__

=head1 NAME

CLIDTest::Sub::Cmd - has sub commands

=head1 DESCRIPTION

I have children
