package DateTime::Format::Strptime::Types;

use strict;
use warnings;

our $VERSION = '1.79';

use parent 'Specio::Exporter';

use DateTime;
use DateTime::Locale::Base;
use DateTime::Locale::FromData;
use DateTime::TimeZone;
use Specio 0.33;
use Specio::Declare;
use Specio::Library::Builtins -reexport;
use Specio::Library::String -reexport;

union(
    'Locale',
    of => [
        object_isa_type('DateTime::Locale::Base'),
        object_isa_type('DateTime::Locale::FromData'),
    ],
);

coerce(
    t('Locale'),
    from   => t('NonEmptyStr'),
    inline => sub {"DateTime::Locale->load( $_[1] )"},
);

object_isa_type('DateTime');

my $time_zone_object = object_can_type(
    'TZObject',
    methods => [
        qw(
            is_floating
            is_utc
            name
            offset_for_datetime
            short_name_for_datetime
        )
    ],
);

declare(
    'TimeZone',
    of => [ t('NonEmptySimpleStr'), $time_zone_object ],
);

coerce(
    t('TimeZone'),
    from   => t('NonEmptyStr'),
    inline => sub {"DateTime::TimeZone->new( name => $_[1] )"},
);

union(
    'OnError',
    of => [
        enum( values => [ 'croak', 'undef' ] ),
        t('CodeRef'),
    ],
);

1;

# ABSTRACT: Types used for parameter checking in DateTime::Format::Strptime

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::Strptime::Types - Types used for parameter checking in DateTime::Format::Strptime

=head1 VERSION

version 1.79

=head1 DESCRIPTION

This module has no user-facing parts.

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/DateTime-Format-Strptime/issues>.

There is a mailing list available for users of this distribution,
L<mailto:datetime@perl.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for DateTime-Format-Strptime can be found at L<https://github.com/houseabsolute/DateTime-Format-Strptime>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Rick Measham <rickm@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 - 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
