package CLIDTest::Check::WithOptions;

use strict;
use warnings;
use base qw( CLIDTest::More::WithOptions );

sub check { die "for some reasons" }

1;

__END__

=head1 NAME

CLIDTest::Check::WithOptions - option test

=head1 DESCRIPTION

test with options
