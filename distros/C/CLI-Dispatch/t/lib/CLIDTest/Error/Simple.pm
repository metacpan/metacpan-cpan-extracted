package CLIDTest::Error::Simple;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub run { return 'simple' }

die "intentionally";

1;

__END__

=head1 NAME

CLIDTest::Error::Simple - simple test

=head1 DESCRIPTION

simple dispatch test
