package Cassandra::Client::Policy::Throttle::Default;
our $AUTHORITY = 'cpan:TVDW';
$Cassandra::Client::Policy::Throttle::Default::VERSION = '0.19';
use 5.010;
use strict;
use warnings;

sub new {
    my ($class, %args)= @_;
    return bless {}, $class;
}

sub should_fail {
    return 0;
}

sub count {
    return;
}

1;

__END__

=pod

=head1 NAME

Cassandra::Client::Policy::Throttle::Default

=head1 VERSION

version 0.19

=head1 AUTHOR

Tom van der Woerdt <tvdw@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Tom van der Woerdt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
