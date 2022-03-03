package Cassandra::Client::Error::WriteTimeoutException;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Error::WriteTimeoutException::VERSION = '0.19';
use parent 'Cassandra::Client::Error::Base';
use 5.010;
use strict;
use warnings;

sub is_timeout { 1 }
sub cl { $_[0]{cl} }
sub write_type { $_[0]{write_type} }
sub blockfor { $_[0]{blockfor} }
sub received { $_[0]{received} }

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Error::WriteTimeoutException

=head1 VERSION

version 0.19

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
