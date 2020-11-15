package Cassandra::Client::Error::UnavailableException;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Error::UnavailableException::VERSION = '0.18';
use parent 'Cassandra::Client::Error::Base';
use 5.010;
use strict;
use warnings;

sub cl { $_[0]{cl} }
sub required { $_[0]{required} }
sub alive { $_[0]{alive} }

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Error::UnavailableException

=head1 VERSION

version 0.18

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
