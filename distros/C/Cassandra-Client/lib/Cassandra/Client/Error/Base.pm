package Cassandra::Client::Error::Base;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Error::Base::VERSION = '0.20';
use 5.010;
use strict;
use warnings;

sub new { my $class= shift; bless { code => -1, message => "An unknown error occurred", @_ }, $class }
use overload '""' => sub { $_[0]->to_string };
sub to_string { "Error $_[0]{code}: $_[0]{message}" }
sub code { $_[0]{code} }
sub message { $_[0]{message} }
sub is_request_error { $_[0]{request_error} }
sub do_retry { $_[0]{do_retry} }
sub is_timeout { $_[0]{is_timeout} }

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Error::Base

=head1 VERSION

version 0.20

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
