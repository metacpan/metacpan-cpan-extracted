package Cassandra::Client::Policy::Retry;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Policy::Retry::VERSION = '0.16';
use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK= (qw/try_next_host retry rethrow/);

sub try_next_host {
    my $cl= shift;
    return 'retry';
}

sub retry {
    my $cl= shift;
    return 'retry';
}

sub rethrow {
    return 'rethrow';
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Policy::Retry

=head1 VERSION

version 0.16

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
