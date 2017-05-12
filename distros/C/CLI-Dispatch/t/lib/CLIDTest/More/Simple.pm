package CLIDTest::More::Simple;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub run { return 'simple' }

1;

__END__

=head1 NAME

CLIDTest::More::Simple - simple test

=head1 DESCRIPTION

simple dispatch test
