## no critic (RequireStrictDeclarations ProhibitUselessNoCritic)
package App::Oozie::Types::States;
$App::Oozie::Types::States::VERSION = '0.006';
use 5.010;
use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

use App::Oozie::Constants qw(
    OOZIE_STATES_RERUNNABLE
    OOZIE_STATES_RUNNING
);

BEGIN {
    extends 'Types::Standard';
}

my $StateRerunnableEnum = declare StateRerunnableEnum => as Enum[ OOZIE_STATES_RERUNNABLE ];

declare IsOozieStateRerunnable => as ArrayRef[ $StateRerunnableEnum, 1 ];

my $StateRunningEnum = declare StateRunningEnum => as Enum[ OOZIE_STATES_RUNNING ];

declare IsOozieStateRunning => as ArrayRef[ $StateRunningEnum, 1 ];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Types::States

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use App::Oozie::Types::States qw( IsOozieStateRerunnable );

=head1 DESCRIPTION

Internal types.

=head1 NAME

App::Oozie::Types::States - Internal types.

=head1 Types

=head2 IsOozieStateRerunnable

=head2 IsOozieStateRunning

=head2 StateRerunnableEnum

=head2 StateRunningEnum

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
