package Astro::App::Satpass2::FormatTime::DateTime::Strftime;

use 5.008;

use strict;
use warnings;

use parent qw{
    Astro::App::Satpass2::FormatTime::DateTime
};

use Astro::App::Satpass2::FormatTime::Strftime;
use Astro::App::Satpass2::Utils qw{ @CARP_NOT };
use DateTime;
use DateTime::TimeZone;
use POSIX ();

our $VERSION = '0.040';

# So superclass can ducktype the object that does the real work.
use constant METHOD_USED => 'strftime';

sub __format_datetime {
    my ( $self, $date_time, $tplt ) = @_;
    return $date_time->strftime( $self->__preprocess_strftime_format(
	    $date_time, $tplt ) );
}

1;

__END__

=head1 NAME

Astro::App::Satpass2::FormatTime::DateTime::Strftime - Format time using DateTime->strftime()

=head1 SYNOPSIS

 use Astro::App::Satpass2::FormatTime::DateTime::Strftime;
 my $tf = Astro::App::Satpass2::FormatTime::DateTime::Strftime->new();
 print 'It is now ',
     $tf->format_datetime( '%H:%M:%S', time, 1 ),
     " GMT\n";

=head1 NOTICE

This class and its subclasses are private to the
L<Astro::App::Satpass2|Astro::App::Satpass2> package. The author
reserves the right to add, change, or retract functionality without
notice.

=head1 DETAILS

This subclass of
L<Astro::App::Satpass2::FormatTime::DateTime|Astro::App::Satpass2::FormatTime::DateTime>
formats times using C<DateTime->strftime()>. Time zones other than the
default local zone are handled using
L<DateTime::TimeZone|DateTime::TimeZone> objects.

All this class really provides is the interface to
C<< DateTime->strftime() >>. Everything else is inherited.

The L<DateTime|DateTime> C<strftime()> template extensions have been
further extended to add C<'%{calendar_name}'> and some control over
formatting. See the documentation to
L<Astro::App::Satpass2::FormatTime::DateTime|Astro::App::Satpass2::FormatTime::DateTime>
L<__preprocess_strftime_format()|Astro::App::Satpass2::FormatTime::DateTime/__preprocess_strftime_format>
for the details.

=head1 METHODS

This class provides no public methods over and above those provided by
L<Astro::App::Satpass2::FormatTime::DateTime|Astro::App::Satpass2::FormatTime::DateTime>
and
L<Astro::App::Satpass2::FormatTime::Strftime|Astro::App::Satpass2::FormatTime::Strftime>.

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
