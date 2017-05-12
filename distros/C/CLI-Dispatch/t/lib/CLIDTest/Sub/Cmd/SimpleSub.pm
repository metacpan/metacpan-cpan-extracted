package CLIDTest::Sub::Cmd::SimpleSub;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub run { return 'simple subcommand' }

1;

__END__

=head1 NAME

CLIDTest::Sub::Cmd::SimpleSub - simple subcommand test

=head1 DESCRIPTION

simple subcommand test
