package CLIDTest::Check::Simple;

use strict;
use warnings;
use Carp;
use base qw( CLIDTest::More::Simple );

sub check { croak "for some reasons" }

1;

__END__

=head1 NAME

CLIDTest::Check::Simple - simple test

=head1 DESCRIPTION

simple dispatch test
