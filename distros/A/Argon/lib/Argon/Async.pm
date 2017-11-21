package Argon::Async;
#ABSTRACT: A tied condvar that calls recv on FETCH
$Argon::Async::VERSION = '0.18';

use strict;
use warnings;
use Carp;

use parent 'Tie::Scalar';

sub TIESCALAR { bless \$_[1], $_[0] }
sub STORE { croak 'Argon::Async is read only' }
sub FETCH { ${$_[0]}->recv }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Async - A tied condvar that calls recv on FETCH

=head1 VERSION

version 0.18

=head1 DESCRIPTION

A tied condvar (see L<AnyEvent/CONDITION VARIABLES>) that calls C<recv> on
C<FETCH>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
