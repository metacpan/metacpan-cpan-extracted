package CLIDTest::Check::WithArgs;

use strict;
use warnings;
use base qw( CLIDTest::More::WithArgs );

sub check { die "for some reasons" }

1;

__END__

=head1 NAME

CLIDTest::Check::WithArgs - args test

=head1 DESCRIPTION

test with args
