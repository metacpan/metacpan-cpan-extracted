package Cassandra::Client::Error;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Error::VERSION = '0.13';
use 5.010;
use strict;
use warnings;

sub new { my $class= shift; bless { code => -1, message => "An unknown error occurred", @_ }, $class }
use overload '""' => sub { "Error $_[0]{code}: $_[0]{message}" };
sub code { $_[0]{code} }
sub message { $_[0]{message} }

# XXX This class needs serious refactoring
# Important things we pass :
#  * is_timeout
#  * do_retry

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Error

=head1 VERSION

version 0.13

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
