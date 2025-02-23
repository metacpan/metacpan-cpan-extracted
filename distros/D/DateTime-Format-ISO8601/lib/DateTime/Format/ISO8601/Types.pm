package DateTime::Format::ISO8601::Types;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.17';

use parent 'Specio::Exporter';

use DateTime;
use Specio 0.18;
use Specio::Declare;
use Specio::Library::Builtins -reexport;

declare(
    'CutOffYear',
    parent => t('Int'),
    inline => sub {
        shift;
        my $value = shift;
        return "$value >= 0 && $value <= 99",;
    },
);

object_isa_type(
    'DateTime',
    class => 'DateTime',
);

object_can_type(
    'DateTimeIsh',
    methods => ['utc_rd_values'],
);

1;

# ABSTRACT: Types used for parameter checking in DateTime

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::ISO8601::Types - Types used for parameter checking in DateTime

=head1 VERSION

version 0.17

=head1 DESCRIPTION

This module has no user-facing parts.

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/DateTime-Format-ISO8601/issues>.

=head1 SOURCE

The source code repository for DateTime-Format-ISO8601 can be found at L<https://github.com/houseabsolute/DateTime-Format-ISO8601>.

=head1 AUTHORS

=over 4

=item *

Joshua Hoblitt <josh@hoblitt.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Joshua Hoblitt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
