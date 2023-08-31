## no critic (RequireStrictDeclarations ProhibitUselessNoCritic)
package App::Oozie::Constants;
$App::Oozie::Constants::VERSION = '0.002';
use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

use constant OOZIE_STATES_RERUNNABLE => qw(
    KILLED
    SUSPENDED
    FAILED
);

use constant OOZIE_STATES_RUNNING => qw(
    RUNNING
    SUSPENDED
    PREP
);

use constant {
    DEFAULT_TZ           => 'CET',
    DEFAULT_WEBHDFS_PORT => 14000,
};

our @EXPORT_OK = qw(
    DEFAULT_TZ
    DEFAULT_WEBHDFS_PORT
    OOZIE_STATES_RERUNNABLE
    OOZIE_STATES_RUNNING
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Constants

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use App::Oozie::Constants qw( DEFAULT_TZ );

=head1 DESCRIPTION

Internal constants.

=head1 NAME

App::Oozie::Constants - Internal constants.

=head1 Constants

=head2 DEFAULT_TZ

=head2 DEFAULT_WEBHDFS_PORT

=head2 OOZIE_STATES_RERUNNABLE

=head2 OOZIE_STATES_RUNNING

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
