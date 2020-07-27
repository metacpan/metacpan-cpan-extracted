package DateTime::HiRes;

use strict;
use warnings;

our $VERSION = '0.04';

use DateTime;
use Time::HiRes;

sub now { shift; DateTime->from_epoch( epoch => Time::HiRes::time, @_ ) }

1;

# ABSTRACT: Create DateTime objects with sub-second current time resolution

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::HiRes - Create DateTime objects with sub-second current time resolution

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use DateTime::HiRes;

    my $dt = DateTime::HiRes->now;

=head1 DESCRIPTION

This module enables you to generate DateTime objects that represent the current
time with sub-second resolution.

=head1 METHODS

This class provides the following methods:

=head2 DateTime::HiRes->now( ... )

Similar to C<DateTime-E<gt>now> but uses C<Time::HiRes::time()> instead of
Perl's C<CORE::time()> to determine the current time. The returned object will
have fractional second information stored as nanoseconds. The sub-second
precision of C<Time::HiRes> is highly system dependent and will vary from one
platform to the next.

Just like C<DateTime-E<gt>now> it accepts "time_zone" and "locale" parameters.

=head1 CREDITS

Everyone at the DateTime C<Asylum>.

=head1 SEE ALSO

L<DateTime>, L<Time::HiRes>

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/DateTime-HiRes/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for DateTime-HiRes can be found at L<https://github.com/houseabsolute/DateTime-HiRes>.

=head1 AUTHORS

=over 4

=item *

Joshua Hoblitt <jhoblitt@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTOR

=for stopwords Roy Ivy III

Roy Ivy III <rivy.dev@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Joshua Hoblitt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
