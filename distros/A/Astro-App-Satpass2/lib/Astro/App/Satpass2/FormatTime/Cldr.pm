package Astro::App::Satpass2::FormatTime::Cldr;

use 5.008;

use strict;
use warnings;

use parent qw{ Exporter };

use Astro::App::Satpass2::Utils qw{ @CARP_NOT };

our $VERSION = '0.040';

our @EXPORT_OK = qw{
    DATE_FORMAT FORMAT_TYPE ISO_8601_FORMAT TIME_FORMAT
};
our @EXPORT = @EXPORT_OK;	## no critic (ProhibitAutomaticExportation)

use constant DATE_FORMAT => 'yyyy-MM-dd';

use constant FORMAT_TYPE => 'CLDR';

use constant ISO_8601_FORMAT => q{yyyy-MM-dd'T'HHmmss'Z'};

use constant TIME_FORMAT => 'HH:mm:ss';

1;

__END__

=head1 NAME

Astro::App::Satpass2::FormatTime::CLDR - Provide common functionality for CLDR-type time formatters.

=head1 SYNOPSIS

 package MyTimeFormatter;
 use Astro::App::Satpass2::FormatTime::Cldr;
 use DateTime;
 use DateTime::TimeZone;

 my $gmt = DateTime::TimeZone->new( name => 'UTC' );
 
 sub iso8601 {
     my ( $time ) = @_;
     my $dt = DateTime->from_epoch(
         epoch => $time,
	 time_zone => $gmt, 
     );
     return $dt->format_cldr( ISO_8601_FORMAT );
 }

=head1 NOTICE

This package is private to the
L<Astro::App::Satpass2|Astro::App::Satpass2> package.  The author
reserves the right to revoke it or change it without notice.

=head1 DESCRIPTION

This package provides common functionality for CLDR-based time
formatters. Since the actual implementation may vary, what we really
have here is a repository for common formats. These are implemented as
manifest constants (i.e. C<use constant>), but are documented below as
methods.

=head1 MANIFEST CONSTANTS

This class supports the following manifest constants, which are all
exported by default:

=head2 DATE_FORMAT

This manifest constant returns a date format designed to produce a
numeric date in the format year-month-day. Since this format is intended
to be used with C<CLDR>, it is C<'yyyy-MM-dd'>.

=head2 FORMAT_TYPE

This manifest constant returns the type of format expected by the
formatter. This class returns C<'CLDR'>.

=head2 ISO_8601_FORMAT

This manifest constant returns a date format designed to produce a date
and time in ISO 8601 format, in the Universal/GMT time zone. Since this
format is intended to be used with C<CLDR>, it is
C<q{yyyy-MM-dd'T'HHmmss'Z'}>.

=head2 TIME_FORMAT

This manifest constant returns a date format designed to produce a time
in the format hour:minute:second.  Since this format is intended to be
used with C<CLDR>, it is C<'HH:mm:ss'>.


=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
