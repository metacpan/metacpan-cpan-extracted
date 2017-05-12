package Business::CPI::Util::EmptyLogger;
# ABSTRACT: Default null logger
use warnings;
use strict;

our $VERSION = '0.924'; # VERSION

sub new      { bless {}, shift }

sub debug    {}
sub info     {}
sub warn     {}
sub error    {}
sub fatal    {}

sub is_debug {}
sub is_info  {}
sub is_warn  {}
sub is_error {}
sub is_fatal {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Util::EmptyLogger - Default null logger

=head1 VERSION

version 0.924

=head1 DESCRIPTION

By default, nothing is logged. This class exists just so that, if the user
wants, it can provide his own logger (e.g. Log::Log4perl, Catalyst::Log,
Log::Dispatcher, etc) when building the Business::CPI gateway object, such as:

    my $cpi = Business::CPI->new(
        gateway => 'Test',
        log     => $log,
        ...
    );

=head1 METHODS

=head2 new

Constructor.

=head2 debug

=head2 info

=head2 warn

=head2 error

=head2 fatal

None of these do anything. It's called by Business::CPI internally, but it's
just a placeholder.

=head2 is_debug

=head2 is_info

=head2 is_warn

=head2 is_error

=head2 is_fatal

All return false by default.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
