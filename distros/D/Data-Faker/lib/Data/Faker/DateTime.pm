package Data::Faker::DateTime;
use strict;
use warnings;
use vars qw($VERSION); $VERSION = '0.10';
use base 'Data::Faker';
use POSIX;

=head1 NAME

Data::Faker::DateTime - Data::Faker plugin

=head1 SYNOPSIS AND USAGE

See L<Data::Faker>

=head1 DATA PROVIDERS

=over 4

=item unixtime

Return a unix time (seconds since the epoch) for a random time between the
epoch and now.

=cut

__PACKAGE__->register_plugin('unixtime' => sub { int(rand(time())) });

=item date

Return a random date as a string, using a random date format (see date_format).

=cut

__PACKAGE__->register_plugin(
	'date' => sub { timestr(shift()->date_format) },
);

=item time

Return a random time as a string, using a random time format (see time_format).

=cut

__PACKAGE__->register_plugin(
	'time' => sub { timestr(shift()->time_format) },
);

=item rfc822

Return an RFC 822 formatted random date.  This method may not work on systems
using a non-GNU strftime implementation (kindly let me know if that is the
case.)

=cut

__PACKAGE__->register_plugin(
	'rfc822' => sub { timestr('%a,  %d  %b  %Y  %H:%M:%S  %z') },
);

=item ampm

Returns am or pm randomly (in the current locale) using one of the formats
specified in ampm_format.

=cut

__PACKAGE__->register_plugin(
	'ampm' => sub { timestr(shift()->ampm_format) },
);

=item time_format

Return a random time format.

=cut

__PACKAGE__->register_plugin(
	'time_format' => [qw(%R %r %T)],
);

=item date_format

Return a random date format.

=cut

__PACKAGE__->register_plugin(
	'date_format' => [qw(%D %F)],
);

=item ampm_format

Return a random am/pm format.

=cut

__PACKAGE__->register_plugin(
	'ampm_format' => [qw(%p %P)],
);

=item datetime_format

Return a random date and time format.

=cut

__PACKAGE__->register_plugin(
	'datetime_format' => ['%c','%+','%FT%H','%FT%I','%F %H','%F %I'],
);

=item month

Return a random month name, unabbreviated, in the current locale.

=cut

__PACKAGE__->register_plugin(
	'month' => sub { timestr('%B') },
);

=item month_abbr

Return a random month name, abbreviated, in the current locale.

=cut

__PACKAGE__->register_plugin(
	'month_abbr' => sub { timestr('%b') },
);

=item weekday

Return a random weekday name, unabbreviated, in the current locale.

=cut

__PACKAGE__->register_plugin(
	'weekday' => sub { timestr('%A') },
);

=item weekday_abbr

Return a random weekday name, abbreviated, in the current locale.

=cut

__PACKAGE__->register_plugin(
	'weekday_abbr' => sub { timestr('%a') },
);

=item sqldate

Return a random date in the ISO8601 format commonly used by SQL servers
(YYYY-MM-DD).

=cut

__PACKAGE__->register_plugin(
	'sqldate' => sub { timestr('%F') },
);

=item datetime_locale

Return a datetime string in the preferred date representation for the
current locale, for a random date.

=cut

__PACKAGE__->register_plugin(
	'datetime_locale' => sub { timestr('%c') },
);

=item date_locale

Return a date string in the preferred date representation for the
current locale, for a random date.

=cut

__PACKAGE__->register_plugin(
	'date_locale' => sub { timestr('%x') },
);

=item time_locale

Return a time string in the preferred date representation for the
current locale, for a random date.

=cut

__PACKAGE__->register_plugin(
	'time_locale' => sub { timestr('%X') },
);

=item century

Return a random century number.

=cut

__PACKAGE__->register_plugin(
	'century' => sub { timestr('%C') },
);

=item dayofmonth

Return a random day of the month.

=cut

__PACKAGE__->register_plugin(
	'dayofmonth' => sub { timestr('%d') },
);

=back

=head1 UTILITY METHODS

=over 4

=item Data::Faker::DateTime::timestr($format);

Given a strftime format specifier, this method passes it through to
L<POSIX::strftime> along with a random date to display in that format.

Perl passes this through to the strftime function of your system library, so
it is possible that some of the formatting tokens used here will not work on
your system.

=cut

{
    # timestr here redefines the one from Benchmark, which is only loaded for tests.
    no warnings 'redefine';

    sub timestr {
        my $format = shift;
        if(ref($format)) { $format = shift }
        POSIX::strftime($format, localtime(__PACKAGE__->unixtime));
    }
}

=back

=head1 NOTES AND CAVEATS

=over 4

=item Be careful building timestamps from pieces

Be very careful about building date/time representations in formats that
are not already listed here.  For example if you wanted to get a date that
consists of just the month and day, you should NOT do this:

  my $faker = Data::Faker->new();
  print join(' ',$faker->month,$faker->dayofmonth)."\n";

This is bad because you might end up with 'February 31' for example.  Instead
you should use the timestr utility function to provide you a formatted time
for a valid date, or better still, write a plugin function that does it:

  my $faker = Data::Faker->new();
  print $faker->my_short_date()."\n";

  package Data::Faker::MyExtras;
  use base qw(Data::Faker);
  use Data::Faker::DateTime;
  __PACKAGE__->register_plugin(
    my_short_date => sub { Data::Faker::DateTime::timestr('%M %e') },
  );

=item POSIX::strftime

See the documentation above regarding the timestr utility method for some
caveats related to strftime and your system library.

=back

=head1 SEE ALSO

L<Data::Faker>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
